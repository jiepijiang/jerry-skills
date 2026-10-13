/**
 * 站点内容配置
 * ---------------------------------------------------------------------------
 * 页面里所有文案、分类、安装目标目录都在这里改，组件本身不需要动。
 */
import { CATEGORY_KEYS } from '@/lib/category'

export { CATEGORY_KEYS }

/**
 * 静态资源路径前缀。
 * GitHub Pages 把站点挂在 /<仓库名>/ 子路径下，写死的 '/static/...' 在 JS 里会 404
 * （Vite 只重写 index.html 和 CSS 里的绝对路径，JS 字符串得自己加前缀）。
 * 本地 dev 时 BASE_URL 就是 '/'，两种环境写法统一。
 */
export const asset = (path) => `${import.meta.env.BASE_URL}${path.replace(/^\//, '')}`

/**
 * 站点公开地址：优先用构建期注入的值，否则按当前 origin 现算（本地开发用）。
 *
 * ⚠️ `typeof window` 这个判断不能省。这是模块顶层求值，而 Node 里没有 window ——
 *    一旦裸引用，**任何** import 到本模块的东西（组件、lib）都没法在 Node 里加载，
 *    于是「用 SSR 把卡片渲染出来断言」这类测试直接写不了。
 *    浏览器里 window 必然存在，加判断对线上行为零影响。
 */
export const SITE_URL =
  (import.meta.env.VITE_SITE_URL || '').trim().replace(/\/$/, '') ||
  (typeof window === 'undefined'
    ? ''
    : `${window.location.origin}${import.meta.env.BASE_URL}`.replace(/\/$/, ''))

export const brand = {
  name: 'Skill Hub',
  /** 站点主色，取自 --gradient 首段 */
  accent: '#bd34fe',
  tagline: '把好用的 AI Agent 技能，装进你的助手',
  description:
    '上传 SKILL.md 或技能压缩包，自动解析元信息与文件结构；一条命令装到 Claude Code / Cursor / Codex / WorkBuddy 等 AI 助手。',
}

/**
 * 技能分类的**展示信息**（label / icon）。
 *
 * key 清单的真源在 `@/lib/category` —— 那边要用同一份清单做内容推断，
 * 两处各写一份的话，加一个分类就会「推断能推出来、页面却显示空白」。
 * 所以这里只负责「长什么样」，不再自己列 key。
 */
const CATEGORY_META = {
  development: { label: '开发', icon: 'code' },
  design: { label: '设计', icon: 'palette' },
  /* 2026-10-12 新增。label 用「UI」而不是「界面」：分类栏里它是唯一一个
     英文缩写，反而一眼就能认出来，也不会和「设计」在视觉上挤成一团。
     图标用 web（浏览器窗口）—— palette 已经被「设计」占着了，
     两个分类共用一个图标，筛选栏上根本分不出谁是谁。 */
  ui: { label: 'UI', icon: 'web' },
  document: { label: '文档', icon: 'doc' },
  data: { label: '数据', icon: 'chart' },
  writing: { label: '写作', icon: 'pen' },
  devops: { label: '运维', icon: 'server' },
  productivity: { label: '效率', icon: 'bolt' },
  other: { label: '其他', icon: 'box' },
}

/**
 * 技能分类。`all` 是筛选用的伪分类，不会入库。
 * 其余 key 从 @/lib/category 来，label / icon 从上表取。
 */
export const categories = [
  { key: 'all', label: '全部', icon: 'grid' },
  ...CATEGORY_KEYS.map((key) => {
    const meta = CATEGORY_META[key]
    // 加了分类却忘了补 label/icon 时，dev 下要吵一声；线上降级成「key + box 图标」而不是渲染空白
    if (!meta && import.meta.env.DEV) {
      console.warn(`[site] 分类 "${key}" 在 CATEGORY_META 里没有 label / icon`)
    }
    return { key, ...(meta || { label: key, icon: 'box' }) }
  }),
]

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
  { key: 'new', label: '最新', hint: '按上传时间' },
  { key: 'downloads', label: '最多下载', hint: '按「下载 .zip」被点过的次数' },
  { key: 'installs', label: '最多安装', hint: '按「复制安装命令 / AI 提示词」的次数' },
  { key: 'rating', label: '评分最高', hint: '按平均星级；没人评过分的排在最后' },
]

/**
 * 评分配置。
 *
 * ⚠️ `max` 必须和 supabase/migrations/003-ratings.sql 里的
 *    `constraint skill_ratings_score_range check (score between 1 and 5)` 一致 ——
 *    前端只是提前拦住，服务端才是真正的闸门（同 `limits` 那条纪律）。
 *    改一处就要同步改另一处，并在 scripts/tests 里加一条断言钉住。
 *
 * 「一人一票」的口径必须自己解释自己：用户会本能地以为「再点一次能投第二票」，
 * 而实际是**改分**。不写清楚的话，改完分看到人数没变会以为坏了。
 */
export const ratings = {
  max: 5,
  /** 每个分值对应的说法，下标 0 对应 1 星 */
  labels: ['很差', '较差', '一般', '不错', '很好'],
  /** 一条评分都没有时显示什么 */
  empty: '还没人评分',
  /** 打分区的说明 —— 把「一人一票、再点一次是改分」讲明白 */
  hint: '一人一票（按 IP 区分）。再点一次是改分，不会重复计票。',
  /** 打完分之后的提示 */
  thanks: (n) => `已记下你的 ${n} 星评价`,
  /** 悬浮/读屏用的「N 星」描述 */
  starLabel: (n) => `${n} 星`,
  /** 平均分保留几位小数（与服务端 round(…, 2) 一致） */
  digits: 2,
}

