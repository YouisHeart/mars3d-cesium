<script setup>
import { ref, onMounted } from 'vue'
import * as Cesium from "cesium"

const cesiumContainer = ref(null);
let viewer = null;

onMounted(()=>{
  Cesium.Ion.defaultAccessToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJqdGkiOiJlMTRmNzJlMS1iYmY4LTQ0ZGItYjcwZS00NDk3OWU0MzFlNTgiLCJpZCI6MzE2MTcxLCJpYXQiOjE3NTEwMDI3Nzl9.-_pA6MMWnyPOMStsyb0ktnvAjsS5TVdlpL0tTLFxgNo"
  viewer = new Cesium.Viewer(cesiumContainer.value,{})
  viewer.scene.skyAtmosphere.show = true;
  viewer.scene.globe.showGroundAtmosphere = true;

  const clouds = viewer.scene.primitives.add(
  new Cesium.CloudCollection()
);

clouds.add({
  position: Cesium.Cartesian3.fromDegrees(116.39, 39.9, 3000),
  scale: new Cesium.Cartesian2(50000, 20000),
  maximumSize: new Cesium.Cartesian3(50000, 20000, 1500),
  slice: 0.9,
});

viewer.camera.flyTo({
  destination: Cesium.Cartesian3.fromDegrees(116.39, 39.9, 3000)
})
})

const count = ref(0)
</script>

<template>
 <div ref="cesiumContainer" style="width: 100vw; height: 100vh;"></div>
</template>

