/**
 * 技能数据门面
 * ---------------------------------------------------------------------------
 * 上层（页面）只认这一层，不关心后端是 Supabase 还是本地演示。
 * 每个方法都做同一件事：READY → 打 RPC；否则 → 走 localStore 并留痕。
 */
import { READY, rpc, SkillError, warnLocalMode } from './supabase'
import * as local from './localStore'
import { fromBase64, toBase64 } from './parseSkill'

export { READY, SkillError }

/** 列表。返回 { total, items } */
export async function listSkills({ q = '', category = 'all', sort = 'new', limit = 24, offset = 0 } = {}) {
  if (!READY) {
    warnLocalMode()
    return local.localList({ q, category, sort, limit, offset })
  }
  const d = await rpc('list_skills', {
    p_query: q,
    p_category: category,
    p_sort: sort,
    p_limit: limit,
    p_offset: offset,
  })
  return { total: Number(d.total) || 0, items: Array.isArray(d.items) ? d.items : [] }
}

/** 详情（含 readme 与文件表，**不含** zip 体积） */
export async function getSkill(slug) {
  if (!READY) {
    warnLocalMode()
    return local.localGet(slug)
  }
  const d = await rpc('get_skill', { p_slug: slug })
  return d.skill || null
}

/**
 * 发布。`skill` 是 parseSkill() 的产物（带 bundle: Uint8Array）。
 * 返回 { slug, code }，code ∈ created | exists。
 */
export async function publishSkill(skill) {
  if (!READY) {
    warnLocalMode()
    return local.localPublish(skill)
  }

  const payload = {
    name: skill.name,
    description: skill.description,
    category: skill.category || 'other',
    tags: skill.tags || [],
    version: skill.version,
    license: skill.license,
    author: skill.author,
    readme: skill.readme,
    files: skill.files,
    file_count: skill.fileCount,
    total_bytes: skill.totalBytes,
    hash: skill.hash,
    bundle_b64: toBase64(skill.bundle),
  }

  const d = await rpc('publish_skill', { p_payload: payload }, { timeout: 60000 })
  return { slug: d.slug, code: d.code }
}

/** 下载。返回 { filename, bytes, downloads }，并把下载量 +1 */
export async function downloadSkill(slug) {
  if (!READY) {
    warnLocalMode()
    return local.localDownload(slug)
  }
  const d = await rpc('download_skill', { p_slug: slug }, { timeout: 60000 })
  return { filename: d.filename || `${slug}.zip`, bytes: fromBase64(d.bundle_b64), downloads: d.downloads }
}

/** 记一次「安装」（点了复制安装命令 / 走了 agent 安装）。返回 { installs } */
export async function registerInstall(slug) {
  if (!READY) {
    warnLocalMode()
    return local.localInstall(slug)
  }
  const d = await rpc('register_install', { p_slug: slug })
  return { installs: d.installs }
}

/* ------------------------------------------------------------------ 工具 */

/** 触发浏览器下载 */
export function saveBlob(filename, bytes) {
  const blob = new Blob([bytes], { type: 'application/zip' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = filename
  document.body.appendChild(a)
  a.click()
  a.remove()
  // 交给浏览器读完再释放，立即 revoke 在部分浏览器上会导致下载失败
  setTimeout(() => URL.revokeObjectURL(url), 4000)
}

/** 复制到剪贴板（带降级：非 https / 老浏览器上 clipboard API 不可用） */
export async function copyText(text) {
  try {
    if (navigator.clipboard && window.isSecureContext) {
      await navigator.clipboard.writeText(text)
      return true
    }
  } catch {
    /* 落到降级分支 */
  }
  try {
    const ta = document.createElement('textarea')
    ta.value = text
    ta.style.position = 'fixed'
    ta.style.opacity = '0'
    document.body.appendChild(ta)
    ta.select()
    const ok = document.execCommand('copy')
    ta.remove()
    return ok
  } catch {
    return false
  }
}

/**
 * 错误文案映射。按 code 查表，不做字符串匹配 ——
 * 后者遇到后端改文案就静默失效（主站留言板踩过）。
 */
const ERROR_TEXT = {
  not_configured: '后端未配置，当前处于本地演示模式。',
  network: '网络连接失败，请检查网络后重试。',
  timeout: '请求超时，可能是技能包较大，请重试。',
  rate_limited: '上传太频繁了，请过一会儿再试。',
  too_large: '技能包超过大小上限。',
  too_many_files: '文件数超过上限。',
  missing_skill_md: '技能包里没有 SKILL.md。',
  invalid_payload: '提交的数据不完整或格式不对。',
  name_taken: '同名技能已存在，请改个名字。',
  not_found: '没有找到这个技能。',
  server: '服务器开小差了，请稍后重试。',
  http_400: '请求参数有误（可能是前后端版本不一致）。',
  http_404: '接口不存在（多半是数据库函数还没部署）。',
}

export function errorText(e) {
  if (e instanceof SkillError) return ERROR_TEXT[e.code] || `出错了（${e.code}）`
  const m = String(e?.message || '')
  if (m.includes('Failed to fetch') || m.includes('NetworkError')) return ERROR_TEXT.network
  return '出错了，请稍后重试。'
}
