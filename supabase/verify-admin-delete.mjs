/**
 * 用 PGlite（WASM Postgres）真跑一遍 001 + 002，重点验 002 的管理删除
 * ===========================================================================
 * 怎么跑（PGlite 带 ~10MB WASM，不进项目依赖，放在隔离工作区里跑）：
 *
 *   cd ~/.workbuddy-ai/binaries/node/workspace
 *   npm install @electric-sql/pglite fflate
 *   cp <repo>/supabase/verify-admin-delete.mjs .
 *   node verify-admin-delete.mjs
 *
 * 造红（验证这套检查本身有没有判别力）：
 *   SKILLS_SQL_DIR=/path/to/被改坏的副本 node verify-admin-delete.mjs
 *
 * ---------------------------------------------------------------------------
 * 要回答的问题（都不能靠肉眼）：
 *   1. 002 会不会动到 001 建的东西 / 两个姊妹站的表与函数？
 *   2. 口令校验是不是「失败关闭」—— 没设口令时是不是谁都进不去？
 *   3. 删除是不是真的只认口令 —— 口令错的时候行**必须还在**？
 *   4. 硬删之后，重传同一份 zip 还能不能成功？（软删方案会在这里翻车）
 *   5. 限流真的在拦吗？只数失败吗？伪造 IP 能绕开吗？绕开之后还有兜底吗？
 *   6. anon 能不能绕过 RPC 直接摸到口令哈希 / 回收站？
 *
 * ⚠️ 替身环境的局限（写清楚，免得自我安慰）
 *   (a) 姊妹站的表只用真实表名，列定义简化 —— 这里要验的是**名字存活**。
 *   (b) Supabase 的 anon / authenticated 在 PGlite 里不存在，得手动建。
 *   (c) 🔴 必须模拟 Supabase 的 default privileges，否则会把「anon 本来就无权限」
 *       误当成「revoke 生效」—— 两条完全不同的因果被混成一条。
 *   (d) 🔴 RPC 必须以 anon 身份调，且用**具名参数**（PostgREST 按名字匹配，
 *       名字写错线上是 404 而不是 400，只有具名调用才验得到）。
 */
import { PGlite } from '@electric-sql/pglite'
import { zipSync, strToU8 } from 'fflate'
import { readFileSync } from 'node:fs'
import { createHash } from 'node:crypto'

const DIR = process.env.SKILLS_SQL_DIR || '/Users/jiepijiang/workbuddy-ai/jerry-skills/supabase'
const M1 = readFileSync(`${DIR}/migrations/001-skills.sql`, 'utf8')
const M2 = readFileSync(`${DIR}/migrations/002-admin-delete.sql`, 'utf8')
const SETUP = readFileSync(`${DIR}/set-admin-token.sql`, 'utf8')

const results = []
const check = (name, pass, extra = '') => {
  results.push({ name, pass })
  console.log(`${pass ? '✅' : '❌'} ${name}${extra ? ` — ${extra}` : ''}`)
}
const section = (t) => console.log(`\n──── ${t} ────`)

const db = new PGlite()

const tryQuery = async (sql, params) => {
  try {
    return { ok: true, res: await db.query(sql, params) }
  } catch (e) {
    return { ok: false, code: e.code, msg: e.message }
  }
}

/**
 * 跑**多语句** SQL（脚本文件那种）。
 * ⚠️ 不能用 db.query：它走扩展协议 / 预备语句，一条里塞两句会报
 *    `cannot insert multiple commands into a prepared statement`。
 *    set-admin-token.sql 是「一个 DO 块 + 一个 select」，必须用 exec。
 */
const tryExec = async (sql) => {
  try {
    await db.exec(sql)
    return { ok: true }
  } catch (e) {
    return { ok: false, code: e.code, msg: e.message }
  }
}

const OTHER_FNS = [
  'is_admin', 'touch_updated_at', 'post_guestbook_message',
  'notify_guestbook_message', 'get_shared_nav', 'submit_feedback',
]
const OTHER_TABLES = [
  'guestbook_messages', 'app_config', 'bookmarks', 'feedback',
  'notes', 'discover_sites', 'share_settings',
]

