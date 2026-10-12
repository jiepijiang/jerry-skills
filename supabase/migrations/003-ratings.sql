-- ============================================================================
-- 003 — 技能评分（5 星，按 IP 一人一票）
-- ----------------------------------------------------------------------------
-- 需求：访客能给技能打 1~5 星；卡片与详情页显示「平均分 + 评分人数」；
--       列表多一个「评分最高」排序。
--
-- 这个站**没有任何账号体系**（纯静态托管 + 匿名上传），所以「一个人」只能靠
-- IP 来近似。这不是完美的防刷，但配合下面的设计，它挡住了最常见的那种脏数据：
-- 同一个人连点把自己喜欢的技能刷到 5 星。
--
-- ── 三个关键设计决定（都是取舍，写清楚免得后来的人以为可以随便改）──
--
-- ① **一人一票，改分不算新票**：主键 (slug, ip) + `on conflict do update`。
--    重复打分是「改分」而不是「加票」—— 所以 rating_count 数的是**人数**，
--    不是**投票次数**。这也是「不需要限流表」的原因：刷分的收益为零，
--    连点只会在同一行上反复覆盖，不放大任何东西。
--
-- ② **不存冗余计数字段，每次现算**。
--    downloads / installs 是列（001 里），因为它们是「一次一个 +1」的单调累加，
--    没有第二个真相源。评分不同：真正的真相源是 skill_ratings 这张表本身，
--    平均分和人数都是它的**派生值**。存成列就必须回答「谁负责同步」——
--    而这里有个绕不开的场景：admin 删掉技能再重新上传（本站的「更新内容」
--    就是这么做的，见 .workbuddy-ai/skill-import/upload.mjs 的 --delete-first），
--    slug 不变、行是新的，冗余列会从 0 重新开始，和评分表当场对不上。
--    现算没有这个问题：任何时候算出来的都是对的。
--    代价是不能靠普通索引排序 —— 但本站 50 来个技能、每页 24 行，
--    24 次主键前缀查找完全不值得为它引入一个「需要维护的一致性风险」。
--
-- ③ **外键 on delete cascade：删技能时评分一起走**。
--    另一条路是不加外键、让评分活下来，好处是「作者修个错别字」不丢口碑。
--    但本站的语义是**根本没有「更新」这件事**（见 SkillCard.vue 的注释：
--    publish_skill 从不 update 已有行，内容变了就换个 slug 插新行）——
--    删掉再传是一次**新上传**。而留着的评分会有一个更糟的后果：
--    slug 是可以被后来的另一个技能复用的（比如 `docx`），
--    那时新技能会凭空继承一堆属于别人的分数。
--    宁可在重新上传时诚实地从 0 开始，也不要让分数挂错对象。
--
-- ── 已知局限（必须说出来，不能假装它不存在）──
--    `_client_ip()` 取的是 x-forwarded-for 的第一段，而**客户端可以自己塞这个头**
--    （001 里已经写明这条）。所以「一人一票」是可以被伪造 IP 绕过的。
--    没有账号体系就无法根治；真要收紧，只能上登录。
--    另外 `_client_ip()` 取不到头时返回 'unknown'，那些请求会共享同一票。
--    线上走 Supabase（边缘一定带 x-forwarded-for），正常不会落到这个分支。
--
-- 幂等：整份文件可重复执行（create table if not exists / create or replace）。
-- 执行位置：Supabase SQL Editor（anon key 建不了函数）。**要在 001 之后跑**。
-- ============================================================================

-- ---------------------------------------------------------------- 1. 表

create table if not exists public.skill_ratings (
  slug       text        not null references public.skills (slug) on delete cascade,
  ip         text        not null,
  score      smallint    not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  -- 一人一票：同一个 IP 对同一个技能只有一行，「改分」是 update 不是 insert
  primary key (slug, ip),
  constraint skill_ratings_score_range check (score between 1 and 5)
);

comment on table public.skill_ratings is
  '技能评分；主键 (slug, ip) 保证一人一票。评分人身份只能用 IP 近似，表本身对 anon 关闭';
comment on column public.skill_ratings.score is '1~5 星；重复打分为改分（覆盖），不累加';

-- 主键 (slug, ip) 的 btree 已经能服务 `where slug = ?` 的前缀查找，
-- 所以 list_skills / get_skill 里那个按 slug 聚合的子查询不需要额外索引。

