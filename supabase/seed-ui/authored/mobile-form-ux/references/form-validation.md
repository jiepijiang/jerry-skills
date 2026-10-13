# 校验、文案与分步表单

## 一、校验时机矩阵

| 时机 | 用什么 | 适用 | 不适用 |
| --- | --- | --- | --- |
| `input`（每次输入） | 正面反馈 | 密码强度、用户名可用、字数统计 | 格式类校验 |
| `focusout` / `blur` | 格式校验 | 手机号、邮箱、身份证 | 密码确认（用户可能还没输完上一栏） |
| `change` | 选择类校验 | 下拉、单选、复选 | 文本输入 |
| `submit` | 全量校验 | 所有字段 | — |
| 服务端返回 | 字段级错误回填 | 唯一性、业务规则 | — |

**边输入边报错是移动端表单最招人烦的行为**。用户在输第 3 位数字时被标红，
会觉得自己在被指责。规则：输入过程中只给正面反馈，格式问题等 `blur` 再说。

但 `blur` 也有例外：**用户可能永远不会 blur**（直接点提交按钮）。
所以提交时必须有全量校验，不能只依赖 blur。

## 二、校验规则库

```js
export const rules = {
  required: (msg = '此项不能为空') => (v) => v.trim().length > 0 || msg,
  phone:    () => (v) => /^1[3-9]\d{9}$/.test(v) || '手机号应为 11 位数字',
  code6:    () => (v) => /^\d{6}$/.test(v) || '验证码应为 6 位数字',
  email:    () => (v) => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v) || '邮箱格式不正确',
  idCard:   () => (v) => /^\d{17}[\dXx]$/.test(v) || '身份证号应为 18 位',
  len: (min, max) => (v) =>
    (v.length >= min && v.length <= max) || `长度应为 ${min}–${max} 个字符`,
  range: (min, max, unit = '') => (v) => {
    const n = Number(v)
    return (Number.isFinite(n) && n >= min && n <= max) || `应在 ${min}–${max}${unit} 之间`
  },
  amount: () => (v) => /^\d+(\.\d{1,2})?$/.test(v) || '金额最多保留两位小数',
}
```

组合多个规则：

```js
function validate(value, ...fns) {
  for (const fn of fns) {
    const r = fn(value)
    if (r !== true) return r       // 返回第一个错误文案
  }
  return true
}

// 使用
validate(phone.value, rules.required(), rules.phone())
```

只返回**第一个**错误：同时列出 3 条错误会让用户不知从哪改起。

## 三、错误文案模板

文案规则：**说清「错在哪」+「应该是什么样」**，不给用户留猜的空间。

| 场景 | ❌ 差文案 | ✅ 好文案 |
| --- | --- | --- |
| 手机号 | 格式错误 | 手机号应为 11 位数字 |
| 验证码 | 验证码错误 | 验证码不正确，请检查后重试 |
| 验证码过期 | 失败 | 验证码已过期，请重新获取 |
| 密码 | 密码不符合要求 | 密码需 8–20 位，且包含字母和数字 |
| 两次密码 | 不一致 | 两次输入的密码不一致 |
| 必填 | 不能为空 | 请填写收货人姓名 |
| 金额 | 输入有误 | 金额需大于 0，最多两位小数 |
| 身份证 | 格式错误 | 身份证号应为 18 位，最后一位可为 X |
| 唯一性 | 提交失败 | 该手机号已注册，请直接登录 |
| 网络失败 | 系统错误 | 网络异常，请检查网络后重试 |
| 服务异常 | 错误 500 | 服务暂时不可用，请稍后重试 |

禁止出现的文案：`操作失败`、`系统繁忙`、`参数错误`、`未知错误`。
这些文案对用户没有任何帮助，只会让人放弃。

## 四、错误展示规范

```html
<div class="field">
  <label for="phone">手机号</label>
  <input id="phone" aria-invalid="true" aria-describedby="phone-err">
  <p id="phone-err" class="err" role="alert">
    <svg class="err-icon" aria-hidden="true">…</svg>
    手机号应为 11 位数字
  </p>
</div>
```

```css
.field .err {
  min-height: 20px;          /* 预留高度，避免布局跳动 */
  display: flex; align-items: center; gap: 4px;
  font-size: 12px; line-height: 20px;
  color: #ff4d4f;
  margin: 4px 0 0;
}
.field input[aria-invalid="true"] { border-color: #ff4d4f; }
```

