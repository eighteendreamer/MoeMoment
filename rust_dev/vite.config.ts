import path from 'node:path'
import react from '@vitejs/plugin-react'
import { defineConfig } from 'vite'

// Tauri 要求固定端口，且不能在端口被占用时自动切换
export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      '@': path.resolve(import.meta.dirname, './src'),
    },
  },
  clearScreen: false,
  server: {
    port: 1420,
    strictPort: true,
    host: '127.0.0.1',
    watch: {
      // 避免监听 Rust 侧目录导致的重启抖动
      ignored: ['**/src-tauri/**'],
    },
  },
})
