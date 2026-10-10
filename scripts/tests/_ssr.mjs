/**
 * 单测共用的 Vite SSR 服务器
 * ---------------------------------------------------------------------------
 * 有些东西（组件、`@/data/site`）必须让 Vite 真编译一次才能在 Node 里 import ——
 * 它们用了 `import.meta.env`，直接 import 会炸。
 *
 * ⚠️ 为什么不用 `hmr: false`：
 *    那样 Vite 仍然会去绑默认的 24678 端口。测试文件是**并行**跑的，
 *    于是第二个进程会打印
 *      `WebSocket server error: Port 24678 is already in use`
 *    测试本身照样过，但日志里多一条看起来像故障的红字 —— 后来的人会去查它。
 *    给每个进程一个不同的端口就干净了（单文件跑的时候也不会和别的项目撞）。
 *
 * 这个文件不以 `.test.mjs` 结尾，所以 `node --test scripts/tests/*.test.mjs`
 * 不会把它当成用例文件。
 */
import { createServer } from 'vite'
import { fileURLToPath } from 'node:url'

export const ROOT = fileURLToPath(new URL('../..', import.meta.url))

export function createSsrServer() {
  return createServer({
    root: ROOT,
    logLevel: 'error',
    appType: 'custom',
    server: {
      middlewareMode: true,
      hmr: { port: 24000 + (process.pid % 10000) },
      watch: null,
    },
  })
}
