/**
 * 技能包解析
 * ---------------------------------------------------------------------------
 * 这是本站的核心：把用户上传的东西（zip 压缩包 / 单个 SKILL.md / 粘贴的文本）
 * 解析成一份**结构化技能对象**，供预览、入库、下载复用。
 *
 * 设计原则：
 *   1. **纯函数 + 可独立单测**。不碰 DOM、不碰网络，只吃 Uint8Array / string。
 *      单测见 scripts/tests/parse-skill.test.mjs。
 *   2. **判据写死在代码里、能被断言钉住**。体积上限等常量由调用方从
 *      `data/site.js` 传进来（和 SQL 里的常量对齐），这里不重复定义。
 *   3. **绝不因为一行怪数据就整体失败** —— 解析尽量宽容，校验集中在一处
 *      （analyze），让用户看到「哪里不合格」，而不是一句「上传失败」。
 */
import { unzipSync, zipSync, strFromU8, strToU8 } from 'fflate'
/* 带扩展名：Vite 能解析无扩展名的相对导入，Node 不能。
   这个文件要被 scripts/tests 直接 import（不经打包），所以写成显式的 .js。 */
import { parseFrontmatter } from './frontmatter.js'

/** 压缩包里这些条目一律丢弃：macOS 元数据 / 系统垃圾文件 */
const JUNK = [
  /^__MACOSX\//,
  /(^|\/)\.DS_Store$/,
  /(^|\/)Thumbs\.db$/,
  /(^|\/)desktop\.ini$/i,
]

export const SKILL_FILE = 'SKILL.md'

/* ------------------------------------------------------------------ 基础工具 */

/** 二进制判定：出现 NUL 字节就当二进制（文本文件不会有 NUL） */
export function isBinary(u8) {
  const n = Math.min(u8.length, 4096)
  for (let i = 0; i < n; i++) if (u8[i] === 0) return true
  return false
}

/**
 * 路径排序比较器。
 *
 * 🔴 **必须用码位比较，不能用 String.prototype.localeCompare。**
 * localeCompare 受运行环境的 locale 影响：同一份文件表，在 zh-CN 的浏览器里
 * 可能排成 [scripts/a.py, SKILL.md]，在 Node 的默认 locale 下又是另一种。
 * 而文件顺序决定了 packZip 的字节序 → 决定了内容 hash。
 * 一旦两边不一致，「同一份技能」会算出两个 hash，去重直接失效。
 * 码位比较在任何环境下结果都一样。
 */
export function comparePath(a, b) {
  return a < b ? -1 : a > b ? 1 : 0
}

/**
 * 规范化 zip 内部路径。
 * 返回 null 表示「这条不可信，应当丢弃」—— 绝对路径 / 上跳目录（zip slip）。
 */
export function normalizePath(raw) {
  if (typeof raw !== 'string') return null
  let p = raw.replace(/\\/g, '/').trim()
  p = p.replace(/^\.\//, '')
  if (!p) return null
  if (p.startsWith('/') || /^[A-Za-z]:/.test(p)) return null
  const parts = []
  for (const seg of p.split('/')) {
    if (seg === '' || seg === '.') continue
    if (seg === '..') return null
    parts.push(seg)
  }
  if (!parts.length) return null
  return parts.join('/')
}

export function slugify(input) {
  const s = String(input ?? '')
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9\u4e00-\u9fa5]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .slice(0, 64)
  return s || 'skill'
}

/** SHA-256 → 十六进制。浏览器与 Node 18+ 都自带 crypto.subtle。 */
export async function sha256Hex(u8) {
  const buf = await crypto.subtle.digest('SHA-256', u8)
  return [...new Uint8Array(buf)].map((b) => b.toString(16).padStart(2, '0')).join('')
}

export function toBase64(u8) {
  let s = ''
  const CHUNK = 0x8000 // 一次 32KB，避免 apply 参数过多爆栈
  for (let i = 0; i < u8.length; i += CHUNK) {
    s += String.fromCharCode.apply(null, u8.subarray(i, i + CHUNK))
  }
  return btoa(s)
}

export function fromBase64(b64) {
  const bin = atob(b64)
  const u8 = new Uint8Array(bin.length)
  for (let i = 0; i < bin.length; i++) u8[i] = bin.charCodeAt(i)
  return u8
}

