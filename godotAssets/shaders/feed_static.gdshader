// Laid over a camera picture: grain, scanlines, a rolling band and a dark vignette.
// static_amount 0.1 = normal night feed, 1.0 = full static (when switching cams).
shader_type canvas_item;

uniform float static_amount : hint_range(0.0, 1.0) = 0.12;

float rand(vec2 co) { return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453); }

void fragment() {
	vec2 uv = UV;
	float n = rand(floor(uv * vec2(320.0, 240.0)) + vec2(floor(TIME * 30.0) * 1.37, floor(TIME * 30.0) * 3.11));
	float scan = 0.5 + 0.5 * sin(uv.y * 240.0 * 6.2831);
	float band = smoothstep(0.06, 0.0, abs(fract(uv.y + TIME * 0.12) - 0.5));
	float vign = smoothstep(0.35, 0.85, distance(uv, vec2(0.5)));

	float s = clamp(static_amount + band * 0.08, 0.0, 1.0);
	float d = clamp(scan * 0.18 + vign * 0.75, 0.0, 1.0) * (1.0 - static_amount);
	float a = clamp(s + d, 0.0, 1.0);
	vec3 noise_col = vec3(n) * (s / max(a, 0.001));
	COLOR = vec4(noise_col, a);
}
