-- ============================================================================
-- UI 技能包入库 · 自检
-- ----------------------------------------------------------------------------
-- 跑完上面 7 个文件后执行本文件，核对结果。
-- ============================================================================

-- 1. UI 分类下的技能数（期望 42）
select 'ui 技能总数' as 指标, count(*)::text as 值
  from public.skills where category = 'ui' and status = 'published';

-- 2. 每个维度各几个（期望每行都是 6）
--    数据库里没有「维度」这一列（统一是 category = 'ui'），所以用 slug 白名单来分组。
--    这份白名单是 gen-sql.mjs 从技能数据里**自动生成**的，不是手抄的。
with dim(ord, 维度, slug) as (
  values
    (1, 'PC 桌面端', 'frontend-design'),
    (1, 'PC 桌面端', 'web-artifacts-builder'),
    (1, 'PC 桌面端', 'a11y-audit'),
    (1, 'PC 桌面端', 'senior-frontend'),
    (1, 'PC 桌面端', 'data-dense-ui'),
    (1, 'PC 桌面端', 'desktop-layout-system'),
    (2, 'H5 移动端', 'h5-performance'),
    (2, 'H5 移动端', 'h5-touch-accessibility'),
    (2, 'H5 移动端', 'h5-viewport-adaptation'),
    (2, 'H5 移动端', 'mobile-form-ux'),
    (2, 'H5 移动端', 'mobile-web-gestures'),
    (2, 'H5 移动端', 'wechat-h5-guide'),
    (3, 'APP', 'apple-hig-expert'),
    (3, 'APP', 'paywall-upgrade-cro'),
    (3, 'APP', 'app-store-optimization'),
    (3, 'APP', 'material-design-3'),
    (3, 'APP', 'mobile-app-navigation'),
    (3, 'APP', 'mobile-onboarding'),
    (4, '落地页', 'landing-page-generator'),
    (4, '落地页', 'page-cro'),
    (4, '落地页', 'landing'),
    (4, '落地页', 'hero-section-design'),
    (4, '落地页', 'pricing-page-design'),
    (4, '落地页', 'social-proof-blocks'),
    (5, '业务场景', 'ux-researcher-designer'),
    (5, '业务场景', 'site-architecture'),
    (5, '业务场景', 'ecommerce-ui'),
    (5, '业务场景', 'fintech-ui'),
    (5, '业务场景', 'healthcare-ui'),
    (5, '业务场景', 'saas-app-ui'),
    (6, '后台管理', 'ui-design-system'),
    (6, '后台管理', 'admin-dashboard-layout'),
    (6, '后台管理', 'admin-empty-error-states'),
    (6, '后台管理', 'crud-page-patterns'),
    (6, '后台管理', 'data-table-design'),
    (6, '后台管理', 'filter-and-search-ui'),
    (7, 'UI 风格', 'theme-factory'),
    (7, 'UI 风格', 'design-system'),
    (7, 'UI 风格', 'bento-grid-ui'),
    (7, 'UI 风格', 'dark-mode-oled'),
    (7, 'UI 风格', 'glassmorphism-ui'),
    (7, 'UI 风格', 'neumorphism-ui')
)
select d.ord                                                as "#",
       d.维度,
       count(s.slug)                                        as 技能数,
       case when count(s.slug) = 6 then '✅' else '⚠️ 少了' end as 判定
  from dim d
  left join public.skills s
    on s.slug = d.slug
   and s.category = 'ui'
   and s.status = 'published'
 group by d.ord, d.维度
 order by d.ord;

-- 3. 关键字段有没有空（期望 0）
select '缺字段的行数' as 指标,
       count(*)::text as 值
  from public.skills
 where category = 'ui'
   and (description = '' or author = '' or license = '' or hash = '' or bundle_b64 = '');

-- 4. 标签有没有真的写进去（设计区间 5~7，期望判定为 ✅）
select '标签数范围' as 指标,
       min(array_length(tags, 1))::text || ' ~ ' || max(array_length(tags, 1))::text as 值,
       case when min(array_length(tags, 1)) >= 5 and max(array_length(tags, 1)) <= 7
            then '✅' else '⚠️ 越界' end as 判定
  from public.skills where category = 'ui';

-- 5. 逐条清单（看名字和标签对不对）
select slug, name, array_length(tags, 1) as 标签数, round(total_bytes/1024.0, 1) as KB
  from public.skills where category = 'ui' order by slug;