const snapshot = async () => {
  const fns = (await db.query(`
    select p.proname as name, pg_get_functiondef(p.oid) as def
      from pg_proc p join pg_namespace n on n.oid = p.pronamespace
     where n.nspname = 'public' order by p.proname`)).rows
  const cols = (await db.query(`
    select c.relname as tbl, a.attname as col, format_type(a.atttypid, a.atttypmod) as t
      from pg_class c join pg_namespace n on n.oid = c.relnamespace
      join pg_attribute a on a.attrelid = c.oid and a.attnum > 0 and not a.attisdropped
     where n.nspname = 'public' and c.relkind = 'r'
     order by c.relname, a.attnum`)).rows
  const idx = (await db.query(
    `select indexname, indexdef from pg_indexes where schemaname='public' order by indexname`)).rows
  return {
    fns: new Map(fns.map((r) => [r.name, r.def])),
    cols: cols.map((r) => `${r.tbl}.${r.col}:${r.t}`),
    idx: new Map(idx.map((r) => [r.indexname, r.indexdef])),
  }
}

/* ══════════════ 1. 造「共用项目」替身 ══════════════ */

await db.exec(`
  create role anon;
  create role authenticated;
  alter default privileges in schema public grant all on tables to anon, authenticated;

  create table public.guestbook_messages (id bigserial primary key, email text not null, content text not null);
  create table public.app_config (key text primary key, value text);
  create table public.bookmarks (id text primary key, title text);
  create table public.feedback (id text primary key, content text);
  create table public.notes (id text primary key, body text);
  create table public.discover_sites (id text primary key, url text);
  create table public.share_settings (slug text primary key);

  create function public.is_admin() returns boolean language sql stable as $$ select false $$;
  create function public.touch_updated_at() returns trigger language plpgsql as $$ begin return new; end $$;
  create function public.post_guestbook_message(p_email text, p_content text)
    returns jsonb language sql as $$ select jsonb_build_object('ok', true) $$;
  create function public.notify_guestbook_message() returns void language plpgsql as $$ begin end $$;
  create function public.get_shared_nav(p_slug text) returns jsonb language sql as $$ select '{}'::jsonb $$;
  create function public.submit_feedback(p_id text, p_content text, p_contact text)
    returns boolean language sql as $$ select true $$;

  grant all on all tables in schema public to anon, authenticated;

  insert into public.guestbook_messages (email, content) values ('a@b.c', '哨兵留言');
  insert into public.bookmarks (id, title) values ('b22', '哨兵书签');
  insert into public.app_config (key, value) values ('feishu_webhook', '哨兵配置');
`)

const before = await snapshot()

/* ══════════════ 2. 跑两份迁移 ══════════════ */

const runM1 = async () => {
  const out = await db.exec(M1)
  const hit = out.find((r) => r.rows?.[0] && 'tables' in r.rows[0] && 'funcs' in r.rows[0])
  if (!hit) throw new Error('001 自检行没找到')
  return hit.rows[0]
}
const runM2 = async () => {
  const out = await db.exec(M2)
  const hit = out.find((r) => r.rows?.[0] && 'admin_tables' in r.rows[0])
  if (!hit) throw new Error('002 自检行没找到')
  return hit.rows[0]
}

section('迁移执行')

let s1
try {
  s1 = await runM1()
  check('001-skills.sql 执行成功', true)
} catch (e) {
  check('001-skills.sql 执行成功', false, e.message)
  process.exit(1)
}
check('001 自检仍是 2/5/2/0',
  Number(s1.tables) === 2 && Number(s1.funcs) === 5 && Number(s1.rls_on) === 2 && Number(s1.policies) === 0,
  `tables=${s1.tables} funcs=${s1.funcs} rls=${s1.rls_on} policies=${s1.policies}`)

let s2
try {
  s2 = await runM2()
  check('★ 002-admin-delete.sql 执行成功（无语法 / 依赖错误）', true)
} catch (e) {
  check('★ 002-admin-delete.sql 执行成功（无语法 / 依赖错误）', false, e.message)
  process.exit(1)
}
console.log(`【002 自检】admin_tables=${s2.admin_tables} admin_funcs=${s2.admin_funcs} rls_on=${s2.rls_on} token_set=${s2.token_set}`)
check('002 自检 admin_tables = 3', Number(s2.admin_tables) === 3, String(s2.admin_tables))
check('002 自检 admin_funcs = 2', Number(s2.admin_funcs) === 2, String(s2.admin_funcs))
check('002 自检 rls_on = 3（三张新表都开了 RLS）', Number(s2.rls_on) === 3, String(s2.rls_on))
check('002 自检 token_set = 0（迁移本身不含口令）', Number(s2.token_set) === 0, String(s2.token_set))

