# 拖拽排序、侧滑删除、双指缩放实现

三个高频自定义手势的完整实现要点。全部基于 **Pointer Events** ——
它同时覆盖触屏、鼠标、触控笔，且不需要处理 `touchcancel` 与多指索引。

## 一、为什么用 Pointer Events 而不是 Touch Events

| 维度 | Touch Events | Pointer Events |
| --- | --- | --- |
| 覆盖设备 | 仅触屏 | 触屏 + 鼠标 + 笔 |
| 多指处理 | `e.touches[i]` 手动索引 | 每个 `pointerId` 独立事件流 |
| 手指移出元素 | 事件中断，需手动补 | `setPointerCapture` 自动接管 |
| 取消事件 | `touchcancel`（易漏） | `pointercancel` |
| 浏览器支持 | 全支持 | Safari 13+ 全支持 |

结论：新项目一律用 Pointer Events。

## 二、拖拽排序

### 关键参数

| 参数 | 取值 | 理由 |
| --- | --- | --- |
| 长按进入拖拽 | 200–300ms | 与滚动区分；低于 200ms 容易误触发 |
| 位移容差 | 8px | 长按期间手指微动不取消 |
| 自动滚动触发区 | 距容器边缘 60px | 拖到边缘时自动滚动列表 |
| 自动滚动速度 | 4–12 px/帧 | 越靠边越快，用线性插值 |
| 被拖项缩放 | 1.02 + 阴影 | 给出「已拿起」的反馈 |

### 实现骨架

```js
let dragEl = null, startY = 0, offsetY = 0, holdTimer = null, active = false

function onDown(e) {
  dragEl = e.currentTarget
  startY = e.clientY
  offsetY = 0
  holdTimer = setTimeout(() => {
    active = true
    dragEl.setPointerCapture(e.pointerId)
    dragEl.classList.add('is-dragging')       // transform: scale(1.02) + box-shadow
  }, 250)
  dragEl.addEventListener('pointermove', onMove)
  dragEl.addEventListener('pointerup', onUp, { once: true })
  dragEl.addEventListener('pointercancel', onUp, { once: true })
}

function onMove(e) {
  if (!active) {
    if (Math.abs(e.clientY - startY) > 8) clearTimeout(holdTimer)  // 判定为滚动
    return
  }
  offsetY = e.clientY - startY
  dragEl.style.transform = `translateY(${offsetY}px) scale(1.02)`
  // 用缓存的元素矩形判断目标位置，不要每帧 getBoundingClientRect
  const target = findTargetIndex(e.clientY)
  if (target !== lastTarget) { lastTarget = target; reorderPreview(target) }
}

function onUp() {
  clearTimeout(holdTimer)
  if (!active) { cleanup(); return }
  commitOrder()
  dragEl.style.transform = ''
  dragEl.classList.remove('is-dragging')
  cleanup()
}
```

### 性能要点

1. **只改 `transform`，不改 `top`**。`transform` 走合成层，不掉帧；`top` 触发重排。
2. **每帧不要调 `getBoundingClientRect()`**。进入拖拽时把所有行的位置缓存进数组，
   移动时用二分查找算目标索引。每帧布局读取是移动端掉帧的头号原因。
3. **其余行用 `transform: translateY(±行高)` 让位**，并加 150ms 过渡。
4. `pointermove` 里用 `requestAnimationFrame` 节流：

```js
let ticking = false
function onMove(e) {
  lastEvent = e
  if (ticking) return
  ticking = true
  requestAnimationFrame(() => { ticking = false; apply(lastEvent) })
}
```

5. 拖拽期间给列表加 `touch-action: none`，防止页面跟着滚。

## 三、侧滑删除

### 关键参数

| 参数 | 取值 |
| --- | --- |
| 触发方向 | 从右往左（避免 iOS 返回手势） |
| 判定位移 | ≥ 10px 且水平 > 垂直 × 1.5 |
| 吸附位置 | 0 / -80px（露出删除按钮） |
| 删除按钮宽度 | 72–88px |
| 吸附动画 | 200ms `cubic-bezier(.2,0,0,1)` |
| 全滑删除 | 位移 > 容器宽 × 0.5 时直接删除 |

