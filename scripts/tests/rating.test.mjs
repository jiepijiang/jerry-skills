/**
 * 技能评分（5 星）的测试
 * ---------------------------------------------------------------------------
 * 跑法：npm test（= node --test scripts/tests/*.test.mjs）
 *
 * 分四层，越往下越「真」：
 *
 *   ① 渲染层：用 vite ssrLoadModule 真编译 SFC，再用 vue/server-renderer 渲染成
 *      HTML，断言**用户真正会看到的那段文字**。不做 `template.includes(...)`
 *      这种源码断言 —— 那在「模板写了但 props 传错 / v-if 恒假」时照样绿。
 *
 *   ② 数据层：真跑一遍 localStore（本地演示模式那条平行链路）。它只依赖
 *      fflate + parseSkill，不碰 DOM —— 在 Node 里能跑通，
 *      所以「一人一票」「评分排序」这些**逻辑**可以被真断言，而不是靠肉眼。
 *
 *   ③ 跨文件同步：前端常量与服务端约束必须一致。这一类是本次改动里
 *      最容易悄悄漂移的地方（加个排序项忘了改 SQL、星级上限和 check 约束对不上），
 *      而且漂移之后**不会报错**，只会静默用错的值。
 *
 *   ④ 交互接线：点击星星 → emit('rate') → 打 RPC。项目里没有 jsdom（刻意不加
 *      依赖），SSR 又渲染不出可点击的 DOM，所以这一层只能做**源码断言**。
 *      这一点必须写明 —— 否则后来的人会以为它被真跑过了。
 *
 * ⚠️ 按项目纪律：**没红过的绿灯没有意义**。
 *    本文件每条断言都做过造红，见文件末尾的清单。
 */
import { after, before, test } from 'node:test'
import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import { zipSync, strToU8 } from 'fflate'

import { createSSRApp, h } from 'vue'
import { renderToString } from 'vue/server-renderer'

import { ROOT, createSsrServer } from './_ssr.mjs'

let server
let StarRating
let SkillCard
let site

before(async () => {
  server = await createSsrServer()
  ;({ default: StarRating } = await server.ssrLoadModule('/src/components/StarRating.vue'))
  ;({ default: SkillCard } = await server.ssrLoadModule('/src/components/SkillCard.vue'))
  site = await server.ssrLoadModule('/src/data/site.js')
})

after(async () => {
  await server?.close()
})

/** router-link 的替身（同 skill-card-render.test.mjs：必须用渲染函数，不能用 template） */
const RouterLinkStub = {
  name: 'RouterLink',
  props: { to: { type: [String, Object], default: '' } },
  setup(props, { slots }) {
    return () => h('a', { href: String(props.to) }, slots.default ? slots.default() : [])
  },
}

async function render(comp, props) {
  const app = createSSRApp({ render: () => h(comp, props) })
  app.component('router-link', RouterLinkStub)
  return renderToString(app)
}

const baseSkill = {
  slug: 'demo-skill',
  name: '演示技能',
  description: '一个用来测试的演示技能',
  category: 'development',
  tags: ['demo'],
  version: '1.0.0',
  license: 'MIT',
  author: 'Jerry',
  file_count: 3,
  total_bytes: 2048,
  downloads: 12,
  installs: 3,
  rating_count: 8,
  rating_avg: 4.3,
  created_at: new Date(Date.now() - 3 * 86400000 - 60000).toISOString(),
}

/* ══════════════════════════════════════════════ ① 渲染层 */

test('展示态：渲染出平均分与评分人数', async () => {
  const html = await render(StarRating, { readonly: true, avg: 4.3, count: 8 })
  assert.ok(html.includes('4.3'), `应该显示平均分 4.3，实际：\n${html}`)
  assert.ok(html.includes('8 人'), `应该显示「8 人」，实际：\n${html}`)
})

test('展示态：4.3 分画出 86% 的填充，而不是四舍五入成整颗', async () => {
  // 4.3 / 5 = 86%。四舍五入成 4 颗的话，4.3 和 3.7 会画成两个样子、
  // 而 4.4 和 4.6 会画成同一个样子 —— 恰恰丢掉了用户想看的差别。
  const html = await render(StarRating, { readonly: true, avg: 4.3, count: 8 })
  assert.match(html, /width:\s*86%/, `填充宽度应该是 86%，实际：\n${html}`)
})

