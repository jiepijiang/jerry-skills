---
name: "wechat-h5-guide"
description: "在微信内置浏览器里开发或调试 H5 时使用：WebView 差异、分享与授权签名、标题与状态栏、页面栈返回、支付回调与真机调试。"
version: "1.0.0"
license: "MIT"
author: "Skill Hub"
category: ui
tags: ["H5 移动端", "微信 WebView", "JS-SDK", "分享配置", "微信授权", "页面栈"]
---

# 微信内 H5 开发规范

微信内置浏览器（iOS 用 WKWebView，Android 用 XWeb 内核）是一套**定制过的运行环境**：
它有自己的一套 JS-SDK、自己的一套限制、以及一整套「在别处能跑、在微信里不行」的行为。
本技能列出必须提前知道的坑与对应的写法。

## 何时使用

- 页面要在微信里打开（活动页、公众号文章内嵌页、企业应用）
- 分享出去的卡片标题/图片不对、或链接被微信拦截
- 需要微信授权登录（获取 openid / 用户信息）或 JSAPI 支付
- SPA 路由切换后分享配置失效
- 返回上一页时页面状态错乱、或返回层级不对
- 需要真机调试微信里的问题

## 核心规则

1. **先用 UA 判断环境，但不要用 UA 判断内核能力**。
   `navigator.userAgent.includes('MicroMessenger')` 判断是否在微信内；
   小程序 web-view 里会额外包含 `miniProgram`。
   但**内核能力必须用特性检测**（`'IntersectionObserver' in window`），
   因为微信的 XWeb 内核版本与微信版本不是一一对应，UA 里也拿不到真实 Chromium 版本。

2. **JS-SDK 签名用的 URL 必须是「当前页面去掉 `#` 之后的完整 URL」，
   且 iOS 与 Android 的取值时机不同**。
   - iOS（WKWebView）：必须用**进入页面时**的 URL（`location.href` 在 `history.pushState` 之后变化，但 WKWebView 传给微信的仍是首次 URL）。
   - Android：用**当前** `location.href`。
   - SPA 里每次路由变化都要重新 `wx.config`，且 iOS 要缓存首次 URL。

   这是微信 H5 最高频的问题：`invalid signature`。

3. **分享内容只能由用户主动点右上角菜单触发**，无法用代码自动弹出分享面板。
   `updateAppMessageShareData` / `updateTimelineShareData` 只是**预设**分享内容。
   任何「点按钮自动分享」的需求都不成立。

4. **iOS 微信里改 `document.title` 不生效**（标题只在页面加载时读取一次）。
   只能靠 `history.replaceState` 配合首次加载时设定，或接受 iOS 上标题不更新。
   Android 微信里 `document.title` 可以正常更新。

5. **页面栈有上限，SPA 里用 `replace` 而不是 `push` 做中间页**。
   微信 WebView 的页面栈深度有限（iOS 侧实测约 10 层），
   超过后返回行为异常（可能直接退出到聊天窗口）。

6. **微信内不能跳转外部 App（除白名单），也不能用 `window.open` 开新窗口**。
   微信 7.0.9 之后屏蔽了大部分 scheme 跳转。
   引导用户「在浏览器中打开」只能靠右上角菜单，代码无法直接调起。

7. **重要数据不要只存 `localStorage`**。
   iOS 上 WKWebView 的存储会在系统存储紧张时被清理，且微信版本升级、用户清理缓存都会清空。
   登录态、表单草稿必须同时有服务端备份或 cookie（带 `SameSite=None; Secure`）。

## 怎么做

### 第 1 步：环境判断与初始化

```js
export const ua = navigator.userAgent
export const isWeChat = /MicroMessenger/i.test(ua)
export const isMiniProgram = /miniProgram/i.test(ua)
export const isIOS = /iPhone|iPad|iPod/i.test(ua) && !/Windows/i.test(ua)
export const wechatVersion = (ua.match(/MicroMessenger\/([\d.]+)/i) || [])[1] || ''

// 首次进入的 URL —— iOS 签名必须用这个
export const entryUrl = location.href.split('#')[0]
```

在 `index.html` 的 `<head>` 里最早执行并挂到 `window` 上，
避免路由库先改了 URL 导致拿不到入口地址。

### 第 2 步：JS-SDK 接入

```html
<script src="https://res.wx.qq.com/open/js/jweixin-1.6.0.js"></script>
```

```js
async function initWxSdk() {
  const url = isIOS ? entryUrl : location.href.split('#')[0]
  const { appId, timestamp, nonceStr, signature } = await fetch(
    `/api/wx/jsapi-sign?url=${encodeURIComponent(url)}`
  ).then((r) => r.json())

  wx.config({
    debug: false,
    appId, timestamp, nonceStr, signature,
    jsApiList: ['updateAppMessageShareData', 'updateTimelineShareData',
                'chooseWXPay', 'getLocation', 'previewImage'],
  })
  wx.ready(() => setShare())
  wx.error((res) => console.error('wx.config 失败', res))
}

function setShare() {
  const data = {
    title: '活动标题（≤ 20 字）',
    desc: '一句话描述（≤ 40 字）',
    link: location.href.split('#')[0],
    imgUrl: 'https://cdn.example.com/share-300.png',  // ≥ 300×300
  }
  wx.updateAppMessageShareData({ ...data, success() {} })
  wx.updateTimelineShareData({ title: data.title, link: data.link, imgUrl: data.imgUrl })
}
```

