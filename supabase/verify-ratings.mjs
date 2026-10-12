/**
 * 用 PGlite（WASM Postgres）真跑一遍 003-ratings.sql
 * ===========================================================================
 * 怎么跑
 * ---------------------------------------------------------------------------
 * 和 verify-migration.mjs 一样，本脚本**不进项目依赖**（PGlite 带 ~10MB WASM），
 * 手动装在隔离工作区里跑：
 *
 *   cd ~/.workbuddy-ai/binaries/node/workspace
 *   cp <repo>/supabase/verify-ratings.mjs .
 *   node verify-ratings.mjs
 *
 * （ESM 的裸导入按**脚本自身路径**解析，不认 NODE_PATH / cwd，所以必须复制过去。）
 *
 * 造红（验证这套检查本身有没有判别力）：
 *
 *   RATINGS_SQL_DIR=/path/to/被改坏的副本 node verify-ratings.mjs
 *
 * 已做过的两次造红，均如期变红：
 *   A 把 `on conflict (slug, ip) do update` 改成 `do nothing` → 「同 IP 改分」
 *     那两条变红（人数变成 2、平均分不再是 3）
 *   B 把排序里的 `nulls last` 删掉 → 「未评分排最后」那条变红
 *
 * ---------------------------------------------------------------------------
 * 要回答的问题：
 *   1. 003 能不能在 001 之上干净地跑起来、并且可重复执行（幂等）？
 *   2. 「一人一票、改分不加票」真的成立吗？（还是说每次打分都插了新行）
 *   3. 非法分值 / 不存在的技能，是被**业务拒绝**（200 + code），还是抛 500？
 *   4. 「评分最高」排序里，未评分的技能会不会被排到最前面？
 *   5. 删掉技能之后，评分行会不会留下来变成孤儿（然后被后来的同名技能继承）？
 *   6. anon 能不能绕过 RPC 直接读写评分表？
 *
 * ⚠️ 替身环境的局限（写清楚，免得自我安慰）
 * ---------------------------------------------------------------------------
 * (a) Supabase 的 anon / authenticated 在 PGlite 里不存在，得手动建。
 * (b) 🔴 **必须模拟 Supabase 的 default privileges**：真实 Supabase 上
 *     `public` schema 配了 `alter default privileges ... grant all on tables to
 *     anon, authenticated`，所以新表一建出来 anon **是**有 SELECT 的，
 *     随后被迁移的 `revoke all` 收走 → 生产环境表现为 `permission denied`。
 *     不模拟这一步，就会把「anon 本来就无权限」误当成「revoke 生效」。
 * (c) 🔴 **RPC 必须以 anon 身份调**。以超级用户调的话，就算函数漏了
 *     `security definer` 或漏了 `grant execute`，这里照样全绿、线上全挂。
 * (d) 「IP」是靠 `set_config('request.headers', …)` 伪造的 —— 这正是生产环境里
 *     客户端能自己塞 x-forwarded-for 的那条路径。所以本脚本能验「一人一票的
 *     机制对不对」，但**验不了「它防得住伪造」**（它防不住，这是设计上写明的局限）。
 */
import { PGlite } from '@electric-sql/pglite'
import { zipSync, strToU8 } from 'fflate'
import { readFileSync } from 'node:fs'
import { createHash } from 'node:crypto'

const REPO = '/Users/jiepijiang/workbuddy-ai/jerry-skills'
const DIR = process.env.RATINGS_SQL_DIR || `${REPO}/supabase`
const M001 = readFileSync(`${DIR}/migrations/001-skills.sql`, 'utf8')
const M002 = readFileSync(`${DIR}/migrations/002-admin-delete.sql`, 'utf8')
const M003 = readFileSync(`${DIR}/migrations/003-ratings.sql`, 'utf8')

const results = []
const check = (name, pass, extra = '') => {
  results.push({ name, pass })
  console.log(`${pass ? '✅' : '❌'} ${name}${extra ? ` — ${extra}` : ''}`)
}

