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
5. 再把 `migrations/002-admin-delete.sql` **整份**粘进去点 Run
   （站主删除功能。期望自检：`admin_tables = 3, admin_funcs = 2, rls_on = 3, token_set = 0`）
6. **最后**跑 `set-admin-token.sql` —— 见下面「设置管理口令」

> ⚠️ 这几份 SQL 都是幂等的，重复跑不会出错，也不会清数据。

## 站主删除功能（002）

站点上有一个删除按钮，但**只有站主能用**。这个站是纯静态托管 + 匿名开放上传，
**没有任何账号体系**，所以「站主」只能靠一个**管理口令**认人。

### 设置管理口令

把 `set-admin-token.sql` 整段粘进 SQL Editor，**改掉 `v_pass` 那一行**，Run。

```sql
v_pass constant text := '把这里换成你自己的口令';   -- ← 改这一行
```

- 口令**明文不会入库、不会进 git**。库里只有：随机 32 位盐 + `sha256(盐 || 口令)`。
- 脚本会拒绝「没改占位符」和「短于 12 位」的口令 —— 别用你别的站点的密码。
- 改口令 = 把这段重跑一遍，不用先删。**重跑会同时清空失败计数**，
  所以万一被限流锁死了，重设口令即可解锁。
- ⚠️ 口令忘了只能重设，没有「找回」—— 存进密码管理器。

生成一个强口令（别用你别的站点的密码）：

```bash
node -e "console.log(require('crypto').randomBytes(18).toString('base64url'))"
```

#### 改法随便，全局替换也行

手改那一行、或者**用全局替换把整段里的占位符一次换掉**（`sed` / 编辑器全选替换），
两种都行 —— 后者更省事，也不会踩坑。

> 这里曾经有个坑：守卫原本写成 `if v_pass = '把这里换成你自己的口令'`，
> 而**这一行自己也含有占位符**。用全局替换改口令时它被一起替换掉，
> 变成「拿你的口令和你的口令比」→ 恒真 → 永远报「还没改占位符」，
> 而且完全看不出为什么。现在守卫里的占位符是**拆成两段拼起来**比较的，
> 全局替换碰不到它。`verify-admin-delete.mjs` 里有一条专门钉这个行为。

### 界面上怎么用

页脚最右边有个小字「管理」→ 输入口令 → 解锁后**列表卡片和详情页上都会出现删除按钮**。

口令只放在 `sessionStorage`：**刷新还在，关掉标签页就没了**。
（不用 localStorage 是因为它能删掉整站数据，不该长期留在磁盘上。）

### 删除是硬删，但留了回收站

| 动作 | 实际发生什么 |
| --- | --- |
| 删除 | 先把**整行**（含 zip 的 base64、hash、下载/安装量）存进 `skills_trash`，再 `delete` |
| 恢复 | 见下面「从回收站恢复」 |
| 自动清理 | `skills_trash` 保留 90 天，之后在下次删除时顺带清掉 |

**为什么是硬删而不是软删（`status='deleted'`）**：`publish_skill` 的「同 hash 去重」查的是
`where hash = v_hash`（**不带 status 条件**）。软删之后同一份 zip 再上传，会命中那条
看不见的行 → 返回 `exists` 却什么都不显示；而给这个查询加上 status 条件，又会撞上
`skills_hash_uniq` 唯一索引 → 500。也就是说软删**必须**改 `publish_skill` 的语义 ——
那是全站最核心、最容易改坏的一段。硬删 + 回收站把这份风险降成零，
而且「删了就是删了」也和用户对这个词的预期一致。硬删之后重传同一份 zip 完全正常
（`verify-admin-delete.mjs` 里专门有一条断言钉住这件事）。

### 从回收站恢复

没有界面入口，只能在 SQL Editor 里跑。先找到它：

```sql
select id, slug, name, deleted_at, deleted_ip
  from public.skills_trash
 order by id desc limit 20;
```

再把快照原样插回去（`payload` 就是当时那一整行）：

```sql
insert into public.skills
select (jsonb_populate_record(null::public.skills, payload)).*
  from public.skills_trash
 where id = <上面查到的 id>;
```

> ⚠️ 如果那个 slug 已经被重新上传占用了，这条会主键冲突。先删掉新的那条，或者给
> 恢复出来的行换个 slug。

### 口令这一层的安全边界（写清楚，别高估它）

| 做法 | 挡住了什么 |
| --- | --- |
| 服务端只存加盐哈希 | 库被拖走也拿不到口令明文 |
| 口令强制 ≥ 12 位 | 在线暴力枚举不可行 |
| **每 IP 每小时 10 次失败** | 单一来源死磕 |
| **全站每小时 30 次失败** | ⚠️ 见下 —— 这道才是真正兜底的 |
| 成功不计入失败数 | 站主连删 20 个不会被自己锁死 |

> 🔴 **按 IP 的限流是可以被绕过的**：`_client_ip()` 取的是 `x-forwarded-for` 的**第一段**，
> 而客户端可以自己塞这个头（伪造 N 个 IP 就是 N 份额度）。这一点已经用 PGlite 实测确认，
> 所以才额外加了**不依赖任何客户端输入**的全局上限。
> 同一个问题也存在于 `publish_skill` 的上传限流（那是历史遗留，还没改）。

