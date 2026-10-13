-- ============================================================================
-- UI 技能包入库 · 落地页（6 个）
-- ----------------------------------------------------------------------------
-- 跑法：Supabase → SQL Editor → 新建查询 → 粘贴本文件 → Run。
--
-- ⚠️ 幂等：末尾是 `on conflict do nothing`，重复跑不会插重复，
--    也不会覆盖已经攒下的下载量 / 安装量 / 评分。
-- ⚠️ 需要先跑过 001-skills.sql（本文件只 insert，不建表）。
-- ============================================================================

insert into public.skills
  (slug, name, description, category, tags, version, license, author,
   readme, files, file_count, total_bytes, hash, bundle_b64, status)
values (
  'landing-page-generator', 'landing-page-generator', '从产品描述生成高转化落地页：Hero / 功能栅格 / 定价表 / FAQ / 证言 / CTA 等区块，套用 PAS / AIDA / BAB 文案框架，输出 Next.js + Tailwind 组件并优化 Core Web Vitals。', 'ui',
  array['落地页', '转化', 'Hero', '定价表', '文案框架', 'Next.js', 'CWV']::text[], '1.0.0', 'MIT', 'Alireza Rezvani',
  $md$---
name: "landing-page-generator"
description: "从产品描述生成高转化落地页：Hero / 功能栅格 / 定价表 / FAQ / 证言 / CTA 等区块，套用 PAS / AIDA / BAB 文案框架，输出 Next.js + Tailwind 组件并优化 Core Web Vitals。"
version: "1.0.0"
license: "MIT"
author: "Alireza Rezvani"
category: ui
tags: ["落地页", "转化", "Hero", "定价表", "文案框架", "Next.js", "CWV"]
---

# Landing Page Generator

Generate high-converting landing pages from a product description. Output complete Next.js/React components with multiple section variants, proven copy frameworks, SEO optimization, and performance-first patterns. Not lorem ipsum — actual copy that converts.

**Target:** LCP < 1s · CLS < 0.1 · FID < 100ms  
**Output:** TSX components + Tailwind styles + SEO meta + copy variants

---

## Core Capabilities

- 5 hero section variants (centered, split, gradient, video-bg, minimal)
- Feature sections (grid, alternating, cards with icons)
- Pricing tables (2–4 tiers with feature lists and toggle)
- FAQ accordion with schema markup
- Testimonials (grid, carousel, single-quote)
- CTA sections (banner, full-page, inline)
- Footer (simple, mega, minimal)
- 4 design styles with Tailwind class sets

---

## Generation Workflow

Follow these steps in order for every landing page request:

1. **Gather inputs** — collect product name, tagline, audience, pain point, key benefit, pricing tiers, design style, and copy framework using the trigger format below. Ask only for missing fields.
2. **Analyze brand voice** (recommended) — if the user has existing brand content (website copy, blog posts, marketing materials), run it through `marketing-skill/skills/content-production/scripts/brand_voice_analyzer.py` to get a voice profile (formality, tone, perspective). Use the profile to inform design style and copy framework selection:
   - formal + professional → **enterprise** style, **AIDA** framework
   - casual + friendly → **bold-startup** style, **BAB** framework
   - professional + authoritative → **dark-saas** style, **PAS** framework
   - casual + conversational → **clean-minimal** style, **BAB** framework
3. **Select design style** — map the user's choice (or infer from brand voice analysis) to one of the four Tailwind class sets in the Design Style Reference.
4. **Apply copy framework** — write all headline and body copy using the chosen framework (PAS / AIDA / BAB) before generating components. Match the voice profile's formality and tone throughout.
5. **Generate sections in order** — Hero → Features → Pricing → FAQ → Testimonials → CTA → Footer. Skip sections not relevant to the product.
6. **Validate against SEO checklist** — run through every item in the SEO Checklist before outputting final code. Fix any gaps inline.
7. **Output final components** — deliver complete, copy-paste-ready TSX files with all Tailwind classes, SEO meta, and structured data included.

---

## Triggering This Skill

```
Product: [name]
Tagline: [one sentence value prop]
Target audience: [who they are]
Key pain point: [what problem you solve]
Key benefit: [primary outcome]
Pricing tiers: [free/pro/enterprise or describe]
Design style: dark-saas | clean-minimal | bold-startup | enterprise
Copy framework: PAS | AIDA | BAB
```

---

## Design Style Reference

| Style | Background | Accent | Cards | CTA Button |
|---|---|---|---|---|
| **Dark SaaS** | `bg-gray-950 text-white` | `violet-500/400` | `bg-gray-900 border border-gray-800` | `bg-violet-600 hover:bg-violet-500` |
| **Clean Minimal** | `bg-white text-gray-900` | `blue-600` | `bg-gray-50 border border-gray-200 rounded-2xl` | `bg-blue-600 hover:bg-blue-700` |
| **Bold Startup** | `bg-white text-gray-900` | `orange-500` | `shadow-xl rounded-3xl` | `bg-orange-500 hover:bg-orange-600 text-white` |
| **Enterprise** | `bg-slate-50 text-slate-900` | `slate-700` | `bg-white border border-slate-200 shadow-sm` | `bg-slate-900 hover:bg-slate-800 text-white` |

> **Bold Startup** headings: add `font-black tracking-tight` to all `<h1>`/`<h2>` elements.

---

## Copy Frameworks

**PAS (Problem → Agitate → Solution)**
- H1: Painful state they're in
- Sub: What happens if they don't fix it
- CTA: What you offer
- *Example — H1:* "Your team wastes 3 hours a day on manual reporting" / *Sub:* "Every hour spent on spreadsheets is an hour not closing deals. Your competitors are already automated." / *CTA:* "Automate your reports in 10 minutes →"

**AIDA (Attention → Interest → Desire → Action)**
- H1: Bold attention-grabbing statement → Sub: Interesting fact or benefit → Features: Desire-building proof points → CTA: Clear action

**BAB (Before → After → Bridge)**
- H1: "[Before state] → [After state]" → Sub: "Here's how [product] bridges the gap" → Features: How it works (the bridge)

---

## Representative Component: Hero (Centered Gradient — Dark SaaS)

Use this as the structural template for all hero variants. Swap layout classes, gradient direction, and image placement for split, video-bg, and minimal variants.

```tsx
export function HeroCentered() {
  return (
    <section className="relative flex min-h-screen flex-col items-center justify-center overflow-hidden bg-gray-950 px-4 text-center">
      <div className="absolute inset-0 bg-gradient-to-b from-violet-900/20 to-transparent" />
      <div className="pointer-events-none absolute -top-40 left-1/2 h-[600px] w-[600px] -translate-x-1/2 rounded-full bg-violet-600/20 blur-3xl" />
      <div className="relative z-10 max-w-4xl">
        <div className="mb-6 inline-flex items-center gap-2 rounded-full border border-violet-500/30 bg-violet-500/10 px-4 py-1.5 text-sm text-violet-300">
          <span className="h-1.5 w-1.5 rounded-full bg-violet-400" />
          Now in public beta
        </div>
        <h1 className="mb-6 text-5xl font-bold tracking-tight text-white md:text-7xl">
          Ship faster.<br />
          <span className="bg-gradient-to-r from-violet-400 to-pink-400 bg-clip-text text-transparent">
            Break less.
          </span>
        </h1>
        <p className="mx-auto mb-10 max-w-2xl text-xl text-gray-400">
          The deployment platform that catches errors before your users do.
          Zero config. Instant rollbacks. Real-time monitoring.
        </p>
        <div className="flex flex-col items-center gap-4 sm:flex-row sm:justify-center">
          <Button size="lg" className="bg-violet-600 text-white hover:bg-violet-500 px-8">
            Start free trial
          </Button>
          <Button size="lg" variant="outline" className="border-gray-700 text-gray-300">
            See how it works →
          </Button>
        </div>
        <p className="mt-4 text-sm text-gray-500">No credit card required · 14-day free trial</p>
      </div>
    </section>
  )
}
```

---

## Other Section Patterns

### Feature Section (Alternating)

Map over a `features` array with `{ title, description, image, badge }`. Toggle layout direction with `i % 2 === 1 ? "lg:flex-row-reverse" : ""`. Use `<Image>` with explicit `width`/`height` and `rounded-2xl shadow-xl`. Wrap in `<section className="py-24">` with `max-w-6xl` container.

### Pricing Table

Map over a `plans` array with `{ name, price, description, features[], cta, highlighted }`. Highlighted plan gets `border-2 border-violet-500 bg-violet-950/50 ring-4 ring-violet-500/20`; others get `border border-gray-800 bg-gray-900`. Render `null` price as "Custom". Use `<Check>` icon per feature row. Layout: `grid gap-8 lg:grid-cols-3`.

### FAQ with Schema Markup

Inject `FAQPage` JSON-LD via `<script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(schema) }} />` inside the section. Map FAQs with `{ q, a }` into shadcn `<Accordion>` with `type="single" collapsible`. Container: `max-w-3xl`.

### Testimonials, CTA, Footer

- **Testimonials:** Grid (`grid-cols-1 md:grid-cols-3`) or single-quote hero block with avatar, name, role, and quote text.
- **CTA Banner:** Full-width section with headline, subhead, and two buttons (primary + ghost). Add trust signals (money-back guarantee, logo strip) immediately below.
- **Footer:** Logo + nav columns + social links + legal. Use `border-t border-gray-800` separator.

---

## SEO Checklist

- [ ] `<title>` tag: primary keyword + brand (50–60 chars)
- [ ] Meta description: benefit + CTA (150–160 chars)
- [ ] OG image: 1200×630px with product name and tagline
- [ ] H1: one per page, includes primary keyword
- [ ] Structured data: FAQPage, Product, or Organization schema
- [ ] Canonical URL set
- [ ] Image alt text on all `<Image>` components
- [ ] robots.txt and sitemap.xml configured
- [ ] Core Web Vitals: LCP < 1s, CLS < 0.1
- [ ] Mobile viewport meta tag present
- [ ] Internal linking to pricing and docs

> **Validation step:** Before outputting final code, verify every checklist item above is satisfied. Fix any gaps inline — do not skip items.

---

## Performance Targets

| Metric | Target | Technique |
|---|---|---|
| LCP | < 1s | Preload hero image, use `priority` on Next/Image |
| CLS | < 0.1 | Set explicit width/height on all images |
| FID/INP | < 100ms | Defer non-critical JS, use `loading="lazy"` |
| TTFB | < 200ms | Use ISR or static generation for landing pages |
| Bundle | < 100KB JS | Audit with `@next/bundle-analyzer` |

---

## Common Pitfalls

- Hero image not preloaded — add `priority` prop to first `<Image>`
- Missing mobile breakpoints — always design mobile-first with `sm:` prefixes
- CTA copy too vague — "Get started" beats "Learn more"; "Start free trial" beats "Sign up"
- Pricing page missing trust signals — add money-back guarantee and testimonials near CTA
- No above-the-fold CTA on mobile — ensure button is visible without scrolling on 375px viewport

---

## Related Skills

- **Brand Voice Analyzer** (`marketing-skill/skills/content-production/scripts/brand_voice_analyzer.py`) — Run before generation to establish voice profile and ensure copy consistency
- **UI Design System** (`product-team/ui-design-system/`) — Generate design tokens from brand color before building the page
- **Competitive Teardown** (`product-team/competitive-teardown/`) — Competitive positioning informs landing page messaging and differentiation
$md$,
  '[{"path":"ATTRIBUTION.md","size":971,"kind":"text"},{"path":"LICENSE","size":1072,"kind":"text"},{"path":"SKILL.md","size":10350,"kind":"text"},{"path":"references/conversion-patterns.md","size":6126,"kind":"text"},{"path":"references/copy-frameworks.md","size":7720,"kind":"text"},{"path":"references/landing-page-patterns.md","size":2759,"kind":"text"},{"path":"references/seo-checklist.md","size":5098,"kind":"text"},{"path":"scripts/landing_page_scaffolder.py","size":24891,"kind":"text"}]'::jsonb, 8, 58987, 'ad05a7d3101af169ea59dd451e9d93882020c998749eea5cdcc763c2d716c786',
  $b64$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$b64$,
  'published'
)
on conflict do nothing;

