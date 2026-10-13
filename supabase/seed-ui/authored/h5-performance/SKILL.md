---
name: "h5-performance"
description: "H5 移动端页面加载慢、卡顿或需要做性能验收时使用：Core Web Vitals 阈值、图片与字体优化、骨架屏出现时机、弱网降级策略。"
version: "1.0.0"
license: "MIT"
author: "Skill Hub"
category: ui
tags: ["H5 移动端", "Core Web Vitals", "图片优化", "字体加载", "骨架屏", "弱网降级"]
---

# H5 性能优化

移动端性能的判据不是「我这儿打开挺快」，而是**中端安卓机 + 4G + p75 分位**。
本技能给出可验收的数值、每项优化的取舍，以及弱网下的降级顺序。

## 何时使用

- 首屏白屏时间超过 2 秒，或被要求「过一下性能」
- 要定性能预算（performance budget）并写进 CI
- 图片体积大、列表滚动卡顿、字体加载时文字跳动
- 需要设计骨架屏 / 加载态的出现时机
- 要在弱网（地铁、电梯、2G）下仍然可用

## 核心规则

1. **四个指标按这个阈值验收（p75，移动端）**：

   | 指标 | 良好 | 需改进 | 差 | 测什么 |
   | --- | --- | --- | --- | --- |
   | FCP | ≤ 1.8s | ≤ 3.0s | > 3.0s | 第一个像素出现 |
   | LCP | ≤ 2.5s | ≤ 4.0s | > 4.0s | 最大内容块出现 |
   | CLS | ≤ 0.1 | ≤ 0.25 | > 0.25 | 布局偏移累计 |
   | INP | ≤ 200ms | ≤ 500ms | > 500ms | 交互响应延迟 |

   附加：TTFB ≤ 800ms，总阻塞时间（TBT）≤ 200ms。
   **注意 INP 已在 2024 年 3 月正式取代 FID**，还在看 FID 的监控面板要换。

2. **首屏图片绝对不要 `loading="lazy"`**。LCP 元素懒加载是最常见的自伤行为 ——
   图片要等布局完成才开始下载，LCP 直接多 500ms 以上。
   首屏图（尤其是 Hero 图）应设 `fetchpriority="high"`。

3. **图片必须同时给 `width` / `height` 或 `aspect-ratio`**。
   缺了尺寸信息，图片加载完成时会把下方内容顶下去，这是 CLS 的最大来源。

4. **图片格式按这个顺序选**：AVIF → WebP → JPEG/PNG 兜底。
   同画质下 AVIF 比 JPEG 小 50% 左右，WebP 小 25–35%。
   用 `<picture>` 让浏览器自己选，不要用 UA 判断。

5. **中文字体默认用系统字体栈，不要 web font**。
   一套中文字体的常用字子集也有 1–3MB，加载完前文字要么不显示要么用 fallback 重排。
   只有当品牌强制要求时才引入，且必须做子集化 + `unicode-range` 分包 + `font-display: swap`。

6. **骨架屏延迟 200ms 出现**。请求在 200ms 内返回时不要显示骨架 ——
   闪一下的骨架比不显示更让人感觉「卡」。
   超过 200ms 显示骨架，超过 10s 显示「网络较慢，请重试」+ 重试按钮。

7. **首屏 JS ≤ 170KB（gzip 后）**。这是移动端 4G 下能在 2.5s 内完成 LCP 的经验上限。
   超出说明首屏加载了不该加载的代码（整包路由、全量组件库、未拆分的图表库）。

## 怎么做

### 第 1 步：先测，别猜

```bash
npx lighthouse https://example.com --preset=perf --form-factor=mobile \
  --throttling.cpuSlowdownMultiplier=4 --view
```

真机测试环境必须包含：
- 中端安卓（骁龙 6xx / 天玑 700 级别），**不要用 iPhone 测**
- CPU 降速 4 倍（DevTools Performance 面板的 `4x slowdown`）
- 网络 Slow 4G（下载 1.6Mbps / 上传 750Kbps / RTT 150ms）

### 第 2 步：图片优化

```html
<picture>
  <source type="image/avif" srcset="hero-800.avif 800w, hero-1600.avif 1600w" sizes="100vw">
  <source type="image/webp" srcset="hero-800.webp 800w, hero-1600.webp 1600w" sizes="100vw">
  <img src="hero-1600.jpg" width="1600" height="900" alt="…"
       fetchpriority="high" decoding="async">
</picture>
```

