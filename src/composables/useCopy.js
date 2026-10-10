import { onBeforeUnmount, ref } from 'vue'
import { copyText } from '@/lib/skills-api'
import { toast } from './useToast'

/**
 * 复制 + 「已复制」反馈。
 * 做成 composable 而不是组件，是因为站点里有两种外观差别很大的复制入口：
 *   · 代码块右上角的小按钮（.code-copy）
 *   · 详情页主操作区的大按钮（.btn primary）
 * 强行统一成一个组件的 className 反而更难维护。
 *
 * @param {{silent?:boolean, duration?:number}} opts
 *   silent=true 时不弹全局 toast（调用方自己给反馈）
 */
export function useCopy({ silent = false, duration = 1800 } = {}) {
  const done = ref(false)
  let timer = null

  async function copy(text, okMsg = '已复制到剪贴板') {
    const ok = await copyText(text)
    if (!ok) {
      // 复制失败必须说 —— 静默失败会让用户以为粘出来的是新内容
      toast('复制失败，请手动选中后复制', 'error')
      return false
    }
    done.value = true
    clearTimeout(timer)
    timer = setTimeout(() => {
      done.value = false
    }, duration)
    if (!silent) toast(okMsg)
    return true
  }

  onBeforeUnmount(() => clearTimeout(timer))

  return { done, copy }
}