insert into public.skills
  (slug, name, description, category, tags, version, license, author,
   readme, files, file_count, total_bytes, hash, bundle_b64, status)
values (
  'page-cro', 'page-cro', '页面转化率优化：诊断首页 / 落地页 / 定价页 / 功能页「为什么不转化」，按漏斗逐层给出可执行的改版建议。', 'ui',
  array['CRO', '转化率', '漏斗', '落地页', '定价页', '改版建议', '诊断']::text[], '1.0.0', 'MIT', 'Alireza Rezvani',
  $md$---
name: "page-cro"
description: "页面转化率优化：诊断首页 / 落地页 / 定价页 / 功能页「为什么不转化」，按漏斗逐层给出可执行的改版建议。"
version: "1.0.0"
license: "MIT"
author: "Alireza Rezvani"
category: ui
tags: ["CRO", "转化率", "漏斗", "落地页", "定价页", "改版建议", "诊断"]
---

# Page Conversion Rate Optimization (CRO)

You are a conversion rate optimization expert. Your goal is to analyze marketing pages and provide actionable recommendations to improve conversion rates.

## Initial Assessment

**Check for product marketing context first:**
If `.claude/product-marketing-context.md` exists, read it before asking questions. Use that context and only ask for information not already covered or specific to this task.

Before providing recommendations, identify:

1. **Page Type**: Homepage, landing page, pricing, feature, blog, about, other
2. **Primary Conversion Goal**: Sign up, request demo, purchase, subscribe, download, contact sales
3. **Traffic Context**: Where are visitors coming from? (organic, paid, email, social)

---

## CRO Analysis Framework

Analyze the page across these dimensions, in order of impact:

### 1. Value Proposition Clarity (Highest Impact)

**Check for:**
- Can a visitor understand what this is and why they should care within 5 seconds?
- Is the primary benefit clear, specific, and differentiated?
- Is it written in the customer's language (not company jargon)?

**Common issues:**
- Feature-focused instead of benefit-focused
- Too vague or too clever (sacrificing clarity)
- Trying to say everything instead of the most important thing

### 2. Headline Effectiveness

**Evaluate:**
- Does it communicate the core value proposition?
- Is it specific enough to be meaningful?
- Does it match the traffic source's messaging?

**Strong headline patterns:**
- Outcome-focused: "Get [desired outcome] without [pain point]"
- Specificity: Include numbers, timeframes, or concrete details
- Social proof: "Join 10,000+ teams who..."

### 3. CTA Placement, Copy, and Hierarchy

**Primary CTA assessment:**
- Is there one clear primary action?
- Is it visible without scrolling?
- Does the button copy communicate value, not just action?
  - Weak: "Submit," "Sign Up," "Learn More"
  - Strong: "Start Free Trial," "Get My Report," "See Pricing"

**CTA hierarchy:**
- Is there a logical primary vs. secondary CTA structure?
- Are CTAs repeated at key decision points?

### 4. Visual Hierarchy and Scannability

**Check:**
- Can someone scanning get the main message?
- Are the most important elements visually prominent?
- Is there enough white space?
- Do images support or distract from the message?

### 5. Trust Signals and Social Proof

**Types to look for:**
- Customer logos (especially recognizable ones)
- Testimonials (specific, attributed, with photos)
- Case study snippets with real numbers
- Review scores and counts
- Security badges (where relevant)

**Placement:** Near CTAs and after benefit claims

### 6. Objection Handling

**Common objections to address:**
- Price/value concerns
- "Will this work for my situation?"
- Implementation difficulty
- "What if it doesn't work?"

**Address through:** FAQ sections, guarantees, comparison content, process transparency

### 7. Friction Points

**Look for:**
- Too many form fields
- Unclear next steps
- Confusing navigation
- Required information that shouldn't be required
- Mobile experience issues
- Long load times

---

## Tools

| Tool | Invocation | Output |
|---|---|---|
| Conversion audit | `python3 scripts/conversion_audit.py --file page.html` (or `--url https://...`; `--json` for pipelines) | Mechanical scan for conversion signals: CTA presence/count, form weight, social proof, trust elements — with a score |

Run it before the manual framework pass; its score anchors the audit and its flags seed the Quick Wins list.

---

## Output Format

Open with the `conversion_audit.py` score, then structure recommendations as:

### Quick Wins (Implement Now)
Easy changes with likely immediate impact.

### High-Impact Changes (Prioritize)
Bigger changes that require more effort but will significantly improve conversions.

### Test Ideas
Hypotheses worth A/B testing rather than assuming.

### Copy Alternatives
For key elements (headlines, CTAs), provide 2-3 alternatives with rationale.

---

## Page-Specific Frameworks

### Homepage CRO
- Clear positioning for cold visitors
- Quick path to most common conversion
- Handle both "ready to buy" and "still researching"

### Landing Page CRO
- Message match with traffic source
- Single CTA (remove navigation if possible)
- Complete argument on one page

### Pricing Page CRO
- Clear plan comparison
- Recommended plan indication
- Address "which plan is right for me?" anxiety

### Feature Page CRO
- Connect feature to benefit
- Use cases and examples
- Clear path to try/buy

### Blog Post CRO
- Contextual CTAs matching content topic
- Inline CTAs at natural stopping points

---

## Experiment Ideas

When recommending experiments, consider tests for:
- Hero section (headline, visual, CTA)
- Trust signals and social proof placement
- Pricing presentation
- Form optimization
- Navigation and UX

---

## Task-Specific Questions

1. What's your current conversion rate and goal?
2. Where is traffic coming from?
3. What does your signup/purchase flow look like after this page?
4. Do you have user research, heatmaps, or session recordings?
5. What have you already tried?

---

## Related Skills

- **signup-flow-cro** — WHEN: the page itself converts well but users drop off during the signup or registration process that follows it. WHEN NOT: don't switch to signup-flow-cro if the page itself is the bottleneck; fix the page first.
- **form-cro** — WHEN: the page contains a lead capture or contact form that is a conversion point in its own right (not a signup flow). WHEN NOT: don't use for embedded signup/account-creation forms; those belong in signup-flow-cro.
- **popup-cro** — WHEN: a popup or exit-intent modal is being considered as a conversion layer on top of the page. WHEN NOT: don't reach for popups before fixing core page conversion issues.
- **copywriting** — WHEN: the page requires a full copy overhaul, not just CTA tweaks; the messaging architecture needs rebuilding from the value prop down. WHEN NOT: don't invoke copywriting for minor headline or button copy iterations.
- **ab-test-setup** — WHEN: recommendations are ready and the team needs a structured experiment plan to validate changes without guessing. WHEN NOT: don't use ab-test-setup before having a clear hypothesis from the CRO analysis.
- **onboarding-cro** — WHEN: post-conversion activation is the real problem and the page is already converting adequately. WHEN NOT: don't jump to onboarding-cro before confirming the page conversion rate is acceptable.
- **marketing-context** — WHEN: always read `.claude/product-marketing-context.md` first to understand ICP, messaging, and traffic sources before evaluating the page. WHEN NOT: skip if the user has shared all relevant context directly.

---

## Communication

All page CRO output follows this quality standard:
- Recommendations are always organized as **Quick Wins → High-Impact → Test Ideas** — never a flat list
- Every recommendation includes a brief rationale tied to the CRO analysis framework dimension it addresses
- Copy alternatives are provided in sets of 2-3 with the reasoning for each variant
- Page-specific framework (homepage, landing page, pricing, etc.) is applied explicitly — don't give generic advice
- Never recommend A/B testing as a substitute for obvious fixes; call out what to fix vs. what to test
- Avoid prescribing layout without acknowledging traffic source and audience context

---

## Proactive Triggers

Automatically surface page-cro recommendations when:

1. **"This page isn't converting"** — Any mention of low conversion, poor page performance, or high bounce rate immediately activates the CRO analysis framework.
2. **New landing page being built** — When copywriting or frontend-design skills are active and a marketing page is being created, proactively offer a CRO review before launch.
3. **Paid traffic mentioned** — User describes running ads to a page; immediately flag message-match and single-CTA best practices.
4. **Pricing page discussion** — Any pricing strategy or packaging conversation; proactively recommend pricing page CRO review alongside positioning work.
5. **A/B test results reviewed** — When ab-test-setup skill surfaces test results, offer a page-cro analysis to generate the next round of hypotheses.

---

## Output Artifacts

| Artifact | Format | Description |
|----------|--------|-------------|
| CRO Audit Summary | Markdown sections | Analysis across all 7 framework dimensions with issue severity ratings |
| Quick Wins List | Bullet list | ≤5 changes implementable immediately with expected impact |
| High-Impact Recommendations | Structured list | Each with rationale, effort estimate, and success metric |
| Copy Alternatives | Side-by-side table | 2-3 variants per key element (headline, CTA, subhead) with reasoning |
| A/B Test Hypotheses | Table | Hypothesis × variant description × success metric × priority |
$md$,
  '[{"path":"ATTRIBUTION.md","size":960,"kind":"text"},{"path":"LICENSE","size":1072,"kind":"text"},{"path":"SKILL.md","size":9329,"kind":"text"},{"path":"scripts/conversion_audit.py","size":14810,"kind":"text"}]'::jsonb, 4, 26171, '9b8f11e3265c8bd8398588971ac9acf6ce1d870b27b4e0a40884ebde1c9b682b',
  $b64$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$b64$,
  'published'
)
on conflict do nothing;

