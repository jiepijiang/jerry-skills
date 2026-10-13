# backdrop-filter 的性能、兼容与降级

## 一、为什么 backdrop-filter 贵

普通元素渲染：布局 → 绘制 → 合成，绘制结果可以缓存。
`backdrop-filter` 元素：**每次需要显示时，都要把「它背后已经绘制好的像素」重新采样一次**。

这条链路叫 Backdrop Root 采样：
1. 把该元素覆盖区域背后的所有图层合成到一个离屏纹理
2. 对这个纹理做高斯模糊（半径 r 对应 O(r) 的采样成本，实现上通常是多次降采样 + 上采样）
3. 应用 saturate / brightness 等滤镜
4. 把结果作为该元素的背景绘制

关键在于**第 1 步的结果无法长期缓存**：只要背后任何一个像素变了（滚动、动画、视频），
就必须重新走一遍。

成本经验值（1080×2400 的中端 Android 机型）：

| 玻璃层面积 | blur 半径 | 每帧额外耗时 |
| --- | --- | --- |
| 64×400（图标条） | 12px | < 1ms |
| 1080×56（吸顶导航） | 20px | 1–3ms |
| 1080×400（底部抽屉） | 20px | 4–8ms |
| 1080×2400（全屏遮罩） | 40px | 12–25ms |
| 全屏 × 3 层嵌套 | 20px | 30ms+（必掉帧） |

60fps 的预算是 16.7ms，所以**全屏玻璃 + 任何动画**在中端机上都不可行。

## 二、什么时候会从「可接受」变成「灾难」

1. **背后有视频或 canvas 动画** —— 每帧都变，缓存彻底失效
2. **玻璃层自身在动**（拖拽、过渡动画）—— 采样区域每帧变化
3. **多层嵌套** —— 成本是叠加的，不是取最大
4. **滚动容器里放玻璃** —— 列表项各自带 backdrop-filter 是最坏情况，
   50 个列表项 = 50 个采样区域
5. **大圆角** —— 圆角裁剪需要在采样时做 mask，额外一次 pass
6. **`border-radius: 50%` 的圆形玻璃** —— 同上，且边缘容易出现 1px 亮边

## 三、优化手段（按收益排序）

### 1. 缩小面积（收益最大）

全屏遮罩不要真的覆盖全屏。做法：只在需要的地方铺玻璃，其余区域用渐变过渡。

```css
/* 不好：整屏玻璃 */
.overlay { position: fixed; inset: 0; backdrop-filter: blur(24px); }

/* 好：只有顶部和底部两条 */
.overlay__top    { position: fixed; top: 0; height: 120px; backdrop-filter: blur(20px); }
.overlay__bottom { position: fixed; bottom: 0; height: 96px; backdrop-filter: blur(20px); }
```

### 2. 用 `will-change` 只在该动的时候开

```css
.drawer.is-animating { will-change: transform; }
```

常驻 `will-change: transform` 会永久占用一层 GPU 内存（1080×2400 ≈ 10MB），
移动端多开几层就 OOM。动画结束就移除。

### 3. 动画期间临时关掉模糊

抽屉从底部升起的过程中关掉 blur，落位后再打开：

```css
.drawer { transform: translateY(100%); backdrop-filter: none; }
.drawer.is-open { transform: translateY(0); backdrop-filter: blur(20px); }
/* 用 transitionend 在动画结束后加 .has-blur 类，避免动画期间每帧重采样 */
```

代价是落位瞬间会「啪」一下出现模糊，实际观感通常可以接受。

### 4. 列表项不要用 backdrop-filter

列表里的卡片用**半透明背景 + 描边**就够了，不需要真模糊。
只有悬浮在内容之上的单层元素（导航栏、浮动面板、Toast）才值得付这个成本。

## 四、Backdrop Root：模糊「失效」的元凶

规范里有一个概念叫 **Backdrop Root**。一个元素能模糊的，只是「它的 backdrop root 内部、
且在它之下」的像素。

以下属性会让元素成为新的 Backdrop Root：
- `filter`（任何非 none 值）
- `opacity` 小于 1
- `mask` / `mask-image`
- `mix-blend-mode` 非 normal
- `backdrop-filter` 本身
- `will-change` 指向上面任意一个
- `contain: paint`
- `transform` + 某些浏览器的特殊处理

