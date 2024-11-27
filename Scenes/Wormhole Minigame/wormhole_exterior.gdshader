shader_type spatial;
render_mode diffuse_toon, specular_toon;

uniform sampler2D noise;
uniform sampler2D normalmap;


void fragment() {
	ALBEDO = vec3(0.25,0,1);
	ROUGHNESS = 0.0;
	METALLIC = 0.0;
	RIM = 0.75;
}