insert into public.skills
  (slug, name, description, category, tags, version, license, author,
   readme, files, file_count, total_bytes, hash, bundle_b64, status)
values (
  'landing', 'landing', '生成高级单页落地页：3D CSS 动画、GSAP 滚动效果与鼠标视差景深；先做「产品定位访谈」再写文案与标记，输出自包含的单文件 HTML。', 'ui',
  array['落地页', '单文件', 'GSAP', '3D', '视差', '滚动动画', 'HTML']::text[], '1.0.0', 'MIT', 'Alireza Rezvani',
  $md$---
name: "landing"
description: "生成高级单页落地页：3D CSS 动画、GSAP 滚动效果与鼠标视差景深；先做「产品定位访谈」再写文案与标记，输出自包含的单文件 HTML。"
version: "1.0.0"
license: "MIT"
author: "Alireza Rezvani"
category: ui
tags: ["落地页", "单文件", "GSAP", "3D", "视差", "滚动动画", "HTML"]
---

# Landing — Premium HTML Landing Page Generator

> **Distinct from `product-team/skills/landing-page-generator/`.** That skill outputs Next.js TSX components optimized for conversion / lead-gen. THIS skill outputs a single self-contained `.html` file optimized for premium visual experience with GSAP animations. Pick by use case.

Generate a polished, self-contained `.html` landing page from a text prompt or brief. The output is ONE HTML file: all CSS inline in `<style>`, all JS inline in `<script>`, only external dependencies being Google Fonts + GSAP via CDN. The page is visually distinctive, animated, and production-quality.

## Invocation Triggers

- "create a landing page"
- "build a landing page"
- "make a landing page for X"
- "I need a web page for Y"
- "promotional page"
- "product page"
- "one-pager"
- "web presence"
- "sales page"
- "landing for X"

## Delivery Mode

In **Claude Code CLI**, write the file to disk at the specified path. In **Claude.ai web**, create an HTML artifact with the same content.

## Phase 0: Grill-Me Intake (4 forcing questions, one at a time)

Dependency-ordered. Each question carries explicit "why I'm asking". Stop condition: max 4.

### Q1 (root) — Product / Service

> **What's the product or service? Give me the name + a 1–2 sentence elevator pitch — what does it do, and who's it for?**
>
> *Why I'm asking:* The headline, subtext, and feature copy all derive from this. "App for productivity" produces generic boilerplate; "Async standup tool for remote engineering teams who hate Zoom" produces a landing page that converts.

**Refuse mush.** If user gives just a name with no pitch, push back once: "What does it do? Who's it for?" If still no pitch after push-back, deliver with explicit "generic positioning" caveat.

### Q2 (depends on Q1) — Audience Register

> **Who's the audience? Pick one:**
>
> 1. **Technical buyers** (engineers, ops, security)
> 2. **Business buyers** (PMs, execs, ops leaders)
> 3. **Consumers** (general public, hobbyists)
> 4. **Internal** (employees, partners — not for public sale)
>
> *Why I'm asking:* Audience dictates copy register, jargon level, social-proof choices, and CTA framing. Technical buyers want specifics; consumers want benefits; internal pages can skip persuasion.

Forcing choice.

### Q3 (always) — Brand Overrides

> **Brand colors / fonts to override the default (dark navy + teal + Inter)? Provide as: primary HEX, accent HEX, optional bg HEX. Or say "default" if you want the polished default.**
>
> *Why I'm asking:* The default is intentionally beautiful, but matching your brand makes the page feel native to your existing site. Even just a primary color override goes a long way.

Accept "default" or partial overrides (e.g., just primary). If only primary provided, derive accent algorithmically (lighten / darken).

### Q4 (depends on Q1) — Tone

> **Tone — pick one:**
>
> 1. **Professional** — confident, restrained, B2B-friendly
> 2. **Playful** — warm, light, occasional humor
> 3. **Authoritative** — expert, data-forward, trust-building
> 4. **Minimal** — terse, design-led, low copy density
>
> *Why I'm asking:* Tone affects every sentence — headlines, microcopy, button text, closing copy. Picking upfront prevents tonal whiplash across sections.

Forcing choice. **Recommended default:** professional if Q2 = technical/business; playful if Q2 = consumer; minimal if the product is design-led.

**Stop condition:** After Q4, commit and generate. No follow-up questions during generation.

## Content Extraction (with Fallback Strategy)

From Q1's elevator pitch, derive:
- **Hero headline** — punchy version of "what it does" (8–12 words)
- **Hero subtext** — version of "who it's for + payoff" (1–2 sentences)
- **3–6 feature bullets** — distilled from pitch + audience (Q2) + tone (Q4)
- **CTA text** — action-oriented, matches tone
- **Closing copy** — short, emotive, matches tone

**Fallback when input is sparse:** invent compelling content from product-name semantics + audience register. Flag inferred content with a comment in the HTML source (`<!-- inferred: ... -->`). Don't stall waiting for more input.

## Brand System Specification

### Default Color Palette (Dark Navy + Teal)

```css
:root {
  --navy:       #0A1628;
  --navy-mid:   #0D1F38;
  --teal:       #00D4AA;
  --teal-glow:  rgba(0, 212, 170, 0.12);
  --amber:      #F5A623;
  --off-white:  #F7F7F2;
  --text-muted: rgba(247, 247, 242, 0.68);
  --card-bg:    rgba(0, 212, 170, 0.06);
  --card-border:rgba(0, 212, 170, 0.15);
}
```

### Override Pattern

When Q3 provides custom brand values, the skill substitutes them into the `:root` block:

```
Brand override:
- primary: #FF6B35    →  --navy / hero bg
- accent:  #2EC4B6    →  --teal / CTA / highlights
- bg:      #011627    →  --navy-mid / section bg
- text:    #FDFFFC    →  --off-white
```

If only primary provided, derive accent algorithmically (lighten 15% for accent; darken 8% for navy-mid; convert to rgba at 0.12 alpha for glow). Use `scripts/brand_palette_validator.py` for the deterministic derivation.

See [`references/brand_system_design.md`](references/brand_system_design.md) for color theory + WCAG + algorithmic palette derivation canon.

### Typography

- **Font family:** Inter (via Google Fonts)
- **Weight scale:** 400 (body), 500 (eyebrow), 600 (links), 700 (subtitle), 800 (H1 + H2)
- **Size scale:**
  - Hero H1: 68–82px
  - Section H2: 52–62px
  - Card titles: 22px
  - Body: 17–19px
  - Eyebrow: 13px (uppercase, letter-spaced)
  - CTA button: 18px (500 weight)

### Components (Must Specify CSS)

- `.btn-primary` — CTA button with hover state (lift + brightness)
- `.feature-card` — card with hover lift (translateY(-6px) + border-brighten)
- `.eyebrow` — letter-spaced (0.2em) uppercase category label

## Section 1: Hero

- `min-height: 100vh`, flex-centered content
- Optional eyebrow label above H1
- H1 (68–82px, 800 weight)
- Subtitle (17–19px, 1–2 sentences)
- CTA button (.btn-primary)
- Scroll-down indicator (animated chevron, CSS bounce)
- **Depth layers** (mouse parallax):
  - `.hero-shapes-back` — large blurred circles, absolute-positioned, low opacity
  - `.hero-shapes-mid` — smaller shapes, sharper edges, higher opacity
  - Content layer (H1 + subtitle) — moves subtly in same direction as mouse

## Section 2: Features

- 3 columns default (`repeat(3, 1fr)` grid)
- Responsive:
  - 2 columns at 900px breakpoint
  - 1 column at 580px breakpoint
- Each card:
  - SVG icon (28px, stroke=var(--teal), no fill)
  - Title (22px, 700 weight)
  - Description (15–16px, --text-muted)
- Hover state:
  - `transform: translateY(-6px)`
  - `border-color: var(--teal)` (brighten from --card-border)
  - `transition: 0.3s ease`

## Section 3: Closing CTA

- Full-width, `background: var(--navy-mid)`
- `padding: 120px 24px`, text-align: center
- Large closing headline (52–62px, 800 weight)
- Short subtext (--text-muted, 1–2 sentences)
- CTA button with ambient radial-gradient glow behind it:
  ```css
  background: radial-gradient(circle, var(--teal-glow) 0%, transparent 70%);
  ```

## Animation Patterns

See [`references/gsap_animation_patterns.md`](references/gsap_animation_patterns.md) for the canon. Five patterns required:

### 1. Hero Entrance (GSAP timeline)

```js
// MUST use gsap.set() FIRST to prevent FOUC
gsap.set([".eyebrow", ".hero h1", ".hero .subtitle", ".btn-primary", ".scroll-down"], {
  opacity: 0,
  y: 30
});

const tl = gsap.timeline({ defaults: { ease: "power3.out" } });
tl.to(".eyebrow", { opacity: 1, y: 0, duration: 0.6 })
  .to(".hero h1", { opacity: 1, y: 0, duration: 0.8 }, "-=0.3")
  .to(".hero .subtitle", { opacity: 1, y: 0, duration: 0.6 }, "-=0.5")
  .to(".btn-primary", { opacity: 1, y: 0, duration: 0.5 }, "-=0.3")
  .to(".scroll-down", { opacity: 1, y: 0, duration: 0.4 }, "-=0.2");
```

### 2. Mouse Parallax

```js
const hero = document.querySelector(".hero");
hero.addEventListener("mousemove", (e) => {
  const x = (e.clientX / window.innerWidth - 0.5) * 2;
  const y = (e.clientY / window.innerHeight - 0.5) * 2;
  gsap.to(".hero-shapes-back", { x: x * 45, y: y * 22, duration: 0.8 });
  gsap.to(".hero-shapes-mid",  { x: x * 22, y: y * 11, duration: 0.8 });
  gsap.to(".hero .container",  { x: x * 8,  y: y * 5,  duration: 0.8 });
});
```

### 3. Scroll-Triggered Feature Cards

```js
gsap.set(".feature-card", { opacity: 0, y: 55, rotateX: 18 });

ScrollTrigger.batch(".feature-card", {
  start: "top 80%",
  onEnter: batch => gsap.to(batch, {
    opacity: 1, y: 0, rotateX: 0,
    duration: 0.8,
    stagger: 0.11,
    ease: "power2.out"
  })
});
```

### 4. Floating Decorative Shapes (CSS keyframes — NOT GSAP)

CSS handles ambient continuous motion (smoother, cheaper than GSAP for indefinite animations):

```css
@keyframes floatA {
  0%, 100% { transform: translate(0, 0) rotate(0deg); }
  50%      { transform: translate(20px, -30px) rotate(8deg); }
}
@keyframes floatB { /* different duration + rotation */ }
@keyframes floatC { /* different duration + rotation */ }

.hero-shapes-back .shape-a { animation: floatA 12s ease-in-out infinite; }
```

### 5. Scroll Indicator (CSS bounce)

```css
@keyframes bounce {
  0%, 100% { transform: translateY(0); }
  50%      { transform: translateY(8px); }
}
.scroll-down { animation: bounce 2s ease-in-out infinite; }
```

## Required CDN Dependencies

```html
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
<script src="https://cdnjs.cloudflare.com/ajax/libs/gsap/3.12.2/gsap.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/gsap/3.12.2/ScrollTrigger.min.js"></script>
```

NO other external CSS or JS files. All custom CSS in `<style>`, all custom JS in `<script>` blocks within the same HTML file.

See [`references/single_file_html_discipline.md`](references/single_file_html_discipline.md) for the inline-only rationale.

## Layout Rules

- **Container max-width:** 1200px, centered
- **Section padding:** `120px 24px` (vertical 120, horizontal 24, scales down on mobile)
- **Responsive breakpoints:**
  - 900px → features grid 3-col → 2-col
  - 580px → all grids → 1-col; H1 scales down to ~52px
- **Viewport meta:** `<meta name="viewport" content="width=device-width, initial-scale=1">`

## Output Spec

- **Path:** `${OUTPUT_DIR}/<product-name-kebab>.html`
- **Default `${OUTPUT_DIR}`:** `./landing-pages/`
- **Filename:** lowercase kebab-case from product name ("Quill AI" → `quill-ai.html`). Use `scripts/kebab_slug_generator.py` for deterministic slug generation + duplicate detection.
- **Self-contained:** all CSS in `<style>`, all JS in `<script>`, only Google Fonts + GSAP CDN external.

## Validation (Post-Generation)

Run `scripts/html_validator.py --file ${OUTPUT_DIR}/<slug>.html` after generation. Checks:

- All 3 required sections present (`.hero`, `.features`, `.closing-cta`)
- CDN deps present (Inter + GSAP + ScrollTrigger)
- `gsap.set()` initial states precede any `gsap.timeline` or `gsap.to` (FOUC prevention)
- Responsive breakpoints at 900px + 580px
- No external `<link rel="stylesheet">` other than Google Fonts
- No external `<script src=>` other than GSAP CDN
- `<meta name="viewport">` present
- All animated elements have initial-state declarations

## Error Handling

| Situation | Behavior |
|---|---|
| Input is just a name with no context | Invent compelling content from name semantics + audience register; flag as `<!-- inferred -->` in HTML source |
| Input file is large or PDF | Read fully before generating; don't truncate |
| Brand colors insufficient (only 1 HEX provided) | Use as primary; derive secondary/accent algorithmically (lighten/darken via brand_palette_validator.py) |
| Features count not specified | Default to 4 |
| Output dir doesn't exist | Create it |
| Existing file at output path | Append timestamp suffix or ask user (kebab_slug_generator.py flags duplicates) |
| html_validator returns FAIL | Regenerate ONLY the failing sections in one targeted pass; do NOT abandon the file |

## Portability

- **Claude Code CLI:** Native — writes HTML file directly to filesystem.
- **Claude.ai web:** Native — produces HTML as an artifact instead of file.

## Tooling

| Script | Role |
|---|---|
| `scripts/brand_palette_validator.py` | Validates HEX format, checks WCAG AA contrast, generates derived palette from primary (algorithmic lighten/darken). |
| `scripts/kebab_slug_generator.py` | Product name → kebab-case filename + duplicate detection in output dir. |
| `scripts/html_validator.py` | Post-generation structural check: 3 sections, CDN deps, gsap.set() initial states, responsive breakpoints, no external files. |

## References

- [`references/brand_system_design.md`](references/brand_system_design.md) — color theory + WCAG + algorithmic palette derivation (7+ sources)
- [`references/gsap_animation_patterns.md`](references/gsap_animation_patterns.md) — entrance timeline + ScrollTrigger reveals + mouse parallax + CSS floats + scroll indicator (7+ sources)
- [`references/single_file_html_discipline.md`](references/single_file_html_discipline.md) — why inline + CDN-only externals + accessibility minimums + no-build rationale (7+ sources)

## Anti-Patterns To Reject

- Hardcoded absolute paths in output directory
- Single brand palette without override documentation
- Outlining before writing — write in one pass
- External CSS or JS files (must be inline; only Google Fonts + GSAP CDN allowed)
- Skipping `gsap.set()` initial states (causes FOUC)
- More than 6 features in default grid (becomes unscannable)
- Brand-specific content references in the skill itself

---

**Version:** 1.0.0
**Source spec:** `megaprompts/04-landing-megaprompt.md` (maintainer-local draft spec — gitignored, not present in the public repository)
**Build pattern:** Path B (direct conversion). Distinct from `product-team/skills/landing-page-generator/`.
$md$,
  '[{"path":"ATTRIBUTION.md","size":961,"kind":"text"},{"path":"LICENSE","size":1072,"kind":"text"},{"path":"SKILL.md","size":14395,"kind":"text"},{"path":"references/brand_system_design.md","size":8401,"kind":"text"},{"path":"references/gsap_animation_patterns.md","size":9654,"kind":"text"},{"path":"references/single_file_html_discipline.md","size":8528,"kind":"text"},{"path":"scripts/brand_palette_validator.py","size":9269,"kind":"text"},{"path":"scripts/html_validator.py","size":12458,"kind":"text"},{"path":"scripts/kebab_slug_generator.py","size":3912,"kind":"text"}]'::jsonb, 9, 68650, '296c38fce3bfe9af6fc837758869bf98fc494eb673cd308eee0ea05cfd36d859',
  $b64$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$b64$,
  'published'
)
on conflict do nothing;

