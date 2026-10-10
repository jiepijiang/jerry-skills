# jerry-skills · AI Agent Skill 分享站

上传 / 解析 / 下载量统计 / 一键安装的 AI Agent 技能目录站。

线上：https://jiepijiang.github.io/jerry-skills/
姊妹站：[主站](https://jiepijiang.github.io/jerry-site/) ·
[导航](https://jiepijiang.github.io/jerry-tools/) ·
[知识库](https://jiepijiang.github.io/jerry-notes/)

---

## 这是什么

一个可以**上传技能包、自动解析、一条命令装进 AI 助手**的站点。

| 能力 | 怎么实现的 |
| --- | --- |
| 上传 | 拖 `.zip`（技能文件夹压缩包）或 `SKILL.md`，也可以直接粘贴 Markdown |
| 解析 | **在浏览器里就地解析**：frontmatter → 元信息，zip → 文件树与体积校验 |
| 下载量 | 每次「下载 .zip」调一次 `download_skill` RPC，计数与取包在同一个事务里 |
| 一键复制安装 | 按系统生成命令：macOS/Linux 是 `curl … \| bash`，Windows 是 PowerShell，复制即用 |
| AI Agent 安装 | 生成一段自然语言提示词，粘给任意 agent 让它自己装（提示词里带的是当前所选系统的那条命令） |

### 关于「参考站」

交互与信息架构参考了 [skillhub.club](https://www.skillhub.club/) 的技能详情页
（元信息 + 安装命令 + 文件结构 + 说明）。**只借逻辑，不抄任何文案、图片与广告位**：

- 参考站详情页里那些推荐位 / 赞助位 / 评分引导，这里**一个都没有**；
- 取而代之的是一块「安装前请看一眼」的安全提示 —— 技能包里的脚本是要在用户机器上跑的，
  这件事比任何广告都值得占那块位置；
- UI 完全走主站（jerry-site）的设计变量，配色、毛玻璃、圆角、字体一致。

---

## 快速开始

```bash
npm install
npm run dev          # http://127.0.0.1:5176
```

**不配后端也能跑** —— 会进入「本地演示模式」：种子里有 5 个技能可以浏览、
上传会存进 localStorage、下载和计数都能走通。页面顶部会有一条橙色横幅明确说明
「数据只存在这台机器上」，不会假装它是真的。

要接真实后端：

```bash
cp .env.example .env.local
# 填 VITE_SUPABASE_ANON_KEY，然后按 supabase/README.md 在 SQL Editor 里跑一次迁移
npm run check:env    # 验证后端是否就绪
```

---

## 数据流

```
                    ┌──────────────── 浏览器 ────────────────┐
  用户拖入 zip ──▶  │ parseSkill()                          │
                    │  ├─ unzipSync（fflate）               │
                    │  ├─ 剥顶层目录 / 丢 .DS_Store / 挡 ..  │
                    │  ├─ 读 SKILL.md → frontmatter 解析     │
                    │  ├─ analyze() 体积与文件数校验         │
                    │  └─ packZip() → sha256 内容哈希        │
                    └───────────────┬───────────────────────┘
                                    │ 预览 + 可编辑元信息
                                    ▼
                         publish_skill(p_payload)
                                    │
                    ┌───────────────▼───────────────────────┐
                    │ Supabase（表对 anon 全关，只走 RPC）    │
                    │  skills / skill_upload_log            │
                    └───────────────┬───────────────────────┘
                                    │
        ┌───────────────────────────┼───────────────────────────┐
        ▼                           ▼                           ▼
  list_skills()              download_skill()            register_install()
  （不含 bundle_b64）         （取包 + 计数，同一事务）      （安装量 +1）
```

**为什么表对 anon 完全关闭**：`bundle_b64`（技能包本体）和 `readme` 都很占带宽。
如果表可读，任何人都能写个循环把整库拖走。走 RPC 之后，「拿包体」和「+1 下载量」
绑在同一个事务里，计数天然不会漏，也没法绕过。

---

## 安装是怎么工作的

站点是纯静态托管（GitHub Pages），没有服务端能替用户「安装」。所以安装 = **给一段能真正跑起来的命令** —— 而且是**按系统给**：

```bash
# macOS / Linux
curl -fsSL https://jiepijiang.github.io/jerry-skills/install.sh \
  | bash -s -- pdf-editor --agent claude
```

```powershell
# Windows（在 PowerShell 里，不是 cmd）
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; & ([scriptblock]::Create((New-Object Net.WebClient).DownloadString('https://jiepijiang.github.io/jerry-skills/install.ps1'))) -Slug pdf-editor -Agent claude
```

详情页的「系统」选择器只有**两档**，不是三档：macOS 与 Linux 用的是**同一条** `curl | bash`，硬拆成两个选项只会让人切来切去发现「怎么一点没变」—— 那比少一个选项更让人困惑。默认值按 UA 猜（Windows 用户打开就是对的），但随时能改。

两个脚本都由 `scripts/gen-installers.mjs` 在**构建期**从环境变量生成（内联 Supabase 端点）。做的事一样：拉取技能包 → base64 解码 → 校验是 zip → 备份已有目录 → 解压到对应助手的 skills 目录 → 校验 SKILL.md 存在。

> **一份生成逻辑，两个模板**。读 `.env`、替换占位符、「替换不干净就报错」这套逻辑两处各写一份迟早会漂移，
> 而漂移的症状特别难查 —— 表现为「macOS 能装、Windows 装不了」。

### Windows 那一条为什么这么长

每一个字符都有原因，别顺手「简化」：

| 这一段 | 为什么不能省 |
| --- | --- |
| `…SecurityProtocol=…Tls12` | 老一些的 Windows PowerShell 5.1 默认只协商 TLS 1.0，连 GitHub Pages 会以「基础连接已经关闭」这种看不出原因的错失败 |
| `(New-Object Net.WebClient).DownloadString(…)` | 不能用 `irm`：`irm` 遇到 `application/octet-stream` 在 **PS 5.1** 上返回的是 `byte[]`，`[scriptblock]::Create` 会直接抛错 —— 而 GitHub Pages 给 `.ps1` 发的正是这个 content-type。（PS 7 上 `irm` 恰好返回字符串，所以这个坑**本地用 pwsh 试是试不出来的**，只有 Windows 自带的 5.1 上才现形） |
| `[scriptblock]::Create(…)` + `&` | 不能用 `irm … \| iex`：后者没法给脚本传参数，而我们要把 slug 和 agent 交进去 |
| 不走 `powershell -File` | 那得先把脚本落盘，还会撞上 ExecutionPolicy。`[scriptblock]::Create` 不落盘，也就不受执行策略限制 |

⚠️ 支持的目标目录在 **三个地方**定义，必须一致：

| 位置 | 用途 |
| --- | --- |
| `src/data/site.js` 的 `agents` | 前端渲染「会装到哪」 |
| `scripts/install-sh.tpl` 的 `dir_for_agent()` | macOS/Linux 脚本实际落盘位置 |
| `scripts/install-ps1.tpl` 的 `$AgentDirs` | Windows 脚本实际落盘位置 |

不一致会出现「网页写着装到 A、实际装到 B」—— 改一处必须同步改另外两处。
`installers.test.mjs` 里有一条把这三份表抓出来逐个比对。

### install.ps1 上几个只在 PowerShell 里才成立的事

都是在真 pwsh 里跑出来的，不是读代码看出来的：

| 坑 | 事实 |
| --- | --- |
| **`exit` 会关掉用户的终端** | 脚本是被 `[scriptblock]::Create(…)` 之后用 `&` 调起来的，在**交互式** PowerShell 里 `exit` 直接结束整个会话（实测：`exit` 之后同一条命令串里后面的语句根本不执行）。所以失败路径一律 `throw`，**一个 `exit` 都没有** |
| **变量名会吃掉后面的中文** | 和 bash 同一个坑，但 PowerShell 这边是**静默变空串**、不报错：`$a中文` 被解析成变量名 `a中文`。所以模板里一律写 `${VAR}`，单测里有正则钉住 |
| **进度条会混进输出** | 非交互式宿主把进度条**渲染成文字**，`Expand-Archive` 尤其吵。而且必须用 `$global:ProgressPreference` 才压得住 —— 它来自 `Microsoft.PowerShell.Archive` **模块**，模块函数看不到调用方的局部作用域（实测：脚本内普通赋值**完全不管用**）。用完还原，别把用户的会话设置改掉 |
| 错误提示的尾巴 | 失败时会多打一行 `Exception:`（PowerShell 对 `throw` 的标准渲染）。留着的理由：**退出码必须是 1** —— 详情页给的 AI 提示词就是让 agent 照着跑这条命令、靠退出码判断成败，静默返回 0 是更糟的错 |

---

## 目录结构

```
src/
├── lib/
│   ├── frontmatter.js     YAML 子集解析（自写，不引 js-yaml —— 输入不可信）
│   ├── parseSkill.js      ★ 核心：zip → 结构化技能对象（纯函数，可单测）
│   ├── category.js        ★ 分类推断（全站唯一的 key 真源）
│   ├── time.js            时间显示（卡片与详情页共用一份）
│   ├── admin.js           站主口令（sessionStorage，关标签页即失效）
│   ├── install.js         安装命令 / Agent 提示词生成
│   ├── supabase.js        PostgREST 直连（不引 SDK）
│   ├── skills-api.js      数据门面：READY ? RPC : localStore
│   ├── localStore.js      本地演示模式（种子 + localStorage）
│   └── seedSkills.js      演示用种子技能
├── components/            AppIcon / SkillCard / AppDialog / FileTree / HubToast / …
├── views/                 HomeView / SkillDetailView / UploadView
├── composables/           useCopy / useToast / useSearch / useAdmin
├── data/site.js           ★ 所有文案、分类、目标目录、限额
└── styles/                root.css（主题变量）/ base.css / hub.css

scripts/
├── install-sh.tpl         install.sh 模板（macOS / Linux）
├── install-ps1.tpl        install.ps1 模板（Windows / PowerShell）
├── gen-installers.mjs     predev / prebuild 钩子：把端点注入上面两个模板
├── check-supabase-env.mjs 构建期核对（分 warning / error 两档）
└── tests/                 单测 139 条（明细见下面「验证」）

supabase/
├── migrations/001-skills.sql        表 + RLS + 5 个 SECURITY DEFINER 函数
├── migrations/002-admin-delete.sql  站主删除：口令校验 + 回收站 + 双重重限流
├── set-admin-token.sql              设置 / 更换管理口令（**口令不进 git**）
├── preflight-check.sql              跑迁移**之前**先跑的只读冲突预检
├── reset-skills.sql                 清空全部技能数据（需手动跑）
├── verify-migration.mjs             PGlite 离线验证（共用项目替身 + 前后快照对比）
├── verify-admin-delete.mjs          PGlite 离线验证（002 的安全逻辑，67 项）
└── verify-reset-sql.mjs             PGlite 离线验证（清库脚本）
```

---

## 界面一致性：三个「上传技能」按钮为什么会长得不一样

站上有**三个**入口都叫「上传技能」：顶栏一个、首页空状态一个、详情页空状态一个。
它们本该长得一模一样，但实际有一个明显矮一截、图标也灰扑扑的。

**根因不在按钮，在 CSS**。空状态那个图标原本是 `EmptyState.vue` 里一个**装饰性**的
`<AppIcon>`，`hub.css` 里用后代选择器给它上色：

```css
.empty svg { fill: var(--hub_muted); opacity: .6; }   /* ← 元凶 */
```

而 `EmptyState` 有个 `<slot />`，首页/详情页把**「上传技能」按钮塞进了这个插槽**。
后代选择器不看组件边界 —— 于是 `.empty svg` 顺带命中了**插槽里按钮自己的图标**。
两者特异性都是 `(0,1,1)`（`.empty svg` 与 `.btn svg` 打平），**按源码顺序后者被前者盖掉**，
图标就变灰了；尺寸则是因为那个入口此前多写了个 `.sm`。

修法：

- 装饰图标改用**组件自己的 scoped 类** `.empty-icon` —— scoped 属性让样式不可能漏出去；
- `hub.css` 里删掉 `.empty svg`，并**留一条注释说明为什么不能再加回来**；
- 三处按钮统一用默认尺寸（38px），顶栏那个图标按钮也固定成 38px 见方，整排同高。

钉住这件事的是 `scripts/tests/ui-consistency.test.mjs`：它**剥掉注释后**再扫
`hub.css`，只要出现 `.empty svg` 这类会漏进插槽的后代选择器就报红。

> 「先剥注释」不是洁癖 —— `hub.css` 里那段**解释「为什么不能写 `.empty svg`」的注释**
> 本身就含这串字，不剥的话断言会永远为真。所以这一步**两个方向都造了红**：
> 注释里放一条**完整规则**时应当 6/6 绿（正确剥掉）；把 `stripComments` 改成
> `return src` 之后，那条断言**立刻变红**。只验前一半，就只是「碰巧没踩到」。

---

## 验证

```bash
npm test          # 139 条断言：解析 28 · 分类 25 · 站主删除 20 · 时间 13
                  #              卡片渲染 11 · 安装器 22 · 安装命令 14 · 界面一致性 6
npm run build     # 构建（会先跑 gen-installers，生成 install.sh + install.ps1）
npm run check:env # 后端连通性（未配则只警告）
```

> **跑 Windows 那部分要本机有 PowerShell**。默认找 PATH 上的 `pwsh`；没装的话，
> 那 8 条（解析器 / 注入守卫 / 参数校验 / `-Help` / 进度条还原 / 三条端到端）会
> **跳过而不是失败** —— 跳过会在 tap 里明写 `# SKIP 本机没有 pwsh`，不会伪装成绿灯。
> 本机 pwsh **不在 PATH 上**（是从官方 tarball 解到 `~/.workbuddy-ai/binaries/pwsh/pwsh` 的），
> 所以本机要跑全量得显式指路：
>
> ```bash
> PWSH_PATH=~/.workbuddy-ai/binaries/pwsh/pwsh npm test
> ```
>
> 全量实测 **139 pass / 0 fail / 0 skipped，约 11s**；不指定时是 **131 pass / 8 skipped，约 2s**。
> CI 的 ubuntu runner 预装 pwsh，跑的就是全量。

按本项目的纪律，**写完断言要故意造红一次**，确认它真会失败。已验证：

> 「实测」列里的编号是 `npm test` **全量输出**里的 `ok N`（本机实测稳定；`installers.test.mjs`
> 那批从 60 号起编）。别拿**单跑一个测试文件**时的编号去对 —— 那是另一套。

| 造红开关 | 期望红 | 实测 |
| --- | --- | --- |
| 把 `tags` 的 undefined 守卫改回裸 `.slice` | 1 条 | ✅ 1 条（`parseSkill：缺 SKILL.md`） |
| 把路径排序改回 `localeCompare` | 2 条 | ✅ 2 条（`readZip` / `parseSkill：完整走通`） |
| 删掉卡片上的时间元素 | 3 条 | ✅ 3 条（渲染 / title / 与共享模块一致） |
| `parseTime` 改回朴素的 `new Date(iso)` | 5 条 | ✅ 5 条（含「不能是 56 年前」） |
| 详情页又自己写一份 `relativeTime` | 1 条 | ✅ 1 条（防漂移守卫） |
| 去掉 `site.js` 的 `typeof window` 守卫 | 7 条 | ✅ 7 条（整个渲染测试文件加载失败） |
| 取消分类的内容推断 | 2 条 | ✅ 2 条（`resolveCategory` 走推断的两条） |
| 让推断永远得不出结论（阈值拉满） | 5 条 | ✅ 5 条（含 `★ ikotek-cli` 那条回归护栏） |
| 分类关键词去掉词边界（改成裸 `includes`） | 3 条 | ✅ 3 条（`api`→`capital` 等误伤） |
| `normalizeCategory` 认不出时返回 `other` | 3 条 | ✅ 3 条（「不认识」与「就是其他」混为一谈） |
| 推断阈值降到 1（什么都敢下结论） | 1 条 | ✅ 1 条（文件路径不再只配打破平局） |
| `site.js` 的 `CATEGORY_META` 漏一个分类 | 1 条 | ✅ 1 条（覆盖率检查） |
| 卡片 tooltip 退回光秃秃的「安装量」 | 2 条 | ✅ 2 条（口径说明 / 文案统一） |
| 详情页 tooltip 退回光秃秃的「安装量」 | 1 条 | ✅ 1 条（文案统一） |
| `metricNotes.installs` 改成短标签 | 1 条 | ✅ 1 条（口径说明） |
| 详情页安装区的说明不再引用 `metricNotes` | 1 条 | ✅ 1 条（安装区口径检查） |
| 删掉说明正文但保留提到「复制次数」的注释 | 1 条 | ✅ 1 条（证明注释剥除真的生效） |
| 卡片删除按钮去掉 `v-if="isAdmin"` | 1 条 | ✅ 1 条（未解锁就不该渲染） |
| 把删除按钮挪进 `<router-link>` 里 | 1 条 | ✅ 1 条（`<button>` 嵌 `<a>` 是非法嵌套） |
| `skills-api` 把 `p_token` 写成 `p_pass` | 1 条 | ✅ 1 条（跨文件比对 SQL 签名） |
| `skills-api` 把 `p_slug` 写成 `slug` | 1 条 | ✅ 1 条（同上） |
| 忘了给 `skill_admin_delete` 发 `grant` | 1 条 | ✅ 1 条（线上 404，本地无感） |
| 忘了 `revoke` 内部函数 | 1 条 | ✅ 1 条（anon 会拿它当口令预言机） |
| 图标名拼错（`trash` → `trashx`） | 1 条 | ✅ 1 条（否则渲染成一片空白） |
| 首页忘了接 `@deleted` | 1 条 | ✅ 1 条 |
| 详情页绕过 `useSkillDelete` 直接调 API | 1 条 | ✅ 1 条 |
| 详情页删除按钮去掉 `v-if="isAdmin"` | 1 条 | ✅ 1 条 |
| **文案 key 写错顺序**（`confirmDelete` → `deleteConfirm`） | 2 层 | ✅ 单测 1 条 + **浏览器 2 条**（见下） |
| 把 `install.ps1` 的 `throw ''` 换回 `exit 1` | 1 条 | ✅ 1 条（`not ok 67`，「一个 `exit` 都不能有」） |
| 去掉 `$global:ProgressPreference` 的 `$global:` | 1 条 | ✅ 1 条（`not ok 68`，普通赋值压不住模块函数的进度条） |
| 改坏 `install-ps1.tpl` 里一个 agent 目录 | 2 条 | ✅ 2 条（三处目录表比对 + 一条端到端） |
| 把注入守卫改回 `-eq '__SUPABASE_URL__'` | **6 条** | ✅ 6 条（自指哨兵：全局替换会把守卫本身也换掉） |
| `install.ps1` 里 `${Agent}` 写成裸 `$Agent` | 1 条 | ✅ 1 条（变量名吃掉后面的中文 → 静默变空串） |
| 把 `install.ps1` 字符类里的 `"` 去掉（退回「少查一个双引号」） | 1 条 | ✅ 1 条（`not ok 73`：恶意 slug 溜过校验，一路走到网络层才炸） |
| 把 `.empty svg` 加回 `hub.css` | 1 条 | ✅ 1 条（后代选择器漏进插槽，按钮图标被改色） |
| 在 `hub.css` **注释里**放一条完整的 `.empty svg { … }` | 0 条（该绿） | ✅ 6/6 绿（证明剥注释真的生效） |
| 把 `stripComments` 改成 `return src`（停用剥注释） | 1 条 | ✅ 1 条（少了这条，守卫会被一句注释骗过去） |
| 把 `install-sh.tpl` 里的 `__SITE_URL__` 退回 `__SITE__` | 1 条 | ✅ 1 条（`not ok 62`，精确报出 `["__SITE__"]`） |
| 去掉 `packZip` 的 `{ mtime: … }`（退回 fflate 默认的 `Date.now()`） | 2 条 | ✅ 2 条（时间戳常量 / 时钟拧 6 年）。**同时那条旧的「哈希稳定」照样绿** —— 假绿坐实 |

后端迁移另有一层离线验证（PGlite 真跑 SQL），见 `supabase/README.md`：

| 造红开关 | 期望红 | 实测 |
| --- | --- | --- |
| 删掉 `revoke all on public.skills` | 1 条 | ✅ 1 条（anon 读表不再被硬拒） |
| 把 `skills` 改名撞 `bookmarks` | 迁移报错 | ✅ `column "created_at" does not exist` |
| 静默重定义 `is_admin()` | 1 条 | ✅ 1 条（函数快照对比抓到） |
| 偷偷给 `bookmarks` 加一列 | 1 条 | ✅ 1 条（列快照对比抓到） |

基线 `51/51`。

002 的离线验证（`verify-admin-delete.mjs`，基线 `67/67`）另有 10 个造红，
每一个都如期让**指定的那条**断言变红：去掉口令校验 / 校验恒真 / 去掉全局上限 /
不写回收站 / 不 `revoke` / 哈希丢掉盐 / 不 `revoke` 内部函数 / 限流把成功也计入 /
**把「没改占位符」的守卫写成一整串比较** / **删掉「002 还没跑」的前置检查**（见下）。

> 🔴 **一个「全局替换」就能触发的坑**（真实踩到）：
> `set-admin-token.sql` 里那道「你有没有改掉占位符」的守卫，原本写成
> `if v_pass = '<占位符>'` —— 而**这一行自己也含有占位符**。
> 改口令最自然的做法是全局替换（`sed` / 编辑器全选替换），于是守卫那行也被一起换掉，
> 变成「拿你的口令和你的口令比」→ 恒真 → **永远**报「请先把 v_pass 改成你自己的口令」，
> 而且报得让人完全摸不着头脑（明明已经改了）。
>
> 现在守卫里的占位符**拆成两段拼起来**比较，全局替换碰不到它；
> 验证脚本里加了一条 `replaceAll` 的断言，并实测过把守卫还原成整串比较后
> **只有那一条**变红（`合计 65 项，通过 64，失败 1`）。

> 🔴 **一个只有看截图才发现的 bug**（真实踩到，不是演练）：
> 确认按钮的文案 key 我在 `site.js` 里写成了 `deleteConfirm`，而两个模板引用的都是
> `adminNotes.confirmDelete` —— 一个词序之差。Vue 对 `undefined` 的插值**不报错**，
> 只是渲染成空串，于是那个按钮变成**一颗纯红色药丸、上面一个字都没有**。
> 单测全绿、构建全绿、**连浏览器功能测试也全绿**（按钮照样能点、技能照样删得掉），
> 因为没有任何一条断言在检查「按钮上有没有字」。
>
> 修完之后补了两层断言：单测里「模板引用的文案 key 必须在 `site.js` 里定义且非空」，
> 以及浏览器里「弹窗每个按钮的 `textContent` 不能为空」。
> 两个都实测过会红（单测 `not ok`、浏览器 `""(25px) ← 有 1 个是空的`）。

### 对着真实后端的端到端验证

五层都跑过（脚本在本机 AI 工作区，未进仓库）：

| 层 | 验什么 | 结果 |
| --- | --- | --- |
| 只读 | 首页无演示模式横幅、真的发出 `list_skills` 且 200、渲染卡片数与后端 `total` 一致、`install.sh` **和** `install.ps1` 两个端点都已注入 | 17/17（线上） |
| 写入 | 上传 zip → 落库 → 详情页 → 下载（**下载字节的 sha256 等于库内 hash**）→ 下载量/安装量落库 → 列表 → 元信息 → 同内容去重 `exists` → 非法提交被拒 | 37/37 |
| 安装（macOS/Linux） | `curl … \| bash -s -- <slug> --agent workbuddy`，用临时 `HOME` 真装一遍，校验文件落地与内容逐字节一致；含缺 slug / 非法 agent / 含引号 slug 三个造红 | 16/16 |
| 安装（Windows） | 同样的端到端在**真 pwsh** 里跑 `install.ps1`（假 Supabase 发真 zip）：装好 → 再装一次先备份且**保住用户改过的文件** → 临时目录清干净 → 中文 slug 原样往返 → `not_found` 给可操作提示 | 8/8 |
| 界面 | 三个「上传技能」按钮逐个量盒模型与计算样式，要求**完全一致**；Windows 那条长命令在代码块里不横向溢出、但复制到的仍是**一整行** | 31/31 + 14/14 |

> ⚠️ 本机环境注意：工具 shell 注入的 `http_proxy`（`127.0.0.1:55262`）对
> `supabase.co` 不好使，curl 走它会 `SSL_ERROR_SYSCALL`，而直连 0.38s 就通。
> 跑这些验证要 `--noproxy '*'` 或清掉代理变量。这是本机问题，不是脚本缺陷 ——
> 所以修的是验证脚本，**没给 `install.sh` 加 `--noproxy`**（那会坑到真正需要代理的用户）。
>
> Windows 那边是**另一个坑**：`HttpClient` 会读系统代理，而 `.NET` 对一个
> **不可路由的端口**（比如 `127.0.0.1:1`）不会快速失败，而是**硬等满 `-TimeoutSec`**。
> 所以跑 ps1 的测试时必须把 `http_proxy` 一族从子进程 env 里删掉、并设
> `NO_PROXY=127.0.0.1,localhost`，否则每条用例都要干等 30–60 秒（看着像「连不上网」）。

**造红过程中真的抓出四个 bug**（不是演练，是先写测试时暴露的）：

1. 没有 SKILL.md 的包会让 `meta.tags.slice()` 抛 TypeError —— 用户看到的是
   「上传崩了」而不是「缺少 SKILL.md」。
2. 路径排序用了 `localeCompare`，**受运行环境 locale 影响**。而文件顺序决定
   `packZip` 的字节序 → 决定内容 hash。不同地区的人上传同一份技能会算出两个 hash，
   **去重直接失效**。改成码位比较后与环境无关。
3. `install.ps1` 的 slug 校验**比 `install.sh` 少查一个双引号**。症状是
   「macOS 报错、Windows 装上了」—— 因为 `-Slug 'x","p_slug":"y'` 能溜过 PowerShell
   的校验，直到网络层才出问题。**造红时复现的正是这个**：脚本打印
   「正在获取 `x","p_slug":"y` …」然后才 `Connection refused`，而不是在校验处早退。
   修法是让两边的**规则集对齐** —— bash 侧是 `case "$SLUG" in *'"'*|*'\'*)`，
   PowerShell 侧是 `-match '[\x00-\x1f"\\]'`（额外挡掉控制字符），两边都拒 `"` 与 `\`。
   钉住它的是 bash / PowerShell **各一条**「喂同一个恶意 slug，必须报『非法的技能标识』」
   的断言 —— 不是「三处目录比对」那条（那条管的是 agent 目录表）。
4. **`packZip` 不是确定性的，内容去重形同虚设**。fflate 的 `zipSync` 在条目没给
   `mtime` 时用 `Date.now()`，于是 zip 头里的 DOS 时间字段每 2 秒变一次，
   同样内容每次打包出来的字节都不同 → sha256 不同 → 服务端那句
   `where hash = v_hash` 永远匹配不上。**线上实测：13 条技能原样再传一遍，
   总数变成 17。** 修法是给每个条目固定 `mtime`（`new Date(1980, 0, 1)` —— 见下）。

> 🔴 **一个把自己堵死的测试**（真实踩到，症状极具误导性）：
> 写 ps1 的端到端时用了 `spawnSync` 去起 pwsh，而假 Supabase 是**跑在同一个 Node 进程里**的
> 临时 HTTP server —— `spawnSync` 把事件循环整个堵死，子进程发出的请求**永远没人应答**。
>
> 表现是每条用例都在**整 30 秒**后失败，看起来完全像「脚本连不上网」，
> 于是很容易跑去查网络 / 代理（也确实会查出一堆无关的线索：直连是 `Connection refused`、
> 走沙箱代理是 `502`）。真正的判据是**失败时间整齐划一** —— 真实网络故障不会这么齐。
>
> 改成异步 `spawn` + `Promise` 后，整个套件从 **185s → 11s**。
> 记住这条：**在进程内起服务、又要在测试里连它，就不能用 `spawnSync`。**

> 🔴 **一个「所有自动检查都放行」的漏替换**（真实踩到，而且是上一版就潜伏的）：
> `install-sh.tpl` 的 `--help` 示例里写着 `curl -fsSL __SITE__/install.sh`，
> 而生成器只替换 `__SITE_URL__` —— 那串 `__SITE__` **原封不动**发到了线上，
> 用户跑 `install.sh --help` 看到的是个连不上的地址。
>
> 它能同时躲过三道关，每一道都有「合理的理由」不看它：
> - 生成器里的「残留占位符」守卫只查 `TOKENS` 那三个 —— `__SITE__` 不在名单里；
> - CI 的产物核对查的是「**真实 URL 在不在**」—— 它确实在（`ENDPOINT=` 那行）；
> - 语法完全合法 —— 它只是个字符串字面量，`bash -n` 与 PS 解析器都过。
>
> **发现方式是部署完之后真的去 `curl` 线上那两个文件读一遍**，不是靠跑测试。
> 所以补的守卫是**反向**的：模板里出现的任何 `__XXX__` 都必须在替换名单里。
> 这条比「列举已知坏 token」强 —— 它管的是**没见过的**那种。

> 🔴 **一条绿了很久的假断言：测「稳定性」时别让两次取样挨得太近。**
>
> `parseSkill` 的哈希稳定性早就有一条断言：同样内容、条目顺序不同 → 同一个 hash。
> 它一直是绿的。但**它永远会是绿的** —— 两次 `parseSkill` 在同一个进程、同一个
> 2 秒窗口里跑完，而 zip 头的 DOS 时间字段精度正好是 2 秒，
> 旧实现（`zipSync` 不传 `mtime`）在这个间隔里必然算出同一个值。
>
> 换句话说，它测的不是「确定性」，是「碰巧相等」。
> 真正的 bug（同一份技能重复上传不去重）就这么在绿灯底下活到了线上。
>
> 修完之后补的两条断言换了角度，**都不依赖两次调用之间的时间间隔**：
> 一条直接解析 zip 头 offset 10/12 的 DOS 时间字段，断言它等于固定常量；
> 一条把 `Date.now` 分别拧到 2020 和 2026 年，断言输出字节一模一样。
>
> 造红时特意确认了：去掉 `mtime` 之后，**新增两条红、那条旧的照样绿** ——
> 这就是「假绿」的实证。**测时序相关的东西时，先问一句「它有没有可能只是碰巧相等」。**

---

## 分类是怎么判定的

规则写在 `src/lib/category.js`（**唯一的真源**，`data/site.js` 从这里取 key 清单）。

三层，从强到弱：

| 优先级 | 条件 | 结果 |
| --- | --- | --- |
| 1 | SKILL.md 写了 `category` 且能认出来 | 直接用作者的 |
| 2 | 没写 / 写得不认识 → 按 `name` / `tags` / `description` / 文件路径**打分推断** | 用推断结果 |
| 3 | 推断分数低于阈值 | 老实留在「其他」，**不瞎猜** |

### 为什么会「全都跑到其他里去」

旧规则只有第 1 层，而且要求值**精确等于**那 8 个英文 key。问题是：
**Anthropic 官方的 SKILL.md 格式里根本没有 `category` 字段** ——
官方 frontmatter 只有 `name` + `description`（可选 `license` / `allowed-tools`）。

所以真实世界传上来的技能，绝大多数都会被判成「其他」。
2026-10-10 实测：Jerry 自己传的 `ikotek-cli` 就落在 `other`，它的 frontmatter 只有
`name` / `description` / `metadata`。现在它会自动识别成 **development**
（命中：`cli`、`命令行`、`插件`）。

### 几个刻意的设计

- **支持别名与中文**：`dev` / `开发` / `docs` / `文档` / `ops` / `运维` / `数据` … 都认。
  人写 frontmatter 时几乎不会正好写出我们那 8 个英文单词。
- **「不认识」≠「就是其他」**：`normalizeCategory('nonsense')` 返回**空串**而不是 `other`。
  前者该走推断，后者该被尊重。混成一样的话，作者写 `category: misc` 和完全没写会得到同样的处理。
- **不用 readme 做推断**：readme 又长又杂，几乎任何分类都能在里面找到自己的词 ——
  把它算进去等于让「文档长度」决定分类结果。给它一个小权重不如干脆不给。
- **文件路径只配打破平局**：单条权重 1、上限 3，凑不满阈值。
  否则一堆 `scripts/*.ps1` 就能把任何技能判成「开发」。
- **英文关键词按词边界匹配**：`api` 不会命中 `capital`，`word` 不会命中 `keyword` / `password`，
  `ui` 不会命中 `guide` / `build`。这条有专门的测试钉住 —— 裸 `includes` 是最容易埋的假阳性。
- **推断只是预填**：上传页会显示「按内容推断为「开发」（命中：cli、命令行、插件）」，
  并允许随时改。**把依据摆出来**比猜得准更重要 —— 用户看得见才敢信。

---

## 时间显示：为什么只有「上传时间」，没有「更新时间」

列表卡片和详情页显示的时间都是 **`created_at`（上传时间）**，悬浮可看绝对时间。
不显示 `updated_at` 不是偷懒，是**这个站现在根本没有「更新」这件事**：

| 情况 | `publish_skill` 的行为 |
| --- | --- |
| 内容 hash 已存在 | 直接返回 `exists`，**不写库** |
| slug 撞了但内容不同 | 换一个带后缀的新 slug（`xxx-2`），**插一行新的** |

也就是说它从不 `update` 已有行。加一列 `updated_at` 只会得到
**永远等于 `created_at` 的假信息** —— 看起来有信息量，实际是误导。

要真做「更新」得先改 `publish_skill` 的语义（同 slug 覆盖？保留历史版本？
下载量怎么继承？），那是产品决策，不是加一列的事。

时间格式集中在 `src/lib/time.js`（卡片与详情页共用一份，避免两处算法漂移）。
里面有个容易踩的坑，注释写明了：`new Date(null)` 得到的是 **1970-01-01 这个有限值**，
不是 `Invalid Date` —— 不先挡空值，页面上会理直气壮地显示「56 年前」。

---

## 站主删除

站点上有删除按钮，但**只有站主能用**。这个站没有账号体系，所以「站主」靠一个
**管理口令**认人：口令由站主自己在 Supabase 里设，服务端只存
`sha256(盐 || 口令)`，**不存明文**。

| 在哪 | 什么 |
| --- | --- |
| 解锁入口 | 页脚最右边的小字「管理」 |
| 口令存在哪 | `sessionStorage` —— 刷新还在，**关掉标签页就没了** |
| 删除按钮 | 解锁后：详情页头部 + 每张列表卡片右下角 |
| 二次确认 | 两处都有，弹窗里写明「会消失什么」 |

设置口令、恢复已删的技能、以及**这套机制到底挡住了什么**（含一条已知的绕过路径），
见 `supabase/README.md`。

几个刻意的决定：

- **口令只放 `sessionStorage`，不放 `localStorage`**。它能删掉整站数据，
  不该长期留在磁盘上。代价是每次新开标签页要重输一次 —— 这个操作本来就很少做。
  （本站**没有任何 `v-html`**，技能内容全是 mustache 转义渲染的，所以并不存在
  「上传者塞一段脚本偷口令」这条路。但依赖「今天没有 XSS」保护一个长期凭证不划算。）
- **删除是硬删，但先备份整行到 `skills_trash`**（保留 90 天）。
  为什么不软删（`status='deleted'`）：`publish_skill` 的去重查的是
  `where hash = v_hash`（不带 status），软删之后同一份 zip 再上传会命中那条看不见的行 →
  返回 `exists` 却什么都不显示；给查询加上 status 又会撞 `skills_hash_uniq` →
  500。软删**必须**改 `publish_skill` 的语义，那是全站最核心的一段。
  硬删 + 回收站把这份风险降成零，而且删完重传同一份 zip 完全正常。
- **确认弹窗是 `Teleport` 到 body 的**。卡片整个是一个 `<router-link>`，
  弹窗留在卡片内部的话，点「取消」会冒泡给链接 → 反而跳进详情页。
- **卡片根节点是 `<div>` 而不是 `<router-link>`**。`<button>` 嵌在 `<a>` 里是
  非法嵌套，点击归属在部分浏览器上也不可靠。现在链接只包内容、删除按钮是它的兄弟，
  点按钮根本不会冒泡到链接 —— 不需要靠 `stopPropagation` 去救。
- **按钮平时压得很低**（`opacity: .45`，hover 卡片才亮）。它是破坏性操作，
  不该跟「下载量 / 安装量」抢注意力。

### 验证

| 层 | 验什么 | 结果 |
| --- | --- | --- |
| 单测 | 显隐、图标名、文案 key、RPC 参数名 ↔ SQL 签名跨文件比对 | 20 条 |
| 离线 SQL | 口令校验 / 失败关闭 / 盐生效 / 口令错时数据必须还在 / 回收站 / 双重重限流 | 67/67 |
| 浏览器 | 未解锁→解锁→详情页删→卡片删→退出，含「按钮不在 `<a>` 里」「按钮有文字」 | 35/35 |

> ⚠️ 后端（002 迁移）需要你在 SQL Editor 里跑一次才能生效，见 `supabase/README.md`。

---

## 部署

推 `main` 即触发 `.github/workflows/deploy.yml`：单测 → 构建期核对 → 构建 → 核对产物 → 发布 Pages。

需要在仓库 **Settings → Secrets and variables → Actions → Variables** 配：

| 变量 | 说明 |
| --- | --- |
| `VITE_SUPABASE_URL` | `https://swdnendmdmcyqnnjzytv.supabase.co` |
| `VITE_SUPABASE_ANON_KEY` | anon key（公开值，不是秘密） |

用 Variables 而不是 Secrets：anon key 本来就要发给浏览器，放 Variables 更好排查。
**真正的秘密是 `service_role`，那个绝不能进这个工作流**（`check:env` 会拦）。

构建完还有一道**产物核对**：`dist/install.sh` 与 `dist/install.ps1` **两个文件都要**
能 `grep` 到 `VITE_SUPABASE_URL`，否则直接 `exit 1` 让流水线红。
理由是这样错最容易漏到线上：占位符没替换干净时，脚本本身**语法完全合法**，
只是跑起来会去连一个叫 `__SUPABASE_URL__` 的域名 —— 用户在终端里才看到错。
所以宁可让 CI 在发布前拦住。**加安装器时别忘了往这个循环里添一个文件名。**

---

## 已知限制

- **没有账号体系**：任何人可上传，靠 IP 限流（20 次/小时）+ 体积/格式校验兜底。
  要防滥用得上登录或人工审核。
  （**删除**是唯一的例外 —— 它要管理口令，见上面「站主删除」。
  但上传仍然是完全开放的，这是刻意的：这是个分享站，上传门槛高就没人用了。）
- **管理口令的限流里，按 IP 那道可以被绕过**：`_client_ip()` 取 `x-forwarded-for`
  的第一段，而客户端能自己塞这个头。所以真正兜底的是**全站 30 次失败/小时**那道
  全局上限（不依赖任何客户端输入）。同一个问题也存在于 `publish_skill` 的上传限流
  （历史遗留，还没改）。详见 `supabase/README.md`。
- **分类是启发式推断的，会判错**：没写 `category` 的技能靠关键词打分，
  遇到「什么都沾一点」的描述就可能归错类。所以推断**只用于预填表单**、
  永远允许人工改，且认不出来时宁可老实留在「其他」也不硬猜。
  真要准确得让上传者自己写 `category` —— 上传页已经把规则写在页头了。
- **「安装量」的口径**：记的是「复制过安装命令 / Agent 提示词的次数」。
  复制不等于真的装了 —— 纯静态站点拿不到更强的信号。
  这个口径是**产品上确认过的**（2026-10-10）：宁可标一个诚实的近似值，
  好过伪造一个看起来精确的数字。

  口径文案统一放在 `src/data/site.js` 的 `metricNotes`，**每处显示都必须能自己解释自己**：

  | 位置 | 怎么解释 |
  | --- | --- |
  | 列表卡片 | 悬浮 tooltip |
  | 详情页 meta 行 | 悬浮 tooltip |
  | 详情页安装区 | 标题旁「复制即计入「安装量」」+ 一段说明 |
  | 排序 chip | 悬浮 tooltip |

  有测试钉住「不许退回光秃秃的 `title="安装量"`」—— 光给个标签，用户会以为是
  「真的装到 N 台机器上」。
- **技能包上限 2 MB（解压后）**：够放脚本与文档，放不下大模型权重。
- **不做内容审核**：页面上有明确的安全提示，但技能包是否可信由上传者负责。
- **深链接的 HTTP 状态是 404**（GitHub Pages 的固有限制）：`/upload`、`/skills/xxx`
  这类路径在 Pages 上没有对应的物理文件，只能靠 `404.html`（内容是一份
  `index.html`）兜底。**页面渲染完全正常**，但响应状态码是 404 ——
  影响的是链接预览 / SEO 抓取这类不吃 JS 的场景。
  `jerry-site` / `jerry-tools` / `jerry-notes` 是同样行为（已实测四站一致）。
  真要修得换支持 rewrite 的托管（Netlify / Vercel / Cloudflare Pages）。
