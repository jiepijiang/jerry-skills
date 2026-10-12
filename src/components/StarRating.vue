<script setup>
import { computed, ref } from 'vue'
import AppIcon from './AppIcon.vue'
import { ratings as cfg, ratingAvgText } from '@/data/site'

/**
 * 五星评分。两种形态共用一个组件：
 *
 *   · **展示态**（`readonly`）：卡片和详情页头部用。按平均分做**小数填充**
 *     （4.3 分就画 4.3 颗星），不是四舍五入成整颗 —— 四舍五入会把 4.4 和 4.6
 *     画成同一个样子，而这两个分数的差别正是用户想看的。
 *   · **交互态**：详情页打分用。5 个按钮，鼠标悬停预览、键盘可达。
 *
 * ⚠️ 为什么两种形态不拆成两个组件：它们共用同一份「分值 → 星级 → 文案」的
 *    映射规则（cfg.labels / cfg.max）。拆开的话，早晚会出现「卡片写 5 星、
 *    打分区写 5 颗但文案表只有 4 条」这种两边对不上的情况。
 */
const props = defineProps({
  /** 平均分。null / undefined = 还没人评分 */
  avg: { type: Number, default: null },
  /** 评分人数 */
  count: { type: Number, default: 0 },
  /** 我自己打过的分（1~max）。null = 我还没打分 */
  modelValue: { type: Number, default: null },
  /** 只读展示（卡片上用），不给点 */
  readonly: { type: Boolean, default: false },
  /** 单颗星的边长（px） */
  size: { type: Number, default: 16 },
  /** 展示态是否带上「(N 人)」 */
  showCount: { type: Boolean, default: true },
})

const emit = defineEmits(['update:modelValue', 'rate'])

const hover = ref(0)
const starRefs = ref([])

const max = cfg.max

/**
 * 有没有人评过分。
 *
 * ⚠️ 不能只判 `avg > 0`：没人评分时服务端返回的是 **null**，
 *    而 `null > 0` 是 false、`null >= 0` 是 true —— 用后者会把「没人评」
 *    当成「0 分」画出来。两个条件都要判。
 */
const hasVotes = computed(
  () => props.count > 0 && props.avg !== null && props.avg !== undefined && Number.isFinite(Number(props.avg)),
)

/** 平均分文案：去掉无意义的尾零（4.00 → 4，4.50 → 4.5，4.33 → 4.33） */
const avgText = computed(() => (hasVotes.value ? ratingAvgText(props.avg) : ''))

/** 平均分 → 填充百分比 */
const pct = computed(() => {
  if (!hasVotes.value) return 0
  return Math.max(0, Math.min(1, Number(props.avg) / max)) * 100
})

/** 交互态当前该亮几颗：鼠标/键盘指到哪就预览到哪，没指就显示自己已打的分 */
const shown = computed(() => hover.value || props.modelValue || 0)

/** 是不是正在「预览」（鼠标/键盘指在某颗星上） */
const previewing = computed(() => hover.value > 0)

/**
 * 星星旁边那句话。
 *
 * ⚠️ 这三档的**顺序**很关键：不能写成 `hoverText || (modelValue ? '你打了 N 星' : …)`。
 *    `hoverText` 是从 `shown` 算的，而 `shown` 在没悬停时会退化成「我自己打的分」——
 *    于是只要我打过一次分，这句话就永远是「一般」这种**形容词**，
 *    再也不会说出「你打了 3 星」这个事实。
 *    （这条是 rating.test.mjs 里「文案会告诉用户你打了 N 星」抓出来的。）
 */
const labelText = computed(() => {
  if (previewing.value) return cfg.labels[hover.value - 1]
  return props.modelValue ? `你打了 ${props.modelValue} 星` : '点星星打分'
})

/** 只有「还没打分也没在预览」时才该是灰的 —— 其余两种都是在说一件确定的事 */
const labelMuted = computed(() => !previewing.value && !props.modelValue)

const displayTitle = computed(() =>
  hasVotes.value ? `${avgText.value} 分 · ${props.count} 人评分` : cfg.empty,
)

function pick(n) {
  if (props.readonly) return
  emit('update:modelValue', n)
  emit('rate', n)
}

/**
 * 左右方向键切换。星评在语义上是个**单选组**，键盘用户不该被逼着按 5 次 Tab
 * 才能选到第 5 颗星 —— 那是 WAI-ARIA 里 radiogroup 的约定。
 */
function onKey(e, n) {
  const dir =
    e.key === 'ArrowRight' || e.key === 'ArrowUp'
      ? 1
      : e.key === 'ArrowLeft' || e.key === 'ArrowDown'
        ? -1
        : 0
  if (!dir) return
  e.preventDefault()
  const next = Math.min(max, Math.max(1, n + dir))
  starRefs.value[next - 1]?.focus()
}
</script>

