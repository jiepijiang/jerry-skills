/**
 * 分类判定与推断的单元测试
 * ---------------------------------------------------------------------------
 * 跑法：npm test（= node --test scripts/tests/）
 *
 * 覆盖的都是「上线后一定会被用户撞到」的点：
 *   · 没写 category 的技能能不能被认出来（这是原始 bug）
 *   · 英文关键词的**词边界**（`api` 不许命中 `capital`）
 *   · 认不出来时要老实说认不出来，不许瞎猜
 *   · 作者写了的分类必须被尊重，不能被推断覆盖
 *
 * ⚠️ 按项目纪律：**没红过的绿灯没有意义**（造红记录见 README「验证」一节）。
 */
import { test } from 'node:test'
import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'

import {
  CATEGORY_KEYS,
  CATEGORY_RULE_HINT,
  inferCategory,
  normalizeCategory,
  resolveCategory,
} from '../../src/lib/category.js'

const ROOT = fileURLToPath(new URL('../..', import.meta.url))

/** 断言某个关键词**没有**被命中 —— 比断言整个 key 更精确，能指出是哪个词误伤 */
function assertNoHit(input, word) {
  const r = inferCategory(input)
  assert.ok(
    !r.hits.includes(word),
    `「${word}」不该被命中，实际命中：${r.hits.join('、') || '(无)'}`,
  )
}

function assertHit(input, word) {
  const r = inferCategory(input)
  assert.ok(
    r.hits.includes(word),
    `「${word}」应该被命中，实际命中：${r.hits.join('、') || '(无)'}`,
  )
}

/* ------------------------------------------------------------ 基础清单 */

test('CATEGORY_KEYS 不含重复项，且包含兜底的 other', () => {
  assert.equal(new Set(CATEGORY_KEYS).size, CATEGORY_KEYS.length, '有重复 key')
  assert.ok(CATEGORY_KEYS.includes('other'), '必须有兜底的 other')
})

test('CATEGORY_RULE_HINT 把可推断的分类都列出来了', () => {
  for (const key of CATEGORY_KEYS.filter((k) => k !== 'other')) {
    assert.ok(CATEGORY_RULE_HINT.includes(key), `规则说明里漏了分类 ${key}`)
  }
  assert.ok(CATEGORY_RULE_HINT.includes('other'), '规则说明里要提到 other')
})

/* ------------------------------------------------------ normalizeCategory */

test('normalizeCategory：标准 key 原样返回，大小写不敏感', () => {
  for (const key of CATEGORY_KEYS) {
    assert.equal(normalizeCategory(key), key)
    assert.equal(normalizeCategory(key.toUpperCase()), key)
    assert.equal(normalizeCategory(`  ${key}  `), key)
  }
})

test('normalizeCategory：认别名与中文写法', () => {
  const pairs = [
    ['dev', 'development'],
    ['开发', 'development'],
    ['coding', 'development'],
    ['docs', 'document'],
    ['文档', 'document'],
    ['ui', 'design'],
    ['设计', 'design'],
    ['数据', 'data'],
    ['写作', 'writing'],
    ['ops', 'devops'],
    ['运维', 'devops'],
    ['效率', 'productivity'],
    ['其他', 'other'],
  ]
  for (const [input, want] of pairs) {
    assert.equal(normalizeCategory(input), want, `${input} 应该归一化成 ${want}`)
  }
})

test('normalizeCategory：认不出来返回空串，而不是 other', () => {
  // ⚠️ 这个区别是刻意的：「不认识」要走内容推断，「明确写了 other」要直接尊重。
  //    混成一样的话，作者写 category: misc 和完全没写会得到同样的处理。
  for (const bad of ['nonsense', '随便', '123', '', '   ', null, undefined]) {
    assert.equal(normalizeCategory(bad), '', `${JSON.stringify(bad)} 应该返回空串`)
  }
})

/* --------------------------------------------------------- 词边界（重点） */

test('英文关键词按词边界匹配 —— api 不许命中 capital', () => {
  assertNoHit({ name: 'capital-city', description: 'the capital of France' }, 'api')
})