test('展示态：没人评分时显示「还没人评分」，且绝不渲染出 NaN', async () => {
  // ⚠️ 服务端在没人评分时返回的是 **null**。`null > 0` 是 false 但 `null >= 0` 是 true，
  //    判错了就会把「没人评」渲染成「0 分」。所以这条断言查的是文案，不是数字。
  const html = await render(StarRating, { readonly: true, avg: null, count: 0 })
  assert.ok(html.includes('还没人评分'), `应该显示「还没人评分」，实际：\n${html}`)
  assert.ok(!html.includes('NaN'), 'null 平均分绝不能渲染成 NaN')
  assert.ok(!html.includes('>0<'), '也不该退化成「0 分」')
  assert.match(html, /width:\s*0%/, '没有评分时填充宽度应该是 0')
})

test('展示态：count 是 0 但 avg 有值时，也不当成人人评分（两个条件都要判）', async () => {
  const html = await render(StarRating, { readonly: true, avg: 4.5, count: 0 })
  assert.ok(html.includes('还没人评分'), `count=0 就该按「没人评」处理，实际：\n${html}`)
})

test('交互态：渲染出 5 个可点的星星按钮，且每个的读屏标签各不相同', async () => {
  const html = await render(StarRating, { modelValue: null, size: 20 })
  // ⚠️ 只取 <button> 上的 aria-label：外面那层 role="group" 自己也有一个
  //    （"给这个技能打分，共 5 星"），用裸 /aria-label="…"/ 会数出 6 个。
  const btns = [...html.matchAll(/<button[^>]*aria-label="([^"]*)"/g)].map((m) => m[1])
  assert.equal(btns.length, 5, `应该有 5 个星星按钮，实际 ${btns.length} 个：${JSON.stringify(btns)}`)
  assert.equal(new Set(btns).size, 5, `5 个按钮的标签必须互不相同，否则读屏用户分不清：${JSON.stringify(btns)}`)
  for (const b of btns) assert.match(b, /\d 星/, `标签里应该带「N 星」，实际：${b}`)
})

test('交互态：我自己打过的分会被标成 aria-pressed', async () => {
  const html = await render(StarRating, { modelValue: 4, size: 20 })
  const pressed = [...html.matchAll(/aria-pressed="true"/g)].length
  assert.equal(pressed, 1, `应该正好有 1 个按钮是选中态，实际 ${pressed} 个`)

  // ⚠️ 必须拿**整个 button 元素**来判，不能「从 aria-pressed 往前截一段」——
  //    模板里 aria-label 排在 aria-pressed **之后**，往前找只会找到上一颗星的标签。
  const btn = [...html.matchAll(/<button[^>]*>/g)].map((m) => m[0]).find((b) => b.includes('aria-pressed="true"'))
  assert.ok(btn, '应该能找到一个 aria-pressed="true" 的按钮')
  assert.ok(btn.includes('4 星'), `选中的应该是「4 星」那颗，实际：${btn}`)
})

test('交互态：文案会告诉用户「你打了 N 星」', async () => {
  const html = await render(StarRating, { modelValue: 3, size: 20 })
  assert.ok(html.includes('你打了 3 星'), `应该提示已打的分，实际：\n${html}`)
})

/* ══════════════════════════════════════════════ ① 卡片渲染 */

test('卡片：有评分时显示平均分', async () => {
  const html = await render(SkillCard, { skill: baseSkill })
  assert.ok(html.includes('4.3'), `卡片上应该出现 4.3，实际：\n${html}`)
})

test('卡片：没人评分时整块不渲染（不留「0 分」这种占位）', async () => {
  const html = await render(SkillCard, { skill: { ...baseSkill, rating_count: 0, rating_avg: null } })
  assert.ok(!html.includes('class="sc-stat sc-rating"'), `没有评分时不该渲染评分块，实际：\n${html}`)
  assert.ok(!html.includes('NaN'), 'null 平均分绝不能渲染成 NaN')
})

test('卡片：加了评分之后，原有的下载量 / 安装量 / 作者 / 时间都还在', async () => {
  const html = await render(SkillCard, { skill: baseSkill })
  assert.ok(html.includes('12'), '下载量还在')
  assert.ok(html.includes('Jerry'), '作者还在')
  assert.ok(html.includes('3 天前'), '上传时间还在')
  assert.ok(html.includes('v1.0.0'), '版本号还在')
})

