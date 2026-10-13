# 加载态与骨架屏实现细节

骨架屏的目标不是「好看」，是**让加载过程中的布局稳定、让用户知道在等什么**。
本文给出延迟策略的封装、各类组件的骨架形状、以及避免布局偏移的要点。

## 一、为什么需要「延迟 + 最短展示」

朴素的实现是 `isLoading ? <Skeleton/> : <Content/>`。问题有两个：

1. **闪一下**：请求 80ms 就返回时，骨架屏只出现 80ms，用户看到一次闪烁，比直接显示内容更糟。
2. **抖动**：骨架屏和真实内容的高度不一致时，切换瞬间页面跳动（CLS 变大）。

解法是包一层状态机：

```ts
function useDelayedLoading(loading: boolean, { delay = 200, minDuration = 200 } = {}) {
  const [visible, setVisible] = useState(false);
  const shownAt = useRef(0);

  useEffect(() => {
    if (loading) {
      const t = setTimeout(() => { setVisible(true); shownAt.current = Date.now(); }, delay);
      return () => clearTimeout(t);
    }
    if (!visible) return;
    const elapsed = Date.now() - shownAt.current;
    const t = setTimeout(() => setVisible(false), Math.max(0, minDuration - elapsed));
    return () => clearTimeout(t);
  }, [loading, visible, delay, minDuration]);

  return visible;
}
```

- `delay: 200ms` —— 快速请求不显示骨架屏。
- `minDuration: 200ms` —— 一旦显示，至少停留 200ms。
- 两个值都取 200 是有依据的：200ms 是人感知「即时」的阈值（Nielsen 的 0.1s 即时 / 1s 保持注意力的经验值），
  低于这个量的加载提示反而制造噪音。

**例外**：首屏（首次进入页面）可以直接显示骨架屏，不需要延迟 ——
首屏本来就有路由切换的白屏时间，延迟反而让空白更久。

## 二、骨架屏的形状要对应真实内容

| 组件 | 骨架形状 | 高度 |
| --- | --- | --- |
| 表格 | 表头 + 5 行灰条，列宽与真实列一致 | 行高 40 |
| 详情页 | 每个字段一组「label 短条 + value 长条」 | 与真实字段等高 |
| 统计卡 | 大数字条 + 小标签条 | 与卡片等高（如 96px） |
| 图表 | 与图表同高的矩形块（可用简单的柱状轮廓） | 与图表等高 |
| 列表项（头像 + 两行） | 圆形 40 + 两条横线 | 与列表项等高 |
| 正文段落 | 5–7 条不等宽的横线 | 每行 16px + 8px 间距 |

**关键**：骨架屏的**总高度必须等于真实内容的高度**。做不到精确相等时，
宁可让骨架屏略高，也不要略低 —— 略高时切换是「收缩」，略低是「撑开 + 滚动条出现」，后者更明显。

## 三、扫光动画

```css
.skeleton {
  background: #eaecf0;
  border-radius: 4px;
  position: relative;
  overflow: hidden;
}
.skeleton::after {
  content: '';
  position: absolute; inset: 0;
  background: linear-gradient(90deg, transparent, rgba(255,255,255,.6), transparent);
  transform: translateX(-100%);
  animation: shimmer 1.5s infinite;
}
@keyframes shimmer { to { transform: translateX(100%); } }

@media (prefers-reduced-motion: reduce) {
  .skeleton::after { animation: none; }
}
```

- 周期 1.5s。快于 1s 显得焦躁，慢于 2s 显得卡顿。
- 用 `transform` 做位移（GPU 加速），**不要**用 `background-position`（触发重绘）。
- 必须响应 `prefers-reduced-motion`：关掉动画，保留静态灰块。
- 灰块颜色取内容背景与文字色之间的中间值。浅色主题 `#eaecf0`，深色主题 `#1f2937`。
- **不要**用 JS `setInterval` 逐个闪烁每一条 —— 几百个 DOM 节点各自定时器，主线程会抖。

## 四、局部加载的三种形态

| 形态 | 何时用 | 做法 |
| --- | --- | --- |
| 骨架屏替换 | 首次加载，无任何内容 | 用骨架占位 |
| 半透明遮罩 | 已有内容，重新加载（翻页、换筛选） | 内容加 `opacity: .6` + 居中 spinner |
| 顶部进度条 | 路由切换、不确定时长的操作 | 2px 高进度条，不遮挡内容 |

**翻页时用骨架屏是错的**：用户已经看到第 1 页的内容，翻页时把内容全抹成灰条，
会产生「我的数据呢」的错觉。正确做法是保留旧内容 + 半透明遮罩 + 小 spinner，
数据回来再替换。

## 五、按钮的加载态

```tsx
<Button loading={submitting} disabled={submitting}>
  {submitting ? '保存中…' : '保存'}
</Button>
```

- 加载时按钮**必须禁用**，防止重复提交。
- 文案从「保存」变成「保存中…」，比只转个圈更明确。
- spinner 放在文字**左侧**，不要替换文字（宽度变化会导致按钮跳动）。
- 按钮宽度在加载前后保持不变：给一个 `min-width`，或让 spinner 绝对定位不占位。
- 如果提交超过 3 秒，追加提示「处理中，请勿关闭页面」。
- 超过 10 秒仍无响应，给「取消」或超时提示（见 error-copywriting 的「提交结果未知」）。

## 六、避免布局偏移（CLS）

后台的 CLS 主要来自四处，逐一处理：

1. **图片无尺寸** → 给 `width` / `height` 或 `aspect-ratio`，不要等加载完才知道多大。
2. **骨架屏与内容高度不一致** → 见第二节，宁可略高。
3. **字体加载导致文字重排** → `font-display: swap` + 后备字体度量接近（`size-adjust`）。
4. **动态插入的内容**（如「已选条件」标签行）→ 预留位置（`min-height`），
   出现时不要推动下方内容。

目标：单次交互的 CLS < 0.1（Core Web Vitals 的「good」阈值）。

## 七、进度反馈的边界

- **< 1s**：不需要任何加载提示（但要防重复提交）。
- **1–10s**：spinner / 骨架屏 + 明确文案。
- **> 10s**：进度百分比或分步骤提示（「正在导入第 3/10 批」）。
- **> 30s**：转为后台任务，给「任务已提交，完成后通知你」，不要让用户干等。
- **不确定时长**：用不确定进度条（来回滚动的），**不要**用假的百分比 ——
  假进度到 99% 卡住比没有进度更让人抓狂。