-- RLS 打开但**不建任何 policy** → 除 service_role 外谁也读不到、写不了
alter table public.skill_ratings enable row level security;

revoke all on public.skill_ratings from anon, authenticated;


-- ------------------------------------------------------------ 2. 打分

-- 打分 / 改分。返回打分后的聚合结果，前端一次往返就能刷新显示。
--
-- 为什么不在这里做限流：见文件头 ① —— 一人一票让「刷分」没有收益，
-- 而重复请求只是在同一行上覆盖。真正需要防的是「伪造 IP 刷票」，
-- 那件事限流表也防不住（限流同样按 IP 计数）。
create or replace function public.rate_skill(p_slug text, p_score integer)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_slug  text    := btrim(coalesce(p_slug, ''));
  v_score integer := coalesce(p_score, 0);
  v_ip    text    := public._client_ip();
  v_cnt   integer;
  v_avg   numeric;
begin
  if v_slug = '' then
    return jsonb_build_object('ok', false, 'code', 'invalid_payload', 'detail', 'slug 为空');
  end if;

  -- 分值先卡住。不卡的话 check 约束会抛 23514 → 变成 500，
  -- 而「你传了个 6 分」应该是 200 + invalid_payload（业务失败走 200，见 supabase.js 文件头）
  if v_score < 1 or v_score > 5 then
    return jsonb_build_object('ok', false, 'code', 'invalid_payload', 'detail', 'score 必须在 1~5');
  end if;

  -- 只给「存在且已发布」的技能打分。
  -- 少了这一步，任何人都能给一个不存在的 slug 建出评分行 —— 表会被垃圾撑大，
  -- 而且那个 slug 将来真被人用了就会凭空带着一堆分数上线。
  if not exists (
    select 1 from public.skills s where s.slug = v_slug and s.status = 'published'
  ) then
    return jsonb_build_object('ok', false, 'code', 'not_found');
  end if;

  -- 一人一票：冲突就改分。created_at 保持首次打分的时间不动，只推 updated_at
  insert into public.skill_ratings (slug, ip, score)
  values (v_slug, v_ip, v_score::smallint)
  on conflict (slug, ip) do update
     set score      = excluded.score,
         updated_at = now();

  -- 现算聚合（见文件头 ②）。这里也顺带把结果返回给前端，
  -- 免得打完分还要再拉一次列表才知道新的平均分。
  select count(*)::integer, round(avg(x.score)::numeric, 2)
    into v_cnt, v_avg
    from public.skill_ratings x
   where x.slug = v_slug;

  return jsonb_build_object(
    'ok',           true,
    'slug',         v_slug,
    'my_score',     v_score,
    'rating_count', v_cnt,
    'rating_avg',   v_avg
  );
end $$;

grant execute on function public.rate_skill(text, integer) to anon, authenticated;


-- ------------------------------------------------------------ 3. 列表