insert into public.skills
  (slug, name, description, category, tags, version, license, author,
   readme, files, file_count, total_bytes, hash, bundle_b64, status)
values (
  'hero-section-design', 'hero-section-design', '设计或重写落地页首屏时使用：首屏放哪些元素、标题字数与字号、CTA 主次、首屏高度取值，以及移动端首屏该怎么重新排版。', 'ui',
  array['落地页', '首屏', 'CTA 主次', '视口高度', '背景视频', '移动端重排']::text[], '1.0.0', 'MIT', 'Skill Hub',
  $md$---
name: "hero-section-design"
description: "设计或重写落地页首屏时使用：首屏放哪些元素、标题字数与字号、CTA 主次、首屏高度取值，以及移动端首屏该怎么重新排版。"
version: "1.0.0"
license: "MIT"
author: "Skill Hub"
category: ui
tags: ["落地页", "首屏", "CTA 主次", "视口高度", "背景视频", "移动端重排"]
---

# 首屏 Hero 设计

首屏不是「页面的头图」，它是**唯一一次不滚动就能说服用户的机会**。
用户打开页面后 3 秒内要么继续往下滚，要么关掉。首屏的任务只有一个：
让用户看懂「这是什么、对我有什么用、下一步点哪里」。

## 何时使用

- 从零设计落地页、产品官网、活动页的首屏
- 首屏「很好看但转化低」，跳出率 > 70%
- 首屏塞了导航、Banner、搜索、多个按钮，用户不知道该点哪个
- 移动端首屏在 iPhone SE 上只能看到半张背景图，标题和按钮都被挤到折叠线以下
- 纠结首屏用 `100vh`、`100dvh` 还是固定高度

## 核心规则

1. **首屏只放 5 类元素，多一类就要论证**：
   主标题、副标题、主 CTA（+可选次 CTA）、1 条信任证明（Logo 条 / 数据 / 评分）、
   背景（纯色 / 图 / 视频 / 渐变）。
   导航栏算「页面的」不算首屏的，但要计入首屏高度预算。

2. **主标题字数上限：中文 12–18 字，英文 6–10 个词**。
   超过 18 字在桌面端会折成 3 行，首屏的纵向预算立刻崩掉。
   标题字号区间：桌面 `clamp(32px, 4vw, 56px)`，移动 `clamp(28px, 7vw, 36px)`。
   **行数最多 2 行**，第 2 行不超过第 1 行宽度的 70%。

3. **副标题 20–40 字，字号 = 主标题的 0.4–0.5 倍**（主标题 48px → 副标题 20–24px）。
   副标题回答「具体怎么做到」，不重复标题。
   如果副标题和标题说的是同一件事，删掉副标题。

4. **CTA 最多 2 个，且必须有明确主次**：
   - 主 CTA 用实心高对比按钮，高度 48–56px，左右 padding ≥ 32px，字号 16–18px
   - 次 CTA 用描边或纯文字，视觉重量不超过主 CTA 的 60%
   - 两个 CTA 之间间距 ≥ 16px；同色同尺寸的「注册」「了解详情」并列是最典型的错误
   - 主 CTA 上方或下方 8–16px 内必须有「零风险」微文案（如「无需信用卡」）

5. **首屏高度不要写 `100vh`**。理由：移动端浏览器地址栏会吃掉 60–120px，
   `100vh` 会导致 CTA 被推出视口（这是最常见的「按钮点不到」投诉来源）。
   正确做法：
   - 首选 `min-height: 100dvh`（`dvh` 动态视口单位，Safari 15.4+ / Chrome 108+ 支持）
   - 兼容写法：`min-height: 100vh; min-height: 100dvh;`
   - 或者干脆**放弃满屏**，用「内容高度 + 上下 padding 各 64–96px」，
     首屏内容自然落位，第 2 屏内容露出 10–15% 作为「还有内容」的暗示

6. **背景图与视频的取舍**：
   - 背景图：体积 ≤ 200KB（WebP/AVIF），桌面 `1920×1080`，移动单独出 `750×1334` 竖版
   - 背景视频：`<video autoplay muted loop playsinline preload="metadata">`，
     体积 ≤ 3MB，时长 6–12 秒，**必须提供 `poster` 首帧图**，
     并在 `prefers-reduced-motion: reduce` 下换成静态图
   - 无论哪种，背景上必须叠一层 `rgba(0,0,0,.35~.55)` 或双向渐变遮罩，
     保证文字对比度 ≥ 4.5:1（WCAG 2.2 AA 正文标准）
   - **判据**：如果视频没有传达「产品在动」的信息，就用图。纯氛围视频不值得那 3MB。

7. **首屏文字最大宽度 640–720px**。超过 720px 后，眼睛从行首扫到行尾会丢行。
   居中布局用 `max-width: 680px; margin-inline: auto;`，
   左文右图布局则文字列占 45–50%，图片列占 50–55%。

## 怎么做

### 第 1 步：算「首屏纵向预算」

在写代码前先把垂直空间列清楚，超出就砍元素，不要靠缩字号硬塞。

以 1080p 桌面（视口高度约 950px）为例：

| 区块 | 高度预算 |
| --- | --- |
| 顶部导航（吸顶） | 64–72px |
| 首屏上留白 | 64–96px |
| 主标题（2 行 × 1.2 行高） | 100–140px |
| 副标题（2 行） | 60–70px |
| CTA 区（含微文案） | 48 + 12 + 20 = 80px |
| 信任证明条 | 40–56px |
| 下留白 | 64–96px |
| **合计** | **约 480–610px** |

算出来明显小于视口高度时，说明首屏不该做满屏 —— 留白堆到 300px 只会显得空。
这时把「信任证明」下移到第二屏开头，或加一张产品截图。

### 第 2 步：写结构骨架

```html
<section class="hero">
  <div class="hero__inner">
    <p class="hero__eyebrow">新版本 2.0 已上线</p>
    <h1 class="hero__title">让团队的三方协作不再靠截图</h1>
    <p class="hero__subtitle">
      把需求、设计稿和验收标准放在同一条时间线上，改动自动同步给所有人。
    </p>
    <div class="hero__actions">
      <a class="btn btn--primary" href="/signup">免费开始使用</a>
      <a class="btn btn--ghost" href="/demo">看 2 分钟演示</a>
    </div>
    <p class="hero__microcopy">无需信用卡 · 5 分钟完成接入</p>
    <div class="hero__proof"><!-- Logo 条 / 评分 / 数据 --></div>
  </div>
</section>
```

```css
.hero {
  position: relative;
  display: grid;
  place-items: center;
  min-height: 100vh;
  min-height: 100dvh;
  padding: 96px 24px 72px;   /* 上留白 ≥ 导航高度，避免吸顶导航压标题 */
  overflow: hidden;
}
.hero__inner { max-width: 680px; text-align: center; }
.hero__title {
  font-size: clamp(32px, 4vw, 56px);
  line-height: 1.15;
  letter-spacing: -0.01em;   /* 大字号需要轻微收紧，否则显得松散 */
  margin: 12px 0 20px;
  text-wrap: balance;        /* 让 2 行标题长度均衡，避免「尾行孤字」 */
}
.hero__subtitle {
  font-size: clamp(16px, 1.4vw, 22px);
  line-height: 1.6;
  color: var(--text-secondary);
  max-width: 560px;
  margin-inline: auto;
}
```

`text-wrap: balance` 是原生 CSS 属性（Chrome 114+ / Safari 17.5+），
不支持时降级为普通换行，不会破坏布局，可以放心用。

### 第 3 步：移动端重排（不是压缩）

移动端首屏**不是把桌面端缩小**，而是换一套信息顺序。区别在于：

| 维度 | 桌面端 | 移动端 |
| --- | --- | --- |
| 布局 | 左文右图 / 居中 | 单列，图在文下或文上 |
| 主标题 | 32–56px，≤ 2 行 | 28–36px，≤ 3 行 |
| 副标题 | 保留 | 可缩短到 15–25 字 |
| 背景视频 | 可用 | **换静态图**，移动流量与解码成本不划算 |
| CTA | 并排 2 个 | 上下堆叠，主 CTA 全宽，次 CTA 在下方 |
| 信任证明 | Logo 条 5–6 个 | 只留 3 个，或换成一句数据 |
| 上留白 | 96px | 48–64px |

```css
@media (max-width: 640px) {
  .hero { min-height: auto; padding: 72px 20px 48px; }
  .hero__title { font-size: clamp(28px, 7vw, 36px); }
  .hero__actions { display: grid; gap: 12px; }   /* 堆叠 */
  .hero__actions .btn { width: 100%; height: 52px; }  /* 全宽，热区够大 */
  .hero__bg-video { display: none; }             /* 视频换静态图 */
  .hero__proof { display: none; }                /* 或替换为一行文字 */
}
```

**移动端 CTA 必须整宽且高度 ≥ 48px**，这是 Apple HIG 的最小触控目标。
拇指自然覆盖区在屏幕下方 1/3，所以主 CTA 要尽量靠近首屏底部。

### 第 4 步：验证

1. 在 375×667（iPhone SE，最小主流视口）下打开，**不滚动**截图：
   标题、副标题、主 CTA 是否都完整可见？看不到就是不合格。
2. 用浏览器 DevTools 模拟 `prefers-reduced-motion: reduce`，确认视频已停。
3. 把背景图换成纯黑，检查文字对比度是否仍 ≥ 4.5:1（用对比度工具算，不要凭肉眼）。
4. 断网加载一次，确认 `poster` 图正常显示，不会出现黑块或白块。

## 检查清单

- [ ] 首屏不滚动即可看到：主标题、副标题、主 CTA
- [ ] 主标题 ≤ 2 行（桌面）/ ≤ 3 行（移动），且没有孤字尾行
- [ ] CTA 有且只有一个视觉上的「主」，次 CTA 明显更弱
- [ ] 主 CTA 高度 ≥ 48px，移动端整宽
- [ ] 主 CTA 附近有「无需信用卡 / 免费试用」类零风险微文案
- [ ] 高度用 `min-height: 100dvh` 而非 `100vh`
- [ ] 背景视频有 `poster`，且 `reduced-motion` 下自动降级为图
- [ ] 背景图上叠了遮罩，文字对比度实测 ≥ 4.5:1
- [ ] 移动端背景图是单独裁的竖版，不是桌面横图 `object-fit: cover` 裁出来的
- [ ] 375×667 下首屏 CTA 完整可见，未被浏览器工具栏遮挡
- [ ] 首屏文字块宽度 ≤ 720px

## 常见错误

| 错误做法 | 为什么错 | 正确做法 |
| --- | --- | --- |
| `height: 100vh` | 移动端地址栏占 60–120px，CTA 被推出视口，用户以为页面只有一张图 | `min-height: 100dvh`，或干脆不做满屏 |
| 主标题写 30 个字 | 折成 4 行，把 CTA 挤到折叠线以下，首屏失去作用 | 砍到 12–18 字，把细节留给副标题 |
| 「立即注册」和「了解更多」两个同色实心按钮 | 没有视觉主次，用户决策成本上升，点击被分散 | 主 CTA 实心、次 CTA 描边或纯文字 |
| 背景图直接铺图不叠遮罩 | 图上文字对比度可能只有 2:1，在亮部完全看不清 | 叠 `rgba(0,0,0,.4)` 遮罩，实测对比度 ≥ 4.5:1 |
| 桌面背景视频直接 `object-fit: cover` 用到移动 | 竖屏下裁掉 70% 画面，主体没了，还白烧 3MB 流量 | 移动端换静态竖版图，或单独出竖版视频 |
| 首屏放轮播 Banner | 用户只会看到第 1 张，第 2、3 张曝光率通常 < 10%，纯浪费 | 首屏不做轮播，要展示多个卖点就往下做独立区块 |
| 首屏同时放「登录」和「注册」两个入口按钮 | 对未登录用户而言，「登录」是噪音，会分流注册转化 | 首屏只留「注册/试用」，登录放到导航右上角文字链 |
| 用 `rem` 定义首屏字号 | 用户改浏览器默认字号后，首屏标题膨胀导致 CTA 掉出视口 | 首屏标题用 `clamp()` + `vw`，与视口联动 |

## 参考

- 需要为具体行业挑首屏文案与配图策略时，读 `references/hero-patterns.md`
- 需要处理背景视频的性能与降级细节时，读 `references/background-media.md`
$md$,
  '[{"path":"ATTRIBUTION.md","size":484,"kind":"text"},{"path":"LICENSE","size":1074,"kind":"text"},{"path":"SKILL.md","size":10439,"kind":"text"},{"path":"references/background-media.md","size":4165,"kind":"text"},{"path":"references/hero-patterns.md","size":4577,"kind":"text"}]'::jsonb, 5, 20739, '41e4f89147a7e9f30276afb97c22bc2a210428396446a391e9a01394659917ad',
  $b64$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$b64$,
  'published'
)
on conflict do nothing;

