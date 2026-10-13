# 虚拟滚动与固定列的落地细节

本文补齐 SKILL.md 里没展开的部分：虚拟滚动的固定行高算法、与固定列共存时的层级问题、
以及什么时候虚拟滚动反而不该用。

## 一、虚拟滚动的核心算法（固定行高）

固定行高是虚拟滚动能「简单又流畅」的前提。核心只有三件事：
总高度撑出滚动条、只渲染可见区、用 `transform` 把可见区推到正确位置。

```ts
const ROW_H = 40;
const BUFFER = 10;          // 上下各多渲染 10 行，防止快速滚动时白屏

function useVirtual(total: number, viewportH: number, scrollTop: number) {
  const start = Math.max(0, Math.floor(scrollTop / ROW_H) - BUFFER);
  const visible = Math.ceil(viewportH / ROW_H) + BUFFER * 2;
  const end = Math.min(total, start + visible);
  return { start, end, offsetY: start * ROW_H, totalH: total * ROW_H };
}
```

```html
<div class="viewport" style="height: 600px; overflow-y: auto;">
  <div style="height: {{totalH}}px; position: relative;">
    <div style="transform: translateY({{offsetY}}px);">
      <!-- 只渲染 start..end 行 -->
    </div>
  </div>
</div>
```

**BUFFER 取 10 的理由**：正常滚动一帧移动约 10–40px，10 行缓冲足以覆盖。
取 0 会在快速滚动时出现瞬间白屏；取 50 会让 DOM 节点数翻倍，收益递减。

**行高必须能被整除地使用**：`ROW_H = 40` 时 `scrollTop = 401` 落在第 10 行（401/40 = 10.025），
`translateY` 用 `start * ROW_H` 而不是原始 `scrollTop`，避免子像素抖动。

## 二、变高行的降级方案

如果行内容确实需要变高（多行备注、图片），有三条路，按推荐度排序：

1. **限制为固定行高 + 截断**（最推荐）。长文本用展开交互，展开时该行临时脱离虚拟列表，变为普通行。
2. **预测量**：渲染前用 `canvas.measureText` 估算高度，一次性算好所有行高数组，做前缀和定位。
   适合文本长度可预估的场景，成本中等。
3. **动态测量 + 缓存**（如 `react-virtual` 的 `measureElement`）。
   首次滚过某行后缓存其高度。**代价**：滚动条长度会跳动，快速滚动仍有白屏，实现复杂。
   只有前两条都不可行时才用。

## 三、虚拟滚动 + 固定列

固定列用 `position: sticky` 实现时，和虚拟滚动的 `transform` 会冲突 ——
`transform` 会创建新的包含块，导致 `sticky` 相对错误的祖先定位。

**解法**：固定列不用 `sticky`，用 `position: absolute` + 手动跟随横向滚动：

```tsx
<div className="viewport" onScroll={e => {
  setScrollTop(e.currentTarget.scrollTop);
  setScrollLeft(e.currentTarget.scrollLeft);   // 固定列据此位移
}}>
  <div className="canvas" style={{ height: totalH }}>
    <div className="rows" style={{ transform: `translateY(${offsetY}px)` }}>
      {rows.map(row => (
        <div className="row" style={{ display: 'flex' }}>
          <div className="col-fix-left"
               style={{ position: 'sticky', left: 0, zIndex: 2, background: rowBg(row) }}>
            {/* 固定列内容 */}
          </div>
          <div className="col-scroll" style={{ transform: `translateX(${scrollLeft}px)` }}>
            {/* 可滚动列内容 */}
          </div>
        </div>
      ))}
    </div>
  </div>
</div>
```

注意：每行一个 `sticky` 元素在 2000 行虚拟列表里只有可见的 ~30 个真实存在，
所以 `sticky` 其实是可行的 —— 关键是**不要让 `transform` 的祖先和 `sticky` 冲突**。
把 `transform` 放在行容器上，固定列放在行内用 `left: 0`，是可以工作的（行容器本身 `sticky` 的祖先链没有 `transform`）。

## 四、虚拟滚动的三个常见故障

| 症状 | 原因 | 修复 |
| --- | --- | --- |
| 滚动时行内容闪烁 | `key` 用了数组 index | `key` 必须用行数据的稳定 id |
| 表头跟着滚走了 | 表头放在了滚动容器内 | 表头独立于滚动容器，用同一份列宽配置 |
| 滚动条长度不对 | 总高度算错（用了可见行数而非总行数） | `height = total * ROW_H` |
| 键盘移动到不可见行无反应 | 没调 `scrollIntoView` | 移动选中行后 `el.scrollIntoView({ block: 'nearest' })` |
| 打印 / Ctrl+F 找不到内容 | 未渲染的行不在 DOM 里 | 提供「导出」或「打印视图」走全量渲染 |
| 屏幕阅读器读不到全部行 | 同上 | 给表格加 `aria-rowcount`，并在需要时降级为分页 |

## 五、什么时候不该用虚拟滚动

- **行数 < 200**：直接渲染更简单，虚拟滚动带来的收益抵不过复杂度。
- **需要浏览器 Ctrl+F 搜索**：虚拟滚动只有可见行在 DOM 里，浏览器搜索失效。
  如果用户强依赖 Ctrl+F（日志、代码类），改服务端搜索 + 分页。
- **需要打印**：打印视图必须是全量 DOM，虚拟滚动下会只打印出可见的 30 行。
- **行内有大图片 / 富交互**：虚拟滚动会频繁卸载重挂，图片会闪。

## 六、可访问性要求

虚拟滚动对读屏是最不友好的。最低要求：

- 表格元素加 `aria-rowcount={total}`，行加 `aria-rowindex`。
- 提供一个「跳转到第 N 行」的能力，让用户能到任意位置。
- 选中行变化时，用 `aria-live="polite"` 播报「已选中第 12 行，共 3024 行」。
- 如果数据对可访问性要求高（政务、医疗），**放弃虚拟滚动改用分页** —— 这是正确的取舍。
