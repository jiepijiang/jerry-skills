# 输入类型与自动填充对照

## 一、`inputmode` 取值

`inputmode` 只影响**弹哪个键盘**，不影响值的类型与校验，是控制键盘的正确工具。

| 值 | 键盘表现 | iOS | Android | 适用 |
| --- | --- | --- | --- | --- |
| `none` | 不弹键盘 | ✅ | ✅ | 自定义日期/选择器 |
| `text` | 普通字母键盘 | ✅ | ✅ | 默认 |
| `tel` | 数字 + `+` `*` `#` | ✅ | ✅ | 电话、手机号 |
| `url` | 字母 + `/` `.com` | ✅ | ✅ | 网址 |
| `email` | 字母 + `@` `.` | ✅ | ✅ | 邮箱 |
| `numeric` | 纯数字 + 少量符号 | ✅ | ✅ | 整数、验证码、卡号 |
| `decimal` | 数字 + 小数点 | ✅ | ✅ | 金额、体重 |
| `search` | 普通键盘，回车键变「搜索」 | ✅ | ✅ | 搜索框 |

注意：
- `numeric` 在 iOS 上键盘仍带 `,` `.` `-` 等符号，**不能靠它保证只有数字**，
  必须配合 `pattern` 或 JS 过滤。
- Android 上 `numeric` 与 `tel` 的键盘外观差异较小，但 `tel` 会带拨号相关符号。
- `inputmode` 的浏览器支持已覆盖 iOS 12.2+ / Chrome 66+，
  不支持的浏览器会忽略该属性并退回 `type` 的默认键盘，是安全降级。

## 二、`type` 取值与坑

| `type` | 键盘 | 坑 | 建议 |
| --- | --- | --- | --- |
| `text` | 普通 | 无 | 默认选择 |
| `tel` | 数字 | 不校验格式（这是好事） | **手机号首选** |
| `email` | 带 `@` | 会触发浏览器自带校验（可用 `novalidate` 关闭） | 邮箱首选 |
| `url` | 带 `/` | 校验严格，`example.com` 会被判非法 | 明确要求带协议头时用 |
| `number` | 数字 + 箭头 | 丢前导 0、允许 `e`/`-`、非法值 `value` 为空串、有上下箭头 | **基本不用** |
| `password` | 普通 | 无 | 密码 |
| `search` | 普通 | 部分浏览器加清除按钮 | 搜索框 |
| `date` | 系统日期选择器 | 样式不可控、iOS 上是滚轮 | 仅在能接受默认样式时用 |

### `type="number"` 的三个具体问题

```html
<input type="number" id="a">
```

1. 用户输入 `12e5` 时，`input.value` 返回 `"12e5"`；输入 `1.2.3` 时返回 `""`。
   **无法从 `value` 区分「空」和「非法输入」**，表单校验会失灵。
2. 用户输入 `0123` 时，读出的 `value` 是 `"0123"` 但 `valueAsNumber` 是 `123`，
   提交时若用 `valueAsNumber` 会丢前导 0（验证码、银行卡号、身份证号的致命问题）。
3. 桌面浏览器会显示上下箭头，移动端不显示，导致桌面测试与真机表现不一致。

替代写法：

```html
<!-- 整数 -->
<input type="text" inputmode="numeric" pattern="[0-9]*" autocomplete="off">
<!-- 金额 -->
<input type="text" inputmode="decimal" pattern="[0-9]*\.?[0-9]*">
```

## 三、`autocomplete` 常用 token

完整 token 列表见 HTML 标准，以下是移动端表单真正会用到的：

### 身份

| token | 含义 |
| --- | --- |
| `name` | 全名 |
| `given-name` / `family-name` | 名 / 姓 |
| `additional-name` | 中间名 |
| `honorific-prefix` / `honorific-suffix` | 称谓 / 后缀 |
| `nickname` | 昵称 |
| `organization` | 公司名 |
| `organization-title` | 职位 |

### 联系方式

| token | 含义 |
| --- | --- |
| `tel` | 完整电话号码 |
| `tel-country-code` | 国家码（+86） |
| `tel-national` | 号码主体 |
| `email` | 邮箱 |
| `url` | 网址 |
| `impp` | IM 账号 |

### 地址

