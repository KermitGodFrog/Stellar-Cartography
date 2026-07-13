shader_type canvas_item;

float remap(float value, float in_min, float in_max)
{
	return (value - in_min) / (in_max - in_min);
}

void fragment() {
	vec4 tex_col = texture(TEXTURE, UV);
	float fade_value = 1.0 - (distance(UV, vec2(0.5,0.5)) * 2.0);
	fade_value = remap(fade_value, 0.05,0.3);
	COLOR.a = mix(0.0, 1.0 * tex_col.a, fade_value);
}