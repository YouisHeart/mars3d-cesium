<script setup>
import { ref, onMounted } from 'vue'
import "mars3d-cesium/Build/Cesium/Widgets/widgets.css"
import "mars3d/mars3d.css"

import * as mars3d from "mars3d"
import "mars3d-space"

const map = ref(null)

onMounted(() => {
  map.value = new mars3d.Map("mars3dContainer", {
    basemaps: [
      {
        name: "OSM",
        type: "xyz",
        url: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
        show: true
      }
    ]
  })
})
</script>

<template>
  <div id="mars3dContainer" class="mars3d-container"></div>
</template>

<style>
.mars3d-container {
  width: 100%;
  height: 100%;
}
</style>