test('英文关键词按词边界匹配 —— word 不许命中 keyword / password', () => {
  assertNoHit({ name: 'keyword-extractor', description: 'grab the password field' }, 'word')
})

test('英文关键词按词边界匹配 —— ui 不许命中 guide / build', () => {
  assertNoHit({ name: 'guide-builder', description: 'a guide to building things' }, 'ui')
})

test('英文关键词按词边界匹配 —— 该命中的还是要命中', () => {
  assertHit({ name: 'x', description: 'call the REST API' }, 'api')
  assertHit({ name: 'x', description: 'the UI layer and the UX flow' }, 'ui')
  assertHit({ name: 'x', description: 'a design guide' }, 'design')
})

test('带 * 的关键词按前缀匹配 —— script* 命中 scripts / scripting', () => {
  assertHit({ name: 'x', description: 'run the scripts' }, 'script')
  assertHit({ name: 'x', description: 'scripting helper' }, 'script')
  assertHit({ name: 'x', description: 'read the documentation' }, 'document')
})

test('中文关键词按子串匹配', () => {
  assertHit({ name: 'x', description: '这是一个命令行工具' }, '命令行')
  assertHit({ name: 'x', description: '帮你做数据分析' }, '数据')
})

/* ------------------------------------------------------------- 真实样例 */

test('★ 回归：ikotek-cli 的真实元信息要判成 development（原来落 other）', () => {
  // 这条是原始 bug 的护栏。它的 SKILL.md frontmatter 只有 name / description / metadata，
  // **没有 category**，所以旧规则必然把它丢进「其他」。
  const r = inferCategory({
    name: 'ikotek-cli',
    description:
      'Ikotek 企业 CLI（ikotek-cli）通用参考。当用户提到 ikotek-cli、ikotek 命令行、' +
      '插件、IPMS、Jira、Confluence、登录/授权/设备码、env、access_token、升级 CLI、' +
      'AI Skills 等关键词时激活。覆盖安装、两阶段登录、环境切换、插件体系与故障排查',
    tags: [],
    files: [
      'SKILL.md',
      'references/auth-options.md',
      'references/jql-patterns.md',
      'scripts/check-ps2-compat.ps1',
      'scripts/lib-ikotek-login.ps1',
    ],
  })
  assert.equal(r.key, 'development', `应该判成 development，实际 ${r.key}（命中：${r.hits.join('、')}）`)
})

test('真实技能样例各自落到合理分类', () => {
  const cases = [
    [
      { name: 'pdf-processing', description: 'Extract text and tables from PDF files, fill forms, merge documents.', tags: ['pdf'] },
      'document',
    ],
    [
      { name: 'brand-guidelines', description: "Apply the official brand colors and typography to any artifact.", tags: [] },
      'design',
    ],
    [
      { name: 'mcp-builder', description: 'Guide for creating high-quality MCP servers.', tags: ['mcp'] },
      'development',
    ],
    [
      { name: 'spreadsheet-analyzer', description: '按条件筛选表格数据并生成图表报表。', tags: ['excel'] },
      'data',
    ],
    [
      { name: 'deploy-helper', description: '一键把静态站点部署到服务器，自动配 nginx 与证书。', tags: [] },
      'devops',
    ],
  ]
  for (const [input, want] of cases) {
    assert.equal(inferCategory(input).key, want, `${input.name} 应该是 ${want}`)
  }
})

/* ------------------------------------------------------------ 不瞎猜 */

test('完全没有信号时返回 null，不硬凑一个分类', () => {
  const r = inferCategory({ name: '随便什么', description: '帮你做点事情。', tags: [] })
  assert.equal(r.key, null, `不该下结论，实际判成 ${r.key}`)
  assert.equal(r.score, 0)
})

test('只有文件路径命中时不下结论 —— 文件路径只配打破平局', () => {
  // `script*` 在 files 里命中，但 files 字段权重 1、上限 3 → 最多 3 分 < 阈值 4
  const r = inferCategory({ name: 'tool', description: '', tags: [], files: ['scripts/a.ps1', 'scripts/b.ps1'] })
  assert.equal(r.key, null, `文件路径不该单独决定分类，实际判成 ${r.key}`)
})

