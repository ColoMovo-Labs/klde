// SPDX-License-Identifier: GPL-3.0-or-later
// Composites one material tier over a pre-blurred, KLDE-owned wallpaper sample:
// rounded-rect coverage, edge refraction, saturation, tint, fixed grain and a
// light-facing rim. Every input is a uniform; nothing here depends on time.
#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 size;
    float radius;
    float refraction;
    float edge;
    float dispersion;
    vec4 tint;
    float tintOpacity;
    float saturation;
    float grain;
    float rim;
    float specular;
    vec2 lightDir;
    float press;
};

layout(binding = 1) uniform sampler2D source;

float roundedBox(vec2 p, vec2 halfSize, float r) {
    vec2 q = abs(p) - halfSize + vec2(r);
    return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r;
}

vec2 clampUv(vec2 uv) {
    return clamp(uv, vec2(0.0), vec2(1.0));
}

void main() {
    vec2 halfSize = 0.5 * size;
    vec2 p = (qt_TexCoord0 - 0.5) * size;
    float r = min(radius, min(halfSize.x, halfSize.y));
    float d = roundedBox(p, halfSize, r);
    float coverage = clamp(0.5 - d, 0.0, 1.0);
    if (coverage <= 0.0) {
        fragColor = vec4(0.0);
        return;
    }

    // Outward surface normal from the distance field gradient.
    vec2 h = vec2(0.5, 0.0);
    vec2 normal = vec2(roundedBox(p + h.xy, halfSize, r) - roundedBox(p - h.xy, halfSize, r),
                       roundedBox(p + h.yx, halfSize, r) - roundedBox(p - h.yx, halfSize, r));
    normal /= max(length(normal), 1e-4);
    float inset = max(-d, 0.0);

    // Convex lens profile: displacement rises quadratically toward the rim and
    // pulls samples inward, magnifying what sits under the edge.
    float band = edge > 0.0 ? clamp(1.0 - inset / edge, 0.0, 1.0) : 0.0;
    float bend = refraction * (1.0 + 0.4 * press) * band * band;
    vec2 offset = -normal * bend / size;
    vec3 color;
    if (bend > 0.0 && dispersion > 0.0) {
        color.r = texture(source, clampUv(qt_TexCoord0 + offset * (1.0 + dispersion))).r;
        color.g = texture(source, clampUv(qt_TexCoord0 + offset)).g;
        color.b = texture(source, clampUv(qt_TexCoord0 + offset * (1.0 - dispersion))).b;
    } else {
        color = texture(source, clampUv(qt_TexCoord0 + offset)).rgb;
    }

    float luminance = dot(color, vec3(0.2126, 0.7152, 0.0722));
    color = mix(vec3(luminance), color, saturation);
    color = mix(color, tint.rgb, tintOpacity);

    // Static per-pixel grain: it is keyed to the fragment, never to time.
    float n = fract(sin(dot(floor(gl_FragCoord.xy), vec2(12.9898, 78.233))) * 43758.5453);
    color += (n - 0.5) * grain;

    // Elevation rim: light along edges facing the light, a faint shade opposite.
    float facing = dot(normal, normalize(lightDir));
    float stroke = clamp(1.5 - inset, 0.0, 1.0) * rim;
    color = mix(color, vec3(1.0), stroke * clamp(0.55 + 0.45 * facing, 0.0, 1.0));
    color = mix(color, vec3(0.0), stroke * 0.35 * clamp(-facing, 0.0, 1.0));

    // Glass sheen inside the lens band on the lit side.
    color += band * band * max(facing, 0.0) * specular * (0.26 + 0.18 * press);

    fragColor = vec4(clamp(color, 0.0, 1.0) * coverage, coverage) * qt_Opacity;
}
