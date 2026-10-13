-- ============================================================================
-- UI 技能包入库 · APP 移动应用（6 个）
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
  'apple-hig-expert', 'apple-hig-expert', '按 Apple 人机界面指南（HIG）设计与审计 iOS / macOS / watchOS / visionOS 界面，覆盖 iOS 26 的 Liquid Glass 设计语言；检查对比度、点击热区与原生观感。', 'ui',
  array['Apple', 'HIG', 'iOS', 'Liquid Glass', '原生界面', '点击热区', '审计']::text[], '1.1.0', 'MIT', 'Alireza Rezvani',
  $md$---
name: "apple-hig-expert"
description: "按 Apple 人机界面指南（HIG）设计与审计 iOS / macOS / watchOS / visionOS 界面，覆盖 iOS 26 的 Liquid Glass 设计语言；检查对比度、点击热区与原生观感。"
version: "1.1.0"
license: "MIT"
author: "Alireza Rezvani"
category: ui
tags: ["Apple", "HIG", "iOS", "Liquid Glass", "原生界面", "点击热区", "审计"]
---

# Apple HIG Expert

Design and audit apps against the Apple Human Interface Guidelines (HIG, [developer.apple.com/design/human-interface-guidelines](https://developer.apple.com/design/human-interface-guidelines)), including the **Liquid Glass** design language. HIG content evolves with each OS release — when a claim matters, verify against the live HIG pages cited in `references/`.

## Before Starting

If `product-context.md` or `ios-design-context.md` exists, read it before asking questions. Then gather:

1. **Platform target**: iOS, macOS, watchOS, or visionOS?
2. **Current state**: new design or auditing an existing mockup/code?
3. **App category**: utility, productivity, game, social, etc.

## Modes

- **Mode 1 — Design from scratch**: pick the platform navigation paradigm and layout primitives first (see `references/platform-specifics.md`), then apply typography and semantic color (`references/visual-design.md`).
- **Mode 2 — HIG audit**: fill in `templates/hig-audit-template.md`, run `scripts/hig_checker.py` on every measurable element, and deliver a scored report (see Worked example below).

## The Compliance Tool

`scripts/hig_checker.py` (stdlib-only) has three subcommands:

```bash
# 1. Contrast ratio (WCAG formula; pass >= 4.5:1 for normal text)
python3 scripts/hig_checker.py contrast "#8E8E93" "#FFFFFF"
# -> Contrast Ratio: 3.26 [FAILED]

# 2. Tap-target size (pass >= 44x44 pt per HIG)
python3 scripts/hig_checker.py target 32 32
# -> Tap Target: 32x32 [FAILED]

# 3. Batch audit from JSON -> scorecard (starts at 100, -10 per violation)
python3 scripts/hig_checker.py batch audit.json
```

Batch input shape:

```json
{
  "checks": [
    {"type": "contrast", "name": "caption-on-card", "fg": "#8E8E93", "bg": "#FFFFFF"},
    {"type": "target", "name": "close-button", "w": 32, "h": 32}
  ]
}
```

**Scorecard rubric:** the batch score starts at 100 and subtracts 10 per failed check; violations are listed by element name. 90-100 = ship, 70-80 = fix before release, below 70 = systematic rework. Checks the tool cannot measure (VoiceOver labels, Dynamic Type behavior, Reduce Transparency) are assessed manually via the audit template and tagged with confidence.

## Worked example: iOS settings-screen audit

**Input:** mockup with body text `#1C1C1E` and captions `#8E8E93` on white cards, a 32x32 pt close button, and a 343x50 pt primary CTA.

**Run:**

```bash
python3 scripts/hig_checker.py batch audit.json
```

**Output (real):**

```json
{
  "score": 80,
  "violations": [
    "Contrast 3.26 fails for caption-on-card",
    "Target 32x32 small for close-button"
  ]
}
```

**Findings → fixes (bottom line first):**

> **HIG score 80/100 — two fixes before release.**
> 1. Captions fail contrast (3.26 < 4.5). Use `.secondaryLabel` (semantic color) instead of hardcoded `#8E8E93`, or darken to ≥ `#6E6E73` on white. 🟢 verified by tool.
> 2. Close button is 32x32 pt (< 44x44 minimum). Keep the glyph small but expand the hit region to 44x44 with padding/`contentShape`. 🟢 verified by tool.
> 3. Manual check: the card uses an ultra-thin material over a photo background — re-test caption contrast against the *busiest* underlying region and with Reduce Transparency on. 🟡 needs device test.

## Core Design Principles

1. **Liquid Glass** — translucent material hierarchy (announced at WWDC25, June 2025; shipped Sept 2025 across iOS 26, iPadOS 26, macOS Tahoe, watchOS 26, tvOS 26, visionOS 26). In SwiftUI, apply it via the `glassEffect` view modifier; keep hierarchy between content and controls. See `references/visual-design.md`.
2. **Accessibility first** — VoiceOver labels on every element, 44x44 pt minimum targets, 4.5:1 contrast for normal text (3:1 large text), Dynamic Type support. See `references/accessibility.md`.
3. **Platform ergonomics** — tab bars/thumb reach on iOS, sidebars + menu bar + shortcuts on macOS, ornaments + gaze states on visionOS, glanceable vertical layouts on watchOS. See `references/platform-specifics.md`.

## Proactive Triggers

Surface these WITHOUT being asked: low contrast over translucent layers; interactive elements under 44 pt; icon buttons with no accessibility label; density overload (no breathing room between glass layers).

## Communication

- **Bottom line first** — compliance status before details.
- **What + Why + How** — "Expand the hit region (What) because 32 pt targets fail the HIG minimum (Why); pad to 44x44 via contentShape (How)."
- **Confidence tagging** — 🟢 tool-verified / 🟡 needs device test / 🔴 assumed.

## Related Skills

- **ui-design-system**: token-based component systems (not platform HIG rules).
- **ux-researcher-designer**: persona/research validation (not visual styling).
- **landing-page-generator**: web marketing pages, not native apps.
$md$,
  '[{"path":"ATTRIBUTION.md","size":982,"kind":"text"},{"path":"LICENSE","size":1072,"kind":"text"},{"path":"SKILL.md","size":5213,"kind":"text"},{"path":"references/accessibility.md","size":2743,"kind":"text"},{"path":"references/platform-specifics.md","size":2784,"kind":"text"},{"path":"references/visual-design.md","size":3506,"kind":"text"},{"path":"scripts/hig_checker.py","size":3614,"kind":"text"},{"path":"templates/hig-audit-template.md","size":2056,"kind":"text"}]'::jsonb, 8, 21970, '8f96457e3cb232149820b37a074faf2cbdcc6a7a2c1730ba1717d3405e5f1ef3',
  $b64$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$b64$,
  'published'
)
on conflict do nothing;

insert into public.skills
  (slug, name, description, category, tags, version, license, author,
   readme, files, file_count, total_bytes, hash, bundle_b64, status)
values (
  'paywall-upgrade-cro', 'paywall-upgrade-cro', '应用内付费墙与升级时刻设计：升级弹窗、功能门禁、试用到期页、额度用尽提示，聚焦「用户已经感受到价值」之后的那一次转化。', 'ui',
  array['付费墙', '升级页', '弹窗', '功能门禁', '转化', '应用内', '订阅']::text[], '1.0.0', 'MIT', 'Alireza Rezvani',
  $md$---
name: "paywall-upgrade-cro"
description: "应用内付费墙与升级时刻设计：升级弹窗、功能门禁、试用到期页、额度用尽提示，聚焦「用户已经感受到价值」之后的那一次转化。"
version: "1.0.0"
license: "MIT"
author: "Alireza Rezvani"
category: ui
tags: ["付费墙", "升级页", "弹窗", "功能门禁", "转化", "应用内", "订阅"]
---

# Paywall and Upgrade Screen CRO

You are an expert in in-app paywalls and upgrade flows. Your goal is to convert free users to paid, or upgrade users to higher tiers, at moments when they've experienced enough value to justify the commitment.

## Initial Assessment

**Check for product marketing context first:**
If `.claude/product-marketing-context.md` exists, read it before asking questions. Use that context and only ask for information not already covered or specific to this task.

Before providing recommendations, understand:

1. **Upgrade Context** - Freemium → Paid? Trial → Paid? Tier upgrade? Feature upsell? Usage limit?

2. **Product Model** - What's free? What's behind paywall? What triggers prompts? Current conversion rate?

3. **User Journey** - When does this appear? What have they experienced? What are they trying to do?

---

## Core Principles

### 1. Value Before Ask
- User should have experienced real value first
- Upgrade should feel like natural next step
- Timing: After "aha moment," not before

### 2. Show, Don't Just Tell
- Demonstrate the value of paid features
- Preview what they're missing
- Make the upgrade feel tangible

### 3. Friction-Free Path
- Easy to upgrade when ready
- Don't make them hunt for pricing

### 4. Respect the No
- Don't trap or pressure
- Make it easy to continue free
- Maintain trust for future conversion

---

## Paywall Trigger Points

### Feature Gates
When user clicks a paid-only feature:
- Clear explanation of why it's paid
- Show what the feature does
- Quick path to unlock
- Option to continue without

### Usage Limits
When user hits a limit:
- Clear indication of limit reached
- Show what upgrading provides
- Don't block abruptly

### Trial Expiration
When trial is ending:
- Early warnings (7, 3, 1 day)
- Clear "what happens" on expiration
- Summarize value received

### Time-Based Prompts
After X days of free use:
- Gentle upgrade reminder
- Highlight unused paid features
- Easy to dismiss

---

## Paywall Screen Components

1. **Headline** - Focus on what they get: "Unlock [Feature] to [Benefit]"

2. **Value Demonstration** - Preview, before/after, "With Pro you could..."

3. **Feature Comparison** - Highlight key differences, current plan marked

4. **Pricing** - Clear, simple, annual vs. monthly options

5. **Social Proof** - Customer quotes, "X teams use this"

6. **CTA** - Specific and value-oriented: "Start Getting [Benefit]"

7. **Escape Hatch** - Clear "Not now" or "Continue with Free"

---

## Specific Paywall Types

### Feature Lock Paywall
```
[Lock Icon]
This feature is available on Pro

[Feature preview/screenshot]

[Feature name] helps you [benefit]:
• [Capability]
• [Capability]

[Upgrade to Pro - $X/mo]
[Maybe Later]
```

### Usage Limit Paywall
```
You've reached your free limit

[Progress bar at 100%]

Free: 3 projects | Pro: Unlimited

[Upgrade to Pro]  [Delete a project]
```

### Trial Expiration Paywall
```
Your trial ends in 3 days

What you'll lose:
• [Feature used]
• [Data created]

What you've accomplished:
• Created X projects

[Continue with Pro]
[Remind me later]  [Downgrade]
```

---

## Timing and Frequency

### When to Show
- After value moment, before frustration
- After activation/aha moment
- When hitting genuine limits

### When NOT to Show
- During onboarding (too early)
- When they're in a flow
- Repeatedly after dismissal

### Frequency Rules
- Limit per session
- Cool-down after dismiss (days, not hours)
- Track annoyance signals

---

## Upgrade Flow Optimization

### From Paywall to Payment
- Minimize steps
- Keep in-context if possible
- Pre-fill known information

### Post-Upgrade
- Immediate access to features
- Confirmation and receipt
- Guide to new features

---

## A/B Testing

### What to Test
- Trigger timing
- Headline/copy variations
- Price presentation
- Trial length
- Feature emphasis
- Design/layout

### Metrics to Track
- Paywall impression rate
- Click-through to upgrade
- Completion rate
- Revenue per user
- Churn rate post-upgrade

---

## Anti-Patterns to Avoid

### Dark Patterns
- Hiding the close button
- Confusing plan selection
- Guilt-trip copy

### Conversion Killers
- Asking before value delivered
- Too frequent prompts
- Blocking critical flows
- Complicated upgrade process

---

## Task-Specific Questions

1. What's your current free → paid conversion rate?
2. What triggers upgrade prompts today?
3. What features are behind the paywall?
4. What's your "aha moment" for users?
5. What pricing model? (per seat, usage, flat)
6. Mobile app, web app, or both?

---

## Related Skills

- **page-cro** — WHEN the public-facing pricing page needs optimization (before users are in-app). NOT for in-product upgrade screens or feature gates.
- **onboarding-cro** — WHEN users haven't reached their activation moment and are hitting paywalls too early; fix onboarding first. NOT when value has already been delivered.
- **ab-test-setup** — WHEN running controlled experiments on paywall trigger timing, copy, pricing display, or layout. NOT for initial paywall design.
- **email-sequence** — WHEN setting up trial expiration or upgrade reminder email sequences to complement in-app prompts. NOT as a replacement for in-app paywall design.
- **marketing-context** — Foundation skill for understanding ICP, pricing model, and value proposition. Load before designing paywall copy and positioning.

---

## Communication

Paywall recommendations must account for where the user is in their value journey — always confirm whether the aha moment has been reached before recommending upgrade prompt placement. When writing paywall copy, deliver complete screen copy: headline, value statement, feature list, CTA, and escape hatch text. Flag dark patterns proactively and recommend ethical alternatives. Load `marketing-context` for pricing model and plan structure context before writing copy.

---

## Proactive Triggers

- User reports low free-to-paid conversion rate → ask where in the journey the paywall appears and whether the aha moment is reached first.
- User mentions users hitting limits and churning → distinguish between limit frustration (fix timing/messaging) vs. wrong ICP (fix acquisition).
- User asks about freemium model design → help define what's free vs. paid, then design paywall moments around natural value gaps.
- User shares a trial expiration screen → audit for dark patterns, missing escape hatches, and unclear value summarization.
- User mentions mobile app monetization → flag platform-specific considerations (App Store IAP rules, Google Play billing requirements).

---

## Output Artifacts

| Artifact | Description |
|----------|-------------|
| Paywall Trigger Map | All paywall trigger points with timing rules, cooldown periods, and frequency caps |
| Full Paywall Screen Copy | Headline, value demonstration, feature comparison, CTA, and escape hatch for each paywall type |
| Upgrade Flow Diagram | Step-by-step from paywall click to post-upgrade confirmation with friction reduction notes |
| Anti-Pattern Audit | Review of existing paywall for dark patterns, trust-damaging copy, and conversion killers |
| A/B Test Backlog | Prioritized experiment ideas for trigger timing, copy, and pricing display |
$md$,
  '[{"path":"ATTRIBUTION.md","size":971,"kind":"text"},{"path":"LICENSE","size":1072,"kind":"text"},{"path":"SKILL.md","size":7671,"kind":"text"}]'::jsonb, 3, 9714, 'b0e29731c19c15c8162a403ccbc14ca237ec259a2709f7281d41b394d0f6960a',
  $b64$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$b64$,
  'published'
)
on conflict do nothing;

insert into public.skills
  (slug, name, description, category, tags, version, license, author,
   readme, files, file_count, total_bytes, hash, bundle_b64, status)
values (
  'app-store-optimization', 'app-store-optimization', '应用商店优化（ASO）：关键词研究与打分、竞品排名分析、标题与描述元信息优化、A/B 测试规划与上架检查清单，覆盖 App Store 与 Google Play。', 'ui',
  array['ASO', '应用商店', '关键词', '元信息', '上架清单', 'iOS', 'Android']::text[], '1.0.0', 'MIT', 'Alireza Rezvani',
  $md$---
name: "app-store-optimization"
description: "应用商店优化（ASO）：关键词研究与打分、竞品排名分析、标题与描述元信息优化、A/B 测试规划与上架检查清单，覆盖 App Store 与 Google Play。"
version: "1.0.0"
license: "MIT"
author: "Alireza Rezvani"
category: ui
tags: ["ASO", "应用商店", "关键词", "元信息", "上架清单", "iOS", "Android"]
---

# App Store Optimization (ASO)

---

## Keyword Research Workflow

Discover and evaluate keywords that drive app store visibility.

### Workflow: Conduct Keyword Research

1. Define target audience and core app functions:
   - Primary use case (what problem does the app solve)
   - Target user demographics
   - Competitive category
2. Generate seed keywords from:
   - App features and benefits
   - User language (not developer terminology)
   - App store autocomplete suggestions
3. Expand keyword list using:
   - Modifiers (free, best, simple)
   - Actions (create, track, organize)
   - Audiences (for students, for teams, for business)
4. Evaluate each keyword:
   - Search volume (estimated monthly searches)
   - Competition (number and quality of ranking apps)
   - Relevance (alignment with app function)
5. Score and prioritize keywords:
   - Primary: Title and keyword field (iOS)
   - Secondary: Subtitle and short description
   - Tertiary: Full description only
6. Map keywords to metadata locations
7. Document keyword strategy for tracking
8. **Validation:** Keywords scored; placement mapped; no competitor brand names included; no plurals in iOS keyword field

### Keyword Evaluation Criteria

| Factor | Weight | High Score Indicators |
|--------|--------|----------------------|
| Relevance | 35% | Describes core app function |
| Volume | 25% | 10,000+ monthly searches |
| Competition | 25% | Top 10 apps have <4.5 avg rating |
| Conversion | 15% | Transactional intent ("best X app") |

### Keyword Placement Priority

| Location | Search Weight |
|----------|---------------|
| App Title | Highest |
| Subtitle (iOS) | High |
| Keyword Field (iOS) | High |
| Short Description (Android) | High |
| Full Description | Medium |

See: [references/keyword-research-guide.md](references/keyword-research-guide.md)

---

## Metadata Optimization Workflow

Optimize app store listing elements for search ranking and conversion.

### Workflow: Optimize App Metadata

1. Audit current metadata against platform limits:
   - Title character count and keyword presence
   - Subtitle/short description usage
   - Keyword field efficiency (iOS)
   - Description keyword density
2. Optimize title following formula:
   ```
   [Brand Name] - [Primary Keyword] [Secondary Keyword]
   ```
3. Write subtitle (iOS) or short description (Android):
   - Focus on primary benefit
   - Include secondary keyword
   - Use action verbs
4. Optimize keyword field (iOS only):
   - Remove duplicates from title
   - Remove plurals (Apple indexes both forms)
   - No spaces after commas
   - Prioritize by score
5. Rewrite full description:
   - Hook paragraph with value proposition
   - Feature bullets with keywords
   - Social proof section
   - Call to action
6. Validate character counts for each field
7. Calculate keyword density (target 2-3% primary)
8. **Validation:** All fields within character limits; primary keyword in title; no keyword stuffing (>5%); natural language preserved

### Platform Character Limits

| Field | Apple App Store | Google Play Store |
|-------|-----------------|-------------------|
| Title | 30 characters | 50 characters |
| Subtitle | 30 characters | N/A |
| Short Description | N/A | 80 characters |
| Keywords | 100 characters | N/A |
| Promotional Text | 170 characters | N/A |
| Full Description | 4,000 characters | 4,000 characters |
| What's New | 4,000 characters | 500 characters |

### Description Structure

```
PARAGRAPH 1: Hook (50-100 words)
├── Address user pain point
├── State main value proposition
└── Include primary keyword

PARAGRAPH 2-3: Features (100-150 words)
├── Top 5 features with benefits
├── Bullet points for scanability
└── Secondary keywords naturally integrated

PARAGRAPH 4: Social Proof (50-75 words)
├── Download count or rating
├── Press mentions or awards
└── Summary of user testimonials

PARAGRAPH 5: Call to Action (25-50 words)
├── Clear next step
└── Reassurance (free trial, no signup)
```

See: [references/platform-requirements.md](references/platform-requirements.md)

---

## Competitor Analysis Workflow

Analyze top competitors to identify keyword gaps and positioning opportunities.

### Workflow: Analyze Competitor ASO Strategy

1. Identify top 10 competitors:
   - Direct competitors (same core function)
   - Indirect competitors (overlapping audience)
   - Category leaders (top downloads)
2. Extract competitor keywords from:
   - App titles and subtitles
   - First 100 words of descriptions
   - Visible metadata patterns
3. Build competitor keyword matrix:
   - Map which keywords each competitor targets
   - Calculate coverage percentage per keyword
4. Identify keyword gaps:
   - Keywords with <40% competitor coverage
   - High volume terms competitors miss
   - Long-tail opportunities
5. Analyze competitor visual assets:
   - Icon design patterns
   - Screenshot messaging and style
   - Video presence and quality
6. Compare ratings and review patterns:
   - Average rating by competitor
   - Common praise themes
   - Common complaint themes
7. Document positioning opportunities
8. **Validation:** 10+ competitors analyzed; keyword matrix complete; gaps identified with volume estimates; visual audit documented

### Competitor Analysis Matrix

| Analysis Area | Data Points |
|---------------|-------------|
| Keywords | Title keywords, description frequency |
| Metadata | Character utilization, keyword density |
| Visuals | Icon style, screenshot count/style |
| Ratings | Average rating, total count, velocity |
| Reviews | Top praise, top complaints |

### Gap Analysis Template

| Opportunity Type | Example | Action |
|------------------|---------|--------|
| Keyword gap | "habit tracker" (40% coverage) | Add to keyword field |
| Feature gap | Competitor lacks widget | Highlight in screenshots |
| Visual gap | No videos in top 5 | Create app preview |
| Messaging gap | None mention "free" | Test free positioning |

---

## App Launch Workflow

Execute a structured launch for maximum initial visibility.

### Workflow: Launch App to Stores

1. Complete pre-launch preparation (4 weeks before):
   - Finalize keywords and metadata
   - Prepare all visual assets
   - Set up analytics (Firebase, Mixpanel)
   - Build press kit and media list
2. Submit for review (2 weeks before):
   - Complete all store requirements
   - Verify compliance with guidelines
   - Prepare launch communications
3. Configure post-launch systems:
   - Set up review monitoring
   - Prepare response templates
   - Configure rating prompt timing
4. Execute launch day:
   - Verify app is live in both stores
   - Announce across all channels
   - Begin review response cycle
5. Monitor initial performance (days 1-7):
   - Track download velocity hourly
   - Monitor reviews and respond within 24 hours
   - Document any issues for quick fixes
6. Conduct 7-day retrospective:
   - Compare performance to projections
   - Identify quick optimization wins
   - Plan first metadata update
7. Schedule first update (2 weeks post-launch)
8. **Validation:** App live in stores; analytics tracking; review responses within 24h; download velocity documented; first update scheduled

### Pre-Launch Checklist

| Category | Items |
|----------|-------|
| Metadata | Title, subtitle, description, keywords |
| Visual Assets | Icon, screenshots (all sizes), video |
| Compliance | Age rating, privacy policy, content rights |
| Technical | App binary, signing certificates |
| Analytics | SDK integration, event tracking |
| Marketing | Press kit, social content, email ready |

### Launch Timing Considerations

| Factor | Recommendation |
|--------|----------------|
| Day of week | Tuesday-Wednesday (avoid weekends) |
| Time of day | Morning in target market timezone |
| Seasonal | Align with relevant category seasons |
| Competition | Avoid major competitor launch dates |

See: [references/aso-best-practices.md](references/aso-best-practices.md)

---

## A/B Testing Workflow

Test metadata and visual elements to improve conversion rates.

### Workflow: Run A/B Test

1. Select test element (prioritize by impact):
   - Icon (highest impact)
   - Screenshot 1 (high impact)
   - Title (high impact)
   - Short description (medium impact)
2. Form hypothesis:
   ```
   If we [change], then [metric] will [improve/increase] by [amount]
   because [rationale].
   ```
3. Create variants:
   - Control: Current version
   - Treatment: Single variable change
4. Calculate required sample size:
   - Baseline conversion rate
   - Minimum detectable effect (usually 5%)
   - Statistical significance (95%)
5. Launch test:
   - Apple: Use Product Page Optimization
   - Android: Use Store Listing Experiments
6. Run test for minimum duration:
   - At least 7 days
   - Until statistical significance reached
7. Analyze results:
   - Compare conversion rates
   - Check statistical significance
   - Document learnings
8. **Validation:** Single variable tested; sample size sufficient; significance reached (95%); results documented; winner implemented

### A/B Test Prioritization

| Element | Conversion Impact | Test Complexity |
|---------|-------------------|-----------------|
| App Icon | 10-25% lift possible | Medium (design needed) |
| Screenshot 1 | 15-35% lift possible | Medium |
| Title | 5-15% lift possible | Low |
| Short Description | 5-10% lift possible | Low |
| Video | 10-20% lift possible | High |

### Sample Size Quick Reference

| Baseline CVR | Impressions Needed (per variant) |
|--------------|----------------------------------|
| 1% | 31,000 |
| 2% | 15,500 |
| 5% | 6,200 |
| 10% | 3,100 |

### Test Documentation Template

```
TEST ID: ASO-2025-001
ELEMENT: App Icon
HYPOTHESIS: A bolder color icon will increase conversion by 10%
START DATE: [Date]
END DATE: [Date]

RESULTS:
├── Control CVR: 4.2%
├── Treatment CVR: 4.8%
├── Lift: +14.3%
├── Significance: 97%
└── Decision: Implement treatment

LEARNINGS:
- Bold colors outperform muted tones in this category
- Apply to screenshot backgrounds for next test
```

---

## Before/After Examples

### Title Optimization

**Productivity App:**

| Version | Title | Analysis |
|---------|-------|----------|
| Before | "MyTasks" | No keywords, brand only (8 chars) |
| After | "MyTasks - Todo List & Planner" | Primary + secondary keywords (29 chars) |

**Fitness App:**

| Version | Title | Analysis |
|---------|-------|----------|
| Before | "FitTrack Pro" | Generic modifier (12 chars) |
| After | "FitTrack: Workout Log & Gym" | Category keywords (27 chars) |

### Subtitle Optimization (iOS)

| Version | Subtitle | Analysis |
|---------|----------|----------|
| Before | "Get Things Done" | Vague, no keywords |
| After | "Daily Task Manager & Planner" | Two keywords, benefit clear |

### Keyword Field Optimization (iOS)

**Before (Inefficient - 89 chars, 8 keywords):**
```
task manager, todo list, productivity app, daily planner, reminder app
```

**After (Optimized - 97 chars, 14 keywords):**
```
task,todo,checklist,reminder,organize,daily,planner,schedule,deadline,goals,habit,widget,sync,team
```

**Improvements:**
- Removed spaces after commas (+8 chars)
- Removed duplicates (task manager → task)
- Removed plurals (reminders → reminder)
- Removed words in title
- Added more relevant keywords

### Description Opening

**Before:**
```
MyTasks is a comprehensive task management solution designed
to help busy professionals organize their daily activities
and boost productivity.
```

**After:**
```
Forget missed deadlines. MyTasks keeps every task, reminder,
and project in one place—so you focus on doing, not remembering.
Trusted by 500,000+ professionals.
```

**Improvements:**
- Leads with user pain point
- Specific benefit (not generic "boost productivity")
- Social proof included
- Keywords natural, not stuffed

### Screenshot Caption Evolution

| Version | Caption | Issue |
|---------|---------|-------|
| Before | "Task List Feature" | Feature-focused, passive |
| Better | "Create Task Lists" | Action verb, but still feature |
| Best | "Never Miss a Deadline" | Benefit-focused, emotional |

---

## Tools and References

### Scripts

| Script | Purpose | Usage |
|--------|---------|-------|
| [keyword_analyzer.py](scripts/keyword_analyzer.py) | Analyze keywords for volume and competition | `python keyword_analyzer.py --keywords "todo,task,planner"` |
| [metadata_optimizer.py](scripts/metadata_optimizer.py) | Validate metadata character limits and density | `python metadata_optimizer.py --platform ios --title "App Title"` |
| [competitor_analyzer.py](scripts/competitor_analyzer.py) | Extract and compare competitor keywords | `python competitor_analyzer.py --competitors "App1,App2,App3"` |
| [aso_scorer.py](scripts/aso_scorer.py) | Calculate overall ASO health score | `python aso_scorer.py --app-id com.example.app` |
| [ab_test_planner.py](scripts/ab_test_planner.py) | Plan tests and calculate sample sizes | `python ab_test_planner.py --cvr 0.05 --lift 0.10` |
| [review_analyzer.py](scripts/review_analyzer.py) | Analyze review sentiment and themes | `python review_analyzer.py --app-id com.example.app` |
| [launch_checklist.py](scripts/launch_checklist.py) | Generate platform-specific launch checklists | `python launch_checklist.py --platform ios` |
| [localization_helper.py](scripts/localization_helper.py) | Manage multi-language metadata | `python localization_helper.py --locales "en,es,de,ja"` |

### References

| Document | Content |
|----------|---------|
| [platform-requirements.md](references/platform-requirements.md) | iOS and Android metadata specs, visual asset requirements |
| [aso-best-practices.md](references/aso-best-practices.md) | Optimization strategies, rating management, launch tactics |
| [keyword-research-guide.md](references/keyword-research-guide.md) | Research methodology, evaluation framework, tracking |

### Assets

| Template | Purpose |
|----------|---------|
| [aso-audit-template.md](assets/aso-audit-template.md) | Structured audit checklist for app store listings |

---

## Platform Notes

| Platform / Constraint | Behavior / Impact |
|-----------------------|-------------------|
| iOS keyword changes | Require app submission |
| iOS promotional text | Editable without an app update |
| Android metadata changes | Index in 1-2 hours |
| Android keyword field | None — use description instead |
| Keyword volume data | Estimates only; no official source |
| Competitor data | Public listings only |

**When not to use this skill:** web apps (use web SEO), enterprise/internal apps, TestFlight-only betas, or paid advertising strategy.

---

## Related Skills

| Skill | Integration Point |
|-------|-------------------|
| [content-creator](../content-creator/) | App description copywriting |
| [marketing-demand-acquisition](../marketing-demand-acquisition/) | Launch promotion campaigns |
| [marketing-strategy-pmm](../marketing-strategy-pmm/) | Go-to-market planning |

## Proactive Triggers

- **No keyword optimization in title** → App title is the #1 ranking factor. Include top keyword.
- **Screenshots don't show value** → Screenshots should tell a story, not show UI.
- **No ratings strategy** → Below 4.0 stars kills conversion. Implement in-app rating prompts.
- **Description keyword-stuffed** → Natural language with keywords beats keyword stuffing.

## Output Artifacts

| When you ask for... | You get... |
|---------------------|------------|
| "ASO audit" | Full app store listing audit with prioritized fixes |
| "Keyword research" | Keyword list with search volume and difficulty scores |
| "Optimize my listing" | Rewritten title, subtitle, description, keyword field |

## Communication

All output passes quality verification:
- Self-verify: source attribution, assumption audit, confidence scoring
- Output format: Bottom Line → What (with confidence) → Why → How to Act
- Results only. Every finding tagged: 🟢 verified, 🟡 medium, 🔴 assumed.
$md$,
  '[{"path":"ATTRIBUTION.md","size":974,"kind":"text"},{"path":"HOW_TO_USE.md","size":10252,"kind":"text"},{"path":"LICENSE","size":1072,"kind":"text"},{"path":"README.md","size":14917,"kind":"text"},{"path":"SKILL.md","size":16472,"kind":"text"},{"path":"assets/aso-audit-template.md","size":4871,"kind":"text"},{"path":"expected_output.json","size":5492,"kind":"text"},{"path":"references/aso-best-practices.md","size":12488,"kind":"text"},{"path":"references/keyword-research-guide.md","size":11906,"kind":"text"},{"path":"references/platform-requirements.md","size":9575,"kind":"text"},{"path":"sample_input.json","size":723,"kind":"text"},{"path":"scripts/ab_test_planner.py","size":22857,"kind":"text"},{"path":"scripts/aso_scorer.py","size":18966,"kind":"text"},{"path":"scripts/competitor_analyzer.py","size":21340,"kind":"text"},{"path":"scripts/keyword_analyzer.py","size":13108,"kind":"text"},{"path":"scripts/launch_checklist.py","size":28949,"kind":"text"},{"path":"scripts/localization_helper.py","size":22142,"kind":"text"},{"path":"scripts/metadata_optimizer.py","size":20824,"kind":"text"},{"path":"scripts/review_analyzer.py","size":25561,"kind":"text"}]'::jsonb, 19, 262489, '30d0b286a81546114c3e709c3a2fcf0f86adaa84edb65ea45440cb531571555a',
  $b64$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$b64$,
  'published'
)
on conflict do nothing;

insert into public.skills
  (slug, name, description, category, tags, version, license, author,
   readme, files, file_count, total_bytes, hash, bundle_b64, status)
values (
  'material-design-3', 'material-design-3', '在 Android 或 Web 上落地 Material Design 3 时使用：动态取色与色调调板、表面分层与形状刻度、组件尺寸规范，以及从 M2 迁移到 M3 的差异清单。', 'ui',
  array['APP 移动端', '动态取色', 'HCT 色彩空间', '色调调板', 'Elevation 分层', '形状刻度', 'M2 迁移']::text[], '1.0.0', 'MIT', 'Skill Hub',
  $md$---
name: "material-design-3"
description: "在 Android 或 Web 上落地 Material Design 3 时使用：动态取色与色调调板、表面分层与形状刻度、组件尺寸规范，以及从 M2 迁移到 M3 的差异清单。"
version: "1.0.0"
license: "MIT"
author: "Skill Hub"
category: ui
tags: ["APP 移动端", "动态取色", "HCT 色彩空间", "色调调板", "Elevation 分层", "形状刻度", "M2 迁移"]
---

# Material Design 3 落地手册

M3 不是「M2 换了个圆角」。它的核心变化是**颜色由色调（tone）派生而不是手写十六进制**，
以及**层级由表面色差而不是阴影表达**。把这两条搞错，做出来就是个换了配色的 M2。

## 何时使用

- 从零搭一个遵循 M3 的 Android / Compose 应用，或 Flutter / Web 上复刻 M3
- 已有 M2 项目要迁移到 M3，需要知道哪些数值变了
- 要接「动态取色」（Material You），跟随用户壁纸生成主题
- 组件尺寸对不上：按钮高度、FAB 大小、底部导航高度和官方规范不一致

## 核心规则

1. **颜色只从 5 组色调调板（tonal palette）里取，禁止手写 `#6750A4` 之外的随机色值。**
   调板是 primary / secondary / tertiary / neutral / neutral-variant / error 六组，
   每组含 tone 0、10、20、30、40、50、60、70、80、90、95、99、100 共 13 档。
   手写色值等于放弃了暗色模式、对比度校验和动态取色三件事。

2. **角色（role）到 tone 的映射是固定的**，不要凭感觉选：

   | 角色 | 浅色 tone | 深色 tone |
   | --- | --- | --- |
   | primary / on-primary | 40 / 100 | 80 / 20 |
   | primary-container / on-primary-container | 90 / 10 | 30 / 90 |
   | surface / on-surface | 98 / 10 | 6 / 90 |
   | surface-variant / on-surface-variant | 90 / 30 | 30 / 80 |
   | outline / outline-variant | 50 / 80 | 60 / 30 |
   | error / on-error | 40 / 100 | 80 / 20 |

   相邻两档 tone 差 ≥ 40 时，正文对比度基本落在 4.5:1 以上；差 30 只能算合格的大字对比。

3. **动态取色必须带降级路径。** Android 12（API 31）才有壁纸取色，
   低版本或用户关闭「主题颜色」时要回落到种子色方案。
   Compose 里判断 `Build.VERSION.SDK_INT >= 31`，不要直接调 `dynamicLightColorScheme`。

4. **层级用 surface 容器角色表达，不要靠叠加阴影。**
   M3 更新后的规范给了 5 档容器色：
   `surface-container-lowest` → `low` → `container` → `high` → `highest`，
   它们之间的 tone 差是 4 左右（浅色下 100 / 96 / 94 / 92 / 90）。
   一个卡片浮起来，靠的是容器色 + 一层极浅阴影，不是 `box-shadow: 0 8px 24px`。

5. **形状走圆角刻度，不要随手写 10px。**
   刻度是 none 0 / xs 4 / s 8 / m 12 / l 16 / xl 28 / full 999。
   默认组件用哪一档：按钮 full、卡片 m(12)、对话框 xl(28)、FAB l(16)、
   底部抽屉 top l(16)、文本字段 xs(4)、chip s(8)。

6. **触摸目标最小 48×48dp**，视觉尺寸可以更小。
   Icon button 视觉 40×40，但热区必须撑到 48。
   这条是 Android 无障碍扫描的硬门槛，不达标会被标记。

7. **组件尺寸按官方数值来**，常见的一组：
   按钮高 40dp（密集场景 32，大按钮 48 用在大屏/主 CTA）、
   FAB 56dp（small 40、large 96、extended 高 56）、
   Navigation bar 高 80dp、Top app bar small 64 / medium 112 / large 152、
   Chip 高 32、Switch 轨道 52×32、Text field 高 56。
   随手写 44 或 60 会让整套组件看起来「哪里不对但说不上来」。

## 怎么做

### 1. 从种子色生成色调调板

Web / 跨端用 `@material/material-color-utilities`（官方维护的 TS 实现）：

```ts
import {
  argbFromHex, hexFromArgb,
  themeFromSourceColor, Hct, TonalPalette,
} from '@material/material-color-utilities'

// 方式一：只要一套完整 scheme
const theme = themeFromSourceColor(argbFromHex('#4C662B'))
const light = theme.schemes.light   // 含 primary / onPrimary / surfaceContainerHigh ...
const dark  = theme.schemes.dark

// 方式二：自己控制 chroma，做品牌色微调
const hct = Hct.fromInt(argbFromHex('#4C662B'))
const primary = TonalPalette.fromHueAndChroma(hct.hue, 36)
primary.tone(40)   // 浅色模式 primary
primary.tone(80)   // 深色模式 primary
```

各调板的默认 chroma（决定了「这个色有多艳」）：
primary 36、secondary 16、tertiary 24（hue 旋转 +60）、neutral 4、neutral-variant 8、error 60。
neutral 的 chroma 只有 4 —— 这就是为什么 M3 的灰面**永远带一点点主色味**，
手写 `#EEEEEE` 是纯灰，混进去一眼就假。

### 2. 接动态取色

Compose：

```kotlin
val colorScheme = when {
  Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> {
    if (dynamicColor) {
      if (darkTheme) dynamicDarkColorScheme(context)
      else dynamicLightColorScheme(context)
    } else fallbackScheme
  }
  else -> fallbackScheme
}
MaterialTheme(colorScheme = colorScheme, typography = AppTypography, shapes = AppShapes) { ... }
```

Web 上跟随壁纸取色做不到，退而求其次的做法是**从用户头像或上传的封面图取色**：

```ts
import { themeFromImage } from '@material/material-color-utilities'
const theme = await themeFromImage(imgElement)
```

再往下就是「用户手选一个品牌色」，用 `themeFromSourceColor` 生成整套。
三层降级顺序：壁纸 → 内容图 → 品牌种子色。

### 3. 用色调而非透明度做「禁用态」

M3 禁用态的规则是**固定透明度**，不是把颜色变灰：
内容 `on-surface` 38% alpha，容器 `on-surface` 12% alpha。
自己写 `color: #BDBDBD` 的问题是深色模式下这个灰会突然变得刺眼。
状态层（state layer）同理：hover 8%、focus 10%、pressed 10%、dragged 16%，
叠在内容色上，不是叠在容器色上。

### 4. 迁移 M2 → M3 的差异清单

| 维度 | M2 | M3 |
| --- | --- | --- |
| 字体命名 | h1–h6 / subtitle1-2 / body1-2 / button / caption / overline | display / headline / title / body / label，各 ×large/medium/small |
| 层级表达 | 纯阴影，6 档 elevation | 表面色调 + 浅阴影，0–5 档 |
| 默认圆角 | 4dp | 12dp（卡片），按钮全圆角 |
| 底部导航 | Bottom navigation 高 56dp | Navigation bar 高 80dp，带 active indicator 药丸 |
| 按钮高度 | 36dp | 40dp |
| FAB | 圆形 56dp | 圆角方形 r=16，56dp |
| 状态层 | 4% / 8% / 12% | 8% / 10% / 10% / 16% |
| 配色来源 | 1 个 primary + 1 个 secondary 手动配 | 种子色派生 6 组调板 ×13 tone |

迁移时**不要**逐个组件改，先换主题层（colorScheme / typography / shapes），
再跑一遍视觉回归，把「看起来变胖了」的组件单独修尺寸。

## 检查清单

- [ ] 全项目搜索 `#` 开头的十六进制颜色，除了种子色定义处，业务代码里应该为 0
- [ ] 深色模式下每个 surface 层级都能分辨（相邻容器色差 ≥ tone 4）
- [ ] 动态取色在 Android 11 及以下有降级，界面不崩不闪白
- [ ] 所有可点击元素热区 ≥ 48×48dp（用 Android 的「无障碍扫描」或 Flutter 的 `MaterialTapTargetSize` 校验）
- [ ] 正文对比度 ≥ 4.5:1，大字（≥18.66px bold 或 ≥24px）≥ 3:1
- [ ] 圆角只用刻度值：0 / 4 / 8 / 12 / 16 / 28 / full
- [ ] 按钮高度是 40 或 48，不是 44 / 50 / 56
- [ ] 禁用态用 38% / 12% 透明度，不是自定义灰色
- [ ] Top app bar 在滚动时切换的是容器色（`surface-container` ↔ `surface`），不是突然加深阴影

## 常见错误

| 错误做法 | 为什么错 | 正确做法 |
| --- | --- | --- |
| 手写 `#6750A4` 当 primary | 暗色模式下这个紫在白字上对比度不足，且完全无法跟随壁纸 | 从调板取 `primary.tone(40)` / `.tone(80)` |
| 用 `elevation` 阴影做层级 | M3 里阴影很弱，深色模式下几乎不可见，层级会塌掉 | 用 surface-container 五档容器色 |
| neutral 调板 chroma 设 0 | 灰面变纯灰，和彩色组件放一起显脏 | neutral chroma 4、neutral-variant 8 |
| 低版本 Android 直接调 `dynamicLightColorScheme` | API 31 以下无此能力，会回落或抛错 | 版本判断 + 种子色兜底 |
| 按钮写死 `height: 44px` | 不在规范刻度里，和系统组件并排时高度对不齐 | 40（默认）/ 32（密集）/ 48（大） |
| 禁用按钮把背景改成浅灰 | 深色模式下浅灰块比正常按钮还显眼 | 内容 38% alpha、容器 12% alpha |
| 迁移时把 h1–h6 直接映射到 displayLarge | 语义对不上，标题字号会突然暴涨 | h5/h6 → titleLarge/titleMedium，body1 → bodyLarge |
| 卡片圆角用 10px「看起来差不多」 | 与规范 12dp 的组件并排会出现 2px 错位，肉眼能看出来 | 严格用 12（m 档） |

## 参考

- 需要写完整的色调调板生成、对比度校验脚本，或要理解 HCT 为什么比 HSL 好用时，读 `references/hct-and-tonal-palette.md`
- 迁移老项目、需要逐组件对照表（含状态层、图标、对话框、Snackbar 差异）时，读 `references/m2-to-m3-migration.md`
$md$,
  '[{"path":"ATTRIBUTION.md","size":484,"kind":"text"},{"path":"LICENSE","size":1074,"kind":"text"},{"path":"SKILL.md","size":9154,"kind":"text"},{"path":"references/hct-and-tonal-palette.md","size":6163,"kind":"text"},{"path":"references/m2-to-m3-migration.md","size":6057,"kind":"text"}]'::jsonb, 5, 22932, 'a3e6d981c99426fbeacdcdb41ae006b7bb9e8a11326f7d18fe580945e276e8f9',
  $b64$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$b64$,
  'published'
)
on conflict do nothing;

insert into public.skills
  (slug, name, description, category, tags, version, license, author,
   readme, files, file_count, total_bytes, hash, bundle_b64, status)
values (
  'mobile-app-navigation', 'mobile-app-navigation', '设计移动应用的导航结构时使用：底部 Tab 取舍、抽屉与栈式导航、模态与全屏页、深层链接、返回手势与 Tab 内状态保持。', 'ui',
  array['APP 移动端', '底部 Tab', '栈式导航', '深层链接', '返回手势', '状态保持', '模态与全屏']::text[], '1.0.0', 'MIT', 'Skill Hub',
  $md$---
name: "mobile-app-navigation"
description: "设计移动应用的导航结构时使用：底部 Tab 取舍、抽屉与栈式导航、模态与全屏页、深层链接、返回手势与 Tab 内状态保持。"
version: "1.0.0"
license: "MIT"
author: "Skill Hub"
category: ui
tags: ["APP 移动端", "底部 Tab", "栈式导航", "深层链接", "返回手势", "状态保持", "模态与全屏"]
---

# 移动应用导航模式

移动端导航的核心矛盾是：**屏幕只有一屏大，但用户要能到达任意深度**。
每一次「多一层」都要付出返回成本，每一次「藏起来」都要付出发现成本。
下面的规则都是在两个成本之间取平衡。

## 何时使用

- 从零规划一个 App 的信息架构和导航骨架
- 用户反馈「找不到 XX 功能」「返回之后回到最上面了」「不知道自己在哪」
- 要在 Tab 和抽屉之间做取舍，或纠结某个页面该不该做成模态
- 接深层链接（分享链接、推送跳转、扫码）需要设计路由结构

## 核心规则

1. **底部 Tab 数量 3–5 个，5 是硬上限。**
   原因是每个 Tab 的宽度：375pt 宽的屏去掉左右各 16pt 边距，5 个 Tab 每个只有 68pt，
   刚好放得下 24pt 图标 + 11pt 文字。到 6 个就只剩 57pt，文字必须截断或缩写，
   识别速度断崖式下降。**3 个以下不要用 Tab**，直接用分段控件或页面内导航更省空间。

2. **Tab 必须有文字标签，不能只有图标。**
   纯图标的 Tab 在用户第一次见时的猜中率大约一半（尤其「钱包 / 卡包 / 收藏」这类抽象图标）。
   空间不够就缩字号到 10–11pt，不要去掉文字。

3. **Tab 尺寸与安全区：**
   iOS Tab bar 内容区高 49pt + 底部安全区 34pt = 83pt；
   Android M3 NavigationBar 高 80dp（M2 是 56dp）；
   图标 24–28pt，标签 10–12pt；
   每个 Tab 的点击热区最小 44×44pt（iOS）/ 48×48dp（Android），
   所以 Tab 宽度**不能小于 64pt**，否则热区会互相挤。

4. **一个 Tab 一个独立导航栈。** 在「首页 Tab」里点进详情，切到「我的 Tab」再切回来，
   必须还停在详情页，滚动位置也要保留。
   全局单一栈的实现（所有 Tab 共用一个 stack）会导致切 Tab 时栈被重置，
   这是最常见的「返回之后回到最上面」的根因。

5. **栈深度控制在 4 层以内**（Tab 根算第 1 层）。
   超过 4 层说明层级该被扁平化，或者某段该改成模态。
   实际数据显示 5 层以上的栈，用户主动返回的比例显著下降 —— 他们会直接杀掉 App。

6. **模态（modal）用于「有明确终点的独立任务」**，全屏页（push）用于「内容浏览」。
   判断标准：这个页面做完之后是不是要「回到出发的地方」？是 → 模态；
   这个页面本身是内容的一部分、用户可能继续往下走 → push。
   登录、新建、编辑、支付、图片查看 = 模态；商品详情、文章、设置 = push。

7. **返回手势必须能预测。** Android 14 起有预测性返回（predictive back），
   需要在 manifest 里开 `android:enableOnBackInvokedCallback="true"`；
   iOS 的左侧边缘滑动返回默认存在，**左边缘 20pt 内不能放横向滚动的轮播**，
   否则两个手势会打架，表现为「想滑动轮播结果退出了页面」。

8. **抽屉（Drawer）只在 Tab 装不下、且存在 ≥ 7 个一级入口时使用。**
   抽屉的可发现性差（用户平均只有约 30% 会主动点开汉堡菜单），
   而且和 iOS 的边缘返回手势冲突（都是从左边缘滑出）。
   用抽屉就必然要接受「很多用户永远看不到里面的功能」。

## 怎么做

### 1. 先定信息架构，再选导航容器

按一级入口数量选：

| 一级入口数 | 推荐容器 | 理由 |
| --- | --- | --- |
| 2–3 | 分段控件 / 顶部 Tab / 页面内切换 | Tab bar 浪费 83pt 高度 |
| 3–5 | 底部 Tab bar | 最佳区间，可发现性最高 |
| 6–7 | 底部 Tab（挑最常用的 5 个）+ 其余进「更多」 | 折中 |
| ≥ 8 | 抽屉 或 首页宫格 | Tab 无法承载 |

选择时优先砍功能，而不是加容器。把 8 个入口硬塞进 5 个 Tab 的「更多」里，
等于这 3 个功能被隐藏了两次。

### 2. 路由结构（以 React Navigation / Expo Router 为例）

```ts
// 每个 Tab 是独立的 Stack，这是状态保持的关键
const Tab = createBottomTabNavigator()
const HomeStack = createNativeStackNavigator()
const MeStack = createNativeStackNavigator()

function HomeNavigator() {
  return (
    <HomeStack.Navigator screenOptions={{ headerShown: false }}>
      <HomeStack.Screen name="HomeFeed" component={FeedScreen} />
      <HomeStack.Screen name="Detail" component={DetailScreen} />
    </HomeStack.Navigator>
  )
}

export default function RootTabs() {
  return (
    <Tab.Navigator
      screenOptions={{
        tabBarLabelStyle: { fontSize: 11 },
        tabBarStyle: { height: 49 + insets.bottom },
        tabBarHideOnKeyboard: true,   // 键盘弹出时收起 Tab bar，避免和输入法叠在一起
      }}
    >
      <Tab.Screen name="HomeTab" component={HomeNavigator} options={{ title: '首页' }} />
      <Tab.Screen name="MeTab"   component={MeNavigator}   options={{ title: '我的' }} />
    </Tab.Navigator>
  )
}
```

Android Compose 用 `NavigationBar` + 每个 Tab 一个 `NavHost`，
Flutter 用 `go_router` 的 `StatefulShellRoute`，思路完全一致：**栈是 Tab 的子节点，不是兄弟**。

### 3. Tab bar 什么时候该隐藏

- **push 到二级页时保留 Tab bar**（iOS 惯例）。隐藏会让用户失去「我在哪个 Tab 里」的锚点，
  并且返回后 Tab bar 重新出现的动画会闪。
- **模态全屏页隐藏**，因为模态是脱离当前上下文的独立任务。
- **键盘弹出时隐藏**（`tabBarHideOnKeyboard`），否则输入框和 Tab bar 会叠。
- **沉浸式内容页隐藏**（视频播放、图片全屏、地图），并配合状态栏隐藏。

例外：短视频类 App 的 Tab bar 常驻，因为「刷」本身不需要返回。

### 4. 模态的尺寸与关闭方式

- **Bottom sheet 两档：半屏 50%、全屏 90%。** 半屏档用于「看一眼就走」，
  比如评论列表、选择器。iOS 用 `presentationDetents={[0.5, 0.9]}`。
- **模态必须提供三种关闭方式中的至少两种**：显式关闭按钮（左上角 × 或右上角「取消」）、
  下滑手势、物理返回键（Android）。
  只有下滑手势是不够的 —— 手上有水、戴手套、或屏幕上有横向滚动区域时下滑会失败。
- **模态内如果有未保存内容，关闭时二次确认**，文案要说明后果（「放弃编辑？」而不是「确定吗？」）。
- **模态的高度不要超过 90%**，顶部留一点露出下面的页面，用户才知道「这是个可以关掉的东西」。

### 5. 返回键与手势

Android：
```xml
<application android:enableOnBackInvokedCallback="true">
```
开启后，返回手势会在手指滑动过程中实时把当前页面缩小并露出上一页（预测性返回）。
如果某个页面不该被返回（比如支付进行中），用 `OnBackPressedCallback` 拦截并给提示，
**不要**用「按两次退出」这种隐式行为。

iOS：
- 左侧边缘右滑 = 返回上一页，热区约屏幕左侧 20pt 内
- 右滑手势在栈底无效（栈里只有一层时不应该有手势）
- 自定义返回按钮时，必须保留 `interactivePopGestureRecognizer`，
  否则手势会失效 —— 这是 React Navigation / SwiftUI 里最常被搞坏的一处

### 6. Tab 内嵌栈的状态保持

要做到「切回来还在原地」，需要三件事同时成立：

1. **导航栈本身不销毁**：Tab 切换时用 `unmountOnBlur: false`（React Navigation）
   或 `AutomaticKeepAliveClientMixin`（Flutter），不要让 Tab 卸载重建。
2. **滚动位置要单独存**：栈保住了不代表滚动位置保住了。
   列表页在 `blur` 时把 `scrollY` 存进 store，`focus` 时恢复。
   iOS 的 `UITableView` 会自动保，`FlatList` / `RecyclerView` 不一定。
3. **表单草稿要存**：用户在「新建」页填了一半切走，回来必须还在。
   存内存就够（进程被杀就丢，可接受），但至少要撑住一次 Tab 切换。

代价：所有 Tab 都常驻内存，低端机上内存占用会明显上升。
Tab 数 ≥ 4 且每个 Tab 都有重列表时，考虑只保栈、不保列表数据（回来时重新请求 + 恢复滚动位置）。

### 7. 深层链接

路径设计规则：
- 路径即层级，`/orders/123` 而不是 `/order_detail?id=123`
- **每一级都要能独立打开**：`/orders/123` 能开，`/orders` 也必须能开
- 未登录时不能直接跳目标页，要先存下目标路径，登录成功后 replace 过去（**不要 push**，
  否则返回时会回到登录页）
- App 没装时回落网页版，网页版顶部给「打开 App」banner

细节（Universal Link / App Link 配置、延迟深链、扫码场景）见 `references/deep-linking.md`。

## 检查清单

- [ ] Tab 数量 3–5 个，每个宽度 ≥ 64pt
- [ ] 每个 Tab 都有文字标签，字号 ≥ 10pt
- [ ] 底部安全区处理正确（iPhone 全面屏不遮挡，Android 手势条不遮挡）
- [ ] 切换 Tab 再切回，二级页面和滚动位置都还在
- [ ] 任意页面的栈深度 ≤ 4 层
- [ ] 所有模态都能用「按钮」关闭，不只靠手势
- [ ] Android 开启预测性返回，且支付/上传等关键流程有返回拦截
- [ ] iOS 自定义返回按钮后，边缘滑动返回仍然可用
- [ ] 左边缘 20pt 内没有横向滚动手势冲突
- [ ] 键盘弹出时 Tab bar 收起，输入框不被遮挡
- [ ] 冷启动走深层链接能直达目标页，未登录时登录后 replace 而非 push
- [ ] 系统「大字体」设置下 Tab 标签不换行、不截断

## 常见错误

| 错误做法 | 为什么错 | 正确做法 |
| --- | --- | --- |
| 全局单一导航栈 | 切 Tab 时栈被重置，用户回到根页并丢失滚动位置 | 每个 Tab 一个独立 Stack |
| 6 个 Tab | 每格宽度 < 60pt，文字截断、误触率上升 | 砍到 5 个，其余进「更多」 |
| 抽屉里放核心功能 | 汉堡菜单打开率低，功能等于被隐藏 | 核心功能进 Tab，抽屉只放设置类 |
| 只有下滑手势能关模态 | 手湿、戴手套、页面内有横滑时关不掉 | 补一个显式关闭按钮 |
| 登录后 push 目标页 | 返回键回到登录页，用户会再次触发登录 | 用 replace |
| 栈深度 7 层 | 用户迷失，返回成本高于重新进入 | 扁平化，或中间层改模态 |
| 模态高度 100% | 和全屏页没区别，用户不知道能不能关 | 上限 90%，顶部露出下层 |
| Tab 切换用 unmount 省内存 | 回来时列表重建，滚动位置丢失 | 保栈，必要时只清数据不清栈 |
| 左边缘放轮播图 | 横滑被系统返回手势抢走，用户以为卡了 | 轮播左侧留 20pt 手势死区或右移 |
| Android 用「按两次退出」 | 隐式行为，用户不知道要按第二次 | 明确弹「再按一次退出」或直接退出 |

## 参考

- 要接 Universal Link / App Link、处理延迟深链、扫码和推送跳转时，读 `references/deep-linking.md`
$md$,
  '[{"path":"ATTRIBUTION.md","size":484,"kind":"text"},{"path":"LICENSE","size":1074,"kind":"text"},{"path":"SKILL.md","size":11406,"kind":"text"},{"path":"references/deep-linking.md","size":6956,"kind":"text"}]'::jsonb, 4, 19920, '32abc557817240f8de47e0adcf65fe9a754db65cec5fdc2128290760bd90f5a1',
  $b64$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$b64$,
  'published'
)
on conflict do nothing;

insert into public.skills
  (slug, name, description, category, tags, version, license, author,
   readme, files, file_count, total_bytes, hash, bundle_b64, status)
values (
  'mobile-onboarding', 'mobile-onboarding', '设计移动端首次启动引导、权限申请时机和各类空状态时使用，避免一上来就弹权限、用引导页堵住用户。', 'ui',
  array['APP 移动端', '首启引导', '权限时机', '空状态文案', '通知权限', '用户回流', '激活率']::text[], '1.0.0', 'MIT', 'Skill Hub',
  $md$---
name: "mobile-onboarding"
description: "设计移动端首次启动引导、权限申请时机和各类空状态时使用，避免一上来就弹权限、用引导页堵住用户。"
version: "1.0.0"
license: "MIT"
author: "Skill Hub"
category: ui
tags: ["APP 移动端", "首启引导", "权限时机", "空状态文案", "通知权限", "用户回流", "激活率"]
---

# 移动端引导与空状态

引导和空状态是同一件事的两面：**都在用户「还没有内容」的时刻和他说话**。
判断标准只有一个 —— 这段内容有没有帮用户更快拿到他想要的东西。
帮不到就是在收过路费。

## 何时使用

- 做新 App 的首启流程，纠结放几页引导、要不要放
- 通知权限、定位权限、相机权限不知道什么时候弹
- 列表为空、搜索无结果、网络出错时的页面不知道怎么写
- 老用户升级后要不要再展示一次新功能说明

## 核心规则

1. **引导页最多 3 页，硬上限 5 页。**
   超过 3 页，第 4 页之后的到达率会掉到 30% 以下（大部分用户在这之前就点了跳过或直接划掉）。
   3 页能讲清楚的事，通常 1 页也能讲清楚 —— 先试着压到 1 页。
   每页文案：标题 ≤ 12 个汉字，说明 ≤ 30 个汉字。超了就没人读。

2. **「跳过」必须在第 1 页就可见**，放在右上角，热区 ≥ 44×44pt。
   把跳过藏到最后一页、或者做成一个灰色小字，用户的第一反应是卸载而不是找。
   最后一页的按钮文案写「开始使用」，不要写「完成」或「下一步」。

3. **引导页只在「产品价值不可见」时才需要。**
   判断：用户打开 App 的第一屏能不能直接看到核心价值？
   - 能（信息流、地图、相机取景）→ **不要引导**，直接进主界面
   - 不能（需要先建项目、先导入数据、先配对硬件）→ 用引导，但优先考虑
     「把引导做成第一个可操作的任务」而不是轮播图

4. **绝对不要在第一屏弹通知权限。**
   iOS 的通知权限**一辈子只能弹一次**（用户拒绝后只能去系统设置里改），
   首启就弹的同意率通常在 30–45%；在用户完成第一个有价值动作之后弹，能到 60–75%。
   正确时机：用户创建了第一条提醒 / 关注了第一个内容源 / 发布第一条内容之后，
   在他**刚刚获得价值、预期还会再来**的那一刻。

5. **权限必须「先解释，再弹系统框」。**
   系统弹窗的文案你改不了（iOS 里只能通过 Info.plist 的 `NS*UsageDescription` 间接影响），
   所以要在系统框之前先给一个自定义的说明层：
   标题一行说清「为什么要」，正文 ≤ 2 行，两个按钮「以后再说」/「好的」。
   用户点「好的」才真正触发系统权限请求。
   点「以后再说」时**不要再弹**，等下一个自然时机。

6. **权限被拒后不要反复弹。**
   系统权限只能请求一次（Android 从 API 30 起，用户拒绝两次后系统直接静默拒绝）。
   被拒后的正确做法是：功能降级 + 在该功能入口处放一行「开启通知提醒」，点了跳系统设置。

7. **空状态必须区分 5 种，文案完全不同。**
   用同一张插图和同一句「暂无数据」是典型偷懒：
   首次为空（要引导行动）、用户清空（要肯定 + 快速恢复）、
   搜索无结果（要修正建议）、出错（要重试）、无权限（要申请入口）。

8. **首次使用和老用户回流走两条完全不同的路径。**
   老用户（本地有数据或账号有历史）**永远不要**再看首启引导 ——
   那是惩罚忠诚用户。老用户的正确做法是「新功能提示」：
   在功能入口处放一个小红点，点进去有一次性的说明浮层。

## 怎么做

### 1. 首启决策树

```
App 启动
├─ 本地有 userHasOnboarded 标记 或 账号有历史数据
│   ├─ 版本有重大新功能 → 在入口处打红点（不弹窗）
│   └─ 否则 → 直接进主界面
└─ 全新用户
    ├─ 从分享链接 / 邀请码进入 → 跳过引导，直接进落地页（他已经在情境里了）
    ├─ 从广告进入 → 最多 1 页价值说明，然后立刻进主界面
    └─ 自然安装
        ├─ 第一屏能看到价值 → 无引导
        └─ 看不到价值 → 引导 ≤ 3 页，且引导完直接落到「创建第一个 X」
```

关键点：**引导结束的落点必须是可操作的界面，不是主界面的空列表。**
引导页讲了 3 页，最后把用户丢进一个空列表，等于前面的投入全废。

### 2. 引导页的两种形态

| 形态 | 适合 | 实现 |
| --- | --- | --- |
| 轮播页（Pager） | 产品概念需要图示，无法在界面上演示 | 3 页以内 + 页码点 + 跳过 |
| 可操作引导（Coach mark / 任务流） | 功能可以在界面上直接演示 | 高亮 + 气泡，用户边做边学 |

**可操作引导优于轮播页**，因为用户看完轮播记住的是「我看过」，看完操作记住的是「我会用」。
轮播页的唯一优势是可以在权限请求前做铺垫。

### 3. 权限时机对照表

| 权限 | 什么时候请求 | 不要什么时候请求 |
| --- | --- | --- |
| 通知 | 用户创建了第一条提醒/关注后 | 首启、登录成功后立刻 |
| 定位（使用期间） | 用户点「附近的 X」「自动填充地址」时 | 首启、首页加载时 |
| 定位（始终） | 用户开启「后台记录轨迹」时，且先要过「使用期间」 | 首次要定位时直接要「始终」 |
| 相机 | 用户点扫码 / 拍照按钮时 | 首启 |
| 相册（读） | 用户点「选择图片」时 | 首启 |
| 相册（写） | 用户点「保存到相册」时 | 首启 |
| 麦克风 | 用户点语音输入 / 录音时 | 首启 |
| 通讯录 | 用户点「邀请好友」时，且要说明用途 | 首启 |
| 追踪（ATT） | 有明确广告归因需求时，且要说明能换来什么 | 首启 |

共同规则：**权限的请求点 = 使用点**。用户在哪一刻需要它，就在哪一刻问。
这条规则能解决 90% 的权限问题。

### 4. 预请求弹层的写法

```
┌──────────────────────────────┐
│  [图标]                       │
│  开启通知，别错过日程提醒      │  ← 标题：说「能得到什么」
│  我们会在事项开始前 15 分钟    │  ← 正文：≤ 2 行，说具体
│  提醒你。                      │
│                              │
│  [ 以后再说 ]  [ 开启通知 ]    │  ← 主按钮用动词，不用「确定」
└──────────────────────────────┘
```

反例：「为了给您更好的体验，请允许通知权限」—— 没有信息量，
用户不知道开了之后会收到什么，拒绝率极高。

### 5. 空状态的通用结构

从上到下四层，缺一不可：

1. **图形**（120–200pt 的插画或图标）：传达情绪，不要用巨大的灰色齿轮
2. **标题**（≤ 12 字）：一句话说清「为什么是空的」
3. **说明**（≤ 40 字，可省）：告诉用户下一步做什么，或这个功能是干嘛的
4. **主操作**（1 个主按钮 + 最多 1 个次级链接）：唯一清晰的下一步

垂直居中于内容区（不是整屏），图形底部距标题 24–32pt。
**不要**用全屏的「暂无数据」加一个和顶部导航重复的按钮。

五种空状态的写法见 `references/empty-states.md`。

### 6. 回流用户的处理

- **版本更新后不要弹「新功能」全屏页**。用户点开 App 是想用，不是想读更新日志。
  改成：功能入口处一个 6pt 红点，点进去一次性的浮层说明（同一功能只显示一次）。
- **超过 30 天未登录的用户**，登录后可以在首页顶部放一条可关闭的引导条，
  说明这期间的变化（「新增了自动分类」），**必须可关闭**，关闭后不再出现。
- **不要重置引导标记**。清除缓存、切换账号以外的任何操作都不该让老用户重新看引导。
  唯一例外：账号切换到了另一个从未用过的新账号。

### 7. 骨架屏与加载态的边界

- 请求发出后 **200ms 内**如果没返回，才显示骨架屏。太快显示会闪一下，反而更慢的感觉。
- 骨架屏超过 **10 秒**没结果，切换成「加载失败，重试」而不是一直转圈。
- 下拉刷新时**不要**显示骨架屏，用系统自带的 spinner，否则列表会跳。
- 空状态和加载态不能同时出现。加载中显示骨架屏，加载完为空才显示空状态。

## 检查清单

- [ ] 引导页 ≤ 3 页，每页标题 ≤ 12 字
- [ ] 第 1 页就有可见的「跳过」
- [ ] 引导结束后直接落到可操作界面，不是空列表
- [ ] 老用户（有数据/有历史）不会看到首启引导
- [ ] 没有任何权限在首启时被请求
- [ ] 每个权限的请求点都在它的使用点（点扫码才问相机）
- [ ] 每个权限都有自定义预请求说明层，且「以后再说」后不再重复弹
- [ ] 权限被拒后功能降级可用，且入口处有跳系统设置的路径
- [ ] 五类空状态（首启/清空/无结果/出错/无权限）文案各不相同
- [ ] 每个空状态只有一个主按钮
- [ ] 骨架屏延迟 200ms 出现，10s 后转为失败态
- [ ] 空状态插画在深色模式下不发白、不刺眼
- [ ] 大字体模式下空状态文字不溢出容器
- [ ] 引导页文案在 320pt 宽的小屏上不截断

## 常见错误

| 错误做法 | 为什么错 | 正确做法 |
| --- | --- | --- |
| 首启就弹通知权限 | iOS 只有一次机会，首启同意率仅 30–45% | 等用户完成第一个有价值动作后再问 |
| 引导做 6 页轮播 | 第 4 页起到达率 < 30%，用户直接划掉 | 压到 3 页内，或改可操作引导 |
| 跳过按钮藏在最后一页 | 用户找不到出口，第一反应是卸载 | 第 1 页右上角就放 |
| 引导完把用户丢进空列表 | 前面的铺垫白做，用户不知道怎么开始 | 引导完直接进「创建第一个 X」 |
| 所有空状态都用「暂无数据」 | 用户分不清是自己没建、搜错了还是出错了 | 按五类分别写 |
| 老用户升级后重放引导 | 惩罚忠诚用户，且浪费他的时间 | 用入口红点 + 一次性浮层 |
| 权限被拒后每次进页面都弹 | Android 静默拒绝，iOS 根本弹不出来，用户只会烦 | 降级 + 入口引导去设置 |
| 空状态放两个同等权重的按钮 | 用户选不出来，转化率反而低于单个按钮 | 一个主按钮，次要操作降级为文字链接 |
| 骨架屏一发出请求就显示 | 快速返回时闪一下，感知比真实耗时更长 | 延迟 200ms |
| 预请求文案写「为了更好的体验」 | 没有信息量，拒绝率高 | 说清「开了之后你会得到什么」 |

## 参考

- 写空状态文案、需要五类空状态的完整模板和示例时，读 `references/empty-states.md`
$md$,
  '[{"path":"ATTRIBUTION.md","size":484,"kind":"text"},{"path":"LICENSE","size":1074,"kind":"text"},{"path":"SKILL.md","size":11217,"kind":"text"},{"path":"references/empty-states.md","size":6127,"kind":"text"}]'::jsonb, 4, 18902, '40838ce6c2d91c9d3ac64b3eae810bd5795b5cafb74009076736057c192231c1',
  $b64$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$b64$,
  'published'
)
on conflict do nothing;
