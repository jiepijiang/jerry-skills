---
name: "mobile-form-ux"
description: "设计移动端表单与登录注册流程时使用：inputmode 与 type 选型、错误提示时机、分步还是单页、自动填充、验证码交互与防重复提交。"
version: "1.0.0"
license: "MIT"
author: "Skill Hub"
category: ui
tags: ["H5 移动端", "表单设计", "inputmode", "自动填充", "验证码", "防重复提交"]
---

# 移动端表单设计

移动端表单的成败几乎全部落在**键盘**上：调错键盘、被键盘遮住、输错一栏要重来。
本技能给出输入类型选型、校验时机、分步策略与提交态的完整规则。

## 何时使用

- 做登录 / 注册 / 实名认证 / 收货地址 / 支付信息填写
- 用户反馈「手机号输不进去」「键盘上没有我需要的符号」
- 表单提交后没反应，用户重复点击产生重复订单
- 需要在「一页填完」和「分步骤」之间做决定
- 验证码收不到、填错、倒计时结束后按钮没恢复

## 核心规则

1. **键盘类型用 `inputmode` 决定，不要用 `type="number"`**。
   `type="number"` 有三个真实问题：
   ① 允许输入 `e`、`-`、`+`；② 值非法时 `input.value` 返回**空字符串**（拿不到用户输入）；
   ③ 部分浏览器显示上下箭头，占位且容易误触。
   正确写法：`type="text" inputmode="numeric" pattern="[0-9]*"`。

2. **手机号用 `type="tel"`**。`number` 会丢掉前导 0，且允许小数点和负号。
   `tel` 在 iOS 和 Android 上都会调出数字键盘。

3. **输入框字号必须 ≥ 16px**。iOS Safari 在字号小于 16px 的输入框获得焦点时会
   **自动放大整个页面**，用户填完还要手动缩回去。这是移动端表单最经典的体验事故。

4. **校验时机：失焦（`blur`）时校验，提交时全量校验并聚焦第一个错误项**。
   不要边输入边报错 —— 用户输入 `138` 时提示「手机号格式错误」是纯骚扰。
   例外：可以实时给**正面反馈**（密码强度、用户名可用），因为正面反馈不会打断输入。

5. **错误提示放在输入框下方，不要用 toast**。toast 会消失，
   用户回到表单时已经不知道哪一栏错了。文案必须具体：
   写「手机号应为 11 位数字」，不写「格式错误」。

6. **字段 ≤ 5 个用单页，≥ 8 个才考虑分步**。分步的代价是每多一步就多一个放弃点。
   分步的前提是能给出清晰的进度感，且每一步都能独立完成、可以后退不丢数据。

7. **提交按钮必须做防重复提交**：点击后立即 `disabled` + 显示 loading，
   请求结束（含失败）后再恢复。**不要用定时器恢复**。

8. **每个输入框都写 `autocomplete`**。这是移动端性价比最高的一行属性：
   正确的 `autocomplete` 能让系统密码管理器、地址簿、短信验证码自动填进去。

## 怎么做

### 第 1 步：选对输入类型

| 要输入的内容 | `type` | `inputmode` | `autocomplete` |
| --- | --- | --- | --- |
| 手机号 | `tel` | `tel` | `tel` |
| 短信验证码 | `text` | `numeric` | `one-time-code` |
| 整数（数量、年龄） | `text` | `numeric` | — |
| 金额 | `text` | `decimal` | — |
| 邮箱 | `email` | `email` | `email` |
| 密码（登录） | `password` | — | `current-password` |
| 密码（注册） | `password` | — | `new-password` |
| 银行卡号 | `text` | `numeric` | `cc-number` |
| 详细地址 | `text` | — | `street-address` |
| 邮编 | `text` | `numeric` | `postal-code` |

`inputmode="numeric"` 与 `"decimal"` 的区别：前者只有数字，后者带小数点。
金额一定要用 `decimal`，否则用户找不到小数点。
`type="email"` 在 iOS 上键盘会带 `@` 和 `.` 快捷键，用对了能省用户好几次键盘切换。

### 第 2 步：回车键与焦点流转

```html
<input type="tel" inputmode="tel" enterkeyhint="next" autocomplete="tel">
<input type="text" inputmode="numeric" enterkeyhint="done" autocomplete="one-time-code">
<button type="submit">提交</button>
```

`enterkeyhint` 取值：`next`（中间字段）、`done`（最后一个）、`go`（跳转）、
`search`（搜索）、`send`（发送消息/验证码）。

