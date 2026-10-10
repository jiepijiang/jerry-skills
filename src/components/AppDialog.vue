<script setup>
import { onBeforeUnmount, watch } from 'vue'
import AppIcon from './AppIcon.vue'

/**
 * 通用弹窗。
 * ---------------------------------------------------------------------------
 * 站点原本没有任何弹窗（上传/下载都靠 toast 反馈），但「删除」这个动作需要
 * 一次**明确的、看得见的**确认 —— toast 是事后通知，挡不住误点。
 *
 * 两个必须做对的地方：
 *   1. **Teleport 到 body**。技能卡片整个是一个 <router-link>，弹窗如果留在
 *      卡片内部，里面的点击会冒泡给链接 → 点「取消」反而跳转进详情页。
 *      传送到 body 之后它跟那个 <a> 在 DOM 上就没关系了。
 *   2. **Esc 关闭 + 锁背景滚动**。滚动锁不上的话，弹窗开着还能滚后面列表，
 *      视觉上很乱；Esc 是键盘用户唯一的「退出」路径（他们点不到遮罩）。
 *
 * z-index 用 900：顶栏是 50、toast 是 1000。也就是说 toast 会盖在弹窗上 ——
 * 故意的，「口令不对」这类提示必须能看见，哪怕弹窗还开着。
 */
const props = defineProps({
  open: { type: Boolean, default: false },
  title: { type: String, default: '' },
  icon: { type: String, default: 'info' },
  /** 危险操作：标题图标和主按钮转成警示色 */
  danger: { type: Boolean, default: false },
})

const emit = defineEmits(['close'])

/**
 * 本站不做 SSR，但**测试会**用 vue/server-renderer 把组件渲染成 HTML 来断言
 * （见 scripts/tests/skill-card-render.test.mjs）。setup 里的 watch 是
 * `immediate: true`，在 Node 里会立刻走到 else 分支去碰 document 而炸掉整个测试文件。
 * 加一层存在性判断，组件就真的能在无 DOM 环境里加载 —— 对浏览器行为零影响。
 */
const hasDom = typeof document !== 'undefined'

function onKeydown(e) {
  if (e.key === 'Escape') emit('close')
}

/** 记录锁之前的值，恢复时写回去 —— 直接设成 '' 会把别的组件设的锁也清掉 */
let prevOverflow = ''

watch(
  () => props.open,
  (open) => {
    if (!hasDom) return
    if (open) {
      document.addEventListener('keydown', onKeydown)
      prevOverflow = document.body.style.overflow
      document.body.style.overflow = 'hidden'
      // 让键盘用户一进来就在输入框里，不用先 Tab 一圈
      requestAnimationFrame(() => {
        document.querySelector('[data-autofocus]')?.focus?.()
      })
    } else {
      document.removeEventListener('keydown', onKeydown)
      document.body.style.overflow = prevOverflow
    }
  },
  { immediate: true },
)

onBeforeUnmount(() => {
  if (!hasDom) return
  document.removeEventListener('keydown', onKeydown)
  document.body.style.overflow = prevOverflow
})
</script>

<template>
  <Teleport to="body">
    <Transition name="dlg">
      <!-- @click.self：只有点在遮罩本身才关，点在弹窗内部冒泡上来的不算 -->
      <div v-if="open" class="dlg-mask" @click.self="emit('close')">
        <div class="dlg" :class="{ danger }" role="dialog" aria-modal="true">
          <header class="dlg-head">
            <AppIcon :name="icon" :size="17" />
            <h3 class="dlg-title">{{ title }}</h3>
            <button class="dlg-x" type="button" aria-label="关闭" @click="emit('close')">
              <AppIcon name="close" :size="15" />
            </button>
          </header>

          <div class="dlg-body">
            <slot />
          </div>

          <footer class="dlg-foot">
            <slot name="actions" />
          </footer>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<style scoped>
.dlg-mask {
  align-items: center;
  background: var(--hub_mask);
  display: flex;
  inset: 0;
  justify-content: center;
  padding: 20px;
  position: fixed;
  /* 顶栏 50 / toast 1000 —— 弹窗夹在中间，toast 必须能盖在它上面 */
  z-index: 900;
}

.dlg {
  background: var(--hub_panel_bg);
  border: 1px solid var(--hub_line_strong);
  border-radius: 14px;
  box-shadow: 0 18px 50px #00000073;
  max-width: 440px;
  padding: 18px 20px 16px;
  width: 100%;
}

.dlg-head {
  align-items: center;
  display: flex;
  gap: 8px;
}

.dlg-head svg {
  fill: var(--hub_muted);
  flex-shrink: 0;
}

.dlg.danger .dlg-head svg {
  fill: var(--hub_err);
}

.dlg-title {
  flex: 1;
  font-size: 16px;
  font-weight: 700;
  margin: 0;
  min-width: 0;
}

.dlg-x {
  align-items: center;
  background: transparent;
  border: 0;
  border-radius: 7px;
  color: var(--hub_muted);
  cursor: pointer;
  display: inline-flex;
  flex-shrink: 0;
  height: 26px;
  justify-content: center;
  padding: 0;
  transition:
    background-color 0.2s ease,
    color 0.2s ease;
  width: 26px;
}

.dlg-x:hover {
  background: var(--item_hover_color);
  color: var(--main_text_color);
}

.dlg-x svg {
  fill: currentColor;
}

.dlg-body {
  color: var(--hub_muted);
  font-size: 13.5px;
  line-height: 1.7;
  margin-top: 12px;
}

.dlg-foot {
  display: flex;
  gap: 9px;
  justify-content: flex-end;
  margin-top: 18px;
}

/* 进出场：淡入 + 轻微上浮。用 transform 而不是改 height，避免触发重排 */
.dlg-enter-active,
.dlg-leave-active {
  transition: opacity 0.18s ease;
}

.dlg-enter-active .dlg,
.dlg-leave-active .dlg {
  transition: transform 0.18s ease;
}

.dlg-enter-from,
.dlg-leave-to {
  opacity: 0;
}

.dlg-enter-from .dlg,
.dlg-leave-to .dlg {
  transform: translateY(8px) scale(0.98);
}

@media (prefers-reduced-motion: reduce) {
  .dlg-enter-active,
  .dlg-leave-active,
  .dlg-enter-active .dlg,
  .dlg-leave-active .dlg {
    transition: none;
  }
}
</style>
