# 屏幕阅读器标注与真机测试

## 一、VoiceOver（iOS）与 TalkBack（Android）的差异

| 维度 | VoiceOver（iOS） | TalkBack（Android） |
| --- | --- | --- |
| 开启方式 | 设置 → 辅助功能 → 旁白 | 设置 → 无障碍 → TalkBack |
| 逐项浏览 | 单指左右滑 | 单指左右滑 |
| 激活 | 单指双击 | 单指双击 |
| 滚动 | 三指上下滑 | 双指上下滑 |
| 返回 | 双指 Z 字形 | 系统返回键 |
| 忽略元素 | 尊重 `aria-hidden`，也尊重 `<span>` 无语义 | 行为基本一致，但更依赖 `role` |
| `role="alert"` | 会立即朗读 | 会立即朗读并震动 |
| 自定义操作 | 转子（Rotor，双指旋转） | 本地上下文菜单 |

结论：**两个平台都要测**。同一份标注在 iOS 上正确，在 Android 上可能读出不同结果，
尤其是 `role` 与 `tabindex` 的组合。

## 二、可访问名称的优先级

浏览器计算「可访问名称」的顺序（前一个存在则后面忽略）：

1. `aria-labelledby` 指向的元素文本
2. `aria-label`
3. 元素自身的文本内容（含 `sr-only` 文本）
4. `title` 属性（最弱，仅兜底）

```html
<!-- 优先级示例：最终读出的是「关闭弹窗」，不是「关闭」 -->
<button aria-labelledby="dlg-close" aria-label="关闭">关闭</button>
<span id="dlg-close" hidden>关闭弹窗</span>
```

实践建议：**优先用可见文本**，其次 `sr-only`，最后才用 `aria-label`。
`aria-label` 会覆盖可见文本，容易造成「看到的和听到的不一致」，
违反 WCAG 2.5.3（语音控制用户按可见文本说话会匹配不到）。

## 三、常用标注模式

### 图标按钮

```html
<button type="button" aria-label="搜索"><svg aria-hidden="true">…</svg></button>
<button type="button" aria-label="返回上一页"><svg aria-hidden="true">…</svg></button>
<button type="button" aria-label="关闭" aria-keyshortcuts="Escape">
  <svg aria-hidden="true">…</svg>
</button>
```

### 表单字段

```html
<label for="phone">手机号</label>
<input id="phone" type="tel" inputmode="tel" autocomplete="tel"
       required aria-required="true"
       aria-invalid="false" aria-describedby="phone-hint phone-err">
<p id="phone-hint" class="hint">用于接收订单通知</p>
<p id="phone-err" class="err" role="alert"></p>
```

- `aria-describedby` 可以指向多个 id（空格分隔），朗读顺序按书写顺序。
- `aria-invalid="true"` 会让部分屏幕阅读器在朗读字段时补一句「无效」。
- `required` + `aria-required` 同时写：前者触发浏览器校验，后者给屏幕阅读器。

### 开关与切换

```html
<!-- 用原生 checkbox，语义最完整 -->
<label class="switch">
  <input type="checkbox" role="switch" checked>
  <span class="track"><span class="thumb"></span></span>
  <span class="label">接收推送通知</span>
</label>
```

`role="switch"` 让屏幕阅读器朗读「开关，已开启」，
而原生 checkbox 会读「复选框，已勾选」。功能上等价，语义上 switch 更准确。

不要用 `<div onclick>` 做开关 —— 那样没有键盘支持、没有语义、无法朗读。

### 列表与列表项

```html
<ul role="list">
  <li>…</li>
</ul>
```

`role="list"` 在 `list-style: none` 之后需要显式加回 ——
Safari 与部分浏览器在移除列表样式后会同时移除列表语义。

### 折叠面板

```html
<button aria-expanded="false" aria-controls="panel-1">
  更多筛选条件
</button>
<div id="panel-1" hidden>…</div>
```

`aria-expanded` 的取值必须是字符串 `"true"` / `"false"`，切换时同步更新。

### 加载与状态

```html
<!-- 区域加载 -->
<div aria-busy="true" aria-live="polite">正在加载列表…</div>

<!-- 操作结果 -->
<div role="status" aria-live="polite">已保存</div>

<!-- 分页信息 -->
<div role="status" aria-live="polite">共 128 条，当前第 2 页</div>
```

`aria-busy="true"` 告诉屏幕阅读器「这个区域正在变化，先别读」，
加载完成后改为 `false` 并更新内容。

## 四、朗读顺序

屏幕阅读器按 DOM 顺序朗读，`tabindex` 为正数会打乱顺序（**永远不要用 `tabindex > 0`**）。

常见问题：视觉上「图标在左、文字在右」，但 DOM 里顺序反了，
导致朗读顺序与视觉顺序不一致。

