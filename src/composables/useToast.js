import { ref } from 'vue'

/**
 * 全局 Toast。
 * ---------------------------------------------------------------------------
 * 主站的留言板把 toast 做成了页面私有状态（那个页面只有一个提交动作）。
 * 本站多个页面都要弹提示（复制成功 / 上传成功 / 上传失败），所以提到全局，
 * 由 App.vue 挂一个 <HubToast> 消费。
 *
 * 用法：toast('已复制', 'success') / toast('网络错误', 'error')
 */
export const toastState = ref({ active: false, type: 'success', text: '' })

let timer = null

export function toast(text, type = 'success', duration = 2600) {
  toastState.value = { active: true, type, text }
  clearTimeout(timer)
  timer = setTimeout(() => {
    toastState.value.active = false
  }, duration)
}

export function useToast() {
  return { toastState, toast }
}
