# 安全区与机型差异实测参考

数值为 CSS 逻辑像素，随系统版本可能微调，**代码里一律用 `env()` 而不是硬编码**。
这里列出数值只是为了让你在设计稿阶段心里有数、以及在真机上排查时对照。

## 一、竖屏安全区

| 机型 | `safe-area-inset-top` | `safe-area-inset-bottom` |
| --- | --- | --- |
| iPhone SE 2/3 | 20 | 0 |
| iPhone 8 | 20 | 0 |
| iPhone X / XS / 11 Pro | 44 | 34 |
| iPhone XR / 11 | 48 | 34 |
| iPhone 12 / 13 / 14 | 47 | 34 |
| iPhone 12 mini / 13 mini | 50 | 34 |
| iPhone 14 Pro / 15 / 15 Pro | 59 | 34 |
| iPhone 15 Pro Max / 16 Pro | 62 | 34 |
| 主流 Android（无刘海） | 0 | 0 |
| Android 挖孔屏 | 0（内容区避开由系统处理） | 0 |

要点：
- **底部 34px 是绝大多数全面屏 iPhone 的值**，不是 30 也不是 40。
- 顶部差异极大（20 → 62），所以顶部导航绝对不能用固定值。
- Android 在 Chrome 里通常返回 0，因为系统把状态栏算在视口之外了 ——
  这意味着**安卓上不需要额外加顶部留白**，而 iOS 上需要，两者不能共用一套 padding。

## 二、横屏安全区

横屏时刘海跑到左右两侧：

| 机型 | `left` / `right` | `top` | `bottom` |
| --- | --- | --- | --- |
| iPhone X 及以后（横屏） | 44 | 0 | 21 |
| iPhone 14 Pro 及以后（横屏） | 59 | 0 | 21 |

横屏的 `top` 变成 0（状态栏隐藏），`bottom` 变成 21（Home Indicator 变窄）。
**如果你只在竖屏测过，横屏一定出问题**，尤其是全屏播放器和全屏地图。

## 三、安全区的三种使用姿势

```css
/* ① 固定元素：把安全区叠加进 padding */
.fixed-bottom {
  padding-bottom: calc(12px + env(safe-area-inset-bottom, 0px));
}

/* ② 内容区：只在有安全区时增加留白，避免安卓上多出空白 */
.safe-pad { padding-inline: env(safe-area-inset-left, 0px) env(safe-area-inset-right, 0px); }

/* ③ 背景延伸但内容不延伸（常见于通栏卡片） */
.card-full {
  margin-inline: calc(-1 * env(safe-area-inset-left, 0px))
                 calc(-1 * env(safe-area-inset-right, 0px));
  padding-inline: calc(16px + env(safe-area-inset-left, 0px))
                  calc(16px + env(safe-area-inset-right, 0px));
}
```

③ 的用法很实用：横屏时卡片背景铺满到屏幕边缘，但文字仍然避开刘海。

## 四、`viewport-fit` 的三个取值

| 值 | 含义 | 什么时候用 |
| --- | --- | --- |
| `auto` | 默认，内容被限制在安全区内 | 不打算处理安全区 |
| `contain` | 视口完全包含在安全区内 | 几乎不用 |
| `cover` | 视口铺满整屏，露出安全区 | **要用 `env()` 就必须选它** |

注意：设了 `cover` 之后，页面会铺到刘海下面，
所以**必须主动给所有顶部/底部固定元素加安全区留白**，
否则内容会被状态栏和时间重叠。这是「加了 `cover` 页面变难看」的唯一原因。

## 五、软键盘高度参考

| 平台 / 输入法 | 键盘高度（约） |
| --- | --- |
| iOS 英文全键盘 | 216–291 |
| iOS 中文九宫格 | 291 |
| iOS 中文全键盘 | 291 |
| Android 英文 | 240–280 |
| Android 中文（搜狗/百度） | 280–320 |
| 带工具栏的输入法（候选词、表情栏） | 再 +44 |

结论：**给键盘预留的空间不能小于 320px**，否则在中文输入法下会遮住输入框。
实践做法不是预留固定高度，而是用 `visualViewport` 动态响应。

## 六、`visualViewport` 的可靠用法

```js
const vv = window.visualViewport
if (vv) {
  let raf = 0
  const onResize = () => {
    cancelAnimationFrame(raf)
    raf = requestAnimationFrame(() => {
      const kb = window.innerHeight - vv.height - vv.offsetTop
      document.documentElement.style.setProperty('--kb-h', Math.max(0, kb) + 'px')
    })
  }
  vv.addEventListener('resize', onResize)
  vv.addEventListener('scroll', onResize)   // iOS 键盘弹出时会触发 scroll
}
```

三个容易踩的点：
1. **iOS 上键盘弹出时 `visualViewport.scroll` 会触发，`resize` 有时不触发**，
   两个事件都要监听。
2. `vv.offsetTop` 在页面被上推时不为 0，必须减掉，否则算出的键盘高度偏小。
3. 事件触发频率极高，必须用 `requestAnimationFrame` 节流，否则输入时会掉帧。

## 七、真机排查清单

在真机上按顺序检查（桌面模拟器测不出这些）：

- [ ] iPhone 竖屏：底部按钮完整可见，不被 Home Indicator 遮挡
- [ ] iPhone 横屏：左右内容不被圆角/刘海裁切
- [ ] iPhone Safari：下拉刷新时页面顶部不出现白色空隙（`overscroll-behavior`）
- [ ] iPhone Safari：滚动到顶部时导航栏是否被地址栏覆盖
- [ ] iPhone：输入框聚焦后，提交按钮仍然可点
- [ ] iPhone：中文输入法下，候选词栏不遮挡输入框
- [ ] Android Chrome：键盘弹出后 `100vh` 容器是否被压扁
- [ ] Android：返回键行为是否符合预期（不能直接退出 H5）
- [ ] 微信内置浏览器：顶部标题栏是否遮挡页面内容
- [ ] 微信内置浏览器：底部工具栏是否遮挡固定操作栏

## 八、微信内置浏览器额外注意

- 微信 iOS 端的 WebView 顶部**没有额外安全区**，`safe-area-inset-top` 是 0，
  因为微信的标题栏已经占掉了。如果页面自己在顶部再加 44px，就会出现多余空白。
- 微信安卓端有 `safe-area-inset-bottom`（用于小程序胶囊/导航），H5 里通常为 0。
- 结论：**同一份代码在微信内和微信外表现不同**，
  需要判断 UA（`MicroMessenger`）来决定是否叠加顶部安全区。
