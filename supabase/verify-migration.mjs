/**
 * 用 PGlite（WASM Postgres）真跑一遍 001-skills.sql
 * ===========================================================================
 * 怎么跑
 * ---------------------------------------------------------------------------
 * 本脚本**不进项目依赖**（PGlite 带 ~10MB WASM，塞进 CI 不值当），
 * 所以手动装在一个隔离工作区里跑：
 *
 *   mkdir -p ~/.workbuddy-ai/binaries/node/workspace && cd $_
 *   npm install @electric-sql/pglite fflate
 *   cp <repo>/supabase/verify-migration.mjs .
 *   node verify-migration.mjs
 *
 * （ESM 的裸导入按**脚本自身路径**解析，不认 NODE_PATH / cwd，所以必须复制过去；
 *   想一条命令跑通就 `npm i -D @electric-sql/pglite` 再直接
 *   `node supabase/verify-migration.mjs`。）
 *
 * 造红（验证这套检查本身有没有判别力）：
 *
 *   SKILLS_SQL_DIR=/path/to/被改坏的副本 node verify-migration.mjs
 *
 * 已做过的四次造红，均如期变红：
 *   A 删掉 `revoke all on public.skills`      → anon 读表不再被硬拒
 *   B 把 skills 改名撞 jerry-tools 的 bookmarks → 迁移报错
 *   C 静默重定义 jerry-site 的 is_admin()      → 函数快照对比抓到
 *   D 偷偷给 bookmarks 加一列                  → 列快照对比抓到
 *
 * ---------------------------------------------------------------------------
 * 要回答的问题：「跑这份 SQL 会不会动到 jerry-site / jerry-tools 的表？」
 * 不能靠肉眼看，所以：
 *
 *   1. 先造一个「共用项目」的替身环境（两个站的真实表名 + 函数名 + 哨兵数据）
 *   3. 预检 → 期望 0 冲突
 *   4. 跑迁移 → 期望自检 2/5/2/0
 *   5. 再跑一遍迁移 → 期望仍然成功（幂等）
 *   6. 再跑预检 → **期望冲突数 > 0**（造红：证明预检真有判别力，
 *      否则「0 冲突」和「查询压根没跑成」分不清）
 *   7. 逐项核对两个站的哨兵数据 / 函数 / 表是否原封不动（前后快照对比）
 *   8. anon 视角的权限：读不到、写不进、内部函数调不动，但 RPC 全都能调
 *   9. 5 个 RPC 全部以 anon 身份调一遍（含校验失败、去重、限流）
 *
 * ⚠️ 替身环境的局限（写清楚，免得自我安慰）
 * ---------------------------------------------------------------------------
 * (a) 两个站的表**只用了真实表名**，列定义是简化的。这里要验证的命题是
 *     「同名对象会不会被覆盖 / 被动到」，与列结构无关 —— 要验的是**名字存活**。
 * (b) Supabase 的 anon / authenticated 在 PGlite 里不存在，得手动建。
 * (c) 🔴 **必须模拟 Supabase 的 default privileges**：真实 Supabase 上
 *     `public` schema 配了 `alter default privileges ... grant all on tables to
 *     anon, authenticated`，所以新表一建出来 anon **是**有 SELECT 的，
 *     随后被迁移的 `revoke all` 收走 → 生产环境表现为 `permission denied`。
 *     不模拟这一步，就会把「anon 本来就无权限」误当成「revoke 生效」，
 *     两条完全不同的因果被混成一条。
 * (d) 🔴 **RPC 必须以 anon 身份调**。以超级用户调的话，就算函数漏了
 *     `security definer` 或漏了 `grant execute`，这里照样全绿、线上全挂。
 */
import { PGlite } from '@electric-sql/pglite'
import { zipSync, strToU8 } from 'fflate'
import { readFileSync } from 'node:fs'
import { createHash } from 'node:crypto'