const db = new PGlite()

/** 跑一条语句并捕获错误，用来断言「应当被拒」 */
const tryQuery = async (sql, params) => {
  try {
    return { ok: true, res: await db.query(sql, params) }
  } catch (e) {
    return { ok: false, code: e.code, msg: e.message }
  }
}

/** 跑一份迁移，并从输出里按列名认领自检结果（不能取最后一条，见 verify-migration 的注释） */
async function runMigration(sql, marker) {
  const out = await db.exec(sql)
  const hit = out.find((r) => r.rows?.[0] && marker in r.rows[0])
  return hit ? hit.rows[0] : null
}

/** 伪造请求来源 IP —— 就是生产环境里 x-forwarded-for 的第一段 */
const setIp = (ip) =>
  db.exec(`select set_config('request.headers', '{"x-forwarded-for":"${ip}"}', false)`)

/**
 * 以 anon 身份调一个 RPC。
 * ⚠️ 调用串里**必须写显式类型转换**（`$1::text`）—— 裸 `$1` 的类型推断在
 *    多候选/可空场景下不可靠，会把「参数传对了」变成「碰巧对了」。
 */
const rpc = (call, args = []) =>
  withAnon(async () => {
    try {
      return (await db.query(`select public.${call} as r`, args)).rows[0].r
    } catch (e) {
      // 「本该是 200 + code 的业务拒绝，结果抛了异常」本身就是一种失败模式。
      // 兜住它，让**该红的那条断言红**，而不是整个脚本崩掉、把其余结果一起吞掉
      //（造红 C 就是踩到这个：拆掉守卫后 FK 抛 23503，脚本直接退出，
      //  前 40 条结果全看不见了）。
      return { ok: false, code: e.code || 'threw', detail: e.message }
    }
  })

async function withAnon(fn) {
  await db.exec(`set role anon;`)
  try {
    return await fn()
  } finally {
    await db.exec(`reset role;`)
  }
}

/** 以超级用户身份直读/直写（仅用于内部断言）。anon 读不到表是设计如此。 */
const asRoot = (sql, params) => db.query(sql, params)

/** 打分 */
const rate = (slug, score) => rpc('rate_skill($1::text, $2::integer)', [slug, score])

/* ══════════════ 1. 建替身环境 ══════════════ */

await db.exec(`
  create role anon;
  create role authenticated;
  -- 🔴 模拟 Supabase 的默认权限：之后新建的表会自动 grant 给 anon / authenticated
  alter default privileges in schema public
    grant all on tables to anon, authenticated;
`)

/* ══════════════ 2. 跑 001 → 002 → 003 ══════════════ */

try {
  await runMigration(M001, 'tables')
  check('001-skills.sql 执行成功', true)
} catch (e) {
  check('001-skills.sql 执行成功', false, e.message)
  process.exit(1)
}

try {
  await runMigration(M002, 'admin_tables')
  check('002-admin-delete.sql 执行成功', true)
} catch (e) {
  check('002-admin-delete.sql 执行成功', false, e.message)
  process.exit(1)
}

let sc
try {
  sc = await runMigration(M003, 'rating_tables')
  check('003-ratings.sql 执行成功（001 之上）', true)
} catch (e) {
  check('003-ratings.sql 执行成功（001 之上）', false, e.message)
  process.exit(1)
}

console.log(
  `【自检】rating_tables=${sc.rating_tables} rating_funcs=${sc.rating_funcs} ` +
    `rls_on=${sc.rls_on} fk_on=${sc.fk_on} policies=${sc.policies}\n`,
)
check('自检 rating_tables = 1', Number(sc.rating_tables) === 1, String(sc.rating_tables))
check('自检 rating_funcs = 1', Number(sc.rating_funcs) === 1, String(sc.rating_funcs))
check('自检 rls_on = 1', Number(sc.rls_on) === 1, String(sc.rls_on))
check('自检 fk_on = 1（外键在，级联删除才有依据）', Number(sc.fk_on) === 1, String(sc.fk_on))
check('自检 policies = 0（表对 anon 全关是**故意**的）', Number(sc.policies) === 0, String(sc.policies))

