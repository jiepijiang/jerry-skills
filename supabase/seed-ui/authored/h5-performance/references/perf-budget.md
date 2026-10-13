# 性能预算与监控落地

## 一、预算表（可直接抄进项目文档）

### 资源体积

| 资源 | 预算（gzip/br 后） | 超限处理 |
| --- | --- | --- |
| 首屏 HTML | 30KB | 拆 SSR 数据、去掉内联大 JSON |
| 关键 CSS（内联） | 14KB | 拆分组件样式 |
| 全量 CSS | 80KB | 按路由拆分 |
| 首屏 JS | 170KB | 路由级 code splitting |
| 单个路由 JS（懒加载） | 120KB | 继续拆组件 |
| 首屏图片合计 | 400KB | 换 AVIF、降尺寸 |
| 字体 | 0KB（用系统字体） | 必须用时 ≤ 100KB 子集 |
| 图标 | 内联 SVG，单个 ≤ 2KB | 用 sprite 或按需导入 |
| 第三方脚本合计 | 50KB | 延后加载、自托管 |

### 指标（p75，移动端 4G）

| 指标 | 预算 |
| --- | --- |
| TTFB | ≤ 800ms |
| FCP | ≤ 1.8s |
| LCP | ≤ 2.5s |
| CLS | ≤ 0.1 |
| INP | ≤ 200ms |
| TBT | ≤ 200ms |
| 首屏请求数 | ≤ 30 |
| 长任务（> 50ms）数量 | ≤ 5 |

**移动端和桌面端要分开定预算**。移动端 p75 通常比桌面端差 40–60%，
用一套预算会导致要么桌面端太松、要么移动端永远不达标。

## 二、RUM 埋点（真实用户监控）

用官方 `web-vitals` 库，它和 Chrome 的指标口径完全一致：

```js
import { onCLS, onFCP, onINP, onLCP, onTTFB } from 'web-vitals'

function report(metric) {
  const body = JSON.stringify({
    name: metric.name,
    value: metric.value,
    rating: metric.rating,        // 'good' | 'needs-improvement' | 'poor'
    delta: metric.delta,
    id: metric.id,
    navigationType: metric.navigationType,
    // 维度：用于分位分析
    path: location.pathname,
    device: /Mobi/i.test(navigator.userAgent) ? 'mobile' : 'desktop',
    conn: navigator.connection?.effectiveType,
  })
  // 用 sendBeacon 避免阻塞卸载
  navigator.sendBeacon('/rum', body)
}

onCLS(report); onFCP(report); onINP(report); onLCP(report); onTTFB(report)
```

要点：
1. **用 `sendBeacon`**，不要用 `fetch`。页面卸载时 `fetch` 会被取消。
2. `onCLS` 和 `onINP` 是**持续累加**的，要在 `visibilitychange` 到 hidden 时上报最终值。
3. 上报维度至少包含：设备类型、网络类型、路由、版本号。
4. **看 p75，不看平均值**。平均值会被公司内网和快用户拉高。

自建监控最小看板：每个指标的 p50 / p75 / p95 + good/ni/poor 占比。

## 三、CI 卡点

```yaml
# .github/workflows/perf.yml（示意）
- name: Lighthouse CI
  run: |
    npm i -g @lhci/cli
    lhci autorun --collect.url=https://staging.example.com \
                 --collect.settings.preset=desktop
  env:
    LHCI_ASSERT: |
      {
        "assertions": {
          "categories:performance": ["error", { "minScore": 0.9 }],
          "largest-contentful-paint": ["error", { "maxNumericValue": 2500 }],
          "cumulative-layout-shift": ["error", { "maxNumericValue": 0.1 }],
          "total-blocking-time": ["error", { "maxNumericValue": 200 }]
        }
      }
```

```bash
# 体积卡点：用 bundlesize 或 size-limit
npx size-limit
```

```json
// package.json 里
"size-limit": [
  { "name": "首屏 JS", "path": "dist/assets/index-*.js", "limit": "170 KB" },
  { "name": "全量 CSS", "path": "dist/assets/*.css", "limit": "80 KB" }
]
```

注意：Lighthouse CI 的分数**波动很大**（同一份代码能差 10 分），
所以卡点应该用**数值阈值**（LCP ≤ 2500）而不是分数（≥ 0.9），
并且只跑一次、失败重跑一次取较好结果，避免 CI 抖动导致误报。

## 四、性能回归的定位顺序

出现指标劣化时，按这个顺序查：

1. **LCP 变差**
   - LCP 元素是什么？（`PerformanceObserver` 的 `element` 属性）
   - 是图片吗？查是否被 lazy、是否缺 `fetchpriority`、是否体积变大。
   - 是文本吗？查字体是否阻塞、是否被 CSS 延迟渲染。
   - TTFB 变了吗？查后端/接口/边缘节点。

2. **CLS 变差**
   - 用 Layout Instability API 找出**哪个元素**在移动（`sources` 属性）。
   - 常见来源：图片无尺寸、广告位无预留、字体替换、动态插入的提示条。
   - 动态提示条（Toast、公告栏）必须用 `position: fixed` 或提前预留高度。

3. **INP 变差**
   - 找长任务：Performance 面板里的红色三角。
   - 常见来源：一次性渲染 500 个 DOM 节点、同步解析大 JSON、
     在输入事件里做全量过滤、第三方脚本的主线程占用。

4. **FCP 变差**
   - 通常是首屏关键 CSS 变大或阻塞渲染的脚本变多。
   - 检查 `<head>` 里是否出现了新的同步 `<script>`。

## 五、埋点代码的性能陷阱

监控代码本身会拖慢页面，注意：

- `web-vitals` 体积约 2KB，可接受。
- **不要**在 `scroll` / `mousemove` 里上报。
- **不要**把 `PerformanceObserver` 的每条记录都上报（`element` 可能很大）。
- 上报队列要限制长度（如 50 条），超了丢最旧的。
- 生产环境关掉 `console.log`，日志本身有成本。

## 六、检查清单

- [ ] 预算表已写进项目 README，团队可见
- [ ] 移动端与桌面端预算分开定义
- [ ] RUM 埋点使用 `web-vitals` + `sendBeacon`
- [ ] 监控看板按 p75 展示，含设备/网络维度
- [ ] CI 用数值阈值卡点，不用分数
- [ ] 体积卡点覆盖首屏 JS 与 CSS
- [ ] CLS 使用 Layout Instability API 定位到具体元素
- [ ] 每季度复核一次预算（业务增长后原预算可能不合理）
