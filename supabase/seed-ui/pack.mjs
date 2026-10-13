/**
 * 技能包构建：把「一个目录」变成站上能直接入库的形态。
 * ---------------------------------------------------------------------------
 * ⚠️ 打包算法必须和站上 src/lib/parseSkill.js 的 packZip **逐字节一致**：
 *    · 条目按 path 的**码位**排序（不是 localeCompare）
 *    · mtime 固定成 1980-01-01（fflate 默认用 Date.now()，同内容每次字节都不同）
 *    · level 6
 *    三者任一不同，hash 就和站上算出来的对不上 —— 将来有人在页面重新上传
 *    同一个包，站上会认不出「已存在」，于是插出 xxx-2、xxx-3。
 */
import { zipSync } from 'fflate'
import { createHash } from 'node:crypto'
import { readdirSync, readFileSync, statSync } from 'node:fs'
import { join, relative, sep } from 'node:path'

const ZIP_MTIME = new Date(1980, 0, 1)
const cmp = (a, b) => (a < b ? -1 : a > b ? 1 : 0)

/** 这些一律不进包：系统垃圾 + 对分发无意义的仓库文件 */
const SKIP = [
  /^\.DS_Store$/i,
  /^\.gitignore$/i,
  /^\.gitattributes$/i,
  /^__MACOSX/,
  /^Thumbs\.db$/i,
  /^desktop\.ini$/i,
  /^\.markdown-html$/, // design-system 的运行时配置目录
]

export function walk(dir) {
  const out = []
  for (const name of readdirSync(dir)) {
    const full = join(dir, name)
    const st = statSync(full)
    if (st.isDirectory()) out.push(...walk(full))
    else out.push(full)
  }
  return out
}

/** 有 NUL 字节就当二进制 —— 和站上 isBinary 同一判据 */
function isBinary(u8) {
  const n = Math.min(u8.length, 4096)
  for (let i = 0; i < n; i++) if (u8[i] === 0) return true
  return false
}

/**
 * @param {Record<string, Uint8Array>} files  path → 内容（path 用 / 分隔，无前导斜杠）
 * @returns {{bundle: Uint8Array, hash: string, list: Array, totalBytes: number}}
 */
export function pack(files) {
  const paths = Object.keys(files).sort(cmp)
  const obj = {}
  const list = []
  let totalBytes = 0
  for (const p of paths) {
    const u8 = files[p]
    obj[p] = [u8, { mtime: ZIP_MTIME }]
    list.push({ path: p, size: u8.length, kind: isBinary(u8) ? 'binary' : 'text' })
    totalBytes += u8.length
  }
  const bundle = zipSync(obj, { level: 6 })
  const hash = createHash('sha256').update(bundle).digest('hex')
  return { bundle, hash, list, totalBytes }
}

/** 目录 → { path: Uint8Array }（已过滤垃圾文件） */
export function readDir(dir) {
  const out = {}
  for (const full of walk(dir)) {
    const rel = relative(dir, full).split(sep).join('/')
    if (SKIP.some((re) => re.test(rel) || re.test(rel.split('/').pop()))) continue
    out[rel] = new Uint8Array(readFileSync(full))
  }
  return out
}

/** 替换 SKILL.md 的 frontmatter（第一个 --- 到第二个 --- 之间） */
export function replaceFrontmatter(md, frontmatter) {
  const m = /^---\r?\n[\s\S]*?\r?\n---\r?\n?/.exec(md)
  if (!m) throw new Error('SKILL.md 没有 frontmatter')
  return `---\n${frontmatter}---\n\n` + md.slice(m[0].length).replace(/^\s*\n/, '')
}

/** 生成站上格式的 frontmatter */
export function buildFrontmatter({ slug, description, version, license, author, category = 'ui', tags }) {
  const q = (s) => `"${String(s).replace(/"/g, '\\"')}"`
  const tagList = tags.map((t) => q(t)).join(', ')
  return [
    `name: ${q(slug)}`,
    `description: ${q(description)}`,
    `version: ${q(version)}`,
    `license: ${q(license)}`,
    `author: ${q(author)}`,
    `category: ${category}`,
    `tags: [${tagList}]`,
    '',
  ].join('\n')
}

/** 生成 ATTRIBUTION.md —— 站上既有技能包都有这一份 */
export function buildAttribution({ srcRepo, srcPath, license, copyright, extraNote }) {
  return `# 来源与署名

本技能**不是本站原创**，转载自开源仓库，遵循其原始许可证。

| 项 | 内容 |
| --- | --- |
| 原始仓库 | ${srcRepo} |
| 原始路径 | \`${srcPath}\` |
| 许可证 | ${license} |
| 版权 | ${copyright} |

## 本站做了什么改动

1. **SKILL.md 的 frontmatter**：补了 \`category\` / \`version\` / \`license\` / \`author\` / \`tags\`，
   并把 \`description\` 改写成中文（本站是中文站，列表卡片上显示的就是这个字段）。
2. **新增本文件**（\`ATTRIBUTION.md\`）—— 许可证要求版权与许可声明随副本走。
3. **新增 \`LICENSE\`**（取自原仓库根目录）。
4. **删除了** \`.gitignore\` 等对分发出去的技能包没有意义的文件。
${extraNote ? `5. ${extraNote}\n` : ''}
**SKILL.md 的正文（frontmatter 之后的部分）以及所有附属文件均未改动。**

## 许可证全文

见同目录下的 \`LICENSE\`。
`
}
