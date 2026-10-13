-- ============================================================================
-- UI 技能包入库 · H5 移动端 Web（6 个）
-- ----------------------------------------------------------------------------
-- 跑法：Supabase → SQL Editor → 新建查询 → 粘贴本文件 → Run。
--
-- ⚠️ 幂等：末尾是 `on conflict do nothing`，重复跑不会插重复，
--    也不会覆盖已经攒下的下载量 / 安装量 / 评分。
-- ⚠️ 需要先跑过 001-skills.sql（本文件只 insert，不建表）。
-- ============================================================================

insert into public.skills
  (slug, name, description, category, tags, version, license, author,
   readme, files, file_count, total_bytes, hash, bundle_b64, status)
values (
  'h5-performance', 'h5-performance', 'H5 移动端页面加载慢、卡顿或需要做性能验收时使用：Core Web Vitals 阈值、图片与字体优化、骨架屏出现时机、弱网降级策略。', 'ui',
  array['H5 移动端', 'Core Web Vitals', '图片优化', '字体加载', '骨架屏', '弱网降级']::text[], '1.0.0', 'MIT', 'Skill Hub',
  $md$---
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
$md$,
  '[{"path":"ATTRIBUTION.md","size":484,"kind":"text"},{"path":"LICENSE","size":1074,"kind":"text"},{"path":"SKILL.md","size":11753,"kind":"text"},{"path":"references/perf-budget.md","size":5509,"kind":"text"},{"path":"references/weak-network.md","size":7429,"kind":"text"}]'::jsonb, 5, 26249, 'd00902ef0ae044131a397a987f27fa7baf9352a6203e8ac3fa4e6f9a5593d3cb',
  $b64$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$b64$,
  'published'
)
on conflict do nothing;

insert into public.skills
  (slug, name, description, category, tags, version, license, author,
   readme, files, file_count, total_bytes, hash, bundle_b64, status)