| token | 含义 |
| --- | --- |
| `street-address` | 完整地址（多行） |
| `address-line1` / `address-line2` / `address-line3` | 地址行 |
| `address-level1` | 省 / 州 |
| `address-level2` | 市 |
| `address-level3` | 区 / 县 |
| `postal-code` | 邮编 |
| `country` / `country-name` | 国家代码 / 国家名 |

### 密码与验证

| token | 含义 |
| --- | --- |
| `username` | 用户名 |
| `current-password` | 已有密码（登录） |
| `new-password` | 新密码（注册/改密） |
| `one-time-code` | 短信/邮件验证码 |
| `webauthn` | WebAuthn 凭据 |

**`current-password` 与 `new-password` 必须分清**：
登录页写 `new-password` 会让密码管理器弹出「生成强密码」，
注册页写 `current-password` 则不会提供保存建议。

### 支付与生日

| token | 含义 |
| --- | --- |
| `cc-number` | 卡号 |
| `cc-name` | 持卡人 |
| `cc-exp` | 有效期 |
| `cc-exp-month` / `cc-exp-year` | 有效期月 / 年 |
| `cc-csc` | 安全码（CVV） |
| `cc-type` | 卡类型 |
| `bday` / `bday-day` / `bday-month` / `bday-year` | 生日 |
| `sex` | 性别 |

## 四、完整示例

```html
<form novalidate autocomplete="on">
  <div class="field">
    <label for="name">收货人</label>
    <input id="name" name="name" type="text" autocomplete="name"
           enterkeyhint="next" required>
    <p class="err" id="name-err" role="alert"></p>
  </div>

  <div class="field">
    <label for="phone">手机号</label>
    <input id="phone" name="phone" type="tel" inputmode="tel" autocomplete="tel"
           maxlength="11" enterkeyhint="next" required>
    <p class="err" id="phone-err" role="alert"></p>
  </div>

  <div class="field">
    <label for="code">验证码</label>
    <div class="code-row">
      <input id="code" name="code" type="text" inputmode="numeric"
             autocomplete="one-time-code" maxlength="6" pattern="[0-9]*"
             enterkeyhint="done" required>
      <button type="button" id="send-code">获取验证码</button>
    </div>
    <p class="err" id="code-err" role="alert"></p>
  </div>

  <button type="submit" class="submit">提交订单</button>
</form>
```

```css
.field input {
  height: 48px;
  font-size: 16px;        /* 关键：≥16px 防止 iOS 自动放大 */
  border-radius: 8px;
  border: 1px solid #d9d9d9;
}
.field input:focus-visible { border-color: #1677ff; outline: 2px solid #1677ff33; }
.field input[aria-invalid="true"] { border-color: #ff4d4f; }
.field .err { min-height: 20px; font-size: 12px; color: #ff4d4f; margin: 4px 0 0; }
.submit { height: 48px; width: 100%; font-size: 16px; }
```

## 五、移动端输入框尺寸规范

| 项 | 取值 | 理由 |
| --- | --- | --- |
| 输入框高度 | 44–48px | 触控目标下限 44px |
| 输入框字号 | **≥ 16px** | 小于 16px iOS 会自动放大页面 |
| 输入框圆角 | 6–10px | 与整体设计语言一致 |
| 字段间距 | 16–20px | 小于 16px 容易点错相邻字段 |
| label 字号 | 13–14px | 比输入内容小一档 |
| 错误文案字号 | 12–13px | 不抢主信息 |
| 左右内边距 | 12–16px | 与卡片内边距对齐 |
| 底部固定提交按钮 | 48–52px + 安全区 | 拇指可达 |

**底部固定提交按钮要额外注意**：它必须叠加 `env(safe-area-inset-bottom)`，
且要处理键盘弹出（见主 SKILL.md 第 6 步）。

## 六、检查清单

- [ ] 没有使用 `type="number"`
- [ ] 手机号 `type="tel"`，验证码 `inputmode="numeric"` + `pattern`
- [ ] 金额用 `inputmode="decimal"`（能打出小数点）
- [ ] 每个字段的 `autocomplete` 已配置
- [ ] 登录页用 `current-password`，注册页用 `new-password`
- [ ] 验证码字段有 `autocomplete="one-time-code"`
- [ ] 输入框字号 ≥ 16px
- [ ] 输入框高度 44–48px
- [ ] 有 `maxlength` 限制超长输入
- [ ] `enterkeyhint` 已按字段位置设置
- [ ] 表单加 `novalidate`，避免浏览器原生气泡与自定义提示冲突