try {
  const again2 = await runM2()
  const again1 = await runM1()
  check('重复执行 002 不报错（幂等）',
    Number(again2.admin_tables) === 3 && Number(again2.admin_funcs) === 2,
    `admin_tables=${again2.admin_tables}`)
  check('002 跑完再跑 001 也不报错（互相幂等）',
    Number(again1.tables) === 2 && Number(again1.funcs) === 5, `funcs=${again1.funcs}`)
} catch (e) {
  check('重复执行不报错（幂等）', false, e.message)
}

/* ══════════════ 3. 无附带损伤 ══════════════ */

section('无附带损伤')

const after = await snapshot()

const fnDrift = OTHER_FNS.filter((k) => before.fns.get(k) !== after.fns.get(k))
check('两个站的 6 个函数定义逐字节一致（无静默覆盖）',
  fnDrift.length === 0, fnDrift.length ? `被改写：${fnDrift.join(', ')}` : OTHER_FNS.join(', '))

const colDrift = OTHER_TABLES.filter((t) => {
  const b = before.cols.filter((c) => c.startsWith(t + '.')).join('|')
  const a = after.cols.filter((c) => c.startsWith(t + '.')).join('|')
  return b !== a
})
check('两个站的 7 张表列定义逐字节一致',
  colDrift.length === 0, colDrift.length ? `被改：${colDrift.join(', ')}` : `共 ${before.cols.length} 列全对得上`)

const idxDrift = [...before.idx.keys()].filter((k) => after.idx.get(k) !== before.idx.get(k))
check('两个站既有索引定义逐字节一致',
  idxDrift.length === 0, idxDrift.length ? `被改：${idxDrift.join(', ')}` : `既有 ${before.idx.size} 个索引未动`)

const sent = (await db.query(`
  select 'guestbook' as t, count(*)::int as n from public.guestbook_messages
  union all select 'bookmarks', count(*)::int from public.bookmarks
  union all select 'app_config', count(*)::int from public.app_config`)).rows
check('两个站的哨兵数据全部还在', sent.every((r) => r.n === 1), sent.map((r) => `${r.t}=${r.n}`).join(' '))

const wantFns = ['_client_ip', 'download_skill', 'get_skill', 'list_skills', 'publish_skill', 'register_install',
  '_skill_admin_gate', '_skill_admin_log', '_skill_admin_ok', 'skill_admin_check', 'skill_admin_delete'].sort()
const addedFns = [...after.fns.keys()].filter((k) => !before.fns.has(k)).sort()
check('新增函数恰好是这 11 个，没有顶替任何既有函数',
  addedFns.join(',') === wantFns.join(','), addedFns.join(', '))

const addedTables = [...new Set(after.cols.map((c) => c.split('.')[0]))]
  .filter((t) => !OTHER_TABLES.includes(t)).sort()
check('新增表恰好是这 5 张',
  addedTables.join(',') === 'skill_admin_config,skill_admin_log,skill_upload_log,skills,skills_trash',
  addedTables.join(', '))

/* ══════════════ 4. anon 权限 ══════════════ */

section('anon 权限（绕过 RPC 直接摸表）')

await db.exec(`grant usage on schema public to anon;`)

const denyRead = async (tbl) => {
  await db.exec(`set role anon;`)
  const r = await tryQuery(`select * from public.${tbl}`)
  await db.exec(`reset role;`)
  return r
}
for (const t of ['skill_admin_config', 'skill_admin_log', 'skills_trash']) {
  const r = await denyRead(t)
  check(`anon 直接读 ${t} 被硬拒（42501，不是「0 行」）`, !r.ok && r.code === '42501',
    r.ok ? `居然读到 ${r.res.rows.length} 行` : r.code)
}

