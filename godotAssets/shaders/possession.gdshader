// Lilly "possession" effect: 0 = cute stage idol, 1 = what she is at 3 AM.
shader_type canvas_item;

uniform float possession : hint_range(0.0, 1.0) = 0.0;
uniform vec4 blood_tint : source_color = vec4(0.62, 0.04, 0.08, 1.0);
uniform float glitch_strength = 0.018;

float hash(float n) { return fract(sin(n) * 43758.5453); }

void fragment() {
	vec2 uv = UV;
	float t = TIME;

	// Horizontal slice glitch: a few rows jump sideways for a frame.
	float row = floor(uv.y * 48.0);
	float tick = floor(t * 14.0);
	float slice = step(0.965, hash(row * 1.7 + tick));
	uv.x += (hash(row + tick) - 0.5) * 2.0 * glitch_strength * slice * possession;

	vec4 c = texture(TEXTURE, uv);

	// Drain the color, then soak what's left in red.
	float luma = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	vec3 drained = mix(vec3(luma), blood_tint.rgb * (luma * 1.6), 0.4);

	// Uneven flicker, like a dying stage bulb.
	float flicker = 0.82 + 0.18 * sin(t * 37.0) * sin(t * 5.3);
	drained *= flicker;

	c.rgb = mix(c.rgb, drained, possession);
	COLOR = c * COLOR;
}
