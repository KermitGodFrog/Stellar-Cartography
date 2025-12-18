shader_type spatial;
render_mode diffuse_toon, specular_toon;

uniform sampler2D noise;
uniform sampler2D normal_map;
uniform sampler2D stars;
uniform vec4 color : source_color = vec4(0.501961,0.0,0.501961,1.0);

void fragment() {
	vec4 noise_texture = texture(noise, UV);
	vec4 star_texture = texture(stars, UV);
	ALBEDO = color.rgb * noise_texture.rgb;
	// + star_texture.rgb

	NORMAL_MAP = texture(normal_map, UV).rgb;

	ROUGHNESS = 0.0;
	METALLIC = 0.25;
	RIM = 0.5;
	RADIANCE = (star_texture * 4.0);
}