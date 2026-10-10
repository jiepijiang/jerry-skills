-- ============================================================================
-- jerry-skills · 清空全部技能数据
-- ----------------------------------------------------------------------------
-- 用途：把站点恢复成「一条技能都没有」的初始状态（**包含你自己上传的**）。
--
-- 跑法：Supabase Dashboard → 项目 swdnendmdmcyqnnjzytv → SQL Editor
--       → 整段粘贴 → Run
--
-- ⚠️ 不可撤销。skills 表里没有备份，删掉就没了。
--    只想删某几条 → 看文件末尾的「只删一部分」示例。
--
-- 为什么不能由前端 / anon key 做：
--   迁移里对这两张表做了 `revoke all from anon, authenticated` + RLS 零策略，
--   而且**刻意没有提供 delete 类 RPC** —— 否则任何人都能一键清空整站。
--   所以只能拿有权限的账号（SQL Editor / service_role）来跑。
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 主操作：全清
-- ---------------------------------------------------------------------------
do $$
declare
  v_skills bigint;
  v_log    bigint;
begin
  select count(*) into v_skills from public.skills;
  select count(*) into v_log    from public.skill_upload_log;

  -- ① 技能本体。downloads / installs 的计数就存在这一行里，跟着一起没了
  delete from public.skills;

  -- ② 上传限流日志（20 次 / 小时 / IP 的那个计数）。
  --    不清的话，刚重置完你可能正好被自己刚才的测试顶到上限，传不上去。
  --    想保留限流状态 → 把下面这行注释掉。
  delete from public.skill_upload_log;

  raise notice '已删除：skills % 行，skill_upload_log % 行', v_skills, v_log;
end $$;

-- ---------------------------------------------------------------------------
-- 自检：期望 skills_remaining = 0
-- （SQL Editor 会把这条的返回值显示成表格）
-- ---------------------------------------------------------------------------
select
  (select count(*) from public.skills)           as skills_remaining,
  (select count(*) from public.skill_upload_log) as upload_log_remaining;


-- ============================================================================
-- 附：只删一部分（按需取用，别和上面的「全清」一起跑）
-- ============================================================================
--
-- 只删端到端测试留下的那几条：
--   delete from public.skills where slug like 'e2e-smoke-test%';
--
-- 只删某一条：
--   delete from public.skills where slug = 'ikotek-cli';
--
-- 只删自己传的（作者名是 anonymous 的）：
--   delete from public.skills where author = 'anonymous';
--
-- 删完顺手看一眼还剩什么：
--   select slug, name, category, author, downloads, installs, created_at
--     from public.skills order by created_at desc;
