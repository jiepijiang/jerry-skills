/**
 * 站主删除功能
 * ---------------------------------------------------------------------------
 * 跑法：npm test
 *
 * 这个功能的失败模式都很安静，所以断言要挑得准：
 *   · 没解锁却渲染出删除按钮  → 每个访客都能看到「这里能删东西」
 *   · 解锁了却没渲染出来      → 站主自己用不了
 *   · RPC 参数名和 SQL 不一致 → PostgREST 按**名字**匹配，线上表现为 404，
 *                               而界面上会显示成「口令怎么都不对」，极难查
 *   · 图标名拼错              → AppIcon 兜底成空 paths，按钮变成一片空白，不报错
 *   · 忘了 grant execute      → 线上 404，本地无感
 *
 * ⚠️ 按项目纪律：**没红过的绿灯没有意义**。每条断言都做过造红（见 README）。
 */
import { after, before, test } from 'node:test'
import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'

import { createServer } from 'vite'
import { createSSRApp, h } from 'vue'
import { renderToString } from 'vue/server-renderer'

const ROOT = fileURLToPath(new URL('../..', import.meta.url))

const read = (p) => readFileSync(`${ROOT}${p}`, 'utf8')
const SQL = read('supabase/migrations/002-admin-delete.sql')
const API = read('src/lib/skills-api.js')

let server
let SkillCard
let admin

before(async () => {
  server = await createServer({
    root: ROOT,
    logLevel: 'error',
    appType: 'custom',
    server: { middlewareMode: true, hmr: false, watch: null },
  })
  ;({ default: SkillCard } = await server.ssrLoadModule('/src/components/SkillCard.vue'))
  admin = await server.ssrLoadModule('/src/lib/admin.js')
})

after(async () => {
  await server?.close()
})

const RouterLinkStub = {
  name: 'RouterLink',
  props: { to: { type: [String, Object], default: '' } },
  setup(props, { slots }) {
    return () => h('a', { href: String(props.to) }, slots.default ? slots.default() : [])
  },
}

async function renderCard(skill) {
  const app = createSSRApp({ render: () => h(SkillCard, { skill }) })
  app.component('router-link', RouterLinkStub)
  return renderToString(app)
}

const SKILL = {
  slug: 'demo-skill',
  name: '演示技能',
  description: '一个用来测试的演示技能',
  category: 'development',
  tags: ['demo'],
  version: '1.2.0',
  license: 'MIT',
  author: 'Jerry',
  file_count: 3,
  total_bytes: 2048,
  downloads: 12,
  installs: 3,
  created_at: new Date(Date.now() - 3 * 86400000).toISOString(),
}

/* ══════════════ 1. 口令的存取 ══════════════ */

test('未解锁时 isAdmin 为假', () => {
  admin.clearAdminToken()
  assert.equal(admin.isAdmin.value, false)
})

test('setAdminToken 之后 isAdmin 为真，clear 之后又变假', () => {
  admin.setAdminToken('some-token')
  assert.equal(admin.isAdmin.value, true)
  assert.equal(admin.adminToken.value, 'some-token')

  admin.clearAdminToken()
  assert.equal(admin.isAdmin.value, false)
  assert.equal(admin.adminToken.value, '')
})

test('Node 里没有 sessionStorage 也不会炸（降级成只存内存）', () => {
  // 这条同时钉住「SSR 渲染测试跑得起来」这件事：admin.js 是模块顶层求值，
  // 一旦 sessionStorage 被裸引用，任何 import 到它的组件都加载不了。
  assert.equal(typeof globalThis.sessionStorage, 'undefined', '这个测试假设没有 sessionStorage')
  admin.setAdminToken('x')
  assert.equal(admin.isAdmin.value, true)
  admin.clearAdminToken()
})

/* ══════════════ 2. 按钮的显隐 ══════════════ */

test('★ 未解锁时卡片上没有任何删除入口', async () => {
  admin.clearAdminToken()
  const html = await renderCard(SKILL)
  assert.ok(!html.includes('sc-del'), `未解锁不该渲染删除按钮，实际 HTML：\n${html}`)
  assert.ok(!html.includes('确认删除'), '未解锁更不该渲染确认弹窗')
})

test('★ 解锁后卡片上出现删除按钮', async () => {
  admin.setAdminToken('some-token')
  try {
    const html = await renderCard(SKILL)
    assert.ok(html.includes('sc-del'), `解锁后应该出现删除按钮，实际 HTML：\n${html}`)
    assert.match(html, /aria-label="删除 演示技能"/, '按钮要有可读的无障碍标签')
  } finally {
    admin.clearAdminToken()
  }
})

