import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import { fileURLToPath, URL } from 'node:url'
import { copyFileSync, existsSync } from 'node:fs'
import path from 'node:path'

/*
 * GitHub Pages 把站点挂在 https://<user>.github.io/<repo>/ 子路径下，
 * 所以构建必须带 base，否则 /assets/*.js 全部 404。本地 dev 仍用 '/'。
 * 换仓库名只改这一行（和主站 / jerry-tools / jerry-notes 一个套路）。
 */
const REPO_NAME = 'jerry-skills'

/*
 * GitHub Pages 没有 SPA fallback：直接打开 /jerry-skills/skills/xxx 或刷新该页会 404。
 * 官方推荐额外提供一份 404.html（内容同 index.html），Pages 找不到路径时回退到它，
 * 前端路由再接管。
 *
 * 输出目录从 configResolved 取，不写死 ./dist —— 否则用 `vite build --outDir xxx`
 * 时 404.html 会被写到 dist 去。
 */
function spaFallbackPlugin() {
  let outDir = null
  return {
    name: 'spa-404-fallback',
    apply: 'build',
    configResolved(config) {
      const dir = config.build.outDir
      outDir = path.isAbsolute(dir) ? dir : path.resolve(config.root, dir)
    },
    closeBundle() {
      if (!outDir) return
      const index = path.join(outDir, 'index.html')
      if (existsSync(index)) copyFileSync(index, path.join(outDir, '404.html'))
    },
  }
}

export default defineConfig(({ command }) => ({
  base: command === 'build' ? `/${REPO_NAME}/` : '/',
  plugins: [vue(), spaFallbackPlugin()],
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url)),
    },
  },
  server: {
    port: 5176,
    host: '127.0.0.1',
  },
  build: {
    chunkSizeWarningLimit: 1200,
  },
}))
