/**
 * 技能卡片的**渲染**测试
 * ---------------------------------------------------------------------------
 * 跑法：npm test（= node --test scripts/tests/）
 *
 * 为什么不在源码上做字符串断言：`template.includes('relativeTime')` 这种检查
 * 在「模板里写了但 props 传错 / computed 拼错 / v-if 永远为假」时**照样绿**。
 * 所以这里用 vite 的 ssrLoadModule 真编译一次 SFC，再用 vue/server-renderer
 * 渲染成 HTML，断言的是**用户真正会看到的那段文字**。
 * （不需要 jsdom —— 服务端渲染就够了，卡片本身没有浏览器 API 依赖。）
 *
 * ⚠️ 按项目纪律：**没红过的绿灯没有意义**。
 *    把 SkillCard.vue 里的时间那一段删掉，本文件必须红（已实测）。
 */
import { after, before, test } from 'node:test'
import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'

import { createSSRApp, h } from 'vue'
import { renderToString } from 'vue/server-renderer'

import { ROOT, createSsrServer } from './_ssr.mjs'

let server
let SkillCard

before(async () => {
  server = await createSsrServer()
  ;({ default: SkillCard } = await server.ssrLoadModule('/src/components/SkillCard.vue'))
})

after(async () => {
  await server?.close()
})

/**
 * router-link 的替身。用**渲染函数**而不是 template ——
 * vue 默认导出的是 runtime-only 构建，带 template 的组件在 SSR 下会报
 * 「runtime compilation is not supported」。
 */
const RouterLinkStub = {
  name: 'RouterLink',
  props: { to: { type: [String, Object], default: '' } },
  setup(props, { slots }) {
    return () => h('a', { href: String(props.to) }, slots.default ? slots.default() : [])
  },
}

/** 渲染一张卡片，返回 HTML */
async function renderCard(skill) {
  const app = createSSRApp({ render: () => h(SkillCard, { skill }) })
  app.component('router-link', RouterLinkStub)
  return renderToString(app)
}

/** 造一个「N 天前上传」的技能 */
function skillAgedDays(days) {
  return {
    slug: 'demo-skill',
    name: '演示技能',
    description: '一个用来测试的演示技能',
    category: 'dev',
    tags: ['demo', 'test'],
    version: '1.2.0',
    license: 'MIT',
    author: 'Jerry',
    file_count: 3,
    total_bytes: 2048,
    downloads: 12,
    installs: 3,
    created_at: new Date(Date.now() - days * 86400000 - 60000).toISOString(),
  }
}

/* ------------------------------------------------------------ 渲染断言 */

test('卡片渲染出上传时间', async () => {
  const html = await renderCard(skillAgedDays(3))
  assert.ok(html.includes('3 天前'), `卡片里应该出现「3 天前」，实际 HTML：\n${html}`)
})

test('卡片的时间带绝对时间悬浮提示（title）', async () => {
  const html = await renderCard(skillAgedDays(3))
  assert.match(html, /title="上传于 \d{4}-\d{2}-\d{2} \d{2}:\d{2}"/)
})

test('卡片渲染出的时间与 @/lib/time 的结果一致（两处算法不漂移）', async () => {
  const skill = skillAgedDays(10)
  const { relativeTime } = await server.ssrLoadModule('/src/lib/time.js')
  const html = await renderCard(skill)
  assert.ok(html.includes(relativeTime(skill.created_at)), '卡片显示的时间应该就是共享模块算出来的那个')
})

test('没有 created_at 时整段时间都不渲染 —— 不能出现「56 年前」', async () => {
  const skill = { ...skillAgedDays(3), created_at: null }
  const html = await renderCard(skill)
  assert.ok(!html.includes('年前'), 'null 时间戳绝不能渲染成「N 年前」')
  // ⚠️ 断言用 `class="sc-time"` 而不是 `sc-time`：模板里的注释也会被 SSR 输出，
  //    写成裸类名的话，注释里提到一次就能让这条断言**永远绿**。
  assert.ok(!html.includes('class="sc-time"'), '时间元素应该整个不渲染')
})

test('created_at 是非法字符串时同样不渲染', async () => {
  const html = await renderCard({ ...skillAgedDays(3), created_at: 'not-a-date' })
  assert.ok(!html.includes('class="sc-time"'))
  assert.ok(!html.includes('Invalid Date'))
})

