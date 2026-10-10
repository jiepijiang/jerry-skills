<script setup>
import { computed, onMounted, ref, watch } from 'vue'
import SkillCard from '@/components/SkillCard.vue'
import EmptyState from '@/components/EmptyState.vue'
import LocalModeBanner from '@/components/LocalModeBanner.vue'
import AppIcon from '@/components/AppIcon.vue'
import { brand, categories, sorts } from '@/data/site'
import { listSkills, errorText } from '@/lib/skills-api'
import { useSearch } from '@/composables/useSearch'

const PAGE_SIZE = 24

const { query } = useSearch()
const category = ref('all')
const sort = ref('new')

const items = ref([])
const total = ref(0)
const loading = ref(true)
const loadingMore = ref(false)
const error = ref('')

/**
 * 竞态守卫：快速改筛选/搜索词时会并发多个请求，
 * 先发的后回来就会把旧结果盖在新结果上。用一个自增序号，只认最后一次。
 */
let seq = 0
let debounce = null

async function load({ append = false } = {}) {
  const my = ++seq
  if (append) loadingMore.value = true
  else loading.value = true
  error.value = ''

  try {
    const r = await listSkills({
      q: query.value.trim(),
      category: category.value,
      sort: sort.value,
      limit: PAGE_SIZE,
      offset: append ? items.value.length : 0,
    })
    if (my !== seq) return
    total.value = r.total
    items.value = append ? [...items.value, ...r.items] : r.items
    loading.value = false
    loadingMore.value = false
  } catch (e) {
    if (my !== seq) return
    error.value = errorText(e)
    if (!append) items.value = []
    loading.value = false
    loadingMore.value = false
  }
}

const hasMore = computed(() => items.value.length < total.value)
const isFiltering = computed(() => category.value !== 'all' || query.value.trim() !== '')

/**
 * 「浏览全部」滚到筛选栏。
 *
 * 原来是 `<a href="#browse">` 的原生锚点跳转 —— 瞬移，很生硬。改成平滑滚动。
 *
 * 为什么不用全局的 `html { scroll-behavior: smooth }`：
 * 路由的 scrollBehavior 返回的是 `{ top: 0 }`，vue-router 只在**没指定 behavior** 时
 * 交给浏览器决定，于是全局平滑会把「切换页面回到顶部」也一起变慢，反而更卡。
 * 所以只在这一个入口显式平滑，别动全局。
 */
function scrollToBrowse() {
  const el = document.getElementById('browse')
  if (!el) return
  // 尊重系统的「减弱动效」设置 —— 前庭功能敏感的用户会被平滑滚动晃到
  const reduce = window.matchMedia?.('(prefers-reduced-motion: reduce)').matches
  el.scrollIntoView({ behavior: reduce ? 'auto' : 'smooth', block: 'start' })
}

watch([category, sort], () => load())

watch(query, () => {
  clearTimeout(debounce)
  debounce = setTimeout(() => load(), 220)
})

onMounted(() => load())
</script>