签名服务端要点（这几条错了就是 `invalid signature`）：
1. 用 `jsapi_ticket`（不是 `access_token`）参与签名。
2. 签名字符串：`jsapi_ticket=xxx&noncestr=xxx&timestamp=xxx&url=xxx`，
   参数名**全小写**、按字典序排列、`url` 不带 `#` 及其后内容。
3. `jsapi_ticket` 有效期 7200s，必须服务端缓存（微信有调用频率限制）。
4. 前端传的 `url` 必须与最终参与签名的一致，**不要在前端做 URL 归一化**，
   把原始 URL 原样传给服务端。

### 第 3 步：SPA 路由切换后重新配置

路由变化后重新调用 `initWxSdk()`（内部已处理 iOS / Android 的 URL 差异）。
注意：`wx.config` 在同一页面重复调用是允许的，但**签名 URL 必须与本次传入的一致**。
不要为了「省一次请求」缓存签名结果 —— Android 上 URL 变了签名就失效。

### 第 4 步：微信授权登录

```js
const code = new URLSearchParams(location.search).get('code')
if (!code) {
  const redirect = encodeURIComponent(location.href.split('#')[0])
  location.replace(
    `https://open.weixin.qq.com/connect/oauth2/authorize?appid=${APPID}` +
    `&redirect_uri=${redirect}&response_type=code&scope=snsapi_base&state=STATE#wechat_redirect`
  )
} else {
  await fetch(`/api/wx/login?code=${code}`)   // 必须服务端换 openid
  history.replaceState(null, '', location.pathname + location.hash)
}
```

关键点：
- **`code` 只能用一次，5 分钟有效**。刷新页面时会带着旧 code，必须用 `replaceState` 清掉，
  否则第二次请求会失败并陷入循环。
- `redirect_uri` 必须 URL encode，且域名必须在公众号后台配置过（否则报 `redirect_uri 参数错误`）。
- `snsapi_base` 静默、`snsapi_userinfo` 弹窗。**能用 base 就不要用 userinfo** ——
  每次弹授权页会显著降低转化。
- `state` 参数用于防 CSRF，必须回传校验。授权必须在**微信内**发起。

### 第 5 步：JSAPI 支付

```js
async function pay(orderId) {
  const p = await fetch(`/api/pay/prepay?orderId=${orderId}`).then((r) => r.json())
  // p 由服务端调用统一下单接口得到，字段如下
  wx.chooseWXPay({
    timestamp: p.timeStamp,
    nonceStr: p.nonceStr,
    package: p.package,       // 'prepay_id=xxx'
    signType: p.signType,     // 'RSA'（V3）或 'MD5'（V2）
    paySign: p.paySign,
    success() { location.replace(`/pay/result?orderId=${orderId}`) },
    cancel() { /* 用户取消，留在原页并给提示 */ },
    fail(res) { /* 失败：展示原因，提供重试 */ },
  })
}
```

要点：
- **不要再用 `WeixinJSBridge.invoke('getBrandWCPayRequest')`**，
  老 WeixinJSBridge 已停止维护，统一走 JSSDK 的 `wx.chooseWXPay`。
- `paySign` 必须服务端算（涉及商户私钥）。
- 支付结果**以服务端回调为准**，前端 `success` 只代表用户完成支付操作，
  不代表订单已支付成功。结果页要轮询订单状态，不要直接显示「支付成功」。
- 支付中转页用 `location.replace`，避免用户返回到支付页重复下单。
- 用户 `cancel` 是正常路径，不要报错弹窗，给个轻提示即可。

### 第 6 步：页面栈与返回

中间页（授权、支付、loading 跳转）一律用 `location.replace('/next')`；
需要「返回上一步」的业务用 `history.replaceState({ step: 2 }, '', '?step=2')` 模拟，
避免污染页面栈。

微信返回行为：
- 微信左上角「返回」和系统返回键都走 `history.back()`。
- 如果栈里只剩当前页，返回会**直接退出 WebView 回到聊天窗口**。
- SPA 里如果用了 hash 路由，`history.back()` 会先在 hash 间跳转，
  用户会感觉「返回没退出去」——这是正常的，但要在设计上避免产生大量 hash 历史。
- 需要「拦截返回」时（如未保存的表单），只能监听 `popstate` 再 `history.pushState` 推回去，
  且必须二次确认才放行，否则用户会被困在页面里出不去。

### 第 7 步：真机调试

| 平台 | 方法 |
| --- | --- |
| iOS 微信 | Mac + Safari「开发 → 你的 iPhone → 页面」，需在 iPhone 设置里开启「网页检查器」 |
| Android 微信 | Chrome `chrome://inspect`，需开启 USB 调试；微信需在「设置 → 帮助与反馈 → 右上角工具 → 打开 X5 调试」 |
| 通用 | 引入 `vconsole`（仅测试环境），在页面右下角看 console 与 network |
| 公众号网页调试 | 微信开发者工具 → 公众号网页 → 输入 URL（注意：这不是真实微信内核，不能完全替代真机） |

