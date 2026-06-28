shader_type spatial;

uniform float cleanliness : hint_range(0.0, 1.0) = 0.0;
uniform vec4 clean_color : source_color = vec4(0.45, 0.65, 0.9, 1.0);
uniform vec4 dirty_color : source_color = vec4(0.22, 0.20, 0.15, 1.0);

void fragment() {
	ALBEDO = mix(dirty_color.rgb, clean_color.rgb, cleanliness);
	ROUGHNESS = mix(0.85, 0.08, cleanliness);
	METALLIC = 0.0;
	SPECULAR = mix(0.0, 0.75, cleanliness);
}
