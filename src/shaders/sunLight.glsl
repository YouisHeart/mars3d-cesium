uniform sampler2D colorTexture;
uniform sampler2D depthTexture;
// 从 Cesium 环境中获取的内置变量
in vec2 v_textureCoordinates;
// 随机函数：2D输入
float rnd(vec2 p) {
    float f = fract(sin(dot(p, vec2(12.1234, 72.8392))) * 45123.2);
    return f;
}
// 随机函数：1D输入
float rnd(float w) {
    float f = fract(sin(w) * 1000.);
    return f;
}
// 生成随机形状（六边形、星形等）
float regShape(vec2 p, int N) {
    float f;
    float a = atan(p.x, p.y) + 0.2;
    float b = 6.28319 / float(N);
    f = smoothstep(0.5, 0.51, cos(floor(0.5 + a / b) * b - a) * length(p.xy));
    return f;
}
// 圆形光晕 + 光环 + 小光斑效果
vec3 circle(vec2 p, float size, float decay, vec3 color, vec3 color2, float dist, vec2 mouse) {
    // 光晕强度随距离衰减
    float l = length(p + mouse * (dist * 4.)) + size / 2.;
    float l2 = length(p + mouse * (dist * 4.)) + size / 3.;
    
    // 中心光斑
    float c = max(0.01 - pow(length(p + mouse * dist), size * 1.4), 0.0) * 50.;
    
    // 周期性光纹
    float c1 = max(0.001 - pow(l - 0.3, 1. / 40.) + sin(l * 30.), 0.0) * 3.;
    
    // 次级光斑
    float c2 = max(0.04 / pow(length(p - mouse * dist / 2. + 0.09) * 1., 1.), 0.0) / 20.;
    
    // 随机星形
    float s = max(0.01 - pow(regShape(p * 5. + mouse * dist * 5. + 0.9, 6), 1.), 0.0) * 5.;
    // 动态色彩（叠加抖动）
    color = 0.5 + 0.5 * sin(color);
    color = cos(vec3(0.44, 0.24, 0.2) * 8. + dist * 4.) * 0.5 + 0.5;
    
    vec3 f = c * color;
    f += c1 * color;
    f += c2 * color;
    f += s * color;
    return f - 0.01;
}
// 太阳光源基础：越远越暗
float sun(vec2 p, vec2 mouse) {
    vec2 sunp = p + mouse;
    float sun = 1.0 - length(sunp) * 8.;
    return sun;
}
// 主函数
void main() {
    // 获取时间（动态控制）
    float iTime = czm_frameNumber / 10000.0;
    
    // 获取原始场景颜色和深度
    vec4 sceneColor = texture(colorTexture, v_textureCoordinates);
    vec2 uv = gl_FragCoord.xy / czm_viewport.zw - 0.5;
    uv.x *= czm_viewport.z / czm_viewport.w;
    
    float depth = czm_unpackDepth(texture(depthTexture, v_textureCoordinates));
    
    // 获取太阳位置（世界坐标 -> 屏幕坐标）
    vec4 sunPos = czm_morphTime == 1.0 ? vec4(czm_sunPositionWC, 1.0) : vec4(czm_sunPositionColumbusView.zxy, 1.0);
    vec4 sunPositionEC = czm_view * sunPos;
    vec4 sunPositionWC = czm_eyeToWindowCoordinates(sunPositionEC);
    vec4 sunInView = czm_viewportOrthographic * vec4(sunPositionWC.xy, -sunPositionWC.z, 1.0);
    vec2 mm = sunInView.xy;
    mm.x *= czm_viewport.z / czm_viewport.w;
    // 背景颜色渐变（从地底到高空）
    vec3 circColor = vec3(0.9, 0.2, 0.1);
    vec3 circColor2 = vec3(0.3, 0.1, 0.9);
    vec3 color = mix(vec3(0.3, 0.2, 0.02) / 0.9, vec3(0.2, 0.5, 0.8), uv.y) * 3. - 0.52 * sin(iTime);
    // 多层光晕叠加
    for (float i = 0.0; i < 10.0; i++) {
        float scale = pow(rnd(i * 2000.0) * 1.8, 2.0) + 1.41;
        float dist = rnd(i * 20.0) * 3.0 + 0.2 - 0.5;
        color += circle(uv, scale, 0.0, circColor + vec3(i), circColor2 + vec3(i), dist, mm);
    }
    // 从中心扩散效果
    float a = atan(uv.y - mm.y, uv.x - mm.x);
    float l = max(1.0 - length(uv - mm) - 0.84, 0.0);
    // 光辉细节叠加
    float bright = 0.1;
    color += max(0.1 / pow(length(uv - mm) * 5.0, 5.0), 0.0) * abs(sin(a * 5.0 + cos(a * 9.0))) / 20.0;
    color += max(0.1 / pow(length(uv - mm) * 10.0, 1.0 / 20.0), 0.0) + abs(sin(a * 3.0 + cos(a * 9.0))) / 8.0 * (abs(sin(a * 9.0))) / 1.0;
    color += (max(bright / pow(length(uv - mm) * 4.0, 1.0 / 2.0), 0.0) * 4.0) * vec3(0.2, 0.21, 0.3) * 4.0;
    // 衰减：越远越暗
    color *= exp(1.0 - length(uv - mm)) / 5.0;
    // 深度混合：只有在光源上方的区域才叠加光照
    vec4 sunDepthColor = texture(depthTexture, v_textureCoordinates);
    float sunDepth = sunDepthColor.r;
    
    if (depth > sunDepth) {
        out_FragColor = sceneColor;
    } else {
        out_FragColor = vec4(color, 1.0) * vec4(vec4(color, 1.0).aaa, 1.0) + sceneColor * (2.001 - vec4(color, 1.0).a);
    }
}