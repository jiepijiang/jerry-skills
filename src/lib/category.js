/**
 * 技能分类：判定规则 + 自动推断
 * ---------------------------------------------------------------------------
 * 本站的分类 key 只有下面这 8 个，**这份清单是全站唯一的真源**
 * （`data/site.js` 从这里取，别在别处再抄一份）。
 *
 * ## 原来的规则为什么等于没有规则
 *
 * 之前只有一条规则：读 SKILL.md frontmatter 的 `category` 字段，
 * 值必须**精确等于** 8 个 key 之一，否则一律落到 `other`。
 *
 * 问题在于：Anthropic 官方的 SKILL.md 格式里**根本没有 category 字段** ——
 * 官方 frontmatter 只有 `name` + `description`（可选 `license` / `allowed-tools`）。
 * 所以真实世界里传上来的技能，绝大多数都会被判成「其他」。
 * （2026-10-10 实测：Jerry 自己传的 ikotek-cli 就落在 other，
 *  它的 frontmatter 只有 name / description / metadata。）
 *
 * ## 现在的规则（三层，从强到弱）
 *
 * 1. **SKILL.md 写了 `category`** → 用它。支持别名与中文（`dev` / `开发` / `docs` …）。
 * 2. **没写或写得不认识** → 按 `name` / `tags` / `description` / 文件路径**打分推断**。
 * 3. **推断也没把握**（分数低于阈值）→ 老实留在「其他」，不瞎猜。
 *
 * 推断结果**只用于预填表单**，用户在页面上随时能改 —— 见 UploadView.vue。
 */

/** 全站唯一的分类 key 清单。`other` 是兜底，不参与推断。 */
export const CATEGORY_KEYS = [
  'development',
  'design',
  'ui',
  'document',
  'data',
  'writing',
  'devops',
  'productivity',
  'other',
]

/** 参与推断的分类（去掉兜底的 other） */
const INFER_KEYS = CATEGORY_KEYS.filter((k) => k !== 'other')

/**
 * 别名 → 标准 key。
 * 让 `category: dev` / `category: 开发` / `category: docs` 这些写法也能被认出来 ——
 * 人写 frontmatter 时几乎不会正好写出我们那 8 个英文单词。
 */
const ALIASES = {
  dev: 'development',
  developer: 'development',
  coding: 'development',
  code: 'development',
  engineering: 'development',
  开发: 'development',
  编程: 'development',

  /* ⚠️ 2026-10-12 拆出 ui 分类时改过这里。
     `ui` 现在是**标准 key**，会被 CATEGORY_KEYS 直接命中、根本走不到别名 ——
     所以原来那条 `ui: 'design'` 已删掉：留着是死代码，还会让人以为「ui 归设计」。
     `ux` / `uiux` 则显式改指 ui：界面设计才是这两个词的本义，
     继续归「设计」（品牌 / 视觉 / 平面）会让写 ux 的人落到不相干的分类里。 */
  ux: 'ui',
  uiux: 'ui',
  interface: 'ui',
  界面: 'ui',
  交互: 'ui',
  设计: 'design',

  docs: 'document',
  documentation: 'document',
  doc: 'document',
  文档: 'document',

  analytics: 'data',
  数据: 'data',

  content: 'writing',
  写作: 'writing',

  ops: 'devops',
  运维: 'devops',

  productivity: 'productivity',
  utility: 'productivity',
  utilities: 'productivity',
  效率: 'productivity',

  misc: 'other',
  general: 'other',
  uncategorized: 'other',
  其他: 'other',
  其它: 'other',
}

/**
 * 关键词表。
 * 写法约定：
 *   · 结尾带 `*` → 前缀匹配（`script*` 命中 scripts / scripting）
 *   · 纯 ASCII   → 按**词边界**匹配（`api` 不会命中 `capital`，`go` 不会命中 `google`）
 *   · 含中日韩字 → 直接子串匹配（中文本来就不分词）
 *
 * 选词原则：**宁可少，不要脏**。像 `助手` / `content` / `ad` 这种哪都能出现的词一律不收 ——
 * 收了等于给所有分类加同样的分，反而把真正的信号淹掉。
 */