values (
  'h5-touch-accessibility', 'h5-touch-accessibility', '做触屏无障碍验收或改造时使用：最小点击热区、对比度与字号下限、焦点可见性、VoiceOver/TalkBack 标注、减弱动效与色盲友好。', 'ui',
  array['H5 移动端', '触屏无障碍', '点击热区', '屏幕阅读器', '对比度', '减弱动效']::text[], '1.0.0', 'MIT', 'Skill Hub',
  $md$---
name: "h5-touch-accessibility"
description: "做触屏无障碍验收或改造时使用：最小点击热区、对比度与字号下限、焦点可见性、VoiceOver/TalkBack 标注、减弱动效与色盲友好。"
version: "1.0.0"
license: "MIT"
author: "Skill Hub"
category: ui
tags: ["H5 移动端", "触屏无障碍", "点击热区", "屏幕阅读器", "对比度", "减弱动效"]
---

# 触屏无障碍

触屏无障碍的判据不是「我觉得能点到」，而是**戴上老花镜、单手拇指、在颠簸的公交上能不能点到**。
本技能给出可测量的数值门槛与真机验证方法。

## 何时使用

- 做无障碍验收 / 整改，需要对照 WCAG 2.2 的触屏相关条款
- 有用户反馈「按钮太小点不到」「颜色太浅看不清」
- 需要给屏幕阅读器用户（VoiceOver / TalkBack）提供正确的标注
- 要支持「减弱动态效果」「大字体」等系统辅助设置
- 图表、状态标签这类「只靠颜色传达信息」的组件需要改造

## 核心规则

1. **点击热区最小 44×44 CSS px，相邻热区间距 ≥ 8px**。
   WCAG 2.2 的 **2.5.8 Target Size (Minimum)** 是 AA 级，要求 24×24 CSS px
   （或间距足够时豁免）；Apple HIG 建议 44×44 pt，Material Design 建议 48×48 dp。
   **移动端按 44×44 做**，这是能同时满足三者且留余量的值。
   视觉尺寸可以更小（如 24px 图标），但热区必须撑到 44px。

2. **正文对比度 ≥ 4.5:1，大字 ≥ 3:1，UI 组件边界与图标 ≥ 3:1**。
   前两条来自 WCAG 1.4.3（AA），第三条来自 1.4.11 非文本对比度。
   「大字」定义：≥ 18.66px 且 `font-weight: 700`，或 ≥ 24px 任意字重。

3. **移动端正文字号 ≥ 16px，绝对下限 14px**。
   低于 14px 在强光下与低视力用户手中不可读。12px 只用于时间戳等非关键信息，
   且对比度仍需 ≥ 4.5:1。

4. **焦点指示器必须可见，轮廓宽度 ≥ 2px、对比度 ≥ 3:1**。
   不能靠浏览器默认的细虚线。用 `:focus-visible` 而不是 `:focus`，
   避免鼠标点击时也出现轮廓。

5. **所有图标按钮必须有可访问名称**。
   `<button>` 里只有 SVG 时，屏幕阅读器读出的是「按钮」两个字，用户完全不知道它做什么。

6. **不允许只靠颜色传达信息**。约 8% 的男性有红绿色觉异常。
   状态、错误、必填、图表分类都必须同时有文字、图标或形状上的区别。

7. **尊重 `prefers-reduced-motion`**。前庭功能障碍用户会因视差、大位移、缩放动画产生眩晕。
   开启后关闭非必要动画，但**不要把过渡时间设为 0** —— 那会让状态变化失去可感知性。

8. **拖拽、多指、路径手势必须有单指替代**（WCAG 2.5.1 / 2.5.7）。
   侧滑删除要有删除按钮，双指缩放要有 +/− 按钮，拖拽排序要有「上移/下移」操作。

## 怎么做

### 第 1 步：热区

```css
/* 视觉 24px 的图标按钮，热区撑到 44px */
.icon-btn { position: relative; width: 24px; height: 24px; }
.icon-btn::after {
  content: '';
  position: absolute;
  inset: -10px;              /* 24 + 10*2 = 44 */
}
```

用伪元素扩大热区的优点是不影响布局，缺点是不能处理相邻元素重叠 ——
**相邻热区不能重叠**，重叠处后渲染的元素会吃掉点击，表现为「点 A 触发了 B」。
紧凑排列时（如表格操作列）改为扩大元素本身：视觉 32px + `gap: 12px`，热区已自然达到 44px。

检查方法：DevTools 里临时给所有可点元素加轮廓，肉眼确认无重叠、无小于 44px 的。

```css
button, a, [role="button"], input, select { outline: 1px solid red !important; }
```

### 第 2 步：对比度

常用色对的对比度（对 `#fff` 背景）：

| 颜色 | 对比度 | 可用于 |
| --- | --- | --- |
| `#1f2329` | 15.8:1 | 任何文字 |
| `#333333` | 12.6:1 | 任何文字 |
| `#4e5969` | 7.4:1 | 任何文字 |
| `#666666` | 5.7:1 | 任何文字（含小字） |
| `#86909c` | 3.2:1 | 仅 ≥18.66px 粗体或 ≥24px |
| `#999999` | 2.8:1 | ❌ 不可用于文字 |
| `#cccccc` | 1.6:1 | ❌ 不可用于文字 |

**`#86909c` 这类灰色是重灾区**：看起来「挺清楚」，但对比度只有 3.2:1，
用于 12px 辅助文字时不合格，移动端强光下可读性更差。

**输入框边框、开关、复选框边框**属于「UI 组件边界」，要求 3:1。
`#d9d9d9`（1.4:1）做输入框边框不合格 —— 低视力用户看不出输入框的边界。

### 第 3 步：焦点可见性

```css
:focus { outline: none; }          /* 移除默认轮廓 */
:focus-visible {                   /* 必须补一个可见的 */
  outline: 2px solid #1677ff;
  outline-offset: 2px;
  border-radius: 4px;
  box-shadow: 0 0 0 4px #fff;      /* 白色光晕，深色背景上也可见 */
}
```

- `:focus-visible` 只在键盘/辅助设备导航时触发，鼠标点击不触发，这是正确行为。
- 轮廓颜色必须与**相邻背景**有 3:1 对比。同一元素可能出现在深浅两种背景上，
  用 `outline` + `box-shadow` 双层保证在任何背景上可见。
- **不要 `outline: none` 且不给替代** —— 这是最常见的无障碍缺陷之一。

### 第 4 步：可访问名称

```html
<!-- ❌ 屏幕阅读器只读「按钮」 -->
<button><svg>…</svg></button>

<!-- ✅ 图标加 aria-hidden，按钮加 aria-label -->
<button aria-label="关闭"><svg aria-hidden="true">…</svg></button>
```

```css
.sr-only {   /* 视觉隐藏但保留在无障碍树里 */
  position: absolute; width: 1px; height: 1px;
  padding: 0; margin: -1px; overflow: hidden;
  clip-path: inset(50%); white-space: nowrap; border: 0;
}
```

`sr-only` 优于 `display: none`：后者会让文本从无障碍树里消失，等于没写。

**WCAG 2.5.3 Label in Name**：可访问名称必须包含可见文本。
按钮上写着「提交」，`aria-label` 就不能是「确认订单」——
语音控制用户说「点击提交」时会匹配不到。

### 第 5 步：动态内容与语义

```html
<div role="dialog" aria-modal="true" aria-labelledby="dlg-title">
  <h2 id="dlg-title">确认删除</h2>
</div>
<div role="status" aria-live="polite">已保存</div>
<div role="alert" aria-live="assertive">手机号格式不正确</div>
<button aria-expanded="false" aria-controls="panel">更多筛选</button>
<div aria-busy="true" aria-live="polite">加载中…</div>
```

`polite` 等用户朗读完再播报，用于「已保存」「共 20 条」；
`assertive` 立即打断，只用于错误与紧急提示。滥用会让屏幕阅读器体验极差。

弹窗打开时必须做**焦点管理**：① 焦点移到弹窗内第一个可聚焦元素；
② `Tab` 在弹窗内循环；③ 关闭后焦点回到触发元素。三件事缺一不可。

### 第 6 步：减弱动效

```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
  }
  .parallax { transform: none !important; }
  .auto-carousel { animation: none !important; }
}
```

用 `0.01ms` 而不是 `0`：某些浏览器对 `0s` 的处理是「跳过过渡」，状态切换会显得生硬。
需要保留的动效（loading 指示器、进度条）是状态信息，可以缩短但不要删。
自动播放的轮播、自动滚动的公告在 `reduce` 下应暂停并给出手动控制。

### 第 7 步：色盲友好

| 场景 | ❌ 只靠颜色 | ✅ 加上 |
| --- | --- | --- |
| 表单错误 | 输入框变红 | 红边框 + 图标 + 文字说明 |
| 状态标签 | 绿/黄/红 | 色点 + 文字（已完成 / 处理中 / 失败） |
| 必填项 | 红色星号 | 星号 + 「必填」文字或 `aria-required` |
| 图表分类 | 6 种颜色 | 颜色 + 形状（圆/方/三角）+ 图例文字 |
| 链接 | 蓝色文字 | 蓝色 + 下划线（WCAG 1.4.1） |

链接加下划线经常被设计反对。折中：正文中的链接加下划线，
导航区、按钮样式的链接可以不加（它们有足够的其他区分特征）。

## 检查清单

- [ ] 所有可点元素热区 ≥ 44×44 CSS px，相邻热区不重叠
- [ ] 正文对比度 ≥ 4.5:1，大字 ≥ 3:1
- [ ] UI 组件边框、图标对比度 ≥ 3:1（输入框边框不是浅灰）
- [ ] 正文字号 ≥ 16px，绝对下限 14px
- [ ] `:focus-visible` 有 2px 轮廓、offset 2px、对比度 ≥ 3:1
- [ ] 没有 `outline: none` 而不给替代
- [ ] 所有图标按钮有可访问名称，且名称包含可见文本（WCAG 2.5.3）
- [ ] 装饰性元素 `aria-hidden="true"`
- [ ] 弹窗有 `role="dialog"` + `aria-modal` + 焦点陷阱 + 关闭后焦点归还
- [ ] 动态提示用 `aria-live`，错误用 `assertive`、其他用 `polite`
- [ ] 信息不只用颜色传达（状态、错误、必填、图表）
- [ ] `prefers-reduced-motion: reduce` 下关闭装饰动画
- [ ] 拖拽/多指手势有单指替代操作
- [ ] 320px 宽下无横向滚动（WCAG 1.4.10），横竖屏都可用
- [ ] 未使用 `user-scalable=no`，允许双击缩放

## 常见错误

| 错误做法 | 为什么错 | 正确做法 |
| --- | --- | --- |
| 图标按钮只有 24×24 热区 | 低于 44px 门槛，拇指点不到 | 用伪元素或 padding 把热区撑到 44px |
| 用 `outline: none` 去掉焦点环 | 键盘与辅助设备用户失去位置感 | 用 `:focus-visible` 补 2px 可见轮廓 |
| 图标按钮无 `aria-label` | 屏幕阅读器只读「按钮」 | `aria-label` 或 `sr-only` 文本 |
| 用 `display: none` 隐藏辅助文本 | 文本从无障碍树消失，等于没写 | 用 `.sr-only` 视觉隐藏 |
| 输入框边框 `#d9d9d9` | 对比度 1.4:1，低视力用户看不出边界 | 用 ≥ 3:1 的边框色 |
| 辅助文字用 `#999` | 对比度 2.8:1，不满足 4.5:1 | 用 `#666` 或更深的颜色 |
| 错误只用红框不用文字 | 色盲用户完全感知不到 | 边框 + 图标 + 文字三重提示 |
| `prefers-reduced-motion` 设为 `0s` | 状态切换变得生硬不可感知 | 用 `0.01ms` 保留瞬间切换 |
| 所有提示都用 `aria-live="assertive"` | 频繁打断朗读，比不读更差 | 只错误用 assertive |
| 弹窗打开后焦点仍留在背景 | 屏幕阅读器用户不知道弹窗已打开 | 焦点移入弹窗并做焦点陷阱 |
| `aria-label` 与可见文本不一致 | 语音控制用户按可见文本说话匹配不到 | 可访问名称包含可见文本 |
| 链接只靠蓝色区分 | 色盲用户看不出是链接 | 正文链接加下划线 |
| 禁用页面缩放 | 违反 WCAG 1.4.4 | 移除 `user-scalable=no` |

## 参考

- 需要 VoiceOver / TalkBack 的具体标注写法、朗读顺序控制与真机测试步骤时，读 `references/screen-reader.md`
- 需要逐条对照 WCAG 2.2 中与移动端触屏相关的条款（含新增的 2.5.7 拖拽、2.4.11 焦点遮挡）与验证方法时，读 `references/wcag-mobile.md`
$md$,
  '[{"path":"ATTRIBUTION.md","size":484,"kind":"text"},{"path":"LICENSE","size":1074,"kind":"text"},{"path":"SKILL.md","size":11047,"kind":"text"},{"path":"references/screen-reader.md","size":8370,"kind":"text"},{"path":"references/wcag-mobile.md","size":8910,"kind":"text"}]'::jsonb, 5, 29885, '6b75473f5e4106b21c71038f0cbe239d6b07d47024231d62ff419e167071ebaa',
  $b64$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$b64$,
  'published'
)
on conflict do nothing;