// 默认读真实迁移；造红时可以指向一份被故意改坏的副本
const DIR = process.env.SKILLS_SQL_DIR || '/Users/jiepijiang/workbuddy-ai/jerry-skills/supabase'
const MIGRATION = readFileSync(`${DIR}/migrations/001-skills.sql`, 'utf8')
const PREFLIGHT = readFileSync(`${DIR}/preflight-check.sql`, 'utf8')

const results = []
const check = (name, pass, extra = '') => {
  results.push({ name, pass })
  console.log(`${pass ? '✅' : '❌'} ${name}${extra ? ` — ${extra}` : ''}`)
}
/** 跑一条语句并捕获错误，用来断言「应当被拒」 */
const tryQuery = async (sql, params) => {
  try {
    return { ok: true, res: await db.query(sql, params) }
  } catch (e) {
    return { ok: false, code: e.code, msg: e.message }
  }
}

const db = new PGlite()

/* 两个站的既有对象（白名单）—— 迁移前后必须逐字节一致 */
const OTHER_FNS = [
  'is_admin', 'touch_updated_at', 'post_guestbook_message',
  'notify_guestbook_message', 'get_shared_nav', 'submit_feedback',
]
const OTHER_TABLES = [
  'guestbook_messages', 'app_config', 'bookmarks', 'feedback',
  'notes', 'discover_sites', 'share_settings',
]

/**
 * 拍一份 schema 快照：函数**完整定义** + 列定义 + 索引定义。
 *
 * 🔴 为什么要拍快照，而不是「检查函数体里有没有出现 skills」：
 *    后者只能抓到「被改成引用了新表」这一种改写。如果有人把 jerry-site 的
 *    `is_admin()` 悄悄重定义成 `select true`，函数体里一个 'skills' 都没有，
 *    子串检查照样放行 —— 而这正是 preflight 里标注为「最危险」的
 *    静默覆盖。只有前后逐字节对比才能真的兜住。
 */
const snapshot = async () => {
  const fns = (
    await db.query(`
      select p.proname as name, pg_get_functiondef(p.oid) as def
        from pg_proc p join pg_namespace n on n.oid = p.pronamespace
       where n.nspname = 'public' order by p.proname
    `)
  ).rows
  const cols = (
    await db.query(`
      select c.relname as tbl, a.attname as col, format_type(a.atttypid, a.atttypmod) as t
        from pg_class c
        join pg_namespace n on n.oid = c.relnamespace
        join pg_attribute a on a.attrelid = c.oid and a.attnum > 0 and not a.attisdropped
       where n.nspname = 'public' and c.relkind = 'r'
       order by c.relname, a.attnum
    `)
  ).rows
  const idx = (
    await db.query(`select indexname, indexdef from pg_indexes where schemaname='public' order by indexname`)
  ).rows
  return {
    fns: new Map(fns.map((r) => [r.name, r.def])),
    cols: cols.map((r) => `${r.tbl}.${r.col}:${r.t}`),
    idx: new Map(idx.map((r) => [r.indexname, r.indexdef])),
  }
}

/* ══════════════ 1. 造「共用项目」替身 ══════════════ */