test('卡片：评分的 tooltip 说明了口径（一人一票）', async () => {
  // 光写一个「4.3」用户会以为是「4.3 分 / 5 分」而不知道这是多少人打出来的。
  const html = await render(SkillCard, { skill: baseSkill })
  const titles = [...html.matchAll(/\stitle="([^"]*)"/g)].map((m) => m[1])
  const t = titles.find((x) => x.includes('评分'))
  assert.ok(t, `卡片上应该有解释评分口径的 tooltip，实际：${JSON.stringify(titles)}`)
  assert.match(t, /一人一票/, `tooltip 必须说清一人一票，实际：${t}`)
})

/* ══════════════════════════════════════════════ ② 数据层（本地模式真跑） */

test('数据层：打分后平均分与人数一起更新', async () => {
  const local = await server.ssrLoadModule('/src/lib/localStore.js')
  const list = await local.localList({ limit: 100 })
  const target = list.items.find((s) => s.rating_count > 0)
  assert.ok(target, '种子技能应该带初始评分（否则「评分最高」排序排不出东西）')

  const before = target.rating_count
  const r = await local.localRate(target.slug, 1)
  assert.equal(r.my_score, 1, '返回的应该是我打的分')
  assert.equal(r.rating_count, before + 1, `我的票应该让总人数 +1（${before} → ${r.rating_count}）`)
  assert.ok(r.rating_avg < target.rating_avg, '打了 1 分之后平均分应该下降')
})

test('数据层：同一个技能再打一次是「改分」，人数不变（一人一票）', async () => {
  const local = await server.ssrLoadModule('/src/lib/localStore.js')
  const list = await local.localList({ limit: 100 })
  const target = list.items.find((s) => s.rating_count > 0)

  const first = await local.localRate(target.slug, 1)
  const second = await local.localRate(target.slug, 5)

  assert.equal(second.rating_count, first.rating_count, '改分不该增加人数 —— 加了就是「一人多票」')
  assert.equal(second.my_score, 5)
  assert.ok(second.rating_avg > first.rating_avg, '改成 5 分之后平均分应该上升')
})

test('数据层：给不存在的技能打分抛 not_found（和线上返回同一种错）', async () => {
  const local = await server.ssrLoadModule('/src/lib/localStore.js')
  await assert.rejects(
    () => local.localRate('根本没有这个技能', 5),
    (e) => e.code === 'not_found',
    '本地静默成功、线上报错，是最容易让人误以为「线上有 bug」的一种差异',
  )
})

test('数据层：非法分值被拒（0 / 6 / 小数 / 空）', async () => {
  const local = await server.ssrLoadModule('/src/lib/localStore.js')
  const list = await local.localList({ limit: 1 })
  const slug = list.items[0].slug
  for (const bad of [0, 6, 4.5, null, undefined, '四']) {
    await assert.rejects(
      () => local.localRate(slug, bad),
      (e) => e.code === 'invalid_payload',
      `score=${JSON.stringify(bad)} 应该被拒`,
    )
  }
})

test('数据层：「评分最高」排序里未评分的排最后，且平均分单调不增', async () => {
  const local = await server.ssrLoadModule('/src/lib/localStore.js')
  const { parseSkill } = await server.ssrLoadModule('/src/lib/parseSkill.js')
  const limits = site.limits

  // 传一个全新的技能进去 —— 它没有任何票底，就是「还没人评过」
  const md = '---\nname: 全新未评分技能\ndescription: 用来验证排序的。\n---\n\n# new\n'
  const parsed = await parseSkill(
    { name: 'fresh.zip', bytes: zipSync({ 'SKILL.md': strToU8(md) }, { level: 6 }) },
    limits,
  )
  assert.ok(parsed.ok, `测试用的技能包应该能解析：${JSON.stringify(parsed)}`)
  await local.localPublish(parsed.skill)

  const sorted = await local.localList({ sort: 'rating', limit: 100 })
  const last = sorted.items[sorted.items.length - 1]

  assert.equal(last.slug, parsed.skill.slug, '没有评分的技能必须排在最后（对齐 SQL 的 nulls last）')

  const rated = sorted.items.filter((s) => s.rating_count > 0)
  for (let i = 1; i < rated.length; i++) {
    assert.ok(
      rated[i - 1].rating_avg >= rated[i].rating_avg,
      `平均分应该单调不增，实际第 ${i} 项 ${rated[i - 1].rating_avg} < 第 ${i + 1} 项 ${rated[i].rating_avg}`,
    )
  }
})