insert into public.skills
  (slug, name, description, category, tags, version, license, author,
   readme, files, file_count, total_bytes, hash, bundle_b64, status)
values (
  'h5-viewport-adaptation', 'h5-viewport-adaptation', '需要做 H5 移动端页面适配时使用：viewport meta 写法、rem 与 vw 方案取舍、1px 边框、刘海屏安全区、横屏与软键盘顶起布局的处理规则。', 'ui',
  array['H5 移动端', 'viewport', 'rem 适配', '安全区', '1px 边框', '软键盘']::text[], '1.0.0', 'MIT', 'Skill Hub',
  $md$---
name: "h5-viewport-adaptation"
description: "需要做 H5 移动端页面适配时使用：viewport meta 写法、rem 与 vw 方案取舍、1px 边框、刘海屏安全区、横屏与软键盘顶起布局的处理规则。"
version: "1.0.0"
license: "MIT"
author: "Skill Hub"
category: ui
tags: ["H5 移动端", "viewport", "rem 适配", "安全区", "1px 边框", "软键盘"]
---

# H5 移动端适配

H5 适配的难点不在「等比缩放」，而在于**浏览器 UI（地址栏、键盘、刘海）会改变可用视口**，
而 CSS 里的 `100vh`、`100%` 并不总是你以为的那个值。
本技能给出各方案的取舍与可以直接用的写法。

## 何时使用

- 新建 H5 项目，要决定用 rem 还是 vw
- 设计稿是 375 或 750，要换算成代码
- 页面在 iPhone 上底部被小黑条（Home Indicator）挡住
- `100vh` 的弹窗在 iOS Safari 上被地址栏切掉一截
- 输入框聚焦时软键盘把底部按钮顶出屏幕 / 或把整个页面推上去
- 1px 边框在手机上看起来像 3px

## 核心规则

1. **viewport meta 用这一行，不要加别的**：

   ```html
   <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
   ```

   - 不要写 `maximum-scale=1` 和 `user-scalable=no`：违反 WCAG 1.4.4（允许缩放至 200%），
     且 iOS 10 之后 Safari 会直接忽略它们，写了也没用。
   - `viewport-fit=cover` 是使用 `env(safe-area-inset-*)` 的**前置条件**，漏了安全区变量全是 0。
   - 不要用 `width=750` 的固定宽度方案（老派做法）：它会让页面在横屏/大屏上被整体缩放，
     且和 `position: fixed` 元素冲突。

2. **rem 与 vw 只选一个，且都要 `clamp()` 封顶**。
   纯等比缩放在 414 宽的手机上会让 375 设计稿的文字放大 10%，
   在 320 宽的旧机上缩小 15% —— 文字太小是不可接受的。
   正确写法：`font-size: clamp(14px, 4.267vw, 18px)`。

3. **1px 边框用 `transform: scaleY(0.5)` 实现**，不要直接写 `0.5px`。
   `border: 0.5px` 在 iOS 上有效，但部分 Android WebView 会向上取整成 1px 或直接不渲染。
   `transform` 方案在所有 DPR 下行为一致。

4. **不要用 `100vh` 做全屏高度**。iOS Safari 的 `100vh` 等于「地址栏收起时的视口高度」，
   页面初次加载时底部会有一截被地址栏盖住。
   用 `100dvh`（动态视口高度，Chrome 108+ / Safari 15.4+ 支持）或降级到 `--vh` 变量。

5. **底部固定元素必须叠加安全区**：

   ```css
   .bottom-bar {
     position: fixed; inset-inline: 0; bottom: 0;
     padding-bottom: calc(12px + env(safe-area-inset-bottom));
   }
   ```

   iPhone 14 Pro 的底部安全区是 34px，不叠加的话按钮正好压在 Home Indicator 上。

6. **软键盘只改 `visualViewport`，不改 `window.innerHeight`（iOS）**。
   依赖 `window.innerHeight` 判断键盘弹出的代码在 iOS 上一定失败。
   用 `window.visualViewport` 的 `resize` 事件。

7. **横屏时左右也有安全区**。iPhone 横屏的 `safe-area-inset-left/right` 是 44px，
   全屏内容（视频、游戏、地图）必须同时处理四边。

## 怎么做

### 第 1 步：选适配方案

| 方案 | 换算 | 优点 | 代价 |
| --- | --- | --- | --- |
| 固定 px + 弹性布局 | 无 | 最简单，不依赖构建工具 | 大屏上元素偏小，需要手动调 |
| rem | `1rem = 16 * (clientWidth / 375)px` | 等比缩放，改造老项目容易 | 需 JS 或 PostCSS 插件；根字号被改后所有尺寸联动 |
| vw | `1vw = clientWidth / 100` | 纯 CSS，无 JS | 用户浏览器字号设置失效（无障碍问题） |
| vw + `clamp()` | 见下 | 兼顾缩放与可读性 | 需要为每个尺寸设上下限 |

**推荐**：容器尺寸用 `vw` 或 `%`，**字号一律用 `clamp(px, vw, px)`**。

```css
:root {
  --fs-body: clamp(14px, 4.267vw, 18px);   /* 375 设计稿下的 16px */
  --fs-cap:  clamp(11px, 3.2vw, 14px);     /* 375 设计稿下的 12px */
  --fs-title: clamp(17px, 5.33vw, 24px);   /* 375 设计稿下的 20px */
}
```

换算公式：`vw值 = 设计稿px / 设计稿宽度 × 100`。
375 稿下 `20px → 5.333vw`，750 稿下 `40px → 5.333vw`（同一比例）。

### 第 2 步：rem 方案的完整写法

如果坚持 rem（老项目常见），用 `html { font-size }` + 一行 JS：

```js
function setRootFontSize() {
  const w = document.documentElement.clientWidth
  // 设计稿 375，基准 16px；clamp 到 [13, 20] 防止极端屏
  const size = Math.min(20, Math.max(13, 16 * (w / 375)))
  document.documentElement.style.fontSize = size + 'px'
}
setRootFontSize()
window.addEventListener('resize', setRootFontSize)
window.addEventListener('orientationchange', () => setTimeout(setRootFontSize, 300))
```

`orientationchange` 后必须延迟 300ms 再读 `clientWidth` ——
旋转过程中浏览器还没算完新尺寸，立刻读会拿到旧值。

如果用 PostCSS，配 `postcss-pxtorem`（`rootValue: 16`）或 `postcss-px-to-viewport`，
写代码时仍按设计稿写 px，构建时自动换算。

### 第 3 步：1px 边框

```css
.hairline-bottom { position: relative; }
.hairline-bottom::after {
  content: '';
  position: absolute;
  inset-inline: 0;
  bottom: 0;
  height: 1px;
  background: #e5e5e5;
  transform: scaleY(0.5);
  transform-origin: 0 100%;   /* 关键：从底部缩放，否则线会跑位 */
  pointer-events: none;
}
@media (-webkit-min-device-pixel-ratio: 3) {
  .hairline-bottom::after { transform: scaleY(0.3333); }
}
```

要点：
- `transform-origin` 必须是线所在的那一边，否则缩放后位置偏移半个像素。
- 用 `::after` 而不是改 `border`，避免影响盒模型与布局。
- `pointer-events: none` 防止伪元素挡住点击。
- 圆角元素的 1px 边框用 `border: 1px solid` + 外层 `transform: scale()` 整体缩放不现实，
  这种情况直接用 `0.5px` 并接受 Android 的微小差异。

### 第 4 步：安全区

```css
:root {
  --sat: env(safe-area-inset-top, 0px);
  --sar: env(safe-area-inset-right, 0px);
  --sab: env(safe-area-inset-bottom, 0px);
  --sal: env(safe-area-inset-left, 0px);
}

/* 顶部固定导航：给状态栏留位 */
.navbar { padding-top: calc(8px + var(--sat)); }

/* 底部固定操作栏 */
.action-bar { padding-bottom: calc(12px + var(--sab)); }

/* 全屏内容（视频/地图）四边都处理 */
.fullscreen-media {
  padding: var(--sat) var(--sar) var(--sab) var(--sal);
  box-sizing: border-box;
}

/* 滚动容器底部留白，防止最后一条被固定栏盖住 */
.scroll-area { padding-bottom: calc(64px + var(--sab)); }
```

`env()` 必须给 fallback（第二个参数），否则在不支持 `viewport-fit=cover` 的浏览器上
整条声明会失效（不是取 0，而是声明无效）。

典型安全区数值：iPhone 14 Pro 顶部 59px、底部 34px；iPhone SE 顶部 20px、底部 0；
安卓大部分机型为 0。**不要用这些数字硬编码**，一律用 `env()`。

### 第 5 步：全屏高度

```css
/* 方案 A：dvh（推荐，现代浏览器） */
.full-page { height: 100dvh; }

/* 方案 B：JS 变量兜底 */
/* html { --vh: 1vh } 由 JS 设置 */
.full-page { height: calc(var(--vh, 1vh) * 100); }
```

```js
// 方案 B 的 JS
function setVh() {
  document.documentElement.style.setProperty('--vh', window.innerHeight * 0.01 + 'px')
}
setVh()
window.addEventListener('resize', setVh)
window.visualViewport?.addEventListener('resize', setVh)
```

三种视口单位的区别：
- `vh`：最大视口（地址栏收起），iOS 上会偏大。
- `svh`：最小视口（地址栏展开），偏小但不会溢出。
- `dvh`：动态，随地址栏变化而变。**做全屏容器用 `dvh`，做吸底元素用 `svh` 更稳**。

### 第 6 步：软键盘

```js
const vv = window.visualViewport
if (vv) {
  vv.addEventListener('resize', () => {
    // 键盘高度 = 布局视口高度 - 可视视口高度 - 视口偏移
    const keyboardH = window.innerHeight - vv.height - vv.offsetTop
    const open = keyboardH > 100   // 100px 以下通常是地址栏变化，不是键盘
    document.documentElement.classList.toggle('kb-open', open)
  })
}
```

```css
/* 键盘弹出时，吸底元素改为跟随可视视口 */
.kb-open .action-bar {
  position: absolute;
  top: calc(var(--vvh, 100vh) - 56px);
}
```

两种浏览器行为必须都处理：
- **iOS**：视口不变，页面整体上推，`position: fixed` 的元素会被键盘盖住或飘在键盘上方。
- **Android（Chrome）**：默认 `resize` 模式，视口变小，`100vh` 变小，
  布局会被压扁（常见症状是表格挤压、`flex: 1` 区域高度变 0）。

Android 可在 manifest 里设 `android:windowSoftInputMode="adjustResize"` 统一行为。
通用原则：**输入框不要放在 `position: fixed` 的容器里**，
把表单放进正常文档流 + `position: sticky` 的提交按钮，能规避 80% 的键盘问题。

## 检查清单

- [ ] viewport meta 含 `viewport-fit=cover`，且没有 `user-scalable=no`
- [ ] 字号使用 `clamp()` 设了上下限，320 宽下不小于 12px
- [ ] 1px 线用 `transform: scaleY()`，`transform-origin` 指向线所在边
- [ ] 底部固定元素叠加了 `env(safe-area-inset-bottom)`，iPhone 上按钮不被小黑条遮挡
- [ ] 顶部固定导航叠加了 `env(safe-area-inset-top)`
- [ ] `env()` 全部带 fallback 值
- [ ] 没有使用裸 `100vh` 做全屏容器（改用 `dvh` 或 `--vh`）
- [ ] 输入框聚焦时，底部按钮仍可见可点（iOS + Android 都测）
- [ ] 横屏下左右安全区已处理，全屏内容不被圆角裁切
- [ ] 旋转屏幕后布局正确（`orientationchange` 延迟 300ms 重算）
- [ ] 页面在 320 / 375 / 414 / 430 四档宽度下无横向滚动条
- [ ] 滚动容器底部留白 ≥ 固定栏高度 + 安全区

## 常见错误

| 错误做法 | 为什么错 | 正确做法 |
| --- | --- | --- |
| `user-scalable=no, maximum-scale=1` | 违反 WCAG 1.4.4，且 iOS 10+ 已忽略 | 只写 `width=device-width, initial-scale=1` |
| 用 `env()` 但不写 `viewport-fit=cover` | 所有安全区变量都是 0，等于没写 | meta 里加 `viewport-fit=cover` |
| `border-bottom: 0.5px` 做细线 | 部分 Android WebView 取整成 1px 或不渲染 | `::after` + `transform: scaleY(0.5)` |
| `transform: scaleY(0.5)` 不写 `transform-origin` | 线向上偏移半像素，看起来像双线 | `transform-origin` 指向线所在边 |
| `height: 100vh` 做全屏 | iOS 上底部被地址栏遮住一截 | `100dvh` 或 `--vh` 变量 |
| 用 `window.innerHeight` 判断键盘 | iOS 上键盘弹出不改 `innerHeight` | 用 `window.visualViewport` |
| `env()` 不写 fallback | 不支持时整条声明失效（不是取 0） | `env(safe-area-inset-bottom, 0px)` |
| 硬编码 `padding-bottom: 34px` | 只对 iPhone 14 Pro 成立 | 用 `env()` |
| 纯 vw 设字号且不 clamp | 用户浏览器字号设置完全失效 | `clamp(14px, 4.267vw, 18px)` |
| `orientationchange` 里立即读宽度 | 拿到旋转前的旧值 | 延迟 300ms 或监听 `resize` |
| 底部滚动区不留白 | 最后一条数据被固定栏永久遮挡 | `padding-bottom: calc(64px + var(--sab))` |

## 参考

- 需要各机型安全区实测值、横屏适配细节、以及 iOS / Android WebView 差异清单时，读 `references/safe-area.md`
- 需要把 rem / vw / 混合方案的构建配置（PostCSS、Vite 插件）完整搭起来时，读 `references/rem-vw-pipeline.md`
$md$,
  '[{"path":"ATTRIBUTION.md","size":484,"kind":"text"},{"path":"LICENSE","size":1074,"kind":"text"},{"path":"SKILL.md","size":11519,"kind":"text"},{"path":"references/rem-vw-pipeline.md","size":5717,"kind":"text"},{"path":"references/safe-area.md","size":5662,"kind":"text"}]'::jsonb, 5, 24456, '18d7f2e68a53dc591197943eaec7bdceda4e3f1c8c70d116f2c2656ff5cec642',
  $b64$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$b64$,
  'published'
)
on conflict do nothing;