// 纵深防御：就算有人把 SELECT 还回去，RLS 零策略也必须兜住
await db.exec(`grant select on public.skill_admin_config to anon;`)
await db.exec(`set role anon;`)
const rlsRead = await tryQuery(`select * from public.skill_admin_config`)
await db.exec(`reset role;`)
await db.exec(`revoke select on public.skill_admin_config from anon;`)
check('即使显式 grant select，RLS 零策略仍过滤成 0 行（第二道锁真的在）',
  rlsRead.ok && rlsRead.res.rows.length === 0,
  rlsRead.ok ? `${rlsRead.res.rows.length} 行` : `报错 ${rlsRead.code}`)

for (const fn of ['_skill_admin_ok', '_skill_admin_gate', '_skill_admin_log']) {
  await db.exec(`set role anon;`)
  const args = fn === '_skill_admin_ok' ? `'x'` : fn === '_skill_admin_log' ? `'x', true` : ''
  const r = await tryQuery(`select public.${fn}(${args})`)
  await db.exec(`reset role;`)
  check(`anon 调不动内部函数 ${fn}()`, !r.ok && r.code === '42501', r.ok ? '调通了（不该）' : r.code)
}

/* ══════════════ 5. 以 anon 身份调 RPC（具名参数） ══════════════ */

await db.exec(`set role anon;`)

const asRoot = async (sql, params) => {
  await db.exec(`reset role;`)
  const res = await db.query(sql, params)
  await db.exec(`set role anon;`)
  return res
}

/** 模拟客户端伪造 x-forwarded-for（_client_ip 取的就是这个头的第一段） */
const setIp = async (ip) => {
  await db.exec(`select set_config('request.headers', '${JSON.stringify({ 'x-forwarded-for': ip })}', false)`)
}

await setIp('1.2.3.4')

const adminCheck = async (token) =>
  (await db.query(`select public.skill_admin_check(p_token => $1) as r`, [token])).rows[0].r
const adminDelete = async (slug, token) =>
  (await db.query(`select public.skill_admin_delete(p_slug => $1, p_token => $2) as r`, [slug, token])).rows[0].r

section('口令校验：失败关闭')

const c0 = await adminCheck('随便一个口令')
check('★ 还没设口令时 → unauthorized（不是「没设就等于不设防」）',
  c0.ok === false && c0.code === 'unauthorized', JSON.stringify(c0))

const stillThere = (await asRoot(`select count(*)::int as n from public.skill_admin_config`)).rows[0].n
check('  此时表里确实一行配置都没有', stillThere === 0, `rows=${stillThere}`)

section('口令校验：设好之后')

// 用真实的 set-admin-token.sql 来设，而不是自己 insert —— 那个文件本身也要被验
const PASS = '正确的马的口令-battery-staple-42'
await db.exec(`reset role;`)
const setupSql = SETUP.replace(`'把这里换成你自己的口令'`, `'${PASS}'`)
const setupOut = await tryExec(setupSql)
check('set-admin-token.sql 能跑通（占位符换掉后）', setupOut.ok, setupOut.ok ? '' : setupOut.msg)
await db.exec(`set role anon;`)

const cfg = (await asRoot(`select salt, token_hash from public.skill_admin_config where id = 1`)).rows[0]
check('  库里存的是「盐 + 哈希」，不是明文',
  cfg && cfg.salt.length === 32 && cfg.token_hash.length === 64 && !cfg.token_hash.includes(PASS),
  `salt=${cfg?.salt?.slice(0, 8)}… hash=${cfg?.token_hash?.slice(0, 12)}…`)

const c1 = await adminCheck(PASS)
check('★ 正确口令 → ok:true', c1.ok === true && c1.valid === true, JSON.stringify(c1))

const c2 = await adminCheck(PASS + 'x')
check('口令多一个字符 → unauthorized', c2.ok === false && c2.code === 'unauthorized', JSON.stringify(c2))

const c3 = await adminCheck(PASS.toUpperCase())
check('口令大小写敏感 → unauthorized', c3.ok === false && c3.code === 'unauthorized', JSON.stringify(c3))

const c4 = await adminCheck('')
check('空口令 → unauthorized', c4.ok === false && c4.code === 'unauthorized', JSON.stringify(c4))

