-- ============================================================================
-- 002 — 站主专属的「删除技能」
-- ----------------------------------------------------------------------------
-- 需求：站点上要有删除按钮，但**只有站主**能删。
--
-- 这个站是纯静态托管（GitHub Pages）+ 匿名开放上传，**没有任何账号体系**。
-- 所以「站主」只能靠一个**管理口令**来认：口令由站主自己设，服务端只存
-- 「盐 + sha256(盐 || 口令)」，**不存明文**。前端拿口令来换一次删除权。
--
-- ⚠️ 为什么用内置的 sha256 而不是 pgcrypto 的 crypt/gen_salt：
--    · 实测 PGlite（PG 18.3）里 pgcrypto **不存在**（crypt / gen_salt / digest 全无）。
--      用 pgcrypto 意味着这份 SQL **没法离线验证**，只能拿到线上盲跑 ——
--      而这份文件里有一半是安全逻辑，盲跑是不可接受的。
--    · sha256(bytea) 与 gen_random_uuid() 都是 PG 11 / 13 起的内置函数，
--      Supabase（PG 15+）必然有，离线也必然能验。
--    · 加盐的意义是防「预计算表」，而**低熵口令才需要慢哈希来防暴力枚举**。
--      这里的暴力枚举路径只有一个：在线打 RPC，已被下面的双重重限流卡死
--      （口令本身也强制 ≥ 12 位）。哈希只存于一张 anon 完全读不到的表里。
--
-- 删除语义：**硬删**（表里真的少一行），但删之前把整行原样备份进 skills_trash。
--   为什么不软删（status='deleted'）：publish_skill 的「同 hash 去重」查的是
--   `where hash = v_hash`（**不带 status 条件**），软删之后同一份 zip 再上传会
--   命中那条看不见的行、返回 exists 却什么都不显示；而改成带 status 条件，
--   又会撞上 skills_hash_uniq 唯一索引 → 500。也就是说软删**必须**改 publish_skill
--   的语义，那是全站最核心、最容易改坏的一段。硬删 + 回收站把这份风险降为零，
--   同时「删了就是删了」也和用户对这个词的预期一致。
--
-- 幂等：整份文件可重复执行。
-- 执行位置：Supabase SQL Editor（anon key 建不了函数）。
-- 设口令：另跑 supabase/set-admin-token.sql（**不要把口令写进这个文件**）。
-- ============================================================================

-- ---------------------------------------------------------------- 1. 表

-- 管理口令。**只会有 0 行或 1 行**（id 恒为 1）。
create table if not exists public.skill_admin_config (
  id         smallint    primary key default 1,
  salt       text        not null,
  token_hash text        not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint skill_admin_config_singleton check (id = 1)
);

comment on table public.skill_admin_config is
  '站主管理口令的加盐哈希；只通过 RPC 间接使用，表本身对 anon 关闭。口令明文不存在于此';

-- 管理操作日志：既是审计，也是限流的计数依据。
create table if not exists public.skill_admin_log (
  id         bigserial   primary key,
  ip         text        not null,
  action     text        not null default 'delete',
  success    boolean     not null default false,
  created_at timestamptz not null default now()
);

create index if not exists skill_admin_log_ip_idx     on public.skill_admin_log (ip, created_at desc);
-- 全局失败计数要用到，单独给一个（不带 ip 前缀的）时间索引
create index if not exists skill_admin_log_time_idx   on public.skill_admin_log (created_at desc);
create index if not exists skill_admin_log_failed_idx on public.skill_admin_log (success, created_at desc);

-- 回收站：硬删之前把整行原样存下来。
-- ⚠️ 主键必须是**自增 id 而不是 slug**：删掉 x → 重新上传 x → 再删一次，
--    会有两行 slug 都叫 x。拿 slug 当主键当场冲突。
create table if not exists public.skills_trash (
  id         bigserial   primary key,
  slug       text        not null,
  name       text        not null default '',
  payload    jsonb       not null,
  deleted_ip text        not null default 'unknown',
  deleted_at timestamptz not null default now()
);

create index if not exists skills_trash_slug_idx on public.skills_trash (slug, deleted_at desc);

comment on table public.skills_trash is
  '删除技能的回收站（整行 jsonb 快照）。恢复见 supabase/README.md；anon 完全读不到';

-- RLS 打开但**不建任何 policy** → 除 service_role 外谁也读不到、写不了
alter table public.skill_admin_config enable row level security;
alter table public.skill_admin_log    enable row level security;
alter table public.skills_trash       enable row level security;

revoke all on public.skill_admin_config from anon, authenticated;
revoke all on public.skill_admin_log    from anon, authenticated;
revoke all on public.skills_trash       from anon, authenticated;
-- 回收站里装着 bundle_b64，连序列也不给
revoke all on sequence public.skills_trash_id_seq       from anon, authenticated;
revoke all on sequence public.skill_admin_log_id_seq    from anon, authenticated;


-- ------------------------------------------------- 2. 口令校验（内部）

-- 口令是否正确。
-- 失败一律返回 false（失败关闭）：没设口令、口令为空、表里没行，都是拒绝。
create or replace function public._skill_admin_ok(p_token text)
returns boolean
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  r public.skill_admin_config;
begin
  if p_token is null or length(p_token) = 0 then
    return false;
  end if;

  select * into r from public.skill_admin_config where id = 1;
  if not found then
    -- 还没设口令 → 谁都别想删（而不是「没设就等于不设防」）
    return false;
  end if;

  -- 用 convert_to(…, 'UTF8') 而不是 `::bytea`：后者是「按库的编码取字节」，
  -- 语义依赖 server_encoding，而且中文口令下各版本表现不一致。
  -- 显式转 UTF-8 字节，和前端 / 任何语言算出来的都一致。
  return encode(sha256(convert_to(r.salt || p_token, 'UTF8')), 'hex') = r.token_hash;
