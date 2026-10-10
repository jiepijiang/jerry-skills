/**
 * 时间显示
 * ---------------------------------------------------------------------------
 * 从 SkillDetailView 里提取出来：现在**列表卡片**也要显示时间，两处各写一份
 * 迟早会漂移（详情页说「3 天前」、列表页说「4 天前」，用户第一反应是站坏了）。
 */

/**
 * 把后端时间戳解析成 Date，解析不了就返回 null。
 *
 * ⚠️ 这里**不能**直接 `new Date(iso)` 然后判 NaN —— 空值的行为根本不一致：
 *
 *      new Date(null)       → 1970-01-01T00:00:00Z  ← **有限值！**
 *      new Date(undefined)  → Invalid Date
 *      new Date('')         → Invalid Date
 *
 *    所以 `created_at` 为 null 时，`new Date(null)` 不是 NaN，而是**纪元时间**，
 *    页面上会理直气壮地渲染出「56 年前」。这是最难查的那类 bug：
 *    不报错、不空白、只是数字不对，肉眼扫过去还觉得挺合理。
 *    （2026-10-10 实测确认，见 scripts/tests/time.test.mjs）
 */
export function parseTime(iso) {
  if (iso === null || iso === undefined || iso === '') return null
  if (typeof iso !== 'string' && typeof iso !== 'number') return null
  const d = new Date(iso)
  return Number.isFinite(d.getTime()) ? d : null
}

/**
 * 相对时间：刚刚 / 12 分钟前 / 3 小时前 / 5 天前 / 2 个月前 / 1 年前。
 * 解析不了返回空串（调用方用 v-if 兜住，不要渲染出「Invalid Date」）。
 *
 * `now` 可注入 —— 否则测试只能去 mock Date.now()，那种测试既难写又容易假绿。
 */
export function relativeTime(iso, now = Date.now()) {
  const d = parseTime(iso)
  if (!d) return ''

  const min = Math.floor((now - d.getTime()) / 60000)
  if (!Number.isFinite(min)) return ''
  // 未来时间（时钟偏差 / 上传机器时间不准）一律按「刚刚」，不要显示「-3 分钟前」
  if (min < 1) return '刚刚'
  if (min < 60) return `${min} 分钟前`

  const h = Math.floor(min / 60)
  if (h < 24) return `${h} 小时前`

  const day = Math.floor(h / 24)
  if (day < 30) return `${day} 天前`

  const mo = Math.floor(day / 30)
  return mo < 12 ? `${mo} 个月前` : `${Math.floor(mo / 12)} 年前`
}

/**
 * 绝对时间：「2026-10-10 14:22」（**本地时区**，补零）。
 * 给 title 悬浮提示用 —— 相对时间好读，但想知道确切哪一天还得看绝对值。
 *
 * 手写补零而不用 toLocaleString：后者受 locale / ICU 版本影响，
 * 同一份代码在不同机器上能输出完全不同的格式，测试也跟着飘。
 */
export function absoluteTime(iso) {
  const d = parseTime(iso)
  if (!d) return ''
  const p = (n) => String(n).padStart(2, '0')
  return (
    `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())}` +
    ` ${p(d.getHours())}:${p(d.getMinutes())}`
  )
}