insert into public.skills
  (slug, name, description, category, tags, version, license, author,
   readme, files, file_count, total_bytes, hash, bundle_b64, status)
values (
  'pricing-page-design', 'pricing-page-design', '设计定价页或改版套餐表时使用：档位数量、推荐档的视觉处理、功能对比表组织、月付年付切换、价格文案写法与常见异议的放置位置。', 'ui',
  array['落地页', '定价表', '功能对比', '锚定效应', '月付年付', '异议处理']::text[], '1.0.0', 'MIT', 'Skill Hub',
  $md$---
name: "pricing-page-design"
description: "设计定价页或改版套餐表时使用：档位数量、推荐档的视觉处理、功能对比表组织、月付年付切换、价格文案写法与常见异议的放置位置。"
version: "1.0.0"
license: "MIT"
author: "Skill Hub"
category: ui
tags: ["落地页", "定价表", "功能对比", "锚定效应", "月付年付", "异议处理"]
---

# 定价页设计

定价页是整个网站**信息密度最高、决策成本最大**的一页。
它的目标不是把价格列清楚，而是**把用户推向一个确定的档位**并消除犹豫。
所有设计决策都要服务于「降低决策成本」这一件事。

## 何时使用

- 从零设计 SaaS / 会员 / 服务的定价页
- 定价页转化低、用户停留在对比表上很久却不下单
- 档位数量拿不准（2 档、3 档还是 4 档）
- 需要加月付/年付切换，但不确定默认选哪个、怎么显示折扣
- 用户反复问「这个包含 XX 吗」，说明对比表没组织好

## 核心规则

1. **档位数量 2–4 档，主推 3 档**。
   理由：
   - 1 档 = 没有对比，用户只能判断「贵不贵」，无法判断「值不值」
   - 2 档 = 只能形成「便宜的够用吗」的二选一，缺少诱饵
   - 3 档 = 经典的三方对比：低价档做**锚**（让中间档显得合理）、
     高价档做**天花板**（让中间档显得克制）
   - 5 档以上 = 选择过载，用户会推迟决策或直接走人
   超过 4 档时，把最高档改成「企业定制 / 联系我们」入口，不参与价格对比。

2. **推荐档必须有且只有一个，且视觉权重明显更高**：
   - 卡片加 1–2px 品牌色边框 + 轻微上浮（`translateY(-8px)`）
   - 顶部挂一个标签（「最受欢迎」/「推荐」），字号 12–13px
   - 高度比其余卡片高 16–24px（用 padding 撑，不要用 transform 造成错位）
   - 按钮用实心，其余档用描边
   - **不要**让推荐档同时是「最贵」或「最便宜」—— 推荐档应是中间档

3. **锚定档（最贵档）的作用是「让推荐档显得便宜」**，
   所以它的价格要**完整展示**，不要藏起来。锚定档与推荐档的价格差建议 ≥ 2 倍。
   如果最贵档和推荐档只差 20%，锚定就失效了。

4. **月付/年付切换默认选中「年付」**，但必须让用户看清折算价：
   - 展示年付时，价格区要同时出现「原价划线」和「折算到每月的价格」
   - 例：`¥1188/年`（划线 `¥1428`）`≈ ¥99/月`，旁边标 `省 17%`
   - 折扣力度 < 10% 时不要强调「省」，用户会觉得被耍
   - 切换开关必须是**双态可见的 segment control**，
     不要用只有一个 checkbox 的「年付（省 20%）」，用户会不知道当前是什么状态

5. **价格文案格式统一**：
   - 货币符号紧贴数字：`¥99`，不写 `¥ 99`
   - 单位用斜杠：`¥99/月`、`¥1188/年`；不要写「每月 99 元」
   - 数字字号是单位字号的 2.5–3 倍（价格 48px → 单位 16–18px）
   - **大额价格用千分位**：`¥1,188`、`¥12,000`；4 位数以下可省略（`¥999` 不写 `¥999`）
   - 年付一定要给「折算到月」的数字，用户无法心算 1188 ÷ 12

6. **功能对比表用「分组 + 逐行勾选」，不要平铺 40 行**：
   - 按功能域分组（如「协作」「安全」「集成」「支持」），每组 3–6 行
   - 组内每行对应各档的取值：`✓` / `—` / 具体数值（`10 GB`、`5 个成员`）
   - 前 5 行放**最能区分的差异项**，把「所有档都有」的功能沉到最下方
   - 移动端不要做横向滚动的表格，改成**每档一张可折叠的列表**

7. **常见异议必须出现在定价页内，不要只放在 FAQ**。
   高频异议与放置位置：

   | 异议 | 处理位置 |
   | --- | --- |
   | 「会不会被自动续费坑」 | 价格区下方 8–12px 的微文案 |
   | 「能随时退吗」 | 每个档位卡片按钮下方 |
   | 「我的数据安全吗」 | 定价表下方的安全信任条 |
   | 「换了档位怎么办」 | 对比表底部一行说明 |
   | 「超出用量怎么算」 | 对应功能行的 tooltip |

## 怎么做

### 第 1 步：确定档位与差异

先把「按什么分档」定下来，三种常见分法：

| 分档依据 | 适用 | 例子 |
| --- | --- | --- |
| 按用量 | 资源型产品 | 存储 10GB / 100GB / 1TB |
| 按人数 | 协作型产品 | 单人 / 5 人 / 不限 |
| 按功能 | 工具型产品 | 基础 / 专业 / 企业 |

**只用一个维度分档**。同时按人数和用量分档，用户没法在脑子里建模。

### 第 2 步：写卡片结构

```html
<div class="plans">
  <article class="plan">
    <h3 class="plan__name">基础版</h3>
    <p class="plan__desc">适合个人试用</p>
    <div class="plan__price">
      <span class="plan__currency">¥</span>
      <span class="plan__amount">99</span>
      <span class="plan__period">/月</span>
    </div>
    <p class="plan__note">按年付费，随时可取消</p>
    <a class="btn btn--ghost" href="/signup?plan=basic">开始使用</a>
    <ul class="plan__features">
      <li><svg aria-hidden="true"/><span>3 个项目</span></li>
      <li><svg aria-hidden="true"/><span>1 GB 存储</span></li>
    </ul>
  </article>

  <article class="plan plan--featured">
    <span class="plan__badge">最受欢迎</span>
    <!-- 同上结构 -->
  </article>
</div>
```

```css
.plans {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 24px;
  align-items: start;          /* 让 featured 的上浮不被拉伸抵消 */
}
.plan { padding: 32px 28px; border: 1px solid var(--border); border-radius: 12px; }
.plan--featured {
  border: 2px solid var(--brand);
  box-shadow: 0 12px 32px rgba(0,0,0,.10);
  padding-top: 48px;           /* 为 badge 留位，而不是用 transform 顶出去 */
}
.plan__amount {
  font-size: 48px;
  font-variant-numeric: tabular-nums;  /* 三档数字宽度一致，价格才对齐 */
  letter-spacing: -0.02em;
  line-height: 1;
}
```

`font-variant-numeric: tabular-nums` 让数字等宽。
不加的话，`¥99` 和 `¥199` 的宽度不同，三张卡片的价格会看起来没对齐。

### 第 3 步：月付/年付切换

```html
<div class="billing-toggle" role="radiogroup" aria-label="计费周期">
  <button role="radio" aria-checked="false" data-cycle="monthly">按月</button>
  <button role="radio" aria-checked="true"  data-cycle="yearly">按年 <span>省 17%</span></button>
</div>
```

- 用 `role="radiogroup"` + `role="radio"`，让读屏用户知道这是一组互斥选项
- 切换后价格**不要做整块淡入淡出**，用数字滚动或直接替换，
  动画时长 ≤ 200ms，避免用户在动画中误读价格
- 切换状态必须写进 URL query（`?cycle=yearly`），方便分享和埋点
- 默认选中按年，但**首次访问时不要弹窗推销年付**

### 第 4 步：功能对比表

```html
<table class="compare">
  <thead>
    <tr><th scope="col">功能</th><th scope="col">基础</th>
        <th scope="col">专业</th><th scope="col">企业</th></tr>
  </thead>
  <tbody>
    <tr class="compare__group"><th colspan="4">协作</th></tr>
    <tr>
      <th scope="row">成员上限</th>
      <td>3</td><td>20</td><td>不限</td>
    </tr>
  </tbody>
</table>
```

要点：

- **每档列的顶部要重复价格和按钮**（用户滚到表格底部时已经忘了上面写了什么）
- 「不限」比 `∞` 好，`∞` 有用户会理解成「没有这个功能」
- 缺失功能用灰色 `—` 而非空格，空格会让人以为漏渲染
- 表格 `position: sticky` 的表头在长表格里必加，`top` 值 = 导航高度

### 第 5 步：移动端

三档在 375px 宽度下**不可能并排**，两种处理：

1. **横向滚动卡片**（推荐）：每张卡 `width: 78vw`，`scroll-snap-type: x mandatory`，
   卡片 `scroll-snap-align: center`，首屏默认露出下一张的边缘 15% 提示可滑
2. **纵向堆叠**：推荐档放最上面（不要放中间），因为移动端用户只滑 1–2 屏

对比表在移动端**改成每档一个可折叠区块**，不要做横向滚动表格：
横向滚动的表格在移动端有 60% 以上的用户不会去滑。

## 检查清单

- [ ] 档位数量 2–4 个，推荐档是中间档且视觉明显更重
- [ ] 推荐档只有一个，其余档没有「推荐」「热门」标签
- [ ] 最贵档价格完整展示，与推荐档差距 ≥ 2 倍
- [ ] 年付默认选中，且展示了折算月价与原价划线
- [ ] 价格数字用 `tabular-nums`，三档价格在垂直方向对齐
- [ ] 大额价格有千分位，单位用 `/月` 而非「每月」
- [ ] 每个 CTA 按钮下方有零风险微文案（可随时取消 / 无需信用卡）
- [ ] 功能对比表按功能域分组，且每列顶部重复了价格与按钮
- [ ] 移动端定价卡改为横向 snap 滚动或纵向堆叠，未做三列并排
- [ ] 移动端对比表是可折叠列表，不是横向滚动表格
- [ ] 切换月/年付后 URL 同步，且价格变化有 ≤ 200ms 的过渡
- [ ] 定价页内直接回答了「能否退款」「超出用量怎么办」两个最高频异议

## 常见错误

| 错误做法 | 为什么错 | 正确做法 |
| --- | --- | --- |
| 5 个以上档位并排 | 用户陷入逐项对比，决策时间翻倍，最终放弃 | 砍到 3 档，其余并入「联系我们」 |
| 每档都挂「推荐」标签 | 没有推荐，等于没有引导 | 只留一个推荐档 |
| 把最贵档价格藏成「联系销售」 | 失去锚点，推荐档失去参照物，显得贵 | 最贵档明码标价，只把「超大规模」部分设为联系 |
| 年付开关只有一个 checkbox | 用户不知道当前是月付还是年付 | 用双态 segment control，两个选项都可见 |
| 只显示 `¥1188/年` 不给月均 | 用户无法心算，会本能地觉得「贵」 | 同时显示 `≈ ¥99/月` 与划线原价 |
| 三档价格字号不同 | 视觉上无法横向比较，对比失效 | 三档价格字号、字重、位置完全一致 |
| 功能对比表平铺 40 行无分组 | 用户滚到底部已经忘了档位差异 | 按域分组，每组 3–6 行，差异项前置 |
| 对比表里「不限」写成 `∞` | 部分用户会理解成「无此功能」 | 写「不限」或「无上限」 |
| 移动端三档并排压缩 | 每张卡只剩 110px 宽，文字折成 4 行，价格被截断 | 横向 snap 滚动，或纵向堆叠 |
| 「最受欢迎」标签用 `transform: translateY(-100%)` 顶出卡片 | 会和上方元素重叠，或在小屏被裁掉 | 用卡片内 `padding-top` 预留位置 |

## 参考

- 需要写具体档位的功能差异与「按什么分档」时，读 `references/tier-strategy.md`
- 需要为长功能对比表做移动端折叠与分组细节时，读 `references/comparison-table.md`
$md$,
  '[{"path":"ATTRIBUTION.md","size":484,"kind":"text"},{"path":"LICENSE","size":1074,"kind":"text"},{"path":"SKILL.md","size":10961,"kind":"text"},{"path":"references/comparison-table.md","size":3900,"kind":"text"},{"path":"references/tier-strategy.md","size":4148,"kind":"text"}]'::jsonb, 5, 20567, '0944d35d4ddb156588ee1ecfafcc2fd25ebfaae55edc078fe97285b7eca4a0dd',
  $b64$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$b64$,
  'published'
)
on conflict do nothing;

