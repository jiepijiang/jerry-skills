# Supabase 接线说明

本站的后端是 Supabase 的一个 Postgres 项目（与主站 `jerry-site`、`jerry-tools` **共用**）：

```
ref: swdnendmdmcyqnnjzytv
url: https://swdnendmdmcyqnnjzytv.supabase.co
```

## 需要你手动做的事（只有一次）

前端那个 anon key **建不了表、建不了函数**，所以下面的步骤必须在
Supabase Dashboard 的 **SQL Editor** 里跑：

1. 打开 https://supabase.com/dashboard/project/swdnendmdmcyqnnjzytv/sql/new
2. **先跑预检**：把 `preflight-check.sql` 粘进去点 Run。
   期望**恰好一行**输出：`✅ 无冲突，可以安全执行 001-skills.sql`
   （故意做成恒定一行 —— 如果写成「有冲突才出行」，那「0 行」和「查询没跑成」就分不清了）
3. 再把 `migrations/001-skills.sql` **整份**粘进去点 Run
4. 看输出：期望自检查询返回
   `tables = 2, funcs = 5, rls_on = 2, policies = 0`
   （`policies = 0` 是**故意的** —— 表对所有角色关闭，只走 RPC）

> ⚠️ 这份 SQL 是幂等的，重复跑不会出错，也不会清数据。

## 会不会影响主站 / jerry-tools 的表？

**不会。** 已经静态 + 动态两边都验过：

- **静态**：三个仓库所有 SQL 里建的表名 / 函数名取交集 → **空**。
  jerry-tools 11 张表（`bookmarks` `categories` `discover_sites` `favorites`
  `feedback` `notes` `profiles` `share_settings` `submissions` `user_settings` `visits`）、
  jerry-site 2 张表（`app_config` `guestbook_messages`），
  与本迁移的 `skills` `skill_upload_log` 无重叠；`_client_ip` 也没被别处用过。
  迁移里除了自己的对象，只出现 `alter table` / `revoke` / `grant` / `comment`，
  作用域全部限定在 `public.skills` 与 `public.skill_upload_log`。
- **动态**：`verify-migration.mjs` 在一个共用项目的替身里真跑了整份迁移，
  并对比迁移前后的 **函数定义 / 列定义 / 索引定义快照**，逐字节一致。
  详见下面「离线验证」。

真正需要留意的**不是**同名表（那会直接报错、事务回滚），而是**同名函数** ——
`create or replace function` 会**静默覆盖**，不报错。这也是预检单独把函数列出来的原因。

## 离线验证（不用连线上库）

`verify-migration.mjs` 用 PGlite（WASM 版 Postgres）把整份迁移真跑一遍，
造一个「共用项目」替身（含两个站的真实表名 / 函数名 / 哨兵数据），然后：

| 验什么 | 怎么验 |
| --- | --- |
| 预检有判别力 | 迁移**前**跑一次期望 0 冲突，迁移**后**再跑必须报冲突（造红） |
| 迁移本身能跑通 | 自检 `2/5/2/0`，且**重复执行**仍成功 |
| 不碰别人的东西 | 函数 / 列 / 索引**快照前后逐字节对比**，哨兵数据内容不变 |
| 权限锁真的锁上 | anon 直读表 → `permission denied`；**就算把 select 还回去，RLS 仍过滤成 0 行** |
| 绕过 RPC 写表 | anon 直接 `insert` → 被 RLS 挡下 |
| 5 个 RPC 全通 | **以 anon 身份**调，含校验失败 / hash 去重 / slug 后缀 / 限流 20 |

跑法见脚本头部注释（PGlite 不进项目依赖，手动装在隔离工作区）。

> 🔴 两个容易自我欺骗的点，脚本里都特意处理了：
> 1. **必须模拟 Supabase 的 default privileges**。线上 `public` schema 配了
>    `alter default privileges ... grant all on tables to anon`，新表一建出来 anon
>    本来**是**有 SELECT 的。不模拟的话，删掉 `revoke` 也照样报 `permission denied`，
>    测试会**假绿**。
> 2. **RPC 必须以 anon 身份调**。以超级用户调的话，函数漏了 `security definer`
>    或漏了 `grant execute` 都发现不了。

## 配到前端

`.env.local`（本地）或仓库 Variables（CI）：

```
VITE_SUPABASE_URL=https://swdnendmdmcyqnnjzytv.supabase.co
VITE_SUPABASE_ANON_KEY=<anon key>
```

CI 里是 **Variables** 而不是 Secrets —— anon key 本来就要发给浏览器，
放 Variables 更好排查（真正的秘密是 service_role，那个绝不能进前端）。
详见 `../.github/workflows/deploy.yml`。

## 验证后端是否就绪

```bash
npm run check:env
```

它会打一次真实的 RPC，确认函数已部署、参数名对得上。

## 访问模型

| 对象 | anon 能做什么 |
| --- | --- |
| `public.skills` 表 | **什么都不能** —— 直读报 `permission denied`（42501），且**即使把 select 权限还回去，RLS 零策略仍过滤成 0 行**（两道锁） |
| `public.skill_upload_log` 表 | **什么都不能**（同上） |
| `_client_ip()` | 不可执行（内部函数，`revoke ... from public, anon, authenticated`） |
| `list_skills` / `get_skill` | 可执行 |
| `download_skill` | 可执行（顺带 +1 下载量） |
| `register_install` | 可执行（顺带 +1 安装量） |
| `publish_skill` | 可执行（带体积/格式/频率校验） |

上表每一行都在 `verify-migration.mjs` 里以 **anon 身份**实测过，不是照文档抄的。

**为什么不给表开 select policy**：`bundle_b64`（技能包本体）和 `readme` 都很占带宽，
如果表可读，任何人都能写个循环把整库拖走。走 RPC 之后，「拿包体」这个动作
和「+1 下载量」绑在同一个事务里，计数天然不会漏，也没法绕过。

## 常见故障

| 现象 | 原因 |
| --- | --- |
| 页面一直显示「本地演示模式」横幅 | `.env.local` 没配，或 CI 里 Variables 没加 |
| `http_404` | 函数没部署（SQL 没跑），或 RPC 参数名写错了 |
| `http_400` | 参数类型不对（多半是 `p_limit` 传了字符串） |
| `rate_limited` | 同 IP 一小时内超过 20 次上传 |
| `too_large` | 技能包超过 2 MB（解压后） |
