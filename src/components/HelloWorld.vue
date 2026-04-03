<script setup>
import { ref, onMounted } from 'vue'
import * as Cesium from "cesium"

const cesiumContainer = ref(null);
let viewer = null;

onMounted(async () => {
  Cesium.Ion.defaultAccessToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJqdGkiOiJlMTRmNzJlMS1iYmY4LTQ0ZGItYjcwZS00NDk3OWU0MzFlNTgiLCJpZCI6MzE2MTcxLCJpYXQiOjE3NTEwMDI3Nzl9.-_pA6MMWnyPOMStsyb0ktnvAjsS5TVdlpL0tTLFxgNo"
  
  viewer = new Cesium.Viewer(cesiumContainer.value, {
    terrain: Cesium.Terrain.fromWorldTerrain({
      requestWaterMask: true,
      requestVertexNormals: true
    })
  })
  
  viewer.scene.skyAtmosphere.show = true;
  viewer.scene.globe.showGroundAtmosphere = true;

  // 隐藏 logo
  viewer.cesiumWidget.creditContainer.style.display = "none";

  // 查看帧率
  viewer.scene.debugShowFramesPerSecond = true;

  const position = Cesium.Cartesian3.fromDegrees(116.3912757, 39.906217, 0);

  // 修复1: 使用 Cesium.Color.RED 或导入 Color
  const icon = viewer.entities.add({
    position: position,
    billboard: {
      image: "./icon/Location.png",
      verticalOrigin: 0,
      scale: 1.5,
      color: Cesium.Color.RED  // 修改这里
    },
    label: {
      text: "北京",
      font: "14pt monospace",
      style: 0,
      outlineWidth: 2,
      verticalOrigin: 1,
      pixelOffset: new Cesium.Cartesian2(0, -9)
    }
  })


  viewer.camera.flyTo({
    destination: Cesium.Cartesian3.fromDegrees(116.3912757, 39.906217, 50000),
    orientation: {
      heading: Cesium.Math.toRadians(30.0),
      pitch: Cesium.Math.toRadians(-25.0),
      roll: 0,
    },
    duration: 3.0
  })
})
</script>

<template>
  <div ref="cesiumContainer" style="width: 100vw; height: 100vh;"></div>
</template>