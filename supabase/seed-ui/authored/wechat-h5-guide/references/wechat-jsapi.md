# 微信 JS-SDK、授权与支付实现细则

## 一、JS-SDK 引入与配置

```html
<script src="https://res.wx.qq.com/open/js/jweixin-1.6.0.js"></script>
```

`1.6.0` 是当前线上通用版本。**不要引 `jweixin-1.0.0.js` 这类老版本**，
它们不包含 `updateAppMessageShareData` 等新接口。

```js
wx.config({
  debug: false,                 // 真机调试时改 true，会 alert 出每一步
  appId: 'wx…',
  timestamp: 1730000000,        // 秒级时间戳，字符串或数字都可以
  nonceStr: 'abc123',
  signature: '…',
  jsApiList: ['updateAppMessageShareData', 'updateTimelineShareData'],
  openTagList: ['wx-open-launch-weapp'],   // 需要开放标签时才填
})
```

`jsApiList` 只写真正用到的接口。写全量会让 `wx.config` 变慢，
且未申请的接口在部分场景下会触发 `permission denied`。

## 二、签名算法（服务端实现）

```
参与签名的四个参数（参数名必须全小写）：
  jsapi_ticket
  noncestr
  timestamp
  url

按字段名字典序拼接成：
  jsapi_ticket=RANDOMTICKET&noncestr=Wm3WZYTPz0wzccnW&timestamp=1414587457&url=http://mp.weixin.qq.com?params=value

对该字符串做 SHA1，得到 signature（十六进制小写）。
```

Node.js 实现：

```js
import { createHash } from 'node:crypto'

export function jsapiSignature({ ticket, noncestr, timestamp, url }) {
  const raw = `jsapi_ticket=${ticket}&noncestr=${noncestr}&timestamp=${timestamp}&url=${url}`
  return createHash('sha1').update(raw, 'utf8').digest('hex')
}
```

四条最容易错的点：

1. **参数名全小写**。写成 `jsapi_ticket` 而不是 `jsapiTicket`，
   写成 `noncestr` 而不是 `nonceStr`。`wx.config` 里的字段名才是驼峰，两者不同。
2. **`url` 不含 `#` 及其后内容**，也不要做任何 URL 编码/解码、去端口、补斜杠。
   前端传什么，服务端就用什么。
3. **`jsapi_ticket` 与 `access_token` 不同**。签名用 ticket，
   ticket 通过 `https://api.weixin.qq.com/cgi-bin/ticket/getticket?type=jsapi&access_token=…` 获取。
4. **ticket 有效期 7200 秒，必须缓存**。每次请求都去取会被限流。
   缓存时提前 300 秒过期（`expires_in - 300`），并做好并发去重。

```js
// 带并发去重的 ticket 缓存
let cache = { ticket: '', expireAt: 0 }
let inflight = null

export async function getTicket() {
  if (cache.ticket && Date.now() < cache.expireAt) return cache.ticket
  if (inflight) return inflight
  inflight = (async () => {
    const { ticket, expires_in } = await fetchTicketFromWechat()
    cache = { ticket, expireAt: Date.now() + (expires_in - 300) * 1000 }
    inflight = null
    return ticket
  })()
  return inflight
}
```

## 三、常见错误码对照

| 现象 / 报错 | 原因 | 处理 |
| --- | --- | --- |
| `invalid signature` | 签名串不匹配（URL 含 `#`、参数名大小写、URL 编码差异） | 用 `debug: true` 打印，逐字符比对 |
| `invalid url domain` | 当前域名未加入「JS 接口安全域名」 | 公众号后台配置，需上传校验文件 |
| `permission denied` | 该接口未在 `jsApiList` 中声明，或公众号无该接口权限 | 补进 `jsApiList`，检查公众号类型 |
| `40001 invalid credential` | `access_token` 失效或被别处刷新覆盖 | 全局统一一处获取 token，缓存 7000s |
| `40029 invalid code` | 授权 code 无效 | 检查 appid 是否一致 |
| `40163 code been used` | code 已被使用 | 用后立即 `replaceState` 清除 |
| `redirect_uri 参数错误` | 回调域名未配置，或未 URL encode | 后台配置授权回调域名 |
| 分享配置不生效但无报错 | 用户在 `wx.ready` 之前就点了菜单 | 页面加载即初始化，不要等用户交互 |

## 四、分享接口

```js
wx.ready(() => {
  const shareData = {
    title: '标题（建议 ≤ 20 字，超出会被截断）',
    desc: '描述（建议 ≤ 40 字，iOS 上部分场景不显示）',
    link: location.href.split('#')[0],   // 不要带自定义 query 里的一次性参数
    imgUrl: 'https://cdn.example.com/share.png',
  }

  // 发送给朋友
  wx.updateAppMessageShareData({ ...shareData, success: () => {} })
  // 分享到朋友圈（朋友圈只有 title / link / imgUrl 生效，desc 会被忽略）
  wx.updateTimelineShareData({
    title: shareData.title, link: shareData.link, imgUrl: shareData.imgUrl,
  })
})
```