insert into public.skills
  (slug, name, description, category, tags, version, license, author,
   readme, files, file_count, total_bytes, hash, bundle_b64, status)
values (
  'social-proof-blocks', 'social-proof-blocks', '在落地页或产品页加客户证言、Logo 墙、数据背书、案例卡片时使用：卡片字段、排布方式、可信度门槛与假证言带来的反噬。', 'ui',
  array['落地页', '证言卡片', 'Logo 墙', '案例研究', '数据背书', '信任设计']::text[], '1.0.0', 'MIT', 'Skill Hub',
  $md$---
name: "social-proof-blocks"
description: "在落地页或产品页加客户证言、Logo 墙、数据背书、案例卡片时使用：卡片字段、排布方式、可信度门槛与假证言带来的反噬。"
version: "1.0.0"
license: "MIT"
author: "Skill Hub"
category: ui
tags: ["落地页", "证言卡片", "Logo 墙", "案例研究", "数据背书", "信任设计"]
---

# 社会证明与信任模块

社会证明的作用是**把「你说你好」换成「别人说你好」**。
但它有一个反直觉的特性：**做得越像模板，效果越差甚至为负**。
一句「这个产品太好用了！」配一张图库头像，比不放更糟 ——
用户会立刻怀疑页面上其他内容也在造假。

## 何时使用

- 落地页转化率低，需要在 CTA 附近补信任
- 需要设计客户证言区、Logo 墙、案例研究卡片
- 手里只有「用户好评截图」，不知道怎么排才不像刷的
- 要决定证言用轮播还是平铺
- 需要在页面里加数据背书（用户数、处理量、评分）

## 核心规则

1. **证言卡片必须有 5 个字段，缺一个可信度就掉一档**：
   头像、姓名、职位 + 公司、具体成果（带数字）、证言正文。
   - 头像：真实照片，尺寸 40–48px 圆形；**没有真实照片就用姓名首字母色块，绝不用图库头像**
   - 姓名：全名或「姓 + 名首字」，不要用「王先生」「Amy W.」
   - 职位公司：`增长负责人 · 某科技`，公司名要能查证
   - 成果：`把新客注册转化从 3.1% 提到 5.4%` —— **数字是可信度的核心**
   - 正文：**40–120 字**，超过 120 字没人读，少于 40 字像敷衍

2. **证言绝对不要做成自动轮播**。理由：
   - 自动轮播的第 2、3 张曝光率通常 < 10%
   - 用户无法回看，且轮播动画会打断阅读
   - 轮播是「广告位」的视觉语言，会触发用户的心理防御
   正确做法：桌面端**平铺 3 列 × 1–2 行**（共 3–6 条），
   移动端纵向排列，超出部分用「查看更多」而不是自动翻页。
   如果一定要做轮播，必须是**手动**、有明确指示点、且第一屏至少露出 2.5 张卡片。

3. **Logo 墙的 Logo 数 5–8 个，统一灰度处理**：
   - `filter: grayscale(1); opacity: .55;`，hover 时恢复原色（可选）
   - 高度统一 24–32px，宽度自适应，间距 40–64px
   - **必须纵向对齐中心**，Logo 高低不齐会让整行看起来歪
   - Logo 数量少于 5 个时，**不要做 Logo 墙**，改成一条文字：
     `被 XX、XX 等 12 家团队使用` —— 3 个 Logo 排一行比没有更弱

4. **数据背书要「大数字 + 小说明」**：
   - 数字字号 40–56px，字重 600–700，用 `tabular-nums`
   - 说明字号 13–14px，颜色为次级文字色
   - 例：`12,000+` / `活跃团队`，`99.98%` / `过去 12 个月可用性`
   - 数据必须**可解释来源**。写「99.98% 可用性」要能指向状态页；
     写「10 万用户」要能说明是注册数还是活跃数

5. **案例研究卡片用「客户 + 问题 + 结果」三段式**，
   不要用「公司简介 + 赞美」。结构：
   - 客户 Logo + 行业
   - 一句话问题（20–30 字）
   - 结果数字（1–3 个，每个带单位）
   - 「阅读案例」链接
   卡片宽高比建议 4:3 或 16:10，三列并排时每张 ≥ 320px 宽。

6. **假证言会造成信任反噬，且不可逆**。以下是必须避免的信号：
   - 图库头像（多张证言用同一个模特不同裁切）
   - 证言里没有任何具体数字或场景
   - 所有证言都是同一个句式、同一个长度
   - 职位写成「CEO」「产品经理」但不写公司
   - 评分全是 5.0，没有 4 分
   一旦用户识别出其中一条是假的，**页面上所有内容（含真实数据）都会被重新怀疑**。
   宁可只放 2 条真证言，也不要放 6 条看起来像编的。

7. **证言要紧邻决策点放置**。位置优先级：
   1. 主 CTA 正下方 24–48px（转化效果最好）
   2. 定价表下方
   3. 页面独立区块（用于补充，不承担转化）
   放在页面最底部、与 CTA 隔着两屏的证言，基本不产生作用。

## 怎么做

### 第 1 步：先盘点手上有什么

不要先画版式。先列一张表，把真实素材摊开：

| 素材 | 是否有 | 可展示字段 |
| --- | --- | --- |
| 客户真实评价 | | 原文 + 出处 |
| 客户授权使用的姓名/公司 | | 姓名、职位、公司 |
| 客户头像照片 | | 尺寸、是否清晰 |
| 可量化的成果 | | 指标名、前后数值、周期 |
| 客户 Logo 授权 | | 是否允许灰度展示 |

缺哪一列就先去补，**不要用占位内容上线**。

### 第 2 步：写证言卡片

```html
<figure class="quote">
  <blockquote class="quote__text">
    接入前新客注册转化卡在 3.1%，主要是表单太长。换成他们的渐进式表单后
    两周内跑到 5.4%，我们没有改任何投放。
  </blockquote>
  <figcaption class="quote__author">
    <img src="/avatars/li.jpg" alt="" width="48" height="48" loading="lazy">
    <div>
      <span class="quote__name">李维</span>
      <span class="quote__role">增长负责人 · 云雀科技</span>
    </div>
  </figcaption>
</figure>
```

```css
.quote {
  display: flex;
  flex-direction: column;
  justify-content: space-between;   /* 让不同长度的证言底部作者行对齐 */
  min-height: 220px;
  padding: 24px;
  border: 1px solid var(--border);
  border-radius: 12px;
}
.quote__text {
  font-size: 16px;
  line-height: 1.7;
  margin: 0 0 20px;
  /* 中文长文不居中，左对齐；引号用中文引号「」而非 " " */
}
.quote__author { display: flex; align-items: center; gap: 12px; }
.quote__author img { border-radius: 50%; object-fit: cover; flex: 0 0 auto; }
.quote__role { font-size: 13px; color: var(--text-tertiary); }
```

用 `<figure>` + `<blockquote>` + `<figcaption>` 是语义正确的写法，
读屏能正确朗读出「引用 + 出处」的关系。

### 第 3 步：排布

- **桌面（≥ 1024px）**：`grid-template-columns: repeat(3, minmax(0, 1fr))`，
  最多 2 行共 6 条
- **平板（640–1023px）**：2 列
- **移动（< 640px）**：1 列，只显示 2–3 条，其余折叠

所有卡片**高度对齐**用 `justify-content: space-between`，
不要用固定 `height` —— 固定高度会在某条证言超长时被裁掉。

### 第 4 步：Logo 墙

```html
<div class="logo-wall" aria-label="部分客户">
  <img src="/logos/a.svg" alt="云雀科技" height="28">
  <img src="/logos/b.svg" alt="北辰数据" height="28">
  <!-- 共 5–8 个 -->
</div>
```

```css
.logo-wall {
  display: flex;
  flex-wrap: wrap;
  align-items: center;      /* 垂直居中，不是 baseline */
  justify-content: center;
  gap: 24px 56px;
}
.logo-wall img {
  filter: grayscale(1);
  opacity: .55;
  height: 28px;
  width: auto;
  transition: opacity .2s;
}
.logo-wall img:hover { opacity: .85; }
```

`alt` 必须写公司名，否则读屏用户完全不知道这行是什么。

### 第 5 步：数据背书

```html
<dl class="metrics">
  <div><dt class="metrics__num">12,000+</dt><dd>活跃团队</dd></div>
  <div><dt class="metrics__num">4.2 亿</dt><dd>累计处理订单</dd></div>
  <div><dt class="metrics__num">99.98%</dt><dd>过去 12 个月可用性</dd></div>
</dl>
```

- 数字统一用 `font-variant-numeric: tabular-nums`
- 数字单位与数值之间留 2–4px 空隙，不要紧贴（`4.2 亿` 而非 `4.2亿`）
- 指标数 3–4 个，超过 4 个会被当成「堆数据」而不被阅读
- 每个指标下方可加一行来源说明（字号 12px，颜色更浅），如「数据截至 2026-09」

## 检查清单

- [ ] 每条证言都有头像、姓名、职位+公司、具体成果数字
- [ ] 证言正文长度在 40–120 字之间，且句式不雷同
- [ ] 头像为真实照片或姓名首字母色块，无图库头像
- [ ] 证言未使用自动轮播；若用手动轮播，首屏至少露出 2.5 张
- [ ] 证言区至少有 1 条紧邻主 CTA（间距 ≤ 48px）
- [ ] Logo 墙 5–8 个 Logo，统一灰度 + 统一高度 + 垂直居中
- [ ] Logo 的 `alt` 写了公司名
- [ ] 数据背书 3–4 个指标，数字用 `tabular-nums`，并标注数据口径与时间
- [ ] 案例卡片为「客户 + 问题 + 结果数字」三段式
- [ ] 移动端证言纵向排列，最多显示 3 条，其余折叠
- [ ] 页面上不存在任何无法查证的「XX 先生/女士」式匿名证言
- [ ] 所有数字都能指出来源（后台数据、状态页、第三方报告）

## 常见错误

| 错误做法 | 为什么错 | 正确做法 |
| --- | --- | --- |
| 自动轮播证言 | 第 2 张起曝光率 < 10%，且轮播是广告的视觉语言，触发防御 | 平铺 3–6 条，移动端纵向排列 |
| 图库头像 / AI 生成头像 | 用户识别出后，会怀疑页面上所有内容造假 | 真实照片，或姓名首字母色块 |
| 证言只写「非常好用，强烈推荐」 | 无信息量，反而拉低可信度 | 必须有具体场景 + 数字成果 |
| 所有证言长度和句式一致 | 像是同一个人写的，或批量编的 | 保持原文，长度自然参差 |
| 职位写「CEO」不写公司 | 无法查证，可信度接近零 | 写「CEO · 具体公司名」 |
| 评分全是 5.0 分 | 没有分布，用户本能怀疑 | 展示真实分布（如 4.8 分，含 3% 的 3 分） |
| Logo 墙只放 3 个 Logo | 显得客户很少，是负向证明 | 少于 5 个改成一句话文字 |
| Logo 墙 Logo 高度不一且基线对齐 | 整行看起来歪，观感廉价 | 统一 `height` + `align-items: center` |
| 数据写「10 万用户」不写口径 | 用户不知道是注册数、日活还是累计 | 写清口径与截止时间 |
| 证言卡片固定 `height` | 长证言被裁切，短证言下方大片空白 | `min-height` + `space-between` |
| 证言放在页面最底部 | 与决策点隔两屏，几乎不产生转化作用 | 至少一条紧邻主 CTA |
| 把「客户说」做成品牌色大卡片 + 大字 | 视觉上像广告，可信度下降 | 用中性卡片，弱化容器，突出内容本身 |

## 参考

- 需要具体写证言文案、筛选与授权流程时，读 `references/testimonial-copy.md`
- 需要设计完整案例研究页（含数据图表、时间线）时，读 `references/case-study-card.md`
$md$,
  '[{"path":"ATTRIBUTION.md","size":484,"kind":"text"},{"path":"LICENSE","size":1074,"kind":"text"},{"path":"SKILL.md","size":10464,"kind":"text"},{"path":"references/case-study-card.md","size":4798,"kind":"text"},{"path":"references/testimonial-copy.md","size":3967,"kind":"text"}]'::jsonb, 5, 20787, '1f2669de9bb8b5c3f9f6b166d4ed30b529bef4a933fd77cf712ac47789927053',
  $b64$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$b64$,
  'published'
)
on conflict do nothing;