export function formatBytes(n) {
  const v = Number(n) || 0
  if (v < 1024) return `${v} B`
  if (v < 1024 * 1024) return `${(v / 1024).toFixed(1)} KB`
  return `${(v / 1024 / 1024).toFixed(2)} MB`
}

/**
 * 检测压缩包的「公共顶层目录」。
 * 用户压缩技能时通常会把整个文件夹打进去（`my-skill/SKILL.md`），
 * 我们要把这层剥掉，否则装到 skills 目录下会多套一层。
 *
 * 判据：**所有**条目都在同一个顶层目录下才算（只有一个顶层条目时不算 ——
 * 那可能就是一个名叫 `scripts` 的目录，剥掉反而丢了结构）。
 */
export function pickRoot(paths) {
  if (paths.length < 2) return ''
  const first = paths[0].split('/')[0]
  if (!first) return ''
  const allInside = paths.every((p) => p.startsWith(`${first}/`))
  return allInside ? first : ''
}

/* ------------------------------------------------------------- zip → 文件表 */

/**
 * 解压并规范化一个 zip。
 * 返回 { files, warnings }，files 已按 path 排序（保证哈希稳定）。
 */
export function readZip(u8) {
  const warnings = []
  let raw
  try {
    raw = unzipSync(u8)
  } catch (e) {
    return { files: [], warnings: [`不是有效的 zip 压缩包（${e?.message || '解析失败'}）`] }
  }

  // 1. 路径规范化 + 丢垃圾 + 丢目录条目
  const entries = []
  for (const [rawPath, bytes] of Object.entries(raw)) {
    if (rawPath.endsWith('/')) continue // 目录占位条目
    if (JUNK.some((re) => re.test(rawPath))) continue
    const p = normalizePath(rawPath)
    if (!p) {
      warnings.push(`已跳过不安全路径：${rawPath}`)
      continue
    }
    entries.push({ path: p, bytes })
  }

  // 2. 剥掉公共顶层目录
  const root = pickRoot(entries.map((e) => e.path))
  const stripped = root ? entries.map((e) => ({ ...e, path: e.path.slice(root.length + 1) })) : entries
  if (root) warnings.push(`已自动去除压缩包的顶层目录「${root}/」`)

  // 3. 去重（同名条目以最后一条为准，和 unzip 的覆盖语义一致）
  const byPath = new Map()
  for (const e of stripped) {
    if (byPath.has(e.path)) warnings.push(`压缩包里有重名条目，已保留后一条：${e.path}`)
    byPath.set(e.path, e)
  }

  const files = [...byPath.values()]
    .sort((a, b) => comparePath(a.path, b.path))
    .map((e) => ({
      path: e.path,
      size: e.bytes.length,
      kind: isBinary(e.bytes) ? 'binary' : 'text',
      bytes: e.bytes,
    }))

  return { files, warnings }
}

/**
 * 打包时写进 zip 条目的**固定时间戳**。
 *
 * 🔴 这个常量不是可有可无的装饰，去掉它去重就废了。
 *
 * fflate 的 zipSync 在条目没给 `mtime` 时用的是 `Date.now()`（见 fflate
 * `esm/browser.js` 里 `new Date(f.mtime == null ? Date.now() : f.mtime)`），
 * 于是 **同样的内容每次打包出来的字节都不一样** —— zip 头 offset 10/12 是
 * DOS 的修改时间/日期字段，精度 2 秒，每两秒就变一次。
 * 而本站的「同内容去重」判据就是 `skills.hash` 相等（见 001-skills.sql 的
 * `select slug into v_existing from public.skills where hash = v_hash`）。
 * 两者一叠加，后果是：**同一份技能重复上传永远不会被判为「已存在」**，
 * 每次都新建一条 `xxx-2`。
 *
 * 线上实测过：13 条技能原样再传一遍，总数从 13 变成 17。
 *
 * 为什么是 `new Date(1980, 0, 1)` 而不是 `new Date(0)` 或 ISO 字符串：
 *   - ZIP 的 DOS 时间字段**最早只能表示 1980 年**，fflate 遇到 `y < 0` 直接
 *     `err(10)` 抛错 —— 1970 年会让上传整个挂掉；
 *   - 用 ISO 字符串（`'1980-01-01T00:00:00Z'`）会被解析成 UTC 瞬时点，
 *     在 UTC-8 之类时区本地读出来是 1979-12-31，同样触发上面的抛错。
 *     多参数构造函数按**本地时间**解释，任何时区读出来都是 1980-01-01，
 *     写进 zip 的字节因而与环境无关。
 *
 * ⚠️ 它必须是个**常量**。「今天零点」之类的写法看着更自然，但跨天就会变，
 *    等于把 bug 从「每 2 秒」缩小成「每天」，问题依旧。
 */
