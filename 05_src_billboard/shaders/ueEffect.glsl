 uniform sampler2D colorTexture;
uniform float exposure;
uniform float contrast;
uniform float gamma;
uniform float saturation;
uniform float vibrance;
uniform float temperature;
uniform float shadows;
uniform float midtones;
uniform float highlights;
uniform float sharpen;
uniform float vignette;

in vec2 v_textureCoordinates;

vec3 ACESFilm(vec3 x) {
float a = 2.51;
float b = 0.03;
float c = 2.43;
float d = 0.59;
float e = 0.14;
return clamp((x * (a * x + b)) / (x * (c * x + d) + e), 0.0, 1.0);
}

float luminance(vec3 c) {
return dot(c, vec3(0.2126, 0.7152, 0.0722));
}

void main() {
vec2 uv = v_textureCoordinates;
vec2 texelSize = 1.0 / czm_viewport.zw;

// 锐化
vec3 color;
if (sharpen > 0.0) {
    vec3 center = texture(colorTexture, uv).rgb;
    vec3 blur = texture(colorTexture, uv + vec2(-texelSize.x, 0.0)).rgb
                + texture(colorTexture, uv + vec2(texelSize.x, 0.0)).rgb
                + texture(colorTexture, uv + vec2(0.0, -texelSize.y)).rgb
                + texture(colorTexture, uv + vec2(0.0, texelSize.y)).rgb;
    blur *= 0.25;
    color = center + (center - blur) * sharpen;
} else {
    color = texture(colorTexture, uv).rgb;
}

// sRGB to Linear
color = pow(color, vec3(2.2));

// 曝光
color *= exposure;

// ACES色调映射
color = ACESFilm(color);

// 对比度
color = (color - 0.5) * contrast + 0.5;

// Lift/Gamma/Gain
color = color + shadows * (1.0 - color);
color = pow(max(color, vec3(0.0)), vec3(1.0 / midtones));
color = color * highlights;

// 色温
color.r += temperature * 0.15;
color.b -= temperature * 0.15;

// 饱和度
float lum = luminance(color);
color = mix(vec3(lum), color, saturation);

// 自然饱和度
float maxC = max(color.r, max(color.g, color.b));
float minC = min(color.r, min(color.g, color.b));
float sat = maxC - minC;
float amount = vibrance * (1.0 - sat) * (1.0 - sat);
color = mix(vec3(lum), color, 1.0 + amount);

// Gamma
color = pow(max(color, vec3(0.0)), vec3(1.0 / gamma));

// 暗角
if (vignette > 0.0) {
    vec2 vigUV = uv * (1.0 - uv);
    float vig = vigUV.x * vigUV.y * 15.0;
    vig = pow(vig, vignette * 0.5);
    color *= vig;
}

// Linear to sRGB
color = pow(color, vec3(1.0 / 2.2));

out_FragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}