await db.exec(`
  -- Supabase 内置角色（迁移里的 revoke / grant 依赖它们存在）
  create role anon;
  create role authenticated;

  -- 🔴 模拟 Supabase 的默认权限：之后新建的表会自动 grant 给 anon / authenticated
  alter default privileges in schema public
    grant all on tables to anon, authenticated;

  -- ── jerry-site 的表（真实表名，列简化）──
  create table public.guestbook_messages (
    id      bigserial primary key,
    email   text not null,
    content text not null
  );
  create table public.app_config (key text primary key, value text);

  -- ── jerry-tools 的表（真实表名，列简化）──
  create table public.bookmarks (id text primary key, title text);
  create table public.feedback    (id text primary key, content text);
  create table public.notes       (id text primary key, body text);
  create table public.discover_sites (id text primary key, url text);
  create table public.share_settings (slug text primary key);

  -- ── 两个站的函数（真实函数名）──
  create function public.is_admin() returns boolean
    language sql stable as $$ select false $$;
  create function public.touch_updated_at() returns trigger
    language plpgsql as $$ begin return new; end $$;
  create function public.post_guestbook_message(p_email text, p_content text)
    returns jsonb language sql as $$ select jsonb_build_object('ok', true) $$;
  create function public.notify_guestbook_message() returns void
    language plpgsql as $$ begin end $$;
  create function public.get_shared_nav(p_slug text) returns jsonb
    language sql as $$ select '{}'::jsonb $$;
  create function public.submit_feedback(p_id text, p_content text, p_contact text)
    returns boolean language sql as $$ select true $$;

  -- 既有表也补上 grant（Supabase 上这些表本来就有）
  grant all on all tables in schema public to anon, authenticated;

  -- ── 哨兵数据：跑完迁移后要一字不差地还在 ──
  insert into public.guestbook_messages (email, content) values ('a@b.c', '哨兵留言');
  insert into public.bookmarks (id, title) values ('b22', '哨兵书签');
  insert into public.app_config (key, value) values ('feishu_webhook', '哨兵配置');
`)

/* ══════════════ 2. 迁移前快照 ══════════════ */

const before = await snapshot()

/* ══════════════ 3. 预检 #1：迁移之前应当 0 冲突 ══════════════ */

const pre1 = (await db.query(PREFLIGHT)).rows[0]
console.log(`\n【预检 #1（迁移前）】${pre1.结论}  冲突数=${pre1.冲突数}\n`)
check('预检（迁移前）报告 0 冲突', Number(pre1.冲突数) === 0, `冲突数=${pre1.冲突数}`)

/* ══════════════ 4. 跑迁移 ══════════════ */

const runMigration = async () => {
  const out = await db.exec(MIGRATION)
  // ⚠️ 不能直接取 out[out.length - 1]：自检查询未必是最后一条语句
  //（造红时会在迁移后面追加 SQL），按列名认领才稳。
  const hit = out.find((r) => r.rows?.[0] && 'tables' in r.rows[0] && 'funcs' in r.rows[0])
  if (!hit) throw new Error('迁移输出里找不到自检结果（tables/funcs 那一条）')
  return hit.rows[0]
}

let selfCheck
try {
  selfCheck = await runMigration()
  check('001-skills.sql 执行成功（无语法 / 依赖错误）', true)
} catch (e) {
  check('001-skills.sql 执行成功（无语法 / 依赖错误）', false, e.message)
  process.exit(1)
}

console.log(`【自检】tables=${selfCheck.tables} funcs=${selfCheck.funcs} rls_on=${selfCheck.rls_on} policies=${selfCheck.policies}\n`)
check('自检 tables = 2', Number(selfCheck.tables) === 2, String(selfCheck.tables))
check('自检 funcs = 5', Number(selfCheck.funcs) === 5, String(selfCheck.funcs))
check('自检 rls_on = 2', Number(selfCheck.rls_on) === 2, String(selfCheck.rls_on))
check('自检 policies = 0（表对 anon 全关是**故意**的）', Number(selfCheck.policies) === 0, String(selfCheck.policies))

/* ══════════════ 5. 幂等：再跑一遍不应报错 ══════════════ */

try {
  const again = await runMigration()
  check(
    '重复执行迁移不报错（全是 if not exists）',
    Number(again.tables) === 2 && Number(again.funcs) === 5,
    `tables=${again.tables} funcs=${again.funcs}`,
  )
} catch (e) {
  check('重复执行迁移不报错（全是 if not exists）', false, e.message)
}

/* ══════════════ 6. 预检 #2：造红 —— 迁移后应当报冲突 ══════════════ */