```js
form.addEventListener('keydown', (e) => {
  if (e.key !== 'Enter') return
  const inputs = [...form.querySelectorAll('input:not([type=submit])')]
  const i = inputs.indexOf(e.target)
  e.preventDefault()
  const isLast = e.target.getAttribute('enterkeyhint') === 'done' || i === inputs.length - 1
  isLast ? form.requestSubmit() : inputs[i + 1]?.focus()
})
```

用 `form.requestSubmit()` 而不是 `form.submit()`：前者会触发表单校验与 `submit` 事件，
后者会绕过校验直接提交。

### 第 3 步：标签与占位符

```html
<label for="phone">手机号</label>
<input id="phone" type="tel" inputmode="tel" autocomplete="tel"
       placeholder="11 位手机号" aria-describedby="phone-err">
<p id="phone-err" class="err" role="alert"></p>
```

- **`label` 不能省**。`placeholder` 在用户开始输入后就消失了，用户会忘记这一栏要填什么。
- `placeholder` 只放**格式示例**（「11 位手机号」「如：张三」），不放字段名。
- 必填项标记：用「*」加 `aria-required="true"`，不要只靠颜色。
- 每个输入框下方预留错误提示位（`min-height: 20px`），
  否则错误出现时会把下方内容顶下去（CLS）。

### 第 4 步：校验与错误提示

```js
const rules = {
  phone: (v) => /^1[3-9]\d{9}$/.test(v) || '手机号应为 11 位数字',
  code:  (v) => /^\d{6}$/.test(v) || '验证码应为 6 位数字',
}

function validateField(input) {
  const rule = rules[input.name]
  if (!rule) return true
  const r = rule(input.value)
  input.setAttribute('aria-invalid', String(r !== true))
  document.getElementById(`${input.id}-err`).textContent = r === true ? '' : r
  return r === true
}

form.addEventListener('focusout', (e) => {       // 失焦校验
  if (e.target.matches('input')) validateField(e.target)
})

form.addEventListener('submit', (e) => {         // 提交时全量校验
  e.preventDefault()
  const bad = [...form.querySelectorAll('input')].filter((i) => !validateField(i))
  if (bad.length) {
    bad[0].focus()
    bad[0].scrollIntoView({ block: 'center', behavior: 'smooth' })
    return
  }
  doSubmit()
})
```

要点：
- `scrollIntoView({ block: 'center' })` 让错误项居中，避开顶部吸顶栏和底部键盘。
- 错误项用边框变色 + 图标 + 文字**三重提示**，不能只靠颜色。
- 提交失败时把服务端返回的字段级错误映射回对应输入框，不要只弹一个 toast。

### 第 5 步：分步 vs 单页

| 判据 | 单页 | 分步 |
| --- | --- | --- |
| 字段数 | ≤ 5 | ≥ 8 |
| 字段间有依赖（后面取决于前面） | 不适合 | 适合 |
| 有需要跳过的分支 | 不适合 | 适合 |
| 用户需要一次性看到全貌 | 适合 | 不适合 |
| 移动端、注意力碎片化 | 适合 | 每步 ≤ 5 个字段时适合 |

分步表单的硬性要求：
1. **显示进度**：`第 2 步 / 共 3 步` + 进度条，进度条宽度用百分比。
2. **每步可后退且不丢数据**，数据存在一个统一的状态对象里。
3. **最后一步前给一次确认页**（汇总所有填写内容，允许跳回修改）。
4. 步骤标题用**动宾短语**（「填写收货信息」），不要用「第一步」。

反模式：把一个 4 字段的表单拆成 3 步。用户点了 3 次「下一步」才填了 4 个字段，
完成率一定低于单页。

### 第 6 步：验证码交互

```html
<input type="text" inputmode="numeric" autocomplete="one-time-code"
       maxlength="6" pattern="[0-9]*" aria-label="短信验证码">
```

1. **`autocomplete="one-time-code"`**：iOS 12+ 与 Android 支持从短信里直接提取验证码，
   在键盘上方给一个「自动填充」按钮。这一条能显著提升验证码通过率。
2. **倒计时 60s**，按钮文案 `重新发送（58s）`，结束后变回 `重新发送`。
   倒计时期间按钮 `disabled` 但保持可读（不要变灰到看不见）。
3. **分格输入用「一个隐藏 input + 6 个展示格」**。用 6 个独立 input 会带来大量
   焦点管理问题（退格、粘贴、自动跳格），实现成本高且容易出 bug。
4. **支持粘贴**。用户从短信复制后粘贴是最自然的操作，
   粘贴 `123456` 时要能整段填充而不是只填一位。