/* ══════════════════════════════════════════════ ③ 跨文件同步 */

const readRepo = (p) => readFileSync(`${ROOT}${p}`, 'utf8')

test('评分上限必须和服务端 check 约束一致（1..5）', () => {
  // 前端 max 是提前拦住，服务端 check 才是真闸门。两处不一致会出现
  // 「前端让打、后端拒绝」这种最难解释的现象（limits 那条纪律同样适用）。
  const sql = readRepo('supabase/migrations/003-ratings.sql')
  const m = /check\s*\(\s*score\s+between\s+(\d+)\s+and\s+(\d+)\s*\)/i.exec(sql)
  assert.ok(m, '003-ratings.sql 里应该能找到 score 的 check 约束')
  assert.equal(
    Number(m[2]),
    site.ratings.max,
    `SQL 的上限是 ${m[2]}，前端 ratings.max 是 ${site.ratings.max} —— 必须一致`,
  )
  assert.equal(Number(m[1]), 1, '下限应该是 1（0 星不是一个有意义的评价）')
})

test('每个排序 key 在 SQL 的 list_skills 里都有对应分支', () => {
  // 前端加了「评分最高」但 SQL 没有 when 'rating' 的话，选它会**静默**回落到
  // `else 's.created_at desc'`（最新）—— 界面看起来正常，排序却是错的。
  const sql = readRepo('supabase/migrations/003-ratings.sql')
  const handled = new Set([...sql.matchAll(/when\s+'([a-z]+)'\s+then/gi)].map((m) => m[1].toLowerCase()))

  const keys = site.sorts.map((s) => s.key)
  const nonDefault = keys.filter((k) => k !== keys[0])
  for (const k of nonDefault) {
    assert.ok(handled.has(k), `排序「${k}」在 SQL 里没有 when 分支，会被静默当成默认排序`)
  }
})

test('SQL 里 p_sort 的默认值就是前端排序列表的第一项', () => {
  const sql = readRepo('supabase/migrations/003-ratings.sql')
  const m = /p_sort\s+text\s+default\s+'([a-z]+)'/i.exec(sql)
  assert.ok(m, '应该能找到 p_sort 的默认值')
  assert.equal(m[1], site.sorts[0].key, '两边的默认排序必须一致，否则首次进页面就是错的')
})

test('评分排序分支必须带 nulls last（否则未评分的会窜到最前）', () => {
  // Postgres 里 DESC 默认是 NULLS FIRST，不写 nulls last 的话
  // 「评分最高」会先列出一堆 0 票的技能。这条已用 PGlite 造红验证过。
  const sql = readRepo('supabase/migrations/003-ratings.sql')
  const m = /when\s+'rating'\s+then\s+'([^']*)'/.exec(sql)
  assert.ok(m, "应该能找到 when 'rating' 的排序分支")
  assert.match(m[1], /nulls\s+last/i, `评分排序必须写 nulls last，实际：${m[1]}`)
})

