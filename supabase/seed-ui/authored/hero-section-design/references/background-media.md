# 首屏背景媒体：图与视频

背景媒体的唯一职责是**托住文字并传达氛围**。任何干扰文字可读性的背景都是负资产。

## 一、背景图

### 尺寸与格式

| 用途 | 尺寸 | 格式 | 体积上限 |
| --- | --- | --- | --- |
| 桌面横版 | 1920×1080 | AVIF / WebP | 200KB |
| 移动竖版 | 750×1334 | AVIF / WebP | 120KB |
| 平板 | 1536×1024 | AVIF / WebP | 160KB |

用 `<picture>` 分流，避免移动端下载桌面大图：

```html
<picture>
  <source media="(max-width: 640px)" srcset="/hero-mobile.avif" type="image/avif">
  <source media="(max-width: 640px)" srcset="/hero-mobile.webp" type="image/webp">
  <source srcset="/hero-desktop.avif" type="image/avif">
  <img src="/hero-desktop.webp" alt="" fetchpriority="high" width="1920" height="1080">
</picture>
```

`fetchpriority="high"` 是原生属性（Chrome 102+），首屏图值得抢占带宽。
`width` / `height` 必须写，否则会因图片加载造成布局偏移（CLS）。

### 裁切

用 `object-fit: cover` + `object-position` 控制焦点：

```css
.hero__bg img {
  position: absolute; inset: 0;
  width: 100%; height: 100%;
  object-fit: cover;
  object-position: center 35%;   /* 人物/主体通常在偏上位置 */
}
```

**不要**用 CSS `background-image` 铺首屏图：无法用 `object-position` 精确控焦点，
也无法让浏览器预加载，LCP 会明显变差。

### 对比度保证

文字对比度必须实测 ≥ 4.5:1（WCAG 2.2 AA 正文）。做法优先级：

1. 局部渐变遮罩（推荐）：只在文字区域加重
2. 整层半透明黑 `rgba(0,0,0,.45)`
3. 文字加 `text-shadow: 0 1px 8px rgba(0,0,0,.5)` —— 只能补救，不能替代遮罩
4. 换图 —— 如果这张图无论怎么加遮罩都压不住，就换一张明暗分布更均匀的

## 二、背景视频

### 什么时候值得用

用视频的门槛应该是：**视频本身传达了「产品在动」的信息**。
例如编辑器实时协作、渲染过程、地图导航动线。
纯氛围视频（云、海浪、粒子）不值得 3MB 流量和移动端解码开销。

### 标准写法

```html
<video class="hero__video" autoplay muted loop playsinline
       preload="metadata" poster="/hero-poster.jpg"
       width="1920" height="1080">
  <source src="/hero.webm" type="video/webm">
  <source src="/hero.mp4" type="video/mp4">
</video>
```

每个属性的必要性：

| 属性 | 不加会怎样 |
| --- | --- |
| `muted` | 浏览器自动播放策略会直接拒绝播放（除用户静音外无法绕过） |
| `playsinline` | iOS Safari 会强制全屏播放，直接劫持整个页面 |
| `loop` | 播完停在最后一帧，通常是最暗/最乱的一帧 |
| `preload="metadata"` | 默认可能预载整个视频，白烧带宽 |
| `poster` | 视频加载前显示白块或黑块，首屏闪一下 |

### 体积控制

- 时长 **6–12 秒**，循环点要接得上（首尾帧构图接近）
- 分辨率 1920×1080 足够，**不要 4K**：首屏视频永远会被遮罩压暗
- 码率 2–4 Mbps，`webm`（VP9）+ `mp4`（H.264）双格式兜底
- 用 ffmpeg 压：
  ```
  ffmpeg -i in.mp4 -vf "scale=1920:-2,fps=24" -c:v libvpx-vp9 -b:v 2M -an hero.webm
  ffmpeg -i in.mp4 -vf "scale=1920:-2,fps=24" -c:v libx264 -crf 26 -an hero.mp4
  ```
  `-an` 去掉音轨，背景视频不需要声音，能省 10–20% 体积。

### 降级

```css
@media (prefers-reduced-motion: reduce), (max-width: 640px) {
  .hero__video { display: none; }
  .hero__poster-fallback { display: block; }
}
```

`prefers-reduced-motion` 是系统级无障碍设置，前庭功能障碍用户开启后
会因自动播放的动效产生眩晕，必须尊重。

移动端也建议关掉视频：4G 下 3MB 视频会让 LCP 直接爆掉，
而用户在手机上通常只停留 3–5 秒，看不到完整循环。

### 性能检查

- 视频文件放 CDN，支持 Range 请求（否则 iOS 上无法流式播放）
- 视频的 `poster` 图要单独优化到 ≤ 80KB
- 用 Lighthouse 跑一次，确认 LCP < 2.5s；视频场景常见 LCP 在 4s+
- 视频元素加 `aria-hidden="true"`，它是装饰，不需要被读屏读出
