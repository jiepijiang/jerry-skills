/**
 * 构建期核对 Supabase 配置
 * ---------------------------------------------------------------------------
 * 为什么要有这个脚本：未配置时站点会**静默退回本地演示模式** ——
 * 页面照样能开、能点，只是上传不落库、下载量不累计。这种「看起来正常」的故障
 * 最难发现，所以必须在构建日志里点出来。
 *
 * 判据分两档（别把不该红的搞红，那会训练人忽略红灯）：
 *   ::warning  只在「不影响功能」的问题上（比如 key 首尾有空白，源码有 .trim() 兜着）
 *   ::error    让构建红：key 不是 anon / ref 对不上 / 已过期 / 接口打不通
 *
 * ⚠️ 这个脚本**必须有一条会 exit 1 的路径**。只 echo 出变量长度不叫检查 ——
 *    那会在日志里留下一个看起来像证据的东西（主站踩过这个坑）。
 */
import { existsSync, readFileSync } from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')

function readEnvFile(file) {
  if (!existsSync(file)) return {}
  const out = {}
  for (const line of readFileSync(file, 'utf8').split(/\r?\n/)) {
    const m = /^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)$/.exec(line)
    if (!m) continue
    let v = m[2].trim()
    if (
      (v.startsWith('"') && v.endsWith('"') && v.length >= 2) ||
      (v.startsWith("'") && v.endsWith("'") && v.length >= 2)
    ) {
      v = v.slice(1, -1)
    }
    out[m[1]] = v
  }
  return out
}

const fileEnv = readEnvFile(path.join(ROOT, '.env.local'))
const rawUrl = (process.env.VITE_SUPABASE_URL ?? fileEnv.VITE_SUPABASE_URL ?? '').trim()
const rawKey = (process.env.VITE_SUPABASE_ANON_KEY ?? fileEnv.VITE_SUPABASE_ANON_KEY ?? '').trim()

/** GitHub Actions 的注解语法；本地跑时降级成普通输出 */
const isCI = Boolean(process.env.GITHUB_ACTIONS)
const warn = (msg) => console.log(isCI ? `::warning title=Supabase 配置::${msg}` : `⚠️  ${msg}`)
const fail = (msg) => {
  console.log(isCI ? `::error title=Supabase 配置::${msg}` : `❌ ${msg}`)
  process.exitCode = 1
}

/* -------------------------------------------------- 1. 有没有配 */

if (!rawUrl || !rawKey) {
  // 本地没配是允许的（会走演示模式），CI 上没配就要红 —— 线上不该是演示模式
  if (isCI) {
    fail(
      'CI 里没有注入 VITE_SUPABASE_URL / VITE_SUPABASE_ANON_KEY，' +
        '线上会退回本地演示模式。请到仓库 Settings → Secrets and variables → Actions → Variables 添加。',
    )
  } else {
    warn('未配置 Supabase，本地会走演示模式（数据只存在浏览器里）。')
  }
  process.exit()
}

/* -------------------------------------------------- 2. 值对不对 */

if (rawUrl !== rawUrl.trim()) warn('URL 首尾有空白（源码有 .trim() 兜着，不影响功能）')
if (rawKey !== rawKey.trim()) warn('anon key 首尾有空白（源码有 .trim() 兜着，不影响功能）')
if (/\s/.test(rawUrl)) fail('URL 中间有空白字符，请求会失败。')
if (/\s/.test(rawKey)) fail('anon key 中间有空白字符，Headers 构造会直接抛异常。')

let ref = ''
try {
  ref = new URL(rawUrl).hostname.split('.')[0]
} catch {
  fail(`VITE_SUPABASE_URL 不是合法 URL：${rawUrl}`)
  process.exit()
}

// JWT 载荷：base64url，取中间那段
let claims = null
try {
  const part = rawKey.split('.')[1]
  if (!part) throw new Error('不是 JWT 结构')
  const b64 = part.replace(/-/g, '+').replace(/_/g, '/')
  claims = JSON.parse(Buffer.from(b64, 'base64').toString('utf8'))
} catch {
  fail('anon key 不是合法的 JWT，无法解析。')
}

if (claims) {
  if (claims.role !== 'anon') {
    // 这条最重要：service_role 打进前端等于把库门钥匙发出去
    fail(`key 的 role 是「${claims.role}」，不是 anon。**绝对不要把 service_role 放进前端**。`)
  }
  if (claims.ref && claims.ref !== ref) {
    fail(`key 的 ref（${claims.ref}）和 URL 的 ref（${ref}）对不上，八成是配错了项目。`)
  }
  if (claims.exp && claims.exp * 1000 < Date.now()) {
    fail('anon key 已过期，请到 Supabase 项目设置里换一个新的。')
  }
}

if (process.exitCode) process.exit()

/* -------------------------------------------------- 3. 打得通吗 */

// 用 list_skills 探活：它同时验证了「函数部署了」和「参数名对得上」
const probe = async () => {
  const ctrl = new AbortController()
  const timer = setTimeout(() => ctrl.abort(), 15000)
  try {
    const res = await fetch(`${rawUrl}/rest/v1/rpc/list_skills`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        apikey: rawKey,
        Authorization: `Bearer ${rawKey}`,
      },
      body: JSON.stringify({ p_limit: 1, p_offset: 0 }),
      signal: ctrl.signal,
    })
    if (!res.ok) {
      fail(
        `list_skills 返回 HTTP ${res.status}。` +
          (res.status === 404
            ? '多半是 001-skills.sql 还没在 SQL Editor 里跑过。'
            : '请检查项目状态与 RLS 配置。'),
      )
      return
    }
    const data = await res.json()
    if (!data || data.ok !== true) {
      fail(`list_skills 返回了非成功响应：${JSON.stringify(data).slice(0, 200)}`)
      return
    }
    console.log(`✅ Supabase 就绪：ref=${ref}，list_skills 正常，当前技能数 ${data.total}`)
  } catch (e) {
    fail(`连不上 Supabase：${e?.name === 'AbortError' ? '请求超时' : e?.message}`)
  } finally {
    clearTimeout(timer)
  }
}

await probe()
