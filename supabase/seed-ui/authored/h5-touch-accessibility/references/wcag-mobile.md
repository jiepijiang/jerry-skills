# WCAG 2.2 移动端相关条款与验证方法

只列与触屏 / 移动端 H5 直接相关的条款。等级：A（最低）、AA（常规目标）、AAA（增强）。

## 一、触屏操作类

### 2.5.1 Pointer Gestures（A）

**要求**：多指或路径手势必须有单指替代（除非该手势是必要的）。

| 手势 | 必须提供的替代 |
| --- | --- |
| 双指缩放地图 | +/− 按钮 |
| 双指旋转 | 角度输入或「旋转 90°」按钮 |
| 画 Z 字返回 | 返回按钮 |
| 三指滑动 | 单指可完成的等价操作 |

验证：只用一根手指，能否完成所有功能。

### 2.5.2 Pointer Cancellation（A）

**要求**：动作在 `up` 事件触发，而不是 `down`；或 `down` 触发后可以取消。

反例：`touchstart` 就执行删除 —— 用户手指滑过就误删了。

验证：在按钮上按下后手指滑出按钮再松开，动作不应执行。

### 2.5.3 Label in Name（A）

**要求**：可访问名称必须包含可见文本。

反例：按钮显示「提交」，`aria-label="确认订单"`。

验证：语音控制（iOS 语音控制 / Android 语音访问）说可见文本，能否激活。

### 2.5.4 Motion Actuation（A）

**要求**：靠设备运动（摇一摇、倾斜）触发的功能必须有 UI 替代，且能被关闭。

验证：摇一摇抽奖类功能，是否有可点击的替代入口。

### 2.5.7 Dragging Movements（AA，WCAG 2.2 新增）

**要求**：需要拖拽才能完成的操作，必须能用单指的非拖拽方式完成。

| 拖拽场景 | 必须提供的替代 |
| --- | --- |
| 拖拽排序 | 上移 / 下移按钮，或「移动到…」选择器 |
| 拖拽调整滑块 | 点击轨道跳转 + 左右微调按钮 |
| 侧滑删除 | 行内的删除按钮或长按菜单 |
| 拖拽上传 | 文件选择按钮 |
| 拖拽调整分栏宽度 | 预设档位按钮 |

这一条是 WCAG 2.2 新增的 AA 级要求，移动端最容易踩。

验证：不用拖拽，能否完成排序/调整/删除。

### 2.5.8 Target Size (Minimum)（AA，WCAG 2.2 新增）

**要求**：指针目标的尺寸至少 24×24 CSS px，除非：
- 有足够的间距（圆形不相交原则）；
- 目标在句子/文本块内（如行内链接）；
- 目标由用户代理决定且未被修改；
- 该尺寸对功能是必要的（如地图上的精确点位）。

**实践建议**：移动端按 **44×44** 做（同时满足 Apple HIG 与 Material 的 48dp 建议）。

验证：DevTools 里量每个可点元素的盒模型（含 padding 与伪元素撑开的区域）。

## 二、视觉类

### 1.4.1 Use of Color（A）

**要求**：颜色不是传达信息的唯一手段。

检查清单：
- [ ] 错误状态：颜色 + 图标 + 文字
- [ ] 必填标记：颜色 + 星号 + `aria-required`
- [ ] 图表分类：颜色 + 形状 + 图例文字
- [ ] 链接：颜色 + 下划线（正文内链接）
- [ ] 状态标签：色 + 文字

### 1.4.3 Contrast (Minimum)（AA）

- 正文（< 18.66px 或 < 24px）：**≥ 4.5:1**
- 大字（≥ 18.66px 粗体 或 ≥ 24px）：**≥ 3:1**

「大字」的准确判据：`font-size ≥ 18.66px` 且 `font-weight ≥ 700`，
或 `font-size ≥ 24px`（任意字重）。18.66px 来自 14pt 的换算。

### 1.4.4 Resize Text（AA）

**要求**：文本可以放大到 200% 而不丢失内容或功能。

移动端注意：`user-scalable=no` 直接违反此条。**必须移除**。

### 1.4.10 Reflow（AA）

**要求**：320 CSS px 宽（相当于 400% 缩放）下不出现双向滚动，内容不丢失。

验证：DevTools 设宽度 320px，确认无横向滚动条（表格等特殊内容除外，
但必须能纵向滚动访问到全部内容）。

### 1.4.11 Non-text Contrast（AA）

**要求**：UI 组件边界与图形对象对比度 ≥ 3:1。

适用对象：
- 输入框、下拉框、复选框的**边框**
- 图标的线条
- 图表中的数据线
- 开关的轨道与滑块（开启/关闭状态之间要能区分）

高频不合格项：输入框边框用 `#d9d9d9`（1.4:1）、禁用态文字用 `#bfbfbf`。

### 1.4.12 Text Spacing（AA）

**要求**：强制以下样式后内容不丢失：

```css
* {
  line-height: 1.5 !important;
  letter-spacing: 0.12em !important;
  word-spacing: 0.16em !important;
}
p { margin-bottom: 2em !important; }
```

验证：用 DevTools 注入上述样式，检查文字是否被截断或重叠。