test('删除按钮在 <a> 的**外面**（<button> 嵌在 <a> 里是非法嵌套）', async () => {
  admin.setAdminToken('some-token')
  try {
    const html = await renderCard(SKILL)
    const closeA = html.indexOf('</a>')
    const del = html.indexOf('sc-del')
    assert.ok(closeA > -1, '卡片里应该有链接')
    assert.ok(del > closeA, `删除按钮必须排在 </a> 之后，实际 closeA=${closeA} del=${del}`)
  } finally {
    admin.clearAdminToken()
  }
})

test('解锁后卡片原有的内容一样都不少', async () => {
  admin.setAdminToken('some-token')
  try {
    const html = await renderCard(SKILL)
    for (const want of ['演示技能', 'v1.2.0', 'Jerry', '3 天前', '12']) {
      assert.ok(html.includes(want), `解锁后卡片上应该还有「${want}」`)
    }
  } finally {
    admin.clearAdminToken()
  }
})

/* ══════════════ 3. 跨文件一致性（JS ↔ SQL） ══════════════ */

/** 从 SQL 里取某个函数的参数名 */
function sqlParams(fnName) {
  const m = new RegExp(`create or replace function public\\.${fnName}\\s*\\(([^)]*)\\)`, 'i').exec(SQL)
  assert.ok(m, `002 迁移里找不到函数 ${fnName}`)
  return m[1]
    .split(',')
    .map((s) => s.trim().split(/\s+/)[0])
    .filter(Boolean)
    .sort()
}

/** 从 skills-api.js 里取某个 rpc 调用传的参数名 */
function jsParams(fnName) {
  const m = new RegExp(`rpc\\('${fnName}',\\s*\\{([\\s\\S]*?)\\}`).exec(API)
  assert.ok(m, `skills-api.js 里找不到 rpc('${fnName}', …)`)
  return [...m[1].matchAll(/(p_[a-z_]+)\s*:/g)].map((x) => x[1]).sort()
}

test('★★ adminDelete 的参数名和 SQL 签名逐字一致（否则线上是 404）', () => {
  assert.deepEqual(jsParams('skill_admin_delete'), sqlParams('skill_admin_delete'))
})

test('★★ adminCheck 的参数名和 SQL 签名逐字一致', () => {
  assert.deepEqual(jsParams('skill_admin_check'), sqlParams('skill_admin_check'))
})

test('★ 两个 RPC 都 grant 给了 anon —— 忘了这句线上就是 404，本地毫无感觉', () => {
  for (const [fn, sig] of [
    ['skill_admin_check', 'text'],
    ['skill_admin_delete', 'text, text'],
  ]) {
    assert.ok(
      SQL.includes(`grant execute on function public.${fn}(${sig}) to anon, authenticated;`),
      `${fn} 缺少 grant execute`,
    )
  }
})

test('内部函数必须 revoke，不能被 anon 当口令预言机', () => {
  for (const fn of ['_skill_admin_ok', '_skill_admin_gate', '_skill_admin_log']) {
    assert.match(
      SQL,
      new RegExp(`revoke all on function public\\.${fn}\\([^)]*\\) from public, anon, authenticated;`),
      `${fn} 缺少 revoke`,
    )
  }
})

test('三张新表都开了 RLS 并对 anon revoke', () => {
  for (const t of ['skill_admin_config', 'skill_admin_log', 'skills_trash']) {
    // ⚠️ 用 \s+ 而不是字面空格：SQL 里这几行是**对齐排版的**，
    //    表名长短不同，中间的空格数就不一样。
    assert.match(SQL, new RegExp(`alter table public\\.${t}\\s+enable row level security;`), `${t} 没开 RLS`)
    assert.match(SQL, new RegExp(`revoke all on public\\.${t}\\s+from anon, authenticated;`), `${t} 没 revoke`)
  }
})

test('口令哈希算法在前端可见的两处表述一致（sha256(盐||口令)，UTF-8）', () => {
  // 迁移里的校验和设口令脚本必须逐字同款，否则设完就登不上。
  // 这条断言抓的是「改了其中一处」这种回归 —— 那种错误在线上表现为
  // 「口令明明设对了却说不对」，而且没有任何报错线索。
  const setter = read('supabase/set-admin-token.sql')
  // 参数名带 schema 前缀（r.salt），所以字符集里必须允许点号
  const expr = (s) => /sha256\(\s*convert_to\(\s*([\w.]+)\s*\|\|\s*([\w.]+)\s*,\s*'UTF8'\s*\)\s*\)/.exec(s)
  const a = expr(SQL)
  const b = expr(setter)
  assert.ok(a, "002 里应该有 sha256(convert_to(盐 || 口令, 'UTF8'))")
  assert.ok(b, 'set-admin-token.sql 里应该有同款表达式')
  // 参数名不同（一个叫 r.salt/p_token，一个叫 v_salt/v_pass），但结构必须一样
  assert.equal(a[2], 'p_token')
  assert.equal(b[2], 'v_pass')
})

