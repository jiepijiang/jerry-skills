/**
 * 站主口令
 * ---------------------------------------------------------------------------
 * 本站没有任何账号体系，删除权靠一个**管理口令**认人（服务端只存加盐哈希，
 * 见 supabase/migrations/002-admin-delete.sql）。这里只管「口令放在哪」。
 *
 * 🔴 为什么是 sessionStorage 而不是 localStorage：
 *    口令能删掉整站数据。localStorage 会把它**长期**留在磁盘上，任何一次
 *    XSS / 共用电脑都能拿走；sessionStorage 关掉标签页就没了。
 *    代价是每次新开标签页要重输一次 —— 这个操作本来就很少做，值得。
 *    （顺带说明：本站目前**没有任何 v-html**，技能内容全是 mustache 转义渲染的，
 *      所以并不存在「上传者塞一段脚本偷口令」这条路。但依赖「今天没有 XSS」
 *      来保护一个长期凭证是不划算的，所以还是用 sessionStorage。）
 *
 * 存进去的口令在解锁那一刻已经被服务端验过（skill_admin_check）。
 * 之后若服务端换了口令，删除会返回 unauthorized —— 调用方负责 clear 掉并提示重来。
 */
import { computed, ref } from 'vue'

const SS_KEY = 'jerry-skills:admin:v1'

/** sessionStorage 在隐私模式 / 禁用 cookie 时可能直接抛异常，一律降级成「没解锁」 */
function read() {
  try {
    return sessionStorage.getItem(SS_KEY) || ''
  } catch {
    return ''
  }
}

export const adminToken = ref(read())

/** 有口令 = 已解锁。按钮的显隐就看这个 */
export const isAdmin = computed(() => adminToken.value !== '')

export function setAdminToken(token) {
  adminToken.value = String(token || '')
  try {
    sessionStorage.setItem(SS_KEY, adminToken.value)
  } catch {
    // 存不下也不影响本次会话（ref 里已经有了），只是刷新后要重输
  }
}

export function clearAdminToken() {
  adminToken.value = ''
  try {
    sessionStorage.removeItem(SS_KEY)
  } catch {
    /* 忽略 */
  }
}
