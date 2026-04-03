<script setup>
import { ref, onMounted } from 'vue'
import "mars3d-cesium/Build/Cesium/Widgets/widgets.css"
import * as Cesium from "cesium"
import "mars3d/mars3d.css"

import * as mars3d from "mars3d"
import "mars3d-space"

const map = ref(null)

onMounted(() => {
  map.value = new mars3d.Map("mars3dContainer", {
    scene:{
      center: { lat: 30.054604, lng: 108.885436, alt: 17036414, heading: 0, pitch: -90 },
      showSun: true,
      showMoon: true,
      showSkyBox: true,
      showSkyAtmosphere: false, // 关闭球周边的轮廓 
      fog: true,
      fxaa: true,
      globe: {
        showGroundAtmosphere: false, // 关闭大气
        depthTestAgainstTerrain: false,
        baseColor: "#546a53"
      },
      cameraController: {
        zoomFactor: 3.0,
        minimumZoomDistance: 1,
        maximumZoomDistance: 50000000,
        enableRotate: true,
        enableZoom: true
      },
      mapProjection: mars3d.CRS.EPSG3857, // 2D下展示墨卡托投影
      mapMode2D: Cesium.MapMode2D.INFINITE_SCROLL // 2D下左右一直可以滚动重复世界地图
    },
    control: {
      baseLayerPicker: true,
      homeButton: true,
      sceneModePicker: true,
      navigationHelpButton: true,
      fullscreenButton: true,
      contextmenu: { hasDefault: true} 
    },
    terrain: {
      url: "https://data.mars3d.cn/terrain",
      show: true
    },
    basemaps: [
      {
        name: "天地图影响",
        icon: "https://data.mars3d.cn/img/thumbnail/basemap/tdt_img.png",
        type: "tdt",
        layer: "img_d",
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