insert into public.skills
  (slug, name, description, category, tags, version, license, author,
   readme, files, file_count, total_bytes, hash, bundle_b64, status)
values (
  'mobile-form-ux', 'mobile-form-ux', '设计移动端表单与登录注册流程时使用：inputmode 与 type 选型、错误提示时机、分步还是单页、自动填充、验证码交互与防重复提交。', 'ui',
  array['H5 移动端', '表单设计', 'inputmode', '自动填充', '验证码', '防重复提交']::text[], '1.0.0', 'MIT', 'Skill Hub',
  $md$---
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
$md$,
  '[{"path":"ATTRIBUTION.md","size":484,"kind":"text"},{"path":"LICENSE","size":1074,"kind":"text"},{"path":"SKILL.md","size":12705,"kind":"text"},{"path":"references/form-validation.md","size":8101,"kind":"text"},{"path":"references/input-types.md","size":7344,"kind":"text"}]'::jsonb, 5, 29708, '6f84af4f7ca2edef8f8fab53eac0c8a8436578e345f6d8533b1f47c862e5917f',
  $b64$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$b64$,
  'published'
)
on conflict do nothing;

insert into public.skills
  (slug, name, description, category, tags, version, license, author,
   readme, files, file_count, total_bytes, hash, bundle_b64, status)
