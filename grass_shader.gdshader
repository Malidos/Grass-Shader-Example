shader_type spatial;
render_mode cull_disabled, diffuse_toon, specular_schlick_ggx;
// Nice Shader by @_Malido ^^

uniform vec3 top_color: source_color;
uniform vec3 bottom_color: source_color;
uniform float player_displacement_strength: hint_range(0.0, 1.0, 0.01) = 0.4;
uniform float player_displacement_size: hint_range(0.0, 2.0, 0.01) = 1.0;

uniform vec3 wind_direction; // Use a negative y component to give it an extra touch (For displacement effect and noise scroll direction)
uniform float wind_strength: hint_range(0.0, 1.0, 0.01) = 0.3;
uniform sampler2D wind_noise; // Periln FBM Noise looks Best
uniform float wind_noise_size: hint_range(0.0, 1.0, 0.001) = 0.05; // high values dont work well
uniform float wind_noise_speed: hint_range(0.0, 1.0, 0.001) = 0.1;

// Instance the Player Position through a GDScript in the _physics_process
instance uniform vec3 player_position;

void vertex() {
	vec3 world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	
	vec3 wind_texture = texture(wind_noise, world_position.xz * wind_noise_size + normalize(-wind_direction.xz) * TIME * wind_noise_speed).rgb;
	vec3 wind_vector = (vec4(wind_texture * normalize(wind_direction) * wind_strength, 0.0) * MODEL_MATRIX).xyz;
	
	float player_height = smoothstep(1.0, 0.0, length(player_position.y - world_position.y + 0.3));
	vec3 push_direction = vec3(world_position - player_position) * vec3(1 , -0.3 ,1);
	float player_position_factor = smoothstep(player_displacement_size, 0.0, length(push_direction));
	
	vec3 player_push_vector = (vec4(normalize(push_direction), 0.0) * MODEL_MATRIX).xyz;
	
	// Apply Player Position displacement
	VERTEX += player_push_vector * (1.0 - UV.y) * player_position_factor * player_displacement_strength * player_height;
	// Apply Wind displacement (Mixes linear with exponential displacement)
	VERTEX += wind_vector * mix(2.0 * (pow(2.0, -UV.y)-0.5), 1.0 - UV.y, 0.5) * (1.0 - player_position_factor * 0.7);
	
}

void fragment() {
	vec3 color = mix(bottom_color, top_color, 1.0 - UV.y);
	ALBEDO = color;
	ROUGHNESS = 0.3;
	
	// Increase the Specular with Grass Height
	SPECULAR *=  (1.0 - UV.y);
	
	// I had issues with the Normals imported from Blender,
	// so I just set the Normals facing up manually.
	// You can disable this line if you have no normal shading problems
	NORMAL_MAP = vec3(0, 1, 0);
}