缩略图要求：
- 尺寸 **≥ 300×300px**，小于这个值部分机型不显示图。
- 比例接近正方形（1:1）最稳，长图会被裁切。
- 大小建议 < 128KB，使用 HTTPS 且域名可公开访问（不能是内网地址）。
- 图片有防盗链时微信抓不到，需要允许 `Referer: https://mp.weixin.qq.com` 或留空。

`link` 的坑：如果 `link` 里带了当前用户的一次性参数（如 `?code=xxx`），
别人点开这个链接会带着无效的 code，可能触发授权异常。
**分享的 link 要清理掉敏感/一次性参数**。

## 五、授权登录时序

```
用户访问 H5
  ↓ 无 code
跳转 open.weixin.qq.com/connect/oauth2/authorize?...
  ↓ 微信回调 redirect_uri?code=XXX&state=STATE
H5 拿到 code
  ↓ 前端 POST /api/wx/login { code }
服务端 GET snsapi/oauth2/access_token?appid&secret&code
  ↓ 返回 { access_token, openid, [unionid] }
  ↓ snsapi_userinfo 时再 GET snsapi/userinfo?access_token&openid
服务端下发自己的 session（cookie / token）
  ↓
前端 history.replaceState 清掉 code
```

两种 scope 对比：

| scope | 是否弹窗 | 能拿到 | 适用 |
| --- | --- | --- | --- |
| `snsapi_base` | 否（静默） | openid、unionid | 登录、绑定、绝大多数场景 |
| `snsapi_userinfo` | 是 | 昵称、头像、地区 | 只有首次要展示用户资料时 |

如果同时有公众号和小程序，用 `unionid` 做用户唯一标识（需绑定到同一开放平台账号），
只用 `openid` 会导致同一个人在两处被当成两个用户。

## 六、JSAPI 支付时序

```
前端 POST /api/pay/prepay { orderId }
  ↓ 服务端调用「JSAPI 下单」（v3 接口 /v3/pay/transactions/jsapi）
  ↓ 服务端用商户私钥生成 paySign（RSA-SHA256）
返回 { timeStamp, nonceStr, package: 'prepay_id=xxx', signType: 'RSA', paySign }
  ↓
前端 wx.chooseWXPay({...})
  ↓ 用户支付
微信服务端 → 商户服务端 回调通知（异步）
  ↓ 商户服务端更新订单状态
前端轮询 GET /api/order/status 直到 success / fail
  ↓
location.replace('/pay/result?orderId=xxx')
```

要点：

1. **`signType` 用 `RSA`**（APIv3）。老 APIv2 的 `MD5` 已不推荐。
   如果服务端还在用 v2，`signType` 是 `MD5` 且签名方式不同，前后端必须一致。
2. **前端 `success` 回调 ≠ 支付成功**。它只表示用户完成了支付操作。
   必须以服务端收到微信回调后的订单状态为准。
3. **回调必须做幂等**。微信会重复通知直到收到成功响应，
   同一笔订单可能收到多次回调。
4. **轮询策略**：1s 间隔，最多 10 次；超时显示「支付结果确认中，请稍后在订单列表查看」。
   不要无限轮询。
5. **用户取消（`cancel`）是正常路径**，不要弹错误提示。
6. 支付页不要做成可返回的中间页，否则用户返回后重复下单。

## 七、其他常用接口

```js
// 预览图片（点击放大，支持左右切换）
wx.previewImage({ current: url, urls: [url1, url2] })

// 获取地理位置（需公众号后台开通，且用户会看到授权提示）
wx.getLocation({
  type: 'gcj02',    // 必填，wgs84 只用于计算距离
  success: ({ latitude, longitude }) => {},
})

// 扫一扫
wx.scanQRCode({ needResult: 1, scanType: ['qrCode', 'barCode'], success: ({ resultStr }) => {} })
```

`wx.getLocation` 在微信 8.0 之后需要**在公众号后台配置「地理位置」权限**，
否则返回 `permission denied`。且定位精度有限，不要用于导航级场景。

## 八、检查清单

- [ ] `jweixin-1.6.0.js` 已引入（非老版本）
- [ ] `jsApiList` 只包含实际使用的接口
- [ ] 签名字符串参数名全小写、字典序、URL 不含 `#`
- [ ] `jsapi_ticket` 有缓存（`expires_in - 300`）且并发去重
- [ ] `access_token` 全局单点获取，避免相互覆盖
- [ ] 分享缩略图 ≥ 300×300、< 128KB、HTTPS、无防盗链
- [ ] 分享 `link` 已清除一次性参数
- [ ] 朋友圈分享未依赖 `desc`
- [ ] 授权 `code` 用后立即清除
- [ ] 用户唯一标识优先使用 `unionid`
- [ ] 支付 `signType` 前后端一致（RSA / MD5）
- [ ] 支付结果以服务端回调为准，回调幂等
- [ ] 轮询有上限（如 10 次），超时有兜底文案
- [ ] `debug: true` 只在测试环境开启