5. **自动提交**：填满 6 位后自动提交，但要保留手动提交按钮作为兜底。
6. 验证码错误时**清空输入框并重新聚焦**，不要让用户手动全选删除。

### 第 7 步：提交态

```js
let submitting = false

async function doSubmit() {
  if (submitting) return
  submitting = true
  const btn = form.querySelector('[type=submit]')
  const original = btn.textContent
  btn.disabled = true
  btn.textContent = '提交中…'
  btn.setAttribute('aria-busy', 'true')
  try {
    await api.submit(collect())
    showSuccess()
  } catch (err) {
    showError(err)             // 保留用户已填内容
  } finally {
    submitting = false
    btn.disabled = false
    btn.textContent = original
    btn.removeAttribute('aria-busy')
  }
}
```

必须做到的：
- **按钮宽度固定**。文案从「提交」变「提交中…」时按钮变宽会让整行布局跳动。
- **失败后保留所有输入**。清空表单是最不可原谅的错误。
- **成功后有明确落点**：跳转结果页或显示成功态，不要让用户停在原表单上猜有没有成功。
- 网络超时时给出明确文案 + 重试入口，不要静默失败。

## 检查清单

- [ ] 每个输入框都有正确的 `type` / `inputmode` / `autocomplete`
- [ ] 手机号用 `type="tel"`，数字用 `inputmode="numeric"`，未使用 `type="number"`
- [ ] 所有输入框字号 ≥ 16px（iOS 不自动放大）
- [ ] `enterkeyhint` 已设置，回车能流转焦点或提交
- [ ] 每个字段有 `label`，`placeholder` 只放格式示例
- [ ] 错误提示在输入框下方，位置已预留（不引起布局跳动）
- [ ] 校验时机为 `blur` + 提交时全量，未做边输入边报错
- [ ] 错误文案具体（含位数、格式要求），不用 toast
- [ ] 提交失败后保留用户输入，服务端字段级错误已回填
- [ ] 提交按钮有 disabled + loading，宽度固定，无重复提交
- [ ] 验证码有 `autocomplete="one-time-code"`、支持粘贴、错误后清空重聚焦
- [ ] 倒计时 60s，结束后按钮恢复可用
- [ ] 分步表单有进度指示，可后退且不丢数据
- [ ] 键盘弹出时当前输入框仍可见（未被键盘遮挡）
- [ ] 在 iOS Safari + Android Chrome 真机各走一遍完整流程

## 常见错误

| 错误做法 | 为什么错 | 正确做法 |
| --- | --- | --- |
| `type="number"` 收手机号/验证码 | 丢前导 0、允许 `e`/`-`、非法值读出空字符串 | `type="tel"` 或 `type="text" inputmode="numeric"` |
| 输入框字号 14px | iOS 聚焦时自动放大整页，用户填完要手动缩回 | 字号 ≥ 16px |
| 边输入边报错 | 用户还没输完就被判错，纯骚扰 | `blur` 时校验，提交时全量 |
| 错误提示用 toast | toast 消失后用户不知道哪栏错了 | 提示固定在输入框下方 |
| 提示文案「格式错误」 | 用户不知道要改成什么样 | 「手机号应为 11 位数字」 |
| 用 `placeholder` 代替 `label` | 开始输入后字段名消失 | 保留 `label`，placeholder 放示例 |
| 6 个独立 input 做验证码 | 焦点/退格/粘贴逻辑复杂，容易出 bug | 一个隐藏 input + 6 个展示格 |
| 验证码不支持粘贴 | 用户从短信复制后只能手打 6 位 | 处理 `paste` 事件整段填充 |
| 用 `setTimeout` 恢复提交按钮 | 慢网下按钮提前恢复，产生重复提交 | 在 `finally` 里恢复 |
| 提交失败后清空表单 | 用户要全部重填，直接流失 | 保留输入，只提示错误 |
| 4 个字段拆成 3 步 | 每多一步多一个放弃点，完成率下降 | ≤ 5 个字段用单页 |
| 不写 `autocomplete` | 用户要手打手机号、地址、验证码 | 逐字段配置 `autocomplete` |
| 提交后停在原页无反馈 | 用户不确定是否成功，可能再点一次 | 跳转结果页或显示成功态 |

## 参考

- 需要完整的 `inputmode` / `type` / `autocomplete` 取值对照，以及各取值在 iOS / Android 上的实际键盘差异时，读 `references/input-types.md`
- 需要校验规则库、错误文案模板、分步表单状态管理与键盘遮挡处理时，读 `references/form-validation.md`
