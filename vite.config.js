import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import cesium from "vite-plugin-cesium"
import { mars3dPlugin } from "vite-plugin-mars3d"
import path from 'path' // 引入 path 模块
import glsl from "vite-plugin-glsl"

// https://vite.dev/config/
export default defineConfig({
  plugins: [vue(),cesium(),mars3dPlugin,glsl()],
   resolve: {
    alias: {
      // 传统写法：使用 __dirname
      '@': path.resolve(__dirname, 'src')
    }
  }
});






