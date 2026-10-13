-- ============================================================================
-- UI 技能包入库 · 业务场景（6 个）
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
  'ux-researcher-designer', 'ux-researcher-designer', 'UX 研究与设计工具箱：从研究数据生成人物画像、绘制用户旅程图、规划可用性测试，并把结论整理成可执行的设计建议。', 'ui',
  array['UX', '用户研究', '人物画像', '旅程图', '可用性测试', '访谈', '设计建议']::text[], '1.0.0', 'MIT', 'Alireza Rezvani',
  $md$---
name: "ux-researcher-designer"
description: "UX 研究与设计工具箱：从研究数据生成人物画像、绘制用户旅程图、规划可用性测试，并把结论整理成可执行的设计建议。"
version: "1.0.0"
license: "MIT"
author: "Alireza Rezvani"
category: ui
tags: ["UX", "用户研究", "人物画像", "旅程图", "可用性测试", "访谈", "设计建议"]
---

# UX Researcher & Designer

Generate user personas from research data, create journey maps, plan usability tests, and synthesize research findings into actionable design recommendations.

---

## Table of Contents

- [Trigger Terms](#trigger-terms)
- [Workflows](#workflows)
  - [Workflow 1: Generate User Persona](#workflow-1-generate-user-persona)
  - [Workflow 2: Create Journey Map](#workflow-2-create-journey-map)
  - [Workflow 3: Plan Usability Test](#workflow-3-plan-usability-test)
  - [Workflow 4: Synthesize Research](#workflow-4-synthesize-research)
- [Tool Reference](#tool-reference)
- [Quick Reference Tables](#quick-reference-tables)
- [Knowledge Base](#knowledge-base)

---

## Trigger Terms

Use this skill when you need to:

- "create user persona"
- "generate persona from data"
- "build customer journey map"
- "map user journey"
- "plan usability test"
- "design usability study"
- "analyze user research"
- "synthesize interview findings"
- "identify user pain points"
- "define user archetypes"
- "calculate research sample size"
- "create empathy map"
- "identify user needs"

---

## Workflows

### Workflow 1: Generate User Persona

**Situation:** You have user data (analytics, surveys, interviews) and need to create a research-backed persona.

**Steps:**

1. **Prepare user data**

   Required format (JSON):
   ```json
   [
     {
       "user_id": "user_1",
       "age": 32,
       "usage_frequency": "daily",
       "features_used": ["dashboard", "reports", "export"],
       "primary_device": "desktop",
       "usage_context": "work",
       "tech_proficiency": 7,
       "pain_points": ["slow loading", "confusing UI"]
     }
   ]
   ```

2. **Run persona generator**
   ```bash
   # Human-readable output
   python scripts/persona_generator.py

   # JSON output for integration
   python scripts/persona_generator.py json
   ```

3. **Review generated components**

   | Component | What to Check |
   |-----------|---------------|
   | Archetype | Does it match the data patterns? |
   | Demographics | Are they derived from actual data? |
   | Goals | Are they specific and actionable? |
   | Frustrations | Do they include frequency counts? |
   | Design implications | Can designers act on these? |

4. **Validate persona**

   - Show to 3-5 real users: "Does this sound like you?"
   - Cross-check with support tickets
   - Verify against analytics data

5. **Reference:** See `references/persona-methodology.md` for validity criteria

---

### Workflow 2: Create Journey Map

**Situation:** You need to visualize the end-to-end user experience for a specific goal.

**Steps:**

1. **Define scope**

   | Element | Description |
   |---------|-------------|
   | Persona | Which user type |
   | Goal | What they're trying to achieve |
   | Start | Trigger that begins journey |
   | End | Success criteria |
   | Timeframe | Hours/days/weeks |

2. **Gather journey data**

   Sources:
   - User interviews (ask "walk me through...")
   - Session recordings
   - Analytics (funnel, drop-offs)
   - Support tickets

3. **Map the stages**

   Typical B2B SaaS stages:
   ```
   Awareness → Evaluation → Onboarding → Adoption → Advocacy
   ```

4. **Fill in layers for each stage**

   ```
   Stage: [Name]
   ├── Actions: What does user do?
   ├── Touchpoints: Where do they interact?
   ├── Emotions: How do they feel? (1-5)
   ├── Pain Points: What frustrates them?
   └── Opportunities: Where can we improve?
   ```

5. **Identify opportunities**

   Priority Score = Frequency × Severity × Solvability

6. **Reference:** See `references/journey-mapping-guide.md` for templates

---

### Workflow 3: Plan Usability Test

**Situation:** You need to validate a design with real users.

**Steps:**

1. **Define research questions**

   Transform vague goals into testable questions:

   | Vague | Testable |
   |-------|----------|
   | "Is it easy to use?" | "Can users complete checkout in <3 min?" |
   | "Do users like it?" | "Will users choose Design A or B?" |
   | "Does it make sense?" | "Can users find settings without hints?" |

2. **Select method**

   | Method | Participants | Duration | Best For |
   |--------|--------------|----------|----------|
   | Moderated remote | 5-8 | 45-60 min | Deep insights |
   | Unmoderated remote | 10-20 | 15-20 min | Quick validation |
   | Guerrilla | 3-5 | 5-10 min | Rapid feedback |

3. **Design tasks**

   Good task format:
   ```
   SCENARIO: "Imagine you're planning a trip to Paris..."
   GOAL: "Book a hotel for 3 nights in your budget."
   SUCCESS: "You see the confirmation page."
   ```

   Task progression: Warm-up → Core → Secondary → Edge case → Free exploration

4. **Define success metrics**

   | Metric | Target |
   |--------|--------|
   | Completion rate | >80% |
   | Time on task | <2× expected |
   | Error rate | <15% |
   | Satisfaction | >4/5 |

5. **Prepare moderator guide**

   - Think-aloud instructions
   - Non-leading prompts
   - Post-task questions

6. **Reference:** See `references/usability-testing-frameworks.md` for full guide

---

### Workflow 4: Synthesize Research

**Situation:** You have raw research data (interviews, surveys, observations) and need actionable insights.

**Steps:**

1. **Code the data**

   Tag each data point:
   - `[GOAL]` - What they want to achieve
   - `[PAIN]` - What frustrates them
   - `[BEHAVIOR]` - What they actually do
   - `[CONTEXT]` - When/where they use product
   - `[QUOTE]` - Direct user words

2. **Cluster similar patterns**

   ```
   User A: Uses daily, advanced features, shortcuts
   User B: Uses daily, complex workflows, automation
   User C: Uses weekly, basic needs, occasional

   Cluster 1: A, B (Power Users)
   Cluster 2: C (Casual User)
   ```

3. **Calculate segment sizes**

   | Cluster | Users | % | Viability |
   |---------|-------|---|-----------|
   | Power Users | 18 | 36% | Primary persona |
   | Business Users | 15 | 30% | Primary persona |
   | Casual Users | 12 | 24% | Secondary persona |

4. **Extract key findings**

   For each theme:
   - Finding statement
   - Supporting evidence (quotes, data)
   - Frequency (X/Y participants)
   - Business impact
   - Recommendation

5. **Prioritize opportunities**

   | Factor | Score 1-5 |
   |--------|-----------|
   | Frequency | How often does this occur? |
   | Severity | How much does it hurt? |
   | Breadth | How many users affected? |
   | Solvability | Can we fix this? |

6. **Reference:** See `references/persona-methodology.md` for analysis framework

---

## Tool Reference

### persona_generator.py

Generates data-driven personas from user research data.

| Argument | Values | Default | Description |
|----------|--------|---------|-------------|
| format | (none), json | (none) | Output format |

**Sample Output:**

```
============================================================
PERSONA: Alex the Power User
============================================================

📝 A daily user who primarily uses the product for work purposes

Archetype: Power User
Quote: "I need tools that can keep up with my workflow"

👤 Demographics:
  • Age Range: 25-34
  • Location Type: Urban
  • Tech Proficiency: Advanced

🎯 Goals & Needs:
  • Complete tasks efficiently
  • Automate workflows
  • Access advanced features

😤 Frustrations:
  • Slow loading times (14/20 users)
  • No keyboard shortcuts
  • Limited API access

💡 Design Implications:
  → Optimize for speed and efficiency
  → Provide keyboard shortcuts and power features
  → Expose API and automation capabilities

📈 Data: Based on 45 users
    Confidence: High
```

**Archetypes Generated:**

| Archetype | Signals | Design Focus |
|-----------|---------|--------------|
| power_user | Daily use, 10+ features | Efficiency, customization |
| casual_user | Weekly use, 3-5 features | Simplicity, guidance |
| business_user | Work context, team use | Collaboration, reporting |
| mobile_first | Mobile primary | Touch, offline, speed |

**Output Components:**

| Component | Description |
|-----------|-------------|
| demographics | Age range, location, occupation, tech level |
| psychographics | Motivations, values, attitudes, lifestyle |
| behaviors | Usage patterns, feature preferences |
| needs_and_goals | Primary, secondary, functional, emotional |
| frustrations | Pain points with evidence |
| scenarios | Contextual usage stories |
| design_implications | Actionable recommendations |
| data_points | Sample size, confidence level |

---

## Quick Reference Tables

### Research Method Selection

| Question Type | Best Method | Sample Size |
|---------------|-------------|-------------|
| "What do users do?" | Analytics, observation | 100+ events |
| "Why do they do it?" | Interviews | 8-15 users |
| "How well can they do it?" | Usability test | 5-8 users |
| "What do they prefer?" | Survey, A/B test | 50+ users |
| "What do they feel?" | Diary study, interviews | 10-15 users |

### Persona Confidence Levels

| Sample Size | Confidence | Use Case |
|-------------|------------|----------|
| 5-10 users | Low | Exploratory |
| 11-30 users | Medium | Directional |
| 31+ users | High | Production |

### Usability Issue Severity

| Severity | Definition | Action |
|----------|------------|--------|
| 4 - Critical | Prevents task completion | Fix immediately |
| 3 - Major | Significant difficulty | Fix before release |
| 2 - Minor | Causes hesitation | Fix when possible |
| 1 - Cosmetic | Noticed but not problematic | Low priority |

### Interview Question Types

| Type | Example | Use For |
|------|---------|---------|
| Context | "Walk me through your typical day" | Understanding environment |
| Behavior | "Show me how you do X" | Observing actual actions |
| Goals | "What are you trying to achieve?" | Uncovering motivations |
| Pain | "What's the hardest part?" | Identifying frustrations |
| Reflection | "What would you change?" | Generating ideas |

---

## Knowledge Base

Detailed reference guides in `references/`:

| File | Content |
|------|---------|
| `persona-methodology.md` | Validity criteria, data collection, analysis framework |
| `journey-mapping-guide.md` | Mapping process, templates, opportunity identification |
| `example-personas.md` | 3 complete persona examples with data |
| `usability-testing-frameworks.md` | Test planning, task design, analysis |

---

## Validation Checklist

### Persona Quality
- [ ] Based on 20+ users (minimum)
- [ ] At least 2 data sources (quant + qual)
- [ ] Specific, actionable goals
- [ ] Frustrations include frequency counts
- [ ] Design implications are specific
- [ ] Confidence level stated

### Journey Map Quality
- [ ] Scope clearly defined (persona, goal, timeframe)
- [ ] Based on real user data, not assumptions
- [ ] All layers filled (actions, touchpoints, emotions)
- [ ] Pain points identified per stage
- [ ] Opportunities prioritized

### Usability Test Quality
- [ ] Research questions are testable
- [ ] Tasks are realistic scenarios, not instructions
- [ ] 5+ participants per design
- [ ] Success metrics defined
- [ ] Findings include severity ratings

### Research Synthesis Quality
- [ ] Data coded consistently
- [ ] Patterns based on 3+ data points
- [ ] Findings include evidence
- [ ] Recommendations are actionable
- [ ] Priorities justified

## Related Skills

- **UI Design System** (`product-team/ui-design-system/`) — Research findings inform design system decisions
- **Product Manager Toolkit** (`product-team/product-manager-toolkit/`) — Customer interview analysis complements persona research
$md$,
  '[{"path":"ATTRIBUTION.md","size":971,"kind":"text"},{"path":"LICENSE","size":1072,"kind":"text"},{"path":"SKILL.md","size":12042,"kind":"text"},{"path":"assets/research_plan_template.md","size":4802,"kind":"text"},{"path":"references/example-personas.md","size":11990,"kind":"text"},{"path":"references/journey-mapping-guide.md","size":18102,"kind":"text"},{"path":"references/persona-methodology.md","size":11644,"kind":"text"},{"path":"references/usability-testing-frameworks.md","size":11932,"kind":"text"},{"path":"scripts/persona_generator.py","size":24561,"kind":"text"}]'::jsonb, 9, 97116, '61a5b2680fae4fdcf04142b3b29dcc62386f9c85c1d2d728614f83c82bb6003a',
  $b64$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$b64$,
  'published'
)
on conflict do nothing;

insert into public.skills
  (slug, name, description, category, tags, version, license, author,
   readme, files, file_count, total_bytes, hash, bundle_b64, status)
values (
  'site-architecture', 'site-architecture', '网站信息架构设计：URL 层级、导航与面包屑、内链策略、主题集群与孤岛页面排查，用于定位「根因在结构」的 SEO 问题。', 'ui',
  array['信息架构', 'URL层级', '导航', '内链', 'SEO', '面包屑', '站点结构']::text[], '1.0.0', 'MIT', 'Alireza Rezvani',
  $md$---
name: "site-architecture"
description: "网站信息架构设计：URL 层级、导航与面包屑、内链策略、主题集群与孤岛页面排查，用于定位「根因在结构」的 SEO 问题。"
version: "1.0.0"
license: "MIT"
author: "Alireza Rezvani"
category: ui
tags: ["信息架构", "URL层级", "导航", "内链", "SEO", "面包屑", "站点结构"]
---

# Site Architecture & Internal Linking

You are an expert in website information architecture and technical SEO structure. Your goal is to design website architecture that makes it easy for users to navigate, easy for search engines to crawl, and builds topical authority through intelligent internal linking.

## Before Starting

**Check for context first:**
If `.claude/product-marketing-context.md` exists, read it before asking questions.

Gather this context:

### 1. Current State
- Do they have an existing site? (URL, CMS, sitemap.xml available?)
- How many pages exist? Rough estimate by section.
- What are the top-performing pages (if they know)?
- Any known problems: orphan pages, duplicate content, poor rankings?

### 2. Goals
- Primary business goal (lead gen, e-commerce, content authority, local search)
- Target audience and their mental model of navigation
- Specific SEO targets — topics or keyword clusters they want to rank for

### 3. Constraints
- CMS capabilities (can they change URLs? Does it auto-generate certain structures?)
- Redirect capacity (if restructuring, can they manage bulk 301s?)
- Development resources (minor tweaks vs full migration)

---

## How This Skill Works

### Mode 1: Audit Current Architecture
When a site exists and they need a structural assessment.

1. Run `scripts/sitemap_analyzer.py` on their sitemap.xml (or paste sitemap content)
2. Review: depth distribution, URL patterns, potential orphans, duplicate paths
3. Evaluate navigation by reviewing the site manually or from their description
4. Identify the top structural problems by SEO impact
5. Deliver a prioritized audit with quick wins and structural recommendations

### Mode 2: Plan New Structure
When building a new site or doing a full redesign/restructure.

1. Map business goals to site sections
2. Design URL hierarchy (flat vs layered by content type)
3. Define content silos for topical authority
4. Plan navigation zones: primary nav, breadcrumbs, footer nav, contextual
5. Deliver site map diagram (text-based tree) + URL structure spec

### Mode 3: Internal Linking Strategy
When the structure is fine but they need to improve link equity flow and topical signals.

1. Identify hub pages (the pillar content that should rank highest)
2. Map spoke pages (supporting content that links to hubs)
3. Find orphan pages (indexed pages with no inbound internal links)
4. Identify anchor text patterns and over-optimized phrases
5. Deliver an internal linking plan: which pages link to which, with anchor text guidance

---

## URL Structure Principles

### The Core Rule: URLs are for Humans First

A URL should tell a user exactly where they are before they click. It also tells search engines about content hierarchy. Get this right once — URL changes later require redirects and lose equity.

### Flat vs Layered: Pick the Right Depth

| Depth | Example | Use When |
|-------|---------|----------|
| Flat (1 level) | `/blog/cold-email-tips` | Blog posts, articles, standalone pages |
| Two levels | `/blog/email-marketing/cold-email-tips` | When category is a ranking page itself |
| Three levels | `/solutions/marketing/email-automation` | Product families, nested services |
| 4+ levels | `/a/b/c/d/page` | ❌ Avoid — dilutes crawl equity, confusing |

**Rule of thumb:** If the category URL (`/blog/email-marketing/`) is not a real page you want to rank, don't create the directory. Flat is usually better for SEO.

### URL Construction Rules

| Do | Don't |
|----|-------|
| `/how-to-write-cold-emails` | `/how_to_write_cold_emails` (underscores) |
| `/pricing` | `/pricing-page` (redundant suffixes) |
| `/blog/seo-tips-2024` | `/blog/article?id=4827` (dynamic, non-descriptive) |
| `/services/web-design` | `/services/web-design/` (trailing slash — pick one and be consistent) |
| `/about` | `/about-us-company-info` (keyword stuffing the URL) |
| Short, human-readable | Long, generated, token-filled |

### Keywords in URLs

Yes — include the primary keyword. No — don't stuff 4 keywords in.

`/guides/technical-seo-audit` ✅
`/guides/technical-seo-audit-checklist-how-to-complete-step-by-step` ❌

The keyword in the URL is a minor signal, not a major one. Don't sacrifice readability for it.

### Reference docs
See `references/url-design-guide.md` for patterns by site type (blog, SaaS, e-commerce, local).

---

## Navigation Design

Navigation serves two masters: user experience and link equity flow. Most sites optimize for neither.

### Navigation Zones

| Zone | Purpose | SEO Role |
|------|---------|----------|
| Primary nav | Core site sections, 5-8 items max | Passes equity to top-level pages |
| Secondary nav | Sub-sections within a section | Passes equity within a silo |
| Breadcrumbs | Current location in hierarchy | Equity from deep pages upward |
| Footer nav | Secondary utility links, key service pages | Sitewide links — use carefully |
| Contextual nav | In-content links, related posts, "next step" links | Most powerful equity signal |
| Sidebar | Related content, category listing | Medium equity if above fold |

### Primary Navigation Rules

- 5-8 items maximum. Cognitive load increases with every item.
- Each nav item should link to a page you want to rank.
- Never use nav labels like "Resources" with no landing page — it should be a real, rankable resources page.
- Dropdown menus are fine but crawlers may not engage them deeply — critical pages need a clickable parent link.

### Breadcrumbs

Add breadcrumbs to every non-homepage page. They do three things:
1. Show users where they are
2. Create site-wide upward internal links to category/hub pages
3. Enable BreadcrumbList schema for rich results in Google

Format: `Home > Category > Subcategory > Current Page`

Every breadcrumb segment should be a real, crawlable link — not just styled text.

---

## Silo Structure & Topical Authority

A silo is a self-contained cluster of content about one topic, where all pages link to each other and to a central hub page. Google uses this to determine topical authority.

### Hub-and-Spoke Model

```
HUB: /seo/                          ← Pillar page, broad topic
  SPOKE: /seo/technical-seo/        ← Sub-topic
  SPOKE: /seo/on-page-seo/          ← Sub-topic
  SPOKE: /seo/link-building/        ← Sub-topic
  SPOKE: /seo/keyword-research/     ← Sub-topic
    └─ DEEP: /seo/keyword-research/long-tail-keywords/   ← Specific guide
```

**Linking rules within a silo:**
- Hub links to all spokes
- Each spoke links back to hub
- Spokes can link to adjacent spokes (contextually relevant)
- Deep pages link up to their spoke + the hub
- Cross-silo links are fine when genuinely relevant — just don't build a link for its own sake

### Building Topic Clusters

1. Identify your core topics (usually 3-7 for a focused site)
2. For each topic: one pillar page (the hub) that covers it broadly
3. Create spoke content for each major sub-question within the topic
4. Every spoke links to the pillar with relevant anchor text
5. The pillar links down to all spokes
6. Build the cluster before you build the links — if you don't have the content, the links don't help

---

## Internal Linking Strategy

Internal links are the most underused SEO lever. They're fully under your control, free, and directly affect which pages rank.

### Link Equity Principles

- Google crawls your site from the homepage outward
- Pages closer to the homepage (fewer clicks away) get more equity
- A page with no internal links is an orphan — Google won't prioritize it
- Anchor text matters: generic ("click here") signals nothing; descriptive ("cold email templates") signals topic relevance

### Anchor Text Rules

| Type | Example | Use |
|------|---------|-----|
| Exact match | "cold email templates" | Use sparingly — 1-2x per page, looks natural |
| Partial match | "writing effective cold emails" | Primary approach — most internal links |
| Branded | "our email guide" | Fine, not the most powerful |
| Generic | "click here", "learn more" | Avoid — wastes the signal |
| Naked URL | `https://example.com/guide` | Never use for internal links |

### Finding and Fixing Orphan Pages

An orphan page is indexed but has no inbound internal links. It's invisible to the site's link graph.

How to find them:
1. Export all indexed URLs (from GSC, Screaming Frog, or `sitemap_analyzer.py`)
2. Export all internal links on the site
3. Pages that appear in set A but not set B are orphans
4. Or: run `scripts/sitemap_analyzer.py` which flags potential orphan candidates

How to fix them:
- Add contextual links from relevant existing pages
- Add them to relevant hub pages
- If they truly have no home, consider whether they should exist at all

### The Linking Priority Stack

Not all internal links are equal. From most to least powerful:

1. **In-content links** — within the body copy of a relevant page. Most natural, most powerful.
2. **Hub page links** — the pillar page linking to all its spokes. High equity because pillar pages are linked from everywhere.
3. **Navigation links** — sitewide, consistent, but diluted by their ubiquity.
4. **Footer links** — sitewide, but Google gives them less weight than in-content.
5. **Sidebar links** — OK but often not in the main content flow.

See `references/internal-linking-playbook.md` for patterns and scripts.

---

## Common Architecture Mistakes

| Mistake | Why It Hurts | Fix |
|---------|-------------|-----|
| Orphan pages | No equity flows in, Google deprioritizes | Add contextual internal links from related content |
| URL changes without redirects | Inbound links become broken, equity lost | Always 301 redirect old URLs to new ones |
| Duplicate paths | `/blog/seo` and `/resources/seo` covering same topic | Consolidate with canonical or merge content |
| Deep nesting (4+ levels) | Crawl equity diluted, users confused | Flatten structure, remove unnecessary directories |
| Sitewide footer links to every post | Footer equity is diluted across 500 links | Footer should link to high-value pages only |
| Navigation that doesn't match user intent | Users leave, rankings drop | Run card-sort tests — let users show you their mental model |
| Homepage linking nowhere | Home is highest-equity page — use it | Link from home to key hub pages |
| Category pages with no content | Thin pages rank poorly | Add content to all hub/category pages |
| Dynamic URLs with parameters | `?sort=&filter=` creates duplicate content | Canonicalize or block with robots.txt |

---

## Proactive Triggers

Surface these without being asked:

- **Pages more than 3 clicks from homepage** → flag as crawl equity risk. Any page a user has to click 4+ times to reach needs a structural shortcut.
- **Category/hub page has thin or no content** → hub pages without real content don't rank. Flag and recommend adding a proper pillar page.
- **Internal links using generic anchor text ("click here", "read more")** → wasted signal. Offer to rewrite anchor text patterns.
- **No breadcrumbs on deep pages** → missing upward equity links and BreadcrumbList schema opportunity.
- **Sitemap includes noindex pages** → sitemap should only contain pages you want indexed. Flag and offer to filter.
- **Primary nav links to utility pages (contact, privacy)** → pushing equity to low-value pages. Nav should prioritize money/content pages.

---

## Output Artifacts

| When you ask for... | You get... |
|---------------------|------------|
| Architecture audit | Structural scorecard: depth distribution, orphan count, URL pattern issues, navigation gaps + prioritized fix list |
| New site structure | Text-based site tree (hierarchy diagram) + URL spec table with notes per section |
| Internal linking plan | Hub-and-spoke map per topic cluster + anchor text guidelines + orphan fix list |
| URL redesign | Before/after URL table + 301 redirect mapping + implementation checklist |
| Silo strategy | Topic cluster map per business goal + content gap analysis + pillar page brief |

---

## Communication

All output follows the structured communication standard:
- **Bottom line first** — answer before explanation
- **What + Why + How** — every finding has all three
- **Actions have owners and deadlines** — no "we should consider"
- **Confidence tagging** — 🟢 verified / 🟡 medium / 🔴 assumed

---

## Related Skills

- **seo-audit**: For comprehensive SEO audit covering technical, on-page, and off-page. Use seo-audit when architecture is one of several problem areas. NOT for deep structural redesign — use site-architecture.
- **schema-markup**: For structured data implementation. Use after site-architecture when you want to add BreadcrumbList and other schema to your finalized structure.
- **content-strategy**: For deciding what content to create. Use content-strategy to plan the content, then site-architecture to determine where it lives and how it links.
- **programmatic-seo**: When you need to generate hundreds or thousands of pages systematically. Site-architecture provides the URL and structural patterns that programmatic-seo scales.
- **seo-audit**: For identifying technical issues. NOT for architecture redesign planning — use site-architecture for that.
$md$,
  '[{"path":"ATTRIBUTION.md","size":969,"kind":"text"},{"path":"LICENSE","size":1072,"kind":"text"},{"path":"SKILL.md","size":13645,"kind":"text"},{"path":"references/internal-linking-playbook.md","size":8651,"kind":"text"},{"path":"references/url-design-guide.md","size":8505,"kind":"text"},{"path":"scripts/sitemap_analyzer.py","size":15162,"kind":"text"}]'::jsonb, 6, 48004, 'b49cfc61ccf23bf2b43048faf5d7f2a5e9da4b2a74b73fd7f5c8f694a75f6f97',
  $b64$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$b64$,
  'published'
)
on conflict do nothing;

insert into public.skills
  (slug, name, description, category, tags, version, license, author,
   readme, files, file_count, total_bytes, hash, bundle_b64, status)
values (
  'ecommerce-ui', 'ecommerce-ui', '设计电商商品卡、商品详情页、购物车与结算流程时使用：图片比例、价格层级、规格选择、吸底加购、结算步数与移动端差异。', 'ui',
  array['业务场景', '商品卡', '结算流程', '规格选择', '促销标签', '吸底操作栏']::text[], '1.0.0', 'MIT', 'Skill Hub',
  $md$---
name: "ecommerce-ui"
description: "设计电商商品卡、商品详情页、购物车与结算流程时使用：图片比例、价格层级、规格选择、吸底加购、结算步数与移动端差异。"
version: "1.0.0"
license: "MIT"
author: "Skill Hub"
category: ui
tags: ["业务场景", "商品卡", "结算流程", "规格选择", "促销标签", "吸底操作栏"]
---

# 电商界面设计

电商界面的每一屏都在做同一件事：**把「想买」变成「下单」**。
它比大多数界面更依赖「减少犹豫」而不是「减少操作」——
用户不是不会点，是在犹豫。设计要处理的是犹豫，不是路径。

## 何时使用

- 设计商品列表 / 商品卡
- 设计商品详情页（图集、规格、加购区）
- 设计购物车与结算流程
- 电商页面转化率低、加购多但支付少
- 需要处理库存、促销标签、划线价等电商特有元素

## 核心规则

1. **商品卡图片比例全站统一，取 `1:1` 或 `3:4`，不能混用**。
   - `1:1`：适合家居、数码、日用 —— 商品居中，留白多
   - `3:4`：适合服饰、鞋包 —— 更接近人眼对「全身」的预期，列表更高信息量
   - 统一比例的理由：混用会让列表出现参差不齐的卡片高度，
     用户视线无法沿一条水平线扫描，浏览效率显著下降
   - 图片用 `aspect-ratio: 1 / 1` + `object-fit: cover`，**不要用固定高度**

2. **价格层级：现价必须比原价明显更重**。
   - 现价字号 20–28px、字重 600–700、品牌红/主色
   - 划线原价字号 = 现价的 0.65–0.75 倍，灰色，`text-decoration: line-through`
   - **原价在前、现价在后**（`¥199 ¥99`）符合中文电商阅读习惯，
     且划线价的作用是「让现价显得便宜」
   - 只有现价没有原价时，**不要伪造原价**。假划线价在部分市场属于价格欺诈
   - 折扣用「省 ¥100」比「5 折」更有效，因为金额比比例更直观

3. **加购区在移动端必须吸底**。
   - 吸底条高度 56–64px，`position: fixed; bottom: 0`，
     且必须加 `padding-bottom: env(safe-area-inset-bottom)`（iPhone 底部横条区）
   - 吸底条内容：左侧「客服/收藏」图标（可选）+ 中间「加入购物车」描边按钮 +
     右侧「立即购买」实心按钮，比例约 1 : 1.4 : 1.6
   - 页面主体必须加 `padding-bottom: 80px`，否则最后一个模块会被吸底条挡住
   - 商品详情页的「立即购买」是**唯一**视觉最强按钮，不要同时给 3 个按钮同等权重

4. **规格选择必须用「选项即按钮」而不是 `<select>`**。
   - 颜色/尺码等 ≤ 8 个选项时，用可点选的 chip，热区 ≥ 44×44px
   - 选项选中态：品牌色边框 2px + 浅色背景，**不要只靠颜色变化**（色盲不可辨）
   - 不可选（无库存）的规格要**禁用并说明原因**（`该尺码已售罄`），
     不要直接隐藏 —— 隐藏会让用户以为这个尺码不存在
   - 选项数 > 8（如手机号段、地址省市区）才用下拉

5. **结算流程步数 ≤ 3 步**，且必须有进度指示：
   `购物车 → 填地址与支付 → 完成`。
   - 每多一步，流失率约增加 10–20%
   - 地址、发票、优惠券、配送时间**放在同一步内用折叠区块**，不要各占一步
   - 未登录用户**必须支持游客下单**；强制注册是电商最大的流失来源之一
   - 进度条要显示「第 2 步 / 共 3 步」，只用圆点会让用户不知道还有多远

6. **促销与库存标签最多同屏 2 个**。
   标签类型：`包邮`、`满减`、`限时`、`新品`、`仅剩 3 件`、`预售`。
   - 同屏超过 2 个标签，用户会认为「全是套路」，标签的边际说服力变负
   - 标签字号 11–12px，高度 18–20px，圆角 2–4px（小圆角，大圆角显廉价）
   - 「仅剩 N 件」的 N 必须真实且 ≤ 10 才有紧迫感；写「仅剩 999 件」是反效果
   - 库存紧张提示必须在**用户选择规格之后**出现，不是一进页面就闪

7. **移动端电商与 PC 端不是同一套信息顺序**：

   | 维度 | PC | 移动 |
   | --- | --- | --- |
   | 详情页布局 | 左图右信息（图 55% / 信息 45%） | 上图文下信息，单列 |
   | 图集 | 左侧缩略图 + 主图 | 横向滑动轮播，带 `1/8` 计数 |
   | 规格 | 页面内嵌 | 从底部弹出抽屉（`bottom sheet`） |
   | 加购 | 页面内按钮 | 固定吸底 |
   | 列表列数 | 4–5 列 | 2 列（大图）或 1 列（信息多） |
   | 促销信息 | 可并排 | 必须折叠，只留最关键的 1 条 |

## 怎么做

### 第 1 步：商品卡

```html
<a class="pcard" href="/p/12345">
  <div class="pcard__media">
    <img src="/p/12345-1.webp" alt="轻量羽绒外套 藏青" width="400" height="400" loading="lazy">
    <span class="pcard__tag">限时直降</span>
  </div>
  <div class="pcard__body">
    <h3 class="pcard__title">轻量羽绒外套 90 白鸭绒 可机洗</h3>
    <div class="pcard__price">
      <span class="pcard__now">¥<b>399</b></span>
      <s class="pcard__was">¥599</s>
    </div>
    <p class="pcard__meta">已售 2.3 万 · 好评率 98%</p>
  </div>
</a>
```

```css
.pcard__media { position: relative; aspect-ratio: 1 / 1; overflow: hidden; border-radius: 8px; }
.pcard__media img { width: 100%; height: 100%; object-fit: cover; }
.pcard__title {
  font-size: 14px; line-height: 1.4; margin: 8px 0 6px;
  display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical;
  overflow: hidden;   /* 标题最多 2 行，保证卡片等高 */
}
.pcard__now { font-size: 22px; font-weight: 700; color: var(--price-red); }
.pcard__now b { font-size: 22px; }
.pcard__was { font-size: 13px; color: var(--text-tertiary); margin-left: 6px; }
```

`-webkit-line-clamp` 是各主流浏览器都支持的多行截断（需配 `display: -webkit-box`）。
不截断会导致标题长短不一的卡片高度错乱。

### 第 2 步：商品详情页

信息顺序（移动端从上到下）：

1. 图集轮播（1:1，带 `1/8` 计数，点击放大）
2. 价格区（现价 + 划线价 + 促销标签）
3. 标题（最多 2 行）+ 卖点短句
4. 规格选择入口（显示已选：`颜色：藏青 · 尺码：L`）
5. 服务承诺（`7 天无理由` `顺丰包邮` `正品保障`）
6. 评价摘要（评分 + 3 条带图评价 + `查看全部`）
7. 图文详情
8. 推荐商品
9. **吸底加购条**（固定）

规格抽屉：

```html
<div class="sku-sheet" role="dialog" aria-modal="true" aria-labelledby="sku-title">
  <div class="sku-sheet__head">
    <img src="/p/12345-1.webp" alt="" width="72" height="72">
    <div>
      <p class="sku-sheet__price">¥399 <s>¥599</s></p>
      <p class="sku-sheet__stock">库存 128 件</p>
    </div>
    <button class="sku-sheet__close" aria-label="关闭">✕</button>
  </div>
  <div class="sku-sheet__group">
    <p id="sku-title">颜色</p>
    <div class="sku-sheet__options">
      <button aria-pressed="true">藏青</button>
      <button aria-pressed="false">米白</button>
      <button disabled aria-describedby="soldout">墨绿</button>
    </div>
    <p id="soldout" class="sku-sheet__hint">墨绿已售罄</p>
  </div>
  <button class="btn btn--primary btn--block">加入购物车</button>
</div>
```

要点：

- 抽屉高度不超过视口的 80%，内容超出时**内部滚动**，头部价格固定
- 头部必须**重复显示商品图和价格** —— 用户从详情页滚下来时已经忘了自己在看什么
- 用 `aria-pressed` 表示 chip 选中态，而不是只加 class
- 抽屉打开时锁住背景滚动：`body { overflow: hidden }`，
  并处理 iOS 的滚动穿透（可用 `overscroll-behavior: contain` 在抽屉容器上）

### 第 3 步：购物车

- 每行：勾选框、图片（1:1，80px）、标题（最多 2 行）、规格、
  单价、数量步进器、删除
- 数量步进器：减号、输入框、加号，每个热区 ≥ 44×44px；
  输入框 `inputmode="numeric"`，限制 1–999
- 底部结算栏固定：左侧「全选」+ 合计金额，右侧「去结算（N）」按钮
- **合计金额必须只统计勾选项**，并实时更新；延迟超过 100ms 会让用户怀疑算错
- 失效商品（下架/无货）单独分组放在最下方，标题写「失效商品」，
  提供「一键清空失效商品」，不要混在有效商品里

### 第 4 步：结算页

单页三段（用锚点或折叠，不要拆成三个路由）：

1. **收货地址**：默认地址直接展示，点击切换；新增地址用抽屉
2. **配送与发票**：配送时间（`工作日/周末/指定日期`）、发票类型
3. **商品清单 + 优惠**：可折叠，默认收起，标题写 `共 3 件，合计 ¥1,197`

底部固定提交栏：`实付 ¥1,197` + `提交订单` 按钮。

**支付方式选择在提交后**（跳转收银台），不要在结算页里选，
否则会把一个已经很难的页面变得更长。

### 第 5 步：错误与边界

| 场景 | 处理 |
| --- | --- |
| 加购时商品已下架 | Toast：`该商品已下架`，并把加购按钮置为禁用 |
| 提交时库存不足 | 保留用户填的地址，只提示冲突商品，不要清空表单 |
| 优惠券失效 | 保留订单，在优惠行内标红提示，不阻断提交 |
| 支付超时 | 订单进入「待付款」，提供「继续支付」入口，并给出倒计时 |
| 重复点击提交 | 提交按钮立即置 `disabled` + loading，防止重复下单 |

## 检查清单

- [ ] 所有商品卡图片比例统一（1:1 或 3:4），未混用
- [ ] 商品标题截断为 2 行，卡片等高
- [ ] 现价字号 ≥ 20px 且字重 ≥ 600，划线价为灰色且更小
- [ ] 划线价真实，不存在伪造原价
- [ ] 同屏促销/库存标签 ≤ 2 个
- [ ] 规格选项热区 ≥ 44×44px，选中态不只靠颜色区分
- [ ] 无库存规格禁用并给出文字说明，而非隐藏
- [ ] 移动端加购区吸底，且加了 `env(safe-area-inset-bottom)`
- [ ] 吸底条存在时，页面主体有 ≥ 80px 的底部 padding
- [ ] 结算流程 ≤ 3 步，且有「第 N 步 / 共 M 步」指示
- [ ] 支持游客下单，未强制注册
- [ ] 购物车合计只统计勾选项，且实时更新
- [ ] 失效商品独立分组，可一键清空
- [ ] 提交订单按钮点击后立即禁用，防止重复下单
- [ ] 移动端规格选择用底部抽屉，且抽屉打开时背景不滚动

## 常见错误

| 错误做法 | 为什么错 | 正确做法 |
| --- | --- | --- |
| 商品图比例 1:1 和 4:3 混用 | 列表卡片高度参差，视线无法水平扫描 | 全站统一比例，`aspect-ratio` 锁死 |
| 用固定高度代替 `aspect-ratio` | 图片变形，或响应式下被拉伸 | `aspect-ratio` + `object-fit: cover` |
| 现价和划线价同字号同色 | 没有价格对比，划线价失去「锚」的作用 | 现价大且重，划线价小且灰 |
| 伪造划线价 | 涉嫌价格欺诈，且被识破后信任崩塌 | 只用真实历史价或建议零售价 |
| 一屏挂 5 个促销标签 | 用户判定「全是套路」，说服力转负 | 最多 2 个，其余折叠进详情 |
| 规格用 `<select>` | 移动端唤起系统滚轮，选项少时体验差 | ≤ 8 个选项用 chip，热区 ≥ 44px |
| 无库存规格直接隐藏 | 用户以为该尺码不存在，反复刷新页面 | 禁用 + 文字说明原因 |
| 结算要 5 步（地址、配送、发票、优惠、支付各一步） | 每步流失 10–20%，累计流失过半 | 折叠成 1 步内，支付跳转收银台 |
| 强制注册才能下单 | 电商最大的流失来源，尤其移动端 | 支持游客下单，下单后再引导注册 |
| 吸底条不加 safe-area | iPhone 底部横条遮挡按钮，点不到 | `padding-bottom: env(safe-area-inset-bottom)` |
| 购物车合计包含未勾选项 | 用户认为算错，放弃结算 | 合计只算勾选项，实时更新 |
| 提交订单按钮无防重复 | 网络慢时用户连点，产生重复订单 | 点击后立即禁用 + loading |

## 参考

- 需要细化结算流程与地址、支付、发票的具体字段时，读 `references/checkout-flow.md`
- 需要商品卡在列表、推荐位、搜索结果等不同场景的规格时，读 `references/product-card-specs.md`
$md$,
  '[{"path":"ATTRIBUTION.md","size":484,"kind":"text"},{"path":"LICENSE","size":1074,"kind":"text"},{"path":"SKILL.md","size":12386,"kind":"text"},{"path":"references/checkout-flow.md","size":5087,"kind":"text"},{"path":"references/product-card-specs.md","size":6000,"kind":"text"}]'::jsonb, 5, 25031, '86794817409db1daf8ee5809b71a16cf37af7fdb40c9c7adab0360e8bc92078f',
  $b64$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$b64$,
  'published'
)
on conflict do nothing;

insert into public.skills
  (slug, name, description, category, tags, version, license, author,
   readme, files, file_count, total_bytes, hash, bundle_b64, status)
values (
  'fintech-ui', 'fintech-ui', '设计账户、行情、转账、账单等金融界面时使用：金额排版与等宽数字、涨跌色惯例、表格图表层级、二次确认与安全感的视觉表达。', 'ui',
  array['业务场景', '等宽数字', '涨跌配色', '金额排版', '二次确认', '风控流程']::text[], '1.0.0', 'MIT', 'Skill Hub',
  $md$---
name: "fintech-ui"
description: "设计账户、行情、转账、账单等金融界面时使用：金额排版与等宽数字、涨跌色惯例、表格图表层级、二次确认与安全感的视觉表达。"
version: "1.0.0"
license: "MIT"
author: "Skill Hub"
category: ui
tags: ["业务场景", "等宽数字", "涨跌配色", "金额排版", "二次确认", "风控流程"]
---

# 金融界面设计

金融界面的核心不是「好看」，是**让用户在 3 秒内确认三件事**：
这笔钱是多少、方向对不对、接下来会发生什么。
一个数字对齐错位、一个颜色用反，都会让用户怀疑「系统是不是算错了」，
而这种怀疑一旦产生，很难靠文案消除。

## 何时使用

- 设计账户余额、资产总览、账单明细页
- 设计行情列表、K 线、持仓表
- 设计转账、提现、支付确认、风控校验流程
- 需要在界面里表达「这笔钱是安全的」
- 需要在表格/图表里同时呈现大量数字且保证可读

## 核心规则

1. **所有金额数字必须用等宽数字**：
   ```css
   .amount { font-variant-numeric: tabular-nums; }
   ```
   理由：比例数字里 `1` 比 `8` 窄，一列金额右对齐后会参差不齐，
   用户无法快速比较大小。这是金融界面**最不能省**的一条。
   同时指定一个数字等宽的字体族
   （如 `ui-monospace, "SF Mono", Consolas, monospace`）或本身数字等宽的无衬线字体。

2. **金额对齐规则**：
   - **一列金额右对齐**（`text-align: right`），不是左对齐、不是居中
   - 表格里数字列的宽度按最长值预留，不要用 `1fr` 让它们撑开
   - 货币符号与数字之间不留空格（`¥1,299.00`），
     但符号字号为数字的 0.7–0.8 倍
   - 小数位**同列统一**：要么全 2 位（`99.00`），要么全 0 位（`99`）。
     混用（`99` 和 `99.5`）会破坏右对齐的视觉列
   - 千分位**必加**：`¥1,299,000.00`。超过 4 位不加分隔是金融界面的低级错误

3. **涨跌色遵循中国惯例：涨红跌绿**。
   - 上涨：红 `#e5342a` 附近；下跌：绿 `#0aa06e` 附近
   - **必须提供「国际惯例」开关**（涨绿跌红），因为跨境产品/外籍用户需要
   - **颜色不能是唯一信号**：涨跌同时要有 `+` / `−` 号和箭头（`▲` / `▼`）。
     红绿色盲人群约占男性 8%，只靠颜色他们完全无法分辨
   - 分时图 / K 线的涨跌色与列表色保持一致，不要一处红涨一处绿涨
   - 中性（0.00%）用灰色，不要用红也不要绿

4. **金额层级：一屏只允许一个「最大数字」**。
   - 主金额（如账户总资产）：32–40px，字重 600
   - 次级金额（如可用余额）：20–24px，字重 500
   - 列表金额：14–16px，字重 400–500
   - 说明文字（如「折合人民币」）：12–13px，次级色
   **不要**在一屏放 3 个 36px 的数字 —— 用户会不知道先看哪个。

5. **任何资金流出动作必须有二次确认，且确认内容要「可核对」**：
   - 确认页必须重复：收款方（名称 + 账号后 4 位）、金额（大号加粗）、
     手续费、到账时间
   - 金额在确认页的字号应 ≥ 输入页的 1.2 倍
   - 高危操作（大额、首次转给新收款人、修改安全设置）用**输入密码 / 短信验证码**
     而非「点击确认」，因为点击的摩擦太低
   - 确认按钮文案写具体动作：`确认转账 ¥12,000`，
     不要写 `确定`。带金额的按钮能让用户在最后一步再核对一次

6. **「让用户相信钱是安全的」靠四类视觉手段，不是靠一句「安全」**：
   - **可核对的细节**：显示收款方实名、账号后 4 位、银行名 —— 细节越具体越可信
   - **状态可见**：加密标识（`https` + 锁图标）、风控提示（`本次交易已通过风控校验`）
   - **可撤销**：明确写出撤销窗口（`2 小时内可撤回`）和客服入口
   - **一致性**：金额、时间、订单号在输入页、确认页、结果页三处必须完全一致。
     任何一处对不上，用户就会怀疑资金安全

7. **风控拦截页必须给出出路**，不能只说「交易被拒绝」：
   - 说明**原因类别**（不暴露风控规则细节）：`为保护账户安全，本次交易需人工核实`
   - 给出**具体下一步**：`拨打 400-XXX-XXXX 核实` / `前往网点` / `等待 15 分钟重试`
   - 保留**订单信息**，让用户在解决后能一键继续，不用重新填
   - 不要显示错误码作为唯一信息（`Error 4032` 对用户无意义）

## 怎么做

### 第 1 步：建立金额排版基元

```css
:root {
  --num-font: ui-monospace, "SF Mono", "Roboto Mono", Consolas, monospace;
  --up: #e5342a;      /* 涨：红 */
  --down: #0aa06e;    /* 跌：绿 */
  --flat: #8a8f99;
}
.amount {
  font-family: var(--num-font);
  font-variant-numeric: tabular-nums;
  text-align: right;
}
.amount--hero { font-size: 36px; font-weight: 600; letter-spacing: -0.01em; }
.amount--sub  { font-size: 22px; font-weight: 500; }
.amount--cell { font-size: 14px; font-weight: 400; }
.amount__cur  { font-size: .72em; font-weight: 500; margin-right: 1px; }
```

显示金额时统一走一个格式化函数，**不要在各处手写**：

```js
const fmt = (n, d = 2) => n.toLocaleString("zh-CN", {
  minimumFractionDigits: d, maximumFractionDigits: d,
});   // fmt(1299000.5) → "1,299,000.50"
```

`toLocaleString` 是标准 API，不要自己写千分位正则 ——
自己写通常会在负数、小数、极大值上出错。

### 第 2 步：涨跌显示组件

```html
<span class="chg chg--up">
  <span aria-hidden="true">▲</span>
  <span class="amount">+2.35%</span>
</span>
```

```css
.chg { display: inline-flex; align-items: center; gap: 2px; font-variant-numeric: tabular-nums; }
.chg--up   { color: var(--up); }
.chg--down { color: var(--down); }
.chg--flat { color: var(--flat); }
```

- 箭头 `▲` / `▼` 加 `aria-hidden`，因为旁边的 `+2.35%` 已经表达了方向，
  读屏重复朗读反而干扰
- 涨跌数值**必须带正负号**，`0.00%` 不带号
- 涨跌色的对比度也要满足 4.5:1（红绿在浅背景上容易不达标，实测再定色值）

### 第 3 步：资产总览

结构从上到下：

1. 总资产（主金额，36px）+ 当日变动（涨跌组件，14px）
2. 「隐藏金额」眼睛图标 —— **默认显示**，点击后全站金额变 `****`，
   状态持久化到 sessionStorage，切页面不重置
3. 资产构成（可用 / 冻结 / 在途），三列，每列金额 + 标签
4. 快捷操作（转入 / 转出 / 明细），最多 4 个
5. 明细列表（最近 5 条）+ `查看全部`

**隐藏金额时也要隐藏「当日变动」**，否则能从变动额反推总资产。

### 第 4 步：明细/持仓表格

```html
<table class="fin-table">
  <thead>
    <tr>
      <th scope="col" class="col-name">名称</th>
      <th scope="col" class="col-num">持仓</th>
      <th scope="col" class="col-num">成本</th>
      <th scope="col" class="col-num">市值</th>
      <th scope="col" class="col-num">盈亏</th>
    </tr>
  </thead>
  <tbody><!-- ... --></tbody>
</table>
```

```css
.fin-table { width: 100%; border-collapse: collapse; }
.fin-table th, .fin-table td { padding: 12px 16px; }
.fin-table .col-num { text-align: right; font-variant-numeric: tabular-nums; }
.fin-table thead th { position: sticky; top: 0; background: var(--surface); z-index: 1; }
.fin-table tbody tr:nth-child(even) { background: rgba(0,0,0,.015); }  /* 极浅斑马纹 */
```

要点：

- **斑马纹要极浅**（透明度 ≤ 0.02）。金融表格行多，强斑马纹会让人眼晕
- 表头 `sticky`，长表格滚动时列含义不能丢
- 名称列左对齐且 `min-width: 160px`，数字列右对齐
- 行高 44–52px（金融表格以可读性优先，比后台的 40px 略高）
- 负数金额用括号或负号**统一一种**（`-¥1,200` 或 `(¥1,200)`），不要混用
- 盈亏列同时用颜色 + 符号，不要只上色
### 第 5 步：转账确认流程

```
输入（收款方、金额、备注）
  ↓
确认页（收款方实名、账号后4位、金额大字、手续费、到账时间）
  ↓  [确认转账 ¥12,000]
验证（支付密码 / 短信验证码 / 生物识别）
  ↓
结果页（成功 + 订单号 + 到账时间 + 撤销入口）
```

每一页都要有的东西：**金额、收款方、订单号（确认后才有）**。
三页之间金额必须逐字一致，包括千分位和两位小数。

输入页的金额输入框：

```html
<div class="amt-input">
  <label for="amt">转账金额</label>
  <div class="amt-input__field">
    <span class="amount__cur">¥</span>
    <input id="amt" inputmode="decimal" autocomplete="off"
           value="12,000.00" aria-describedby="amt-hint">
  </div>
  <p id="amt-hint">可用余额 ¥58,420.00</p>
</div>
```

- `inputmode="decimal"` 唤起数字键盘，但保留小数点
- 输入时实时格式化千分位，**但光标位置要正确**（格式化后把光标放到原相对位置，
  否则用户输入会被打断）
- 超限时在输入框下方提示（`超出可用余额`），并禁用下一步按钮
- 常用金额快捷按钮：`全部` / 整百金额，热区 ≥ 44px
### 第 6 步：安全感视觉元素

| 手段 | 具体做法 | 不要做什么 |
| --- | --- | --- |
| 实名核对 | 显示收款方姓氏 + `**`（`李**`）与银行名 | 不显示任何收款方信息 |
| 账号核对 | 显示账号后 4 位 | 显示完整账号（隐私风险） |
| 加密标识 | 页面底部一行 `本页已启用 TLS 1.3 加密` | 挂一个无来源的「安全认证」徽章 |
| 风控状态 | `已通过风控校验`（成功时静默，不弹窗） | 每次都弹「安全提示」弹窗 |
| 撤销窗口 | `2 小时内可在「交易记录」中撤回` | 不告知可撤销性 |

**反模式**：页面上堆 5 个盾牌图标写「银行级安全」——
没有具体信息的图标不产生信任，只产生广告感。

## 检查清单

- [ ] 所有金额使用 `font-variant-numeric: tabular-nums`
- [ ] 金额列右对齐，同列小数位一致
- [ ] 千分位通过 `toLocaleString` 统一格式化，无手写正则
- [ ] 涨红跌绿，并提供国际惯例（涨绿跌红）开关
- [ ] 涨跌同时有颜色和符号（`+`/`−`、`▲`/`▼`），不只靠颜色
- [ ] 一屏只有一个最大号金额
- [ ] 资金流出动作有二次确认页，且重复展示金额与收款方
- [ ] 确认按钮带具体金额文案（`确认转账 ¥12,000`）
- [ ] 大额/首次转账使用密码或验证码而非点击确认
- [ ] 输入页、确认页、结果页的金额、收款方、订单号完全一致
- [ ] 风控拦截页给出具体下一步与客服入口，且保留订单信息
- [ ] 「隐藏金额」状态持久化，且同时隐藏当日变动
- [ ] 长表格表头 sticky，斑马纹透明度 ≤ 0.02，负数写法全站统一

## 常见错误

| 错误做法 | 为什么错 | 正确做法 |
| --- | --- | --- |
| 金额用比例数字 | 数字宽度不一，右对齐后视觉参差，无法快速比较 | `tabular-nums` 等宽数字 |
| 金额左对齐或居中 | 不同位数的金额无法形成可比较的视觉列 | 一列金额统一右对齐 |
| 千分位手写正则 | 负数、小数、超大值容易算错，且各页面实现不一致 | `Number.prototype.toLocaleString` |
| 用绿色表示上涨（直接套欧美惯例） | 中国用户看到绿会以为是跌，方向读反 | 涨红跌绿，并提供国际惯例开关 |
| 只靠红绿区分涨跌 | 红绿色盲用户完全无法分辨 | 加 `+`/`−` 号和箭头 |
| 一屏三个 36px 大数字 | 用户不知道主次，视觉上互相抢 | 只留一个主金额，其余降级 |
| 确认页只写「确认转账」 | 用户在最后一步无法核对金额，容易转错 | 按钮写 `确认转账 ¥12,000` |
| 点击即完成大额转账 | 摩擦太低，误触与诈骗风险高 | 大额/首次收款人需密码或验证码 |
| 三页金额显示不一致（一处 `12000` 一处 `¥12,000.00`） | 用户怀疑系统出错，甚至认为被篡改 | 统一走同一格式化函数 |
| 风控拦截只显示错误码 | 用户不知道怎么办，只能打客服或放弃 | 给出原因类别 + 具体下一步 + 保留订单 |
| 隐藏金额后仍显示「当日变动」 | 可从变动额反推总资产，隐私泄露 | 两者一起隐藏 |
| 表格斑马纹透明度 0.08 | 长表格下视觉疲劳，行间干扰 | 透明度 ≤ 0.02，或改用极细分隔线 |
| 挂 5 个盾牌图标写「银行级安全」 | 无信息量，观感像广告，不产生信任 | 用可核对细节 + 撤销窗口 + 客服入口 |

## 参考

- 需要处理 K 线、分时图、盘口等专业行情组件时，读 `references/market-charts.md`
- 需要细化金额输入、校验与风控流程的交互细节时，读 `references/money-input-and-risk.md`
$md$,
  '[{"path":"ATTRIBUTION.md","size":484,"kind":"text"},{"path":"LICENSE","size":1074,"kind":"text"},{"path":"SKILL.md","size":13070,"kind":"text"},{"path":"references/market-charts.md","size":6021,"kind":"text"},{"path":"references/money-input-and-risk.md","size":6649,"kind":"text"}]'::jsonb, 5, 27298, '636e31d2915cb9d563346584638ab612933d613c56b54b2e796d711da9cdc3f6',
  $b64$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$b64$,
  'published'
)
on conflict do nothing;

insert into public.skills
  (slug, name, description, category, tags, version, license, author,
   readme, files, file_count, total_bytes, hash, bundle_b64, status)
values (
  'healthcare-ui', 'healthcare-ui', '设计挂号、病历、检验报告、用药与健康数据录入界面时使用：字号与对比度下限、单位与范围校验、隐私边界、紧急状态与适老化。', 'ui',
  array['业务场景', '适老化', '数值录入校验', '隐私脱敏', '紧急状态', '可读性']::text[], '1.0.0', 'MIT', 'Skill Hub',
  $md$---
name: "healthcare-ui"
description: "设计挂号、病历、检验报告、用药与健康数据录入界面时使用：字号与对比度下限、单位与范围校验、隐私边界、紧急状态与适老化。"
version: "1.0.0"
license: "MIT"
author: "Skill Hub"
category: ui
tags: ["业务场景", "适老化", "数值录入校验", "隐私脱敏", "紧急状态", "可读性"]
---

# 医疗健康界面设计

医疗界面的用户画像和别的行业不一样：**平均年龄更大、状态更差、
容错能力更低**，而且看错一个数字的代价可能是吃错药。
所以这里的每一条设计规则都要为「读错」和「输错」兜底，
视觉表现力排在最后。

## 何时使用

- 设计挂号、预约、问诊、缴费流程
- 设计病历、检验报告、影像报告展示
- 设计用药提醒、体征记录（血压、血糖、体重）、健康档案录入
- 面向老年用户的健康类 App / 小程序
- 需要在界面上表达紧急状态（危急值、过敏、抢救）

## 核心规则

1. **字号与行高有硬性下限，不得为了「塞下更多内容」而降低**：
   | 内容 | 最小字号 | 推荐字号 |
   | --- | --- | --- |
   | 正文 / 报告描述 | 16px | 16–18px |
   | 数值（血压、血糖等） | 24px | 28–36px |
   | 标签 / 单位 | 14px | 14–16px |
   | 辅助说明 | 13px | 14px |
   | 按钮文字 | 16px | 16–18px |
   | 适老模式正文 | 20px | 22–24px |

   行高 **1.6–1.8**（高于通用界面的 1.5），因为医疗文本句子长、术语多，
   行距不足会导致串行。**任何位置都不允许出现 12px 以下的文字**。

2. **对比度提高到 7:1（WCAG AAA 正文标准），不是 4.5:1**。
   理由：老年用户晶状体浑浊，对低对比度极不敏感；
   且医疗场景常在强光（医院走廊、户外）下使用。
   - 正文用 `#1a1a1a` 而非 `#333` 或 `#666`
   - 次级信息最低 `#5a5a5a`，且字号不得小于 14px；
     **不要用浅灰文字表达「禁用」**，改用明确的文字说明
   - 状态色（正常/异常）必须实测对比度，红绿在浅背景上常不达标

3. **数值必须带单位，且单位与数值绑定显示**：
   - `120/80 mmHg`、`5.6 mmol/L`、`36.8 ℃`、`72 次/分`
   - **数值和单位不能分离到两行**，用 `white-space: nowrap` 包住；
     单位字号 = 数值的 0.5–0.6 倍，颜色为次级色
   - 不同医院/设备的单位可能不同（血糖 `mmol/L` 与 `mg/dL`），
     切换单位时必须**重新换算数值**，不能只换标签
   - 参考范围必须紧跟数值：`5.6 mmol/L（参考 3.9–6.1）`

4. **数据录入必须做三重校验：格式、范围、异常值**。
   | 层级 | 时机 | 处理 |
   | --- | --- | --- |
   | 格式 | 输入时 | 只允许数字与一个小数点，`inputmode="decimal"` |
   | 范围 | 失焦时 | 超出「医学可能范围」直接报错并阻止提交 |
   | 异常值 | 提交前 | 超出「正常参考范围」不阻止，但要求二次确认 |

   举例（血压收缩压）：
   - 医学可能范围 `50–300`：超出 → 硬报错，不允许提交
   - 正常参考范围 `90–140`：超出 → 提示 `该数值偏高，请确认是否输入正确`，
     用户确认后可继续
   **绝不能**把异常值静默存下，也**绝不能**因为「偏高」就不让用户提交 ——
   真实患者的高血压数据本来就该被记录。

5. **隐私与敏感信息的展示边界**：
   - 默认**不展示完整身份证号、手机号、住址**：
     `3301**********1234`、`138****8888`
   - 检验报告默认只展示本次，历史记录需主动展开
   - 涉及精神科、传染病、生殖健康的报告：列表页**不显示项目名称**，
     只显示 `报告（需登录查看）`；进入详情前增加一次身份校验
   - 截图分享时**自动打码**敏感字段，或提供「生成分享图」功能，
     而不是让用户直接截屏
   - 退出登录、切换账号时必须清空本地缓存的报告数据，页面加 `no-store` 缓存头

6. **紧急状态的视觉处理要「一眼可辨」，且不依赖颜色**：
   - 危急值（critical value）用**红色实底横幅 + 图标 + 文字**三通道，
     文案写清**做什么**：`血压 185/120 mmHg 属危急值，请立即联系医生`
   - 过敏史在用药页**常驻显示**，用红色描边卡片固定在页面顶部，不随滚动消失
   - 紧急联系人按钮在适老模式下固定悬浮，热区 ≥ 56×56px
   - **禁止**用闪烁动画表达紧急（会诱发光敏性癫痫，且老年用户看不清）
   - 危急值不能只出现在报告某一行的颜色上，必须提到页面顶部汇总

7. **适老化不是「把字号调大」，是四条同时成立**：
   1. 字号放大到 20–24px（正文），行高 1.8
   2. 点击热区 ≥ 56×56px，按钮间距 ≥ 16px
   3. **减少同屏信息量**：一屏一个任务，去掉所有次要入口
   4. 提供**大字号模式开关**（默认可以开），并保留系统字号设置的响应
   - 不要用纯图标按钮（老年用户对图标的语义识别率低），必须带文字标签
   - 手势操作要有替代：滑动删除必须同时提供「删除」按钮
   - 适老模式下**不出现横向滚动**，需要横向滑的内容一律改纵向

## 怎么做

### 第 1 步：建立可读性基线

```css
:root {
  --text-primary: #1a1a1a;     /* 对比度 ≥ 12:1 */
  --text-secondary: #5a5a5a;   /* 对比度 ≥ 7:1 */
  --danger: #c62828;           /* 用于危急值，实底 + 白字 */
}
body {
  font-size: 16px;
  line-height: 1.7;
  color: var(--text-primary);
  -webkit-text-size-adjust: 100%;   /* 防止横屏时 iOS 自动放大字号 */
}
@media (prefers-contrast: more) {
  :root { --text-secondary: #333; }
  .card { border-width: 2px; }
}
```

`prefers-contrast` 是系统级无障碍媒体查询，用户开启「增强对比度」时生效。

### 第 2 步：检验报告行

```html
<tr class="result result--high">
  <th scope="row">空腹血糖</th>
  <td class="result__value">
    <span class="num">5.6</span>
    <span class="unit">mmol/L</span>
  </td>
  <td class="result__range">3.9 – 6.1</td>
  <td class="result__flag">
    <span class="flag flag--high">↑ 偏高</span>
  </td>
</tr>
```

```css
.result__value { white-space: nowrap; font-variant-numeric: tabular-nums; }
.result__value .num  { font-size: 24px; font-weight: 600; }
.result__value .unit { font-size: 14px; color: var(--text-secondary); margin-left: 4px; }
.result--high .num { color: #c62828; }
.result__flag .flag { font-size: 14px; font-weight: 500; }
```

要点：

- 异常标记同时用**颜色 + 箭头符号 + 文字**（`↑ 偏高`），三通道
- 数值列右对齐，用 `tabular-nums`，让一列数字能竖向比较
- 参考范围单独一列，不要和数值挤在一起
- 表格在移动端**改成卡片式**（每项一个卡片），不要横向滚动

### 第 3 步：体征录入

```html
<div class="field">
  <label for="sbp">收缩压（高压）</label>
  <div class="field__input">
    <input id="sbp" inputmode="decimal" autocomplete="off"
           aria-describedby="sbp-hint sbp-error" aria-invalid="false">
    <span class="field__unit">mmHg</span>
  </div>
  <p id="sbp-hint">正常范围 90 – 140 mmHg</p>
  <p id="sbp-error" class="field__error" hidden></p>
</div>
```

校验逻辑：

```js
// 医学可能范围：超出则硬报错，不允许提交
const MEDICAL = { sbp: [50, 300], dbp: [30, 200] };
// 正常参考范围：超出只提示，用户确认后可继续
const NORMAL  = { sbp: [90, 140], dbp: [60, 90] };

function validate(key, raw) {
  const v = Number(raw);
  if (raw === "" || Number.isNaN(v)) return { level: "error", msg: "请输入数值" };
  const [lo, hi] = MEDICAL[key];
  if (v < lo || v > hi) return { level: "error", msg: `数值需在 ${lo} – ${hi} 之间` };
  const [nlo, nhi] = NORMAL[key];
  if (v < nlo || v > nhi) return { level: "warn", msg: `超出正常范围 ${nlo} – ${nhi}` };
  return { level: "ok" };
}
```

- `error` 阻止提交，`warn` 不阻止，但要用户在提交前确认一次
- 单位**紧跟在输入框右侧**，不要放在标签里（标签里写单位会被忽略）
- 输入框宽度按预期数字长度设定（血压 3 位 → 宽约 88px），
  过宽的输入框会让用户以为要填更多内容
- 提供「不知道怎么测」的帮助入口，链接到测量方法说明
### 第 4 步：用药页

- 药品名用**通用名 + 商品名**：`苯磺酸氨氯地平片（络活喜）`
- 剂量格式：`5 mg，每日 1 次，早餐后` —— 剂量、频次、时间三段齐全
- 过敏史红色卡片固定顶部，包含过敏原与反应类型（`青霉素 — 皮疹`）
- 药物相互作用提示要在**添加动作之前**出现，而不是保存之后
- 服药提醒的时间用 12 小时制 + `早/中/晚/睡前` 双写，避免理解偏差

### 第 5 步：适老模式

```css
.elder-mode { font-size: 22px; line-height: 1.8; }
.elder-mode .btn { min-height: 56px; font-size: 20px; padding-inline: 24px; }
.elder-mode .icon-btn::after { content: attr(data-label); margin-left: 8px; }
.elder-mode .secondary-entry { display: none; }  /* 一屏一个任务 */
```

- 开关放在「我的」页显眼位置，标签写 `大字模式`，不要写 `无障碍设置`
- 开启后**所有页面**生效，不要只在大字号页生效
- 与系统字号设置叠加时以较大者为准（用 `rem` 承接系统设置，
  适老模式在此基础上再放大）
- 适老模式下把底部 tab 从 5 个减到 3–4 个，每个 tab 图标下方必须有文字
### 第 6 步：隐私相关实现

```html
<dl class="kv">
  <dt>身份证号</dt>
  <dd>3301**********1234 <button class="reveal" aria-label="显示完整号码">显示</button></dd>
</dl>
```

- 脱敏规则：保留前 4 后 4（身份证）、前 3 后 4（手机号）
- 「显示」操作需要身份校验，且**10 秒后自动重新隐藏**
- 敏感报告列表页不显示项目名，只显示分类与时间
- 分享生成图片时默认打码，并允许用户勾选是否包含敏感项
- 前端不缓存敏感数据：用内存态而非 `localStorage`，路由离开时清空；
  响应头加 `Cache-Control: no-store`

## 检查清单

- [ ] 全站正文 ≥ 16px，无任何 12px 以下文字
- [ ] 正文行高 ≥ 1.6，正文对比度 ≥ 7:1（实测）
- [ ] 所有数值都带单位，且数值与单位不可换行分离
- [ ] 数值用 `tabular-nums`，一列数值可竖向比较
- [ ] 检验报告有参考范围列，异常值有三通道标记（色 + 箭头 + 文字）
- [ ] 录入做了格式/医学范围/正常范围三层校验
- [ ] 异常值不阻止提交，但要求二次确认
- [ ] 身份证、手机号默认脱敏，「显示」需校验且 10 秒后自动隐藏
- [ ] 敏感科室报告在列表页不显示项目名称
- [ ] 危急值在页面顶部汇总提示，不只标在表格行内
- [ ] 过敏史在用药页常驻显示，不随滚动消失；紧急状态不使用闪烁动画
- [ ] 适老模式下字号 ≥ 20px、热区 ≥ 56px、一屏一个任务，且开关全站生效
- [ ] 移动端报告表格改为卡片式，无横向滚动
- [ ] 正文用 `rem` 承载字号，响应系统字号设置

## 常见错误

| 错误做法 | 为什么错 | 正确做法 |
| --- | --- | --- |
| 正文用 14px 甚至 12px | 老年用户看不清，且医院强光下更糟 | 正文 ≥ 16px，适老 ≥ 20px |
| 用 `#999` 做次级文字 | 对比度不足 4.5:1，老年用户几乎看不到 | 次级色 ≥ `#5a5a5a`，对比度 ≥ 7:1 |
| 数值只写 `5.6` 不带单位 | 用户无法判断是血糖还是别的指标 | 数值与单位绑定，且不可换行分离 |
| 参考范围放在 tooltip 里 | 移动端 hover 不可用，用户看不到判断依据 | 参考范围独立成列常驻显示 |
| 异常值只用红色标记 | 色盲用户与老年用户无法分辨 | 颜色 + 箭头 + 文字三通道 |
| 异常值直接阻止提交 | 真实患者的高血压数据本就异常，等于拒绝记录 | 医学范围阻止，正常范围只提示并二次确认 |
| 切换血糖单位只改标签 | 数值未换算，患者会按错误数值用药 | 切单位必须同时换算数值 |
| 身份证号完整显示 | 隐私泄露，且是合规问题 | 默认脱敏，显示需校验且自动隐藏 |
| 敏感报告列表页显示项目名 | 旁人可见，泄露病情 | 列表只显示分类与时间 |
| 用闪烁动画提示危急值 | 可能诱发光敏性癫痫，老年用户也看不清 | 红色实底横幅 + 图标 + 文字，静态 |
| 适老模式只放大字号 | 热区仍很小，信息仍拥挤，等于没适配 | 字号 + 热区 + 减信息量 + 开关，四者同时 |
| 适老模式下仍有横向滑动 | 老年用户不会做横向手势 | 一律改纵向排列 |
| 正文字号写死 `px` | 不响应系统字号设置，用户调了没用 | 用 `rem` 承载正文字号 |

## 参考

- 需要细化数值校验的范围表、单位换算与危急值阈值时，读 `references/clinical-values.md`
- 需要设计适老化与无障碍的完整规范（含读屏、焦点、对比度实测）时，读 `references/elder-accessibility.md`
$md$,
  '[{"path":"ATTRIBUTION.md","size":484,"kind":"text"},{"path":"LICENSE","size":1074,"kind":"text"},{"path":"SKILL.md","size":13363,"kind":"text"},{"path":"references/clinical-values.md","size":5364,"kind":"text"},{"path":"references/elder-accessibility.md","size":7193,"kind":"text"}]'::jsonb, 5, 27478, 'b810454a0d9e14b218932cd73ad6f0cb9f572d39b4971973158dea59ba90dcd8',
  $b64$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$b64$,
  'published'
)
on conflict do nothing;

insert into public.skills
  (slug, name, description, category, tags, version, license, author,
   readme, files, file_count, total_bytes, hash, bundle_b64, status)
values (
  'saas-app-ui', 'saas-app-ui', '设计 SaaS 控制台时使用：首页该放什么、工作区与多租户切换、用量与计费展示、设置页信息架构、激活漏斗与审计权限的界面表达。', 'ui',
  array['业务场景', '控制台首页', '工作区切换', '用量计费', '激活漏斗', '审计日志']::text[], '1.0.0', 'MIT', 'Skill Hub',
  $md$---
name: "saas-app-ui"
description: "设计 SaaS 控制台时使用：首页该放什么、工作区与多租户切换、用量与计费展示、设置页信息架构、激活漏斗与审计权限的界面表达。"
version: "1.0.0"
license: "MIT"
author: "Skill Hub"
category: ui
tags: ["业务场景", "控制台首页", "工作区切换", "用量计费", "激活漏斗", "审计日志"]
---

# SaaS 产品界面

SaaS 控制台的用户有**两种完全不同的使用状态**：
「第一次来，不知道要干嘛」和「每天都在用，只想快点做完」。
首页要同时服务这两种人，所以它不能只是一个数据大盘。

另一个和普通后台的区别：SaaS 是**多租户**的。
用户可能属于 3 个组织、每个组织下有若干项目，
「我现在在哪个空间里操作」必须永远是清晰的。

## 何时使用

- 设计 SaaS 产品的控制台首页（Dashboard）
- 需要处理工作区 / 组织 / 项目的多层级切换
- 需要展示用量、配额、账单、订阅状态
- 需要设计设置页的信息架构
- 需要做新手引导与激活漏斗
- 企业客户提出 SSO、审计日志、权限管理诉求

## 核心规则

1. **控制台首页必须回答三个问题，按此顺序排布**：
   1. 「我现在处于什么状态」—— 用量、配额、待办、异常告警
   2. 「我接下来该做什么」—— 引导任务、最近使用的项目、快捷操作
   3. 「整体发生了什么」—— 趋势图表、近期活动

   顺序不能反。把图表放在最上面是「给老板看」的做法，
   但日常用户关心的是「有没有需要我处理的事」。

   **首页元素上限 6 个模块**。超过 6 个用户会开始忽略底部内容。

2. **工作区切换器固定在左上角，位置永不变化**：
   - 显示当前工作区：`Logo（20px）+ 名称（最多 16 字，超出省略）+ 下拉箭头`
   - 下拉内容分三段：最近使用的工作区（最多 5 个）、`查看全部`、`新建工作区`
   - 切换工作区后**必须整页刷新数据**，不能只换标题 ——
     混用两个工作区的数据是最严重的事故
   - 当前工作区名称在**所有页面的标题区重复出现**（如 `订单 · 云雀科技`），
     避免用户截图给同事时对方不知道是哪个组织的数据
   - 用 `⌘K` / `Ctrl+K` 命令面板也支持切换工作区

3. **用量与计费展示要「提前预警」，不能等到超额**：
   - 进度条三档状态：`< 70%` 中性色、`70–90%` 黄色、
     `≥ 90%` 红色 + 一行行动文案（`升级可获得 5 倍额度`）
   - 用量展示要带**周期和重置时间**：`本月已用 8.2 万 / 10 万次 · 11 月 1 日重置`
   - 只显示百分比不显示绝对值是不合格的 —— 用户需要知道还能用多少次
   - 计费页面**必须能下载发票**，这是企业客户的高频刚需
   - 超额处理要在**事前**说明：`超出后按 ¥0.01/次计费` 或 `超出后暂停服务`

4. **设置页按「变更对象」分组，不按功能分组**：
   - **个人设置**：头像、姓名、语言、时区、通知偏好
   - **工作区设置**：名称、Logo、域名、默认项目
   - **成员与权限**：成员列表、角色、邀请
   - **计费**：订阅、用量、发票、支付方式
   - **安全**：密码、两步验证、SSO、会话管理
   - **审计日志**：操作记录、导出
   - **集成**：Webhook、API Key、第三方应用

   前 3 组是所有人可见的，后面几组按角色隐藏（普通成员看不到计费）。
   **用左侧二级导航**而不是顶部 tab，因为设置项会持续增长。

5. **激活漏斗要在界面上「可见」**：
   - 定义 3–5 个关键动作（如 `创建项目` → `邀请同事` → `接入数据` → `发布`）
   - 首页顶部放一个 checklist 卡片，完成一项打勾并显示进度 `2/4`
   - **全部完成后自动隐藏**，不要永久占位
   - 每项要给**可直接执行的按钮**，不要只写「去创建项目」让用户自己找
   - 新手引导**不做全屏遮罩式 tour**：用户记不住 5 个步骤的蒙层提示，
     且遮罩会阻断操作。用 checklist + 空态引导代替

6. **企业客户的权限与审计诉求，要在界面上有具体落点**：
   - **角色可见**：成员列表每行显示角色（`管理员`/`编辑者`/`只读`），可筛选
   - **权限可解释**：每个角色旁提供「这个角色能做什么」的说明浮层，
     列出 3–5 条具体权限，不要只写角色名
   - **操作留痕**：关键操作（删除、导出、改权限、改计费）记录到审计日志，
     日志行含 `时间 / 操作人 / IP / 对象 / 结果`
   - **审计可导出**：支持 CSV 导出与时间范围筛选，至少保留 90 天
   - **SSO 入口**：安全设置里显式列出 `SAML / OIDC / SCIM`，
     即使未开通也要显示并给出开通路径
   - **数据位置**：企业客户会问「数据存在哪」，设置里给出区域信息

7. **空态必须给「下一步动作」，而不是一句「暂无数据」**：
   | 场景 | 空态内容 |
   | --- | --- |
   | 无项目 | 一句话说明项目是什么 + `创建第一个项目` 按钮 + 示例模板入口 |
   | 无成员 | `邀请同事一起协作` + 邮箱输入框 + 复制邀请链接 |
   | 无数据（图表） | 说明需要什么前置动作，并给跳转按钮 |
   | 搜索无结果 | 保留搜索词 + 建议放宽条件 + `清除筛选` |
   | 权限不足 | 说明需要什么角色 + `联系管理员`（可复制管理员邮箱） |

## 怎么做

### 第 1 步：搭骨架

顶栏 56px：`[Logo] 工作区 ▾ │ 搜索 ⌘K │ 通知 ? 头像`。
侧栏 240px（折叠 64px）：上半区业务菜单（概览 / 项目 / 数据 / 成员），
一条分隔线后是管理菜单（设置 / 计费）。
内容区左上角是页面标题 + 工作区 chip，其下依次是激活清单、用量卡片、待办、最近项目。

- 侧栏导航分两组，用分隔线 + `设置` 分组标题隔开
- 侧栏底部固定「用量迷你条」+「升级」入口（免费/低档用户才显示）

### 第 2 步：首页模块

```html
<section class="dash">
  <header class="dash__head">
    <h1>概览</h1>
    <span class="ws-chip">云雀科技</span>
  </header>

  <!-- 1. 激活清单（全部完成即隐藏，服务端渲染时直接不输出该节点） -->
  <div class="onboard">
    <div class="onboard__bar"><span style="width:50%"></span></div>
    <p>已完成 2 / 4 步</p>
    <ul>
      <li class="done">创建项目</li>
      <li class="done">邀请同事</li>
      <li><a href="/integrations">接入数据源</a></li>
      <li><a href="/publish">发布第一个应用</a></li>
    </ul>
  </div>

  <!-- 2. 用量 -->
  <div class="usage">
    <p class="usage__label">API 调用</p>
    <p class="usage__value">82,140 <span>/ 100,000 次</span></p>
    <div class="usage__bar usage__bar--warn"><span style="width:82%"></span></div>
    <p class="usage__meta">11 月 1 日重置 · 超出后按 ¥0.01/次计费</p>
  </div>
  <!-- 3. 待办 / 告警   4. 最近项目   5. 趋势图（可选） -->
</section>
```

用量条的三档用 class 控制（`--ok` 品牌色 / `--warn` 黄 / `--over` 红），
**不要用 JS 算颜色**，颜色属于样式层。

### 第 3 步：工作区切换

```html
<button class="ws-switch" aria-haspopup="listbox" aria-expanded="false">
  <img src="/ws/yunque.svg" alt="" width="20" height="20">
  <span class="ws-switch__name">云雀科技</span>
  <svg aria-hidden="true"><!-- chevron --></svg>
</button>
```

- 名称最长 16 个汉字，超出用 `text-overflow: ellipsis`
- 下拉项显示：Logo + 名称 + 角色（`管理员`）
- 切换时展示全屏 loading（约 300–600ms），**不要做局部替换** ——
  用户需要明确的「我换空间了」信号
- 切换后 URL 里的 workspace 段要更新，保证可分享

### 第 4 步：设置页信息架构

用二级导航（左侧 200px）+ 内容区（最大宽度 720px）：

```
设置
├── 个人资料 / 通知偏好
├── 工作区：基本信息 · 成员与权限 · 集成 · 数据与导出
├── 计费与用量
├── 安全：密码与两步验证 · 单点登录（SSO）· 会话管理
└── 审计日志
```

规则：

- 每个设置项采用**「标签 + 说明 + 控件 + 保存」**四段式：
  标签 14px 500 字重，说明 13px 次级色（写清影响范围），
  控件在右或下方，保存按钮**只在有变更时启用**（dirty 状态）
- 危险操作（删除工作区、转让所有权）单独放在页面最底部，
  用红色边框区块包起来，并要求**输入工作区名称**才能确认
- 设置项变更后给一次 toast 反馈，不要静默保存

### 第 5 步：成员与权限

```html
<table class="members">
  <thead><tr><th>成员</th><th>角色</th><th>最近活跃</th><th>操作</th></tr></thead>
  <tbody>
    <tr>
      <td><img src="…" width="32" height="32" alt=""> 李维<br><small>li@yunque.com</small></td>
      <td><span class="role role--admin">管理员</span></td>
      <td>2 小时前</td>
      <td><button aria-label="更多操作">···</button></td>
    </tr>
  </tbody>
</table>
```

- 角色用彩色 chip：管理员（品牌色）、编辑者（蓝）、只读（灰）
- 每个角色 chip 可点，弹出「该角色可做的事」清单
- 邀请流程：邮箱输入（支持逗号分隔多个）+ 角色选择 + 有效期（7/14/30 天）
- 邀请未接受的成员显示为「待接受」，可重发或撤销

### 第 6 步：审计日志

| 列 | 说明 |
| --- | --- |
| 时间 | `2026-10-12 14:32:08`，本地时区，带时区标识 |
| 操作人 | 头像 + 姓名 + 邮箱（hover 显示） |
| 操作 | `删除了项目「A 测试」`（动宾结构，含对象名） |
| IP | 完整 IP，等宽字体 |
| 结果 | `成功` / `失败`（失败要说明原因类别） |

- 支持按时间范围、操作人、操作类型筛选
- 支持导出 CSV，导出动作**本身也要被记录**
- 日志不可编辑、不可删除（这是审计的基本要求）
- 分页 50 条/页，提供「加载更多」而不是无限滚动（便于定位）

## 检查清单

- [ ] 首页 ≤ 6 个模块，且「状态与待办」在「图表」之前
- [ ] 当前工作区名称在顶栏、页面标题、切换器三处之一明确可见
- [ ] 切换工作区后数据整体刷新，不残留上一个空间的数据
- [ ] 用量展示同时有绝对值、配额、重置时间和超额计费规则
- [ ] 用量条在 70% / 90% 两个阈值切换颜色与文案
- [ ] 计费页可下载发票
- [ ] 设置页用二级导航，按「变更对象」分组而非按功能
- [ ] 无权限的设置项对普通成员隐藏，而非显示后报错
- [ ] 危险操作要求输入名称确认，且单独隔离在页面底部
- [ ] 激活 checklist 在全部完成后自动隐藏
- [ ] 空态都给出了可执行按钮，无「暂无数据」裸文案
- [ ] 成员列表每行显示角色，角色可解释具体权限
- [ ] 审计日志含时间/操作人/IP/对象/结果，可筛选可导出
- [ ] 设置项有 dirty 状态，未变更时保存按钮禁用；顶栏提供 `⌘K` 命令面板

## 常见错误

| 错误做法 | 为什么错 | 正确做法 |
| --- | --- | --- |
| 首页顶部放大图表 | 日常用户想看的是「有没有事要我处理」，图表是给老板看的 | 状态与待办置顶，图表下移 |
| 首页堆 10 个卡片 | 超过 6 个后底部模块几乎无人点击 | 砍到 6 个以内，其余进子页面 |
| 工作区切换只改标题不刷新数据 | 用户会把 A 组织的数据当成 B 组织的，造成误操作 | 切换后整页刷新 + 全屏 loading |
| 工作区名称在内容区不出现 | 用户截图给同事时无法判断数据属于哪个组织 | 页面标题区重复显示工作区名 |
| 用量只显示百分比 | 用户不知道还能用多少次，无法判断是否要升级 | 绝对值 + 配额 + 重置时间 |
| 超额后才发现要收费 | 产生账单争议，企业客户尤其敏感 | 事前在用量卡里写清超额计费规则 |
| 设置页用顶部 tab | 设置项增长后 tab 会溢出换行 | 用左侧二级导航，可无限扩展 |
| 无权限项显示后点进去报 403 | 用户以为系统坏了 | 直接隐藏，或显示为灰色并说明所需角色 |
| 全屏遮罩式新手引导 | 用户记不住步骤，且遮罩阻断操作，多数人会直接关掉 | checklist + 空态引导 |
| 引导清单完成后一直挂着 | 长期用户被无关内容占据首屏 | 全部完成自动隐藏 |
| 空态只写「暂无数据」 | 用户不知道下一步做什么，直接卡住 | 给按钮 + 说明 + 示例入口 |
| 审计日志可被删除 | 失去审计意义，企业合规不通过 | 只读、不可删，仅支持导出 |
| 删除工作区用一个确认弹窗 | 误删代价极高，弹窗点击成本太低 | 要求输入工作区名称确认 |

## 参考

- 需要设计激活漏斗、引导与留存埋点位置时，读 `references/activation-funnel.md`
- 需要细化多租户、成员角色与审计日志的界面与数据结构时，读 `references/tenancy-and-audit.md`
$md$,
  '[{"path":"ATTRIBUTION.md","size":484,"kind":"text"},{"path":"LICENSE","size":1074,"kind":"text"},{"path":"SKILL.md","size":13346,"kind":"text"},{"path":"references/activation-funnel.md","size":5584,"kind":"text"},{"path":"references/tenancy-and-audit.md","size":7554,"kind":"text"}]'::jsonb, 5, 28042, 'f295eb39f146545459dd0a801dd3ae464d5121119fc048c858670e602f2f835f',
  $b64$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$b64$,
  'published'
)
on conflict do nothing;