要点：
1. `sizes` 必须写，否则浏览器按最大宽度下载。列表图写 `(max-width: 640px) 100vw, 320px`。
2. `srcset` 的 `w` 描述符配合 `sizes` 让浏览器自己算该下哪张。
3. 图片实际尺寸 = 显示 CSS 尺寸 × DPR，DPR 上限取 3。
   一个 100×100 的头像最多准备 300×300，给 1200×1200 是纯浪费。
4. 首屏图不 lazy，非首屏图加 `loading="lazy"`。
5. `decoding="async"` 让图片解码不阻塞主线程。
6. 用 CDN 的图片处理参数（`?w=800&fmt=avif&q=75`）而不是手工导出多份。

体积目标：

| 位置 | 上限 |
| --- | --- |
| 首屏 Hero 图 | 200KB |
| 列表缩略图 | 30KB |
| 头像 | 8KB |
| 图标 | 用 SVG 内联或图标字体，单图 < 2KB |
| 首屏全部图片合计 | 400KB |

### 第 3 步：字体

```css
:root {
  --font-sans: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto,
               "PingFang SC", "Hiragino Sans GB", "Microsoft YaHei", sans-serif;
}
body { font-family: var(--font-sans); }
```

这套栈在 iOS 上是苹方、Android 上是思源黑体/系统默认、Windows 上是微软雅黑，
**零下载、零 CLS**，中文场景下体验优于任何 web font。

如果必须用 web font：

```css
@font-face {
  font-family: "Brand";
  src: url("/fonts/brand-subset.woff2") format("woff2");
  font-display: swap;              /* 先用 fallback 显示，加载完替换 */
  unicode-range: U+4E00-9FFF;      /* 只对中文区间生效，其余走 fallback */
  size-adjust: 105%;               /* 让 fallback 与自定义字体宽度接近，减少 CLS */
  ascent-override: 90%;
}
```

`font-display` 取值对照：

| 值 | 行为 | 适用 |
| --- | --- | --- |
| `swap` | 立刻用 fallback，加载完替换 | 正文，**默认选这个** |
| `optional` | 极短等待，超时本次就用 fallback | 非关键装饰字体 |
| `fallback` | 100ms 阻塞期，之后 fallback | 折中 |
| `block` | 3s 阻塞期（文字不可见） | 几乎不要用 |

关键：**不要 preload 中文字体**。字体文件太大，preload 会抢占首屏图片的带宽，
反而让 LCP 变差。只有在字体 < 50KB 时才考虑 preload。

### 第 4 步：骨架屏与加载态

```js
const timer = setTimeout(() => root.classList.add('is-skeleton'), 200)  // 延迟 200ms
// 请求返回后：clearTimeout(timer); root.classList.remove('is-skeleton')
```

| 时长 | 表现 |
| --- | --- |
| 0–200ms | 什么都不显示（保持上次内容或空白） |
| 200ms–3s | 骨架屏 |
| 3s–10s | 骨架屏 + 弱网提示文案 |
| > 10s | 错误态 + 重试按钮 |

骨架屏的硬性要求：
- **形状必须和真实内容一致**（行数、高度、圆角都要对）。形状不对会导致加载完的瞬间「跳一下」。
- 骨架块颜色 `#f2f3f5`，不做高亮扫光动画（扫光持续占用合成线程，列表长时更明显）；
  真要做动画，用 `background-position` 而不是 `width`。
- 骨架屏本身不产生 CLS：容器高度必须固定。
- 列表骨架默认渲染 6–8 条，不要 20 条（屏幕外的骨架没意义还费渲染）。

### 第 5 步：首屏关键路径

按优先级做这几件事，收益从高到低：

1. **HTML 里内联首屏关键 CSS**（≤ 14KB），其余 CSS 异步加载：
   ```html
   <style>/* critical css */</style>
   <link rel="stylesheet" href="/main.css" media="print" onload="this.media='all'">
   ```
2. **首屏 JS 拆包**，非首屏路由用动态 `import()`。
3. **用 `<link rel="preconnect">` 提前连上关键域名**（CDN、API 域名）：
   ```html
   <link rel="preconnect" href="https://cdn.example.com" crossorigin>
   ```
   只对 2–4 个域名做，多了反而排队。
4. **SSR / 预渲染首屏**，让 HTML 里就有内容，不要等 JS 渲染出 DOM。
5. **路由级代码分割 + 组件懒加载**，图表、富文本编辑器、地图这类重库必须懒加载。

### 第 6 步：弱网降级

弱网定义（用于测试与降级判定）：

| 网络 | RTT | 下载 | 降级动作 |
| --- | --- | --- | --- |
| 4G 良好 | 50–100ms | 10Mbps+ | 无 |
| 4G 一般 | 150–300ms | 2–5Mbps | 无 |
| Slow 4G | 300–500ms | 1–1.6Mbps | 图片降质量档 |
| 3G | 500–800ms | 400Kbps | 关闭动画与视频预加载 |
| 弱网 / 2G | > 800ms | < 200Kbps | 纯文本模式、禁用图片 |

