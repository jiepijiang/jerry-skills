/**
 * 本地演示数据层（未配置 Supabase 时启用）
 * ---------------------------------------------------------------------------
 * 目标：**让整站功能在没有后端时也完整可走**，方便本地开发和预览。
 *
 * 但绝不假装它是真的：
 *   · supabase.js 的 warnLocalMode() 会在控制台明确留痕；
 *   · 界面顶部有一条「本地演示模式」横幅（见 LocalModeBanner）。
 * 「看着像发出去了、其实只存在本机」是这里最需要避免的失败模式。
 *
 * 数据落点：
 *   · 种子技能（seedSkills.js）每次启动重新解析，不持久化；
 *   · 用户上传的技能存 localStorage（含 zip 的 base64），刷新还在。
 */
import { zipSync, strToU8 } from 'fflate'
import { parseSkill, toBase64, fromBase64 } from './parseSkill'
import { SkillError } from './supabase'
import { SEED_SKILLS } from './seedSkills'
import { limits } from '@/data/site'

const LS_KEY = 'jerry-skills:local:v1'
/** 本地模式里被「删掉」的**种子**技能。用户上传的那些直接从 LS_KEY 里消失就行，
 *  种子是每次启动重新解析出来的，不记一笔的话刷新就又冒出来了 —— 「删了又回来」
 *  是最容易让人以为功能坏了的一种表现。 */
const LS_DELETED = 'jerry-skills:local:deleted:v1'

let records = null // Map<slug, record>
let userSlugs = null // Set<slug>：来自 localStorage 或本次会话上传的（要持久化）
let deletedSeeds = null // Set<slug>
let building = null
let warnedAuth = false

function readLS() {
  try {
    const raw = localStorage.getItem(LS_KEY)
    const arr = raw ? JSON.parse(raw) : []
    return Array.isArray(arr) ? arr.filter((r) => r && r.slug) : []
  } catch {
    return []
  }
}

function writeLS() {
  const arr = [...userSlugs].map((s) => records.get(s)).filter(Boolean)
  try {
    localStorage.setItem(LS_KEY, JSON.stringify(arr))
  } catch (e) {
    // 配额爆了（base64 的 zip 挺占地方）—— 说清楚，别静默丢
    console.warn('[jerry-skills] 本地存储写入失败，上传的技能刷新后会消失：', e?.message)
  }
}

function readDeleted() {
  try {
    const raw = localStorage.getItem(LS_DELETED)
    const arr = raw ? JSON.parse(raw) : []
    return new Set(Array.isArray(arr) ? arr.filter((s) => typeof s === 'string') : [])
  } catch {
    return new Set()
  }
}

function writeDeleted() {
  try {
    localStorage.setItem(LS_DELETED, JSON.stringify([...deletedSeeds]))
  } catch {
    /* 忽略 */
  }
}

/** 把「原始文件表」打成 zip，再走一遍真实解析 —— 演示数据与线上同构 */
async function parseSeed(filesObj) {
  const entries = {}
  for (const [path, text] of Object.entries(filesObj)) entries[path] = strToU8(text)
  return parseSkill({ name: 'seed.zip', bytes: zipSync(entries, { level: 6 }) }, limits)
}

export async function ensureLocal() {
  if (records) return records
  if (building) return building

  building = (async () => {
    const map = new Map()
    const user = new Set()
    const now = Date.now()
    deletedSeeds = readDeleted()

    let i = 0
    for (const seed of SEED_SKILLS) {
      const r = await parseSeed(seed.files)
      if (!r.ok || !r.skill) continue
      const s = r.skill
      // ⚠️ 先 i++ 再判断要不要跳过：否则删掉一条之后，后面几条的
      //    初始下载量会整体往前挪一格，「最多下载」的排序看着就变了
      const idx = i++
      if (deletedSeeds.has(s.slug)) continue
      map.set(s.slug, {
        slug: s.slug,
        name: s.name,
        description: s.description,
        category: s.category || 'other',
        tags: s.tags,
        version: s.version,
        license: s.license,
        author: s.author || 'jerry',
        readme: s.readme,
        files: s.files,
        file_count: s.fileCount,
        total_bytes: s.totalBytes,
        hash: s.hash,
        bundle_b64: toBase64(s.bundle),
        // 种子给一些初始数字，「最多下载 / 最多安装」排序才有东西可排
        downloads: 128 - idx * 19,
        installs: 41 - idx * 7,
        created_at: new Date(now - (idx + 1) * 3 * 86400000).toISOString(),
      })
    }

    for (const rec of readLS()) {
      map.set(rec.slug, rec)
      user.add(rec.slug)
    }

    records = map
    userSlugs = user
    return records
  })()

  return building
}

