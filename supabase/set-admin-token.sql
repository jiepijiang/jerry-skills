-- ============================================================================
-- 设置 / 更换站主管理口令
-- ----------------------------------------------------------------------------
-- 跑法：Supabase Dashboard → SQL Editor → 把下面整段粘进去 → **改掉 v_pass** → Run。
--
-- ⚠️ 口令的明文**不会**被存下来，也不会进这个文件、不进 git。
--    存进库里的只有：盐（随机 32 位十六进制）+ sha256(盐 || 口令)。
--    也就是说**口令忘了就只能重设**，没有「找回」。
--    建议存进密码管理器 —— 这个口令能删掉整个站点的数据。
--
-- 跑完这个脚本会同时：
--   · 覆盖旧口令（改口令就是重跑一遍，不用先删）
--   · **清空失败尝试记录** —— 万一被自己或别人试到限流锁死，重设口令即解锁
-- ============================================================================

do $$
declare
  -- ▼▼▼ 改这一行 ▼▼▼
  v_pass constant text := '把这里换成你自己的口令';
  -- ▲▲▲ 建议 16 位以上，别用你别的站点的密码 ▲▲▲

  v_salt text;
begin
  if v_pass = '把这里换成你自己的口令' then
    raise exception '请先把 v_pass 改成你自己的口令 —— 现在还是示例值。';
  end if;

  if length(v_pass) < 12 then
    raise exception '口令太短（现在 % 位，至少 12 位）。这个口令能删掉整个站点的数据。', length(v_pass);
  end if;

  v_salt := replace(gen_random_uuid()::text, '-', '');   -- 32 位十六进制随机盐

  insert into public.skill_admin_config (id, salt, token_hash, updated_at)
  -- 必须与 002 里 _skill_admin_ok 的算法**逐字一致**：sha256(UTF-8 字节(盐 || 口令))
  values (1, v_salt, encode(sha256(convert_to(v_salt || v_pass, 'UTF8')), 'hex'), now())
  on conflict (id) do update
    set salt       = excluded.salt,
        token_hash = excluded.token_hash,
        updated_at = now();

  -- 重设口令即解锁：把失败计数清掉，否则刚设完口令却还被限流挡着，很难解释
  delete from public.skill_admin_log;

  raise notice '✅ 管理口令已设置。口令明文没有被存下来。';
end $$;

-- 期望：token_set = 1
select
  (select count(*) from public.skill_admin_config)                     as token_set,
  (select count(*) from public.skill_admin_log)                        as fail_log,
  (select to_char(updated_at, 'YYYY-MM-DD HH24:MI:SS')
     from public.skill_admin_config where id = 1)                      as updated_at;
