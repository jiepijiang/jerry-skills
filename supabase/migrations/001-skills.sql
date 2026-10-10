-- ============================================================================
-- 001 — Skill Hub 的存储与接口
-- ----------------------------------------------------------------------------
-- 一个技能 = 一行。技能包（zip）以 base64 存在行内，**不用 Supabase Storage**：
--   · Storage 要额外配 bucket + policy，而 anon 写入的 policy 很容易配错
--     （配宽了是任何人都能往你桶里塞东西，配窄了上传直接失败）；
--   · 技能包本身就小（上限 2 MB），行内存储足够，而且**下载和计数在同一个事务里**，
--     不会出现「扣了计数没给文件」。
--   · 代价：单行较大。Postgres 的 TOAST 会自动把大字段挪到旁表，行本身仍很快。
--
-- 访问模型：**表对所有角色关闭**（RLS 开、无 policy），全部走 SECURITY DEFINER 函数。
--   好处是 `bundle_b64` 这种大字段不可能被列表接口顺出来 —— 想拿必须调
--   download_skill，而那个函数会顺带 +1 下载量，计数天然不会漏。
--
-- ⚠️ 常量必须和 src/data/site.js 的 `limits` 一致（前端只是提前拦住，
--    这里才是真正的闸门）。改一处要同步改另一处。
--
-- 幂等：整份文件可重复执行。
-- 执行位置：Supabase SQL Editor（前端那个 anon key 建不了函数）。
-- ============================================================================

-- ---------------------------------------------------------------- 1. 表

create table if not exists public.skills (
  slug         text        primary key,
  name         text        not null,
  description  text        not null default '',
  category     text        not null default 'other',
  tags         text[]      not null default '{}',
  version      text        not null default '1.0.0',
  license      text        not null default '',
  author       text        not null default 'anonymous',
  readme       text        not null default '',
  files        jsonb       not null default '[]'::jsonb,
  file_count   integer     not null default 0,
  total_bytes  integer     not null default 0,
  hash         text        not null,
  bundle_b64   text        not null,
  downloads    integer     not null default 0,
  installs     integer     not null default 0,
  status       text        not null default 'published',
  created_at   timestamptz not null default now()
);

comment on table public.skills is 'AI Agent 技能包；只通过 RPC 访问，表本身对 anon 关闭';

create index if not exists skills_created_idx   on public.skills (created_at desc);
create index if not exists skills_downloads_idx on public.skills (downloads desc);
create index if not exists skills_installs_idx  on public.skills (installs desc);
create index if not exists skills_category_idx  on public.skills (category);

-- 同内容只存一份（重复上传直接返回已有的那条，不报错）
create unique index if not exists skills_hash_uniq on public.skills (hash);

-- 上传限流：按 IP + 时间窗计数
create table if not exists public.skill_upload_log (
  id         bigserial   primary key,
  ip         text        not null,
  created_at timestamptz not null default now()
);

create index if not exists skill_upload_log_ip_idx on public.skill_upload_log (ip, created_at desc);

-- RLS 打开但**不建任何 policy** → 除 service_role 外谁也读不到、写不了
alter table public.skills            enable row level security;
alter table public.skill_upload_log  enable row level security;

revoke all on public.skills           from anon, authenticated;
revoke all on public.skill_upload_log from anon, authenticated;


-- ------------------------------------------------------- 2. 取客户端 IP

create or replace function public._client_ip()
returns text
language plpgsql
stable
as $$
declare
  h jsonb;
begin
  h := coalesce(nullif(current_setting('request.headers', true), ''), '{}')::jsonb;
  return coalesce(
    nullif(btrim(split_part(coalesce(h ->> 'x-forwarded-for', ''), ',', 1)), ''),
    nullif(btrim(coalesce(h ->> 'cf-connecting-ip', '')), ''),
    'unknown'
  );
exception when others then
  -- 请求头缺失 / 不是合法 JSON 时不要 500，退化成 unknown
  return 'unknown';
end $$;

-- 内部函数，不对外
revoke all on function public._client_ip() from public, anon, authenticated;


-- ------------------------------------------------------------ 3. 列表

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

  execute format(
    'select coalesce(jsonb_agg(t), ''[]''::jsonb) from ('
    '  select s.slug, s.name, s.description, s.category, s.tags, s.version, s.license,'
    '         s.author, s.file_count, s.total_bytes, s.downloads, s.installs, s.created_at'
    '    from public.skills s %s order by %s limit %s offset %s'
    ') t',
    v_where, v_order, v_limit, v_offset)
  into v_items;

  return jsonb_build_object('ok', true, 'total', v_total, 'items', v_items);
end $$;

grant execute on function public.list_skills(text, text, text, integer, integer) to anon, authenticated;


-- ------------------------------------------------------------ 4. 详情

