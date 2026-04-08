<script setup>
import { ref, onMounted, onBeforeUnmount } from 'vue'
import * as Cesium from "cesium"
import "cesium/Build/Cesium/Widgets/widgets.css";
import cloud from "@/shaders/cloud.glsl"

const cesiumContainer = ref(null);
let viewer = null;

onMounted(async () => {
  Cesium.Ion.defaultAccessToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJqdGkiOiJlMTRmNzJlMS1iYmY4LTQ0ZGItYjcwZS00NDk3OWU0MzFlNTgiLCJpZCI6MzE2MTcxLCJpYXQiOjE3NTEwMDI3Nzl9.-_pA6MMWnyPOMStsyb0ktnvAjsS5TVdlpL0tTLFxgNo";

  viewer = new Cesium.Viewer(cesiumContainer.value, {
    terrain: Cesium.Terrain.fromWorldTerrain({
      requestWaterMask: true,
      requestVertexNormals: true
    }),
    scene3DOnly: true,
    shadows: true,
    baseLayerPicker: false,
    timeline: false,
    animation: false
  });

  viewer.scene.skyAtmosphere.show = true;
  viewer.scene.globe.showGroundAtmosphere = true;
  viewer.scene.globe.depthTestAgainstTerrain = true;
  viewer.scene.postProcessStages.fxaa.enabled = true;
  viewer.cesiumWidget.creditContainer.style.display = "none";
  viewer.scene.debugShowFramesPerSecond = true;

  const cloudStage = new Cesium.PostProcessStage({
    fragmentShader: cloud,
    uniforms:{
      noiseTexture: "./texture/Wpq1UDJ.png"
    }
  })
  viewer.scene.postProcessStages.add(cloudStage);

  
  // 飞入视角
  viewer.camera.flyTo({
    destination: Cesium.Cartesian3.fromDegrees(116.3912757, 39.906217, 500000),
    orientation: {
      heading: Cesium.Math.toRadians(30.0),
      pitch: Cesium.Math.toRadians(-30.0),
      roll: 0
    },
    duration: 3.0
  });
});

onBeforeUnmount(() => {
  if (viewer) {
    viewer.destroy();
    viewer = null;
  }
});
</script>

<template>
  <div ref="cesiumContainer" style="width: 100vw; height: 100vh;"></div>
</template>

<style scoped>
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

:deep(.cesium-viewer-timelineContainer) {
  display: none;
}

:deep(.cesium-viewer-animationContainer) {
  display: none;
}
</style>