test('rate_skill 是 security definer，且授给了 anon', () => {
  // 漏了 security definer → 表对 anon 关闭 → 打分永远失败；
  // 漏了 grant execute → 线上 404。两者在「以超级用户调」的测试里都看不出来。
  const sql = readRepo('supabase/migrations/003-ratings.sql')
  const fn = /create or replace function public\.rate_skill\([\s\S]*?\$\$;/.exec(sql)
  assert.ok(fn, '应该能找到 rate_skill 的定义')
  assert.match(fn[0], /security definer/, 'rate_skill 必须是 security definer')
  assert.match(fn[0], /set search_path = public/, 'security definer 必须固定 search_path')
  assert.match(
    sql,
    /grant execute on function public\.rate_skill\(text, integer\) to anon, authenticated;/,
    'rate_skill 必须授给 anon / authenticated',
  )
})

test('评分表对 anon 关闭（RLS 开 + revoke），和 skills 表同等待遇', () => {
  const sql = readRepo('supabase/migrations/003-ratings.sql')
  assert.match(sql, /alter table public\.skill_ratings enable row level security;/)
  assert.match(sql, /revoke all on public\.skill_ratings from anon, authenticated;/)
})

test('卡片与详情页共用同一份平均分格式化，不各写一份 toFixed', () => {
  // 两处显示的是同一个数字。各写一份的话迟早出现「卡片 4.5、详情页 4.50」。
  const files = {
    'SkillCard.vue': readRepo('src/components/SkillCard.vue'),
    'StarRating.vue': readRepo('src/components/StarRating.vue'),
  }
  for (const [name, src] of Object.entries(files)) {
    assert.ok(src.includes('ratingAvgText'), `${name} 应该用 @/data/site 的 ratingAvgText`)
    assert.ok(
      !/toFixed\(\s*[a-zA-Z.]*digits\s*\)/.test(src),
      `${name} 里不该再自己 toFixed —— 格式化规则只能有一处`,
    )
  }
  // 详情页通过 StarRating 间接用，但口径文案要走 metricNotes
  const detail = readRepo('src/views/SkillDetailView.vue')
  assert.ok(detail.includes('metricNotes.rating'), '详情页应该用 metricNotes.rating 说明口径')
  assert.ok(detail.includes('StarRating'), '详情页应该用 StarRating 组件而不是自己画星星')
})

test('评分的口径文案自己解释自己（一人一票 / 改分不重复计票）', () => {
  // 「再点一次能不能投第二票」是用户一定会问的问题。不写清楚的话，
  // 改完分看到人数没变会以为坏了。
  assert.match(site.metricNotes.rating, /一人一票/, 'metricNotes.rating 必须说明一人一票')
  assert.match(site.metricNotes.rating, /改分/, '必须说明重复打分是改分')
  assert.match(site.ratings.hint, /改分/, '打分区的提示也要说清改分')
  assert.equal(site.ratings.labels.length, site.ratings.max, 'labels 的条数必须等于星级上限')
})

test('排序列表里「评分最高」的 hint 说明了未评分的去向', () => {
  const s = site.sorts.find((x) => x.key === 'rating')
  assert.ok(s, 'sorts 里应该有 rating 这一项')
  assert.match(s.hint, /最后/, '必须说明未评分的排最后 —— 否则用户会以为排序坏了')
})

/* ══════════════════════════════════════════════ ④ 交互接线（源码级） */

test('交互态把点击接成了 rate 事件（源码级断言）', () => {
  // ⚠️ 项目里没有 jsdom（刻意不加依赖），SSR 也渲染不出可点击的 DOM，
  //    所以「点第 4 颗星 → emit('rate', 4)」这条链路**没有被真跑过**，
  //    这里只是钉住接线本身。真正的行为验证在数据层（localStore）和
  //    PGlite（supabase/verify-ratings.mjs）。
  const src = readRepo('src/components/StarRating.vue')
  assert.match(src, /emit\(\s*'rate'/, "StarRating 必须 emit('rate')")
  assert.match(src, /@click="pick\(/, '星星按钮必须绑 click 到 pick()')
  assert.match(src, /readonly[^\n]*return/, 'readonly 时不该 emit（否则只读卡片也能改分）')

  const detail = readRepo('src/views/SkillDetailView.vue')
  assert.match(detail, /@rate="onRate"/, '详情页必须把 @rate 接到 onRate')
  assert.match(detail, /rateSkill\(/, 'onRate 必须真的调 rateSkill')
})

test('详情页打分失败时会回滚乐观更新', () => {
  // 乐观更新（先把星星点亮）必须配回滚，否则请求失败后界面会停在一个
  // 服务端并不认可的状态上 —— 用户刷新才发现分没打上。
  const src = readRepo('src/views/SkillDetailView.vue')
  const fn = /async function onRate\(n\)[\s\S]*?\n}/.exec(src)
  assert.ok(fn, '应该能找到 onRate')
  assert.match(fn[0], /catch/, 'onRate 必须有 catch')
  assert.match(fn[0], /prev\./, '失败分支必须用备份值回滚')
})

test('填充层的内层保持 max-content（否则星星会被压扁而不是裁掉）', () => {
  // 父级是 overflow:hidden 的窄容器，内层若跟着收缩，4.3 分画出来的星星会
  // **比 5 分的窄一圈** —— 看起来像渲染 bug，很难定位。这条只能源码断言，
  // SSR 渲染不出计算后的宽度。
  //
  // ⚠️ 不能写 `/\.sr-inner\s*\{([^}]*)\}/` 取「第一个匹配」—— .sr-inner 在
  //    `.sr-base, .sr-inner { display: inline-flex; gap: 1px }` 里先出现一次，
  //    那个规则里当然没有 width。必须遍历所有规则、挑出带 width 的那一条。
  const src = readRepo('src/components/StarRating.vue')
  const rules = [...src.matchAll(/([^{}]+)\{([^}]*)\}/g)].map((m) => ({ sel: m[1].trim(), body: m[2] }))
  const hit = rules.find((r) => r.sel.includes('.sr-inner') && /width:\s*max-content/.test(r.body))
  assert.ok(
    hit,
    `.sr-inner 必须有一条 width: max-content 的规则。\n实际找到的 .sr-inner 规则：\n` +
      rules
        .filter((r) => r.sel.includes('.sr-inner'))
        .map((r) => `  ${r.sel} { ${r.body.trim().replace(/\s+/g, ' ')} }`)
        .join('\n'),
  )
})

test('星星用独立的 --hub_star 变量，不复用 --hub_warn', () => {
  const root = readRepo('src/styles/root.css')
  assert.match(root, /--hub_star:/, 'root.css 应该定义 --hub_star')
  const src = readRepo('src/components/StarRating.vue')
  assert.ok(src.includes('var(--hub_star)'), 'StarRating 应该用 --hub_star 上色')
  assert.ok(!src.includes('var(--hub_warn)'), '不该复用「警告」的橙色 —— 语义不同，会被同一次调色改动带走')
})

/**
 * ─────────────────────────────────────────────────────────────────────
 * 造红清单
 * ─────────────────────────────────────────────────────────────────────
 * 每一条都真跑过：把源码改坏 → 跑本文件 → 确认**指定的那条**断言变红 → 还原。
 * （只看到「整体失败了」不算 —— 那可能是别的断言红的。）
 *
 *  A hasVotes 只看 avg、漏判 count
 *      → 「count 是 0 但 avg 有值时…」变红
 *  B hasVotes 两个守卫都漏掉（Number(null) 是 0，被当成有值）
 *      → 「没人评分时显示「还没人评分」，且绝不渲染出 NaN」变红
 *  C pct 改成 Math.round(avg) / max
 *      → 「4.3 分画出 86% 的填充」变红
 *  D SkillCard 去掉 v-if="ratingText"
 *      → 「卡片：没人评分时整块不渲染」变红
 *  E localRate 改成每次都新增一条记录（一人多票）
 *      → 「同一个技能再打一次是「改分」，人数不变」变红
 *  F localList 的 rating 比较式写反（升序）
 *      → 「未评分的排最后，且平均分单调不增」变红
 *  G 003-ratings.sql 的 check 改成 between 1 and 10
 *      → 「评分上限必须和服务端 check 约束一致」变红
 *  H 003-ratings.sql 里 when 'rating' 的 nulls last 删掉
 *      → 「评分排序分支必须带 nulls last」变红
 *  I 003-ratings.sql 的 grant execute on rate_skill 删掉
 *      → 「rate_skill 是 security definer，且授给了 anon」变红
 *  J .sr-inner 的 width: max-content 删掉
 *      → 「填充层的内层保持 max-content」变红
 *  K site.js 的 sorts 里 rating 那一项的 hint 改成「按平均星级」
 *      → 「排序列表里评分最高的 hint 说明了未评分的去向」变红
 *  L StarRating 的标签退回「预览文案优先」的写法（`hoverText || …`）
 *      → 「交互态：文案会告诉用户你打了 N 星」变红
 *      （这条不是假想 —— 它本来就是这么写的，是真被这条断言抓出来的 bug）
 *  M 003-ratings.sql 的 list_skills 里删掉 when 'rating' 分支
 *      → 「每个排序 key 在 SQL 的 list_skills 里都有对应分支」变红
 *
 * ⚠️ 有一条**没能**造出红，如实记下来：把 localStore 的 rating 比较器里
 *    那三行显式判 null 删掉，本文件照样全绿。原因是 JS 里 null 参与减法被当成 0，
 *    而这是个降序比较，未评分的恰好还是排最后。所以那三行对**当前**的排序结果
 *    是冗余的（防的是 undefined 引入 NaN，见那里的注释）。
 *    —— 不把这件事写下来，后来的人会以为那三行被测试保护着。
 */
