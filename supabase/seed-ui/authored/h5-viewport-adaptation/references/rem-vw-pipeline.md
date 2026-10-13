# rem / vw 适配流水线

## 一、先决定设计稿宽度

| 设计稿 | 适用 | 换算基准 |
| --- | --- | --- |
| 375 | 主流 iOS 逻辑宽度，标注直观 | `1vw = 3.75px` |
| 390 / 393 | iPhone 14 / 15 实际宽度 | `1vw = 3.9 / 3.93px` |
| 750 | 2 倍图物理像素（老派） | `1vw = 7.5px` |
| 1440 | 桌面端设计稿，H5 复用 | 不建议直接复用，需重排 |

**推荐 375**：它是「逻辑像素」而不是物理像素，和浏览器里 `clientWidth` 直接对应，
换算时不用再除以 2。

## 二、方案 A：vw + PostCSS（推荐新项目）

```bash
npm i -D postcss postcss-px-to-viewport-8-plugin
```

```js
// postcss.config.js
export default {
  plugins: {
    'postcss-px-to-viewport-8-plugin': {
      unitToConvert: 'px',
      viewportWidth: 375,          // 设计稿宽度
      unitPrecision: 5,
      propList: ['*', '!font-size', '!border*'],  // 字号与边框不转换
      viewportUnit: 'vw',
      fontViewportUnit: 'vw',
      selectorBlackList: ['.no-vw'],   // 需要保留 px 的类名
      minPixelValue: 2,                // 小于 2px 不转（保护 1px 线）
      mediaQuery: false,
      replace: true,
      landscape: false,
    },
  },
}
```

关键配置解释：
- `propList` 排除 `font-size` 和 `border*`：字号要单独用 `clamp()` 控制，
  边框要用 transform 方案，**不能被自动转成 vw**。
- `minPixelValue: 2`：保护 1px 边框不被转换。
- `landscape: false`：横屏不单独换算，避免横屏时字体突然变大。

**这个方案最大的坑**：vw 会让用户的浏览器字号设置完全失效
（在 Chrome 设置里把字号调到 24px，页面文字纹丝不动）。
无障碍要求下必须对 `font-size` 单独处理。

## 三、方案 B：rem + 运行时脚本

```html
<script>
  (function () {
    function setRoot() {
      var w = document.documentElement.clientWidth
      var size = Math.min(20, Math.max(13, 16 * (w / 375)))
      document.documentElement.style.fontSize = size + 'px'
    }
    setRoot()
    window.addEventListener('resize', setRoot)
    window.addEventListener('orientationchange', function () {
      setTimeout(setRoot, 300)
    })
    window.addEventListener('pageshow', function (e) {
      if (e.persisted) setRoot()   // bfcache 恢复时重算
    })
  })()
</script>
```

或构建期转换：

```js
// postcss.config.js
'postcss-pxtorem': { rootValue: 16, propList: ['*'], minPixelValue: 2 }
```

rem 方案的问题：
1. 需要运行时 JS，首屏会有一次重排（字体大小变化触发）。
2. 根字号被任何第三方库或用户脚本改动，全站尺寸立刻崩。
3. 系统字号放大（iOS 辅助功能「更大字体」）不会生效，因为根字号是 JS 写死的。

**折中做法**：rem 只用于布局尺寸，字号用 `rem` + `clamp` 混合：

```css
:root { font-size: clamp(13px, 4.267vw, 20px); }
p { font-size: 1rem; }          /* 跟随根字号，但有上下限 */
.tight { font-size: 0.75rem; }  /* 375 下 = 12px */
```

这样纯 CSS，无 JS，且字号有上下限。**新项目首选这个。**

## 四、方案 C：纯 px + 弹性布局

只做以下事情，不缩放：

```css
/* 容器用 % / flex / grid，元素用 px */
.card { display: flex; gap: 12px; padding: 16px; }
.card__body { flex: 1 1 auto; min-width: 0; }
```

适用：内容型页面（文章、表单、列表），元素尺寸本来就不该随屏幕等比放大。
不适用：需要严格还原设计稿视觉比例的营销页（Banner 排版、活动页）。

判断标准：**如果「把 375 的设计稿按比例放大到 430」会让设计变难看，就用 px 方案。**

## 五、混用规则（现实中最多的情况）

| 元素 | 单位 | 理由 |
| --- | --- | --- |
| 字号 | `clamp(px, vw, px)` 或 `rem` | 需要上下限，兼顾可读性 |
| 间距 / 内边距 | `px` | 16px 的间距在 430 屏上不需要变成 18px |
| 图标尺寸 | `px` | 图标有最小可辨识尺寸，缩放会糊 |
| 容器宽高 | `%` / `vw` / `flex` | 跟随屏幕 |
| 圆角 | `px` | 8px 圆角是视觉语言，不缩放 |
| 1px 线 | `px` + `transform` | 见 SKILL.md |
| 大图 / 插画 | `%` + `aspect-ratio` | 保持比例 |
| 安全区 | `env()` | 系统提供 |

结论：**真正需要「等比缩放」的只有极少数组件**。
大多数团队上 rem/vw 是为了「省事」，代价是无障碍和可预测性，值得重新评估。

## 六、验证流水线

```bash
# 1. 构建后确认没有意外的 vw 字号
grep -rn "font-size:.*vw" dist/*.css | grep -v clamp
# 期望：无输出（字号都在 clamp 里）

# 2. 确认 1px 线没被转换
grep -rn "border.*0\.[0-9]vw" dist/*.css
# 期望：无输出

# 3. 确认 px 残留量在合理范围
grep -o "[0-9]\+px" dist/*.css | wc -l
```

浏览器侧验证：
1. DevTools 里把设备设为 320 / 375 / 414 / 430，看有无横向滚动条。
2. Chrome 设置里把默认字号调到 24px，刷新页面，文字应变大（否则说明 vw 字号没保护）。
3. 开启系统「减少动态效果」与「更大字体」，检查布局不破。

## 七、检查清单

- [ ] 设计稿宽度已写进配置（`viewportWidth: 375`），团队内统一
- [ ] `font-size` 与 `border*` 已排除自动转换
- [ ] 字号全部在 `clamp()` 里，320 宽下不小于 12px
- [ ] `minPixelValue: 2` 已设置，1px 线未被转成 vw
- [ ] rem 方案的根字号有上下限（13–20px）
- [ ] `orientationchange` 后延迟 300ms 重算
- [ ] `pageshow`（bfcache）时重算根字号
- [ ] 构建产物里没有裸 `font-size: Xvw`
- [ ] 浏览器调大默认字号后页面文字确实变大
- [ ] 320 / 375 / 414 / 430 四档无横向滚动
