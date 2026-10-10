/**
 * Supabase 接入层（PostgREST 直连，不引 SDK）
 * ---------------------------------------------------------------------------
 * 与主站留言板 / jerry-tools 同一个套路：只用到 PostgREST 的 RPC，
 * 一条 fetch 就够了，没必要为此引入 @supabase/supabase-js（那会多出上百 KB）。
 *
 * ⚠️ 两条必须遵守的判据（主站留言板踩过坑，见 README）：
 *   1. **业务失败走 HTTP 200**：`{ok:false, code:'rate_limited'}` 也是 200。
 *      所以判断成功必须写 `ok !== true`（失败关闭），不能写 `ok === false` ——
 *      后者会把「200 + 解析不出的 body」判成成功，是谎报。
 *   2. **参数名要和 SQL 函数签名一致**（`p_slug` / `p_query` …）。
 *      PostgREST 按名字匹配，写错会 404 而不是 400。
 */

const URL = (import.meta.env.VITE_SUPABASE_URL || '').trim()
const KEY = (import.meta.env.VITE_SUPABASE_ANON_KEY || '').trim()

/** 两个都要有才算配置好（只配 URL 不配 key 会 401，那还不如当没配） */
export const READY = Boolean(URL && KEY)

/** 业务失败。带 code 出去，让上层按 code 查表映射文案，而不是字符串匹配 */
export class SkillError extends Error {
  constructor(code, detail) {
    super(code)
    this.name = 'SkillError'
    this.code = code
    this.detail = detail
  }
}

let warned = false

/** 未配置后端时的留痕 —— 不静默假成功 */
export function warnLocalMode() {
  if (warned || READY) return
  warned = true
  console.warn(
    '[jerry-skills] 未配置 Supabase（VITE_SUPABASE_URL / VITE_SUPABASE_ANON_KEY 为空），' +
      '本次运行在**本地演示模式**：数据只存在这台机器的 localStorage 里，' +
      '上传的内容别人看不到，下载量也不会真的累计。',
  )
}

export async function rpc(fn, params = {}, { timeout = 20000 } = {}) {
  if (!READY) throw new SkillError('not_configured')

  const ctrl = new AbortController()
  const timer = setTimeout(() => ctrl.abort(), timeout)

  let res
  try {
    res = await fetch(`${URL}/rest/v1/rpc/${fn}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        apikey: KEY,
        Authorization: `Bearer ${KEY}`,
      },
      body: JSON.stringify(params),
      signal: ctrl.signal,
    })
  } catch (e) {
    throw new SkillError(e?.name === 'AbortError' ? 'timeout' : 'network', e?.message)
  } finally {
    clearTimeout(timer)
  }

  if (!res.ok) {
    // 404 通常是函数名/参数名写错；400 是参数类型不对
    throw new SkillError(`http_${res.status}`, `${fn} → HTTP ${res.status}`)
  }

  const data = await res.json().catch(() => null)
  /* 失败关闭：只有后端明确说 ok:true 才算成功（见文件头第 1 条） */
  if (!data || data.ok !== true) {
    throw new SkillError(data?.code || 'server', data?.detail)
  }
  return data
}
