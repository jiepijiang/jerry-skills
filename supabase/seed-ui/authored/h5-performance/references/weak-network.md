# 弱网与离线降级矩阵

## 一、网络分档与对应策略

| 档位 | RTT | 下载 | 典型场景 | 策略 |
| --- | --- | --- | --- | --- |
| 优 | < 100ms | > 10Mbps | WiFi、城市 4G/5G | 正常 |
| 良 | 100–300ms | 2–10Mbps | 一般 4G | 正常 |
| 慢 | 300–600ms | 800Kbps–2Mbps | Slow 4G、电梯口 | 图片降档、延后非关键请求 |
| 差 | 600–1200ms | 200–800Kbps | 3G、地铁 | 关图片、关动画、减并发 |
| 极差 | > 1200ms | < 200Kbps | 2G、地下车库 | 纯文本、单请求串行 |

判定方式（按优先级）：

```js
function getNetLevel() {
  // 1. 用户主动省流
  if (navigator.connection?.saveData) return 'poor'
  // 2. Network Information API（Chrome / Android；iOS 不支持）
  const et = navigator.connection?.effectiveType
  if (et === 'slow-2g' || et === '2g') return 'poor'
  if (et === '3g') return 'bad'
  // 3. 用实测请求耗时兜底（iOS 只能靠这个）
  return measuredRtt > 800 ? 'bad' : 'good'
}
```

iOS 不支持 Network Information API，只能用**最近几次请求的实测 RTT** 来推断。
实现方式：记录最近 5 次请求的耗时，取中位数，> 800ms 判定为慢网。

## 二、降级矩阵

| 能力 | 优/良 | 慢 | 差 | 极差 |
| --- | --- | --- | --- | --- |
| 首屏图片 | 全尺寸 AVIF | 降一档 | 低清占位（LQIP） | 隐藏，显示色块 + alt |
| 列表缩略图 | 正常加载 | 正常 | 懒加载 + 降档 | 隐藏 |
| 视频 | 可自动播放 | 不自动播放 | 只显示封面 | 隐藏 |
| 动画/过渡 | 全部 | 全部 | 关闭装饰动画 | 全部关闭 |
| 字体 | web font | web font | 系统字体 | 系统字体 |
| 骨架屏扫光 | 有 | 有 | 无 | 无 |
| 预加载 | 开启 | 开启 | 关闭 | 关闭 |
| 请求并发 | 6 | 4 | 2 | 1（串行） |
| 数据预取 | 下一页预取 | 关闭 | 关闭 | 关闭 |
| 埋点上报 | 实时 | 实时 | 批量 30s | 批量 + 只报错误 |

CSS 层实现：

```css
html[data-net="slow"] .decor-anim { animation: none; }
html[data-net="bad"] img:not([data-critical]) { visibility: hidden; }
html[data-net="bad"] video { display: none; }
html[data-net="poor"] .non-essential { display: none; }
```

## 三、请求策略

### 超时

| 请求类型 | 超时 | 理由 |
| --- | --- | --- |
| 关键接口（首屏数据） | 8s | 超过用户大概率已离开 |
| 普通接口 | 10s | 平衡误判与等待 |
| 上报/埋点 | 3s | 失败就丢，不重试 |
| 图片/静态资源 | 15s | 浏览器默认行为，不必干预 |

超时小于 5s 会在慢网下大量误判失败（请求其实在正常进行），
超时大于 15s 用户早就退出了。

### 重试

```js
// 指数退避 + 抖动，避免重试风暴
const delay = Math.min(8000, 1000 * 2 ** attempt) * (0.5 + Math.random() * 0.5)
```

- 最多重试 2–3 次。
- 只对**幂等**请求重试（GET、带幂等键的写操作）。支付、下单不要自动重试。
- 加随机抖动（jitter）：不加的话所有客户端会在同一时刻同时重试，把服务打垮。
- 网络恢复时（`online` 事件）可以触发一次补发，但要限制频率。

### 请求合并与优先级

```html
<link rel="preload" as="fetch" href="/api/boot" crossorigin>
```

```js
// 关键请求先发，非关键延后
await fetch('/api/boot', { priority: 'high' })
// 次屏数据等首屏渲染完再请求
requestIdleCallback(() => prefetch('/api/secondary'))
```