const ZIP_MTIME = new Date(1980, 0, 1)

/**
 * 把文件表打回 zip。
 *
 * 条目顺序按 path 码位排序，时间戳固定成 ZIP_MTIME ——
 * **同样内容必须永远得到同样的字节**，这是内容哈希与去重的前提。
 */
export function packZip(files) {
  const obj = {}
  for (const f of [...files].sort((a, b) => comparePath(a.path, b.path))) {
    obj[f.path] = [f.bytes, { mtime: ZIP_MTIME }]
  }
  return zipSync(obj, { level: 6 })
}

/* ------------------------------------------------------- 文件表 → 结构化技能 */

/**
 * 从文件表里提取技能元信息。
 * 找不到 SKILL.md 时 `readme` 为空、meta 全部兜底 —— 是否合格交给 analyze 判。
 */
export function extractMeta(files) {
  const md = files.find((f) => f.path.toLowerCase() === SKILL_FILE.toLowerCase())
  if (!md) return { readme: '', meta: {} }

  const readme = strFromU8(md.bytes)
  const { data } = parseFrontmatter(readme)

  const tags = Array.isArray(data.tags)
    ? data.tags
    : typeof data.tags === 'string' && data.tags
      ? data.tags.split(/[,，]/).map((s) => s.trim()).filter(Boolean)
      : []

  return {
    readme,
    meta: {
      name: String(data.name || '').trim(),
      description: String(data.description || '').trim(),
      version: String(data.version || '').trim(),
      license: String(data.license || '').trim(),
      author: String(data.author || '').trim(),
      category: String(data.category || '').trim(),
      tags,
    },
  }
}

/**
 * 校验解析结果。
 *
 * ⚠️ 这里的每条规则都要在 SQL 里有一份对应（服务端才是真正的闸门）。
 * 两边不一致会出现「前端让传、后端拒绝」。改这里时同步改 001-skills.sql。
 */
export function analyze(files, limits) {
  const errors = []
  const md = files.find((f) => f.path.toLowerCase() === SKILL_FILE.toLowerCase())

  if (!md) {
    errors.push(`压缩包里没有找到 ${SKILL_FILE}（技能根目录必须有一个 SKILL.md）`)
  } else if (md.size > limits.maxSkillMdBytes) {
    errors.push(`${SKILL_FILE} 超过 ${formatBytes(limits.maxSkillMdBytes)} 上限`)
  }

  if (!files.length) errors.push('压缩包里没有任何文件')
  if (files.length > limits.maxFiles) {
    errors.push(`文件数 ${files.length} 超过上限 ${limits.maxFiles}`)
  }

  const totalBytes = files.reduce((a, f) => a + f.size, 0)
  if (totalBytes > limits.maxTotalBytes) {
    errors.push(`解压后总大小 ${formatBytes(totalBytes)} 超过上限 ${formatBytes(limits.maxTotalBytes)}`)
  }

  return { ok: errors.length === 0, errors, totalBytes, fileCount: files.length }
}

/**
 * 主入口：把「一份上传」解析成完整技能对象。
 *
 * @param {{name:string, bytes:Uint8Array}} input  name 仅用于兜底推断（单文件上传时）
 * @param {object} limits  data/site.js 的 limits
 * @returns {Promise<{ok:boolean, errors:string[], warnings:string[], skill?:object}>}
 */
