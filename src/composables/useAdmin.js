import { ref } from 'vue'
import { adminCheck, adminDelete, errorText } from '@/lib/skills-api'
import { clearAdminToken, setAdminToken } from '@/lib/admin'
import { toast } from './useToast'

/**
 * 解锁：拿口令去服务端换一次「你是站主」的确认，通过就记在 sessionStorage 里。
 *
 * 为什么要有这一步而不是「直接删、删的时候顺手验口令」：
 *   删到一半才发现口令是错的，那个确认弹窗就白点了。先验一次，
 *   错误能在输入框下面当场显示。
 */
export function useAdminUnlock() {
  const busy = ref(false)
  const error = ref('')

  async function submit(token) {
    if (busy.value) return false
    busy.value = true
    error.value = ''
    try {
      await adminCheck(token)
      setAdminToken(token)
      return true
    } catch (e) {
      error.value = errorText(e, { admin: true })
      return false
    } finally {
      busy.value = false
    }
  }

  function reset() {
    error.value = ''
  }

  return { busy, error, submit, reset }
}

/**
 * 删除。把「口令失效」和「东西已经不在了」这两种特殊失败收在这里 ——
 * 否则详情页和卡片各写一份，迟早只修一处。
 *
 * 返回 true 表示「调用方可以把它从界面上拿掉了」（含 not_found：本来就没有，
 * 界面上还留着才是错的）。
 */
export function useSkillDelete() {
  const busy = ref(false)

  async function remove(slug, token) {
    if (busy.value) return false
    busy.value = true
    try {
      const r = await adminDelete(slug, token)
      toast(`已删除「${r?.name || slug}」`)
      return true
    } catch (e) {
      if (e?.code === 'unauthorized') {
        // 服务端换了口令 / 口令被清过 —— 把本地状态也清掉，回到「未解锁」
        clearAdminToken()
        toast('管理口令已失效，请重新解锁', 'error')
        return false
      }
      if (e?.code === 'not_found') {
        toast('这个技能已经不在了')
        return true
      }
      toast(errorText(e, { admin: true }), 'error')
      return false
    } finally {
      busy.value = false
    }
  }

  return { busy, remove }
}