/* ══════════════ 3. 幂等 ══════════════ */

try {
  const again = await runMigration(M003, 'rating_tables')
  check(
    '重复执行 003 不报错（create table if not exists / create or replace）',
    Number(again.rating_tables) === 1 && Number(again.rating_funcs) === 1,
    `tables=${again.rating_tables} funcs=${again.rating_funcs}`,
  )
} catch (e) {
  check('重复执行 003 不报错', false, e.message)
}

/* ══════════════ 4. anon 读不到评分表 ══════════════ */

await db.exec(`grant usage on schema public to anon;`)

const a1 = await withAnon(() => tryQuery(`select * from public.skill_ratings`))
check(
  'anon 直接读 skill_ratings 被拒（revoke 生效，非「0 行」）',
  !a1.ok && a1.code === '42501',
  a1.ok ? `居然读到 ${a1.res.rows.length} 行` : a1.code,
)

// 纵深防御：就算有人把 SELECT 还回去，RLS（零策略）也必须兜住
await db.exec(`grant select on public.skill_ratings to anon;`)
const a2 = await withAnon(() => tryQuery(`select * from public.skill_ratings`))
await db.exec(`revoke select on public.skill_ratings from anon;`)
check(
  '即使显式 grant select，RLS 零策略仍过滤成 0 行（第二道锁真的在）',
  a2.ok && a2.res.rows.length === 0,
  a2.ok ? `${a2.res.rows.length} 行` : `报错 ${a2.code}`,
)

// anon 不能绕过 RPC 直接插一行评分
await db.exec(`grant insert on public.skill_ratings to anon;`)
const a3 = await withAnon(() =>
  tryQuery(`insert into public.skill_ratings (slug, ip, score) values ('x', '1.1.1.1', 5)`),
)
await db.exec(`revoke insert on public.skill_ratings from anon;`)
check(
  'anon 无法绕过 RPC 直接 insert 评分（RLS 挡住写入）',
  !a3.ok || a3.res.affectedRows === 0,
  a3.ok ? `affectedRows=${a3.res.affectedRows}` : a3.code,
)

/* ══════════════ 5. 准备 4 个技能 ══════════════ */

await setIp('10.0.0.1')

function mkPayload(name) {
  const md =
    `---\nname: ${name}\ndescription: ${name} 的说明。\nversion: 1.0.0\n` +
    `author: qa\ncategory: development\ntags: [测试]\n---\n\n# ${name}\n`
  const bundle = zipSync({ 'SKILL.md': strToU8(md) }, { level: 6 })
  return {
    name,
    description: `${name} 的说明。`,
    category: 'development',
    tags: ['测试'],
    version: '1.0.0',
    license: 'MIT',
    author: 'qa',
    readme: md,
    files: [{ path: 'SKILL.md', size: md.length, kind: 'text' }],
    file_count: 1,
    total_bytes: md.length,
    hash: createHash('sha256').update(bundle).digest('hex'),
    bundle_b64: Buffer.from(bundle).toString('base64'),
  }
}

const pub = (name) => rpc('publish_skill($1::jsonb)', [JSON.stringify(mkPayload(name))])

const pAlpha = await pub('alpha')
const pBeta = await pub('beta')
const pGamma = await pub('gamma')
const pDelta = await pub('delta')
check(
  '发布 4 个技能成功（alpha/beta/gamma/delta）',
  [pAlpha, pBeta, pGamma, pDelta].every((p) => p.ok && p.code === 'created'),
  [pAlpha, pBeta, pGamma, pDelta].map((p) => p.slug).join(', '),
)

const SLUG = pAlpha.slug // 一律用线上真实派生的 slug，不硬写

/* ══════════════ 6. 打分：一人一票 + 改分 ══════════════ */

