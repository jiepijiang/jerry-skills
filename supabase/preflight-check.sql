-- ============================================================================
-- 预检（只读）—— 跑 001-skills.sql **之前**先执行这一份
-- ----------------------------------------------------------------------------
-- 背景：这个 Supabase 项目是 jerry-site / jerry-tools / jerry-skills **共用**的。
--       如果本迁移要创建的对象名和另外两个站撞了，后果分两种，严重程度差很多：
--
--   ① 表名撞 → `create table if not exists` 会**静默跳过**建表，
--      紧接着在它上面建索引会因为「列不存在」报错。整段回滚，**不会坏数据**，
--      但你会拿到一个看不懂的错误，还得回头查半天。
--
--   ② 函数名撞（同名同参数）→ `create or replace function` 会**静默覆盖**，
--      **一句报错都没有**。这是真正危险的一种：另一个站的功能会突然失效，
--      而你会以为「只是加了个技能站」。
--
--   ③ 索引 / 序列名撞 → 直接报错，同样会整段回滚。
--
-- 所以先跑这一份。**结论行永远有输出**，不会出现「0 行」这种
-- 「没冲突」和「查询没跑成」分不清的情况。
--
-- ⚠️ 本文件全是 select，**不改任何东西**，可以放心执行。
-- ============================================================================

with hits as (
  -- 表
  select '表' as kind, c.relname as name
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
   where n.nspname = 'public'
     and c.relkind = 'r'
     and c.relname in ('skills', 'skill_upload_log')

  union all

  -- 函数（这一类的风险最高：会被静默覆盖）
  select '函数', p.proname
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public'
     and p.proname in (
       '_client_ip', 'list_skills', 'get_skill',
       'download_skill', 'register_install', 'publish_skill'
     )

  union all

  -- 索引
  select '索引', i.indexname
    from pg_indexes i
   where i.schemaname = 'public'
     and i.indexname in (
       'skills_created_idx', 'skills_downloads_idx', 'skills_installs_idx',
       'skills_category_idx', 'skills_hash_uniq', 'skill_upload_log_ip_idx'
     )

  union all

  -- 序列（bigserial 会自动建一个）
  select '序列', c.relname
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
   where n.nspname = 'public'
     and c.relkind = 'S'
     and c.relname = 'skill_upload_log_id_seq'
)
select
  case
    when count(*) = 0 then '✅ 无冲突，可以安全执行 001-skills.sql'
    else '❌ 发现 ' || count(*) || ' 个同名对象 —— 先确认它们不属于 jerry-site / jerry-tools，再决定怎么办'
  end                                        as 结论,
  count(*)                                   as 冲突数,
  coalesce(string_agg(kind || ':' || name, '、' order by kind, name), '（无）') as 明细
from hits;