const c5 = await adminCheck(null)
check('null 口令 → unauthorized（不 500）', c5.ok === false && c5.code === 'unauthorized', JSON.stringify(c5))

// 盐真的参与了运算吗 —— 同一个口令、换一个盐，哈希必须变
await asRoot(`update public.skill_admin_config set salt = '${'f'.repeat(32)}' where id = 1`)
const c6 = await adminCheck(PASS)
check('★ 换了盐之后同一口令就失效了（证明盐真的进了哈希，不是摆设）',
  c6.ok === false && c6.code === 'unauthorized', JSON.stringify(c6))
// 换回去
await asRoot(`update public.skill_admin_config set salt = '${cfg.salt}' where id = 1`)
const c7 = await adminCheck(PASS)
check('  换回原盐 → 口令重新生效', c7.ok === true, JSON.stringify(c7))

section('set-admin-token.sql 自身的守卫')

await db.exec(`reset role;`)
const short = await tryExec(SETUP.replace(`'把这里换成你自己的口令'`, `'short'`))
check('★ 口令太短 → 脚本拒绝执行（不是默默设成短口令）',
  !short.ok && /口令太短/.test(short.msg), short.ok ? '居然跑过了' : short.msg.slice(0, 60))

const placeholder = await tryExec(SETUP)
check('★ 没改占位符 → 脚本拒绝执行', !placeholder.ok && /改成你自己的口令/.test(placeholder.msg),
  placeholder.ok ? '居然跑过了' : placeholder.msg.slice(0, 60))

// 🔴 这条是**真踩过**才加的：改口令最自然的做法是「全局替换占位符」
//    （sed / 编辑器全选替换）。如果守卫写成 `if v_pass = '<占位符>'`，
//    那它自己那一行也含有占位符 → 被一起替换 → 变成「拿口令和口令比」→ 恒真
//    → 永远报「还没改占位符」，而且完全看不出为什么。
//    现在守卫里的占位符是拆成两段拼的，全局替换碰不到它。
const replacedAll = await tryExec(SETUP.replaceAll(`把这里换成你自己的口令`, PASS))
await db.exec(`set role anon;`)

// 口令还在（上面两次失败不该把配置弄坏）
const c8 = await adminCheck(PASS)
check('  两次被拒之后口令依然有效', c8.ok === true, JSON.stringify(c8))

check('★ 用「全局替换」改口令也能跑通（守卫不会把自己也换掉后恒真）',
  replacedAll.ok, replacedAll.ok ? '' : replacedAll.msg.slice(0, 80))
const c9 = await adminCheck(PASS)
check('  全局替换设的口令生效', c9.ok === true, JSON.stringify(c9))

/* ══════════════ 5.5 「少跑了 002」时的提示 ══════════════ */

section('没跑 002 就跑 set-admin-token.sql')

// 干净的实例：**只跑 001**，故意不跑 002 —— 复现「照着文档跳步」的真实场景
const db2 = new PGlite()
await db2.exec(`create role anon; create role authenticated;`)
await db2.exec(M1)
let msg2 = ''
try {
  await db2.exec(SETUP.replaceAll(`把这里换成你自己的口令`, PASS))
} catch (e) {
  msg2 = String(e?.message || e)
}
check('★ 给出「你少跑了哪一步」的提示，而不是裸的 42P01',
  /002-admin-delete\.sql/.test(msg2) && !/42P01/.test(msg2), msg2.split('\n')[0].slice(0, 90))
check('  提示里点名了要跑的期望结果（token_set = 0）', /token_set/.test(msg2))
await db2.close()

/* ══════════════ 6. 删除 ══════════════ */

section('删除')

const md = `---
name: pgtest
description: PGlite 里验证用的技能。
version: 1.0.0
author: qa
category: development
tags: [测试]
---

# PG Test
`
const bundle = zipSync({ 'SKILL.md': strToU8(md) }, { level: 6 })
const b64 = Buffer.from(bundle).toString('base64')
const hash = createHash('sha256').update(bundle).digest('hex')
const payload = (over = {}) => ({
  name: 'pgtest', description: 'PGlite 里验证用的技能。', category: 'development',
  tags: ['测试'], version: '1.0.0', license: 'MIT', author: 'qa', readme: md,
  files: [{ path: 'SKILL.md', size: md.length, kind: 'text' }],
  file_count: 1, total_bytes: md.length, hash, bundle_b64: b64, ...over,
})
const pub = async (p) =>
  (await db.query(`select public.publish_skill(p_payload => $1::jsonb) as r`, [JSON.stringify(p)])).rows[0].r