await setIp('10.0.0.1')
const s1 = await rate(SLUG, 5)
check(
  'rate_skill 首次打分 → ok，人数 1、平均 5',
  s1.ok === true && s1.rating_count === 1 && Number(s1.rating_avg) === 5,
  JSON.stringify(s1),
)

// 🔴 核心：同一个 IP 再打一次，是**改分**不是**加票**
const s2 = await rate(SLUG, 3)
check(
  '同 IP 改分 → 人数仍是 1（一人一票，不是一人多票）',
  s2.rating_count === 1,
  `rating_count=${s2.rating_count}`,
)
check(
  '同 IP 改分 → 平均分跟着变成 3（不是 4 —— 4 就说明插了两行）',
  Number(s2.rating_avg) === 3,
  `rating_avg=${s2.rating_avg}`,
)
check('rate_skill 回传 my_score = 3（前端据此高亮自己那几颗星）', s2.my_score === 3, String(s2.my_score))

// 换个 IP → 这才该加票
await setIp('10.0.0.2')
const s3 = await rate(SLUG, 5)
check('换 IP 打分 → 人数 2', s3.rating_count === 2, `rating_count=${s3.rating_count}`)
check('两人 (3+5)/2 → 平均 4', Number(s3.rating_avg) === 4, `rating_avg=${s3.rating_avg}`)

await setIp('10.0.0.3')
const s4 = await rate(SLUG, 4)
check('第三个 IP → 人数 3', s4.rating_count === 3, `rating_count=${s4.rating_count}`)
check('三人 (3+5+4)/3 → 平均 4', Number(s4.rating_avg) === 4, `rating_avg=${s4.rating_avg}`)

// 真的落库了（不是只在返回值里算）
const rowN = (
  await asRoot(`select count(*)::int as n from public.skill_ratings where slug = $1`, [SLUG])
).rows[0].n
check('评分行真的写进了表，且正好 3 行（3 个 IP）', rowN === 3, `rows=${rowN}`)

/* ══════════════ 7. 非法输入 ══════════════ */

const bad0 = await rate(SLUG, 0)
check(
  'score = 0 → invalid_payload（业务拒绝，不是 500）',
  bad0.ok === false && bad0.code === 'invalid_payload',
  JSON.stringify(bad0),
)

const bad6 = await rate(SLUG, 6)
check('score = 6 → invalid_payload', bad6.ok === false && bad6.code === 'invalid_payload', JSON.stringify(bad6))

const badNull = await rate(SLUG, null)
check(
  'score = null → invalid_payload',
  badNull.ok === false && badNull.code === 'invalid_payload',
  JSON.stringify(badNull),
)

const badSlug = await rate('', 5)
check('slug 为空 → invalid_payload', badSlug.ok === false && badSlug.code === 'invalid_payload', JSON.stringify(badSlug))

const noSuch = await rate('根本不存在的技能', 5)
check('给不存在的技能打分 → not_found', noSuch.ok === false && noSuch.code === 'not_found', JSON.stringify(noSuch))

const orphanN = (
  await asRoot(`select count(*)::int as n from public.skill_ratings where slug = '根本不存在的技能'`)
).rows[0].n
check('给不存在的技能打分**没有**留下垃圾行（表不会被撑大）', orphanN === 0, `rows=${orphanN}`)

// 未发布的技能（直接插一行 status='deleted' 的，模拟软删/隐藏）
await asRoot(
  `insert into public.skills (slug,name,hash,bundle_b64,status)
   values ('hidden-one','隐藏技能','${'0'.repeat(64)}','x','deleted')`,
)
const hidden = await rate('hidden-one', 5)
check('给未发布的技能打分 → not_found', hidden.ok === false && hidden.code === 'not_found', JSON.stringify(hidden))