test('加时间没有挤掉原有的下载量 / 安装量 / 作者', async () => {
  const html = await renderCard(skillAgedDays(3))
  assert.ok(html.includes('>12<') || html.includes('12'), '下载量还在')
  assert.ok(html.includes('Jerry'), '作者还在')
  assert.ok(html.includes('v1.2.0'), '版本号还在')
})

/* ------------------------------------------------- 计量口径必须说清楚 */

test('卡片上「安装量」的 tooltip 说明了口径 —— 数的是复制次数，不是真的装了', async () => {
  // 「安装量」实际统计的是「复制过安装命令 / 提示词的次数」。
  // 这个口径是产品上确认过的，但**数字必须自己解释自己** ——
  // 光写一个「安装量」标签，用户会以为是「真的装到 N 台机器上」。
  const html = await renderCard(skillAgedDays(3))
  const titles = [...html.matchAll(/\stitle="([^"]*)"/g)].map((m) => m[1])
  const installTitle = titles.find((t) => t.includes('安装量'))

  assert.ok(installTitle, `卡片上应该有解释安装量口径的 tooltip，实际 title：${JSON.stringify(titles)}`)
  assert.notEqual(installTitle, '安装量', '不能只是一个光秃秃的标签')
  assert.match(installTitle, /复制/, `tooltip 必须说明它数的是复制次数，实际：${installTitle}`)
})

test('下载量的 tooltip 同样有口径说明（两个数字待遇一致）', async () => {
  const html = await renderCard(skillAgedDays(3))
  const titles = [...html.matchAll(/\stitle="([^"]*)"/g)].map((m) => m[1])
  const dl = titles.find((t) => t.includes('下载量'))
  assert.ok(dl, `应该有下载量口径说明，实际：${JSON.stringify(titles)}`)
  assert.notEqual(dl, '下载量', '不能只是一个光秃秃的标签')
})

test('卡片与详情页共用同一份口径文案，不各写一份', () => {
  const card = readFileSync(`${ROOT}src/components/SkillCard.vue`, 'utf8')
  const detail = readFileSync(`${ROOT}src/views/SkillDetailView.vue`, 'utf8')
  for (const [name, src] of Object.entries({ SkillCard: card, SkillDetailView: detail })) {
    assert.ok(src.includes('metricNotes'), `${name} 应该从 @/data/site 取 metricNotes`)
    assert.ok(
      !/title="安装量"/.test(src),
      `${name} 里不该再有光秃秃的 title="安装量" —— 口径文案要统一走 metricNotes`,
    )
  }
})

test('详情页安装区里解释了「安装量」的口径', () => {
  // 详情页没有 SSR 渲染测试（要 mock 路由 + 异步取数，不划算），所以退一步做源码检查。
  // 抓的是「把那段解释删掉」这种回归 —— 用户点复制之前就该知道这个数字会怎么变。
  const src = readFileSync(`${ROOT}src/views/SkillDetailView.vue`, 'utf8')
  const block = /安装 -->([\s\S]*?)<div class="tabs">/.exec(src)
  assert.ok(block, '没找到安装区块')

  // ⚠️ 必须先剥掉注释再断言。这段代码附近就有解释「为什么不能直接摊在 flex 里」的注释，
  //    里面恰好写着「复制次数」—— 不剥的话，注释本身就能让下面的 /复制/ 永远为真，
  //    于是「把解释删掉」这种回归**照样绿**。
  //    （同类坑在 SSR 渲染测试里也踩过一次：模板注释会被渲染进 HTML。）
  const code = block[1].replace(/<!--[\s\S]*?-->/g, '')

  assert.ok(
    code.includes('metricNotes.installs'),
    '安装区应该引用 metricNotes.installs 而不是自己写一段口径说明',
  )
  assert.match(code, /复制次数/, '安装区必须说清楚这个数字数的是复制次数')
})

/* --------------------------------------------------- 防止两处各写一份 */

test('卡片与详情页都从 @/lib/time 取时间函数，不各写一份', () => {
  const files = {
    'SkillCard.vue': readFileSync(`${ROOT}src/components/SkillCard.vue`, 'utf8'),
    'SkillDetailView.vue': readFileSync(`${ROOT}src/views/SkillDetailView.vue`, 'utf8'),
  }
  for (const [name, src] of Object.entries(files)) {
    assert.ok(src.includes("from '@/lib/time'"), `${name} 应该从 @/lib/time 导入时间函数`)
    assert.ok(
      !/function\s+relativeTime\s*\(/.test(src),
      `${name} 里不该再有 relativeTime 的本地实现 —— 两处各写一份迟早会漂移`,
    )
  }
})
