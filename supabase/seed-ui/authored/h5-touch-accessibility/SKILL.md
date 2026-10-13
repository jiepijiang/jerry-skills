---
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
