<script setup>
import { ref, onMounted } from 'vue'
import * as Cesium from "cesium"
import "cesium/Build/Cesium/Widgets/widgets.css";


const cesiumContainer = ref(null);
let viewer = null;

// 噪声纹理URL（可替换为你的3D噪声纹理）
const noiseTextureUrl = new URL("./texture/Wpq1UDJ.png",import.meta.url).href

onMounted(async () => {
  Cesium.Ion.defaultAccessToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJqdGkiOiJlMTRmNzJlMS1iYmY4LTQ0ZGItYjcwZS00NDk3OWU0MzFlNTgiLCJpZCI6MzE2MTcxLCJpYXQiOjE3NTEwMDI3Nzl9.-_pA6MMWnyPOMStsyb0ktnvAjsS5TVdlpL0tTLFxgNo"

  viewer = new Cesium.Viewer(cesiumContainer.value, {
    terrain: Cesium.Terrain.fromWorldTerrain({
      requestWaterMask: true,
      requestVertexNormals: true
    }),
    scene3DOnly: true,
    shadows: true,
    baseLayerPicker: false
  })

  viewer.scene.skyAtmosphere.show = true;
  viewer.scene.globe.showGroundAtmosphere = true;
  viewer.scene.globe.depthTestAgainstTerrain = true;
  viewer.scene.postProcessStages.fxaa.enabled = true;
  viewer.cesiumWidget.creditContainer.style.display = "none";
  viewer.scene.debugShowFramesPerSecond = true;

  // 飞到初始位置
  viewer.camera.flyTo({
    destination: Cesium.Cartesian3.fromDegrees(116.3912757, 39.906217, 50000),
    orientation: {
      heading: Cesium.Math.toRadians(30.0),
      pitch: Cesium.Math.toRadians(-25.0),
      roll: 0,
    },
    duration: 3.0
  })

  // 加载噪声纹理
  const noiseTexture = await new Promise((resolve) => {
    const img = new Image()
    img.src = noiseTextureUrl
    img.onload = () => resolve(new Cesium.Texture({
      context: viewer.scene.context,
      source: img
    }))
  })

  // 创建体积云后处理
  const cloudStage = new Cesium.PostProcessStage({
    fragmentShader: `
    uniform sampler2D colorTexture;
    uniform sampler2D noiseTexture;
    uniform float iTime;
    varying vec2 v_textureCoordinates;

    // 简单伪3D噪声
    float hash(vec2 p) {
      return fract(sin(dot(p, vec2(127.1,311.7))) * 43758.5453123);
    }

    float noise(vec3 p){
      vec3 i = floor(p);
      vec3 f = fract(p);
      float n = i.x + i.y*57.0 + i.z*113.0;
      return mix(mix(mix(hash(i.xy), hash(i.xy+vec2(1.0,0.0)),f.x),
                     mix(hash(i.xy+vec2(0.0,1.0)), hash(i.xy+vec2(1.0,1.0)),f.x),f.y),
                 f.z);
    }

    void main(void){
      vec2 uv = v_textureCoordinates;
      vec4 color = texture2D(colorTexture, uv);

      // 体积云位置
      float cloudHeight = 0.2;
      float density = noise(vec3(uv*5.0, iTime*0.02));
      float cloud = smoothstep(cloudHeight-0.05, cloudHeight+0.05, density);

      // 混合云层
      vec3 finalColor = mix(color.rgb, vec3(1.0), cloud*0.6);
      gl_FragColor = vec4(finalColor, 1.0);
    }
    `,
    uniforms: {
      iTime: 0,
      noiseTexture
    }
  })

  viewer.scene.postProcessStages.add(cloudStage)

  // 更新time，实现动态流动
  viewer.scene.preRender.addEventListener((scene, time) => {
    cloudStage.uniforms.iTime += scene.deltaTime
  })
})
</script>

<template>
  <div ref="cesiumContainer" style="width: 100vw; height: 100vh;"></div>
</template>

<!-- 删除了空的 style 标签，或者添加：
<style scoped>
/* 样式代码 */
</style>
-->