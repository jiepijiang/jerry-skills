# 深层链接（Deep Link）落地细节

## 三种链接类型，能力不同

| 类型 | 格式 | 未装 App 时 | 需要配置 |
| --- | --- | --- | --- |
| URI Scheme | `myapp://orders/123` | 报错或静默失败 | manifest / Info.plist 注册 scheme |
| Universal Link（iOS） | `https://ex.com/orders/123` | 直接开网页 | `apple-app-site-association` |
| App Link（Android） | `https://ex.com/orders/123` | 直接开网页 | `assetlinks.json` |

**优先用 HTTPS 链接**。URI Scheme 的问题是：
任何 App 都能注册同名 scheme，存在被劫持的风险，且无法回落到网页。

## iOS：Universal Link

1. 在 `https://ex.com/.well-known/apple-app-site-association` 放 JSON（**无扩展名、Content-Type: application/json**）：

```json
{
  "applinks": {
    "details": [
      {
        "appIDs": ["TEAMID.com.example.app"],
        "components": [
          { "/": "/orders/*", "comment": "订单详情" },
          { "/": "/share/*",  "comment": "分享页" }
        ]
      }
    ]
  }
}
```

2. Xcode → Signing & Capabilities → 添加 Associated Domains：`applinks:ex.com`
3. 处理回调（SwiftUI）：

```swift
.onOpenURL { url in
  router.handle(url)
}
.onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
  guard let url = activity.webpageURL else { return }
  router.handle(url)
}
```

注意：
- AASA 文件由 Apple 的 CDN 缓存，**改完可能要等几小时**，测试时用开发者模式或 `?mode=developer`
- 链接必须和用户实际点击的域名完全一致（`www` 和裸域算两个域名）
- 用户手动在地址栏输入 URL **不会**触发 Universal Link（Apple 有意为之），
  测试要用备忘录或信息里的可点击链接

## Android：App Link

1. 在 `https://ex.com/.well-known/assetlinks.json` 放：

```json
[{
  "relation": ["delegate_permission/common.handle_all_urls"],
  "target": {
    "namespace": "android_app",
    "package_name": "com.example.app",
    "sha256_cert_fingerprints": ["AA:BB:CC:..."]
  }
}]
```

2. manifest 里声明，关键是 `android:autoVerify="true"`：

```xml
<intent-filter android:autoVerify="true">
  <action android:name="android.intent.action.VIEW" />
  <category android:name="android.intent.category.DEFAULT" />
  <category android:name="android.intent.category.BROWSABLE" />
  <data android:scheme="https" android:host="ex.com" android:pathPrefix="/orders" />
</intent-filter>
```

3. 验证：`adb shell pm get-app-links com.example.app` 应显示 `verified`。
   调试签名和发布签名的 SHA-256 不同，**两个指纹都要放进去**，否则测试包能开、线上包不能开。

Compose 里读 intent：

```kotlin
val uri = (LocalContext.current as Activity).intent?.data
LaunchedEffect(uri) { uri?.let { router.handle(it) } }
```
`singleTop` + `onNewIntent` 要处理，否则 App 已在前台时点链接不会跳转。

## 冷启动 / 热启动两条路径都要处理

- **冷启动**：进程被杀，链接在 `launchOptions` / `intent.data` 里
- **热启动**：App 在后台，链接在 `onNewIntent` / `onOpenURL` 里

只处理其中一条是常见 bug：测试时 App 总在后台所以看起来正常，用户冷启动时链接失效。

## 延迟深链（Deferred Deep Link）

场景：用户没装 App，点分享链接 → 落到网页 → 引导下载 → 装完打开，
**期望直接进到分享的那个页面**。

实现方式：
1. **自建**：网页上把 `?dl_target=/share/abc` 写进 cookie / localStorage，
   同时带上设备指纹（IP + UA + 时区），安装后首次启动请求服务端匹配。
   准确率有限，通常 60–85%，隐私政策收紧后更低。
2. **第三方**：Firebase Dynamic Links（已于 2025 年停服）、AppsFlyer、Branch、Adjust 的
   OneLink / Deep Link 产品。选型时确认它还活着。
3. **折中方案（推荐）**：网页上直接给一个「复制口令」或「打开 App 后粘贴」的兜底路径，
   不追求 100% 自动匹配。用户体验损失小，工程量小一个数量级。

## 路由解析的写法

```ts
// 白名单 + 参数校验，不要把 URL 直接映射到任意页面
const ROUTES: Record<string, (p: string[]) => NavTarget> = {
  'orders/:id':      ([id]) => ({ screen: 'OrderDetail', params: { id: assertId(id) } }),
  'share/:token':    ([token]) => ({ screen: 'ShareLanding', params: { token } }),
  'invite':          () => ({ screen: 'Invite' }),
}

function resolve(url: URL): NavTarget | null {
  const segs = url.pathname.split('/').filter(Boolean)
  for (const [pattern, build] of Object.entries(ROUTES)) {
    const pp = pattern.split('/')
    if (pp.length !== segs.length) continue
    const params: string[] = []
    let ok = true
    for (let i = 0; i < pp.length; i++) {
      if (pp[i].startsWith(':')) params.push(segs[i])
      else if (pp[i] !== segs[i]) { ok = false; break }
    }
    if (ok) return build(params)
  }
  return null   // 未匹配 → 首页，不要抛错
}
```

必须做的三件事：
1. **未匹配的路径回落到首页**，不要白屏或崩溃
2. **参数要校验**：`/orders/abc` 里的 `abc` 不是合法 ID 时，走错误页而不是把 `abc` 发给接口
3. **未登录时保存 `pendingRoute`**，登录成功后 `replace` 过去

## 未登录的处理

```ts
async function handle(url: URL) {
  const target = resolve(url)
  if (!target) return goHome()
  if (!isLoggedIn()) {
    pendingRoute = target          // 存起来
    return navigate('Login')       // 不要 replace，用户可能想取消
  }
  navigate(target, { replace: false })
}
```

登录成功后：
```ts
if (pendingRoute) {
  navigate(pendingRoute, { replace: true })   // replace 登录页，避免返回回登录页
  pendingRoute = null
}
```

「取消登录」时要清掉 `pendingRoute`，否则下次登录会莫名跳到上次的目标页。

## 推送与扫码

- **推送**：payload 里不要放完整 URL，放 `{"route": "/orders/123"}` 这种相对路径，
  由客户端拼 host。放完整 URL 会导致换域名时旧推送全失效。
- **扫码**：扫码得到的可能是自有链接、也可能是第三方链接。
  自有链接走路由解析，第三方链接走内置 WebView 或系统浏览器，
  但要**先做域名白名单**，否则会有开放重定向风险。

## 测试清单

- [ ] 冷启动点链接直达（iOS 从备忘录点、Android 用 `adb shell am start -a android.intent.action.VIEW -d "https://ex.com/orders/123"`）
- [ ] 热启动（App 在后台）点链接能跳转且不会新建一个 Activity 实例
- [ ] 未登录状态点链接 → 登录 → 落到目标页，返回键不回登录页
- [ ] 未匹配路径回落到首页，不白屏
- [ ] 非法参数（ID 是字符串、token 超长）走错误页
- [ ] `adb shell pm get-app-links <pkg>` 显示 verified（Android）
- [ ] 正式签名包和调试包都能唤起（两个 SHA-256 都在 assetlinks.json 里）