-- 重定义 list_skills：多返回 rating_count / rating_avg，并新增 'rating' 排序分支。
-- 签名与 001 完全一致（否则 create or replace 会变成「新建一个重载」）。
create or replace function public.list_skills(
  p_query    text default '',
  p_category text default 'all',
  p_sort     text default 'new',
  p_limit    integer default 24,
  p_offset   integer default 0
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_where text;
  v_order text;
  v_total bigint;
  v_items jsonb;
  v_limit integer := greatest(1, least(coalesce(p_limit, 24), 100));
  v_offset integer := greatest(0, coalesce(p_offset, 0));
  v_kw text;
begin
  -- 排序分支白名单 —— 绝不要把 p_sort 直接拼进 SQL
  v_order := case p_sort
    when 'downloads' then 's.downloads desc, s.created_at desc'
    when 'installs'  then 's.installs desc, s.created_at desc'
    -- 未评分的排最后（DESC 默认 NULLS FIRST，必须显式写 nulls last，
    -- 否则「评分最高」会先列出一堆 0 票的技能）。
    -- 同分时人多的在前 —— 20 个人打的 4.5 比 1 个人打的 4.5 更可信。
    when 'rating'    then 'r.avg_score desc nulls last, r.cnt desc, s.created_at desc'
    else 's.created_at desc'
  end;

  v_where := ' where s.status = ''published'' ';

  if coalesce(btrim(p_category), '') not in ('', 'all') then
    v_where := v_where || format(' and s.category = %L', p_category);
  end if;

  v_kw := btrim(coalesce(p_query, ''));
  if v_kw <> '' then
    v_where := v_where || format(
      ' and (s.name ilike %1$L or s.description ilike %1$L or s.author ilike %1$L or array_to_string(s.tags, '' '') ilike %1$L) ',
      '%' || v_kw || '%');
  end if;

  execute 'select count(*) from public.skills s ' || v_where into v_total;

  -- left join lateral：每个技能带一行聚合。用聚合子查询（无 group by）而不是
  -- `left join skill_ratings` + group by —— 后者要为每个技能把评分行展开再收拢，
  -- 而且 group by 一旦漏列就会把 items 结构改掉。
  execute format(
    'select coalesce(jsonb_agg(t), ''[]''::jsonb) from ('
    '  select s.slug, s.name, s.description, s.category, s.tags, s.version, s.license,'
    '         s.author, s.file_count, s.total_bytes, s.downloads, s.installs, s.created_at,'
    '         r.cnt       as rating_count,'
    '         r.avg_score as rating_avg'
    '    from public.skills s'
    '    left join lateral ('
    '      select count(*)::integer as cnt, round(avg(x.score)::numeric, 2) as avg_score'
    '        from public.skill_ratings x'
    '       where x.slug = s.slug'
    '    ) r on true'
    '   %s order by %s limit %s offset %s'
    ') t',
    v_where, v_order, v_limit, v_offset)
  into v_items;

  return jsonb_build_object('ok', true, 'total', v_total, 'items', v_items);
end $$;

grant execute on function public.list_skills(text, text, text, integer, integer) to anon, authenticated;


-- ------------------------------------------------------------ 4. 详情

-- 重定义 get_skill：多返回评分聚合，以及**当前这个 IP 自己打过的分**。
-- my_score 让详情页能直接高亮「你已评 3 星」，不用前端再存一份本地状态
-- （本地状态在换设备 / 换浏览器时就丢了，而且和真实票源可能不一致）。
create or replace function public.get_skill(p_slug text)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  r      public.skills;
  v_ip   text := public._client_ip();
  v_cnt  integer;
  v_avg  numeric;
  v_mine smallint;
begin
  select * into r from public.skills s
   where s.slug = p_slug and s.status = 'published';

  if not found then
    return jsonb_build_object('ok', false, 'code', 'not_found');
  end if;

  select count(*)::integer, round(avg(x.score)::numeric, 2)
    into v_cnt, v_avg
    from public.skill_ratings x
   where x.slug = r.slug;

  -- 没打过分为 null（select into 无行时把变量置空），前端据此显示「还没评分」
  select x.score into v_mine
    from public.skill_ratings x
   where x.slug = r.slug and x.ip = v_ip;

  return jsonb_build_object('ok', true, 'skill', jsonb_build_object(
    'slug',         r.slug,
    'name',         r.name,
    'description',  r.description,
    'category',     r.category,
    'tags',         r.tags,
    'version',      r.version,
    'license',      r.license,
    'author',       r.author,
    'readme',       r.readme,
    'files',        r.files,
    'file_count',   r.file_count,
    'total_bytes',  r.total_bytes,
    'hash',         r.hash,
    'downloads',    r.downloads,
    'installs',     r.installs,
    'rating_count', v_cnt,
    'rating_avg',   v_avg,
    'my_score',     v_mine,
    'created_at',   r.created_at
  ));
end $$;

grant execute on function public.get_skill(text) to anon, authenticated;


-- ---------------------------------------------------------------- 5. 自检

-- 期望：rating_tables = 1，rating_funcs = 1，rls_on = 1，fk_on = 1，policies = 0
select
  (select count(*) from information_schema.tables
    where table_schema = 'public' and table_name = 'skill_ratings')                    as rating_tables,
  (select count(*) from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.proname = 'rate_skill')                           as rating_funcs,
  (select count(*) from pg_tables
    where schemaname = 'public' and tablename = 'skill_ratings' and rowsecurity)       as rls_on,
  (select count(*) from information_schema.table_constraints
    where table_schema = 'public' and table_name = 'skill_ratings'
      and constraint_type = 'FOREIGN KEY')                                             as fk_on,
  (select count(*) from pg_policies
    where schemaname = 'public' and tablename = 'skill_ratings')                       as policies;
