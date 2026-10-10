/**
 * 时间显示单元测试
 * ---------------------------------------------------------------------------
 * 跑法：npm test（= node --test scripts/tests/）
 *
 * 这些断言针对的是「不报错、不空白、只是数字不对」那类缺陷 —— 最容易被放过去，
 * 也最容易被用户一眼看穿。
 *
 * ⚠️ 按项目纪律：**没红过的绿灯没有意义**。
 *    下面每一条都真的改坏过源码确认会红（见 README「验证」一节）。
 */
import { test } from 'node:test'
import assert from 'node:assert/strict'

import { absoluteTime, parseTime, relativeTime } from '../../src/lib/time.js'

/** 固定的「现在」，避免测试依赖真实时钟 */
const BASE = '2026-10-10T06:00:00.000Z'
const NOW = new Date(BASE).getTime()

/** 相对 BASE 往前推 n 毫秒的时间戳 */
const ago = (ms) => new Date(NOW - ms).toISOString()

const MIN = 60_000
const HOUR = 60 * MIN
const DAY = 24 * HOUR

/* ---------------------------------------------------------------- 空值 */

test('parseTime：空值一律返回 null', () => {
  assert.equal(parseTime(null), null)
  assert.equal(parseTime(undefined), null)
  assert.equal(parseTime(''), null)
  assert.equal(parseTime('not-a-date'), null)
  assert.equal(parseTime({}), null)
  assert.equal(parseTime([]), null)
})

test('parseTime(null) 不能变成纪元时间 —— new Date(null) 是有限值', () => {
  // 这条是**回归护栏**：直接 new Date(null) 会得到 1970-01-01，
  // 于是页面上会渲染出「56 年前」。所以先把原生行为钉住，
  // 任何人把 parseTime 改回 new Date(iso) 都会在这里红。
  assert.equal(new Date(null).getTime(), 0, '前提：new Date(null) 确实是纪元')
  assert.equal(parseTime(null), null)
})

test('relativeTime：空值 / 非法值返回空串，而不是「56 年前」或「Invalid Date」', () => {
  for (const bad of [null, undefined, '', 'not-a-date', {}, []]) {
    const out = relativeTime(bad, NOW)
    assert.equal(out, '', `输入 ${JSON.stringify(bad)} 应该返回空串，实际是 ${JSON.stringify(out)}`)
    assert.ok(!out.includes('年前'), '绝不能渲染成「N 年前」')
    assert.ok(!out.includes('NaN'), '绝不能渲染出 NaN')
  }
})

/* ------------------------------------------------------- 相对时间边界 */

test('relativeTime：不到 1 分钟是「刚刚」', () => {
  assert.equal(relativeTime(ago(0), NOW), '刚刚')
  assert.equal(relativeTime(ago(MIN - 1), NOW), '刚刚')
})

test('relativeTime：分钟级，且 59→60 的台阶正好在 60 分钟', () => {
  assert.equal(relativeTime(ago(MIN), NOW), '1 分钟前')
  assert.equal(relativeTime(ago(59 * MIN), NOW), '59 分钟前')
  assert.equal(relativeTime(ago(60 * MIN), NOW), '1 小时前')
})

test('relativeTime：小时级，23→24 的台阶正好在 24 小时', () => {
  assert.equal(relativeTime(ago(HOUR), NOW), '1 小时前')
  assert.equal(relativeTime(ago(23 * HOUR), NOW), '23 小时前')
  assert.equal(relativeTime(ago(24 * HOUR), NOW), '1 天前')
})

test('relativeTime：天级，29→30 的台阶正好在 30 天（进入「个月」）', () => {
  assert.equal(relativeTime(ago(29 * DAY), NOW), '29 天前')
  assert.equal(relativeTime(ago(30 * DAY), NOW), '1 个月前')
})

test('relativeTime：月 / 年的台阶正好在 12 个月', () => {
  assert.equal(relativeTime(ago(330 * DAY), NOW), '11 个月前') // 11 个月
  assert.equal(relativeTime(ago(360 * DAY), NOW), '1 年前') // 12 个月
  assert.equal(relativeTime(ago(720 * DAY), NOW), '2 年前') // 24 个月
})

test('relativeTime：未来时间按「刚刚」，不显示负数', () => {
  assert.equal(relativeTime(ago(-5 * MIN), NOW), '刚刚')
  assert.equal(relativeTime(ago(-30 * DAY), NOW), '刚刚')
})

/* -------------------------------------------------------- 后端格式兼容 */

test('relativeTime：能解析 PostgREST 返回的 6 位小数时间戳', () => {
  // Supabase/PostgREST 的 timestamptz 形如 2026-10-10T06:00:00.123456+00:00。
  // ES 规范里 Date Time String Format 只认 3 位毫秒 —— 如果哪天换了运行时
  // 不再宽松解析，这里会先红，而不是等到线上卡片集体空白。
  const ts = '2026-10-10T06:00:00.123456+00:00'
  const d = parseTime(ts)
  assert.ok(d, '6 位小数应该能解析')
  // 多出来的 456 微秒被截断，只保留到毫秒
  assert.equal(d.getTime(), new Date('2026-10-10T06:00:00.123Z').getTime())

  // ⚠️ 偏移量要留出余量：`.123` 会吃掉 123ms，
  //    正好卡在 2 天整时会掉进「1 天前」—— 那是**正确**行为，
  //    别为了凑整把断言写成 NOW + 2*DAY（那样测的是边界，不是解析）。
  assert.equal(relativeTime(ts, NOW + 2 * DAY + 1000), '2 天前')
})

test('relativeTime：带空格分隔符与 +00 偏移的写法也能解析', () => {
  assert.equal(relativeTime('2026-10-10 06:00:00+00', NOW + HOUR), '1 小时前')
})

/* -------------------------------------------------------- 绝对时间 */

test('absoluteTime：本地时区、补零到分钟', () => {
  // 固定用一个本地构造的日期，避免测试机时区不同导致断言漂移
  const d = new Date(2026, 0, 5, 9, 7) // 2026-01-05 09:07 本地时间
  assert.equal(absoluteTime(d.toISOString()), '2026-01-05 09:07')
})

test('absoluteTime：空值返回空串', () => {
  for (const bad of [null, undefined, '', 'not-a-date']) {
    assert.equal(absoluteTime(bad), '')
  }
})