function publicView(rec, withBody = false) {
  const base = {
    slug: rec.slug,
    name: rec.name,
    description: rec.description,
    category: rec.category,
    tags: rec.tags,
    version: rec.version,
    license: rec.license,
    author: rec.author,
    file_count: rec.file_count,
    total_bytes: rec.total_bytes,
    downloads: rec.downloads,
    installs: rec.installs,
    created_at: rec.created_at,
  }
  if (withBody) {
    base.readme = rec.readme
    base.files = rec.files
    base.hash = rec.hash
  }
  return base
}

export async function localList({ q = '', category = 'all', sort = 'new', limit = 24, offset = 0 } = {}) {
  const map = await ensureLocal()
  let items = [...map.values()]

  const kw = q.trim().toLowerCase()
  if (kw) {
    items = items.filter((r) =>
      [r.name, r.description, r.author, (r.tags || []).join(' ')].join(' ').toLowerCase().includes(kw),
    )
  }
  if (category && category !== 'all') {
    items = items.filter((r) => r.category === category)
  }

  const cmp = {
    new: (a, b) => String(b.created_at).localeCompare(String(a.created_at)),
    downloads: (a, b) => b.downloads - a.downloads,
    installs: (a, b) => b.installs - a.installs,
  }[sort]
  items.sort(cmp || ((a, b) => String(b.created_at).localeCompare(String(a.created_at))))

  return {
    total: items.length,
    items: items.slice(offset, offset + limit).map((r) => publicView(r)),
  }
}

export async function localGet(slug) {
  const map = await ensureLocal()
  const rec = map.get(slug)
  return rec ? publicView(rec, true) : null
}

export async function localPublish(skill) {
  const map = await ensureLocal()

  // 本地模式也要做同名去重 —— 和线上 slug 唯一约束的语义对齐，
  // 否则「本地能传、线上报冲突」这种差异会让人误以为后端有问题。
  let slug = skill.slug
  let n = 2
  while (map.has(slug)) slug = `${skill.slug}-${n++}`

  const rec = {
    slug,
    name: skill.name,
    description: skill.description,
    category: skill.category || 'other',
    tags: skill.tags || [],
    version: skill.version,
    license: skill.license,
    author: skill.author || 'anonymous',
    readme: skill.readme,
    files: skill.files,
    file_count: skill.fileCount,
    total_bytes: skill.totalBytes,
    hash: skill.hash,
    bundle_b64: toBase64(skill.bundle),
    downloads: 0,
    installs: 0,
    created_at: new Date().toISOString(),
  }

  map.set(slug, rec)
  userSlugs.add(slug)
  writeLS()
  return { slug, code: 'created' }
}

export async function localDownload(slug) {
  const map = await ensureLocal()
  const rec = map.get(slug)
  if (!rec) return null
  rec.downloads += 1
  if (userSlugs.has(slug)) writeLS()
  return { filename: `${rec.slug}.zip`, bytes: fromBase64(rec.bundle_b64), downloads: rec.downloads }
}

export async function localInstall(slug) {
  const map = await ensureLocal()
  const rec = map.get(slug)
  if (!rec) return null
  rec.installs += 1
  if (userSlugs.has(slug)) writeLS()
  return { installs: rec.installs }
}

/* -------------------------------------------------------------- 站主专属 */

/**
 * 本地演示模式下的口令校验。
 *
 * 🔴 这里**没有真正的鉴权** —— 任何非空口令都算通过。必须吵一声，
 *    否则「本地随便输就过了」会被误读成「线上也这么松」，
 *    或者更糟：以为已经验证过鉴权逻辑了。
 *    真正的口令校验只存在于 Supabase 那份 SQL 里（离线验不了它，
 *    所以另有一份 PGlite 测试专门验，见 supabase/verify-admin-delete.mjs）。
 */
function warnLocalAuth() {
  if (warnedAuth) return
  warnedAuth = true
  console.warn(
    '[jerry-skills] 本地演示模式**没有真正的鉴权**：任何非空口令都会通过，' +
      '删除也只影响这台浏览器的 localStorage，不影响线上数据。',
  )
}

export async function localAdminCheck(token) {
  warnLocalAuth()
  return String(token || '').length > 0
}

export async function localAdminDelete(slug, token) {
  warnLocalAuth()
  // 和线上对齐：口令错要抛 unauthorized，调用方才有统一的错误分支
  if (!String(token || '').length) throw new SkillError('unauthorized')

  const map = await ensureLocal()
  const rec = map.get(slug)
  if (!rec) throw new SkillError('not_found')

  map.delete(slug)
  if (userSlugs.has(slug)) {
    userSlugs.delete(slug)
    writeLS()
  } else {
    deletedSeeds.add(slug)
    writeDeleted()
  }
  return { slug, name: rec.name }
}
