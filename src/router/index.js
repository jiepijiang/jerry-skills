import { createRouter, createWebHistory } from 'vue-router'
import HomeView from '@/views/HomeView.vue'

const routes = [
  { path: '/', name: 'home', component: HomeView },
  {
    path: '/skills/:slug',
    name: 'skill',
    component: () => import('@/views/SkillDetailView.vue'),
  },
  {
    path: '/upload',
    name: 'upload',
    component: () => import('@/views/UploadView.vue'),
  },
  { path: '/:pathMatch(.*)*', redirect: '/' },
]

export default createRouter({
  /* 用 BASE_URL 而不是 '/'：GitHub Pages 上站点在 /jerry-skills/ 子路径下，
     路由 base 必须跟着走，否则刷新 /jerry-skills/upload 会被当成根路径路由。 */
  history: createWebHistory(import.meta.env.BASE_URL),
  routes,
  scrollBehavior: () => ({ top: 0 }),
})