// 库层的 check 约束是真兜底（绕过 RPC 也插不进 9 分）
const rawBad = await tryQuery(
  `insert into public.skill_ratings (slug, ip, score) values ($1, '9.9.9.9', 9)`,
  [SLUG],
)
check(
  '绕过 RPC 直接插 9 分 → 被 check 约束拒（23514）',
  !rawBad.ok && rawBad.code === '23514',
  rawBad.ok ? '居然插进去了' : rawBad.code,
)

// 🔴 第二道兜底：外键。函数里的「只给已发布技能打分」守卫给的是**友好的**
//    not_found（200 + code），而外键是硬约束 —— 万一那个守卫将来被改坏，
//    脏行仍然进不来（代价是报 500 而不是友好错误，但至少表不会脏）。
//    这条断言就是钉住这层兜底真的存在。
const rawOrphan = await tryQuery(
  `insert into public.skill_ratings (slug, ip, score) values ('压根没有这个技能', '8.8.8.8', 5)`,
)
check(
  '外键兜底：绕过 RPC 给不存在的 slug 插评分 → 被外键拒（23503）',
  !rawOrphan.ok && rawOrphan.code === '23503',
  rawOrphan.ok ? '居然插进去了（外键没生效）' : rawOrphan.code,
)

/* ══════════════ 8. 聚合字段真的出现在读接口里 ══════════════ */

await setIp('10.0.0.2') // 这个 IP 给 alpha 打过 5 分
const g1 = await rpc('get_skill($1::text)', [SLUG])
check(
  'get_skill 返回 rating_count / rating_avg',
  g1.ok === true && g1.skill.rating_count === 3 && Number(g1.skill.rating_avg) === 4,
  `count=${g1.skill?.rating_count} avg=${g1.skill?.rating_avg}`,
)
check('get_skill 的 my_score = 5（这个 IP 自己打的分）', g1.skill.my_score === 5, String(g1.skill.my_score))

await setIp('10.0.0.99') // 从没打过分的 IP
const g2 = await rpc('get_skill($1::text)', [SLUG])
check(
  '没打过分的 IP：my_score 是 null（前端据此显示「还没评分」）',
  g2.skill.my_score === null,
  String(g2.skill.my_score),
)
check(
  '没打过分的 IP 看到的平均分与别人一致（不是按自己过滤过的）',
  g2.skill.rating_count === 3 && Number(g2.skill.rating_avg) === 4,
  `count=${g2.skill.rating_count}`,
)

const g3 = await rpc('get_skill($1::text)', [pGamma.slug])
check(
  '没人评分的技能：count = 0、avg = null（不是 NaN / 0 分）',
  g3.skill.rating_count === 0 && g3.skill.rating_avg === null,
  `count=${g3.skill?.rating_count} avg=${g3.skill?.rating_avg}`,
)

const l1 = await rpc('list_skills($1::text, $2::text, $3::text, $4::integer, $5::integer)', ['', 'all', 'new', 50, 0])
const item = l1.items.find((x) => x.slug === SLUG)
check(
  'list_skills 的每一项都带 rating_count / rating_avg',
  item && 'rating_count' in item && 'rating_avg' in item,
  item ? Object.keys(item).filter((k) => k.startsWith('rating')).join(',') : '没找到该项',
)
check(
  'list_skills 里该项的评分与 get_skill 一致（两个接口不漂移）',
  item.rating_count === 3 && Number(item.rating_avg) === 4,
  `count=${item?.rating_count} avg=${item?.rating_avg}`,
)
check('list_skills 仍然不带 bundle_b64', !JSON.stringify(l1.items).includes('bundle_b64'))

/* ══════════════ 9. 「评分最高」排序 ══════════════ */

// alpha：3 人 (3+5+4) → 4.00 / 3 人
// beta ：3 人全 3 分     → 3.00 / 3 人
// delta：2 人全 5 分     → 5.00 / 2 人
// gamma：没人评          → null / 0 人
for (const ip of ['10.1.0.1', '10.1.0.2', '10.1.0.3']) {
  await setIp(ip)
  await rate(pBeta.slug, 3)
}
for (const ip of ['10.2.0.1', '10.2.0.2']) {
  await setIp(ip)
  await rate(pDelta.slug, 5)
}