三重提示：**边框变色 + 图标 + 文字**。
只靠颜色对色盲用户无效，只靠文字在长表单里不容易扫到。

`role="alert"` 让屏幕阅读器自动朗读错误内容（`aria-live="assertive"` 的等价写法）。
注意：`role="alert"` 只在内容变化时触发朗读，所以要**先清空再写入**，
如果连续两次错误文案相同，屏幕阅读器不会重复朗读。

## 五、分步表单的状态管理

```js
const state = {
  step: 1,
  total: 3,
  data: { name: '', phone: '', code: '', address: '' },
  errors: {},
}

function goNext() {
  const fields = STEP_FIELDS[state.step]
  const bad = fields.filter((f) => !validateField(f))
  if (bad.length) { focusFirst(bad[0]); return }
  state.step++
  render()
  history.pushState({ step: state.step }, '')
}

window.addEventListener('popstate', () => {
  state.step = Math.max(1, state.step - 1)
  render()
})
```

要求：
1. **数据集中在一个对象里**，每一步只读写自己的字段，返回时数据仍在。
2. **`pushState` 让浏览器返回键能回上一步**，而不是直接退出页面。
3. **进度指示用文字 + 进度条**：`第 2 步 / 共 3 步`，
   进度条宽度 `(step - 1) / total * 100%`（第一步时可以是 0 或 33%，团队内统一即可）。
4. **每步独立可完成**，不要「第 3 步依赖第 1 步的某个隐藏值」。
5. **最后一步前给确认页**，把所有填写内容列出来，每项旁边有「修改」链接跳回对应步骤。

## 六、键盘遮挡处理

输入框被键盘挡住是移动端表单的高频问题。

```js
// 输入框聚焦后，把它滚动到可视区域中间
input.addEventListener('focus', () => {
  setTimeout(() => {
    input.scrollIntoView({ block: 'center', behavior: 'smooth' })
  }, 300)   // 等键盘弹出动画结束
})

// 更稳的方式：用 visualViewport 判断
const vv = window.visualViewport
vv?.addEventListener('resize', () => {
  const rect = document.activeElement?.getBoundingClientRect()
  if (!rect) return
  const visibleBottom = vv.height + vv.offsetTop
  if (rect.bottom > visibleBottom - 16) {
    window.scrollBy({ top: rect.bottom - visibleBottom + 32, behavior: 'smooth' })
  }
})
```

要点：
- 延迟 300ms 是因为键盘弹出有动画，立即滚动会被后续的视口变化覆盖。
- **底部固定的提交按钮在键盘弹出时应隐藏或改为跟随键盘**，
  否则它会飘在键盘中间挡住输入框。
- 不要在输入框聚焦时改变布局（如展开说明文字），会让焦点位置跳动。

## 七、提交失败的错误回填

服务端返回字段级错误时，必须映射回对应输入框：

```js
async function doSubmit() {
  try {
    await api.submit(payload)
  } catch (err) {
    // 服务端约定：{ errors: { phone: '该手机号已注册', code: '验证码不正确' } }
    if (err.errors) {
      const names = Object.keys(err.errors)
      names.forEach((n) => showFieldError(n, err.errors[n]))
      const el = form.querySelector(`[name="${names[0]}"]`)
      el?.focus()
      el?.scrollIntoView({ block: 'center', behavior: 'smooth' })
      return
    }
    // 非字段级错误才用全局提示
    showGlobalError(err.message || '网络异常，请稍后重试')
  }
}
```

反模式：不管什么错误都弹一个 toast「提交失败」。
用户面对一个填了 12 个字段的表单，只被告知「失败」，只能逐个重试。

## 八、检查清单

- [ ] 校验时机为 `blur` + 提交全量，输入过程中只给正面反馈
- [ ] 每次只展示第一条错误文案
- [ ] 错误文案说清「错在哪 + 应该是什么样」
- [ ] 错误提示有边框 + 图标 + 文字三重提示，`role="alert"`
- [ ] 错误提示位预留了高度，不引起布局跳动
- [ ] 提交失败保留所有输入
- [ ] 服务端字段级错误已回填到对应输入框并聚焦
- [ ] 全局错误与字段错误分开处理
- [ ] 分步表单数据集中管理，返回不丢
- [ ] 分步表单 `pushState` 支持浏览器返回上一步
- [ ] 最后一步前有确认页，可跳回修改
- [ ] 输入框聚焦后被键盘遮挡时自动滚动到可视区
- [ ] 键盘弹出时底部固定按钮不遮挡输入框
