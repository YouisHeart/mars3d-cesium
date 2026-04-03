<script setup>
import { ref, onMounted } from 'vue'
import * as Cesium from "cesium"
import ueEffect from "@/shaders/ueEffect.glsl?raw"
import sunLight from "@/shaders/sunLight.glsl"
import GUI from 'lil-gui'

const cesiumContainer = ref(null);
let viewer = null;

onMounted(()=>{
  Cesium.Ion.defaultAccessToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJqdGkiOiJlMTRmNzJlMS1iYmY4LTQ0ZGItYjcwZS00NDk3OWU0MzFlNTgiLCJpZCI6MzE2MTcxLCJpYXQiOjE3NTEwMDI3Nzl9.-_pA6MMWnyPOMStsyb0ktnvAjsS5TVdlpL0tTLFxgNo"
  viewer = new Cesium.Viewer(cesiumContainer.value,{
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

   const stage = new Cesium.PostProcessStage({
    name: 'sunLightEffect',
    fragmentShader: sunLight
  })

  viewer.scene.postProcessStages.add(stage)

 viewer.camera.flyTo({
    destination: Cesium.Cartesian3.fromDegrees(7.65, 45.92, 15000),
    orientation: {
      heading: Cesium.Math.toRadians(30.0),
      pitch: Cesium.Math.toRadians(-25.0),
      roll: 0,
    },
    duration: 3.0
  })


     const params = {
        enable: true,
        exposure: 1.0,
        contrast: 1.0,
        gamma: 1.0,
        saturation: 1.0,
        vibrance: 0.0,
        temperature: 0.0,
        shadows: 0.0,
        midtones: 1.0,
        highlights: 1.0,
        sharpen: 0.0,
        vignette: 0.0,
      };

      // UE5风格预设
      const ue5Preset = {
        exposure: 1.2,
        contrast: 1.15,
        gamma: 0.95,
        saturation: 1.1,
        vibrance: 0.2,
        temperature: 0.05,
        shadows: 0.05,
        midtones: 1.05,
        highlights: 1.0,
        sharpen: 0.25,
        vignette: 0.15,
      };

      const defaultParams = {
        exposure: 1.0,
        contrast: 1.0,
        gamma: 1.0,
        saturation: 1.0,
        vibrance: 0.0,
        temperature: 0.0,
        shadows: 0.0,
        midtones: 1.0,
        highlights: 1.0,
        sharpen: 0.0,
        vignette: 0.0,
  };

  // 创建后处理阶段
      let filterStage = null;

      function createFilterStage() {
        if (filterStage) {
          viewer.scene.postProcessStages.remove(filterStage);
          filterStage = null;
        }

        if (!params.enable) return;

        filterStage = new Cesium.PostProcessStage({
          fragmentShader: ueEffect,
          uniforms: {
            exposure: () => params.exposure,
            contrast: () => params.contrast,
            gamma: () => params.gamma,
            saturation: () => params.saturation,
            vibrance: () => params.vibrance,
            temperature: () => params.temperature,
            shadows: () => params.shadows,
            midtones: () => params.midtones,
            highlights: () => params.highlights,
            sharpen: () => params.sharpen,
            vignette: () => params.vignette,
          },
        });

        viewer.scene.postProcessStages.add(filterStage);
      }

      createFilterStage();

      // 初始化 GUI
      const gui = new GUI({ title: "Cesium UE5 滤镜" });

      const actions = {
        applyUE5Preset: () => {
          Object.assign(params, ue5Preset);
          gui.controllersRecursive().forEach((c) => c.updateDisplay());
        },
        reset: () => {
          Object.assign(params, defaultParams);
          gui.controllersRecursive().forEach((c) => c.updateDisplay());
        },
        copyCode: () => {
          const code = `// UE5风格后处理滤镜配置
const filterParams = {
    exposure: ${params.exposure.toFixed(2)},
    contrast: ${params.contrast.toFixed(2)},
    gamma: ${params.gamma.toFixed(2)},
    saturation: ${params.saturation.toFixed(2)},
    vibrance: ${params.vibrance.toFixed(2)},
    temperature: ${params.temperature.toFixed(2)},
    shadows: ${params.shadows.toFixed(2)},
    midtones: ${params.midtones.toFixed(2)},
    highlights: ${params.highlights.toFixed(2)},
    sharpen: ${params.sharpen.toFixed(2)},
    vignette: ${params.vignette.toFixed(2)}
};`;
          navigator.clipboard.writeText(code).then(() => {
            alert("配置代码已复制到剪贴板!");
          });
        },
      };

      gui
        .add(params, "enable")
        .name("启用滤镜 (Enable)")
        .onChange(createFilterStage);

      const folderTone = gui.addFolder("色调映射 (Tone Mapping)");
      folderTone
        .add(params, "exposure", 0.5, 2.5, 0.05)
        .name("曝光 (Exposure)");
      folderTone
        .add(params, "contrast", 0.5, 1.8, 0.05)
        .name("对比度 (Contrast)");
      folderTone.add(params, "gamma", 0.6, 1.6, 0.05).name("Gamma");

      const folderColor = gui.addFolder("色彩调整 (Color)");
      folderColor
        .add(params, "saturation", 0, 2, 0.05)
        .name("饱和度 (Saturation)");
      folderColor
        .add(params, "vibrance", -0.5, 1, 0.05)
        .name("自然饱和度 (Vibrance)");
      folderColor
        .add(params, "temperature", -0.5, 0.5, 0.02)
        .name("色温 (Temperature)");

      const folderLight = gui.addFolder("亮度层级 (Levels)");
      folderLight
        .add(params, "shadows", -0.2, 0.3, 0.02)
        .name("暗部 (Shadows)");
      folderLight
        .add(params, "midtones", 0.7, 1.3, 0.02)
        .name("中间调 (Midtones)");
      folderLight
        .add(params, "highlights", 0.7, 1.3, 0.02)
        .name("高光 (Highlights)");

      const folderEffects = gui.addFolder("特效 (Effects)");
      folderEffects.add(params, "sharpen", 0, 1, 0.05).name("锐化 (Sharpen)");
      folderEffects
        .add(params, "vignette", 0, 0.8, 0.05)
        .name("暗角 (Vignette)");

      const folderActions = gui.addFolder("操作 (Actions)");
      folderActions.add(actions, "applyUE5Preset").name("应用 UE5 预设");
      folderActions.add(actions, "reset").name("重置参数");
      folderActions.add(actions, "copyCode").name("复制配置代码");
})
   
</script>

<template>
 <div ref="cesiumContainer" style="width: 100vw; height: 100vh;"></div>
</template>

