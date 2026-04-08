#version 300 es
precision highp float;

// 输入输出
in vec2 v_textureCoordinates;
out vec4 fragColor;

// 纹理
uniform sampler2D colorTexture;
uniform sampler2D depthTexture;

// Cesium 内置函数
// czm_unpackDepth, czm_windowToEyeCoordinates

// 简单噪声函数（占位）
float sampleNoise(vec3 p) {
    return fract(sin(dot(p, vec3(12.9898, 78.233, 45.164))) * 43758.5453);
}

void main() {
    vec4 sceneColor = texture(colorTexture, v_textureCoordinates);
    float depth = czm_unpackDepth(texture(depthTexture, v_textureCoordinates));

    // 世界空间射线方向
    vec4 positionEC = czm_windowToEyeCoordinates(gl_FragCoord.xy, depth);
    vec3 rayDir = normalize(positionEC.xyz);

    // 云层高度
    float cloudMinHeight = 2000.0; 
    float cloudMaxHeight = 5000.0;

    // 光线步进
    float cloudDensity = 0.0;
    float transmittance = 1.0;
    vec3 cloudColor = vec3(1.0);

    for(int i = 0; i < 32; i++) {
        vec3 samplePos = rayDir * (float(i) * 500.0);
        float noise = sampleNoise(samplePos * 0.0001);

        if(noise > 0.5) {
            float d = (noise - 0.5) * 0.2;
            cloudDensity += d * transmittance;
            transmittance *= (1.0 - d);
        }
        if(transmittance < 0.01) break;
    }

    // 输出最终颜色
    fragColor = mix(sceneColor, vec4(cloudColor, 1.0), cloudDensity);
}