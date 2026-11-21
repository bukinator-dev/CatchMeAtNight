// "No signal" snow for a CRT screen in the 3D office.
shader_type spatial;
render_mode unshaded;

uniform float brightness = 0.55;

float rand(vec2 co) { return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453); }

void fragment() {
	vec2 px = floor(UV * vec2(140.0, 105.0));
	float n = rand(px + floor(TIME * 24.0) * vec2(1.7, 9.2));
	float scan = 0.75 + 0.25 * sin(UV.y * 420.0);
	float roll = smoothstep(0.08, 0.0, abs(fract(UV.y - TIME * 0.2) - 0.5)) * 0.4;
	ALBEDO = vec3(n * brightness * scan + roll * 0.2);
}