/**
 * 平均分 → 展示文案。去掉无意义的尾零：4.00 → 4、4.50 → 4.5、4.33 → 4.33。
 *
 * 放在这里、而不是卡片和详情页各写一份：两处显示的是**同一个**数字，
 * 格式化规则一旦分叉，就会出现「卡片写 4.5、详情页写 4.50」这种看着像算错了的差异。
 * 非数字（null / undefined / NaN）一律给空串 —— 调用方拿空串当「不渲染」的条件，
 * 而不是让它渲染出 "NaN"。
 */
export function ratingAvgText(avg) {
  const n = Number(avg)
  if (!Number.isFinite(n) || n <= 0) return ''
  return n.toFixed(ratings.digits).replace(/\.?0+$/, '')
}

/**
 * 计量口径说明。
 *
 * 「安装量」统计的是**复制安装命令 / 提示词的次数**，不是「真的装到本机了」的次数 ——
 * 本站是纯静态托管（GitHub Pages），没有任何服务端能知道命令有没有被粘贴执行。
 *
 * 口径是产品上明确确认过的（2026-10-10）：宁可标一个**诚实的近似值**，
 * 也不编一个看着精确的假数字。所以数字保留「安装量」这个用户关心的叫法，
 * 但每一处显示都必须能解释清楚它到底数的是什么。
 */
export const metricNotes = {
  downloads: '下载量：点过「下载 .zip」的次数。',
  installs:
    '安装量：复制过安装命令 / AI 提示词的次数。本站是纯静态站点，' +
    '拿不到「真的装到本机了」的信号 —— 这是最接近的近似值，不是精确的安装数。',
  rating:
    '评分：访客打的 1~5 星。一人一票（按 IP 区分），重复打分为改分、不会重复计票。' +
    '人数少的时候平均分波动大，仅供参考。',
}

/**
 * 安装目标：各 AI 助手的 skills 目录。
 *
 * ⚠️ 这里的 `dir` 必须和**两个**安装脚本里的一致 —— 前端用它渲染「装到哪」，
 * 脚本用它决定落盘位置。三处不一致会出现「页面写着 A、实际装到 B」。
 * 改这里的时候记得同步：
 *   - scripts/install-sh.tpl  的 dir_for_agent()
 *   - scripts/install-ps1.tpl 的 $AgentDirs
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
 * 安装命令的「系统」维度。
 *
 * ⚠️ 只有**两档**，不是三档。macOS 和 Linux 跑的是同一条 `curl | bash`，
 *    硬拆成两个选项的话，用户切来切去会发现「怎么一点没变」—— 那比少一个选项更让人困惑。
 *    Windows 上没有 bash，`curl | bash` 根本执行不了，所以必须换一条 PowerShell 命令。
 *
 * `key` 要和 src/lib/install.js 里的分支一致。
 */
export const oses = [
  {
    key: 'unix',
    label: 'macOS / Linux',
    /** 详情页命令上方那句说明的开头 —— 直接写进模板，不用拼接 */
    hint: '在「终端」（Terminal）里执行',
    /**
     * AI 提示词里那句「在哪儿执行」。
     * 单独写一份而不是从 `where` 拼：中文里「在终端里执行」不用空格，
     * 但「在 PowerShell 里执行」必须加空格才好看 —— 拼出来的话总有一边是别扭的。
     */
    promptLine: '在终端（Terminal）里执行这条命令即可：',
  },
  {
    key: 'windows',
    label: 'Windows',
    hint: '在 PowerShell 里执行（不是 cmd）',
    promptLine: '在 PowerShell 里执行这条命令即可：',
  },
]

export const DEFAULT_OS = 'unix'

export function osByKey(key) {
  return oses.find((o) => o.key === key) || oses[0]
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

/**
 * 站主管理（删除技能）的界面文案。
 *
 * ⚠️ 口令本身**不在前端**：服务端只存「盐 + sha256(盐 || 口令)」，
 *    前端拿到的口令只放在 sessionStorage，关标签页即失效。
 *    见 supabase/migrations/002-admin-delete.sql。
 *
 * 为什么入口做得这么不显眼（页脚一个小字）：删除权只属于站主一个人，
 * 没必要让每个访客都看见「这里能删东西」并去试口令。
 */
export const adminNotes = {
  entry: '管理',
  entryActive: '管理中',
  title: '站主管理',
  desc: '输入管理口令后，列表和详情页会出现删除按钮。',
  placeholder: '管理口令',
  submit: '解锁',
  logout: '退出管理',
  unlocked: '已解锁。列表卡片和技能详情页上现在都有删除按钮。',
  /** 本地演示模式下的额外提示 —— 那时候根本没有服务端可验 */
  localHint: '当前是本地演示模式：没有真正的鉴权，任何非空口令都会通过，删除也只影响这台浏览器。',
  storageHint: '口令只保存在这个标签页里，关掉标签页就失效，需要重新输入。',
  deleteButton: '删除技能',
  deleteTitle: '删除技能',
  confirmDelete: '确认删除',
  cancel: '取消',
}