`fetch` 的 `priority` 参数在 Chrome 支持，Safari 会忽略（不报错，安全降级）。

## 四、加载态与提示文案

弱网下**文案比动画重要**。用户需要知道「系统还在工作」而不是「系统坏了」。

| 等待时长 | 表现 | 文案 |
| --- | --- | --- |
| 0–200ms | 无变化 | — |
| 200ms–3s | 骨架屏 | — |
| 3–10s | 骨架屏 + 提示 | 「网络较慢，正在加载…」 |
| > 10s | 错误态 + 重试 | 「加载失败，请检查网络后重试」 |
| 失败且可重试 | 错误态 | 「加载失败」+「重试」按钮 |
| 无网络 | 离线态 | 「当前无网络连接」+「查看已缓存内容」 |

文案规则：
- 不要写「系统繁忙，请稍后再试」—— 用户不知道要等多久。
- 有重试按钮的，按钮文案写「重试」而不是「确定」。
- 断网时用 `navigator.onLine` + `online`/`offline` 事件实时更新提示条。

```js
window.addEventListener('offline', () => showBanner('当前无网络连接'))
window.addEventListener('online', () => { hideBanner(); retryPending() })
```

注意 `navigator.onLine === true` **不代表真的能上网**（连上路由器但没外网），
所以只能用于「明确离线」的判断，不能作为「网络正常」的依据。

## 五、离线能力（Service Worker）

最小可用方案：缓存「应用壳」，离线时至少能打开并显示缓存内容。

```js
const CACHE = 'app-shell-v3'
const SHELL = ['/', '/index.html', '/assets/main.css', '/assets/main.js', '/offline.html']

self.addEventListener('install', (e) => {
  e.waitUntil(caches.open(CACHE).then((c) => c.addAll(SHELL)).then(() => self.skipWaiting()))
})

self.addEventListener('activate', (e) => {
  e.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(keys.filter((k) => k !== CACHE).map((k) => caches.delete(k)))
    ).then(() => self.clients.claim())
  )
})

self.addEventListener('fetch', (e) => {
  const { request } = e
  if (request.method !== 'GET') return
  // 接口：网络优先，失败读缓存
  if (request.url.includes('/api/')) {
    e.respondWith(
      fetch(request).then((res) => {
        const copy = res.clone()
        caches.open(CACHE).then((c) => c.put(request, copy))
        return res
      }).catch(() => caches.match(request).then((r) => r || Response.error()))
    )
    return
  }
  // 静态资源：缓存优先
  e.respondWith(caches.match(request).then((r) => r || fetch(request)))
})
```

要点：
1. **缓存名带版本号**，`activate` 时清理旧版本。
2. 接口数据缓存必须带**过期时间**，否则用户会看到一周前的订单。
3. 不要缓存 `POST` 请求。
4. Service Worker 只在 HTTPS 下工作（`localhost` 例外）。
5. 更新 SW 后要提示用户刷新（`registration.waiting` + 「有新版本，点击刷新」）。

## 六、测试方法

1. **DevTools Network 面板**：`Slow 4G` / `Offline` 预设。
2. **DevTools Performance**：`4x CPU slowdown`。
3. **真机 + 弱网模拟**：Android 开发者选项里有限速；iOS 用 Network Link Conditioner。
4. **必测场景**：
   - 首屏请求超时后重试成功
   - 加载到一半断网（页面不崩，显示离线提示）
   - 恢复网络后数据能自动刷新
   - 弱网下滚动长列表不掉帧
   - 双击提交按钮只产生一次请求

## 七、检查清单

- [ ] 网络分档判定已实现，且 iOS 有 RTT 兜底
- [ ] 降级矩阵的每一档都有对应的 CSS 类与开关
- [ ] 关键请求超时 8s、普通 10s、埋点 3s
- [ ] 重试用指数退避 + 随机抖动，上限 2–3 次
- [ ] 非幂等请求（支付、下单）不自动重试
- [ ] 3s / 10s 两档等待文案已定义
- [ ] `offline` / `online` 事件已监听，有提示条
- [ ] 不把 `navigator.onLine === true` 当作网络正常
- [ ] Service Worker 缓存名带版本，旧缓存会被清理
- [ ] 接口缓存有过期时间
- [ ] 弱网全场景在真机上跑过一遍