**没挡住什么**：知道口令的人可以为所欲为 —— 没有审计、没有二次验证、没有撤销。
一个人用的站，这是刻意的取舍。

## 清空全部技能数据（需要时）

`reset-skills.sql`。同样是 SQL Editor 里整段粘贴 → Run。

删两样东西：

| 表 | 删什么 | 为什么 |
| --- | --- | --- |
| `public.skills` | **全部行** | 技能本体，下载量 / 安装量计数也在这行里 |
| `public.skill_upload_log` | **全部行** | 上传限流计数（20 次/小时/IP）。不清的话，刚重置完可能正好被自己的测试顶到上限 |

想保留限流状态 → 把 `delete from public.skill_upload_log;` 那行注释掉。
只想删一部分 → 文件末尾有 `where slug like 'e2e-smoke-test%'` 之类的示例。

> 有了 002 之后，**日常清理直接点界面上的删除按钮**就行（会留回收站，更安全）。
> 这个脚本只用于「连回收站一起清干净」或者「口令丢了但必须清库」。
> 想连回收站也清掉：`delete from public.skills_trash;`

离线验证：`verify-reset-sql.mjs`（PGlite 真跑，9/9）。除了验「清空生效」，
还验了「清完表还能用」「表结构 / 函数没被破坏」，并做了两个造红：
只清 skills 不清日志（→ 日志那条断言红）、表名写错（→ 直接抛错，不是静默通过）。

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

### 001 / 002 两份迁移

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

### 002 的管理删除：`verify-admin-delete.mjs`（65 项）

这份 SQL 里一半是安全逻辑，所以单独写了一份更狠的：

| 验什么 | 怎么验 |
| --- | --- |
| 口令校验失败关闭 | **没设口令时任何人都进不去**（不是「没设就等于不设防」） |
| 口令真的对得上 | 正确 → 通过；多一个字符 / 大小写不同 / 空 / null → 全拒 |
| 盐不是摆设 | 换一个盐之后同一口令**必须**失效 |
| **口令错时数据必须还在** | 这是整个功能的底线，单独一条断言 |
| 删除是硬删 + 有回收站 | 表里少一行，回收站里多一份**含 zip 包体、hash、下载量**的完整快照 |
| 删完各接口都看不到 | `list_skills` / `get_skill` / `download_skill` / `register_install` 全部 `not_found` |
| **删完能重传同一份 zip** | 硬删 vs 软删的判别点（软删会在这里翻车，见上面那节） |
| 同一 slug 删两次 | 回收站里两行 → 所以主键必须是自增 id |
| 限流只数失败 | 连续成功 12 次（超过阈值）之后，第一次失败仍只是 `unauthorized` |
| 每 IP 上限 10/小时 | 第 11 次才拦 |
| **全局上限 30/小时** | 每次换一个 IP 死磕，仍然在第 31 次被拦下 |
| 旧记录会清理 | 两天前的失败不占额度，且被顺手删掉 |

跑法见脚本头部注释（PGlite 不进项目依赖，手动装在隔离工作区）。

> 🔴 两个容易自我欺骗的点，脚本里都特意处理了：
> 1. **必须模拟 Supabase 的 default privileges**。线上 `public` schema 配了
>    `alter default privileges ... grant all on tables to anon`，新表一建出来 anon
>    本来**是**有 SELECT 的。不模拟的话，删掉 `revoke` 也照样报 `permission denied`，
>    测试会**假绿**。
> 2. **RPC 必须以 anon 身份调**，而且要用**具名参数**（`p_slug => …`）。
>    以超级用户调的话，漏了 `security definer` / `grant execute` 都发现不了；
>    而 PostgREST 是按**名字**匹配参数的，只有具名调用才验得到「名字对不对」。

两份脚本都做过 8 个造红注入（去掉口令校验 / 校验恒真 / 去掉全局上限 / 不写回收站 /
不 revoke / 哈希丢掉盐 / 不 revoke 内部函数 / 限流把成功也计入），
每一个都如期让**指定的那条**断言变红，还原后回到全绿。

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
| `public.skill_admin_config` 表 | **什么都不能** —— 口令哈希在这里，读不到 |
| `public.skill_admin_log` 表 | **什么都不能** —— 管理操作审计 + 限流计数 |
| `public.skills_trash` 表 | **什么都不能** —— 装着已删技能的完整快照（含 zip 包体） |
| `_client_ip()` | 不可执行（内部函数，`revoke ... from public, anon, authenticated`） |
| `_skill_admin_ok` / `_skill_admin_gate` / `_skill_admin_log` | 不可执行（同上 —— 否则 anon 能把 `_skill_admin_ok` 当**口令预言机**逐个试） |
| `list_skills` / `get_skill` | 可执行 |
| `download_skill` | 可执行（顺带 +1 下载量） |
| `register_install` | 可执行（顺带 +1 安装量） |
| `publish_skill` | 可执行（带体积/格式/频率校验） |
| `skill_admin_check` / `skill_admin_delete` | 可执行，但**要口令**；失败按 IP + 全站双重重限流 |

上表每一行都在离线脚本里以 **anon 身份**实测过，不是照文档抄的。

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