const pre2 = (await db.query(PREFLIGHT)).rows[0]
console.log(`\n【预检 #2（迁移后）】${pre2.结论}  冲突数=${pre2.冲突数}`)
console.log(`  明细：${pre2.明细}\n`)
check('造红：迁移后预检必须报出冲突（否则预检没有判别力）', Number(pre2.冲突数) > 0, `冲突数=${pre2.冲突数}`)
check(
  '造红：冲突明细里确实包含 skills 与 publish_skill',
  pre2.明细.includes('skills') && pre2.明细.includes('publish_skill'),
)

/* ══════════════ 7. 两个站的既有对象是否原封不动 ══════════════ */

const sentinels = (
  await db.query(`
    select 'guestbook' as t, count(*)::int as n from public.guestbook_messages
    union all select 'bookmarks', count(*)::int from public.bookmarks
    union all select 'app_config', count(*)::int from public.app_config
  `)
).rows
check(
  '两个站的哨兵数据全部还在（各 1 行）',
  sentinels.every((r) => r.n === 1),
  sentinels.map((r) => `${r.t}=${r.n}`).join(' '),
)

// 顺带核对哨兵内容没被改写
const gb = (await db.query(`select email, content from public.guestbook_messages`)).rows[0]
check('哨兵内容一字未改', gb.email === 'a@b.c' && gb.content === '哨兵留言', `${gb.email}/${gb.content}`)

const others = (
  await db.query(`
    select p.proname
      from pg_proc p join pg_namespace n on n.oid = p.pronamespace
     where n.nspname = 'public'
       and p.proname in ('is_admin','touch_updated_at','post_guestbook_message',
                         'notify_guestbook_message','get_shared_nav','submit_feedback')
     order by 1
  `)
).rows.map((r) => r.proname)
check('两个站的 6 个函数全部还在（没被覆盖）', others.length === 6, others.join(', '))

const otherTables = (
  await db.query(`
    select c.relname from pg_class c join pg_namespace n on n.oid = c.relnamespace
     where n.nspname='public' and c.relkind='r'
       and c.relname in ('guestbook_messages','app_config','bookmarks','feedback',
                         'notes','discover_sites','share_settings')
     order by 1
  `)
).rows.map((r) => r.relname)
check('两个站的 7 张表全部还在', otherTables.length === 7, otherTables.join(', '))

// 🔴 前后快照逐字节对比 —— 「没有附带损伤」唯一站得住的证据
const after = await snapshot()

const fnDrift = OTHER_FNS.filter((k) => before.fns.get(k) !== after.fns.get(k))
check(
  '两个站的 6 个函数定义逐字节一致（无静默覆盖）',
  fnDrift.length === 0,
  fnDrift.length ? `被改写：${fnDrift.join(', ')}` : OTHER_FNS.join(', '),
)

const colDrift = OTHER_TABLES.filter((t) => {
  const b = before.cols.filter((c) => c.startsWith(t + '.')).join('|')
  const a = after.cols.filter((c) => c.startsWith(t + '.')).join('|')
  return b !== a
})
check(
  '两个站的 7 张表列定义逐字节一致',
  colDrift.length === 0,
  colDrift.length ? `被改：${colDrift.join(', ')}` : `共 ${before.cols.length} 列全对得上`,
)

const idxDrift = [...before.idx.keys()].filter((k) => after.idx.get(k) !== before.idx.get(k))
check(
  '两个站既有索引定义逐字节一致',
  idxDrift.length === 0,
  idxDrift.length ? `被改：${idxDrift.join(', ')}` : `既有 ${before.idx.size} 个索引未动`,
)

// 反向确认：新增的函数正好是本迁移那 6 个（5 个公开 RPC + 1 个内部），不多不少
const addedFns = [...after.fns.keys()].filter((k) => !before.fns.has(k)).sort()
const wantFns = ['_client_ip', 'download_skill', 'get_skill', 'list_skills', 'publish_skill', 'register_install'].sort()
check(
  '新增函数恰好是这 6 个，没有顶替任何既有函数',
  addedFns.join(',') === wantFns.join(','),
  addedFns.join(', '),
)

