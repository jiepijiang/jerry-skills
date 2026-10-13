-- ============================================================================
-- UI 技能包入库 · PC 桌面端 Web（6 个）
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
  'frontend-design', 'frontend-design', '前端界面设计指导：为新建或改造 UI 提供有辨识度的视觉方向，涵盖配色、排版与布局的取舍，专门避开「一眼就是 AI 生成」的模板化审美。', 'ui',
  array['前端', 'UI设计', '视觉方向', '排版', '配色', '设计感', '反模板']::text[], '1.0.0', 'Apache-2.0', 'Anthropic',
  $md$---
name: "frontend-design"
description: "前端界面设计指导：为新建或改造 UI 提供有辨识度的视觉方向，涵盖配色、排版与布局的取舍，专门避开「一眼就是 AI 生成」的模板化审美。"
version: "1.0.0"
license: "Apache-2.0"
author: "Anthropic"
category: ui
tags: ["前端", "UI设计", "视觉方向", "排版", "配色", "设计感", "反模板"]
---

# Frontend Design

Approach this as the design lead at a design studio known for giving every client a distinct visual identity that is not mistaken for anyone else's. This client has already rejected proposals that felt cliché or templated, and is paying for a distinctive point of view: make deliberate, opinionated choices about palette, typography, and layout that are specific to this brief, and take aesthetic risk if justified.

## Ground your designs in the subject matter

If the brief does not identify what the product or subject matter is, identify it yourself before designing, and confirm with the client. You can come up with one concrete subject, the design's audience, and the design's primary job, as a proposal. If there's any information in your memory about the client's preferences or context about what they're building, use that as a hint. The subject's industry, subject matter, materials, and vernacular are where distinctive visual choices come from — a design for a toy for girls aged 8–11 will be very aesthetically different from a dashboard for financial analysts. Build with the brief's real content and subject matter throughout.

## Design principles

For web designs, the hero is the first thing viewers will see. Open with the most characteristic thing in the subject's world, in the form that is most appropriate: a headline, an image, an animation, a live demo, an interactive moment, or other treatments. Be deliberate with your choice: a big number with a small label, supporting stats, and a gradient accent is the default treatment, so only use it if that's truly the best option.

Typography carries the personality of the page. You don't need a different typeface for display or headline text and body content: use one family or two, and if two, make them clearly distinct.

Choose your typefaces deliberately, not the default families you would reach for on any other project, and set a clear type scale following the default guidance of The Elements of Typographic Style with intentional weights, widths, and spacing. When type is used as a headline or visual element, use the type treatment itself as an active part of the design, not a neutral delivery vehicle for the content.

Default to line lengths of less than 80 characters. Serif typefaces can have slightly longer line lengths; give serif body text slightly more line-height than a sans-serif.

Avoid these default typographic treatments; they are the commonest tells of a generated page:
- Accenting just a single word or phrase in a headline, like putting one word in italic/bold or a different color.
- Using all caps for labels.
- Adding unnecessary typographic labels above content.

Visual structure is information. Structural devices like outlines, borders, numbering, eyebrows, dividers, labels, etc., encode useful information about the content rather than decorate it. Many generic designs use numbered markers (01 / 02 / 03), but that's only appropriate if the content actually is a sequence — like a stepped process or a timeline. Before adding numbered markers, check the content really is a sequence.

Use non-user-triggered motion sparingly and deliberately, only to draw attention. A single orchestrated moment — one page-load sequence or one reveal — lands better than scattered effects; fade-and-slide-up entrances on each section and hover transitions on every card are the generic default and read as AI-generated. Motion that answers a person's action (opening, expanding, confirming) is welcome when it shows what changed.

Consider written content carefully. Often a design brief may not contain real content, and it's up to you to come up with copy and placeholder content. Copy can make a design feel as templated as the design itself. See the below section on writing for more guidance.

## Process: plan, review against the brief, build, critique

