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
| 一键复制安装 | 生成一条 `curl … \| bash` 命令，复制即用 |
| AI Agent 安装 | 生成一段自然语言提示词，粘给任意 agent 让它自己装 |

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

站点是纯静态托管（GitHub Pages），没有服务端能替用户「安装」。所以安装 = **给一段能真正跑起来的命令**：

```bash
curl -fsSL https://jiepijiang.github.io/jerry-skills/install.sh \
  | bash -s -- pdf-editor --agent claude
```

`install.sh` 由 `scripts/gen-install-sh.mjs` 在**构建期**从环境变量生成（内联 Supabase 端点）。
它做的事：拉取技能包 → base64 解码 → 校验是 zip → 备份已有目录 → 解压到对应助手的 skills 目录 → 校验 SKILL.md 存在。

⚠️ 支持的目标目录在 **两个地方**定义，必须一致：

| 位置 | 用途 |
| --- | --- |
| `src/data/site.js` 的 `agents` | 前端渲染「会装到哪」 |
| `scripts/install-sh.tpl` 的 `dir_for_agent()` | 脚本实际落盘位置 |

不一致会出现「网页写着装到 A、实际装到 B」—— 改一处必须同步改另一处。

---

## 目录结构

```
src/
├── lib/
│   ├── frontmatter.js     YAML 子集解析（自写，不引 js-yaml —— 输入不可信）
│   ├── parseSkill.js      ★ 核心：zip → 结构化技能对象（纯函数，可单测）
│   ├── install.js         安装命令 / Agent 提示词生成
│   ├── supabase.js        PostgREST 直连（不引 SDK）
│   ├── skills-api.js      数据门面：READY ? RPC : localStore
│   ├── localStore.js      本地演示模式（种子 + localStorage）
│   └── seedSkills.js      演示用种子技能
├── components/            AppIcon / SkillCard / FileTree / HubToast / …
├── views/                 HomeView / SkillDetailView / UploadView
├── composables/           useCopy / useToast / useSearch
├── data/site.js           ★ 所有文案、分类、目标目录、限额
└── styles/                root.css（主题变量）/ base.css / hub.css

scripts/
├── install-sh.tpl         install.sh 模板
├── gen-install-sh.mjs     prebuild 钩子：注入端点
├── check-supabase-env.mjs 构建期核对（分 warning / error 两档）
└── tests/parse-skill.test.mjs  解析层单测（26 条）

supabase/
├── migrations/001-skills.sql  表 + RLS + 5 个 SECURITY DEFINER 函数
├── preflight-check.sql        跑迁移**之前**先跑的只读冲突预检
└── verify-migration.mjs       PGlite 离线验证（共用项目替身 + 前后快照对比）
```

---

## 验证

```bash
npm test          # 解析层 26 条断言
npm run build     # 构建（会先跑 gen-install-sh）
npm run check:env # 后端连通性（未配则只警告）
```

按本项目的纪律，**写完断言要故意造红一次**，确认它真会失败。已验证：

| 造红开关 | 期望红 | 实测 |
| --- | --- | --- |
| 把 `tags` 的 undefined 守卫改回裸 `.slice` | 1 条 | ✅ 1 条（`parseSkill：缺 SKILL.md`） |
| 把路径排序改回 `localeCompare` | 2 条 | ✅ 2 条（`readZip` / `parseSkill：完整走通`） |

后端迁移另有一层离线验证（PGlite 真跑 SQL），见 `supabase/README.md`：

| 造红开关 | 期望红 | 实测 |
| --- | --- | --- |
| 删掉 `revoke all on public.skills` | 1 条 | ✅ 1 条（anon 读表不再被硬拒） |
| 把 `skills` 改名撞 `bookmarks` | 迁移报错 | ✅ `column "created_at" does not exist` |
| 静默重定义 `is_admin()` | 1 条 | ✅ 1 条（函数快照对比抓到） |
| 偷偷给 `bookmarks` 加一列 | 1 条 | ✅ 1 条（列快照对比抓到） |

基线 `51/51`。

### 对着真实后端的端到端验证

三层都跑过（脚本在本机 AI 工作区，未进仓库）：

| 层 | 验什么 | 结果 |
| --- | --- | --- |
| 只读 | 首页无演示模式横幅、真的发出 `list_skills` 且 200、渲染卡片数与后端 `total` 一致、`install.sh` 端点已注入 | 17/17（线上） |
| 写入 | 上传 zip → 落库 → 详情页 → 下载（**下载字节的 sha256 等于库内 hash**）→ 下载量/安装量落库 → 列表 → 元信息 → 同内容去重 `exists` → 非法提交被拒 | 37/37 |
| 安装 | `curl … \| bash -s -- <slug> --agent workbuddy`，用临时 `HOME` 真装一遍，校验文件落地与内容逐字节一致；含缺 slug / 非法 agent / 含引号 slug 三个造红 | 16/16 |

> ⚠️ 本机环境注意：工具 shell 注入的 `http_proxy`（`127.0.0.1:55262`）对
> `supabase.co` 不好使，curl 走它会 `SSL_ERROR_SYSCALL`，而直连 0.38s 就通。
> 跑这些验证要 `--noproxy '*'` 或清掉代理变量。这是本机问题，不是脚本缺陷 ——
> 所以修的是验证脚本，**没给 `install.sh` 加 `--noproxy`**（那会坑到真正需要代理的用户）。

**造红过程中真的抓出两个 bug**（不是演练，是先写测试时暴露的）：

1. 没有 SKILL.md 的包会让 `meta.tags.slice()` 抛 TypeError —— 用户看到的是
   「上传崩了」而不是「缺少 SKILL.md」。
2. 路径排序用了 `localeCompare`，**受运行环境 locale 影响**。而文件顺序决定
   `packZip` 的字节序 → 决定内容 hash。不同地区的人上传同一份技能会算出两个 hash，
   **去重直接失效**。改成码位比较后与环境无关。

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

---

## 已知限制

- **没有账号体系**：任何人可上传，靠 IP 限流（20 次/小时）+ 体积/格式校验兜底。
  要防滥用得上登录或人工审核。
- **「安装量」的口径**：记的是「复制过安装命令 / Agent 提示词的次数」。
  复制不等于真的装了 —— 纯静态站点拿不到更强的信号。这是有意的取舍，
  好过伪造一个看起来精确的数字。
- **技能包上限 2 MB（解压后）**：够放脚本与文档，放不下大模型权重。
- **不做内容审核**：页面上有明确的安全提示，但技能包是否可信由上传者负责。
- **深链接的 HTTP 状态是 404**（GitHub Pages 的固有限制）：`/upload`、`/skills/xxx`
  这类路径在 Pages 上没有对应的物理文件，只能靠 `404.html`（内容是一份
  `index.html`）兜底。**页面渲染完全正常**，但响应状态码是 404 ——
  影响的是链接预览 / SEO 抓取这类不吃 JS 的场景。
  `jerry-site` / `jerry-tools` / `jerry-notes` 是同样行为（已实测四站一致）。
  真要修得换支持 rewrite 的托管（Netlify / Vercel / Cloudflare Pages）。