```html
<!-- ❌ 视觉上图标在前，DOM 里图标在后 → 朗读「搜索 按钮」顺序混乱 -->
<button>搜索<svg>…</svg></button>

<!-- ✅ 用 flex-direction 调整视觉顺序，DOM 保持语义顺序 -->
<button><svg aria-hidden="true">…</svg>搜索</button>
```

```css
/* 需要视觉上图标在右时，用 order 而不是改 DOM */
button svg { order: 2; }
```

## 五、真机测试步骤

### iOS VoiceOver

1. 设置 → 辅助功能 → 旁白 → 打开。
2. Safari 打开页面。
3. 单指左右滑遍历所有元素，逐项检查：
   - 是否每项都读出了有意义的内容（不是「按钮」两个字）
   - 装饰性元素是否被跳过（背景图、分隔线）
   - 朗读顺序是否与视觉顺序一致
4. 双指旋转使用转子，切换「标题」「链接」「表单控件」快速跳转，确认结构完整。
5. 用「表单控件」转子快速跳到每个输入框，确认 label 被正确朗读。
6. 触发错误提示，确认 `role="alert"` 被朗读。
7. 打开弹窗，确认焦点移入、`Tab`/滑动只在弹窗内循环、关闭后焦点回到触发元素。

### Android TalkBack

1. 设置 → 无障碍 → TalkBack → 打开。
2. Chrome 打开页面。
3. 同样的遍历流程。
4. 特别注意：TalkBack 对 `role` 的依赖更强，
   如果某个元素读不出语义，加显式 `role`。

### 桌面侧检查（更快）

- Chrome DevTools → Elements → Accessibility 面板，看计算出的 Name / Role / States。
- 用「无障碍」面板顶部的 `Show accessibility tree` 选项，能直接看到被忽略的元素。
- 装 axe DevTools 扩展跑一次，能覆盖约 40% 的机械可检测问题（其余必须人工测）。

## 六、常见朗读问题与修法

| 听到的内容 | 问题 | 修法 |
| --- | --- | --- |
| 「按钮」 | 图标按钮无可访问名称 | 加 `aria-label` 或 `sr-only` 文本 |
| 「图片」 | `<img>` 无 `alt` | 装饰图 `alt=""`，内容图写清描述 |
| 「链接 链接 链接」 | 用链接做了按钮 | 改用 `<button>` |
| 「已勾选 已勾选」 | 自定义控件与原生控件重复 | 只保留一套语义 |
| 「1 2 3 4」 | 图标字体被逐字朗读 | 图标加 `aria-hidden="true"` |
| 「星星星星星」 | 评分组件未合并 | 外层 `aria-label="4 分，共 5 分"`，内部 `aria-hidden` |
| 跳过了整个区块 | 父元素有 `aria-hidden` 或 `display: none` | 检查祖先元素 |
| 顺序与视觉不符 | DOM 顺序与视觉顺序不一致 | 用 CSS `order` 调整视觉，不动 DOM |
| 「无效」读不出 | 只改了边框颜色 | 加 `aria-invalid` + `role="alert"` 文本 |

## 七、装饰性内容的处理

```html
<!-- 纯装饰的图标、分隔线、背景图 -->
<svg aria-hidden="true">…</svg>
<hr aria-hidden="true">
<div class="decor-bg" role="presentation"></div>

<!-- 内容图：必须有描述性 alt -->
<img src="chart.png" alt="2026 年 Q1 销售额环比增长 12%，达到 3400 万元">

<!-- 装饰图：空 alt（不是省略 alt！） -->
<img src="divider.svg" alt="">
```

`alt=""` 与没有 `alt` 的区别：前者明确告诉屏幕阅读器「跳过」，
后者会让部分阅读器朗读文件名（`divider dot svg`）。

图表必须提供**文本替代**：一句概括性描述 + 可展开的数据表格。
仅靠 `alt` 描述复杂图表是不够的。

## 八、检查清单

- [ ] VoiceOver 与 TalkBack 都真机走了一遍
- [ ] 所有图标按钮朗读出有意义的名称
- [ ] 装饰性元素被跳过，未被朗读成噪音
- [ ] 朗读顺序与视觉顺序一致
- [ ] 表单字段的 label 与提示文本被正确关联
- [ ] 错误提示用 `role="alert"` 并被朗读
- [ ] 弹窗焦点移入、循环、归还三件事都正确
- [ ] 加载态用 `aria-busy` 或 `role="status"`
- [ ] 没有 `tabindex` 大于 0 的元素
- [ ] 图表有文本替代（描述 + 数据表）
- [ ] 未使用 `display: none` 隐藏需要朗读的文本
- [ ] axe DevTools 扫描无 error 级问题