const addedTables = [...new Set(after.cols.map((c) => c.split('.')[0]))]
  .filter((t) => !OTHER_TABLES.includes(t))
  .sort()
check(
  '新增表恰好是 skills / skill_upload_log',
  addedTables.join(',') === 'skill_upload_log,skills',
  addedTables.join(', '),
)

/* ══════════════ 8. anon 视角：读不到 / 写不进 / 内部函数调不动 ══════════════ */

await db.exec(`grant usage on schema public to anon;`)

// 7a. revoke 生效 → 硬性 permission denied（这才是生产环境的真实表现）
await db.exec(`set role anon;`)
const a1 = await tryQuery(`select * from public.skills`)
const a2 = await tryQuery(`select * from public.skill_upload_log`)
await db.exec(`reset role;`)
check(
  'anon 直接读 skills 被拒（revoke 生效，非「0 行」）',
  !a1.ok && a1.code === '42501',
  a1.ok ? `居然读到 ${a1.res.rows.length} 行` : a1.code,
)
check('anon 直接读 skill_upload_log 被拒', !a2.ok && a2.code === '42501', a2.ok ? '读到了' : a2.code)

// 7b. 🔴 纵深防御：就算有人把 SELECT 还回去，RLS（零策略）也必须兜住
await db.exec(`grant select on public.skills to anon;`)
await db.exec(`set role anon;`)
const a3 = await tryQuery(`select * from public.skills`)
await db.exec(`reset role;`)
await db.exec(`revoke select on public.skills from anon;`)
check(
  '即使显式 grant select，RLS 零策略仍过滤成 0 行（第二道锁真的在）',
  a3.ok && a3.res.rows.length === 0,
  a3.ok ? `${a3.res.rows.length} 行` : `报错 ${a3.code}`,
)

// 7c. anon 不能绕过 RPC 直接写表
await db.exec(`grant insert on public.skills to anon;`)
await db.exec(`set role anon;`)
const a4 = await tryQuery(
  `insert into public.skills (slug,name,description,category,readme,files,file_count,total_bytes,hash,bundle_b64)
   values ('x','x','x','other','x','[]'::jsonb,1,1,'${'0'.repeat(64)}','x')`,
)
await db.exec(`reset role;`)
await db.exec(`revoke insert on public.skills from anon;`)
check(
  'anon 无法绕过 RPC 直接 insert（RLS 挡住写入）',
  !a4.ok || a4.res.affectedRows === 0,
  a4.ok ? `affectedRows=${a4.res.affectedRows}` : a4.code,
)

// 7d. 内部函数 _client_ip 不该被外部调用
await db.exec(`set role anon;`)
const a5 = await tryQuery(`select public._client_ip()`)
await db.exec(`reset role;`)
check('anon 调不动内部函数 _client_ip()', !a5.ok && a5.code === '42501', a5.ok ? '调通了（不该）' : a5.code)

/* ══════════════ 9. 5 个 RPC 全部以 anon 身份调 ══════════════ */

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
  name: 'pgtest',
  description: 'PGlite 里验证用的技能。',
  category: 'development',
  tags: ['测试'],
  version: '1.0.0',
  license: 'MIT',
  author: 'qa',
  readme: md,
  files: [{ path: 'SKILL.md', size: md.length, kind: 'text' }],
  file_count: 1,
  total_bytes: md.length,
  hash,
  bundle_b64: b64,
  ...over,
})

await db.exec(`set role anon;`)

/**
 * 以超级用户身份直读表 —— 仅用于**测试内部断言**（比如「下载量真的落库了吗」）。
 * anon 读不到表是设计如此，所以断言必须换个身份，否则会把自己的测试写成 42501。
 * 用完立刻切回 anon，避免后面的 RPC 测试「作弊」。
 */
const asRoot = async (sql, params) => {
  await db.exec(`reset role;`)
  const res = await db.query(sql, params)
  await db.exec(`set role anon;`)
  return res
}