const RULES = {
  development: [
    'api', 'sdk', 'cli', 'code', 'coding', 'script*', 'debug', 'refactor', 'lint',
    'compile*', 'compiler', 'git', 'github', 'gitlab', 'npm', 'pip', 'cargo',
    'python', 'javascript', 'typescript', 'nodejs', 'golang', 'rust', 'kotlin', 'swift',
    'mcp', 'playwright', 'puppeteer', 'selenium', 'regex', 'json', 'yaml', 'html',
    '代码', '编程', '开发', '脚本', '命令行', '终端', '调试', '重构', '编译', '依赖',
    /* 「组件」2026-10-12 移去 ui —— 它同时挂在两个分类下会让判定随遍历顺序漂移
       （见 category.test.mjs 的「关键词不重叠」那条）。开发这边有「前端 / 框架 / 插件」
       已经够用了，不缺这一个词。 */
    '框架', '插件', '接口', '函数', '前端', '后端', '服务端', '单元测试',
    '源码', '编码', '打包', '构建', '类库',
  ],
  /* 「设计」= 视觉 / 品牌 / 平面，**不含界面本身**。
     界面（UI / 交互 / 组件 / 布局 / 响应式 / 设计系统）2026-10-12 拆去了下面的 ui，
     两边各留一份的话，同一个技能会随「哪个词先命中」在两个分类之间飘。 */
  design: [
    'design*', 'sketch', 'typography', 'font*', 'color*', 'colour*', 'palette',
    'icon*', 'logo', 'brand*', 'theme*', 'animat*', 'illustration', 'poster', 'banner',
    'visual', 'graphic', 'aesthetic*',
    '设计', '原型', '配色', '图标', '视觉', '字体', '品牌', '主题', '动效',
    '插画', '海报', '排版', '平面',
  ],
  /* 「UI」= 界面本身：布局 / 组件 / 交互 / 响应式 / 设计系统，
     以及各端各场景（PC / H5 / APP / 落地页 / 后台）的界面规则与风格。
     这是「做界面」的分类，和「设计」的「做视觉」互不重叠。 */
  ui: [
    'ui', 'ux', 'uiux', 'interface', 'component*', 'layout', 'responsive', 'breakpoint*',
    'css', 'tailwind', 'design-system', 'style-guide', 'design-token*',
    'dashboard', 'admin-panel', 'admin-dashboard', 'navigation', 'onboarding',
    'wireframe', 'mockup', 'prototype', 'figma', 'accessib*',
    'glassmorphism', 'neumorphism', 'bento', 'dark-mode', 'landing-page', 'h5',
    '界面', '交互', '组件', '布局', '响应式', '设计系统', '样式', '表单', '弹窗',
    '导航', '仪表板', '后台', '落地页', '移动端', '暗黑模式', '深色模式',
    '无障碍', '玻璃拟态', '新拟态', '栅格', '空状态', '加载态', '触屏', '热区',
  ],
  document: [
    'doc', 'docs', 'document*', 'markdown', 'pdf', 'docx', 'pptx', 'word',
    'manual', 'spec', 'specification', 'readme', 'wiki', 'confluence', 'notion',
    'obsidian', 'latex', 'ebook', 'report*', 'outline', 'glossary',
    '文档', '手册', '说明', '规范', '报告', '知识库', '笔记', '幻灯片', '格式转换', '阅读',
  ],
  data: [
    'data', 'dataset', 'sql', 'database', 'postgres*', 'mysql', 'sqlite', 'mongodb',
    'query', 'csv', 'excel', 'xlsx', 'spreadsheet', 'pandas', 'numpy', 'etl',
    /* dashboard 2026-10-12 移去 ui：现在它几乎总是指「仪表板界面」。
       数据这边留着 chart / graph / visuali / metric / statistic 已经够判断。 */
    'analytics', 'analysis', 'analyze', 'metric*', 'statistic*',
    'chart*', 'graph*', 'visuali*', 'scrape*', 'crawl*', 'aggregate',
    '数据', '数据库', '查询', '分析', '报表', '图表', '指标', '统计',
    '可视化', '清洗', '爬虫', '表格', '数据集', '埋点', '聚合', '提取',
  ],
  writing: [
    'writing', 'copywriting', 'blog', 'article', 'essay', 'story', 'novel',
    'marketing', 'seo', 'headline', 'caption', 'newsletter', 'email',
    'proofread', 'translate', 'translation', 'summarize', 'summary', 'abstract',
    'tone', 'persona', 'poem', 'lyrics', 'slogan',
    '写作', '文案', '文章', '博客', '公众号', '营销', '创意', '故事', '小说',
    '润色', '改写', '翻译', '摘要', '总结', '邮件', '标题', '内容创作', '剧本',
    '广告', '标语', '语气', '文风',
  ],
  devops: [
    'devops', 'deploy*', 'deployment', 'release', 'pipeline', 'docker',
    'kubernetes', 'k8s', 'container', 'nginx', 'apache', 'server', 'ssh',
    'cron', 'backup', 'monitor*', 'logging', 'observability', 'terraform',
    'ansible', 'aws', 'gcp', 'azure', 'cloud', 'dns', 'ssl', 'certificate',
    'firewall', 'security', 'vulnerability', 'systemd', 'linux', 'ubuntu',
    '运维', '部署', '发布', '流水线', '容器', '服务器', '监控', '日志', '备份',
    '定时任务', '环境变量', '云服务', '网络', '安全', '证书', '域名', '防火墙', '主机', '权限',
  ],
  productivity: [
    'productivity', 'automation', 'automate', 'workflow', 'todo', 'task',
    'calendar', 'meeting', 'reminder', 'remind*', 'template', 'checklist',
    'organize', 'shortcut', 'batch', 'schedule', 'planner', 'habit', 'focus', 'inbox',
    '效率', '自动化', '工作流', '任务', '待办', '日程', '日历', '会议', '提醒',
    '模板', '整理', '清单', '快捷', '批量', '习惯', '专注', '收集', '归档',
  ],
}

