import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import cesium from "vite-plugin-cesium"
import { mars3dPlugin } from "vite-plugin-mars3d"

// https://vite.dev/config/
export default defineConfig({
  plugins: [vue(),cesium(),mars3dPlugin],
});
