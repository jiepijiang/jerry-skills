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
/**
 * 本地模式里我打过的分：{ [slug]: 1..5 }。
 *
 * 线上是「一人一票、按 IP 区分」，本地没有 IP 这回事 ——
 * 于是「一个人」就退化成「这一个浏览器」，也就是这份 map 里的一条记录。
 * 语义上是对齐的（重复打分是覆盖），所以本地怎么表现，线上就怎么表现。
 */
const LS_RATINGS = 'jerry-skills:local:ratings:v1'

let records = null // Map<slug, record>
let userSlugs = null // Set<slug>：来自 localStorage 或本次会话上传的（要持久化）
let deletedSeeds = null // Set<slug>
let myRatings = null // Map<slug, number>：本地这台浏览器打过的分
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

function readRatings() {
  try {
    const raw = localStorage.getItem(LS_RATINGS)
    const obj = raw ? JSON.parse(raw) : {}
    const out = new Map()
    for (const [slug, score] of Object.entries(obj || {})) {
      const n = Number(score)
      // 夹一下：localStorage 是用户能直接改的，脏数据不该一路灌进界面
      if (typeof slug === 'string' && slug && Number.isInteger(n) && n >= 1 && n <= 5) out.set(slug, n)
    }
    return out
  } catch {
    return new Map()
  }
}

function writeRatings() {
  try {
    localStorage.setItem(LS_RATINGS, JSON.stringify(Object.fromEntries(myRatings)))
  } catch {
    /* 忽略 */
  }
}

/**
 * 一个技能当前的评分聚合。
 *
 * 本地模式也要有「别人也评过」的样子，否则「评分最高」排序在本地永远排不出东西
 * （一台浏览器最多只能贡献一票）。所以种子技能带一份**假的社区票底**
 * （seed_rating_count / seed_rating_sum），我自己的票再叠加在上面 ——
 * 和线上「我的票是 N 票之一」的语义一致。
 *
 * 用户自己上传的技能没有票底（0 票），这也对：刚传上去就是没人评过。
 */
function ratingOf(rec) {
  const mine = myRatings.get(rec.slug) || 0
  const cnt = (rec.seed_rating_count || 0) + (mine ? 1 : 0)
  const sum = (rec.seed_rating_sum || 0) + mine
  return { cnt, avg: cnt > 0 ? sum / cnt : null }
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
    myRatings = readRatings()

    let i = 0
    for (const seed of SEED_SKILLS) {
      const r = await parseSeed(seed.files)
      if (!r.ok || !r.skill) continue
      const s = r.skill
      // ⚠️ 先 i++ 再判断要不要跳过：否则删掉一条之后，后面几条的
      //    初始下载量会整体往前挪一格，「最多下载」的排序看着就变了
      const idx = i++
      if (deletedSeeds.has(s.slug)) continue
      // 评分票底：人数 6~22、平均分 4.1~4.7。理由同下面的 downloads ——
      // 没有票底的话「评分最高」在本地永远排不出东西（一台浏览器只有一票）。
      const seedCnt = 6 + ((idx * 5) % 17)
      const seedAvg = 4.7 - (idx % 4) * 0.2
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
        seed_rating_count: seedCnt,
        seed_rating_sum: Math.round(seedAvg * seedCnt),
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
  const { cnt, avg } = ratingOf(rec)
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
    rating_count: cnt,
    // 保留两位，和服务端的 round(avg(score), 2) 对齐 —— 两条链路的小数位不一样的话，
    // 「本地 4.3333333、线上 4.33」会让人以为哪边算错了
    rating_avg: avg === null ? null : Math.round(avg * 100) / 100,
    created_at: rec.created_at,
  }
  if (withBody) {
    base.readme = rec.readme
    base.files = rec.files
    base.hash = rec.hash
    // 和线上 get_skill 一致：只有详情接口回传「我自己打的分」
    base.my_score = myRatings?.get(rec.slug) || null
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
    // 和 SQL 的 `r.avg_score desc nulls last, r.cnt desc` 对齐：
    // 未评分的排最后，同分时人多的在前。
    //
    // ⚠️ 那三行显式判 null 对**当前**的排序结果是冗余的 —— 实测过：删掉它们，
    //    排序断言照样绿。原因是 JS 里 `null` 参与减法被当成 0，而这是个降序比较，
    //    未评分的（0）自然落到最后。之所以还是写出来：
    //      ① 意图要能一眼看懂，而不是靠一个隐式转换的巧合；
    //      ② 真正防的是 `undefined` —— 万一哪天 ratingOf 漏了某个分支返回 undefined，
    //         `y.avg - x.avg` 会得到 **NaN**，而 sort 的比较器返回 NaN 时顺序是
    //         **实现定义**的（不报错、只是静默乱掉，最难查）。
    rating: (a, b) => {
      const x = ratingOf(a)
      const y = ratingOf(b)
      if (x.avg === null && y.avg === null) return 0
      if (x.avg === null) return 1
      if (y.avg === null) return -1
      return y.avg - x.avg || y.cnt - x.cnt
    },
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

/**
 * 本地打分 / 改分。
 *
 * 和线上对齐的两点：
 *   · **一人一票**：同一个 slug 只留一条记录，再打是覆盖（线上靠主键 (slug, ip)）。
 *   · **不存在的技能要抛 not_found**：线上会返回 `{ok:false, code:'not_found'}`，
 *     而 `rpc()` 会把它转成 SkillError —— 这里必须抛同一种错，
 *     否则「本地静默成功、线上报错」这种差异会被当成线上有 bug。
 */
export async function localRate(slug, score) {
  const map = await ensureLocal()
  const rec = map.get(slug)
  if (!rec) throw new SkillError('not_found')

  const n = Number(score)
  if (!Number.isInteger(n) || n < 1 || n > 5) throw new SkillError('invalid_payload')

  myRatings.set(slug, n)
  writeRatings()

  const { cnt, avg } = ratingOf(rec)
  return {
    my_score: n,
    rating_count: cnt,
    rating_avg: avg === null ? null : Math.round(avg * 100) / 100,
  }
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
  // 对齐线上的外键级联：技能没了，它身上的评分也该一起走 ——
  // 留着的话，将来同名技能再传上来会凭空继承一堆别人的分
  myRatings.delete(slug)
  writeRatings()
  if (userSlugs.has(slug)) {
    userSlugs.delete(slug)
    writeLS()
  } else {
    deletedSeeds.add(slug)
    writeDeleted()
  }
  return { slug, name: rec.name }
}