values (
  'mobile-web-gestures', 'mobile-web-gestures', '在 H5 里实现或调试移动端触摸交互时使用：tap 与 click 的差别、滑动手势判定阈值、下拉刷新、长按、手势冲突与防误触处理。', 'ui',
  array['H5 移动端', '触摸事件', '手势冲突', '下拉刷新', '长按', 'touch-action']::text[], '1.0.0', 'MIT', 'Skill Hub',
  $md$---
name: "mobile-web-gestures"
description: "在 H5 里实现或调试移动端触摸交互时使用：tap 与 click 的差别、滑动手势判定阈值、下拉刷新、长按、手势冲突与防误触处理。"
version: "1.0.0"
license: "MIT"
author: "Skill Hub"
category: ui
tags: ["H5 移动端", "触摸事件", "手势冲突", "下拉刷新", "长按", "touch-action"]
---

# 移动端手势与触摸交互

移动端交互的坑几乎全部来自两件事：**浏览器把同一个动作解释成多种意图**（点、双击缩放、滚动、长按选择），
以及**多个可滚动/可拖拽区域抢同一个手指**。
本技能给出判定阈值和处理顺序。

## 何时使用

- 页面「点一下没反应，要等一下才跳转」（怀疑 300ms 延迟）
- 自定义滑动（左右切页、侧滑删除、拖拽排序）与页面滚动打架
- 实现下拉刷新，但和浏览器自带的下拉刷新冲突
- 长按菜单和文本选择同时触发
- 弹窗打开后，滑动弹窗会把背后的页面也带着滚
- 用户反馈「老是点错」「一滑就误触发」

## 核心规则

1. **300ms 延迟在现代浏览器里已经不存在了 —— 前提是 viewport meta 正确**。
   它的由来是浏览器要等 300ms 判断用户是不是在做「双击缩放」。
   只要写了 `<meta name="viewport" content="width=device-width, initial-scale=1">`，
   Chrome 32+（2014）和 iOS Safari 9.3+（2016）就会取消这个延迟。
   如果 2026 年还遇到「点一下要等一下」，先查 meta，再查有没有 `user-scalable=no` 的遗留代码。

2. **默认一律用 `click`，不要用 `touchstart` 做按钮**。
   `touchstart` 在手指刚接触屏幕时触发，用户反悔（滑动取消）时按钮已经被激活了 ——
   这是「误触」的头号来源。只有实现自定义手势时才用触摸事件。

3. **给可点击元素加 `touch-action: manipulation`**。
   它告诉浏览器「这里只可能是点或滚动，不可能是双击缩放」，
   让浏览器立刻派发 `click` 并允许滚动优化。一行 CSS 换掉大部分点击优化代码。

4. **滑动判定阈值：位移 ≥ 10px 才算滑动**。小于 10px 一律当点击处理。
   这是手指抖动的量级；阈值设成 3px 会让「想点但手抖」全部变成滑动。
   方向判定：水平位移绝对值 > 垂直位移绝对值 **且** 水平位移 > 30px，才算横向滑动。

5. **长按判定 500ms + 位移容差 10px**。
   500ms 与 iOS 文本选择的触发时机一致；容差是为了让手指轻微移动不打断长按。
   长按菜单出现时要 `preventDefault()` 阻止系统文本选择，或给元素加 `user-select: none`。

6. **下拉刷新的触发距离取 64–80px，阻尼系数 0.5**。
   阻尼（手指移动 100px，元素只移动 50px）能让用户感知「还没到触发线」。
   小于 64px 容易在正常滚动时误触发；大于 80px 手机会显得「拉不动」。

7. **滚动容器必须用 `overscroll-behavior: contain`**。
   不加的话，内层列表滚到底会「滚动链」传递到外层页面，
   表现为弹窗在滚、背后页面也在滚。

8. **所有触摸监听器加 `{ passive: true }`**，除非你确实要阻止默认行为。
   Chrome 56+ 已把 `window` / `document` 上的 `touchstart` / `touchmove` 默认设为 passive，
   在这些元素上调用 `preventDefault()` 会无效并打印警告。

## 怎么做

### 第 1 步：建立「点击优先级」认知

浏览器对一次手指触摸的处理顺序：

```
touchstart → touchmove* → touchend → (300ms 内无第二次触摸) → click
```

关键点：
- `click` 一定在 `touchend` 之后，可能有几十毫秒到 300ms 的间隔。
- 如果用户在 `touchend` 后又点了第二下（双击），`click` **不会触发**（浏览器在等缩放）。
- 因此「先 `touchstart` 加高亮，等 `click` 再执行动作」是体验最好的组合：
  用户按下的瞬间有视觉反馈（`touchstart`），动作在 `click` 时才执行（可取消）。

```js
btn.addEventListener('touchstart', () => btn.classList.add('is-active'), { passive: true })
;['touchend', 'touchcancel'].forEach((t) =>
  btn.addEventListener(t, () => btn.classList.remove('is-active'), { passive: true }))
btn.addEventListener('click', doAction)   // 唯一的动作入口
```

`touchcancel` 必须一起监听 —— 来电、系统弹窗、手势返回都会触发它，
漏掉的话按钮会永远保持按下态。

### 第 2 步：写一个手势判定器

```js
function bindGesture(el, { onTap, onSwipeLeft, onSwipeRight, onLongPress } = {}) {
  let x0 = 0, y0 = 0, t0 = 0, moved = false, timer = null, longFired = false
  const clear = () => { clearTimeout(timer); timer = null }

  el.addEventListener('touchstart', (e) => {
    if (e.touches.length !== 1) return           // 多指忽略
    const t = e.touches[0]
    x0 = t.clientX; y0 = t.clientY; t0 = Date.now()
    moved = false; longFired = false
    if (onLongPress) timer = setTimeout(() => { longFired = true; onLongPress(e) }, 500)
  }, { passive: true })

  el.addEventListener('touchmove', (e) => {
    const t = e.touches[0]
    if (Math.hypot(t.clientX - x0, t.clientY - y0) > 10) { moved = true; clear() }
  }, { passive: true })

  el.addEventListener('touchend', (e) => {
    clear()
    if (longFired) return
    const t = e.changedTouches[0]
    const dx = t.clientX - x0, dy = t.clientY - y0
    const dt = Date.now() - t0
    const speed = Math.abs(dx) / Math.max(dt, 1)     // px/ms
    if (Math.abs(dx) > 30 && Math.abs(dx) > Math.abs(dy) * 1.5 && speed > 0.3) {
      dx < 0 ? onSwipeLeft?.() : onSwipeRight?.()
    } else if (!moved && dt < 500) {
      onTap?.(e)
    }
  }, { passive: true })

  el.addEventListener('touchcancel', clear, { passive: true })
}
```

阈值解释：`> 10px` 才认为移动过（抖动容差）；`> 30px` 才算滑动；
`水平 > 垂直 × 1.5` 保证是明确的横向意图；
`speed > 0.3 px/ms`（= 300px/s）是「甩」的下限，慢拖不触发翻页；
`dt < 500` 防止「按住不动 2 秒后松手」被当成点击。

### 第 3 步：用 `touch-action` 消解冲突

```css
button, a, [role="button"] { touch-action: manipulation; }  /* 默认：所有可点元素 */
.carousel { touch-action: pan-y; }      /* 横向轮播：横向归我，纵向给页面 */
.swipe-row { touch-action: pan-y; }     /* 纵向列表：横向留给侧滑删除 */
.drag-handle { touch-action: none; }    /* 自定义拖拽：完全接管 */
.modal-mask { overscroll-behavior: contain; }  /* 弹窗遮罩：阻止滚动链 */
```

`touch-action` 是**声明式**的，浏览器在合成线程就能处理，
比 JS 里 `preventDefault()` 快得多，也不会阻塞滚动。
能用 `touch-action` 解决的冲突，就不要写 JS。

对照表：

| 想要的效果 | `touch-action` |
| --- | --- |
| 只点击，不要双击缩放 | `manipulation` |
| 页面纵向滚动 + 自己处理横向 | `pan-y` |
| 页面横向滚动 + 自己处理纵向 | `pan-x` |
| 完全自己处理（拖拽、画板） | `none` |
| 双向滚动 + 自己处理双指缩放 | `pinch-zoom` |

### 第 4 步：下拉刷新

```js
const THRESHOLD = 72      // 触发距离
const DAMPING = 0.5       // 阻尼
let startY = 0, pulling = false, dist = 0

scroller.addEventListener('touchstart', (e) => {
  if (scroller.scrollTop > 0) return        // 只在顶部启用
  startY = e.touches[0].clientY
  pulling = true
}, { passive: true })

scroller.addEventListener('touchmove', (e) => {
  if (!pulling) return
  const dy = e.touches[0].clientY - startY
  if (dy <= 0) { pulling = false; return }
  dist = Math.min(dy * DAMPING, THRESHOLD * 1.5)   // 阻尼 + 上限
  indicator.style.transform = `translateY(${dist}px)`
}, { passive: true })

scroller.addEventListener('touchend', () => {
  if (!pulling) return
  pulling = false
  if (dist >= THRESHOLD) refresh()          // 触发
  indicator.style.transform = ''            // 回弹（CSS transition 负责动画）
  dist = 0
}, { passive: true })
```

同时要用 `html, body { overscroll-behavior-y: contain; }`
**关掉浏览器自带的下拉刷新**，否则两个刷新叠在一起。

注意该属性在 iOS Safari 上对「橡皮筋效果」无效（iOS 的整页橡皮筋不受它控制），
需要在容器上限制。如果内容高度小于视口，iOS 会整页拖动，
这时只能用 `position: fixed` 容器 + 内部滚动来规避。

### 第 5 步：长按

长按元素需要 `user-select: none`（阻止文本选择）、
`-webkit-touch-callout: none`（关掉 iOS 长按弹出菜单）、`touch-action: manipulation`。

长按与以下行为天然冲突，必须二选一：文本选择、iOS 链接预览/图片保存菜单、
系统级「用力按压」预览（Haptic Touch，无法用 CSS 关闭）。

长按触发时给一次**触觉反馈**（`navigator.vibrate?.(10)`，Android 支持；iOS 不支持）或
视觉反馈（元素缩放 0.96 + 阴影加深），否则用户不知道长按成功了。

### 第 6 步：防误触与防重复提交

| 场景 | 做法 |
| --- | --- |
| 相邻可点元素 | 热区 ≥ 44×44 CSS px，元素间距 ≥ 8px |
| 提交按钮 | 点击后立即 `disabled` + 显示 loading，1.5s 后按请求结果决定是否恢复 |
| 列表行 | 行高 ≥ 44px，行内按钮与整行点击分开（行内按钮 `stopPropagation`） |
| 侧滑删除 | 滑开后才显示删除按钮，删除按钮宽 ≥ 72px |
| 危险操作 | 二次确认，确认按钮不用主色，且默认焦点在「取消」 |
| 底部固定栏 | 与内容之间加 8px 分隔，避免内容贴边被误点 |

防重复提交的正确实现：在 `finally` 里按请求结果恢复按钮状态。

```js
let submitting = false
async function submit() {
  if (submitting) return
  submitting = true
  btn.disabled = true
  try { await api.submit() } finally {
    submitting = false
    btn.disabled = false
  }
}
```

**不要用 `setTimeout` 恢复按钮**：网络慢的时候用户会看到按钮恢复但请求还在飞，
于是再点一次，产生重复订单。

## 检查清单

- [ ] viewport meta 正确，且没有遗留的 `user-scalable=no`
- [ ] 所有按钮用 `click` 触发，`touchstart` 只做视觉反馈
- [ ] 所有可点元素有 `touch-action: manipulation`
- [ ] `touchcancel` 已监听，按下态不会卡住
- [ ] 滑动阈值 ≥ 10px，横向判定 > 30px 且 > 垂直 × 1.5
- [ ] 长按阈值 500ms，位移容差 10px，元素设了 `user-select: none`
- [ ] 自定义下拉刷新阈值 64–80px，带阻尼，且已关掉浏览器自带下拉刷新
- [ ] 滚动容器与弹窗用 `overscroll-behavior: contain`，无滚动穿透
- [ ] 触摸监听器默认 `{ passive: true }`，无 `preventDefault` 警告
- [ ] 提交按钮有 disabled + loading，不用定时器恢复
- [ ] 相邻点击目标间距 ≥ 8px，热区 ≥ 44×44px
- [ ] 在 iPhone 与 Android 各测一遍侧滑返回手势不与应用手势冲突

## 常见错误

| 错误做法 | 为什么错 | 正确做法 |
| --- | --- | --- |
| 用 `touchstart` 做按钮动作 | 用户滑动取消后动作已经执行，误触率高 | 动作放 `click`，`touchstart` 只做高亮 |
| 为了「消除 300ms 延迟」引入 fastclick | 现代浏览器已无此延迟，库反而增加 10KB 与事件冲突 | 写对 viewport meta + `touch-action: manipulation` |
| 只监听 `touchend` | 来电、系统弹窗触发 `touchcancel`，按下态卡死 | 同时监听 `touchcancel` |
| 滑动阈值设 3–5px | 手抖被判定为滑动，点击全部失效 | 阈值 ≥ 10px |
| 只用位移判定滑动方向 | 斜向滑动误触发翻页 | 加 `水平 > 垂直 × 1.5` 与速度下限 |
| 在 `window` 上 `touchmove` 里 `preventDefault()` | Chrome 56+ 默认 passive，无效且报警告 | 用 `touch-action` 或对具体元素加 `{ passive: false }` |
| 弹窗只设 `overflow: hidden` | iOS 上背后页面仍可滚动（滚动穿透） | `overscroll-behavior: contain` + 阻止 `touchmove` |
| 用 `setTimeout` 恢复提交按钮 | 请求慢时按钮提前恢复，产生重复提交 | 在 `finally` 里按请求结果恢复 |
| 长按与文本选择同时生效 | 用户想长按菜单，结果是选中文字 | `user-select: none` + `-webkit-touch-callout: none` |
| 自定义下拉刷新不关浏览器自带的 | 两个刷新指示器同时出现 | `overscroll-behavior-y: contain` |
## 参考

- 需要处理「同一个手指被多个容器抢」的具体场景（侧滑返回、嵌套滚动、拖拽排序、轮播与页面滚动共存）时，读 `references/gesture-conflicts.md`
- 需要手写拖拽排序、侧滑删除、双指缩放的完整实现与性能优化时，读 `references/drag-and-swipe.md`
$md$,
  '[{"path":"ATTRIBUTION.md","size":484,"kind":"text"},{"path":"LICENSE","size":1074,"kind":"text"},{"path":"SKILL.md","size":12818,"kind":"text"},{"path":"references/drag-and-swipe.md","size":7020,"kind":"text"},{"path":"references/gesture-conflicts.md","size":6556,"kind":"text"}]'::jsonb, 5, 27952, '3c0e54c2801a8f5385a5601b1275721474669c39de463361e2224851b23c5b15',
  $b64$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$b64$,
  'published'
)
on conflict do nothing;

insert into public.skills
  (slug, name, description, category, tags, version, license, author,
   readme, files, file_count, total_bytes, hash, bundle_b64, status)
values (
  'wechat-h5-guide', 'wechat-h5-guide', '在微信内置浏览器里开发或调试 H5 时使用：WebView 差异、分享与授权签名、标题与状态栏、页面栈返回、支付回调与真机调试。', 'ui',
  array['H5 移动端', '微信 WebView', 'JS-SDK', '分享配置', '微信授权', '页面栈']::text[], '1.0.0', 'MIT', 'Skill Hub',
  $md$---
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
$md$,
  '[{"path":"ATTRIBUTION.md","size":484,"kind":"text"},{"path":"LICENSE","size":1074,"kind":"text"},{"path":"SKILL.md","size":13519,"kind":"text"},{"path":"references/wechat-jsapi.md","size":8787,"kind":"text"},{"path":"references/wechat-limits.md","size":6822,"kind":"text"}]'::jsonb, 5, 30686, '0d1524904f1dd6b26c515f688e5c22317f31c3809f67debe8e69f82c4465b8e8',
  $b64$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$b64$,
  'published'
)
on conflict do nothing;