/**
 * 字段权重。
 * `name` 是作者自己起的名字，信号最强；`description` 是给人看的一句话，也很准。
 *
 * ⚠️ **刻意不用 readme**：readme 又长又杂，几乎任何分类都能在里面找到自己的词，
 *    把它算进去等于让「文档长度」决定分类结果。让它不参与，比给它一个小权重更干净。
 *
 * `files` 单条权重低（1）且有命中上限（3）—— 文件路径只配用来**打破平局**，
 * 不该靠一堆 `scripts/xxx.ps1` 就把技能判成「开发」。
 */
const FIELDS = [
  { key: 'name', weight: 8, cap: Infinity },
  { key: 'tags', weight: 5, cap: Infinity },
  { key: 'description', weight: 4, cap: Infinity },
  { key: 'files', weight: 1, cap: 3 },
]

/** 低于这个分就不下结论，留在「其他」。4 = 至少得有一条 description 级命中。 */
const MIN_SCORE = 4

/* ------------------------------------------------------------------ 内部 */

const CJK = /[\u3400-\u9fff\uf900-\ufaff]/

function escapeRe(s) {
  return s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')
}

/** 把关键词编译成判定函数。词边界用 `[^a-z0-9]` 显式写，不用 lookbehind（兼容性更稳） */
function compile(word) {
  const display = word.endsWith('*') ? word.slice(0, -1) : word
  if (CJK.test(display)) {
    return { word: display, test: (t) => t.includes(display) }
  }
  const body = escapeRe(display)
  const re = word.endsWith('*')
    ? new RegExp(`(^|[^a-z0-9])${body}[a-z0-9]*`)
    : new RegExp(`(^|[^a-z0-9])${body}([^a-z0-9]|$)`)
  return { word: display, test: (t) => re.test(t) }
}

