# UI 分类技能包 · 入库 SQL

42 个 UI 技能，按 7 个维度各 6 个组织，直接 insert 进 `public.skills`。

## 为什么是 SQL，不是走上传接口

站上的上传走 `publish_skill()` RPC，而它有**每 IP 每小时 20 次**的限流
（见 `001-skills.sql` 的 `c_rate_limit`）。42 个包得跨三个小时传完，中间断一次就要重来。

`anon` key 本来也没有建表/写表的权限（表是 `revoke all` + RLS 零策略），
所以这条路只能由站主在 **Supabase SQL Editor** 里走。

## 怎么跑

按顺序在 SQL Editor 里各开一个查询、粘贴、Run：

| 顺序 | 文件 | 内容 |
| --- | --- | --- |
| 0 | （前置）`../migrations/001-skills.sql` | 建表。**必须已经跑过** |
| 1 | `01-pc.sql` | PC 桌面端 Web · 6 个 |
| 2 | `02-h5.sql` | H5 移动端 Web · 6 个 |
| 3 | `03-app.sql` | APP 移动应用 · 6 个 |
| 4 | `04-landing.sql` | 落地页 · 6 个 |
| 5 | `05-biz.sql` | 业务场景 · 6 个 |
| 6 | `06-admin.sql` | 后台管理系统 · 6 个 |
| 7 | `07-style.sql` | UI 风格 · 6 个 |
| 8 | `99-check.sql` | 自检（只读，不改数据） |

每个文件 200–320 KB。**可以分批跑**，跑一半中断了直接重跑剩下的 ——
末尾都是 `on conflict do nothing`，重复执行不会插重复，也不会覆盖已经攒下的
下载量 / 安装量 / 评分。

## 42 个技能从哪来

| 来源 | 个数 | 说明 |
| --- | --- | --- |
| 转载 | 15 | 从开源仓库转载，每个包内有 `ATTRIBUTION.md` 记录原始仓库、路径、许可证与版权 |
| 自建 | 27 | 本站编写，包内 `ATTRIBUTION.md` 写明「本站原创」 |

### 转载的 15 个

