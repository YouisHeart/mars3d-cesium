#version 300 es
precision highp float;

// ===== Cesium 内置 =====
uniform sampler2D colorTexture;
in vec2 v_textureCoordinates;
out vec4 fragColor;

// ===== 自定义 =====
uniform sampler2D noiseTex;
uniform float iTime;

// ===== 工具函数 =====
vec3 getRayDir(vec2 uv)
{
    vec2 ndc = uv * 2.0 - 1.0;

    vec4 clip = vec4(ndc, 1.0, 1.0);
    vec4 view = czm_inverseProjection * clip;
    view /= view.w;

    vec4 world = czm_inverseView * vec4(view.xyz, 0.0);

    return normalize(world.xyz);
}

// ===== 噪声 =====
float noise(vec3 x)
{
    vec3 p = floor(x);
    vec3 f = fract(x);
    f = f*f*(3.0-2.0*f);

    vec2 uv = (p.xy + vec2(37.0,239.0)*p.z) + f.xy;
    vec2 rg = texture(noiseTex,(uv+0.5)/256.0).yx;

    return mix(rg.x, rg.y, f.z)*2.0-1.0;
}

// ===== 云密度（核心）=====
float cloudDensity(vec3 p)
{
    vec3 q = p - vec3(0.0,0.1,1.0) * iTime;

    float f = 0.0;
    float a = 0.5;

    for(int i=0;i<5;i++){
        f += a * noise(q);
        q *= 2.02;
        a *= 0.5;
    }

    float density = 1.5 - p.y - 2.0 + 1.75 * f;

    return clamp(density, 0.0, 1.0);
}

// ===== Raymarch =====
vec4 raymarchCloud(vec3 ro, vec3 rd)
{
    vec4 sum = vec4(0.0);
    float t = 0.0;

    for(int i = 0; i < 64; i++)
    {
        vec3 pos = ro + t * rd;

        // 云层高度限制（世界坐标，可自行调）
        if(pos.y < 1000.0 || pos.y > 5000.0)
        {
            t += 100.0;
            continue;
        }

        float den = cloudDensity(pos * 0.0005); // 缩放控制云大小

        if(den > 0.01)
        {
            vec3 lightDir = normalize(vec3(-0.5,0.6,-0.7));

            float dif = clamp(
                (den - cloudDensity((pos + 300.0 * lightDir) * 0.0005)) / 0.3,
                0.0, 1.0
            );

            vec3 col = mix(
                vec3(1.0,0.95,0.85),
                vec3(0.3,0.35,0.4),
                den
            );

            col *= vec3(1.0,0.7,0.4) * dif + vec3(0.6);

            float alpha = den * 0.5;

            vec4 cloud = vec4(col * alpha, alpha);

            sum += cloud * (1.0 - sum.a);
        }

        t += max(50.0, 0.02 * t);

        if(sum.a > 0.98) break;
    }

    return clamp(sum, 0.0, 1.0);
}

// ===== 主函数 =====
void main()
{
    vec2 uv = gl_FragCoord.xy / czm_viewport.zw;

    vec4 sceneColor = texture(colorTexture, v_textureCoordinates);

    vec3 ro = czm_inverseView[3].xyz;
    vec3 rd = getRayDir(uv);

    vec4 cloud = raymarchCloud(ro, rd);

    // 混合场景
    vec3 finalColor = mix(sceneColor.rgb, cloud.rgb, cloud.a);

    fragColor = vec4(finalColor, 1.0);
}