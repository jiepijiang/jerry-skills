/**
 * 站点内容配置
 * ---------------------------------------------------------------------------
 * 页面里所有文案、分类、安装目标目录都在这里改，组件本身不需要动。
 */

/**
 * 静态资源路径前缀。
 * GitHub Pages 把站点挂在 /<仓库名>/ 子路径下，写死的 '/static/...' 在 JS 里会 404
 * （Vite 只重写 index.html 和 CSS 里的绝对路径，JS 字符串得自己加前缀）。
 * 本地 dev 时 BASE_URL 就是 '/'，两种环境写法统一。
 */
export const asset = (path) => `${import.meta.env.BASE_URL}${path.replace(/^\//, '')}`

/** 站点公开地址：优先用构建期注入的值，否则按当前 origin 现算（本地开发用） */
export const SITE_URL =
  (import.meta.env.VITE_SITE_URL || '').trim().replace(/\/$/, '') ||
  `${window.location.origin}${import.meta.env.BASE_URL}`.replace(/\/$/, '')

export const brand = {
  name: 'Skill Hub',
  /** 站点主色，取自 --gradient 首段 */
  accent: '#bd34fe',
  tagline: '把好用的 AI Agent 技能，装进你的助手',
  description:
    '上传 SKILL.md 或技能压缩包，自动解析元信息与文件结构；一条命令装到 Claude Code / Cursor / Codex / WorkBuddy 等 AI 助手。',
}

/**
 * 技能分类。
 * key 会作为 `category` 存库（英文，稳定）；label 只用于展示。
 * `all` 是筛选用的伪分类，不会入库。
 */
export const categories = [
  { key: 'all', label: '全部', icon: 'grid' },
  { key: 'development', label: '开发', icon: 'code' },
  { key: 'design', label: '设计', icon: 'palette' },
  { key: 'document', label: '文档', icon: 'doc' },
  { key: 'data', label: '数据', icon: 'chart' },
  { key: 'writing', label: '写作', icon: 'pen' },
  { key: 'devops', label: '运维', icon: 'server' },
  { key: 'productivity', label: '效率', icon: 'bolt' },
  { key: 'other', label: '其他', icon: 'box' },
]

export const CATEGORY_KEYS = categories.filter((c) => c.key !== 'all').map((c) => c.key)

export function categoryLabel(key) {
  return categories.find((c) => c.key === key)?.label || '其他'
}

/** 分类 → AppIcon 名字。未知分类兜底成 box，别渲染出空白图标 */
export function categoryIcon(key) {
  return categories.find((c) => c.key === key)?.icon || 'box'
}

/**
 * 排序方式。`key` 直接映射到 SQL 里的 order by 分支（见迁移 SQL 的 list_skills）。
 */
export const sorts = [
  { key: 'new', label: '最新' },
  { key: 'downloads', label: '最多下载' },
  { key: 'installs', label: '最多安装' },
]

/**
 * 安装目标：各 AI 助手的 skills 目录。
 *
 * ⚠️ 这里的 `dir` 必须和 install.sh 里的一致 —— 前端用它渲染「装到哪」，
 * 脚本用它决定落盘位置。两处不一致会出现「页面写着 A、实际装到 B」。
 * 改这里的时候记得同步 scripts/install-sh.tpl。
 */
export const agents = [
  { key: 'workbuddy', label: 'WorkBuddy', dir: '~/.workbuddy-ai/skills' },
  { key: 'claude', label: 'Claude Code', dir: '~/.claude/skills' },
  { key: 'cursor', label: 'Cursor', dir: '~/.cursor/skills' },
  { key: 'codex', label: 'Codex CLI', dir: '~/.codex/skills' },
  { key: 'gemini', label: 'Gemini CLI', dir: '~/.gemini/skills' },
  { key: 'copilot', label: 'GitHub Copilot', dir: '~/.copilot/skills' },
  { key: 'windsurf', label: 'Windsurf', dir: '~/.windsurf/skills' },
  { key: 'cline', label: 'Cline', dir: '~/.cline/skills' },
]

export const DEFAULT_AGENT = 'workbuddy'

export function agentByKey(key) {
  return agents.find((a) => a.key === key) || agents[0]
}

/**
 * 上传限制。
 *
 * ⚠️ 这三个数字**必须**和 supabase/migrations/001-skills.sql 里的常量一致 ——
 * 前端是「提前拦住」，服务端是「真正的闸门」。两边不一致会出现
 * 「前端让传、后端拒绝」这种最难解释的现象（主站留言板踩过同样的坑）。
 * 改一处就要同步改另一处，并在 scripts/tests 里加一条断言钉住。
 */
export const limits = {
  maxFiles: 200,
  maxTotalBytes: 2 * 1024 * 1024, // 2 MB
  maxSkillMdBytes: 256 * 1024, // SKILL.md 单文件 256 KB
  maxNameLength: 64,
  maxDescLength: 500,
}

export const footer = {
  text: 'Jerry © 2026 · Skill Hub',
  repo: 'https://github.com/jiepijiang/jerry-skills',
  /** 姊妹站，页脚互链 */
  siblings: [
    { label: '主站', href: 'https://jiepijiang.github.io/jerry-site/' },
    { label: '导航', href: 'https://jiepijiang.github.io/jerry-tools/' },
    { label: '知识库', href: 'https://jiepijiang.github.io/jerry-notes/' },
  ],
}