/* ══════════════ 4. 图标 ══════════════ */

test('★ 用到的图标名都真的存在（拼错会渲染成一片空白，不报错）', () => {
  const iconSrc = read('src/components/AppIcon.vue')
  const names = new Set([...iconSrc.matchAll(/^ {2}([a-zA-Z0-9_]+):/gm)].map((m) => m[1]))
  for (const n of ['trash', 'lock', 'shield', 'close']) {
    assert.ok(names.has(n), `AppIcon 里没有图标「${n}」`)
  }
})

test('卡片和详情页用到的图标名都在 AppIcon 里', () => {
  const iconSrc = read('src/components/AppIcon.vue')
  const names = new Set([...iconSrc.matchAll(/^ {2}([a-zA-Z0-9_]+):/gm)].map((m) => m[1]))
  for (const f of ['src/components/SkillCard.vue', 'src/views/SkillDetailView.vue', 'src/components/HubFooter.vue']) {
    const src = read(f)
    for (const m of src.matchAll(/<AppIcon[^>]*\sname="([a-z]+)"/g)) {
      assert.ok(names.has(m[1]), `${f} 用了不存在的图标「${m[1]}」`)
    }
  }
})

/**
 * 文案对象的「引用 vs 定义」一致性。
 *
 * 🔴 这条是**真实踩过**才加的：确认按钮上写的是 `adminNotes.confirmDelete`，
 *    而 site.js 里定义的 key 叫 `deleteConfirm` —— 一个字母的顺序之差。
 *    Vue 对 undefined 的插值**不报错**，只是渲染成空字符串，于是那个按钮
 *    变成一颗纯红色药丸、上面一个字都没有。单测全绿、构建全绿、连
 *    浏览器功能测试也全绿（按钮照样能点、删得掉），**只有看截图才发现**。
 */
test('★ 模板里引用的 adminNotes / metricNotes 的 key 都真的定义了', async () => {
  const site = await server.ssrLoadModule('/src/data/site.js')
  const files = [
    'src/components/SkillCard.vue',
    'src/components/HubFooter.vue',
    'src/views/SkillDetailView.vue',
    'src/views/HomeView.vue',
  ]

  const problems = []
  for (const objName of ['adminNotes', 'metricNotes']) {
    const obj = site[objName]
    assert.ok(obj && typeof obj === 'object', `site.js 应该导出 ${objName}`)
    for (const f of files) {
      const src = read(f)
      for (const m of src.matchAll(new RegExp(`${objName}\\.([a-zA-Z0-9_]+)`, 'g'))) {
        const key = m[1]
        const val = obj[key]
        if (typeof val !== 'string' || val.trim() === '') {
          problems.push(`${f}: ${objName}.${key} → ${val === undefined ? '未定义' : JSON.stringify(val)}`)
        }
      }
    }
  }
  assert.deepEqual(problems, [], `有引用指向未定义（或为空）的文案 key：\n  ${problems.join('\n  ')}`)
})

test('确认按钮的文案不是空的（曾经因为 key 写错渲染成一颗空红药丸）', () => {
  const src = read('src/components/SkillCard.vue') + read('src/views/SkillDetailView.vue')
  const hits = [...src.matchAll(/adminNotes\.confirmDelete/g)]
  assert.ok(hits.length >= 2, '两个删除入口的确认按钮都该用 adminNotes.confirmDelete')
})

/* ══════════════ 5. 界面接线 ══════════════ */

test('详情页的删除按钮同样受 isAdmin 控制', () => {
  const src = read('src/views/SkillDetailView.vue')
  assert.match(src, /v-if="isAdmin"/, '详情页的删除按钮必须有 v-if="isAdmin"')
  assert.ok(src.includes('adminNotes.deleteButton'), '按钮文案走 adminNotes')
})

test('首页把卡片的 deleted 事件接上了（否则删完卡片还杵在那儿）', () => {
  const src = read('src/views/HomeView.vue')
  assert.match(src, /<SkillCard[^>]*@deleted="onDeleted"/, 'SkillCard 必须监听 deleted')
  assert.match(src, /items\.value\s*=\s*items\.value\.filter\(/, 'onDeleted 要真的把那条从列表里去掉')
})

test('两个删除入口都走同一份 useSkillDelete，不各写一份错误处理', () => {
  for (const f of ['src/components/SkillCard.vue', 'src/views/SkillDetailView.vue']) {
    const src = read(f)
    assert.ok(src.includes('useSkillDelete'), `${f} 应该用 @/composables/useAdmin 的 useSkillDelete`)
    assert.ok(
      !/adminDelete\s*\(/.test(src),
      `${f} 不该直接调 adminDelete —— 口令失效 / 已删除这两种失败的处理会各写一份`,
    )
  }
})