create or replace function public.get_skill(p_slug text)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  r public.skills;
begin
  select * into r from public.skills s
   where s.slug = p_slug and s.status = 'published';

  if not found then
    return jsonb_build_object('ok', false, 'code', 'not_found');
  end if;

  return jsonb_build_object('ok', true, 'skill', jsonb_build_object(
    'slug',        r.slug,
    'name',        r.name,
    'description', r.description,
    'category',    r.category,
    'tags',        r.tags,
    'version',     r.version,
    'license',     r.license,
    'author',      r.author,
    'readme',      r.readme,
    'files',       r.files,
    'file_count',  r.file_count,
    'total_bytes', r.total_bytes,
    'hash',        r.hash,
    'downloads',   r.downloads,
    'installs',    r.installs,
    'created_at',  r.created_at
  ));
end $$;

grant execute on function public.get_skill(text) to anon, authenticated;


-- ------------------------------------------------------------ 5. 下载

-- 下载与计数在同一个 UPDATE ... RETURNING 里完成：
-- 不存在 → not_found；存在 → 返回包体 + 递增后的下载量。
create or replace function public.download_skill(p_slug text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  r public.skills;
begin
  update public.skills s
     set downloads = s.downloads + 1
   where s.slug = p_slug and s.status = 'published'
  returning * into r;

  if not found then
    return jsonb_build_object('ok', false, 'code', 'not_found');
  end if;

  return jsonb_build_object(
    'ok',         true,
    'slug',       r.slug,
    'filename',   r.slug || '.zip',
    'bundle_b64', r.bundle_b64,
    'downloads',  r.downloads
  );
end $$;

grant execute on function public.download_skill(text) to anon, authenticated;


-- ------------------------------------------------------------ 6. 安装计数

create or replace function public.register_install(p_slug text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_installs integer;
begin
  update public.skills s
     set installs = s.installs + 1
   where s.slug = p_slug and s.status = 'published'
  returning s.installs into v_installs;

  if not found then
    return jsonb_build_object('ok', false, 'code', 'not_found');
  end if;

  return jsonb_build_object('ok', true, 'installs', v_installs);
end $$;

grant execute on function public.register_install(text) to anon, authenticated;


-- ------------------------------------------------------------ 7. 发布

create or replace function public.publish_skill(p_payload jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  -- ⚠️ 与 src/data/site.js 的 limits 一一对应
  c_max_files        constant integer := 200;
  c_max_total_bytes  constant integer := 2 * 1024 * 1024;   -- 2 MB
  c_max_bundle_b64   constant integer := 4 * 1024 * 1024;   -- base64 字符数
  c_max_name         constant integer := 64;
  c_max_desc         constant integer := 500;
  c_max_tags         constant integer := 12;
  c_rate_limit       constant integer := 20;                -- 每 IP 每小时
  c_categories       constant text[]  := array[
    'development','design','document','data','writing','devops','productivity','other'
  ];

  v_ip        text := public._client_ip();
  v_recent    integer;
  v_name      text;
  v_desc      text;
  v_category  text;
  v_tags      text[];
  v_readme    text;
  v_files     jsonb;
  v_file_cnt  integer;
  v_bytes     integer;
  v_hash      text;
  v_bundle    text;
  v_slug      text;
  v_base      text;
  v_n         integer := 2;
  v_existing  text;
begin
  if p_payload is null or jsonb_typeof(p_payload) <> 'object' then
    return jsonb_build_object('ok', false, 'code', 'invalid_payload');
  end if;

  -- 限流：先记账再校验 —— 否则「反复提交垃圾」不计数，限流形同虚设
  delete from public.skill_upload_log where created_at < now() - interval '1 day';
  select count(*) into v_recent
    from public.skill_upload_log
   where ip = v_ip and created_at > now() - interval '1 hour';
  if v_recent >= c_rate_limit then
    return jsonb_build_object('ok', false, 'code', 'rate_limited');
  end if;
  insert into public.skill_upload_log (ip) values (v_ip);

  -- 逐字段取，缺字段一律给安全默认值（不信任客户端）
  v_name  := btrim(coalesce(p_payload ->> 'name', ''));
  v_desc  := btrim(coalesce(p_payload ->> 'description', ''));
  v_readme := coalesce(p_payload ->> 'readme', '');
  v_hash  := btrim(coalesce(p_payload ->> 'hash', ''));
  v_bundle := coalesce(p_payload ->> 'bundle_b64', '');
  v_files := coalesce(p_payload -> 'files', '[]'::jsonb);
  v_file_cnt := coalesce((p_payload ->> 'file_count')::integer, 0);
  v_bytes := coalesce((p_payload ->> 'total_bytes')::integer, 0);

  v_category := lower(btrim(coalesce(p_payload ->> 'category', 'other')));
  if not (v_category = any (c_categories)) then
    v_category := 'other';
  end if;

  -- tags：只收字符串，去空、限长、限量
  select coalesce(array_agg(left(t, 32)), '{}')
    into v_tags
    from (
      select btrim(x) as t
        from jsonb_array_elements_text(
               case when jsonb_typeof(p_payload -> 'tags') = 'array'
                    then p_payload -> 'tags' else '[]'::jsonb end) as x
       where btrim(x) <> ''
       limit c_max_tags
    ) s;

  -- —— 校验 ——
  if v_name = '' then
    return jsonb_build_object('ok', false, 'code', 'invalid_payload', 'detail', 'name 为空');
  end if;
  if length(v_name) > c_max_name then
    return jsonb_build_object('ok', false, 'code', 'invalid_payload', 'detail', 'name 过长');
  end if;
  if length(v_desc) > c_max_desc then
    return jsonb_build_object('ok', false, 'code', 'invalid_payload', 'detail', 'description 过长');
  end if;
  if jsonb_typeof(v_files) <> 'array' then
    return jsonb_build_object('ok', false, 'code', 'invalid_payload', 'detail', 'files 不是数组');
  end if;
  if not exists (
    select 1 from jsonb_array_elements(v_files) f
     where lower(f ->> 'path') = 'skill.md'
  ) then
    return jsonb_build_object('ok', false, 'code', 'missing_skill_md');
  end if;
  if v_file_cnt < 1 or v_file_cnt > c_max_files then
    return jsonb_build_object('ok', false, 'code', 'too_many_files');
  end if;
  if v_bytes < 1 or v_bytes > c_max_total_bytes then
    return jsonb_build_object('ok', false, 'code', 'too_large');
  end if;
  if length(v_bundle) < 16 or length(v_bundle) > c_max_bundle_b64 then
    return jsonb_build_object('ok', false, 'code', 'too_large');
  end if;
  if v_hash = '' or v_hash !~ '^[0-9a-f]{64}$' then
    return jsonb_build_object('ok', false, 'code', 'invalid_payload', 'detail', 'hash 不是 sha256');
  end if;
  -- base64 形态检查：先卡格式，避免 decode() 抛错变成 500
  if v_bundle !~ '^[A-Za-z0-9+/=\r\n]+$' then
    return jsonb_build_object('ok', false, 'code', 'invalid_payload', 'detail', 'bundle 不是 base64');
  end if;
  -- 真·zip 检查：前 4 字节必须是 PK\x03\x04（否则就是在往库里塞垃圾）
  if encode(decode(substr(v_bundle, 1, 8), 'base64'), 'hex') not like '504b0304%' then
    return jsonb_build_object('ok', false, 'code', 'invalid_payload', 'detail', 'bundle 不是 zip');
  end if;

  -- 同内容去重
  select slug into v_existing from public.skills where hash = v_hash;
  if found then
    return jsonb_build_object('ok', true, 'code', 'exists', 'slug', v_existing);
  end if;

  -- slug 唯一化
  v_base := left(regexp_replace(lower(v_name), '[^a-z0-9\u4e00-\u9fa5]+', '-', 'g'), 64);
  v_base := btrim(v_base, '-');
  if v_base = '' then v_base := 'skill'; end if;
  v_slug := v_base;
  while exists (select 1 from public.skills where slug = v_slug) loop
    v_slug := left(v_base, 58) || '-' || v_n;
    v_n := v_n + 1;
  end loop;

  insert into public.skills (
    slug, name, description, category, tags, version, license, author,
    readme, files, file_count, total_bytes, hash, bundle_b64
  ) values (
    v_slug,
    v_name,
    v_desc,
    v_category,
    v_tags,
    left(btrim(coalesce(p_payload ->> 'version', '1.0.0')), 32),
    left(btrim(coalesce(p_payload ->> 'license', '')), 64),
    left(btrim(coalesce(nullif(p_payload ->> 'author', ''), 'anonymous')), 64),
    v_readme,
    v_files,
    v_file_cnt,
    v_bytes,
    v_hash,
    v_bundle
  );

  return jsonb_build_object('ok', true, 'code', 'created', 'slug', v_slug);
end $$;

grant execute on function public.publish_skill(jsonb) to anon, authenticated;


-- ---------------------------------------------------------------- 8. 自检

-- 期望：tables = 2，funcs = 5，rls_on = 2，policies = 0
select
  (select count(*) from information_schema.tables
    where table_schema = 'public' and table_name in ('skills', 'skill_upload_log'))            as tables,
  (select count(*) from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname in ('list_skills','get_skill','download_skill','register_install','publish_skill')) as funcs,
  (select count(*) from pg_tables
    where schemaname = 'public' and tablename in ('skills','skill_upload_log') and rowsecurity)  as rls_on,
  (select count(*) from pg_policies
    where schemaname = 'public' and tablename in ('skills','skill_upload_log'))                  as policies;
