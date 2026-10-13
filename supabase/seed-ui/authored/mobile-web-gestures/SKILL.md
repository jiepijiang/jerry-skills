---
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