const p1 = await pub(payload())
check('先发布一个技能（前置条件）', p1.ok === true && p1.code === 'created', JSON.stringify(p1))
const slug = p1.slug

// 让它有点下载 / 安装量，好验证这些数字在回收站里没丢
await db.query(`select public.download_skill(p_slug => $1)`, [slug])
await db.query(`select public.download_skill(p_slug => $1)`, [slug])
await db.query(`select public.register_install(p_slug => $1)`, [slug])

const del1 = await adminDelete(slug, '错误口令')
check('★ 口令错 → unauthorized', del1.ok === false && del1.code === 'unauthorized', JSON.stringify(del1))
const survived = (await asRoot(`select count(*)::int as n from public.skills where slug = $1`, [slug])).rows[0].n
check('★★ 口令错时技能**必须还在**（这是整个功能的底线）', survived === 1, `rows=${survived}`)

const del2 = await adminDelete(slug, PASS)
check('★ 口令对 → 删除成功', del2.ok === true && del2.slug === slug, JSON.stringify(del2))

const gone = (await asRoot(`select count(*)::int as n from public.skills where slug = $1`, [slug])).rows[0].n
check('  表里真的少了一行（硬删）', gone === 0, `rows=${gone}`)

const trash = (await asRoot(
  `select slug, name, payload from public.skills_trash where slug = $1 order by id desc limit 1`, [slug])).rows[0]
check('★ 回收站里有一份完整快照',
  trash && trash.slug === slug && trash.name === 'pgtest', trash ? trash.slug : '没找到')
check('  快照里连 zip 包体和 hash 都在（能原样恢复）',
  trash?.payload?.bundle_b64 === b64 && trash?.payload?.hash === hash,
  `hash=${trash?.payload?.hash?.slice(0, 10)}…`)
check('  快照里的下载量 / 安装量也保住了',
  trash?.payload?.downloads === 2 && trash?.payload?.installs === 1,
  `downloads=${trash?.payload?.downloads} installs=${trash?.payload?.installs}`)

section('删完之后：各个读接口都看不到它')

const l1 = (await db.query(`select public.list_skills(p_query => '', p_category => 'all', p_sort => 'new', p_limit => 50, p_offset => 0) as r`)).rows[0].r
check('list_skills 里没有它', l1.total === 0, `total=${l1.total}`)
const g1 = (await db.query(`select public.get_skill(p_slug => $1) as r`, [slug])).rows[0].r
check('get_skill → not_found', g1.ok === false && g1.code === 'not_found', JSON.stringify(g1))
const d1 = (await db.query(`select public.download_skill(p_slug => $1) as r`, [slug])).rows[0].r
check('download_skill → not_found（下载不到已删的包）', d1.ok === false && d1.code === 'not_found', JSON.stringify(d1))
const i1 = (await db.query(`select public.register_install(p_slug => $1) as r`, [slug])).rows[0].r
check('register_install → not_found', i1.ok === false && i1.code === 'not_found', JSON.stringify(i1))

const del3 = await adminDelete(slug, PASS)
check('删一个不存在的 → not_found（不报错）', del3.ok === false && del3.code === 'not_found', JSON.stringify(del3))

section('★ 硬删的关键收益：同一份 zip 还能重传')

// 这条是「硬删 vs 软删」的判别点。软删方案下，publish_skill 的
// `where hash = v_hash`（不带 status）会命中那条看不见的行 → 返回 exists
// 却什么都不显示；改成带 status 又会撞 skills_hash_uniq 唯一索引 → 500。
const p2 = await pub(payload())
check('★ 删掉之后重传同一份 zip → created（软删方案会在这里翻车）',
  p2.ok === true && p2.code === 'created', JSON.stringify(p2))