test('推断结果可复现 —— 同样输入跑两次完全一致', () => {
  const input = { name: 'webapp-testing', description: 'Toolkit for testing web apps using Playwright.', tags: ['testing'] }
  const a = inferCategory(input)
  const b = inferCategory(input)
  assert.deepEqual(a, b)
})

test('tags 单独也能推出分类', () => {
  const r = inferCategory({ name: 'helper', description: 'a small helper', tags: ['excel', 'csv'] })
  assert.equal(r.key, 'data', `tags 应该能推出 data，实际 ${r.key}`)
})

/* -------------------------------------------------------- resolveCategory */

test('resolveCategory：作者写了合法分类就尊重它，哪怕内容指向别的分类', () => {
  // 内容满是「代码 / 编程」，但作者明确写了 design —— 以作者为准。
  const r = resolveCategory({ name: 'x', description: '写代码的工具', category: 'design' })
  assert.equal(r.key, 'design')
  assert.equal(r.source, 'declared')
  assert.equal(r.declared, 'design')
})

test('resolveCategory：中文 / 别名写法也算「写了」', () => {
  const r = resolveCategory({ name: 'x', description: '随便', category: '开发' })
  assert.equal(r.key, 'development')
  assert.equal(r.source, 'declared')
})

test('resolveCategory：没写分类时走推断', () => {
  const r = resolveCategory({ name: 'deploy-helper', description: '部署到服务器，配 nginx' })
  assert.equal(r.key, 'devops')
  assert.equal(r.source, 'inferred')
  assert.ok(r.hits.length > 0, '推断应该给出命中依据')
})

test('resolveCategory：写了但认不出来 → 走推断，并保留原值给用户看', () => {
  const r = resolveCategory({ name: 'x', description: '写代码的工具', category: 'nonsense' })
  assert.equal(r.key, 'development')
  assert.equal(r.source, 'inferred')
  assert.equal(r.declared, 'nonsense', '要把原始值带出来，页面上才能提示用户写错了')
})

test('resolveCategory：写了认不出、推断也没把握 → other，source 标记为 invalid', () => {
  const r = resolveCategory({ name: '随便什么', description: '帮你做点事情。', category: 'nonsense' })
  assert.equal(r.key, 'other')
  assert.equal(r.source, 'invalid')
  assert.equal(r.declared, 'nonsense')
})

test('resolveCategory：什么都没写也推不出来 → other + none', () => {
  const r = resolveCategory({ name: '随便什么', description: '帮你做点事情。' })
  assert.equal(r.key, 'other')
  assert.equal(r.source, 'none')
})

test('resolveCategory：结果永远是合法的 CATEGORY_KEYS 之一', () => {
  const inputs = [
    {},
    { name: 'x' },
    { name: 'x', category: '乱写的' },
    { name: 'x', category: 'dev' },
    { description: '部署 docker 到服务器' },
    { description: '写公众号文章' },
  ]
  for (const i of inputs) {
    const r = resolveCategory(i)
    assert.ok(CATEGORY_KEYS.includes(r.key), `${JSON.stringify(i)} → 非法 key ${r.key}`)
  }
})

/* --------------------------------------------- 展示信息不能漏（源码级） */

test('data/site.js 的 CATEGORY_META 覆盖了所有 CATEGORY_KEYS', () => {
  // site.js 依赖 import.meta.env，纯 node 里 import 不了，所以退一步做源码检查。
  // 漏了 label/icon 的话，筛选栏会渲染出一个空白的分类按钮。
  const src = readFileSync(`${ROOT}src/data/site.js`, 'utf8')
  const block = /const CATEGORY_META = \{([\s\S]*?)\n\}/.exec(src)
  assert.ok(block, '没找到 CATEGORY_META 定义')
  for (const key of CATEGORY_KEYS) {
    assert.ok(
      new RegExp(`^\\s*${key}:\\s*\\{`, 'm').test(block[1]),
      `CATEGORY_META 里缺少 ${key} 的 label / icon`,
    )
  }
})