```js
// 弱网判定与降级（Chrome / Android 支持 Network Information API，iOS 不支持）
if (navigator.connection?.effectiveType === '2g' || navigator.connection?.saveData) {
  document.documentElement.classList.add('lite-mode')
}
```

```css
.lite-mode img:not([data-critical]) { display: none; }
.lite-mode video, .lite-mode .skeleton { display: none; }
```

**超时与重试**：

```js
async function request(url, { timeout = 10000, retries = 2 } = {}) {
  for (let i = 0; i <= retries; i++) {
    const ctrl = new AbortController()
    const t = setTimeout(() => ctrl.abort(), timeout)
    try {
      const res = await fetch(url, { signal: ctrl.signal })
      clearTimeout(t)
      return await res.json()
    } catch (e) {
      clearTimeout(t)
      if (i === retries) throw e
      await new Promise((r) => setTimeout(r, 1000 * 2 ** i))  // 指数退避 1s / 2s
    }
  }
}
```

超时设 8–10s：低于 5s 会在慢网下大量误判失败；高于 15s 用户早就退出了。
重试用指数退避，最多 2–3 次。

**离线壳**：用 Service Worker 缓存 HTML 壳 + 关键 CSS/JS，
离线时显示缓存页面 + 「当前离线」提示，比浏览器自带的错误页体验好一个量级。

## 检查清单

- [ ] Lighthouse 移动端（4x CPU 降速）LCP ≤ 2.5s、CLS ≤ 0.1、INP ≤ 200ms
- [ ] 首屏 LCP 图片没有 `loading="lazy"`，且设了 `fetchpriority="high"`
- [ ] 所有 `<img>` 有 `width`/`height` 或容器有 `aspect-ratio`
- [ ] 图片走 AVIF/WebP，`srcset` + `sizes` 已配置，实际像素 = 显示尺寸 × min(DPR, 3)
- [ ] 中文站点未加载大体积 web font（或已做子集化 + `swap`）
- [ ] 骨架屏延迟 200ms 出现，形状与真实内容一致，容器高度固定不产生 CLS
- [ ] 关键 CSS 内联 ≤ 14KB，非关键 CSS 异步
- [ ] 首屏 JS gzip 后 ≤ 170KB，`preconnect` 域名 ≤ 4 个
- [ ] 请求超时 8–10s，失败重试用指数退避且上限 2–3 次
- [ ] 弱网/`saveData` 下进入精简模式（关图片、关动画）
- [ ] 滚动长列表稳定 60fps，超长列表使用虚拟滚动或分页

## 常见错误

| 错误做法 | 为什么错 | 正确做法 |
| --- | --- | --- |
| 首屏 Hero 图加 `loading="lazy"` | 图片等布局完成才下载，LCP 多 500ms+ | 首屏图不 lazy，加 `fetchpriority="high"` |
| `<img>` 不写宽高 | 图片加载完把内容顶下去，CLS 爆表 | 写 `width`/`height` 或容器 `aspect-ratio` |
| 头像导出 1200×1200 | 浪费 10 倍以上带宽，弱网下加载不出来 | 按显示尺寸 × DPR 导出 |
| `srcset` 不写 `sizes` | 浏览器按最大宽度下载 | 同时写 `sizes` |
| 给中文字体做 preload | 字体 1–3MB，抢占首屏图片带宽 | 用系统字体栈；必须用时只 preload 小体积子集 |
| `font-display: block` | 最长 3s 文字不可见 | 用 `swap` |
| 骨架屏立即显示 | 快请求时闪一下，比不显示更「卡」 | 延迟 200ms |
| 骨架屏行数与真实内容不一致 | 加载完内容跳一下，产生 CLS | 骨架形状对齐真实结构 |
| 监控只看平均值 | 平均值被快用户拉高，掩盖长尾问题 | 看 p75 / p95 |
| 还在监控 FID | FID 已于 2024 年被 INP 取代 | 换 INP |
| 请求不设超时 | 弱网下一直转圈，用户只能杀进程 | 8–10s 超时 + 重试 |
| 失败后立即无限重试 | 弱网下重试风暴，把服务打垮 | 指数退避，上限 2–3 次 |
## 参考

- 需要完整的性能预算表、监控埋点方案与 CI 卡点配置时，读 `references/perf-budget.md`
- 需要弱网、离线、慢请求的完整降级矩阵与提示文案规范时，读 `references/weak-network.md`