export async function parseSkill(input, limits) {
  const name = String(input?.name || '')
  const bytes = input?.bytes
  if (!bytes || !bytes.length) {
    return { ok: false, errors: ['文件是空的'], warnings: [] }
  }

  const isMarkdown = /\.(md|markdown|txt)$/i.test(name)
  let files
  let warnings = []

  if (isMarkdown) {
    // 单个 Markdown：不管用户传的文件叫什么名字，都当作技能根目录下的 SKILL.md
    // （技能包的结构由 SKILL.md 定义，文件名本身不参与判定）
    files = [{ path: SKILL_FILE, size: bytes.length, kind: 'text', bytes }]
  } else {
    const r = readZip(bytes)
    files = r.files
    warnings = r.warnings
  }

  const { readme, meta } = extractMeta(files)
  const check = analyze(files, limits)

  // 名称兜底：frontmatter > 压缩包名/文件名（去掉扩展名）
  const fallbackName = name.replace(/\.(zip|md|markdown|txt)$/i, '') || 'skill'
  const displayName = (meta.name || fallbackName).slice(0, limits.maxNameLength)

  const bundle = packZip(files)
  const hash = await sha256Hex(bundle)

  const skill = {
    slug: slugify(meta.name || fallbackName),
    name: displayName,
    description: (meta.description || '').slice(0, limits.maxDescLength),
    version: meta.version || '1.0.0',
    license: meta.license || '',
    author: meta.author || '',
    category: meta.category || '',
    /* ⚠️ 不能写成 `meta.tags.slice(...)` —— 没有 SKILL.md 时 extractMeta 返回的是
       空对象，meta.tags 是 undefined，直接 .slice 会抛 TypeError，
       结果是「上传一个没有 SKILL.md 的包」会让整个解析崩掉，
       而不是给出一句「缺少 SKILL.md」。测试里有一条专门钉这个。 */
    tags: Array.isArray(meta.tags) ? meta.tags.slice(0, 12) : [],
    readme,
    files: files.map((f) => ({ path: f.path, size: f.size, kind: f.kind })),
    fileCount: files.length,
    totalBytes: check.totalBytes,
    hash,
    bundle,
  }

  return { ok: check.ok, errors: check.errors, warnings, skill }
}

/* ---------------------------------------------------------------- 文件树 */

/**
 * 扁平文件表 → 嵌套树（给「文件结构」那块渲染用）。
 * 目录节点带 children，文件节点带 size/kind。
 */
export function buildTree(files) {
  const root = { name: '', path: '', type: 'dir', children: [], size: 0 }
  const dirs = new Map([['', root]])

  for (const f of [...files].sort((a, b) => comparePath(a.path, b.path))) {
    const parts = f.path.split('/')
    let cur = ''
    for (let i = 0; i < parts.length - 1; i++) {
      const parent = cur
      cur = cur ? `${cur}/${parts[i]}` : parts[i]
      if (!dirs.has(cur)) {
        const node = { name: parts[i], path: cur, type: 'dir', children: [], size: 0 }
        dirs.set(cur, node)
        dirs.get(parent).children.push(node)
      }
    }
    dirs.get(cur).children.push({
      name: parts[parts.length - 1],
      path: f.path,
      type: 'file',
      size: f.size,
      kind: f.kind,
      children: [],
    })
  }

  // 自底向上累计目录大小
  const sum = (n) => {
    if (n.type === 'file') return n.size
    n.size = n.children.reduce((a, c) => a + sum(c), 0)
    return n.size
  }
  sum(root)
  return root
}

/** 文本文件扩展名白名单，用于详情页判断「能不能预览」 */
export function isPreviewable(path) {
  return /\.(md|markdown|txt|json|ya?ml|toml|ini|cfg|conf|js|mjs|cjs|ts|tsx|jsx|vue|css|scss|less|html?|py|sh|bash|zsh|rb|go|rs|java|kt|c|h|cpp|hpp|cs|php|sql|swift|dart|lua|r|pl|xml|svg|csv|tsv|env|gitignore|dockerfile|makefile)$/i.test(
    path,
  )
}

/** 从文件表里取某个文本文件的内容（详情页预览用） */
export function readTextFile(files, path) {
  const f = files.find((x) => x.path === path)
  if (!f) return null
  if (f.kind === 'binary') return null
  return strFromU8(f.bytes)
}

/** 供单测/脚本使用的重导出，避免测试去 import fflate */
export { strToU8, strFromU8 }