For calibration, AI-generated design right now clusters around some traits:
1. a warm cream background (near #F4F1EA) with a high-contrast serif display and a terracotta or warm-clay accent (often near #D97757 — Anthropic's own Claude-interaction accent, so on a user's brief it reads as a tell);
2. a near-black background with a single bright acid-green or vermilion accent;
3. a broadsheet-style layout with hairline rules, zero border-radius, and dense newspaper-like columns;
4. the SaaS-card kit: content chopped into identical rounded cards, one border-radius on everything regardless of hierarchy, the same soft grey shadow (rgba(0,0,0,.1)) under each, and gradient washes as decoration;
5. template chrome that appears whatever the subject: a tracked-out ALL-CAPS eyebrow label above every heading; meta strings joined with middle dots ('A · B · C'); labels built as 'WORD — fragment' with a spaced em dash; tinted near-black (#0B0B0B, #111) standing in for black; a monospace face for small data labels; a '→' appended to link and button text.

All traits are legitimate for some briefs, but they are defaults rather than choices, and they appear regardless of subject. Where the brief pins down a visual direction, follow it exactly — the brief's own words always win, including when it asks for one of these looks. Where it leaves an axis free, don't spend that freedom on one of these defaults. As with a hired human designer, there's often a careful balance between doing what you're good at and taking each project as a chance to experiment and learn.

Work in two passes. First, brainstorm a short design plan based on the client's design brief: create a compact token system with color, type, layout, and principles.
- Color: describe the core base palette as 4–6 named hex values.
- Type: the typefaces and their roles.
- Layout: a layout concept, using one-sentence prose descriptions and ASCII wireframes to ideate and compare. Include alignment guidance; should the content be left aligned, center aligned, justified?
- Principles: the high-level guidance for what makes this page unique.

Then review that plan against the brief before building: if any part of it reads like the generic default you would produce for any similar page (work through a similar prompt to see if you arrive somewhere similar) rather than a choice made for this specific brief — revise that part, say what you changed and why. Only after you've confirmed the relative uniqueness of your design plan should you start to write the code, following the revised plan.

When writing the code, be careful of structuring your CSS selector specificities. It's easy to generate CSS classes that cancel each other out (especially with a type-based selector like .section and an element-based selector like .cta). This can happen often with padding/margin between sections.

## Restraint and self-critique

Spend your boldness in one place. Let one element be the memorable thing, keep everything around it quiet and disciplined, and cut any decoration that does not serve the brief. Build to a quality floor without announcing it: responsive down to mobile, visible keyboard focus, reduced motion respected, visually accessible, harmonious color palettes. Critique your own work as you build, taking screenshots to review if your environment supports it — a picture is worth 1000 tokens. Consider Chanel's advice: before leaving the house, take a look in the mirror and remove one accessory. Human creatives have memory and always try to do something new, so if you have a space to quickly jot down notes about what you've tried, it can help you in future passes.

## More on writing in design

Words appear in a design for one reason: to make it easier to understand and use. They are design content, not decoration. Bring the same intentionality and minimalism to copywriting that you would bring to spacing and color. Before writing anything, ask what the design needs to say, and how it can best be said to help the person navigate the experience.

Write from the end user's perspective. Name things by what users will understand in simple language, not by how the system is built. A user manages notifications, not webhook config. Describe what something is or does in plain terms rather than selling it. Being specific and legible to new users is always better than being clever.

Use active voice as default. A CTA says exactly what happens when it is used: "Save changes," not "Submit." An action keeps the same name through the whole flow, so the button that says "Publish" produces a toast that says "Published." The vocabulary of an interface is the signposting for someone navigating the product. Cohesion and consistency are how people learn their way around.

Treat failure and emptiness as moments for direction, not mood. Explain what went wrong and how to fix it, in the interface's voice rather than a person's. Errors don't apologize, and they are never vague about what happened. An empty screen is an invitation to act.

Keep the tone conversational: plain verbs, sentence case, no filler, with tone matched to the brand and the audience. Let each written element do exactly one job.
$md$,
  '[{"path":"ATTRIBUTION.md","size":936,"kind":"text"},{"path":"LICENSE","size":10174,"kind":"text"},{"path":"SKILL.md","size":9502,"kind":"text"}]'::jsonb, 3, 20612, '3a363ba367d275378bf1b306eb6935958117c48dd3165580fcaed5db39580e80',
  $b64$UEsDBBQAAAAIAAAAIQAfnrylnwIAAKgDAAAOAAAAQVRUUklCVVRJT04ubWRVUstO21AQ3fsrrsTOUpKWdtUdIBZREa0K3TsNbmIV4sg2lZBYJJCHHSBJBQ0kPFOgRCl5gASN86D/0nqunRW/0Ll2G0CKovG58zhz5owRenhOu0Wrk7cH11Dc4jh6cElzCWd9wPNWZ4vutRCwf5Qhfwz6Ps/f9zedwaUzGDjZOvQTrLa3Dd1txIfJG7irQ/qW5V5sOM0OFFpOK/knscZxq2RYNckqgUwamhgg4PP5EHD/8csr8pohHNW0uPoqEIhIWnT5gz8sLwVCMS2qyHEprAbUT9LiovqozvnZgrsU1gneU+CjIsc0MbbgWxBVKRIT3NwRJUyciIfCUdE37n/mPtmGTg/XEZ+S4yuKFIlqZOL/PPJ2cgqTuDGUyxMjWbG6GauXsEyd7piQq3Hccz/h+bnXwZkZ/9ICsSsp4lJYCmmaqDDdKk71HKuIEA5pYkRWVgQSIMJnUVElGflhvCiFxZgqunFoWYvKihtqoYgqoL4cIQTMW5rLEQG3CitSXHNLGYVMmep4xgYtZe/7ukcTj+chGGM96LtOtQZbVdvIWp0c3buzz7pIFNpXmOn8KludOjR2afPmvm+wo42zlWipDd+OmCtKWat3yzbRhYn5+XfByffzwTezuC2SM34ndvD3oLDzPUmv1jxV0V0eDqdtupcfVgpgMFs5N2025sXDGCLMBKemZ+emBXcOFErMZvljzxb0xLT3mzD4+o/fS1YI+smwfIbC8jwR/GgXvLasoIh2w4CWCXoGCl8g24V8D3f1rA2baXpdpQcGTRUs02C4u5zr1KdXpI1TT9JH1ySWuQHFPL4O12s4AOlYvXMo5KiRwKbDcgqujryOcJilB3XPI9id510XjVSCdA3zOM65SEJx01vO6mww94yUYKT+AlBLAwQUAAAACAAAACEAsLejHjoOAAC+JwAABwAAAExJQ0VOU0XVWltvG8cVfs+vGBAoIAE07aZJ26RPiiUnbB3JEKkaeRySQ3Lq3Z3t7K4o9tf3O+fMbUnaTh8rGIm42jlzrt+58Rv1tZ+bVq/3Rr23a9N05kvv/9P4zrpGfTt7M1V/182g/VF9++bNd589tO/79sfXrw+Hw0zzNTPnd68ruap7/Q0dXN49/rpQN/e36u3D/e18OX+4X6h3D4/qaXE3VY93Hx4fbp/e0uMpv3U7Xywf5z890RMm8MeZujVb29gezHUzfoafSZBoorq9ripVG92oHpL2xted0s1GrV2zkVNq67waOjNV3rTebYY1PZ4GUvTuxna9t6uBnivdqQ1daTZqdVQLw2936o+g792w26sflNvig8V7bj3UpulP+XL+jLG1a4/e7va9cofGeAWWcND2R6WHfu+8/Q/fF+hcOtHvda9w6c5rHGx2/FLQQ8GA2elK3THpMyaGhgRk7o3SEAxUIhdQA94NZBxeCAxa08nVUGjvXTVV2hNz/KFipqckDT0dmg2OrV1duyZQCi+qg+33QkcunKl3OER8tINvHTwmazUZPNpoEqhMWJROXdlrOeoOxk9hPg8rERMWNqffp6p3aq1hdHovUJE/sQa8qnWjd4aMR/d2w3ofGJuqw96w+LA+3wtF4USpmYMlbwKVKwtO2Dzd3rZEaWu30GZrPOzSq6vv3/wBL+A6B/WI4iOhoe96aJ1sADN500WKILkyDZSwtjDliHrBZzb5b26YqCucpd/85Lq0Ov6RTp7tZiBaXpX+EQiYF3BrO2IEfNe2IyAIfiZBwGY5c7UFblsjBBFe9amntd5sjfc4zn+lCKz1J7qidhsL0TRHVTSwbdbVwKpAEKrG9aqytaXbYcfObfsDuVfHF8IoG2g/xh4TCmTkBXioxP/W7gbPf4dZKlPAx8PqX3CFc9Z1c5RnMMdQcXxsvavxx/VeN+A6Bgi8ounoTSFPrkxPqvBxq7QS9TC56VjAQONETIRNCy43yjFzQcwdPAEy4PFI4BK9IOmzoDci1YXYrc3GatUf21Lsj85/OgOFAx4yx4xD5Gk5BGwTxUgBIKoLYtV6AyB51rbSqyrGf4FLMEXHDgh7iyvphAsR3aAGvJzgTTSFl3E3wUrfU25hDUVuA4krCGBedN3iZhwEtMPN5SC9edO2Bje/IJgqd7jOWrg13j5Di89GkUK6kUbIA+iOyzoI0gdKooPI+Ep3ZLyGQxF6AH14P7xHsIquYnNRLBz2FoGcwQDG6pEDEJnePCMUKTTwMlQT4kQZaNiJMwtQBDOX0RSIUZYzHTyFta9xmas4KHDM7myDW85tfo7HEacCKieLnqovaI+8OdiOyYes4U2tbYpP02rPnkJ6YTFq4011RBw0n1hxK3gL+UmjawPFidEtgMhv9ZqTRHT9kVLPmCLtGLfNVn9LUB5y/EWLn8ZACtnivqTAEHAxlyY+iNjIJuzDm1CJREokFXTDp/D3zzGffYsUAMh2uLqKsN0NK2BHAI9Yd7B3MefMXggFvohx/KysiFbmdPfFbFEWKoTKfD35+8pAmVuo4vPFy+/L9mqSZJoEWpLvEyzjkKkQgN4BjKdkhZVGRUIR5elcw8UHyhzRPhyuicEaXCkpivTUdzlYWP8IrS+looRd5R34l3kCIlr48g6Huh7UipSVSqHu2PWmTrmP3AY5dwAEotTgHBneEPNT5pNqJdVapdLJSSKMjLyg0DbpDTXuekBqB3m+sWa8DGUkOci0SE3mJSphLGv0R4jStXY9uKFD8NbafyLoC6BE1VEsuUxndw1jP1yRbMSKveiJBFaTe+hbqzJWZ5PzED6pr5PYMQK/WvKUCiR8rE8uVXswszLwJ5SMhpEcTJf35CDszL8H+A/0ANdx0Lekayp4i/ATIPp2pn6msoqufZvEj5WVWgySXIOvXmxmijArUdkgS2YRwCNBCHjmKo7rAhSHkBIVXmt6aCa6H6Cv2hyQOKdw9uYVW76DxPTxFaoev6PGyR111R9fbb3BJ4vC7tmtCcjPsnno/+jC2G3hBGIMyG/OkS7DeTuscBZahKO2lYajpyfgWVIttB3oS42X+rayzE9YzMXy2Y0X0jljixjoT4WBPsCO+O3/3zpXOGZaBBZyNXAulkhgsJOG6Fq1ImthPZTrILbXUBxVeZEh7qPdFsU9JwFTAX7lv0AU56nmgEYSDoRCOVSFDDNRMlKB2Cjeqtu2onbTNTA6a5mwK7C2rrSFvuXdQjhokYmU2k242SB6u057y9G59UCf2NEYG3NfGfhX3TXaYNewd3ADWKMiSVU9Hzs9EAWSDjdkW7AvRd6YuXDFgUwRc91Mzbdk/9QLdUAq8ulklN7uhAW9QzHVQTaAXGjcr3LCSrW1d133ihVGYqzdQPWTfIbltar0oRtsT6JWBgUNJQFoLDKfa4ITVPwSwHFOEMaR1LnVznQ49YlxEM4iVrQH9TScxKQUG3tiLJliMxoiJTYaOcZCyotVlWQHClGyXvQVaD0UbBs8jM6XtAtq1CduBAq+m6lH1OV5MjTjq2t9zMh2ikLAQXbgstH/WpXHJqGyEZcNADn2I6po8H8MCWIhNGqbJYV/BskIbkMrxArJrlUbI1beYnTjDpLfI3b9GPPslb4WSQd42o74Jfak34BZLUQk0CpL39Qd0s+ZoJrzw2kn8TdOo/HOVXGnDG5yKU19FPXvMtTx5EJoHzChg59I9xjdhFMylXLRpYkmte4U9iw40RnfvC5u9qZHgFERyG8XLTx3B+DoVLji4nRhdggYCm6YsiMsw94Nd/fAVKqb2JQFEfS7KdyCbDKCuMDPKaTST67cBD0jDWZu47igRZYhMUmdEnGe8t1IkvNUPVba5ppAK9k/NH5k6sn9w3L+9m6C4HuBP0LfFHbhDiq5i3vK6Cog4EKknGmW7VWQiq2nhg31hnvM7HR4fEGtBEpQgynVH0CNkUEEYRGQwb+u14LMZQ1f1Cs7G2hURsMBkXkKMuFIjlYURrj0x8imjjxmXWcNjbwqW+CybQswHzlZGdfjAZSy24wzlDJ3OQOe03e+dNLEfqj1iilX6A0uaInib2Qqgk90gGIsEPSbVyQkZgfBNg3N59AwU2FhNJrQJXcd3EuXbhi0UtibiwdppdOQDz1Ebl6pQhmzE2KLEUtkSIVjTBuYA9DvaJMOZPLkkQWVyHrQ0O+JBMIYaL+DIUqZuJ+i8cZmgzHYAACRsnXkMRFYpP+L5jzFNFZwHGJADReDiadV6JmkDvDDqf+JYj63t7iootxVcNnKw3opAE4GX4UpiEiQo2SZRnKWqtZRlXuhgs+jvQsrIyFT7IrgOefc0GsFGQKAy61IOZ1LocT06OpimpcZONtWjbJwqrpplsylNPnRaCyTOpWTTmBkkO+52QmbAOlVcxXYzdRTgyzasdHMCy5aW2p/mWKxIEnzjeNpFVkMs4ox1mdHV7nSpxtPBzlS6sHx8vT5f2nNQpnFbBYOIySkdA0UZuE8ZhR0KG1vOL+snDRlFLY7bu8ojTBr3YB0gNkw12kSBoVJwkVSXciAFFpMLdEOPR07/jFECHdkWNmsC4hn4E0K8Zh3eNkrnfYeYRfwZ0BhLEBgzmVZR28cIycqP+6D80aIFB8WalK+xDUGJrXw+VTR0NTL+Gea6YeP4Cn4sLwcnTZyHD0lt6keMxW0EOITSOgdbEIpnU2KxO9A+cjcQMuoO9YQMJgiNR00qT2bz8ZoinYL2eBCChBN/QX7ZwzOqHWipe1WfUT9Cb1gfxmCILFK81NqYLnzphYrwwBbkZuXPAWbZoOF2OeOQFjFamPDQ4PTFrV8m8aXI+Ni08gbv8nNQs0XE/XTzWK+iMr9OF/+8vC0VB9vHh9v7pfzu4XCHr5Yyz+8wwr+N/WP+f0tyh14FG2AX2g6SnEQm1PGlU0xJs0RxHPSUBzwUF1UxQ1RGUd5sbCcL9/jewD3D/ev5vfvHuf3P9/9ene/nKpf7x7f/gIub36av58vf2MXejdf3t8t5OsDN4HGh5tHGOzp/c2j+vD0+OFhcSfZVraFFW0WwH+LSy1vHXgzI13h2F1gOe9abGDgDSzwFt5Fr7D/ZcQt5qUybcTgtuZeJcK17RjZO4ftbWyTBdTDnpWnseWi9byZFd/76wyfo0rp0HurV5guk/PNKfMqlD/wXeJDaOAR+nlCr71Bp12MWuImCw6ErXQeGTRmV1lUX2tzPU3b7rxfKnF8+Kq/X0mhQDP9yq64oGPmdjSPSHuLeCUYX/fks0iRF+ND0HOUPmgoE01WQRu4OEwE2LS6xpR8NMOn0/ErAfnLAV2LNjYP2fA6AgqFrawSqICRmS4t5ALRiNA0cwPfNK6GqfkKmDvlatoanza6rE3ER8AYQi3OdMGYBa6WE4PCSBd24pErEruCdon4zjmMCjGKy7NDDEJ617Z4laxbt8gZWA5gRTHQ1xFoJ19thyYXN5wEL3wThLYA5LylPuRi08FxyA+pQD8dxAUaaZiuN1hu0qZANIFaGnEpSohfbgjkJQJ+mKmbNeUE0kJEXrr5JifqIig+7ql0H4fr6bLwi+u2WIWu9456PFqmU804WrbzzBV129YwngDqmEONEBIhWhmDBvTDHBt+Z2qsuFI8pu0tuXAQH4NtmUJx3fKaYIcqX1m1QB6Kl9Bf2YigqcH4Bd+DQSckrWRSGOuzIJzl42+0oIXJ25BUc4e1CA9xw2MC0gyjzC9XOnmLkhE9T4oKNwgzYeqZ4CSMzxTwEu+sm23SDdaBaFfkBCpjyYLj0bn2NSNRLK6TFnM4D/zVk7AtC5NjYDK6cmpWZYhK64QT0oA0KTayQCi7cEvSaSrmo3nL/S68MfEiDnyH77Qhr176Gtw3/wVQSwMEFAAAAAgAAAAhAH9r4IY5EgAAHiUAAAgAAABTS0lMTC5tZG2aX28c13nG7/dTHFAXkgAuLTpOnVIXBU1brVCnMUK7RlH0Ynb37O6YszObmVmumCumTV0LsGw3cdUif5C6F42LAnZSoK3jCg7QfBPbpKSrfIX8nvc9M7t0AtkSd/bMOe/f533e93A4HA7KbBEPws60rso2lpPhJDb5rNwZ8O+4zpdtXpV8fXH/weP//PjxP7399Kf/9uSjz5589MHl2/9w8fGj3z760ZeffHr58BcX//fp5VsPL9//1dPzfw2v3Q2X77735Wc/vvzJ/Sefffjk4zcvPv33xz/6/pOfv/nk5/cvH/7q4r1//O2jty//578f//jh079/8OT+f31x/r3Ld37w+P5bX37yzsUnf3fxy3PWX7z78MlbD1j55Sc/fPrPHz793q8vHp1/cc7H88c/eXTxi19e/svH4fBuePz+zy7feu+L8we8c/nhB5c//fXF2w8vPvrg8WfvfHH+tzuD01g3rsf+3q29WzuDIh/HspHeh8tsPI/DZ/U0W7XzqtbDsp3X1TIf7wzGWRtnVX12EFb5oM1mzUH462SNnd2w89pdt4Z+3tZOn10f/eQq2hq33fd/pg8X7z5waXf+ZiBXDK6FO8kN4UVzw2BwuFzWFSKGdp43IWv4Nwb3UShiNglZG7LuQdOuJnkVTspqXYZpVYdZfpqXsxAxwFkYF3ksbXXetHk5bsNp3qyyIuQTnuftGXuzG8eUVRsWLMpOou+TlWdVGUMsmni92QuvSpa03RyZsqJGlLNQxzfiuI2TgMzLqskKicuW01i0Wj+e/+Y/Atu1cbEsMOxkl50nOnGZnUlQO6uXLz+NYVnlHFJNkTWuD8ICkdC2yEexZoPdgJdKXKvNwnhe4VfEGVWrli2L2GpJe7asZnW2nJ/5cUV2pu9NsqyOoVnGcT7Nx6Gt3MqjOo9TXysThCw2WL1lRZ03JyGfhjdWSDjN42QPp10Lf1pXKxazbZ1c0YS8NFc1q5FsguDIUg8Gd6f22I4IkwppZWz3wPQsrCWUFmDByYr3MMjVLbDW7mZ93tqpTSymYRQxXxccWNM1GFflNK8XYZ23CqKY/LYX/qpahXFWsmARw2rpC+Rl3hjXse1lx4J9zF3HusRYLMcY1gy0/dWyzhcZkfZGNeJblvaBsBdc8Zr4UTRhHoRFI3wnU5npFnFBpiX3bUS1jeOUdzm1kUWQsI338J6t7Gx2dh3tR6u8mJjyqyYmH0uQOWGkwO21Yte8nODHmrC4auJd/RvrnPh1JUmfMhuviozo5Iy19LgSpSmRugA0k4Koi/D5+fub9PTobquzlJs1+ZHNCNxvfH7+w/19PFAUeFHHYYUu6LKiOOOwqRmAXNK2bJk181GV1RPba5qXWTlGYMTNirOmJUlfkCU2breIQ2kyFUENZTANyn0lvIR8q9kcw3psOxDJtRywLGIzGNzhxHUcdaHu8YFNKmWyfibgGrlEKa28BX5duSbGvfCtJajSy7WoWDqeZ3UGcpBfSjN/82oGIfq6qgsgIz1X/PSIZbtkwkoExXkHcjmYVOSlBWogMGf+U1bys+KOT6GQ9ybEnS/CKpJDDxf4sCT20bVS4IYWy7V6Jttug5DrYhHsAaDDR/kslKsFK/zrLDQLPAn4jGKhgFsuq5r4mQHaWZviLAvglLILXcZUKFPNM2yarcDQXgZ2qEhWIkNhDgoASrIFVmrrFY/N5YQQACld8eWrPQyS9jXR4FsvcQ74WQj/gVl7hKkcHyZVeb0NZSRGBctdDIKoCDQ2HygPAHNernuLA/DKTjQaVZSFFG2UUGQVwkyzRY6MqgRrszw1gKP1swE8QixI/pjVFvqeZ6hwNK8qtjBTdzI0W54oSGXB6bbJ7Cwpy1tE0IqcwIgUVMkO+AiM3MEEj8OdZUVUpTQZ7KjQkIhSuCiqtdy2fcZslU/IP5SbGsS8VEQLFPvcmZ24Pm7P2MPiQaEGhMvy5FI+mysG1vmknadYaCAmnLMXXp+TLiYCwYAFcYUBWmdr1EjwE/3YDvr4X2/1MUOYWJ3Q6+id6mtWW3nd4LibMMPrq7ZmV5nXEOk0ooPZQChhdUI64JcXu/CsSChEKmI5QxHtC2AYCSjDN25t0pwUOibZObb3okrRPEOippA1cHxRlTPcsr3jbTEalti7FlsWaf0r1A/W8sJwbjb1k8m9rGyG9hbSHp5WuRUurNQn1paXNol+28qKYb4rvFgQvoK2WIDdqEfGxtJiD9JD2hwMhuHQUlcxIpqg0/lZfq9Aa2y3nNeZklaCbTCqyAn85aq1F5UktpxFeUtyjp8ZVURuokddHo6roqr3OPI1HQENA9mzZWMeMqBp9OXhRAUxrMoyYuhGBXpbXV+oWoplNz79S48p6iM0ZIUFiL6too0D0zcWIqdW90wHKoc0IoxHaICvCSgDQqvK8SyO6mrNwwnc1L92CfiuHe/xdzmuJjCSJk5XcNMtnrBFDFL9wvAGzfLyJI4rg+OcQv9NpbW5Bg07Sqa0cFHwFkTlRHXpxq398Ey49az++tpNhE7UECQ1fN0qKg6ym9MJZUzEGjFzgvI7KzEUq/lmCZ61cbl0PizTu//afEFKlUDsC87YMnfQV0XbJV/i+OSqwlTvrx6Is16TZlU5RMN62Nb5jMTRRpXZDSiR8aUMwHIVLk1H8nZSZ2t6iQRKe+Gwi9qqRgqiwELci6JpqBBVxA+Lii6kV95ANSLnqXiGmYJD4dTi4slTQKk+sF8kksfKs2k2iUMWDkllfoKOck4tTJUbggF2w1ILA5SYE6wqyeR1roe+ytsckaIuZTch4Hmud9WrCAQP7w775CVi3FbOGMvGOAv81aqjOKuffaOCvHgg31uymf2YKDY/35Rn1rEwAghNVPaGZk68O0sFAME0dQ1HyKzwD+s6l9V7DyO+Ar84gyhN9UVPH71nWFBqBdBanwEP23wulVLFLhbEq6p5/HOF4o+rpQcCVXsc58AKUnR5H470rbDYCvGGusYItwTJu87tK62olxahutudhK7Wvcf4T2p2HZ6hdFcznWW+4glyIKGoQIQPtBFyjIbGJBN/VXrCajG5tiPknIxSmvMRfjRSt+3WTjwygmJAW0xFB5PNt96zNTINcYQCB4P9PTReZ/BKGqBsEUbZ+GTm626UYgLX7jx3Z/+lw5sdp5uz71C2A9FxtJWljg85oeMsSl7VtplSQ3sPx/at87sblfnYN3/xj59//uvPW9L0EwjBEM38UUHbFYc9QVUa2A6JCHKScp/VHiWEncLcJgYSoihu3h48K/V01HCE60+21es4quc8e8heEJDJcFZHBBTJiIR4sTn59uBr2g8055x5jO2wMXqT2mvbcZ7R5Kh+w0lVEb6rJsHLwlBMd5XIDu2sECyugSpSbmjwSXVbLcrm9uC5PYuA4yw7Hlp2n+SQyT5h5pVhLLahAbHGmHgIppeGArzAKQKlKwf3gOHNRh1nLDS2Qlmf55gZ4AMgrQVhRoadpzC9Gj7QzLMJoXSjno2yG7d29Wdv/+ZNKqxSSVjlWvVkfk2zprmEuKoVKax4e/B11ErphBK0dV2/ijqZOiY+SMLtLkitBcE2PomToax8+PLLw6PDV467uuq1NBVzx0NRDDS8TXtNEILkfGho0XFL8vsin6A5ZB/GeuP6Yfj//w0v6K+j6zdvd/RAeWet9PXXv/XtFy1Gp3U2Uzm43kcPlFWgvrDuFPKkcJ1sR9yNa7de0J/dcG1/f/+meh/DUPEcIYOtus1W8KzKtqMypD7D+6dJhhIuk9Zd//zNH1w3i5mznYCeeOsBlxKgQxBF+njX09xqQxFnAIjafN9bxrfMEW1xkuG8LxUO+uYtqpH6/H4CYixBKXw1ipLPjMKneuTZycyKUFBeZx13n+S1g+Vu6jGUwvEeuU59lrW3e3i9KXqoyds6O1NzzXs0SQWzGazZVZ6sOXEyqOh3kk+aFVV1AgF3oVhFj3Oq6ESae5SvKQkPO7POj9GYaagZHo8njB4Mzrd26wwEZZAcCRZV3OerhdEyIbCGKt34xyGP5sorHTAE5uNkKMJaWDMhNKUDh4IkGurMqsoHnT6Rs5GmGEHq2BzkVFvZhRCgNIPExlRs3odn1AC/XtUM74iIdQVzaZqIzHc0qcDlRAaFRhMFwpghcNtVDtUjJFTbZexgayi1XZaBI3UNqpgUWwJXzZCmpw3DGBIiVV7ous0jxfcNJj2ENsMV8fUjLTvQ9lQ5xkHO/zTbUtuQxprS+TnGRn8UNMDH2PFeOM2KlW9B08kUomsBvcFKsZoTpVU66WWTQZiSQFujv7i0DjK1IXRNglkMi7HN3f21gG95eHx09y764csaSWAFhsJmCxs/Yo0arnvXopOH9Gql+aZjALdlcfXl20QXvYsI4NpyDYpVcsi//nM/gv0TFHmlN6BrbXW5AP+KTW+uPLCgErMRebGx8wxiVIpJaEKitEnUw2LenP97JKQbtHajxgP1Beo3ul66L75Wxv4QDd3MInzO69JpjyanyIIkJtkNklz83yZyVp7TlxSLpbXbDNR0uvbTTEe9MVDmA8q0+uYV6FKeCLywAs7wVh5D9DNw11CAI0N0I1RpBtOAt3Rp2VFZc/J6LrZq3RK5XVvaejMpXixcxgZ1pNJJQrc3HaKB5NbQ3O2dgkFnUB6wKGqKPXaJMCF5ro5hXFIjtJbncmPHNzfvEFEd4gibU/eqNSbC0fEx1iyAE9WDZA72EErcVbrHrLFOqSOX9gZcTkDiVoI2j4k4gyYfKSmnbkTbzfq2hI9KyqGDSn+kxcredo+DLdJE5w+vHbfZze4uxoYnqoIJXe2gpTeWz9BPzsC9Dl/TGSCAmPe3rbnTJYuPvYrpcEOujw3/zT6aP5jP2Ml6P3UPe+Fl5mR+NWSSyso21dUoPxvBKoxe7YaTGOnpNnwr0W9S5TurXLM2scC8URKLmKS7C8ynpNiwJjd0f28C5SWg+szsht54KWNfH2pOqXc+hJU3srLkYE3WOPuA0GmW6sQ0BVZV5c1FNcoL4oWYyqXASTzrBu1j8VVKGwnbN9fawS697A2fB4ggN/b2Lm6pITN5BeM0/O8AnLA6SnZ2A6eiDnnxWWXqdFK9A3XxHbkBFUHIhFKe+nDO8jTn5tA8kEbLOMobdZrYvJ/gcACBsX/r1i2vT5Ki60SPyOhYqNedaJxz0OGc+EGXStiw0ZWaN4diEt04fpHXtWGYGuyF6KfCwi3Brc5e+DOjA1YmMXfjw77uykfh7lSG+xibR4BtIJkHC42B9TkJ6ezNRDe1lggan2D2N4gI8yKh0V8D9jxCgUKQ6ALBUpWSWSxtP5HPlVko0QJLjG9K963OlVUOU8YkxL2c89kcb+uGx8cfGWMDahHhJFOJy2UNTYWeWJtgzNf0xqB2MdXxTduob+gV5ZvwJ8ANsfqmZGuMrFjXfswhILZF3nA7otZ/ebbBwoTdXnpIGT3E0D5qTvVaI8VuMtW9SRKmPIZSbi4pk7C6H7CopEB44jLx6KxslxCgQpNp6Fq51TcXD9CX03wmONUzZ25pqPW6gb7dd9l3biv1uHpVSUcc7YW/kB1MOrqUVKC0Ll05bVkbT1ETYQmaSc1WdiEk+/KWBDajOl3TJbAaHs3BtBdeLFluoKO6YM7QYJO3uQnjWuLEqx3zei7MnLeZJJsgZk/dlgi6EAT4VOLQU19tLQBgAFDgJCdY5nel2bnszEAJQ5IUSU9NAz15tqdsI3ubgT2gm0aEaebP/JvEsW7U6Ii0PHqViZ+26HoOk95rilpRbyjSDQS/InGsHHQO0OzumCF2jlejBXLvML3o5mWCfR8UWbiKq/Z8Rk/XzJ/wMcXcEtyQPPVtZj1JtPPKakQ4z3c6smQjjUoTl99fxHBtx+5gTqtxNtKVrV1rdZd71k2mSzXFLpfT/VhKrlLypojs8izdxAsoaXi64oy3Gy6mCFXPWwXQMlYWXOo3EtXGK6nUiV8K+2ho80JYo11o/zlHVRVv+HDVG7atdtB+GYMGaC+8dM+jxlyztsECoO95awFccfN6Dz/1d6S9ziSNe/0qF+zGm+wt9FZTqrYvW4ICs/y7mzt+V7K0ccRpNqNmbaGrR4mGqDheKkFjrVxZZMryp1xiePmmMttV3p+LD1iDkn7lQL+jY2uywqaAaMCjEUnWdyBjWJDsgZZFoY7SL5G1AZ08Y2oDGGcDHbrqU/cbC85WjJ51U9eOtlBuusDXdvwCw97gd1BLAQIUABQAAAAIAAAAIQAfnrylnwIAAKgDAAAOAAAAAAAAAAAAAAAAAAAAAABBVFRSSUJVVElPTi5tZFBLAQIUABQAAAAIAAAAIQCwt6MeOg4AAL4nAAAHAAAAAAAAAAAAAAAAAMsCAABMSUNFTlNFUEsBAhQAFAAAAAgAAAAhAH9r4IY5EgAAHiUAAAgAAAAAAAAAAAAAAAAAKhEAAFNLSUxMLm1kUEsFBgAAAAADAAMApwAAAIkjAAAAAA==$b64$,
  'published'
)
on conflict do nothing;

insert into public.skills
  (slug, name, description, category, tags, version, license, author,
   readme, files, file_count, total_bytes, hash, bundle_b64, status)
values (
  'web-artifacts-builder', 'web-artifacts-builder', '用 React + Tailwind + shadcn/ui 构建多组件 Web 界面：脚手架初始化、组件开发、打包成单文件 HTML，适合需要状态管理与路由的复杂界面。', 'ui',
  array['React', 'Tailwind', 'shadcn', '组件', '单文件', '前端', '制品']::text[], '1.0.0', 'Apache-2.0', 'Anthropic',
  $md$---
name: "web-artifacts-builder"
description: "用 React + Tailwind + shadcn/ui 构建多组件 Web 界面：脚手架初始化、组件开发、打包成单文件 HTML，适合需要状态管理与路由的复杂界面。"
version: "1.0.0"
license: "Apache-2.0"
author: "Anthropic"
category: ui
tags: ["React", "Tailwind", "shadcn", "组件", "单文件", "前端", "制品"]
---

# Web Artifacts Builder

To build powerful frontend claude.ai artifacts, follow these steps:
1. Initialize the frontend repo using `scripts/init-artifact.sh`
2. Develop your artifact by editing the generated code
3. Bundle all code into a single HTML file using `scripts/bundle-artifact.sh`
4. Display artifact to user
5. (Optional) Test the artifact

**Stack**: React 18 + TypeScript + Vite + Parcel (bundling) + Tailwind CSS + shadcn/ui

## Design & Style Guidelines

VERY IMPORTANT: To avoid what is often referred to as "AI slop", avoid using excessive centered layouts, purple gradients, uniform rounded corners, and Inter font.

## Quick Start

### Step 1: Initialize Project

Run the initialization script to create a new React project:
```bash
bash scripts/init-artifact.sh <project-name>
cd <project-name>
```

This creates a fully configured project with:
- ✅ React + TypeScript (via Vite)
- ✅ Tailwind CSS 3.4.1 with shadcn/ui theming system
- ✅ Path aliases (`@/`) configured
- ✅ 40+ shadcn/ui components pre-installed
- ✅ All Radix UI dependencies included
- ✅ Parcel configured for bundling (via .parcelrc)
- ✅ Node 18+ compatibility (auto-detects and pins Vite version)

### Step 2: Develop Your Artifact

To build the artifact, edit the generated files. See **Common Development Tasks** below for guidance.

### Step 3: Bundle to Single HTML File

To bundle the React app into a single HTML artifact:
```bash
bash scripts/bundle-artifact.sh
```

This creates `bundle.html` - a self-contained artifact with all JavaScript, CSS, and dependencies inlined. This file can be directly shared in Claude conversations as an artifact.

**Requirements**: Your project must have an `index.html` in the root directory.

**What the script does**:
- Installs bundling dependencies (parcel, @parcel/config-default, parcel-resolver-tspaths, html-inline)
- Creates `.parcelrc` config with path alias support
- Builds with Parcel (no source maps)
- Inlines all assets into single HTML using html-inline

### Step 4: Share Artifact with User

Finally, share the bundled HTML file in conversation with the user so they can view it as an artifact.

### Step 5: Testing/Visualizing the Artifact (Optional)

Note: This is a completely optional step. Only perform if necessary or requested.

To test/visualize the artifact, use available tools (including other Skills or built-in tools like Playwright or Puppeteer). In general, avoid testing the artifact upfront as it adds latency between the request and when the finished artifact can be seen. Test later, after presenting the artifact, if requested or if issues arise.

## Reference

- **shadcn/ui components**: https://ui.shadcn.com/docs/components$md$,
  '[{"path":"ATTRIBUTION.md","size":942,"kind":"text"},{"path":"LICENSE","size":11345,"kind":"text"},{"path":"SKILL.md","size":3092,"kind":"text"},{"path":"scripts/bundle-artifact.sh","size":1517,"kind":"text"},{"path":"scripts/init-artifact.sh","size":9924,"kind":"text"},{"path":"scripts/shadcn-components.tar.gz","size":19967,"kind":"binary"}]'::jsonb, 6, 46787, '1d07094967111210da6f9a1b0d696d1e0aca55f388c3ca955029fa9f66c1ec20',
  $b64$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$b64$,
  'published'
)
on conflict do nothing;

insert into public.skills
  (slug, name, description, category, tags, version, license, author,
   readme, files, file_count, total_bytes, hash, bundle_b64, status)
values (
  'a11y-audit', 'a11y-audit', 'WCAG 2.2 A/AA 无障碍审计与修复：扫描 React / Next.js / Vue / Angular / Svelte / 原生 HTML 代码，检查对比度、语义与键盘可达性，生成合规报告并可接入 CI。', 'ui',
  array['无障碍', 'a11y', 'WCAG', '对比度', '键盘可达', '合规审计', 'CI']::text[], '1.0.0', 'MIT', 'Alireza Rezvani',
  $md$---
name: "a11y-audit"
description: "WCAG 2.2 A/AA 无障碍审计与修复：扫描 React / Next.js / Vue / Angular / Svelte / 原生 HTML 代码，检查对比度、语义与键盘可达性，生成合规报告并可接入 CI。"
version: "1.0.0"
license: "MIT"
author: "Alireza Rezvani"
category: ui
tags: ["无障碍", "a11y", "WCAG", "对比度", "键盘可达", "合规审计", "CI"]
---

# Accessibility Audit

WCAG 2.2 Accessibility Audit and Remediation Skill

## Description

The a11y-audit skill provides a complete accessibility audit pipeline for modern web applications. It implements a three-phase workflow -- Scan, Fix, Verify -- that identifies WCAG 2.2 Level A and AA violations, generates exact fix code per framework, and produces stakeholder-ready compliance reports.

For every violation it finds, it provides the precise before/after code fix tailored to your framework (React, Next.js, Vue, Angular, Svelte, or plain HTML).

**What this skill does:**

1. **Scans** your codebase for every WCAG 2.2 Level A and AA violation, categorized by severity (Critical, Major, Minor)
2. **Fixes** each violation with framework-specific before/after code patterns
3. **Verifies** that fixes resolve the original violations and introduces no regressions
4. **Reports** findings in a structured format suitable for developers, PMs, and compliance stakeholders
5. **Integrates** into CI/CD pipelines to prevent accessibility regressions

## Features

| Feature | Description |
|---------|-------------|
| **Full WCAG 2.2 Scan** | Checks all Level A and AA success criteria across your codebase |
| **Framework Detection** | Auto-detects React, Next.js, Vue, Angular, Svelte, or plain HTML |
| **Severity Classification** | Categorizes each violation as Critical, Major, or Minor |
| **Fix Code Generation** | Produces before/after code diffs for every issue |
| **Color Contrast Checker** | Validates foreground/background pairs against AA and AAA ratios |
| **Compliance Reporting** | Generates stakeholder reports with pass/fail summaries |
| **CI/CD Integration** | GitHub Actions, GitLab CI, Azure DevOps pipeline configs |
| **Keyboard Navigation Audit** | Detects missing focus management and tab order issues |
| **ARIA Validation** | Checks for incorrect, redundant, or missing ARIA attributes |

### Severity Definitions

| Severity | Definition | Example | SLA |
|----------|-----------|---------|-----|
| **Critical** | Blocks access for entire user groups | Missing alt text, no keyboard access to navigation | Fix before release |
| **Major** | Significant barrier that degrades experience | Insufficient color contrast, missing form labels | Fix within current sprint |
| **Minor** | Usability issue that causes friction | Redundant ARIA roles, suboptimal heading hierarchy | Fix within next 2 sprints |

## Usage

### Quick Start

```bash
# Scan entire project
python scripts/a11y_scanner.py /path/to/project

# Scan with JSON output for tooling
python scripts/a11y_scanner.py /path/to/project --json

# Check color contrast for specific values
python scripts/contrast_checker.py --fg "#777777" --bg "#ffffff"

# Check contrast across a CSS/Tailwind file
python scripts/contrast_checker.py --file /path/to/styles.css
```

### Slash Command

```
/a11y-audit                    # Audit current project
/a11y-audit --scope src/       # Audit specific directory
/a11y-audit --fix              # Audit and auto-apply fixes
/a11y-audit --report           # Generate stakeholder report
/a11y-audit --ci               # Output CI-compatible results
```

### Three-Phase Workflow

**Phase 1: Scan** -- Walk the source tree, detect framework, apply rule set.

```bash
python scripts/a11y_scanner.py /path/to/project --format table
```

**Phase 2: Fix** -- Apply framework-specific fixes for each violation.

> See [references/framework-a11y-patterns.md](references/framework-a11y-patterns.md) for the complete fix patterns catalog.

**Phase 3: Verify** -- Re-run the scanner to confirm fixes and check for regressions.

```bash
python scripts/a11y_scanner.py /path/to/project --baseline audit-baseline.json
```

## Example: React Component Audit

```tsx
// BEFORE: src/components/ProductCard.tsx
function ProductCard({ product }) {
  return (
    <div onClick={() => navigate(`/product/${product.id}`)}>
      <img src={product.image} />
      <div style={{ color: '#aaa', fontSize: '12px' }}>{product.name}</div>
      <span style={{ color: '#999' }}>${product.price}</span>
    </div>
  );
}
```

| # | WCAG | Severity | Issue |
|---|------|----------|-------|
| 1 | 1.1.1 | Critical | `<img>` missing `alt` attribute |
| 2 | 2.1.1 | Critical | `<div onClick>` not keyboard accessible |
| 3 | 1.4.3 | Major | Color `#aaa` on white fails contrast (2.32:1, needs 4.5:1) |
| 4 | 1.4.3 | Major | Color `#999` on white fails contrast (2.85:1, needs 4.5:1) |
| 5 | 4.1.2 | Major | Interactive element missing role and accessible name |

```tsx
// AFTER: src/components/ProductCard.tsx
function ProductCard({ product }) {
  return (
    <a href={`/product/${product.id}`} className="product-card"
       aria-label={`View ${product.name} - $${product.price}`}>
      <img src={product.image} alt={product.imageAlt || product.name} />
      <div style={{ color: '#595959', fontSize: '12px' }}>{product.name}</div>
      <span style={{ color: '#767676' }}>${product.price}</span>
    </a>
  );
}
```

> See [references/examples-by-framework.md](references/examples-by-framework.md) for Vue, Angular, Next.js, and Svelte examples.

## Tools Reference

### a11y_scanner.py

```
Usage: python scripts/a11y_scanner.py <path> [options]

Options:
  --json                  Output results as JSON
  --format {table,csv}    Output format (default: table)
  --severity {critical,major,minor}  Filter by minimum severity
  --framework {react,vue,angular,svelte,html,auto}  Force framework (default: auto)
  --baseline FILE         Compare against previous scan results
  --report                Generate stakeholder report
  --output FILE           Write results to file
  --quiet                 Suppress output, exit code only
  --ci                    CI mode: non-zero exit on critical issues
```

### contrast_checker.py

```
Usage: python scripts/contrast_checker.py [options]

Options:
  --fg COLOR              Foreground color (hex)
  --bg COLOR              Background color (hex)
  --file FILE             Scan CSS file for color pairs
  --tailwind DIR          Scan directory for Tailwind color classes
  --json                  Output results as JSON
  --suggest               Suggest accessible alternatives for failures
  --level {aa,aaa}        Target conformance level (default: aa)
```

## Common Pitfalls

| Pitfall | Correct Approach |
|---------|------------------|
| `role="button"` on a `<div>` | Use native `<button>` -- includes keyboard handling for free |
| `tabindex="0"` on everything | Only interactive elements need focus; use native elements |
| `aria-label` on non-interactive elements | Use `aria-labelledby` pointing to visible text |
| `display: none` for screen reader hiding | Use `.sr-only` class instead |
| Color alone to convey meaning | Add icons, text labels, or patterns alongside color |
| Placeholder as only label | Always provide a visible `<label>` |
| `outline: none` without replacement | Always provide a visible focus indicator via `focus-visible` |
| Empty `alt=""` on informational images | Informational images need descriptive alt text |
| Skipping heading levels (h1 -> h3) | Heading levels must be sequential |
| `onClick` without `onKeyDown` | Add keyboard support or prefer native elements |
| Ignoring `prefers-reduced-motion` | Wrap animations in `@media (prefers-reduced-motion: no-preference)` |

## Related Skills

| Skill | Relationship |
|-------|-------------|
| **senior-frontend** | Frontend patterns used in a11y fixes |
| **code-reviewer** | Include a11y checks in code review workflows |
| **senior-qa** | Integration of a11y testing into QA processes |
| **playwright-pro** | Automated browser testing with accessibility assertions |
| **epic-design** | WCAG 2.1 AA compliant animations and scroll storytelling |
| **tdd-guide** | Test-driven development patterns for a11y test cases |

## Reference Documentation

| Reference | Description |
|-----------|-------------|
| [wcag-quick-ref.md](references/wcag-quick-ref.md) | WCAG 2.2 Level A & AA criteria quick reference |
| [wcag-22-new-criteria.md](references/wcag-22-new-criteria.md) | New WCAG 2.2 success criteria (Focus Appearance, Target Size, etc.) |
| [aria-patterns.md](references/aria-patterns.md) | ARIA patterns, keyboard interaction, and live regions |
| [framework-a11y-patterns.md](references/framework-a11y-patterns.md) | Framework-specific fix patterns (React, Vue, Angular, Svelte, HTML) |
| [color-contrast-guide.md](references/color-contrast-guide.md) | Color contrast checker details, Tailwind palette mapping, sr-only class |
| [ci-cd-integration.md](references/ci-cd-integration.md) | GitHub Actions, GitLab CI, Azure DevOps, pre-commit hook configs |
| [audit-report-template.md](references/audit-report-template.md) | Stakeholder-ready audit report template |
| [testing-checklist.md](references/testing-checklist.md) | Manual testing checklist (keyboard, screen reader, visual, forms) |
| [examples-by-framework.md](references/examples-by-framework.md) | Full audit examples for Vue, Angular, Next.js, and Svelte |

## Resources

- [WCAG 2.2 Specification](https://www.w3.org/TR/WCAG22/)
- [WAI-ARIA Authoring Practices 1.2](https://www.w3.org/WAI/ARIA/apg/)
- [Deque axe-core Rules](https://github.com/dequelabs/axe-core/blob/develop/doc/rule-descriptions.md)
- [eslint-plugin-jsx-a11y](https://github.com/jsx-eslint/eslint-plugin-jsx-a11y)
$md$,
  '[{"path":"ATTRIBUTION.md","size":974,"kind":"text"},{"path":"LICENSE","size":1072,"kind":"text"},{"path":"SKILL.md","size":9793,"kind":"text"},{"path":"assets/sample-component.tsx","size":1263,"kind":"text"},{"path":"expected_outputs/sample-contrast-output.txt","size":813,"kind":"text"},{"path":"expected_outputs/sample-scan-output.json","size":898,"kind":"text"},{"path":"expected_outputs/sample-scan-report.md","size":2213,"kind":"text"},{"path":"references/aria-patterns.md","size":6034,"kind":"text"},{"path":"references/audit-report-template.md","size":1280,"kind":"text"},{"path":"references/ci-cd-integration.md","size":3346,"kind":"text"},{"path":"references/color-contrast-guide.md","size":2521,"kind":"text"},{"path":"references/examples-by-framework.md","size":8159,"kind":"text"},{"path":"references/framework-a11y-patterns.md","size":14416,"kind":"text"},{"path":"references/testing-checklist.md","size":1790,"kind":"text"},{"path":"references/wcag-22-new-criteria.md","size":2201,"kind":"text"},{"path":"references/wcag-quick-ref.md","size":6528,"kind":"text"},{"path":"scripts/a11y_scanner.py","size":29650,"kind":"text"},{"path":"scripts/contrast_checker.py","size":16581,"kind":"text"}]'::jsonb, 18, 109532, 'ddd108d2e943b99c5b2737d58d9d1aeabed36e1b8ac05e4b60c9663b49e4e229',
  $b64$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$b64$,
  'published'
)
on conflict do nothing;

insert into public.skills
  (slug, name, description, category, tags, version, license, author,
   readme, files, file_count, total_bytes, hash, bundle_b64, status)
values (
  'senior-frontend', 'senior-frontend', '前端工程实践：React / Next.js / TypeScript / Tailwind 的组件模式、性能优化、打包体积分析与项目脚手架，内置多套框架 profile。', 'ui',
  array['React', 'Next.js', 'TypeScript', 'Tailwind', '性能优化', '打包体积', '脚手架']::text[], '1.0.0', 'MIT', 'Alireza Rezvani',
  $md$---
name: "senior-frontend"
description: "前端工程实践：React / Next.js / TypeScript / Tailwind 的组件模式、性能优化、打包体积分析与项目脚手架，内置多套框架 profile。"
version: "1.0.0"
license: "MIT"
author: "Alireza Rezvani"
category: ui
tags: ["React", "Next.js", "TypeScript", "Tailwind", "性能优化", "打包体积", "脚手架"]
---

# Senior Frontend

Frontend development patterns, performance optimization, and automation tools for React/Next.js applications.

## Table of Contents

- [Project Scaffolding](#project-scaffolding)
- [Component Generation](#component-generation)
- [Bundle Analysis](#bundle-analysis)
- [React Patterns](#react-patterns)
- [Next.js Optimization](#nextjs-optimization)
- [Accessibility and Testing](#accessibility-and-testing)

---

## Project Scaffolding

Generate a new Next.js or React project with TypeScript, Tailwind CSS, and best practice configurations.

### Workflow: Create New Frontend Project

1. Run the scaffolder with your project name and template:
   ```bash
   python scripts/frontend_scaffolder.py my-app --template nextjs
   ```

2. Add optional features (auth, api, forms, testing, storybook):
   ```bash
   python scripts/frontend_scaffolder.py dashboard --template nextjs --features auth,api
   ```

3. Navigate to the project and install dependencies:
   ```bash
   cd my-app && npm install
   ```

4. Start the development server:
   ```bash
   npm run dev
   ```

### Scaffolder Options

| Option | Description |
|--------|-------------|
| `--template nextjs` | Next.js 14+ with App Router and Server Components |
| `--template react` | React + Vite with TypeScript |
| `--features auth` | Add NextAuth.js authentication |
| `--features api` | Add React Query + API client |
| `--features forms` | Add React Hook Form + Zod validation |
| `--features testing` | Add Vitest + Testing Library |
| `--dry-run` | Preview files without creating them |

### Generated Structure (Next.js)

```
my-app/
├── app/
│   ├── layout.tsx        # Root layout with fonts
│   ├── page.tsx          # Home page
│   ├── globals.css       # Tailwind + CSS variables
│   └── api/health/route.ts
├── components/
│   ├── ui/               # Button, Input, Card
│   └── layout/           # Header, Footer, Sidebar
├── hooks/                # useDebounce, useLocalStorage
├── lib/                  # utils (cn), constants
├── types/                # TypeScript interfaces
├── tailwind.config.ts
├── next.config.js
└── package.json
```

---

## Component Generation

Generate React components with TypeScript, tests, and Storybook stories.

### Workflow: Create a New Component

1. Generate a client component:
   ```bash
   python scripts/component_generator.py Button --dir src/components/ui
   ```

2. Generate a server component:
   ```bash
   python scripts/component_generator.py ProductCard --type server
   ```

3. Generate with test and story files:
   ```bash
   python scripts/component_generator.py UserProfile --with-test --with-story
   ```

4. Generate a custom hook:
   ```bash
   python scripts/component_generator.py FormValidation --type hook
   ```

### Generator Options

| Option | Description |
|--------|-------------|
| `--type client` | Client component with 'use client' (default) |
| `--type server` | Async server component |
| `--type hook` | Custom React hook |
| `--with-test` | Include test file |
| `--with-story` | Include Storybook story |
| `--flat` | Create in output dir without subdirectory |
| `--dry-run` | Preview without creating files |

### Generated Component Example

```tsx
'use client';

import { useState } from 'react';
import { cn } from '@/lib/utils';

interface ButtonProps {
  className?: string;
  children?: React.ReactNode;
}

export function Button({ className, children }: ButtonProps) {
  return (
    <div className={cn('', className)}>
      {children}
    </div>
  );
}
```

---

## Bundle Analysis

Analyze package.json and project structure for bundle optimization opportunities.

### Workflow: Optimize Bundle Size

1. Run the analyzer on your project:
   ```bash
   python scripts/bundle_analyzer.py /path/to/project
   ```

2. Review the health score and issues:
   ```
   Bundle Health Score: 75/100 (C)

   HEAVY DEPENDENCIES:
     moment (290KB)
       Alternative: date-fns (12KB) or dayjs (2KB)

     lodash (71KB)
       Alternative: lodash-es with tree-shaking
   ```

3. Apply the recommended fixes by replacing heavy dependencies.

4. Re-run with verbose mode to check import patterns:
   ```bash
   python scripts/bundle_analyzer.py . --verbose
   ```

### Bundle Score Interpretation

| Score | Grade | Action |
|-------|-------|--------|
| 90-100 | A | Bundle is well-optimized |
| 80-89 | B | Minor optimizations available |
| 70-79 | C | Replace heavy dependencies |
| 60-69 | D | Multiple issues need attention |
| 0-59 | F | Critical bundle size problems |

### Heavy Dependencies Detected

The analyzer identifies these common heavy packages:

| Package | Size | Alternative |
|---------|------|-------------|
| moment | 290KB | date-fns (12KB) or dayjs (2KB) |
| lodash | 71KB | lodash-es with tree-shaking |
| axios | 14KB | Native fetch or ky (3KB) |
| jquery | 87KB | Native DOM APIs |
| @mui/material | Large | shadcn/ui or Radix UI |

---

## React Patterns

Reference: `references/react_patterns.md`

### Compound Components

Share state between related components:

```tsx
const Tabs = ({ children }) => {
  const [active, setActive] = useState(0);
  return (
    <TabsContext.Provider value={{ active, setActive }}>
      {children}
    </TabsContext.Provider>
  );
};

Tabs.List = TabList;
Tabs.Panel = TabPanel;

// Usage
<Tabs>
  <Tabs.List>
    <Tabs.Tab>One</Tabs.Tab>
    <Tabs.Tab>Two</Tabs.Tab>
  </Tabs.List>
  <Tabs.Panel>Content 1</Tabs.Panel>
  <Tabs.Panel>Content 2</Tabs.Panel>
</Tabs>
```

### Custom Hooks

Extract reusable logic:

```tsx
function useDebounce<T>(value: T, delay = 500): T {
  const [debouncedValue, setDebouncedValue] = useState(value);

  useEffect(() => {
    const timer = setTimeout(() => setDebouncedValue(value), delay);
    return () => clearTimeout(timer);
  }, [value, delay]);

  return debouncedValue;
}

// Usage
const debouncedSearch = useDebounce(searchTerm, 300);
```

### Render Props

Share rendering logic:

```tsx
function DataFetcher({ url, render }) {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetch(url).then(r => r.json()).then(setData).finally(() => setLoading(false));
  }, [url]);

  return render({ data, loading });
}

// Usage
<DataFetcher
  url="/api/users"
  render={({ data, loading }) =>
    loading ? <Spinner /> : <UserList users={data} />
  }
/>
```

---

## Next.js Optimization

Reference: `references/nextjs_optimization_guide.md`

### Server vs Client Components

Use Server Components by default. Add 'use client' only when you need:
- Event handlers (onClick, onChange)
- State (useState, useReducer)
- Effects (useEffect)
- Browser APIs

```tsx
// Server Component (default) - no 'use client'
async function ProductPage({ params }) {
  const product = await getProduct(params.id);  // Server-side fetch

  return (
    <div>
      <h1>{product.name}</h1>
      <AddToCartButton productId={product.id} />  {/* Client component */}
    </div>
  );
}

// Client Component
'use client';
function AddToCartButton({ productId }) {
  const [adding, setAdding] = useState(false);
  return <button onClick={() => addToCart(productId)}>Add</button>;
}
```

### Image Optimization

```tsx
import Image from 'next/image';

// Above the fold - load immediately
<Image
  src="/hero.jpg"
  alt="Hero"
  width={1200}
  height={600}
  priority
/>

// Responsive image with fill
<div className="relative aspect-video">
  <Image
    src="/product.jpg"
    alt="Product"
    fill
    sizes="(max-width: 768px) 100vw, 50vw"
    className="object-cover"
  />
</div>
```

### Data Fetching Patterns

```tsx
// Parallel fetching
async function Dashboard() {
  const [user, stats] = await Promise.all([
    getUser(),
    getStats()
  ]);
  return <div>...</div>;
}

// Streaming with Suspense
async function ProductPage({ params }) {
  return (
    <div>
      <ProductDetails id={params.id} />
      <Suspense fallback={<ReviewsSkeleton />}>
        <Reviews productId={params.id} />
      </Suspense>
    </div>
  );
}
```

---

## Accessibility and Testing

Reference: `references/frontend_best_practices.md`

### Accessibility Checklist

1. **Semantic HTML**: Use proper elements (`<button>`, `<nav>`, `<main>`)
2. **Keyboard Navigation**: All interactive elements focusable
3. **ARIA Labels**: Provide labels for icons and complex widgets
4. **Color Contrast**: Minimum 4.5:1 for normal text
5. **Focus Indicators**: Visible focus states

```tsx
// Accessible button
<button
  type="button"
  aria-label="Close dialog"
  onClick={onClose}
  className="focus-visible:ring-2 focus-visible:ring-blue-500"
>
  <XIcon aria-hidden="true" />
</button>

// Skip link for keyboard users
<a href="#main-content" className="sr-only focus:not-sr-only">
  Skip to main content
</a>
```

### Testing Strategy

```tsx
// Component test with React Testing Library
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';

test('button triggers action on click', async () => {
  const onClick = vi.fn();
  render(<Button onClick={onClick}>Click me</Button>);

  await userEvent.click(screen.getByRole('button'));
  expect(onClick).toHaveBeenCalledTimes(1);
});

// Test accessibility
test('dialog is accessible', async () => {
  render(<Dialog open={true} title="Confirm" />);

  expect(screen.getByRole('dialog')).toBeInTheDocument();
  expect(screen.getByRole('dialog')).toHaveAttribute('aria-labelledby');
});
```

---

## Quick Reference

### Common Next.js Config

```js
// next.config.js
const nextConfig = {
  images: {
    remotePatterns: [{ protocol: 'https', hostname: 'cdn.example.com' }],
    formats: ['image/avif', 'image/webp'],
  },
  experimental: {
    optimizePackageImports: ['lucide-react', '@heroicons/react'],
  },
};
```

### Tailwind CSS Utilities

```tsx
// Conditional classes with cn()
import { cn } from '@/lib/utils';

<button className={cn(
  'px-4 py-2 rounded',
  variant === 'primary' && 'bg-blue-500 text-white',
  disabled && 'opacity-50 cursor-not-allowed'
)} />
```

### TypeScript Patterns

```tsx
// Props with children
interface CardProps {
  className?: string;
  children: React.ReactNode;
}

// Generic component
interface ListProps<T> {
  items: T[];
  renderItem: (item: T) => React.ReactNode;
}

function List<T>({ items, renderItem }: ListProps<T>) {
  return <ul>{items.map(renderItem)}</ul>;
}
```

---

## Resources

- React Patterns: `references/react_patterns.md`
- Next.js Optimization: `references/nextjs_optimization_guide.md`
- Best Practices: `references/frontend_best_practices.md`
- Forcing-question library (Matt Pocock grill): `references/forcing_questions.md`
- Composition map (which specialist to fork into): `references/composition_map.md`

---

## Assumptions and Verifiable Success Criteria (Karpathy discipline)

Before this skill scaffolds a component, recommends a framework, or audits a bundle, the following four assumptions MUST be surfaced.

1. **Primary user device + network** — mobile-4G, desktop-fiber, low-end-Android, or corporate-network. Drives every perf decision.
2. **LCP target in milliseconds** — a single number, not "fast." Drives bundle budget and rendering choice.
3. **SEO-dependent vs. auth-walled** — drives rendering (SSR/SSG/RSC vs. SPA).
4. **WCAG target + named a11y owner** — AA, AAA, or best-effort. Drives a11y investment and CI gates.

**Verifiable success criteria** (Karpathy #4) — every recommendation must include:

- Core Web Vitals targets (LCP, INP, CLS) at p75 on the primary device
- A per-route JS bundle budget in KB-gzip
- A Lighthouse a11y floor + perf floor

If any of those three is not stated, the recommendation is incomplete — return to Q2 of the forcing-question library.

The `scripts/frontend_decision_engine.py` tool encodes these checks: it refuses to recommend a profile without the four assumption inputs and prints the verifiable thresholds for the matched profile.

---

## Customization profiles

Four built-in profiles in `profiles/` calibrate every recommendation:

| Profile | When to pick | LCP target (mobile-4G p75) | Bundle budget |
|---|---|---|---|
| `next-app-router` | SaaS customer-facing, SEO + dynamic, RSC-first | 2000ms | 150 KB-gzip / route |
| `remix-or-sveltekit` | Mobile-4G primary, low-JS-first, progressive enhancement | 1500ms | 80 KB-gzip / route |
| `vite-spa` | Auth-walled app, desktop/corporate primary | 2500ms | 200 KB init + 80 KB / route |
| `astro-or-static` | Marketing / docs / blog, near-zero write, SEO-critical | 1200ms | 30 KB JS / page |

Pick a profile via:

```bash
python scripts/frontend_decision_engine.py \
  --primary-device mobile-4g --lcp-target-ms 2000 \
  --seo-dependent true --auth-walled false --team-size 5
```

The tool returns the best-fit profile, the runner-up tradeoff (if within 15%), the stack picks, the anti-patterns to avoid on that profile, and the required CI gates.

To add a custom profile (e.g., your org's internal-tool defaults): copy `profiles/vite-spa.json` to `profiles/<your-org>.json` and adjust `constraints` + `success_thresholds`.

---

## Composition map

This skill does NOT reimplement scope owned by the POWERFUL-tier specialists. It forks into them. See `references/composition_map.md` for the full routing table. Key forks:

| Concern | Fork into |
|---|---|
| WCAG audit, contrast, screen-reader | `engineering-team/skills/a11y-audit/` |
| Bundle profiling + runtime perf | `engineering/skills/performance-profiler/` |
| Cinematic / scroll-storytelling landing | `engineering-team/skills/epic-design/` |
| Apple HIG (iOS / macOS / visionOS) | `product-team/skills/apple-hig-expert/` |
| Pre-commit Karpathy review | `engineering/karpathy-coder/` |
| Pre-flight architecture grill | `engineering/grill-me/` |

The `cs-frontend-engineer` agent orchestrates these forks via `context: fork`. Invoke it from another agent with `Agent({subagent_type: "cs-frontend-engineer", prompt: "..."})` or via `/cs:frontend-review <your problem>`.

---

## Forcing-question library (Matt Pocock grill)

Before locking any framework or rendering decision, walk the seven forcing questions in `references/forcing_questions.md`. Discipline:

1. One question per turn. No bundling.
2. Always recommend the answer with cited canon.
3. Track answers in `/tmp/frontend-grill-<date>.md`.
4. If a kill criterion trips, stop. Don't scaffold around an unresolved gap.
5. After Q7, run `frontend_decision_engine.py` with the seven answers.

Summary:

1. Primary device + network?
2. LCP target in ms (and INP, CLS)?
3. RSC / SPA / SSR / SSG — pick and defend?
4. JS bundle budget per route?
5. SEO-dependent or auth-walled?
6. Design-system source of truth?
7. WCAG target + named a11y owner?

---

## Invocation from other agents and skills

Three surfaces:

1. **Slash command:** `/cs:frontend-review <prompt>` — full grill + decision engine + composition routing.
2. **Agent subagent:** `Agent({subagent_type: "cs-frontend-engineer", prompt: "..."})` — forks context, returns ≤ 200-word digest.
3. **Direct tool call:** `python scripts/frontend_decision_engine.py ...` — deterministic profile match when inputs are known.

See `agents/engineering/cs-frontend-engineer.md` for the full invocation contract.
$md$,
  '[{"path":"ATTRIBUTION.md","size":968,"kind":"text"},{"path":"LICENSE","size":1072,"kind":"text"},{"path":"SKILL.md","size":15757,"kind":"text"},{"path":"profiles/astro-or-static.json","size":2571,"kind":"text"},{"path":"profiles/next-app-router.json","size":2540,"kind":"text"},{"path":"profiles/remix-or-sveltekit.json","size":2398,"kind":"text"},{"path":"profiles/vite-spa.json","size":2354,"kind":"text"},{"path":"references/composition_map.md","size":4312,"kind":"text"},{"path":"references/forcing_questions.md","size":8087,"kind":"text"},{"path":"references/frontend_best_practices.md","size":19783,"kind":"text"},{"path":"references/nextjs_optimization_guide.md","size":15123,"kind":"text"},{"path":"references/react_patterns.md","size":17341,"kind":"text"},{"path":"scripts/bundle_analyzer.py","size":13339,"kind":"text"},{"path":"scripts/component_generator.py","size":8684,"kind":"text"},{"path":"scripts/frontend_decision_engine.py","size":12338,"kind":"text"},{"path":"scripts/frontend_scaffolder.py","size":27981,"kind":"text"}]'::jsonb, 16, 154648, '6f32430603dfbf025f2007b7d29a024cfba522e0ad3dd929e1edea69aee87447',
  $b64$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$b64$,
  'published'
)
on conflict do nothing;

insert into public.skills
  (slug, name, description, category, tags, version, license, author,
   readme, files, file_count, total_bytes, hash, bundle_b64, status)
values (
  'data-dense-ui', 'data-dense-ui', '设计后台表格、日志、监控等高频查看的数据界面时使用：工具栏与过滤器的分工、行高三档取值、如何在大屏塞下更多有效信息。', 'ui',
  array['PC 桌面端', '数据表格', '信息密度', '行高刻度', '虚拟滚动', '详情面板']::text[], '1.0.0', 'MIT', 'Skill Hub',
  $md$---
name: "data-dense-ui"
description: "设计后台表格、日志、监控等高频查看的数据界面时使用：工具栏与过滤器的分工、行高三档取值、如何在大屏塞下更多有效信息。"
version: "1.0.0"
license: "MIT"
author: "Skill Hub"
category: ui
tags: ["PC 桌面端", "数据表格", "信息密度", "行高刻度", "虚拟滚动", "详情面板"]
---

# 高密度数据界面

数据界面的目标不是「好看」，是**让用户在一屏里完成一次判断**。
一屏能看到 17 行还是 8 行，直接决定用户要不要滚动、要不要来回翻页。
本技能给出可量化的密度标准。

## 何时使用

- 做后台列表页、订单/工单管理、日志检索、监控大盘、CRM 客户表
- 用户抱怨「一屏就 8 条，翻页翻到吐」
- 反过来：用户抱怨「字太小、眼睛疼、老是点错行」
- 要在表格右侧加详情面板，但不确定该多宽、该不该挡表格
- 表格里塞了 20 列，横向滚动条长得像一条高速公路

## 核心规则

1. **行高分三档，全站统一取一档**：
   - 紧凑 `32px`（字号 12px，行内 padding 上下 8px）—— 监控、日志、纯数值对比
   - 默认 `40px`（字号 13–14px，padding 上下 12px）—— 通用管理列表，**推荐默认值**
   - 宽松 `48px`（字号 14px，padding 上下 16px）—— 行内有按钮、标签、两行文本
   触屏场景（iPad、触屏笔记本）最小 `48px`，这是 Apple HIG 的最小触控目标高度。

2. **表头高度 = 行高 + 8px**，且必须比数据行**视觉更重**（背景 `#fafafa` 或字重 600）。
   表头与行同高同色时，用户滚动后会分不清表头是不是粘住了。

3. **一屏有效行数 ≥ 15 行**（1080p、浏览器全屏、默认行高 40px）。
   算不出来就说明你上面堆了太多东西：
   `1080 − 浏览器 chrome 120 − 顶栏 64 − 页面标题 56 − 工具栏 48 − 表头 48 − 分页 56 ≈ 688 → 17 行`。
   如果只算到 8 行，通常是因为页面标题占了两行、工具栏换了行、或者行高被写成了 56。

4. **列宽用「主列自适应 + 其余固定」**，主列（如名称/标题）设 `min-width: 200px` 且 `1fr`，
   其余列固定宽度。**所有列都写死 px 的表格，在 2560 屏上会出现一大片空白**。

5. **列数 > 10 时必须做列可见性控制**，默认只显示 6–8 列。
   全部铺开的结果是用户横向滚动 3 屏才找到自己要的那列，且滚回去时忘了行对应谁。

6. **详情面板宽度取 400 / 480 / 560 三档**，覆盖式（overlay）还是挤压式（push）取决于屏幕：
   `< 1440` 用覆盖（否则表格被压到只剩 3 列），`≥ 1440` 用挤压。
   覆盖式必须给背景加 `rgba(0,0,0,.4)` 遮罩或至少 1px 分隔线 + 阴影，否则用户看不出这是浮层。

7. **过滤器分两级**：顶部常驻的「高频 1–3 个」+ 「高级筛选」抽屉里的全部条件。
   把 12 个筛选项全铺在顶部，会把表格往下推 120px，等于每屏少 3 行。

## 怎么做

### 第 1 步：先画「垂直预算表」

在设计前把纵向空间算清楚，写进设计稿：

| 区块 | 高度 | 是否可折叠 |
| --- | --- | --- |
| 顶栏（全局） | 56 或 64 | 否 |
| 面包屑 / 页面标题 | 48（单行） | 否 |
| 工具栏（搜索 + 主操作） | 48 | 否 |
| 过滤器行（常驻 1–3 项） | 48 | 可 |
| 批量操作条 | 48（选中时才出现） | — |
| 表头 | 行高 + 8 | 否（吸顶） |
| 分页 | 56 | 否 |

把合计减掉，剩下的才是表格能用的高度。这个表能在评审时直接终结「能不能再加一行东西」的争论。

### 第 2 步：定义行高三档

```css
:root {
  --row-h-compact: 32px;
  --row-h-default: 40px;
  --row-h-comfort: 48px;
  --row-px: 16px;          /* 单元格左右内边距 */
}
[data-density="compact"] td { height: var(--row-h-compact); font-size: 12px; }
[data-density="default"] td { height: var(--row-h-default); font-size: 13px; }
[data-density="comfort"] td { height: var(--row-h-comfort); font-size: 14px; }
```

用 `data-density` 放在 `<table>` 或容器上切换，而不是给每个单元格写类名。
给用户一个密度切换开关（紧凑/默认/宽松三选一）并持久化到 `localStorage`，
这是投入产出比最高的一行代码。

**注意**：行高不要用 `padding` 撑，用 `height` + `vertical-align: middle` 或 flex。
用 padding 撑时，单元格里有换行文本会把整行顶高，导致行高参差不齐。

### 第 3 步：定列宽策略

```css
table { table-layout: fixed; width: 100%; }
th.col-name  { width: 28%; min-width: 200px; }  /* 主列 */
th.col-status{ width: 96px; }                    /* 状态标签 */
th.col-time  { width: 168px; }                   /* yyyy-MM-dd HH:mm:ss */
th.col-money { width: 120px; text-align: right; }/* 金额右对齐 */
th.col-ops   { width: 120px; }                   /* 操作列，固定右侧 */
```

- `table-layout: fixed` 让列宽可预测，配合 `text-overflow: ellipsis` 才生效。
- 数字列右对齐并加 `font-variant-numeric: tabular-nums`，否则数字宽度不一致、无法纵向比较。
- 时间列宽度按「最长可能值」定：`2026-10-12 19:04:33` 在 13px 字体下约 148px，留 168px 安全。
- 操作列 ≥ 2 个图标按钮时给 120px，只有「详情」时给 88px。
- 主列加 `overflow: hidden; text-overflow: ellipsis; white-space: nowrap` 并配 `title` 属性。

### 第 4 步：工具栏与过滤器的分工

**工具栏（常驻，48px）**放三样东西：
1. 搜索框（宽度 240–320px，`placeholder` 写清搜什么字段）
2. 主操作按钮（1 个，`primary` 样式）
3. 密度切换 + 列设置 + 刷新（图标按钮，靠右）

**过滤器**：
- 高频 1–3 个（如状态、时间范围）放在工具栏下一行，48px 高。
- 其余进「高级筛选」抽屉（宽度 400px，右侧滑出），抽屉底部固定「重置 / 查询」两个按钮。
- 筛选条件生效后，在工具栏下方显示「已选条件」标签行，每个标签可单独移除，最右一个「清空」。

这个「已选条件」行非常关键：没有它，用户过了三分钟就不知道列表为什么少了一半数据。

### 第 5 步：详情面板

```css
.detail-panel { width: 480px; flex: 0 0 480px; border-left: 1px solid #e5e5e5; }

/* <1440 改成覆盖 */
@media (max-width: 1439.98px) {
  .detail-panel {
    position: fixed; inset-block: 0; inset-inline-end: 0;
    width: min(480px, 92vw); z-index: 40;
    box-shadow: -8px 0 24px rgba(0,0,0,.12);
  }
}
```

- 面板内分区用 `8 / 16 / 24` 的间距刻度，标题 14px/600，正文 13px。
- 面板打开时**表格选中行要高亮**（背景 `#eef4ff` 或左侧 3px 主色条），否则用户不知道在看哪一行。
- 键盘：`Esc` 关闭面板，`↑/↓` 在表格中移动选中行。这是数据界面的基本功，不要漏。

### 第 6 步：大数据量渲染

| 数据量 | 方案 |
| --- | --- |
| < 200 行 | 直接渲染 + 客户端分页 |
| 200–2000 行 | 虚拟滚动（只渲染视口 ± 10 行） |
| > 2000 行 | 服务端分页，每页 20/50/100 三档 |
| 无限滚动 | 仅用于时间倒序的流式数据（日志、动态） |

虚拟滚动注意三点：① 行高必须固定（变高虚拟滚动需要测量，成本高一个量级）；
② 表头必须用独立的 `<div>` 而不是 `<thead>`，否则无法与滚动容器分离；
③ 键盘上下移动时要手动 `scrollIntoView({ block: 'nearest' })`。

## 检查清单

- [ ] 1080p 全屏下，表格区可见行数 ≥ 15（紧凑档 ≥ 20）
- [ ] 行高三档数值已定，且全站只用其中一档作为默认
- [ ] 表头视觉重量高于数据行，滚动时表头吸顶且不透明
- [ ] 列数 > 10 时提供列可见性设置，默认显示 ≤ 8 列
- [ ] 主列 `ellipsis` + `title`，长文本不撑破布局
- [ ] 金额/数量列右对齐，使用 `tabular-nums`
- [ ] 筛选生效后有「已选条件」标签行，可单个移除
- [ ] 详情面板打开时对应行有明确高亮
- [ ] `Esc` 可关闭面板/抽屉，`↑/↓` 可移动行选中
- [ ] 2000 行以上数据有虚拟滚动或服务端分页，滚动不掉帧
- [ ] 空状态有明确文案 + 主操作按钮，不是一片空白
- [ ] 加载中用骨架屏（延迟 200ms 出现），不用全屏转圈

## 常见错误

| 错误做法 | 为什么错 | 正确做法 |
| --- | --- | --- |
| 行高写 56px「显得透气」 | 一屏只剩 11 行，用户翻页次数翻倍 | 默认 40px，透气靠列间距不是行高 |
| 用 `padding` 撑行高 | 单元格有换行文本时整行被顶高，行高参差 | 用 `height` + 垂直居中 |
| 所有列宽写死 px | 2560 屏右侧出现大片空白 | 主列 `1fr` + `min-width`，其余固定 |
| 12 个筛选条件全铺在顶部 | 表格下移 120px，每屏少 3 行 | 高频 1–3 个常驻，其余进抽屉 |
| 筛选后不显示已选条件 | 用户不知道数据为什么变少，反复重置 | 工具栏下方显示可移除的条件标签 |
| 详情面板挤在 1280 屏上 | 表格被压到只剩 3 列，横向滚动 | < 1440 用覆盖式面板 |
| 打开详情面板不高亮行 | 用户失去「在看哪一行」的锚点 | 选中行加背景色或左侧主色条 |
| 表格数字左对齐 | 位数不同无法纵向比较大小 | 右对齐 + `tabular-nums` |
| 全屏 loading 遮罩 | 每次翻页屏幕闪一下，长时间使用很累 | 表格区域局部骨架屏，延迟 200ms |
| 虚拟滚动里用变高行 | 需要动态测量，滚动白屏与跳动 | 虚拟滚动强制固定行高 |

## 参考

- 需要完整的表格列宽、单元格对齐、排序/筛选/固定列的交互细则与虚拟滚动实现要点时，读 `references/table-specs.md`
- 需要处理「同一页面既要塞得下又要读得清」的取舍判据（字号下限、对比度、留白分配）时，读 `references/density-tradeoff.md`
$md$,
  '[{"path":"ATTRIBUTION.md","size":484,"kind":"text"},{"path":"LICENSE","size":1074,"kind":"text"},{"path":"SKILL.md","size":10060,"kind":"text"},{"path":"references/density-tradeoff.md","size":5527,"kind":"text"},{"path":"references/table-specs.md","size":5866,"kind":"text"}]'::jsonb, 5, 23011, 'cbbaaed4cc7318ca4aec1ffacedb5aaa6ba43687f8ff70442d3c827181e59b0b',
  $b64$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$b64$,
  'published'
)
on conflict do nothing;

insert into public.skills
  (slug, name, description, category, tags, version, license, author,
   readme, files, file_count, total_bytes, hash, bundle_b64, status)
values (
  'desktop-layout-system', 'desktop-layout-system', '需要为桌面端 Web 定下一套可执行的布局规范时使用：栅格、断点、间距刻度、内容最大宽度与超宽屏处理策略。', 'ui',
  array['PC 桌面端', '栅格系统', '断点策略', '间距刻度', '超宽屏', '容器宽度']::text[], '1.0.0', 'MIT', 'Skill Hub',
  $md$---
name: "desktop-layout-system"
description: "需要为桌面端 Web 定下一套可执行的布局规范时使用：栅格、断点、间距刻度、内容最大宽度与超宽屏处理策略。"
version: "1.0.0"
license: "MIT"
author: "Skill Hub"
category: ui
tags: ["PC 桌面端", "栅格系统", "断点策略", "间距刻度", "超宽屏", "容器宽度"]
---

# 桌面端 Web 布局系统

桌面端布局的核心矛盾不是「好不好看」，而是**同一套规则要在 1280 笔记本和 2560 外接屏上都成立**。
本技能给出一套可以直接抄进项目、并且能被 Code Review 检验的数值规范。

## 何时使用

- 用户说「帮我定一套布局规范」「全局 CSS 怎么写」
- 新项目要从零配置 Tailwind theme 或 CSS 变量
- 现有页面在 1920 宽下两侧留白各 400px、正文被拉成一整行
- 团队里有人写 `margin: 15px`、有人写 `margin: 1rem`，改一个地方崩三个页面
- 要评审一份设计稿：「这个 1440 的设计稿在 1024 上会怎样」

## 核心规则

1. **断点只留 5 个**：`0 / 640 / 1024 / 1280 / 1536`。多一个断点就多一套回归测试成本；
   实测桌面端真正需要区分的只有「窄笔记本(1280)」「宽笔记本(1440)」「外接屏(1920+)」三档。
   低于 1024 的一律按平板/移动处理，不要为 768 单独写桌面布局。

2. **间距刻度以 4px 为基准，只允许 10 个值**：
   `4 / 8 / 12 / 16 / 20 / 24 / 32 / 48 / 64 / 96`。
   禁止出现 15、18、22、30 这类数字 —— 它们和 8 的倍数不成关系，
   会导致 flex 换行时累计误差、以及设计稿标注无法整除。

3. **内容最大宽度分三档，按内容类型选，不按屏幕选**：
   - 阅读型（文章、文档、设置项）：`max-width: 720px`，正文 16px 时约 45 个汉字/行
   - 通用型（官网、营销页、表单页）：`max-width: 1200px`
   - 数据型（表格、看板、IDE 类工具）：**不设上限**，只保留左右各 32px 最小留白
   给数据型页面设 1440 上限是最常见的错误 —— 用户买 27 寸屏就是为了横向多看两列。

4. **栅格固定 12 列，列间距（gutter）24px**，页面左右外边距（padding）随断点走：
   `640–1023 → 24px`，`1024–1535 → 32px`，`≥1536 → 40px`。
   12 列能整除 2/3/4/6，8 列不行，16 列在小屏上列宽过窄。

5. **超宽屏（≥1920）不做「等比放大」**。三种正确做法：
   ① 数据型页面直接铺满；② 通用型页面用 `max-width` 居中 + 左右留白；
   ③ 内容型页面改成多栏（正文 + 目录侧栏）。错误做法是把 `font-size` 或 `zoom` 整体放大，
   那会让 2560 屏上只显示和 1440 一样多的信息。

6. **断点方向必须二选一并写进文档**。移动优先（`min-width`）适合 C 端产品，
   桌面优先（`max-width`）适合后台工具。混用两套方向是 CSS 里最难 debug 的坑之一 ——
   同一条规则可能被两个方向的媒体查询同时命中。

## 怎么做

### 第 1 步：先定内容宽度，再定栅格

不要先画 12 列。先回答「这个页面最重要的一行内容有多宽」：

```css
/* 通用型页面骨架 */
.page {
  max-width: 1200px;
  margin-inline: auto;
  padding-inline: 24px;   /* ≥1024 时提到 32px */
}
```

`padding-inline` / `margin-inline` 是逻辑属性，横竖屏与 RTL 都能正确工作，
比 `padding-left/right` 少一次适配成本。

### 第 2 步：把间距刻度写成变量

```css
:root {
  --space-1: 4px;  --space-2: 8px;  --space-3: 12px; --space-4: 16px;
  --space-5: 20px; --space-6: 24px; --space-8: 32px; --space-12: 48px;
  --space-16: 64px; --space-24: 96px;

  --radius-sm: 4px; --radius-md: 8px; --radius-lg: 12px;

  --bp-md: 640px;  --bp-lg: 1024px; --bp-xl: 1280px; --bp-2xl: 1536px;
}
```

变量名用刻度序号而不是像素值（`--space-4` 而非 `--space-16px`），
这样将来把基准从 4 改成 8 时，只需重写一遍值，不用全库替换。

Tailwind 项目直接覆写 theme：

```js
// tailwind.config.js
export default {
  theme: {
    screens: { sm: '640px', lg: '1024px', xl: '1280px', '2xl': '1536px' },
    extend: {
      maxWidth: { reading: '720px', page: '1200px' },
      spacing: { 13: '3.25rem' }, // 只在确有需要时扩展，不要随手加
    },
  },
}
```

### 第 3 步：选断点方向

```css
/* 移动优先：默认样式是窄屏，用 min-width 往上加 */
.card { padding: 16px; }
@media (min-width: 1024px) { .card { padding: 24px; } }

/* 桌面优先：默认样式是宽屏，用 max-width 往下减 */
.card { padding: 24px; }
@media (max-width: 1023.98px) { .card { padding: 16px; } }
```

注意用 `1023.98px` 而不是 `1023px` —— 小数像素宽度的设备（缩放 125%、150% 的 Windows）
会落在 1023 和 1024 之间的缝隙里，两端规则都不命中。

**代价对比**：

| | 移动优先 `min-width` | 桌面优先 `max-width` |
| --- | --- | --- |
| 主要流量是手机 | 推荐，默认样式即目标样式 | 每屏都要写一条覆盖规则 |
| 主要流量是桌面 | 窄屏默认样式容易被遗忘 | 推荐 |
| 老浏览器支持 | 需要 polyfill 才支持 `min-width`（现代浏览器无此问题） | 支持更早 |
| CSS 体积 | 通常更小（基线样式即手机） | 大屏专属样式会全部下发 |
| 调试心智 | 「往上加」符合直觉 | 「往下减」容易漏掉中间档 |

结论：C 端产品用移动优先，后台/工具用桌面优先，**不要在同一份全局样式里混用**。

### 第 4 步：栅格与列间距

```css
.grid-12 {
  display: grid;
  grid-template-columns: repeat(12, minmax(0, 1fr)); /* minmax(0,1fr) 防止长内容撑破列 */
  gap: 24px;
}
.col-span-4 { grid-column: span 4; }
@media (max-width: 1023.98px) { .col-span-4 { grid-column: span 12; } }
```

`minmax(0, 1fr)` 里的 `0` 是关键：默认 `1fr` 等价于 `minmax(auto, 1fr)`，
当列里有长 URL 或 `white-space: nowrap` 的表格时会把整列顶宽，导致横向滚动条。

### 第 5 步：超宽屏的三种处理

```css
/* ① 数据型：铺满 + 最小留白 */
.dashboard { padding-inline: 32px; }

/* ② 通用型：限宽居中 */
.marketing { max-width: 1200px; margin-inline: auto; }

/* ③ 内容型：≥1536 时切成 正文 + 侧栏 */
@media (min-width: 1536px) {
  .article-layout {
    display: grid;
    grid-template-columns: minmax(0, 720px) 240px;
    gap: 48px;
    justify-content: center;
  }
}
```

判断标准：**一行文字超过 90 个英文字符 / 45 个汉字，阅读效率就明显下降**，
此时无论屏幕多宽都必须限宽或分栏。

### 第 6 步：写成一份可检查的规范文档

在项目 README 或 `docs/layout.md` 里写清三件事，缺一条规范就会失效：
① 断点列表与方向；② 间距刻度与禁用值；③ 每类页面的容器档位。

## 检查清单

- [ ] 断点数量 ≤ 5，且全项目只有一套方向（全 `min-width` 或全 `max-width`）
- [ ] 媒体查询边界用 `.98px` 收尾（`1023.98px`），没有 `1023px` 这种写法
- [ ] `grep -rE "margin|padding" src/ | grep -E "[0-9]{2}px"` 的结果里，数字都属于允许刻度
- [ ] 在 1280 / 1440 / 1920 / 2560 四个宽度下截图对比，1920 与 2560 的**信息量**有差异（不是等比放大）
- [ ] 数据型页面在 2560 下没有出现超过 400px 的单侧留白
- [ ] 正文段落宽度 ≤ 720px（用浏览器标尺量，不是靠感觉）
- [ ] 栅格列里放了长 URL / 不换行文本时，列不被撑破（`minmax(0,1fr)` 生效）
- [ ] 页面缩放 125% 时布局不出现 1px 缝隙或重叠

## 常见错误

| 错误做法 | 为什么错 | 正确做法 |
| --- | --- | --- |
| 给后台表格页设 `max-width: 1440px` | 大屏用户看到的列数和小屏一样，横向空间被浪费 | 数据型容器不设上限，只留 32px 内边距 |
| 用 `zoom` 或整体 `font-size` 放大适配大屏 | 信息量与 1440 完全一致，等于没适配 | 限宽居中、分栏、或铺满 |
| 混用 `min-width` 和 `max-width` 两套断点 | 中间档被两条规则同时命中，样式随机 | 全项目统一方向 |
| 媒体查询写 `@media (max-width: 1023px)` | 缩放 125% 的 Windows 设备宽度落在缝隙里，规则不命中 | 写 `1023.98px` |
| `grid-template-columns: repeat(12, 1fr)` | 长内容把列顶宽，出现横向滚动条 | `minmax(0, 1fr)` |
| 断点定 768 / 992 / 1200 / 1400 | 与主流设备宽度不匹配，测试成本翻倍 | 用 640 / 1024 / 1280 / 1536 |
| 间距随手写 15px / 22px | 设计标注无法整除，flex 换行累计误差 | 只用 4 的倍数刻度 |
| 用 `padding-left/right` 写对称留白 | RTL 与横屏适配要再写一遍 | 用 `padding-inline` |

## 参考

- 需要区分「移动优先 / 桌面优先」在具体项目里的落地步骤与回归测试清单时，读 `references/breakpoint-strategy.md`
- 需要处理 1920 / 2560 / 3440 带鱼屏，以及多栏、侧栏折叠、粘性侧栏的具体数值时，读 `references/ultrawide.md`
$md$,
  '[{"path":"ATTRIBUTION.md","size":484,"kind":"text"},{"path":"LICENSE","size":1074,"kind":"text"},{"path":"SKILL.md","size":9118,"kind":"text"},{"path":"references/breakpoint-strategy.md","size":4700,"kind":"text"},{"path":"references/ultrawide.md","size":5300,"kind":"text"}]'::jsonb, 5, 20676, '8af50250fdeb9fa1e26537002c534014182f44ac747e2ece135757548927aa12',
  $b64$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$b64$,
  'published'
)
on conflict do nothing;
