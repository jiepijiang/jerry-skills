/**
 * 生成入库 SQL。
 * ---------------------------------------------------------------------------
 * 为什么不走 publish_skill：那个 RPC 有**每 IP 每小时 20 次**的限流（见 001-skills.sql），
 * 42 个包得分三个小时传完。直接在 SQL Editor 里 insert 绕开它 ——
 * 反正 anon key 本来就没有建表/写表的权限，这条路只能由站主在 SQL Editor 里走。
 *
 * 按维度拆成多个文件：单个 SQL 太大会让 SQL Editor 卡住，也不方便分批粘贴。
 */
import { readFileSync, writeFileSync } from 'node:fs'

const real = JSON.parse(readFileSync(new URL('./out/real.json', import.meta.url), 'utf8'))
const authored = JSON.parse(readFileSync(new URL('./out/authored.json', import.meta.url), 'utf8'))
const ALL = [...real, ...authored]

const DIMS = [
  ['pc', '01-pc', 'PC 桌面端 Web'],
  ['h5', '02-h5', 'H5 移动端 Web'],
  ['app', '03-app', 'APP 移动应用'],
  ['landing', '04-landing', '落地页'],
  ['biz', '05-biz', '业务场景'],
  ['admin', '06-admin', '后台管理系统'],
  ['style', '07-style', 'UI 风格'],
]

/** Postgres 字符串字面量：用 dollar-quoting 包住含引号的长文本 */
const dq = (tag, s) => `$${tag}$${s}$${tag}$`
const lit = (s) => `'${String(s).replace(/'/g, "''")}'`
const arr = (a) => `array[${a.map(lit).join(', ')}]::text[]`

const HEAD = (title, n) => `-- ============================================================================
-- UI 技能包入库 · ${title}（${n} 个）
-- ----------------------------------------------------------------------------
-- 跑法：Supabase → SQL Editor → 新建查询 → 粘贴本文件 → Run。
--
-- ⚠️ 幂等：末尾是 \`on conflict do nothing\`，重复跑不会插重复，
--    也不会覆盖已经攒下的下载量 / 安装量 / 评分。
-- ⚠️ 需要先跑过 001-skills.sql（本文件只 insert，不建表）。
-- ============================================================================

`

function stmt(s) {
  const readme = dq('md', s.readme)
  const b64 = dq('b64', s.bundle_b64)
  const files = lit(JSON.stringify(s.files))
  return `insert into public.skills
  (slug, name, description, category, tags, version, license, author,
   readme, files, file_count, total_bytes, hash, bundle_b64, status)
values (
  ${lit(s.slug)}, ${lit(s.name)}, ${lit(s.description)}, 'ui',
  ${arr(s.tags)}, ${lit(s.version)}, ${lit(s.license)}, ${lit(s.author)},
  ${readme},
  ${files}::jsonb, ${s.file_count}, ${s.total_bytes}, ${lit(s.hash)},
  ${b64},
  'published'
)
on conflict do nothing;
`
}

// ⚠️ 直接写进**交付目录**（seed-ui/ 顶层），不要写 out/ 再手工拷。
//    之前是 `out/sql/` + 人工拷贝，等于交付物和生成物可以不一样 ——
//    这条链路上任何一次「忘了拷」都会让用户拿到旧文件。
const manifest = []
for (const [dim, file, title] of DIMS) {
  const items = ALL.filter((s) => s.dim === dim)
  if (!items.length) continue
  const body = items.map(stmt).join('\n')
  const sql = HEAD(title, items.length) + body
  const p = new URL(`./${file}.sql`, import.meta.url)
  writeFileSync(p, sql)
  manifest.push({ file: `${file}.sql`, title, n: items.length, kb: Math.round(Buffer.byteLength(sql) / 1024) })
}

