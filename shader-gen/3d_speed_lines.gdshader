shader_type spatial;

render_mode
    cull_disabled,
    unshaded,
    blend_mix;

group_uniforms Speed_Lines;
uniform vec4 color1: source_color;
uniform vec4 color2: source_color;
uniform sampler2D noise_texture; // Our noise texture
uniform vec2 direction; // Direction of UV movement
uniform float speed : hint_range(0.0, 10.0); // Speed of UV movement

group_uniforms Refraction_Efects;
uniform float refraction_strength : hint_range(0.0, 8.0, 0.001) = 0.05;
uniform sampler2D screen_texture : hint_screen_texture;
uniform sampler2D depth_texture : hint_depth_texture;
uniform sampler2D normal_map;

group_uniforms Fading_Ends;
uniform float model_height = 2.0;
uniform float dissolve_start : hint_range(0.0, 1.0) = 0.0;
uniform float dissolve_length : hint_range(0.0, 1.0) = 1.0;
uniform float gradient_bias : hint_range(0.1, 5.0) = 1.0;
varying float vertex_height;

vec2 refract_uv(vec2 uv_coords, float _refraction_strength, vec3 surface_normal) {
    float refraction_intensity = _refraction_strength * 1.0;
    uv_coords += refraction_intensity * length(surface_normal) - refraction_intensity * 1.2;
    return uv_coords;
}

vec3 calculate_neon_effect(float value, vec3 base_color) {
    float ramp = clamp(value, 0.0, 1.0);
    vec3 neon_color = vec3(0.0);
    ramp = ramp * ramp;
    neon_color += pow(base_color, vec3(4.0)) * ramp;
    ramp = ramp * ramp;
    neon_color += base_color * ramp;
    ramp = ramp * ramp;
    neon_color += vec3(1.0) * ramp;
    return neon_color;
}

void vertex() {
    // For fading effect
    vertex_height = (VERTEX.y + (model_height / 2.0)) / model_height;
}

void fragment() {
    vec2 uv_movement = UV + direction.xy * TIME * speed;
    // Sample the noise texture with the moving UVs
    vec4 noise_color1 = texture(noise_texture, uv_movement);
    vec4 noise_color2 = texture(noise_texture, uv_movement + vec2(0.50));
    
    vec3 normal_map_rgb = texture(normal_map, uv_movement).rgb;

    // Apply noise color to the fragment
    ALBEDO = calculate_neon_effect(0.50 + noise_color1.a, color1.rgb);
    ALBEDO += calculate_neon_effect(0.50 + noise_color2.a, color2.rgb);
    
    float alpha_blend = noise_color1.a + noise_color2.a;
    
    ALBEDO = mix(ALBEDO, texture(screen_texture, refract_uv(SCREEN_UV, refraction_strength, normal_map_rgb)).rgb, 1.0 - alpha_blend);

    // Fading effects fragment part
    float gradient_height = abs(vertex_height - (dissolve_start + dissolve_length * 0.5));
    gradient_height *= 1.0 / dissolve_length;
    gradient_height = clamp(pow(gradient_height, gradient_bias), 0.0, 1.0);
    
    ALPHA = mix(1.0, 0.0, gradient_height);
}