<template>
  <div class="hub-shell">
    <LocalModeBanner />

    <!-- Hero -->
    <header class="hero">
      <h1 class="hero-title">
        <span class="gradientText">{{ brand.name }}</span>
      </h1>
      <p class="hero-tagline">{{ brand.tagline }}</p>
      <p class="hero-desc">{{ brand.description }}</p>

      <div class="hero-actions">
        <router-link to="/upload" class="btn primary">
          <AppIcon name="upload" :size="16" fill="#fff" />
          上传技能
        </router-link>
        <a class="btn" href="#browse" @click.prevent="scrollToBrowse">
          <AppIcon name="search" :size="16" />
          浏览全部
        </a>
      </div>
    </header>

    <!-- 筛选栏 -->
    <section id="browse" class="filters">
      <div class="filter-row">
        <span class="filter-label">分类</span>
        <div class="chips">
          <button
            v-for="c in categories"
            :key="c.key"
            class="chip"
            :class="{ active: category === c.key }"
            @click="category = c.key"
          >
            <AppIcon :name="c.icon" :size="14" :fill="category === c.key ? '#fff' : ''" />
            {{ c.label }}
          </button>
        </div>
      </div>

      <div class="filter-row">
        <span class="filter-label">排序</span>
        <div class="chips">
          <button
            v-for="s in sorts"
            :key="s.key"
            class="chip"
            :class="{ active: sort === s.key }"
            @click="sort = s.key"
          >
            {{ s.label }}
          </button>
        </div>
        <span class="count">{{ loading ? '…' : `${total} 个技能` }}</span>
      </div>
    </section>

    <!-- 列表 -->
    <section class="grid">
      <template v-if="loading">
        <div v-for="i in 6" :key="i" class="skeleton card sk" />
      </template>

      <template v-else-if="error">
        <EmptyState icon="warn" :text="error">
          <button class="btn sm" @click="load()">重试</button>
        </EmptyState>
      </template>

      <template v-else-if="items.length">
        <SkillCard v-for="s in items" :key="s.slug" :skill="s" />
      </template>

      <template v-else>
        <EmptyState
          icon="box"
          :text="
            isFiltering
              ? '没有匹配的技能，换个关键词或分类试试。'
              : '还没有技能。你可以上传第一个。'
          "
        >
          <router-link v-if="!isFiltering" to="/upload" class="btn sm primary">
            <AppIcon name="upload" :size="14" fill="#fff" />
            上传技能
          </router-link>
        </EmptyState>
      </template>
    </section>

    <div v-if="!loading && hasMore" class="more">
      <button class="btn" :class="{ loading: loadingMore }" :disabled="loadingMore" @click="load({ append: true })">
        加载更多
      </button>
    </div>
  </div>
</template>

<style scoped>
/* ---------------------------------------------------------------- Hero */
.hero {
  padding: 26px 0 10px;
}

.hero-title {
  font-size: 58px;
  font-weight: 800;
  line-height: 1.1;
  margin: 0;
}

.gradientText {
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  animation: backgroundSizeAnimation 10s ease-in-out infinite;
  background-image: var(--gradient);
  background-position: 0;
  background-size: 200%;
  font-family: title;
}

.hero-tagline {
  font-size: 20px;
  font-weight: 600;
  margin-top: 14px;
}

.hero-desc {
  color: var(--hub_muted);
  font-size: 14px;
  line-height: 1.7;
  margin-top: 10px;
  max-width: 640px;
}

.hero-actions {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
  margin-top: 20px;
}

/* -------------------------------------------------------------- 筛选栏 */
.filters {
  border-bottom: 1px solid var(--hub_line);
  display: flex;
  flex-direction: column;
  gap: 12px;
  margin-top: 26px;
  padding-bottom: 18px;
  /* 「浏览全部」滚过来时给 sticky 顶栏（62px）让位，否则标题会被压在导航底下 */
  scroll-margin-top: 76px;
}

.filter-row {
  align-items: center;
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.filter-label {
  color: var(--hub_muted);
  flex-shrink: 0;
  font-size: 13px;
  width: 34px;
}

.chips {
  display: flex;
  flex-wrap: wrap;
  gap: 7px;
}

.count {
  color: var(--hub_muted);
  font-size: 13px;
  margin-left: auto;
}

/* ---------------------------------------------------------------- 网格 */
.grid {
  display: grid;
  gap: 14px;
  grid-template-columns: repeat(auto-fill, minmax(272px, 1fr));
  margin-top: 20px;
}

.sk {
  height: 172px;
}

.more {
  display: flex;
  justify-content: center;
  margin-top: 26px;
}

@media (max-width: 720px) {
  .hero-title {
    font-size: 40px;
  }

  .hero-tagline {
    font-size: 17px;
  }

  .grid {
    grid-template-columns: 1fr;
  }

  .count {
    margin-left: 0;
    width: 100%;
  }
}
</style>
