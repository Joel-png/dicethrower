shader_type particles;
#include "math.gdshaderinc"
uniform float width; 
uniform float height; 
uniform float num_particles;
uniform float wind_angle:hint_range(0.0, 360.0, 0.01); 
uniform float wind_speed:hint_range(0.0, 1.0, 0.01); 
uniform float wind_strength:hint_range(0.0, 1.0, 0.01); 
uniform sampler2D _noise; 
uniform sampler2D _noisecolor; 
uniform sampler2D _grassmask; 
uniform bool use_mask; 
uniform vec2 player_position;
uniform float distance_cut_off;
uniform float distance_length;
uniform float distance_start;

uniform float instance_rows;
uniform float instance_rot_randomize = 2.5;
uniform float instance_spacing = 1.0;
uniform float instance_scale_x = 1.0;
uniform	float instance_scale_y = 1.0;
uniform float instance_scale_z = 1.0;
uniform float instance_scale_randomize = 1.0;
uniform float instance_pos_randomize : hint_range(0.0, 50.0) =  2.0;
uniform float instance_scale_min = 0.2;
uniform float instance_scale_max = 1.2;
uniform float _coverage_altitude = 10.0;
uniform float _coverage_range = 100.0;
uniform float _slope_coverage = 0.5;
uniform float clumping_strength : hint_range(0.0, 100.0) = 20.0;
uniform mat3 terrain_normal_basis;
uniform float height_offset;
uniform float size_difference_of_world;
uniform float base_size;

uniform sampler2D map_heightmap;
uniform sampler2D map_normalmap;
uniform bool instance_orient_to_normal = false;
uniform float instance_orientation_influence : hint_range(0.0, 10.0) = 1.0;
uniform float __terrain_amplitude;
uniform vec2 map_heightmap_size = vec2(2000.0, 2000.0);
uniform vec2 map_normalmap_size = vec2(2000.0, 2000.0);
uniform sampler2D map_clumpmap;
uniform float noise_size = 1000.0;

float get_height(vec2 pos) {
	pos -= map_heightmap_size/2.0 * size_difference_of_world;//med_offset + 1.0;
	pos /= map_heightmap_size * size_difference_of_world;
	return __terrain_amplitude * (texture(map_heightmap, pos).r);
}

vec3 get_noise(vec2 pos) {
	pos -= noise_size/2.0 * size_difference_of_world;
	pos /= noise_size * size_difference_of_world;
	return texture(map_clumpmap, pos).rgb;
}

float get_clumps(vec2 pos) {
	pos -= 0.5 * map_heightmap_size;
	pos /= map_heightmap_size;
	return 100.0 * texture(map_clumpmap, pos).r;
}

