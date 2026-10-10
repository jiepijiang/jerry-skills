import { computed, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'

/**
 * 顶栏搜索框的共享状态。
 * ---------------------------------------------------------------------------
 * 顶栏（App 级）和首页（HomeView）都要读这个 query，所以提到模块级单例。
 * 在非首页输入搜索词时自动跳到首页 —— 否则用户会看着一个「打了字但页面没反应」的
 * 搜索框，以为坏了。
 */
export const query = ref('')

export function useSearch() {
  const router = useRouter()
  const route = useRoute()

  // 跳到首页后要把「待跳转」标记清掉，否则在首页继续输入会被反复 push
  watch(query, (v) => {
    if (!v) return
    if (route.name !== 'home') router.push({ name: 'home' })
  })

  const hasQuery = computed(() => query.value.trim().length > 0)

  function clear() {
    query.value = ''
  }

  return { query, hasQuery, clear }
}