**症状**：玻璃层看起来完全不模糊，或者只模糊了父容器内部的一点点内容。

**排查步骤**：
1. 在 DevTools 里选中玻璃元素，往上逐层检查 computed style
2. 找第一个有 `filter` / `opacity < 1` / `mask` / `contain: paint` 的祖先
3. 把它改成不创建 backdrop root 的写法

最常见的三个真实场景：

```css
/* 1. 父级用了 opacity 做淡入 */
.fade-in { opacity: 0; transition: opacity .3s; }
.fade-in.is-visible { opacity: 1; }   /* 即使最后是 1，只要声明过动画期间就是 root */
/* 改：动画结束后移除 opacity 相关类，或用 visibility + transform 代替 */

/* 2. 父级加了 filter 做灰度/模糊装饰 */
.hero { filter: blur(40px); }         /* 装饰性色块 */
.glass-card { backdrop-filter: blur(16px); }  /* 这个会失效 */
/* 改：把装饰性色块放在玻璃元素之后的兄弟节点，用 z-index 压到下面 */

/* 3. 用了 mix-blend-mode 做叠加 */
.overlay { mix-blend-mode: overlay; }
/* 改：改用 background-blend-mode 或直接调色，不要用 mix-blend-mode 包玻璃 */
```

## 五、兼容性矩阵

| 浏览器 | 支持情况 |
| --- | --- |
| Safari 9+ / iOS Safari 9+ | 需要 `-webkit-backdrop-filter` |
| Chrome / Edge 76+ | 无前缀支持 |
| Firefox 103+ | 无前缀支持（103 之前需 `layout.css.backdrop-filter.enabled`） |
| Samsung Internet 12+ | 支持 |
| 微信内置浏览器（iOS） | 跟随系统 WKWebView，Safari 14+ 的版本支持，需前缀 |
| 微信内置浏览器（Android） | 跟随 X5/Chromium 内核，较新版本支持 |
| 旧版 Android WebView（< 76） | 不支持，必须降级 |

**结论**：写 CSS 时永远同时写 `-webkit-` 前缀版。
`@supports` 检测也要两个都写：

```css
@supports not ((backdrop-filter: blur(1px)) or (-webkit-backdrop-filter: blur(1px))) {
  .glass-card {
    background: rgba(255, 255, 255, 0.92);
    border: 1px solid rgba(0, 0, 0, 0.08);
  }
}
```

## 六、降级方案的分级

不要只做「有 / 没有」两档，按能力分三档：

```css
/* 第 1 档：完整玻璃（默认写法） */
.glass { background: rgba(255,255,255,.16); backdrop-filter: blur(16px) saturate(180%); }

/* 第 2 档：支持 rgba 但不支持 backdrop-filter → 提高不透明度 */
@supports not ((backdrop-filter: blur(1px)) or (-webkit-backdrop-filter: blur(1px))) {
  .glass { background: rgba(255,255,255,.92); }
}

/* 第 3 档：用户要求减少透明度 → 完全实心 */
@media (prefers-reduced-transparency: reduce) {
  .glass { backdrop-filter: none; background: var(--surface); }
}

/* 第 4 档：用户开了省电 / 减少动画，也要考虑 */
@media (prefers-reduced-motion: reduce) {
  .glass { transition: none; }
}
```

第 2 档和第 3 档必须都做。第 2 档解决「老浏览器看起来是一块几乎透明的玻璃、文字读不了」，
第 3 档解决「用户主动要求不透明」。

## 七、验证流程

1. **桌面 DevTools**：Rendering → Paint flashing，滚动看玻璃区是否持续闪烁（持续闪 = 每帧重绘）
2. **Performance 录制**：滚动 3 秒，看是否有超过 16.7ms 的帧，`Composite Layers` 占比
3. **Layers 面板**：看玻璃元素是否被提升为独立合成层，层数是否失控
4. **真机**：中端 Android（不要用旗舰机测）+ iPhone 的「低电量模式」（会降频）
5. **系统设置**：打开 iOS「降低透明度」、Android「移除动画」，确认界面仍可用
6. **截图对比**：导出 PNG 时确认模糊是否保留（很多导出工具会丢 backdrop-filter）