### 实现要点

```js
// 位移超过一半时，直接触发删除（带确认）
const FULL = el.offsetWidth * 0.5
if (dx < -FULL) { confirmDelete(el); return }

// 否则吸附
const open = dx < -40          // 40px 是吸附判定线
el.style.transform = `translateX(${open ? -80 : 0}px)`
```

细节：
1. **同一时刻只允许一行处于滑开状态**。滑开新行时，关闭其他行。
2. 滑开状态下点击行本身，应先收起而不是进入详情。
3. 删除按钮的背景色用危险色，但**不要用纯红铺满整行** —— 视觉压力过大，
   只在滑开露出的 80px 区域显示。
4. 删除后要有撤销入口（`Toast` 里的「撤销」按钮，5 秒），
   误删是侧滑交互最贵的事故。
5. 列表虚拟滚动时，滑开状态要跟着数据走（存在 `Map<id, 'open'|'closed'>` 里），
   不能存在 DOM 上，否则滚动回来状态就丢了。

## 四、双指缩放

### 场景区分

| 场景 | 做法 |
| --- | --- |
| 图片查看器 | `touch-action: none` + 自己实现平移/缩放 |
| 页面局部放大 | `touch-action: pinch-zoom` 交给浏览器 |
| 地图 | 用地图库自带的，不要自己写 |

### 图片查看器的核心逻辑

```js
let scale = 1, tx = 0, ty = 0, startDist = 0, startScale = 1

function dist(t1, t2) { return Math.hypot(t2.clientX - t1.clientX, t2.clientY - t1.clientY) }
function center(t1, t2) {
  return { x: (t1.clientX + t2.clientX) / 2, y: (t1.clientY + t2.clientY) / 2 }
}

el.addEventListener('touchmove', (e) => {
  if (e.touches.length === 2) {
    const d = dist(e.touches[0], e.touches[1])
    if (!startDist) { startDist = d; startScale = scale; return }
    scale = clamp(startScale * (d / startDist), 1, 4)   // 限制在 1–4 倍
    // 以双指中点为缩放锚点，而不是元素中心
    const c = center(e.touches[0], e.touches[1])
    tx = c.x - (c.x - tx) * (scale / startScale)
    ty = c.y - (c.y - ty) * (scale / startScale)
    img.style.transform = `translate(${tx}px, ${ty}px) scale(${scale})`
  }
}, { passive: true })

el.addEventListener('touchend', () => {
  if (scale <= 1.05) { scale = 1; tx = 0; ty = 0; img.style.transform = '' }
  startDist = 0
})
```

关键点：
1. **缩放锚点必须是双指中点**。以元素中心缩放时，手指位置的内容会跑掉。
2. **缩放范围限制 1–4 倍**，超出后回弹。
3. **缩放后要限制平移边界**，否则可以把图片拖出屏幕再也找不回来。
4. 双击放大到 2 倍是标配：`dblclick` 或自己判定两次 tap 间隔 < 300ms。
5. 双指缩放时不要用 `transform: scale` 缩放整个容器，只缩放图片本身，
   否则会带动 UI 元素。

## 五、通用性能清单

- [ ] 所有动画只改 `transform` / `opacity`
- [ ] 手势过程中不读布局属性（`offsetTop`、`getBoundingClientRect`）
- [ ] `pointermove` / `touchmove` 用 `requestAnimationFrame` 节流
- [ ] 元素位置进入手势前一次性缓存
- [ ] 手势结束时清除内联 `transform`，交还给 CSS
- [ ] 列表超过 100 项时启用虚拟滚动
- [ ] 手势期间禁用 `:hover` 样式（触屏上 hover 会粘住）
- [ ] 用 `will-change: transform` 只加在正在拖拽的那一个元素上，结束就移除

```css
/* 触屏设备上禁用 hover */
@media (hover: none) {
  .row:hover { background: none; }
}
```

最后一条容易被忽略：触屏上 `:hover` 会在点击后粘住，
导致「点过的行一直是灰的」，用户以为选中了。