const lr = await rpc('list_skills($1::text, $2::text, $3::text, $4::integer, $5::integer)', ['', 'all', 'rating', 50, 0])
const order = lr.items.map((x) => x.slug)
console.log(
  `【评分排序】${lr.items.map((x) => `${x.slug}(${x.rating_avg ?? 'null'}×${x.rating_count})`).join(' → ')}\n`,
)

check('平均分最高的排最前（delta 5.00）', order[0] === pDelta.slug, order.join(' → '))
check(
  '同分/降序正确：delta(5.00) → alpha(4.00) → beta(3.00)',
  order.indexOf(pDelta.slug) < order.indexOf(pAlpha.slug) &&
    order.indexOf(pAlpha.slug) < order.indexOf(pBeta.slug),
  order.join(' → '),
)
check(
  '🔴 未评分的排最后（不能因为 null 排序默认靠前而冒到最上面）',
  order.indexOf(pGamma.slug) === order.length - 1,
  `gamma 在第 ${order.indexOf(pGamma.slug) + 1} / ${order.length} 位`,
)

// 改分之后排序要实时跟着变
await setIp('10.3.0.1')
await rate(pBeta.slug, 5) // beta: (3+3+3+5)/4 = 3.5
const lr2 = await rpc('list_skills($1::text, $2::text, $3::text, $4::integer, $5::integer)', ['', 'all', 'rating', 50, 0])
const b = lr2.items.find((x) => x.slug === pBeta.slug)
check(
  '改分后排序实时跟着变（beta 3.00 → 3.50，仍排在 alpha 之后）',
  Number(b.rating_avg) === 3.5 &&
    lr2.items.findIndex((x) => x.slug === pBeta.slug) > lr2.items.findIndex((x) => x.slug === pAlpha.slug),
  lr2.items.map((x) => `${x.slug}(${x.rating_avg})`).join(' → '),
)

/* ══════════════ 10. 删技能 → 评分级联清掉 ══════════════ */

// 先设一个管理口令（复刻 set-admin-token.sql 的算法，逐字一致）
const PASS = 'pglite-测试口令-1234'
await asRoot(`
  insert into public.skill_admin_config (id, salt, token_hash, updated_at)
  values (1, 'aabbcc', encode(sha256(convert_to('aabbcc' || '${PASS}', 'UTF8')), 'hex'), now())
  on conflict (id) do update set salt = excluded.salt, token_hash = excluded.token_hash
`)

const beforeDel = (
  await asRoot(`select count(*)::int as n from public.skill_ratings where slug = $1`, [SLUG])
).rows[0].n
const del = await rpc('skill_admin_delete($1::text, $2::text)', [SLUG, PASS])
check('skill_admin_delete 删掉技能成功', del.ok === true, JSON.stringify(del))

const afterDel = (
  await asRoot(`select count(*)::int as n from public.skill_ratings where slug = $1`, [SLUG])
).rows[0].n
check(
  `🔴 删技能后评分行一起没了（${beforeDel} → ${afterDel}）—— 不会变成孤儿被后来的同名技能继承`,
  afterDel === 0,
  `删前 ${beforeDel} 行，删后 ${afterDel} 行`,
)

const g4 = await rpc('get_skill($1::text)', [SLUG])
check('删掉之后 get_skill → not_found', g4.ok === false && g4.code === 'not_found')

/* ══════════════ 11. 收尾 ══════════════ */

await db.exec(`reset role;`)
await db.close()

const failed = results.filter((r) => !r.pass)
console.log('\n' + '─'.repeat(64))
console.log(`合计 ${results.length} 项，通过 ${results.length - failed.length}，失败 ${failed.length}`)
if (failed.length) {
  console.log('失败项：')
  for (const f of failed) console.log(`  ❌ ${f.name}`)
}
process.exit(failed.length ? 1 : 0)