| 上游仓库 | 技能 |
| --- | --- |
| [anthropics/skills](https://github.com/anthropics/skills)（Apache-2.0） | `frontend-design`、`web-artifacts-builder`、`theme-factory` |
| [alirezarezvani/claude-skills](https://github.com/alirezarezvani/claude-skills)（MIT） | `a11y-audit`、`senior-frontend`、`apple-hig-expert`、`paywall-upgrade-cro`、`app-store-optimization`、`landing-page-generator`、`page-cro`、`landing`、`ux-researcher-designer`、`site-architecture`、`ui-design-system`、`design-system` |

转载时只做了三件事：**补中文 frontmatter**（`description` 改写成中文、加 `category` /
`tags`）、**加 `ATTRIBUTION.md` 与 `LICENSE`**、**删掉 `.gitignore` 之类对分发包没意义的文件**。
SKILL.md 的正文与所有附属文件均未改动。

### 自建的 27 个

覆盖 H5 整个维度（上游没有可转载的移动端 Web 技能），以及其余维度的补位。
内容依据公开规范整理：CSS 标准、WCAG 2.2、Material Design 3、Apple HIG 公开条款等，
不含任何厂商的私有设计资产。

## 维度分布

| 维度 | 转载 | 自建 | 技能 |
| --- | --- | --- | --- |
| PC 桌面端 | 4 | 2 | `frontend-design` `web-artifacts-builder` `a11y-audit` `senior-frontend` + `desktop-layout-system` `data-dense-ui` |
| H5 移动端 | 0 | 6 | `h5-viewport-adaptation` `mobile-web-gestures` `h5-performance` `wechat-h5-guide` `mobile-form-ux` `h5-touch-accessibility` |
| APP | 3 | 3 | `apple-hig-expert` `paywall-upgrade-cro` `app-store-optimization` + `material-design-3` `mobile-app-navigation` `mobile-onboarding` |
| 落地页 | 3 | 3 | `landing-page-generator` `page-cro` `landing` + `hero-section-design` `pricing-page-design` `social-proof-blocks` |
| 业务场景 | 2 | 4 | `ux-researcher-designer` `site-architecture` + `ecommerce-ui` `fintech-ui` `saas-app-ui` `healthcare-ui` |
| 后台管理 | 1 | 5 | `ui-design-system` + `admin-dashboard-layout` `crud-page-patterns` `data-table-design` `filter-and-search-ui` `admin-empty-error-states` |
| UI 风格 | 2 | 4 | `theme-factory` `design-system` + `glassmorphism-ui` `neumorphism-ui` `bento-grid-ui` `dark-mode-oled` |

⚠️ 维度只是**组织方式**，没有单独入库 —— 数据库里它们统一是 `category = 'ui'`。
要按维度筛，得用 slug 白名单（见下面「这套 SQL 验过什么」里那份验证脚本的 `DIM_SLUGS`，
它在 `~/.workbuddy-ai/binaries/node/workspace/verify-ui-sql.mjs`，**不在仓库里**）。

## 跑完怎么验

`99-check.sql` 会给出五组结果，期望：

| 查询 | 期望 |
| --- | --- |
| 1. `ui 技能总数` | **42** |
| 2. 逐维度明细 | **7 行**，每行 `技能数 = 6`，`判定` 列全是 **✅** |
| 3. `缺字段的行数` | **0** |
| 4. `标签数范围` | `判定` 列是 **✅**（真实值是 `6 ~ 7`，落在设计区间 5~7 内） |
| 5. 逐条清单 | **42 行** |

> 第 2 条是**逐维度**列出来的（不是一行汇总），哪个维度少了会直接标 `⚠️ 少了`。
> 数据库里没有「维度」这一列（统一是 `category = 'ui'`），所以它靠一份 **slug 白名单**分组 ——
> 那份白名单由 `gen-sql.mjs` 从技能数据**自动生成**，不是手抄的。

再打开站上首页，分类栏应该多出一个 **「UI」**（图标是浏览器窗口），点进去有 42 个技能。

## 这套 SQL 验过什么

用 PGlite（WASM Postgres）真跑了一遍，**44 项检查全过**，脚本在
`~/.workbuddy-ai/binaries/node/workspace/verify-ui-sql.mjs`（不进仓库，因为 PGlite 带
~10MB WASM）。覆盖：

- 7 个文件都能执行、42 条全部入库、7 个维度各 6 个
- 没有空字段、每行 5~7 个标签、hash 无重复、包体积都在 2MB 内
- **以 `anon` 身份**调 `list_skills(p_category='ui')` → `total = 42`；`get_skill` 能取到正文
- **重复跑一遍仍是 42 条**（幂等）
- 插入 UI 技能**不影响其它分类**的行数
- **`99-check.sql` 本身被真的执行一遍**，并逐条断言它的输出
  （总数 42 / 7 行各 6 / 缺字段 0 / 标签判定 ✅ / 清单 42 行）

三个造红（验证这套检查真的有判别力）：

| 造红 | 结果 |
| --- | --- |
| 把 `01-pc.sql` 里一条的 `category` 改成 `design` | 6 项变红，精确指出「缺 frontend-design / pc 只有 5 个 / 既有分类多了 1 个」 |
| 删掉 `02-h5.sql` 的 6 处 `on conflict do nothing` | 报 `duplicate key value violates unique constraint "skills_pkey"` |
| 把 `99-check.sql` 的第 2 条换回 `group by 1` | 3 项变红，含 `aggregate functions are not allowed in GROUP BY` |

> 🔴 **最后一节是补上的，因为它曾经缺位。**
> `99-check.sql` 从生成到现在**从没被执行过** —— 构建脚本只负责把它写出来，没人跑它。
> 于是里面一条 `group by 1`（把聚合函数当分组键，Postgres 报 `42803`）
> 一路活到了用户手上；同一份文件里的「期望 5~7」也和真实数据（`6~7`）对不上。
> **教训：「文件生成了」不等于「文件能跑」。生成物也要真跑一遍，
> 而且期望值必须来自真实输出，不能手写。**

## 怎么重建

技能包的**源**在 `authored/`（27 个自建技能）。构建脚本依赖 `/tmp/skillsrc` 里的两个
上游仓库副本，所以重建前要先：

```bash
mkdir -p /tmp/skillsrc && cd /tmp/skillsrc
git clone --depth 1 https://github.com/anthropics/skills.git anthropic
git clone --depth 1 https://github.com/alirezarezvani/claude-skills.git arv
```

然后 `pack.mjs` → `build-real.mjs` / `build-authored.mjs` → `gen-sql.mjs` 依次跑。

`gen-sql.mjs` **直接写进本目录**（`seed-ui/01-pc.sql` … `99-check.sql`），
中间产物只在 `out/`（`real.json` / `authored.json`，已 gitignore）。
**不要**改成「先写 `out/sql/` 再手工拷」—— 交付物和生成物必须是同一份，
否则任何一次「忘了拷」都会让用户拿到旧文件。

⚠️ `pack.mjs` 的打包算法（条目按码位排序、mtime 固定 1980-01-01、level 6）**必须和
`src/lib/parseSkill.js` 的 `packZip` 逐字节一致** —— 否则算出的 hash 和站上对不上，
将来有人在页面上重新上传同一个包，站上会认不出「已存在」，插出 `xxx-2`。