// 自检
// ---------------------------------------------------------------------------
// ⚠️ 下面那条「维度分布」查询**必须从数据里生成白名单**。
//    最早这里是手写的 `group by 1`，而 `group by 1` 指第一个 select 项（`count(*)`）
//    —— 聚合函数不能当分组键，Postgres 直接报 `42803`。
//    更糟的是：自检文件当时**从没被真正执行过**（构建只生成、不跑），
//    所以这个语法错误一路活到了用户手上。
//    教训：**生成的文件也要真跑一遍**，见 verify-ui-sql.mjs 的第 7 节。
const DIM_LABEL = {
  pc: 'PC 桌面端', h5: 'H5 移动端', app: 'APP', landing: '落地页',
  biz: '业务场景', admin: '后台管理', style: 'UI 风格',
}
const DIM_VALUES = DIMS.flatMap(([key], i) =>
  ALL.filter((s) => s.dim === key).map((s) => `    (${i + 1}, '${DIM_LABEL[key]}', '${s.slug}')`),
).join(',\n')

const CHECK = `-- ============================================================================
-- UI 技能包入库 · 自检
-- ----------------------------------------------------------------------------
-- 跑完上面 7 个文件后执行本文件，核对结果。
-- ============================================================================

-- 1. UI 分类下的技能数（期望 42）
select 'ui 技能总数' as 指标, count(*)::text as 值
  from public.skills where category = 'ui' and status = 'published';

-- 2. 每个维度各几个（期望每行都是 6）
--    数据库里没有「维度」这一列（统一是 category = 'ui'），所以用 slug 白名单来分组。
--    这份白名单是 gen-sql.mjs 从技能数据里**自动生成**的，不是手抄的。
with dim(ord, 维度, slug) as (
  values
${DIM_VALUES}
)
select d.ord                                                as "#",
       d.维度,
       count(s.slug)                                        as 技能数,
       case when count(s.slug) = 6 then '✅' else '⚠️ 少了' end as 判定
  from dim d
  left join public.skills s
    on s.slug = d.slug
   and s.category = 'ui'
   and s.status = 'published'
 group by d.ord, d.维度
 order by d.ord;

-- 3. 关键字段有没有空（期望 0）
select '缺字段的行数' as 指标,
       count(*)::text as 值
  from public.skills
 where category = 'ui'
   and (description = '' or author = '' or license = '' or hash = '' or bundle_b64 = '');

-- 4. 标签有没有真的写进去（设计区间 5~7，期望判定为 ✅）
select '标签数范围' as 指标,
       min(array_length(tags, 1))::text || ' ~ ' || max(array_length(tags, 1))::text as 值,
       case when min(array_length(tags, 1)) >= 5 and max(array_length(tags, 1)) <= 7
            then '✅' else '⚠️ 越界' end as 判定
  from public.skills where category = 'ui';

-- 5. 逐条清单（看名字和标签对不对）
select slug, name, array_length(tags, 1) as 标签数, round(total_bytes/1024.0, 1) as KB
  from public.skills where category = 'ui' order by slug;
`
writeFileSync(new URL('./99-check.sql', import.meta.url), CHECK)
manifest.push({ file: '99-check.sql', title: '自检', n: 0, kb: Math.round(Buffer.byteLength(CHECK) / 1024) })

console.log('生成完毕：')
let total = 0
for (const m of manifest) {
  console.log(`  ${m.file.padEnd(16)} ${String(m.n).padStart(2)} 个  ${String(m.kb).padStart(5)} KB   ${m.title}`)
  total += m.kb
}
console.log(`\n合计约 ${(total / 1024).toFixed(2)} MB，共 ${ALL.length} 个技能`)
const byDim = {}
for (const s of ALL) byDim[s.dim] = (byDim[s.dim] || 0) + 1
console.log('维度分布:', JSON.stringify(byDim))
console.log('hash 去重:', new Set(ALL.map((s) => s.hash)).size, '/', ALL.length)
console.log('slug 去重:', new Set(ALL.map((s) => s.slug)).size, '/', ALL.length)
