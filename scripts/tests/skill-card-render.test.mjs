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
import { fileURLToPath } from 'node:url'

import { createServer } from 'vite'
import { createSSRApp, h } from 'vue'
import { renderToString } from 'vue/server-renderer'

const ROOT = fileURLToPath(new URL('../..', import.meta.url))

let server
let SkillCard

before(async () => {
  server = await createServer({
    root: ROOT,
    logLevel: 'error',
    appType: 'custom',
    server: { middlewareMode: true, hmr: false, watch: null },
  })
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