check('  而且拿回了同一个 slug（slug 和 hash 都被释放了）', p2.slug === slug, `${p2.slug} vs ${slug}`)
const p3 = await pub(payload())
check('  重传之后再传一次 → exists（去重仍然正常）',
  p3.ok === true && p3.code === 'exists', JSON.stringify(p3))

const del4 = await adminDelete(slug, PASS)
check('  重传的那条也能正常删掉', del4.ok === true, JSON.stringify(del4))
const trashN = (await asRoot(`select count(*)::int as n from public.skills_trash where slug = $1`, [slug])).rows[0].n
check('★ 回收站里同一 slug 有两条（所以主键必须是自增 id，不能是 slug）',
  trashN === 2, `rows=${trashN}`)

/* ══════════════ 7. 限流 ══════════════ */

section('限流')

await asRoot(`delete from public.skill_admin_log`)

// 7a. 成功的尝试不该吃掉额度
await setIp('7.7.7.7')
for (let i = 0; i < 12; i++) await adminCheck(PASS)
const afterOk = (await asRoot(
  `select count(*)::int as n, count(*) filter (where not success)::int as f from public.skill_admin_log`)).rows[0]
check('成功的校验会被记录（审计），但不计入失败数',
  afterOk.n === 12 && afterOk.f === 0, `共 ${afterOk.n} 条，其中失败 ${afterOk.f} 条`)

const afterManyOk = await adminCheck('错的')
check('★ 连续成功 12 次（超过每 IP 阈值 10）之后，第一次失败仍然只是 unauthorized（没被限流误伤）',
  afterManyOk.code === 'unauthorized', JSON.stringify(afterManyOk))

// 7b. 每 IP 阈值
await asRoot(`delete from public.skill_admin_log`)
await setIp('1.2.3.4')
let limitedAt = null
for (let i = 1; i <= 20; i++) {
  const r = await adminCheck(`错的-${i}`)
  if (r.code === 'rate_limited') { limitedAt = i; break }
}
check('★ 同一 IP 连续试错，最终被 rate_limited 拦下', limitedAt !== null, `第 ${limitedAt} 次被拦`)
check('  阈值 = 10/小时（第 11 次才拦）', limitedAt === 11, `limitedAt=${limitedAt}`)

// 7c. 🔴 伪造 IP 能绕开「每 IP」那道 —— 如实记录，别假装它防得住
await setIp('5.5.5.5')
const spoof = await adminCheck('又错一个')
check('⚠️ 伪造 x-forwarded-for 换一个 IP → 又能试了（每 IP 限流**可被绕过**）',
  spoof.code === 'unauthorized', JSON.stringify(spoof))

// 7d. 但全局那道拦得住 —— 这才是真正的兜底
await asRoot(`delete from public.skill_admin_log`)
let globalLimitedAt = null
for (let i = 1; i <= 40; i++) {
  await setIp(`10.0.${Math.floor(i / 250)}.${(i % 250) + 1}`)   // 每次都换 IP
  const r = await adminCheck(`x${i}`)
  if (r.code === 'rate_limited') { globalLimitedAt = i; break }
}
check('★★ 每次换一个 IP 死磕 → 仍然被全局上限拦下（30/小时，第 31 次）',
  globalLimitedAt === 31, `globalLimitedAt=${globalLimitedAt}`)
const tot = (await asRoot(`select count(*)::int as n from public.skill_admin_log`)).rows[0].n
check('  全局计数停在 30', tot === 30, `rows=${tot}`)

// 7e. 旧记录会被清理，且不占用额度
await asRoot(`delete from public.skill_admin_log`)
await asRoot(`insert into public.skill_admin_log (ip, action, success, created_at)
              select '9.9.9.9', 'check', false, now() - interval '2 days' from generate_series(1, 5)`)
await setIp('9.9.9.9')
const pruneProbe = await adminCheck('错的')
check('★ 两天前的失败记录不占额度（窗口是 1 小时）',
  pruneProbe.code === 'unauthorized', JSON.stringify(pruneProbe))
const oldLeft = (await asRoot(
  `select count(*)::int as n from public.skill_admin_log where created_at < now() - interval '1 day'`)).rows[0].n
check('  顺手被清理掉了（表不会无限长）', oldLeft === 0, `残留 ${oldLeft} 条`)

/* ══════════════ 8. 收尾 ══════════════ */

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
