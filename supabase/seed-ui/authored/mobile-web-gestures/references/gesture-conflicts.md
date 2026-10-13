# 手势冲突场景与解法

每一个「手势不灵」的问题，本质都是**同一个手指被两个消费者抢**。
这份文件按场景列出冲突双方与解法，解法优先级从高到低：
① CSS `touch-action` ② `overscroll-behavior` ③ JS `preventDefault` ④ 改交互设计。

## 一、横向轮播 vs 页面纵向滚动

**症状**：手指斜着划一下，页面不滚了，轮播却翻了一页。

```css
.carousel {
  touch-action: pan-y;      /* 横向手势归我，纵向给页面 */
  display: flex;
  overflow-x: auto;
  scroll-snap-type: x mandatory;
  -webkit-overflow-scrolling: touch;
}
.carousel > * { scroll-snap-align: start; flex: 0 0 100%; }
```

优先用 CSS Scroll Snap 而不是 JS 轮播：它在合成线程运行，不卡顿，
且手势冲突由浏览器统一裁决。JS 轮播库（Swiper 等）需要自己处理这套逻辑，
一旦参数没调好就会出现「卡在半路」。

## 二、侧滑删除 vs 页面横向滚动 / iOS 返回手势

**症状**：从屏幕左边缘往右滑，想触发侧滑删除，结果触发了 iOS 的「返回上一页」。

这是**无解冲突**：iOS 的屏幕边缘返回手势优先级最高，网页无法覆盖。
正确做法是改设计：

| 方案 | 说明 |
| --- | --- |
| 左侧留 20px 死区 | 侧滑起点从距左边缘 20px 开始判定，避开系统手势区 |
| 改用右侧滑 | 从右往左滑触发删除，不与返回冲突 |
| 改用长按菜单 | 最稳，但可发现性差 |
| 行尾常驻删除按钮 | 牺牲密度换确定性，管理类页面推荐 |

```css
.swipe-row { touch-action: pan-y; }   /* 纵向滚动归浏览器 */
```

JS 里判定侧滑起点：

```js
const EDGE_GUARD = 20
el.addEventListener('touchstart', (e) => {
  if (e.touches[0].clientX < EDGE_GUARD) { enabled = false; return }
  enabled = true
}, { passive: true })
```

## 三、嵌套滚动（弹窗内列表 vs 背后页面）

**症状**：弹窗里的列表滚到底后，背后的页面开始滚。

```css
.modal-body {
  overflow-y: auto;
  overscroll-behavior: contain;   /* 关键 */
  -webkit-overflow-scrolling: touch;
}
/* 弹窗打开时锁住 body */
body.modal-open { overflow: hidden; position: fixed; width: 100%; }
```

`position: fixed` 锁 body 的必要性：iOS Safari 上 `overflow: hidden` 对 `<body>` 无效，
页面仍能滚动。代价是锁住时页面会跳回顶部，需要用 JS 记录并还原 `scrollTop`：

```js
let savedY = 0
function lockBody() {
  savedY = window.scrollY
  document.body.style.cssText = `position:fixed;top:${-savedY}px;width:100%;overflow:hidden`
}
function unlockBody() {
  document.body.style.cssText = ''
  window.scrollTo(0, savedY)
}
```

## 四、拖拽排序 vs 列表滚动

**症状**：想拖一个列表项，结果列表跟着滚。

推荐做法：**长按 200–300ms 后才进入拖拽模式**，且拖拽手柄是独立的小区域。

```css
.drag-handle { touch-action: none; }        /* 手柄完全接管 */
.list { touch-action: pan-y; }              /* 列表本身只滚不拖 */
```

用 Pointer Events 实现（比 Touch Events 更省心，鼠标/触屏/触控笔统一）：

```js
handle.addEventListener('pointerdown', (e) => {
  handle.setPointerCapture(e.pointerId)     // 手指移出元素也能收到事件
  dragging = true
})
handle.addEventListener('pointermove', (e) => {
  if (!dragging) return
  // 用 e.clientY 计算目标位置；不要在这里做 DOM 查询，缓存元素引用
})
handle.addEventListener('pointerup', (e) => {
  dragging = false
  handle.releasePointerCapture(e.pointerId)
})
```

`setPointerCapture` 是拖拽实现里最容易被忽略的一步：没有它，
手指滑出元素边界后 `pointermove` 就断了，拖拽卡住。

## 五、双指缩放 vs 页面缩放

**症状**：在图片上看细节，整页被放大了。

```css
.zoomable {
  touch-action: pinch-zoom;   /* 允许双指缩放，禁止单指拖动页面 */
}
```

如果要自己实现图片缩放，用 `touch-action: none` 并处理 `gesturestart` / `gesturechange`
（仅 Safari 支持）或双指 `touchmove` 的间距变化。

注意：**`user-scalable=no` 不能阻止双指缩放**（iOS 10+ 忽略该设置），
只能通过 `touch-action` 在具体元素上控制。

## 六、视频/地图等第三方组件的冲突

内嵌 iframe（视频、地图、第三方客服）内部的手势无法从外层控制。
解决办法是**在 iframe 上覆盖一层透明遮罩**：

```html
<div class="embed-wrap">
  <iframe src="..."></iframe>
  <div class="embed-mask" role="button" aria-label="点击播放"></div>
</div>
```

```css
.embed-mask { position: absolute; inset: 0; background: transparent; }
/* 点击后移除遮罩，把控制权交给 iframe */
```

这是行业通用做法：首屏遮罩避免滚动被 iframe 吃掉，点击后才真正进入交互。

## 七、滚动性能与 `-webkit-overflow-scrolling`

`-webkit-overflow-scrolling: touch` 在 iOS 13+ 已是默认行为，现代项目**不需要再写**。
写了反而可能触发历史 bug（滚动容器内的 `position: fixed` 元素错位）。

如果需要自定义滚动（惯性、回弹、下拉刷新），优先用 CSS 原生滚动 + `scroll-behavior: smooth`，
只有需要「滚动到底加载 + 精准控制」时才上 JS 滚动库。

## 八、手势优先级决策表

| 冲突 | 首选解法 | 次选 |
| --- | --- | --- |
| 轮播 vs 页面滚动 | `touch-action: pan-y` + Scroll Snap | JS 判定方向 |
| 侧滑删除 vs 返回 | 改交互（右滑或按钮） | 左边缘 20px 死区 |
| 弹窗滚动 vs 页面滚动 | `overscroll-behavior: contain` + 锁 body | JS `preventDefault` |
| 拖拽 vs 滚动 | 长按进入拖拽 + `touch-action: none` | 独立拖拽手柄 |
| 图片缩放 vs 页面缩放 | `touch-action: pinch-zoom` | 自定义双指判定 |
| iframe 吃手势 | 透明遮罩层 | 点击后重设 iframe `pointer-events` |
| 下拉刷新 vs 页面下拉 | `overscroll-behavior-y: contain` | 固定容器 + 内部滚动 |

## 九、检查清单

- [ ] 每个自定义手势容器都显式声明了 `touch-action`
- [ ] 嵌套滚动容器都有 `overscroll-behavior: contain`
- [ ] 弹窗打开时 body 已锁定，关闭后 `scrollY` 已还原
- [ ] 拖拽使用 `setPointerCapture`，手指移出元素不中断
- [ ] 侧滑删除避开了左边缘 20px
- [ ] 内嵌 iframe 有遮罩层，页面滚动不被吃掉
- [ ] 没有写多余的 `-webkit-overflow-scrolling: touch`
- [ ] 冲突场景在 iPhone + Android 各验证一遍
