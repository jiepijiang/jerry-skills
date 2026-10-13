---
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