### 1.4.13 Content on Hover or Focus（AA）

**要求**：悬停/聚焦出现的内容必须可关闭、可悬停、且持续存在。

移动端表现：长按出现的提示不能一松手就消失，也不能遮挡关键内容。

## 三、结构与导航类

### 1.3.4 Orientation（AA）

**要求**：不限制屏幕方向，除非方向对功能是必要的（如钢琴键盘）。

移动端常见违规：竖屏专用的「请横屏使用」遮罩。
除非真的是必需（如视频播放器的全屏模式），否则必须支持两个方向。

### 1.3.5 Identify Input Purpose（AA）

**要求**：收集用户信息的输入框必须有程序可识别的用途标识。

实现方式就是 `autocomplete`：

```html
<input name="name" autocomplete="name">
<input name="tel" autocomplete="tel">
<input name="email" autocomplete="email">
<input name="zip" autocomplete="postal-code">
```

### 2.4.3 Focus Order（A）

**要求**：焦点顺序保持有意义。

移动端注意：`tabindex` 大于 0 会打乱顺序，**禁止使用**。

### 2.4.7 Focus Visible（AA）

**要求**：键盘焦点必须可见。

移动端注意：外接键盘（iPad）与辅助开关设备会用到焦点。
不能因为「移动端不用键盘」就 `outline: none`。

### 2.4.11 Focus Not Obscured (Minimum)（AA，WCAG 2.2 新增）

**要求**：获得焦点的组件不能被作者内容完全遮挡。

移动端典型违规：焦点元素被吸顶导航或吸底操作栏盖住。
修法：聚焦时 `scrollIntoView({ block: 'center' })`，
并给滚动容器加上等于吸顶/吸底高度的 `scroll-margin-top` / `scroll-margin-bottom`。

```css
input, button, a {
  scroll-margin-top: 64px;      /* 吸顶栏高度 */
  scroll-margin-bottom: 72px;   /* 吸底栏高度 + 安全区 */
}
```

### 2.4.13 Focus Appearance（AAA）

**要求**：焦点指示器面积至少等于 2px 周长的等效面积，对比度 ≥ 3:1。

实践：`outline: 2px solid` + `outline-offset: 2px`。

## 四、动效与时间类

### 2.2.2 Pause, Stop, Hide（A）

**要求**：自动播放、自动更新、自动滚动的内容超过 5 秒必须能暂停/停止/隐藏。

移动端典型违规：自动轮播 Banner、自动滚动的公告、自动更新的行情。

### 2.3.1 Three Flashes（A）

**要求**：闪烁不超过每秒 3 次。

移动端典型违规：促销页的闪烁倒计时、频闪灯效。

### 2.3.3 Animation from Interactions（AAA）

**要求**：交互动画可以被关闭（除非是必要动效）。

实现即 `prefers-reduced-motion: reduce`。

```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
  }
}
```

## 五、验证方法

| 条款 | 自动化 | 人工 |
| --- | --- | --- |
| 1.4.1 颜色 | ❌ | 灰度截图 / 色盲模拟滤镜 |
| 1.4.3 对比度 | ✅ axe / Lighthouse | 抽查复杂背景 |
| 1.4.10 Reflow | ⚠️ 部分 | 320px 宽实测 |
| 1.4.11 非文本对比度 | ⚠️ 部分 | 逐个 UI 组件量 |
| 2.4.7 焦点可见 | ⚠️ 部分 | Tab 遍历 |
| 2.4.11 焦点遮挡 | ❌ | Tab 遍历 + 观察是否被吸顶栏遮住 |
| 2.5.1 手势替代 | ❌ | 单指完成全部功能 |
| 2.5.7 拖拽替代 | ❌ | 不用拖拽完成排序 |
| 2.5.8 目标尺寸 | ✅ 自定义脚本 | DevTools 量盒模型 |
| 2.3.3 动效 | ❌ | 开启系统减弱动效后走一遍 |

**自动化工具只能覆盖约 30–40% 的问题**。剩余的必须真机人工验证，
尤其是手势替代、焦点遮挡、动效这三类。

## 六、检查清单（验收用）

- [ ] 所有功能可用单指完成，无多指/路径手势独占
- [ ] 所有拖拽操作有非拖拽替代
- [ ] 所有可点目标 ≥ 44×44 CSS px，相邻不重叠
- [ ] 正文对比度 ≥ 4.5:1，大字 ≥ 3:1，UI 边界 ≥ 3:1
- [ ] 未使用 `user-scalable=no`
- [ ] 320px 宽下无横向滚动
- [ ] 强制 `line-height: 1.5` 等样式后内容不丢失
- [ ] 支持横竖屏（无「请横屏使用」遮罩）
- [ ] 所有输入框有 `autocomplete`
- [ ] 无 `tabindex > 0`
- [ ] 焦点可见且不被吸顶/吸底栏遮挡
- [ ] 自动轮播可暂停，且 ≤ 5s 内可控制
- [ ] 无每秒 3 次以上闪烁
- [ ] 响应 `prefers-reduced-motion`
- [ ] 屏幕阅读器可完整走完主流程
- [ ] axe / Lighthouse 扫描无 error 级问题