```js
// vConsole 只在非生产环境加载
if (import.meta.env.DEV) {
  const { default: VConsole } = await import('vconsole')
  new VConsole()
}
```

### 第 8 步：样式与状态栏

```css
.full { height: 100dvh; }                    /* 不要用 100vh */
body { -webkit-text-size-adjust: 100%; }     /* 阻止微信字体大小设置影响字号 */
```

- 微信客户端「设置 → 通用 → 字体大小」会改变 WebView 的默认字号，
  **用 `rem` 且根字号基于 `vw` 的页面会被放大到错乱**。
  对策：关键文字用 px，或加 `-webkit-text-size-adjust: 100%`。
- 微信 iOS 顶部没有额外安全区（`env(safe-area-inset-top)` 为 0），
  页面不要再自己加 44px 顶部留白。
- 微信内的 `<video>` 默认全屏播放。需要内联播放要同时加
  `playsinline` / `webkit-playsinline` / `x5-playsinline` 三个属性。

## 检查清单

- [ ] 已用 `MicroMessenger` 判断环境，能力判断用特性检测
- [ ] JS-SDK 签名 URL 在 iOS 用入口 URL、Android 用当前 URL
- [ ] 服务端签名字符串参数名小写、字典序、URL 不含 `#`
- [ ] `jsapi_ticket` 服务端缓存 7200s
- [ ] SPA 路由变化后重新 `wx.config`
- [ ] 分享缩略图 ≥ 300×300，标题 ≤ 20 字，不指望代码自动弹分享面板
- [ ] 授权 `code` 用后立即 `replaceState` 清除
- [ ] `redirect_uri` 已在公众号后台配置且已 URL encode
- [ ] 授权用 `snsapi_base`（除非确实需要用户信息）
- [ ] 支付走 `wx.chooseWXPay`，未使用废弃的 `WeixinJSBridge`
- [ ] 支付结果以服务端回调为准，前端轮询订单状态
- [ ] 中间页（授权/支付/loading）用 `location.replace`
- [ ] 关键数据不只存 `localStorage`（iOS 会被清理）
- [ ] 视频加了 `playsinline` / `webkit-playsinline` / `x5-playsinline`
- [ ] 在 iOS 微信 + Android 微信真机各测一遍，调试通道已验证可用

## 常见错误

| 错误做法 | 为什么错 | 正确做法 |
| --- | --- | --- |
| 用 `location.href`（含 `#`）去签名 | 签名串不匹配，报 `invalid signature` | 用 `location.href.split('#')[0]` |
| iOS 上路由变化后用新 URL 重新签名 | WKWebView 传给微信的仍是入口 URL，签名失效 | iOS 固定用入口 URL |
| 前端自己拼接/归一化签名 URL | 与服务端算的 URL 不一致 | 原样把 URL 传给服务端 |
| 每次路由变化都重新拉 `jsapi_ticket` | 微信有频率限制，会被封 | 服务端缓存 7200s |
| 刷新页面时保留 URL 里的 `code` | code 只能用一次，第二次请求失败陷入循环 | 用后 `replaceState` 清除 |
| 默认用 `snsapi_userinfo` | 每次弹授权页，转化率下降 | 优先 `snsapi_base` |
| 用 `WeixinJSBridge.invoke('getBrandWCPayRequest')` | 老接口已停止维护 | 用 `wx.chooseWXPay` |
| 前端 `success` 就显示「支付成功」 | 前端回调不代表支付成功 | 轮询服务端订单状态 |
| 授权/支付中转页用 `push` | 页面栈变深，返回行为错乱 | 用 `location.replace` |
| 登录态只存 `localStorage` | iOS WKWebView 存储会被清理，用户莫名掉线 | 服务端 session / cookie 兜底 |
| 用 `100vh` 做全屏 | 微信 iOS 上被地址栏/工具栏遮挡 | 用 `100dvh` |
| 依赖 UA 判断是否支持某 API | XWeb 内核版本与微信版本不对应 | 特性检测 |
| 只在微信开发者工具里测 | 那不是真实微信内核，问题测不出来 | 真机 + Safari / chrome://inspect |
| `<video>` 只写 `playsinline` | Android XWeb 需要额外的 `x5-playsinline` | 三个属性都写 |
## 参考

- 需要 JS-SDK 各接口的完整参数、签名服务端实现、授权与支付的时序图时，读 `references/wechat-jsapi.md`
- 需要「微信里做不了什么」的完整能力清单，以及各类真机调试通道的详细步骤时，读 `references/wechat-limits.md`