<template>
  <!-- ------------------------------------------------ 展示态 -->
  <span v-if="readonly" class="sr-display" :title="displayTitle">
    <span class="sr-stars" :style="{ '--sr-size': size + 'px' }">
      <!-- 底层：一排空星。整排宽度就是容器的宽度 -->
      <span class="sr-base" aria-hidden="true">
        <AppIcon v-for="i in max" :key="`b${i}`" name="star-outline" :size="size" />
      </span>
      <!-- 上层：一排实心星，按平均分的百分比裁切出「小数颗」的效果 -->
      <span class="sr-fill" :style="{ width: pct + '%' }" aria-hidden="true">
        <span class="sr-inner">
          <AppIcon v-for="i in max" :key="`f${i}`" name="star" :size="size" />
        </span>
      </span>
    </span>

    <template v-if="hasVotes">
      <b class="sr-num">{{ avgText }}</b>
      <span v-if="showCount" class="sr-count">（{{ count }} 人）</span>
    </template>
    <span v-else class="sr-none">{{ cfg.empty }}</span>
  </span>

  <!-- ------------------------------------------------ 交互态 -->
  <div v-else class="sr-picker">
    <div class="sr-row" role="group" :aria-label="`给这个技能打分，共 ${max} 星`">
      <button
        v-for="i in max"
        :key="i"
        :ref="(el) => (starRefs[i - 1] = el)"
        type="button"
        class="sr-pick"
        :class="{ on: i <= shown }"
        :aria-pressed="modelValue === i"
        :aria-label="`${i} 星 —— ${cfg.labels[i - 1]}`"
        :title="`${i} 星 —— ${cfg.labels[i - 1]}`"
        @click="pick(i)"
        @mouseenter="hover = i"
        @mouseleave="hover = 0"
        @focus="hover = i"
        @blur="hover = 0"
        @keydown="onKey($event, i)"
      >
        <AppIcon :name="i <= shown ? 'star' : 'star-outline'" :size="size" />
      </button>
    </div>

    <!-- 高度固定，免得鼠标扫过时下面的内容上下跳 -->
    <span class="sr-label" :class="{ muted: labelMuted }">{{ labelText }}</span>
  </div>
</template>

<style scoped>
/* ------------------------------------------------------------ 展示态 */
.sr-display {
  align-items: center;
  display: inline-flex;
  gap: 5px;
  white-space: nowrap;
}

.sr-stars {
  display: inline-flex;
  flex-shrink: 0;
  line-height: 0;
  position: relative;
}

.sr-base,
.sr-inner {
  display: inline-flex;
  gap: 1px;
}

/* 裁切层：宽度由平均分决定（inline style），把上面那排实心星「切」出小数颗 */
.sr-fill {
  inset: 0 auto 0 0;
  overflow: hidden;
  position: absolute;
}

/* ⚠️ 内层必须 width: max-content。
   父级是 overflow: hidden 的窄容器，内层若跟着收缩，星星会被**压扁**而不是
   被裁掉 —— 表现是「4.3 分的星星比 5 分的小一圈」，很难看出是 bug。 */
.sr-inner {
  width: max-content;
}

.sr-base :deep(path) {
  fill: var(--hub_muted);
  opacity: 0.35;
}

.sr-inner :deep(path) {
  fill: var(--hub_star);
}

.sr-num {
  color: var(--hub_star);
  font-size: 13px;
  font-weight: 600;
}

.sr-count,
.sr-none {
  color: var(--hub_muted);
  font-size: 12px;
}

/* ------------------------------------------------------------ 交互态 */
.sr-picker {
  align-items: center;
  display: flex;
  gap: 12px;
}

.sr-row {
  display: inline-flex;
  gap: 2px;
}

.sr-pick {
  background: transparent;
  border: 0;
  border-radius: 5px;
  cursor: pointer;
  display: inline-flex;
  line-height: 0;
  padding: 1px;
  transition: transform 0.12s ease;
}

.sr-pick:hover {
  transform: scale(1.15);
}

.sr-pick:focus-visible {
  outline: 2px solid var(--hub_accent);
  outline-offset: 2px;
}

.sr-pick :deep(path) {
  fill: var(--hub_muted);
  opacity: 0.35;
}

.sr-pick.on :deep(path) {
  fill: var(--hub_star);
  opacity: 1;
}

.sr-label {
  color: var(--hub_star);
  font-size: 13px;
  min-width: 92px;
}

.sr-label.muted {
  color: var(--hub_muted);
}
</style>