const pub = async (p) =>
  (await db.query(`select public.publish_skill($1::jsonb) as r`, [JSON.stringify(p)])).rows[0].r

const r1 = await pub(payload())
check('publish_skill 首次发布 → created', r1.ok === true && r1.code === 'created', JSON.stringify(r1))

const r2 = await pub(payload())
check(
  'publish_skill 同内容再发 → exists（按 hash 去重）',
  r2.ok === true && r2.code === 'exists' && r2.slug === r1.slug,
  JSON.stringify(r2),
)

const r3 = await pub(payload({ hash: 'f'.repeat(64) }))
check('publish_skill 同名不同内容 → slug 自动加后缀', r3.ok === true && r3.slug === 'pgtest-2', JSON.stringify(r3))

const r4 = await pub(payload({ hash: 'a'.repeat(64), files: [{ path: 'a.py', size: 1, kind: 'text' }] }))
check('publish_skill 缺 SKILL.md → missing_skill_md', r4.ok === false && r4.code === 'missing_skill_md', JSON.stringify(r4))

const r5 = await pub(payload({ hash: 'not-a-hash' }))
check('publish_skill hash 不是 sha256 → invalid_payload', r5.ok === false && r5.code === 'invalid_payload', JSON.stringify(r5))

const r6 = await pub(payload({ hash: 'b'.repeat(64), bundle_b64: Buffer.from('不是zip的内容').toString('base64') }))
check('publish_skill 不是真 zip → invalid_payload', r6.ok === false && r6.code === 'invalid_payload', JSON.stringify(r6))

const r7 = await pub(payload({ hash: 'c'.repeat(64), name: '' }))
check('publish_skill name 为空 → invalid_payload', r7.ok === false && r7.code === 'invalid_payload', JSON.stringify(r7))

const r8 = await pub(payload({ hash: 'd'.repeat(64), total_bytes: 5 * 1024 * 1024 }))
check('publish_skill 超过体积上限 → too_large', r8.ok === false && r8.code === 'too_large', JSON.stringify(r8))

const r9 = await pub(payload({ hash: 'e'.repeat(64), category: '瞎写的分类' }))
check('publish_skill 非法分类 → 落回 other（不报错）', r9.ok === true, JSON.stringify(r9))
const cat = (await asRoot(`select category from public.skills where slug = $1`, [r9.slug])).rows[0].category
check('  该技能实际存的 category = other', cat === 'other', cat)

// —— 已发布行数：r1 created、r2 exists（不新建）、r3 created、r9 created = 3 ——
const l1 = (await db.query(`select public.list_skills('', 'all', 'new', 50, 0) as r`)).rows[0].r
check('list_skills 返回全部（3 条已发布）', l1.ok === true && l1.total === 3, `total=${l1.total}`)
check('list_skills 不含 bundle_b64（列表接口不该带包体）', !JSON.stringify(l1.items).includes('bundle_b64'))

const l2 = (await db.query(`select public.list_skills('pgtest', 'all', 'new', 50, 0) as r`)).rows[0].r
check('list_skills 关键词搜索生效', l2.total === 3, `total=${l2.total}`)

// 已发布 3 条：r1(development) / r3(development) / r9(非法分类→other)
// 所以 development 过滤应当是 2，不是 3 —— 这里正好顺带验了分类过滤是真过滤
const l3 = (await db.query(`select public.list_skills('', 'development', 'downloads', 50, 0) as r`)).rows[0].r
check('list_skills 分类 + 排序生效（development → 2）', l3.ok === true && l3.total === 2, `total=${l3.total}`)

const l5 = (await db.query(`select public.list_skills('', 'other', 'new', 50, 0) as r`)).rows[0].r
check('list_skills 分类 other → 1（就是那条非法分类落回来的）', l5.total === 1, `total=${l5.total}`)

const l4 = (await db.query(`select public.list_skills('', 'design', 'new', 50, 0) as r`)).rows[0].r
check('list_skills 分类过滤真的在过滤（design → 0）', l4.total === 0, `total=${l4.total}`)