end $$;

revoke all on function public._skill_admin_ok(text) from public, anon, authenticated;


-- ------------------------------------------------- 3. 限流（内部）

-- 还能不能再试。只数**失败**次数 —— 站主连删 20 个技能不该被自己的限流挡住。
--
-- 两道闸门，缺一不可：
--   · 按 IP：防止单一来源死磕。
--   · **全局**：`_client_ip()` 取的是 x-forwarded-for 的第一段，而客户端可以
--     自己塞这个头。也就是说按 IP 的限流**是可以被绕过的**（伪造 N 个 IP
--     就是 N 份额度）。全局上限不依赖任何客户端可控输入，是真正兜底的那道。
create or replace function public._skill_admin_gate()
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  c_max_fails_ip     constant integer := 10;   -- 每 IP 每小时
  c_max_fails_global constant integer := 30;   -- 全站每小时
  v_ip    text := public._client_ip();
  v_fails integer;
begin
  -- 顺手清掉一天前的记录，别让这张表无限长
  delete from public.skill_admin_log where created_at < now() - interval '1 day';

  select count(*) into v_fails
    from public.skill_admin_log
   where not success and created_at > now() - interval '1 hour';

  if v_fails >= c_max_fails_global then
    return false;
  end if;

  select count(*) into v_fails
    from public.skill_admin_log
   where not success and ip = v_ip and created_at > now() - interval '1 hour';

  return v_fails < c_max_fails_ip;
end $$;

revoke all on function public._skill_admin_gate() from public, anon, authenticated;


-- 记一次尝试。**每次尝试都要记**，成功的也记 —— 成功记录不计入限流，
-- 但它让「谁在什么时候删了什么」有据可查。
create or replace function public._skill_admin_log(p_action text, p_success boolean)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.skill_admin_log (ip, action, success)
  values (public._client_ip(), left(coalesce(p_action, '?'), 32), coalesce(p_success, false));
end $$;

revoke all on function public._skill_admin_log(text, boolean) from public, anon, authenticated;


-- ------------------------------------------------- 4. 校验口令（对外）

-- 解锁用：只回答「这个口令对不对」，不改任何数据。
-- 单独存在是为了让界面能在**输入的那一刻**就给出反馈，
-- 而不是等站主点完「确认删除」才发现口令是错的。
create or replace function public.skill_admin_check(p_token text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_ok boolean;
begin
  if not public._skill_admin_gate() then
    return jsonb_build_object('ok', false, 'code', 'rate_limited');
  end if;

  v_ok := public._skill_admin_ok(p_token);
  perform public._skill_admin_log('check', v_ok);

  if not v_ok then
    return jsonb_build_object('ok', false, 'code', 'unauthorized');
  end if;

  return jsonb_build_object('ok', true, 'valid', true);
end $$;

grant execute on function public.skill_admin_check(text) to anon, authenticated;


-- ------------------------------------------------- 5. 删除（对外）

create or replace function public.skill_admin_delete(p_slug text, p_token text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_slug text := btrim(coalesce(p_slug, ''));
  v_row  public.skills;
  v_ip   text;
begin
  if v_slug = '' then
    return jsonb_build_object('ok', false, 'code', 'invalid_payload', 'detail', 'slug 为空');
  end if;

  -- 限流先于校验：否则「反复试口令」不计数，限流形同虚设（001 的教训）
  if not public._skill_admin_gate() then
    return jsonb_build_object('ok', false, 'code', 'rate_limited');
  end if;

  if not public._skill_admin_ok(p_token) then
    perform public._skill_admin_log('delete', false);
    return jsonb_build_object('ok', false, 'code', 'unauthorized');
  end if;

  select * into v_row from public.skills where slug = v_slug;
  if not found then
    perform public._skill_admin_log('delete', true);
    return jsonb_build_object('ok', false, 'code', 'not_found');
  end if;

  -- 回收站也顺手做个上限，免得常年累积把库撑大（90 天足够「手滑救回来」）
  delete from public.skills_trash where deleted_at < now() - interval '90 days';

  v_ip := public._client_ip();

  -- 先备份再删。两句在同一个事务里，备份失败就不会删成「有去无回」。
  insert into public.skills_trash (slug, name, payload, deleted_ip)
  values (v_row.slug, v_row.name, to_jsonb(v_row), v_ip);

  delete from public.skills where slug = v_row.slug;

  perform public._skill_admin_log('delete', true);

  return jsonb_build_object('ok', true, 'slug', v_row.slug, 'name', v_row.name);
end $$;

grant execute on function public.skill_admin_delete(text, text) to anon, authenticated;


-- ---------------------------------------------------------------- 6. 自检

-- 期望：admin_tables = 3，admin_funcs = 2，rls_on = 3，token_set = 0（还没设口令）
select
  (select count(*) from information_schema.tables
    where table_schema = 'public'
      and table_name in ('skill_admin_config','skill_admin_log','skills_trash'))          as admin_tables,
  (select count(*) from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname in ('skill_admin_check','skill_admin_delete'))                        as admin_funcs,
  (select count(*) from pg_tables
    where schemaname = 'public'
      and tablename in ('skill_admin_config','skill_admin_log','skills_trash')
      and rowsecurity)                                                                    as rls_on,
  (select count(*) from public.skill_admin_config)                                        as token_set,
  (select count(*) from public.skills)                                                    as skills;
