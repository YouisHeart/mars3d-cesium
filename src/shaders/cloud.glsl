precision highp float;

uniform sampler2D colorTexture;
uniform sampler2D depthTexture;

in vec2 v_textureCoordinates;
out vec4 fragColor;

// ================= 参数 =================

// 相机 & 光照
uniform vec3 u_cameraPos;      // 相机世界坐标
uniform vec3 u_lightDir;       // 太阳方向（归一化）

// 星球参数
uniform float u_planetRadius;
uniform float u_atmoRadius;

// 散射参数
uniform vec3 beta_ray;         // 瑞利散射系数
uniform vec3 beta_mie;         // 米氏散射系数
uniform vec3 beta_absorption;  // 吸收（臭氧）
uniform vec3 beta_ambient;     // 环境光

uniform float g;               // mie方向性
uniform float scale_height;
uniform float height_absorption;
uniform float absorption_falloff;

uniform float light_intensity;

// 步进
const int STEPS_I = 16;
const int STEPS_L = 8;

// ================= 工具函数 =================

// Cesium深度转世界坐标（关键！）
vec3 getWorldPos(vec2 uv) {
    float depth = texture(depthTexture, uv).r;
    vec4 clip = vec4(uv * 2.0 - 1.0, depth, 1.0);
    vec4 view = czm_inverseProjection * clip;
    view /= view.w;
    vec4 world = czm_inverseView * view;
    return world.xyz;
}

// 光线-球体相交
bool raySphere(vec3 ro, vec3 rd, float radius, out float t0, out float t1) {
    float a = dot(rd, rd);
    float b = 2.0 * dot(rd, ro);
    float c = dot(ro, ro) - radius * radius;
    float d = b*b - 4.0*a*c;

    if (d < 0.0) return false;

    float s = sqrt(d);
    t0 = (-b - s) / (2.0 * a);
    t1 = (-b + s) / (2.0 * a);
    return true;
}

// ================= 主逻辑 =================

void main() {

    vec4 scene_color = texture(colorTexture, v_textureCoordinates);

    // 世界坐标
    vec3 worldPos = getWorldPos(v_textureCoordinates);

    // 视线方向
    vec3 dir = normalize(worldPos - u_cameraPos);
    vec3 start = u_cameraPos;

    // ===== 1. 与大气层求交 =====
    float t0, t1;
    if (!raySphere(start, dir, u_atmoRadius, t0, t1)) {
        fragColor = scene_color;
        return;
    }

    t0 = max(t0, 0.0);

    float segmentLength = (t1 - t0) / float(STEPS_I);
    float rayPos = t0;

    // ===== 相函数 =====
    float mu = dot(dir, u_lightDir);
    float mumu = mu * mu;
    float gg = g * g;

    float phase_ray = 3.0 / (16.0 * 3.1415926) * (1.0 + mumu);
    float phase_mie = 3.0 / (8.0 * 3.1415926) *
        ((1.0 - gg) * (mumu + 1.0)) /
        (pow(1.0 + gg - 2.0 * mu * g, 1.5) * (2.0 + gg));

    // ===== 累计量 =====
    vec3 opt_i = vec3(0.0);
    vec3 total_ray = vec3(0.0);
    vec3 total_mie = vec3(0.0);

    // ===== 外层 RayMarch =====
    for (int i = 0; i < STEPS_I; i++) {

        vec3 pos_i = start + dir * (rayPos + segmentLength * 0.5);
        float height = length(pos_i) - u_planetRadius;

        // 密度
        vec3 density = vec3(exp(-height / scale_height), 0.0);

        float denom = (height_absorption - height) / absorption_falloff;
        density.z = (1.0 / (denom * denom + 1.0)) * density.x;

        density *= segmentLength;

        opt_i += density;

        // ===== 内层 RayMarch（光线）=====
        float t0l, t1l;
        raySphere(pos_i, u_lightDir, u_atmoRadius, t0l, t1l);

        float stepL = t1l / float(STEPS_L);
        float rayPosL = stepL * 0.5;

        vec3 opt_l = vec3(0.0);

        for (int j = 0; j < STEPS_L; j++) {

            vec3 pos_l = pos_i + u_lightDir * rayPosL;
            float height_l = length(pos_l) - u_planetRadius;

            vec3 density = vec3(exp(-height / scale_height), 0.0, 0.0);

            float denom_l = (height_absorption - height_l) / absorption_falloff;
            density_l.z = (1.0 / (denom_l * denom_l + 1.0)) * density_l.x;

            density_l *= stepL;

            opt_l += density_l;

            rayPosL += stepL;
        }

        // ===== 衰减 =====
        vec3 attn = exp(
            -beta_ray * (opt_i.x + opt_l.x)
            -beta_mie * (opt_i.y + opt_l.y)
            -beta_absorption * (opt_i.z + opt_l.z)
        );

        total_ray += density.x * attn;
        total_mie += density.y * attn;

        rayPos += segmentLength;
    }

    // ===== 透明度 =====
    vec3 opacity = exp(
        -(beta_mie * opt_i.y + beta_ray * opt_i.x + beta_absorption * opt_i.z)
    );

    // ===== 最终颜色 =====
    vec3 color =
        phase_ray * beta_ray * total_ray +
        phase_mie * beta_mie * total_mie +
        opt_i.x * beta_ambient;

    color *= light_intensity;

    vec3 finalColor = color + scene_color.rgb * opacity;

    fragColor = vec4(finalColor, 1.0);
}