/** 预编译一次，别在每次推断时重建正则 */
const COMPILED = Object.entries(RULES).map(([key, words], index) => ({
  key,
  index,
  words: words.map(compile),
}))

function norm(v) {
  return String(v ?? '')
    .toLowerCase()
    .replace(/\s+/g, ' ')
    .trim()
}

/* ------------------------------------------------------------------ 导出 */

/**
 * 把用户写的分类值归一化成标准 key。
 * 认不出来返回 `''`（注意：不是 `other` —— 「不认识」和「明确就是其他」是两回事，
 * 前者该走推断，后者该被尊重）。
 */
export function normalizeCategory(value) {
  const v = norm(value)
  if (!v) return ''
  if (CATEGORY_KEYS.includes(v)) return v
  return ALIASES[v] || ''
}

/**
 * 按内容推断分类。
 *
 * @param {{name?:string, description?:string, tags?:string[], files?:Array<string|{path:string}>}} input
 * @returns {{key: string|null, score: number, hits: string[]}}
 *          `key` 为 null 表示没把握（调用方应落回 `other`）
 */
export function inferCategory(input = {}) {
  const text = {
    name: norm(input.name),
    tags: norm((input.tags || []).join(' ')),
    description: norm(input.description),
    files: norm(
      (input.files || [])
        .map((f) => (typeof f === 'string' ? f : f?.path || ''))
        .join(' '),
    ),
  }

  let best = null

  for (const { key, index, words } of COMPILED) {
    let score = 0
    let bestWeight = 0
    const hits = []

    for (const field of FIELDS) {
      const hay = text[field.key]
      if (!hay) continue
      let used = 0
      for (const w of words) {
        if (used >= field.cap) break
        if (w.test(hay)) {
          score += field.weight
          used += 1
          bestWeight = Math.max(bestWeight, field.weight)
          if (!hits.includes(w.word)) hits.push(w.word)
        }
      }
    }

    if (score <= 0) continue
    // 排序：总分 → 最强命中所在字段的权重 → 固定顺序（保证结果可复现）
    if (
      !best ||
      score > best.score ||
      (score === best.score && bestWeight > best.bestWeight) ||
      (score === best.score && bestWeight === best.bestWeight && index < best.index)
    ) {
      best = { key, score, bestWeight, index, hits }
    }
  }

  if (!best || best.score < MIN_SCORE) {
    return { key: null, score: best?.score ?? 0, hits: best?.hits ?? [] }
  }
  return { key: best.key, score: best.score, hits: best.hits }
}

/**
 * 完整的分类判定：SKILL.md 声明 → 内容推断 → 兜底。
 *
 * @returns {{key:string, source:'declared'|'inferred'|'invalid'|'none',
 *            hits:string[], declared:string}}
 *   `source` 的含义：
 *     declared —— SKILL.md 写了，而且认出来了
 *     inferred —— 没写 / 写得不认识，按内容推断出来的
 *     invalid  —— 写了但认不出来，且推断也没把握
 *     none     —— 没写，推断也没把握
 */
export function resolveCategory(input = {}) {
  const raw = String(input.category ?? '').trim()
  const declared = normalizeCategory(raw)

  if (declared) {
    return { key: declared, source: 'declared', hits: [], declared: raw }
  }

  const inf = inferCategory(input)
  if (inf.key) {
    return { key: inf.key, source: 'inferred', hits: inf.hits, declared: raw }
  }

  return { key: 'other', source: raw ? 'invalid' : 'none', hits: [], declared: raw }
}

/** 分类规则的中文说明，给上传页直接用（文案和规则放一起，改了不会忘记同步） */
export const CATEGORY_RULE_HINT =
  `SKILL.md 的 frontmatter 里可以写 category（${INFER_KEYS.join(' / ')} / other，` +
  `中文或常见缩写也认）。没写的话，上传时会按名称、描述、标签自动推断，你可以在下面改。`