const g1 = (await db.query(`select public.get_skill($1) as r`, [r1.slug])).rows[0].r
check(
  'get_skill 返回 readme 与文件表',
  g1.ok === true && g1.skill.readme.includes('# PG Test') && g1.skill.files.length === 1,
  JSON.stringify({ ok: g1.ok, files: g1.skill?.files?.length }),
)

const g2 = (await db.query(`select public.get_skill('不存在的技能') as r`)).rows[0].r
check('get_skill 不存在 → not_found', g2.ok === false && g2.code === 'not_found')

const d1 = (await db.query(`select public.download_skill($1) as r`, [r1.slug])).rows[0].r
check(
  'download_skill 返回包体（PK 魔数）且下载量 +1',
  d1.ok === true &&
    d1.downloads === 1 &&
    Buffer.from(d1.bundle_b64, 'base64').subarray(0, 2).toString() === 'PK',
  `downloads=${d1.downloads}`,
)

const d2 = (await db.query(`select public.download_skill($1) as r`, [r1.slug])).rows[0].r
check('download_skill 再下一次 → 2', d2.downloads === 2, String(d2.downloads))

const i1 = (await db.query(`select public.register_install($1) as r`, [r1.slug])).rows[0].r
check('register_install → 安装量 1', i1.ok === true && i1.installs === 1, JSON.stringify(i1))

const d3 = (await db.query(`select public.download_skill('不存在') as r`)).rows[0].r
check('download_skill 不存在 → not_found（且不报错）', d3.ok === false && d3.code === 'not_found')

// 下载量确实落库了（不是只在返回值里 +1）
const dRow = (await asRoot(`select downloads, installs from public.skills where slug = $1`, [r1.slug])).rows[0]
check('下载量 / 安装量真的写进了表', dRow.downloads === 2 && dRow.installs === 1, JSON.stringify(dRow))

/* ══════════════ 10. 限流（放最后，它会污染后续所有调用）══════════════ */

const loggedBefore = (await asRoot(`select count(*)::int as n from public.skill_upload_log`)).rows[0].n

let attempts = 0
let limited = null
for (let i = 0; i < 40; i++) {
  attempts++
  const r = await pub(payload({ hash: `1${String(i).padStart(63, '0')}` }))
  if (r.code === 'rate_limited') {
    limited = i
    break
  }
}

const loggedAfter = (await asRoot(`select count(*)::int as n from public.skill_upload_log`)).rows[0].n

check(
  '限流生效：连续发布最终被 rate_limited 拦下',
  limited !== null,
  limited === null ? `${attempts} 次都没被拦` : `第 ${limited + 1} 次追加尝试时被拦`,
)
check('限流不是一上来就拦（阈值合理）', limited !== null && limited >= 5, `第 ${(limited ?? 0) + 1} 次才拦`)
check(
  '限流阈值 = 20/小时（记账数正好停在 20）',
  loggedAfter === 20,
  `记账 ${loggedBefore} → ${loggedAfter}`,
)
check(
  '被拦的那次没有记账（拦在 insert 之前）',
  loggedAfter === 20 && limited !== null,
  `拦截点未计入`,
)
// 失败校验的提交也计数 —— 否则「反复塞垃圾」可以无限刷
check(
  '校验失败的提交也计入限流（9 次里 6 次是失败的）',
  loggedBefore === 9,
  `前 9 次发布共记账 ${loggedBefore} 条`,
)

await db.exec(`reset role;`)
await db.close()

/* ══════════════ 收尾 ══════════════ */

const failed = results.filter((r) => !r.pass)
console.log('\n' + '─'.repeat(64))
console.log(`合计 ${results.length} 项，通过 ${results.length - failed.length}，失败 ${failed.length}`)
if (failed.length) {
  console.log('失败项：')
  for (const f of failed) console.log(`  ❌ ${f.name}`)
}
process.exit(failed.length ? 1 : 0)
