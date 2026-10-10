-- ============================================================================
-- 设置 / 更换站主管理口令
-- ----------------------------------------------------------------------------
-- 跑法：Supabase Dashboard → SQL Editor → 把下面整段粘进去 → **改掉 v_pass** → Run。
--      改法随便：手改那一行，或者全局替换整段里的占位符，都行（见下面 DO 块里的注释）。
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
  -- 先确认 002 已经跑过。
  -- 不做这个前置检查的话，下面那条 insert 会直接抛
  --   `42P01: relation "public.skill_admin_config" does not exist`
  -- —— 技术上没错，但对「我照着文档一步步来的，怎么就错了」的人毫无帮助：
  -- 它说的是「表不存在」，而人需要知道的是「我少跑了哪一步」。
  -- to_regclass 查不存在的对象返回 null 而不是报错，正好用来做前置判断。
  if to_regclass('public.skill_admin_config') is null then
    raise exception
      '找不到 public.skill_admin_config —— 说明 migrations/002-admin-delete.sql 还没跑。'
      '请先把那份整段粘进 SQL Editor 跑一遍（期望 token_set = 0），再回来跑这个。';
  end if;

  -- ⚠️ 下面那个比较里，占位符那串中文被**拆成两段拼起来** —— 这不是笔误，是故意的。
  --    如果写成一整串，这一行自己就含有占位符；而改口令的常见做法是
  --    「全局替换」（sed、编辑器的全选替换），那会把这一行也一起换掉，
  --    于是变成「拿你的口令和你的口令比」→ 恒真 → 永远报「还没改占位符」，
  --    而且报得让人完全摸不着头脑。拆开之后全局替换就碰不到它了。
  if v_pass = '把这里换成' || '你自己的口令' then
    raise exception '请先把 v_pass 改成你自己的口令 —— 现在还是示例值。';
  end if;

  -- 「忘了改」和「太短」分开报，因为该做的动作不一样（一个是去改那一行，一个是换个更长的）。
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
