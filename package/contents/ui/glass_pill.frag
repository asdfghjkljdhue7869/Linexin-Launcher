#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec4 region;
    vec4 tintV;
    vec2 pxSize;
    float hover;
    float tier;
    float rad;
};
layout(binding = 1) uniform sampler2D wash;

vec2 toUv(vec2 s) {
    return region.xy + (s + vec2(0.5)) * region.zw;
}

void main() {
    vec2 p = (qt_TexCoord0 - vec2(0.5)) * pxSize;
    vec2 hs = pxSize * 0.5;
    float r = min(hs.x, hs.y) * rad;
    vec2 qv = abs(p) - (hs - vec2(r));
    vec2 qm = max(qv, vec2(0.0));
    float d = length(qm) + min(max(qv.x, qv.y), 0.0) - r;
    float mask = 1.0 - smoothstep(-1.0, 1.0, d);
    float h = clamp(hover, 0.0, 1.3);
    float band = clamp(r * 0.8, 4.0, 12.0);
    float k = pow(1.0 - clamp(-d / band, 0.0, 1.0), 2.2);
    float lens = 0.50 + 0.20 * h + 0.15 * tier;
    float drift = 0.16 + 0.10 * tier + 0.06 * h;
    vec2 s = p / pxSize;
    vec2 sr = s * (1.0 - lens * (1.0 - drift) * k);
    vec2 sg = s * (1.0 - lens * k);
    vec2 sb = s * (1.0 - lens * (1.0 + drift) * k);
    vec4 g0 = texture(wash, toUv(sg));
    vec3 col = vec3(texture(wash, toUv(sr)).r, g0.g, texture(wash, toUv(sb)).b);
    float lum = dot(col, vec3(0.299, 0.587, 0.114));
    col = mix(vec3(lum), col, 1.18);
    vec2 n;
    if (length(qm) > 0.001) {
        n = normalize(qm * sign(p));
    } else {
        n = (qv.x > qv.y) ? vec2(sign(p.x), 0.0) : vec2(0.0, sign(p.y));
    }
    float l = dot(n, normalize(vec2(-0.45, -1.0)));
    float tl = pow(max(l, 0.0), 2.0);
    float brr = pow(max(-l, 0.0), 2.0);
    float line = exp(-pow((d + 1.0) / 1.0, 2.0));
    float spec = line * (0.04 + 1.15 * tl) + line * brr * 0.22;
    float line2 = exp(-pow((d + 3.0) / 1.2, 2.0));
    float refl = line2 * brr * 0.45;
    float meniscus = exp(-pow((d + 4.0) / 3.5, 2.0)) * tl * 0.10;
    float fa = (0.35 + 0.45 * abs(l)) * (0.55 + 0.40 * tier + 0.30 * h);
    vec3 prism = vec3(exp(-pow((d + 1.2) / 1.0, 2.0)), exp(-pow((d + 2.0) / 1.0, 2.0)), exp(-pow((d + 2.8) / 1.0, 2.0))) * fa * 0.38;
    float top = 0.05 * (1.0 - smoothstep(-hs.y, hs.y * 0.2, p.y));
    vec3 add = vec3(spec + refl + meniscus + top * (1.0 - k)) + prism;
    col = mix(col, tintV.rgb, tintV.a);
    float a = clamp(0.07 + 0.55 * k + 0.05 * h + tintV.a * 0.85, 0.0, 1.0);
    float glow = max(add.r, max(add.g, add.b));
    fragColor = vec4(col * a + add, clamp(a + glow * 0.7, 0.0, 1.0)) * mask * qt_Opacity;
}