void start() {	
}
void process() { 
	//All the animations is donde in the particle shader
	// empty transform
	mat4 basis = mat4(vec4(1,0,0,0),vec4(0,1,0,0),vec4(0,0,1,0),vec4(0,0,0,1));
	// get the cols and rows 
	// get position
	vec3 pos = vec3(0.0, 0.0, 0.0);
	pos.z = float(INDEX);
	pos.x = mod(pos.z, instance_rows);
	pos.z = (pos.z - pos.x) / instance_rows;

	// center the emitter
	pos.x -= instance_rows * 0.5;
	pos.z -= instance_rows * 0.5;

	// apply instance spacing
	pos *= instance_spacing;

	// center on position of emitter
	pos.x += EMISSION_TRANSFORM[3][0] - mod(EMISSION_TRANSFORM[3][0], instance_spacing);
	pos.z += EMISSION_TRANSFORM[3][2] - mod(EMISSION_TRANSFORM[3][2], instance_spacing);
	vec3 noise = vec3(get_noise(pos.xz));
	//float randvalue = rand(round(pos.xz * 10.0) / 10.0);
	float randvalue = get_noise(pos.xz).x;
	// remap to 0.3-1.0 so I don't get 0
	randvalue = remap(randvalue,0.0,1.0,0.3,1.0);

	// add noise
	pos.x += instance_spacing * randvalue;
	pos.z -= instance_spacing * randvalue;

	// apply height
	pos.y = get_height(pos.xz);
	float y2 = get_height(pos.xz + vec2(1.0, 0.0));
	float y3 = get_height(pos.xz + vec2(0.0, 1.0));
	float y4 = get_clumps(pos.xz);

	// hide parts from steep areas
	if (abs(y2 - pos.y) > _slope_coverage) {
		pos.y = -10000.0;
	} else if (abs(y3 - pos.y) > _slope_coverage) {
		pos.y = -10000.0;
	}
	if (abs(pos.y) < _coverage_altitude-_coverage_range) {
		pos.y = -10000.0;
	}
	if (abs(pos.y) > _coverage_altitude+_coverage_range) {
		pos.y = -10000.0;
	}

	// clumping
	vec3 clumps = texture(map_clumpmap, pos.zx).rgb;
	if (abs(y4) < clumping_strength) {
		pos.y = -10000.0;
	}
	
	vec3 base_scale = vec3(mix(instance_scale_min, instance_scale_max, noise.x)*instance_scale_x,mix(instance_scale_min, instance_scale_max, noise.y)*instance_scale_y,mix(instance_scale_min, instance_scale_max, noise.z)*instance_scale_z );
	base_scale *= base_scale*randvalue;
	base_scale = sign(base_scale) * max(abs(base_scale), 0.1);
	
	pos.x += cos( noise.x * instance_pos_randomize) * base_scale.x;
	pos.z += sin( noise.z * instance_pos_randomize) * base_scale.z;
	
	// assign the position + space + randomspace
	basis[3].x = pos.x; 
	basis[3].z = pos.z;
	// displace grass depending on the mask
	basis[3].y += 10000.0 * (1.0 - step(0.5,texture(_grassmask,pos.xz).r)) * float(use_mask); 
	
	if (distance(vec2(basis[3].x, basis[3].z), player_position) > 1.0) {
		//basis[3].y += 10000.0;
	}
	// rotate wind_dir in the Y axis
	vec3 wind_dir = mat3(rotation3d(vec3(0,1,0),radians(wind_angle))) * vec3(1,0,0); 
	// wind texture displaced by wind direction * wind speed
	float wind = texture(_noise,pos.xz + wind_dir.xz * TIME * wind_speed).r; 
	
	// rotate by random value (STATIC)
	float rot_y = TAU * randvalue * noise.y; 
	// sine wave rotation in X and Y axis
	float rot_x = sin(TIME+TAU/4.0*randvalue * noise.x)/2.0 * radians(12.0*randvalue * noise.x) + wind*wind_strength; 
	float rot_z = sin(TIME+TAU/4.0*randvalue * noise.z)/2.0 * radians(12.0*randvalue * noise.z) + wind*wind_strength; 
	
	// apply the rotations to the transform
	basis*= rotation3d(vec3(1,0,0),rot_x); 
	basis*= rotation3d(vec3(0,1,0),rot_y); 	
	basis*= rotation3d(vec3(0,0,1),rot_z); 	
	
	// legacy code don't touch
	basis[1]+= (noise.x-0.5)*0.5; 
	
	TRANSFORM = basis; 
	TRANSFORM[3][0] = pos.x;
	TRANSFORM[3][1] = pos.y - height_offset;
	TRANSFORM[3][2] = pos.z;
	// apply color to each particle
	CUSTOM.x = texture(_noisecolor,pos.xz).r; 
	
	float distance_to_player = distance(pos.xz, player_position.xy);
	float fade_in = clamp((distance_to_player - distance_start) / distance_length, 0.0, 1.0);
	float fade_out = clamp(1.0 - (distance_to_player - distance_cut_off) / distance_length, 0.0, 1.0);
	float total_fade = fade_in * fade_out;
	float scale_factor = total_fade * base_size;

    // Construct a scaling matrix
    mat4 scale_matrix = mat4(
        vec4(scale_factor, 0.0, 0.0, 0.0),
        vec4(0.0, scale_factor, 0.0, 0.0),
        vec4(0.0, 0.0, scale_factor, 0.0),
        vec4(0.0, 0.0, 0.0, 1.0)
    );
	
	TRANSFORM = TRANSFORM * scale_matrix;
}

