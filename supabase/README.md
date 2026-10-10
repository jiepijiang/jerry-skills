# Supabase 接线说明

本站的后端是 Supabase 的一个 Postgres 项目（与主站 `jerry-site`、`jerry-tools` **共用**）：

```
ref: swdnendmdmcyqnnjzytv
url: https://swdnendmdmcyqnnjzytv.supabase.co
```

## 需要你手动做的事（只有一次）

前端那个 anon key **建不了表、建不了函数**，所以下面两步必须在
Supabase Dashboard 的 **SQL Editor** 里跑：

1. 打开 https://supabase.com/dashboard/project/swdnendmdmcyqnnjzytv/sql/new
2. 把 `migrations/001-skills.sql` **整份**粘进去，点 Run
3. 看输出：期望最后那条自检查询返回
   `tables = 2, funcs = 5, rls_on = 2, policies = 0`
   （`policies = 0` 是**故意的** —— 表对所有角色关闭，只走 RPC）

> ⚠️ 这份 SQL 是幂等的，重复跑不会出错，也不会清数据。

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
| `public.skills` 表 | **什么都不能**（RLS 开、无 policy，且 revoke 了权限） |
| `public.skill_upload_log` 表 | **什么都不能** |
| `list_skills` / `get_skill` | 可执行 |
| `download_skill` | 可执行（顺带 +1 下载量） |
| `register_install` | 可执行（顺带 +1 安装量） |
| `publish_skill` | 可执行（带体积/格式/频率校验） |

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
