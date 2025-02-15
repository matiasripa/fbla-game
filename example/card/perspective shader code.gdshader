shader_type canvas_item;

uniform float fov : hint_range(1, 179) = 90;
uniform bool cull_back = true;
uniform float y_rot : hint_range(-180, 180) = 0.0;
uniform float x_rot : hint_range(-180, 180) = 0.0;
uniform float inset : hint_range(0, 1) = 0.1;

varying flat vec2 o;
varying vec3 p;

const float PI_VALUE = 3.14159265358979323846;

mat3 get_rotation_matrix(float y_angle, float x_angle) {
	float sin_b = sin(y_angle / 180.0 * PI_VALUE);
	float cos_b = cos(y_angle / 180.0 * PI_VALUE);
	float sin_c = sin(x_angle / 180.0 * PI_VALUE);
	float cos_c = cos(x_angle / 180.0 * PI_VALUE);

	mat3 rot_mat;
	rot_mat[0][0] = cos_b;
	rot_mat[0][1] = 0.0;
	rot_mat[0][2] = sin_b;

	rot_mat[1][0] = -sin_b * sin_c;
	rot_mat[1][1] = cos_c;
	rot_mat[1][2] = cos_b * sin_c;

	rot_mat[2][0] = -sin_b * cos_c;
	rot_mat[2][1] = -sin_c;
	rot_mat[2][2] = cos_b * cos_c;

	return rot_mat;
}

void vertex() {
	mat3 rot_mat = get_rotation_matrix(y_rot, x_rot);

	float t = tan(fov / 360.0 * PI_VALUE);
	p = rot_mat * vec3((UV - 0.5), 0.5 / t);

	float v = (0.5 / t) + 0.5;
	p.xy *= v * rot_mat[2].z;
	o = v * rot_mat[2].xy;

	VERTEX += (UV - 0.5) / TEXTURE_PIXEL_SIZE * t * (1.0 - inset);

	if (AT_LIGHT_PASS) {
		VERTEX = (rot_mat * vec3(VERTEX, 0.0)).xy;
	}
}

void fragment() {
	if (cull_back && p.z <= 0.0) discard;

	vec2 uv = (p.xy / p.z).xy - o;
	COLOR = texture(TEXTURE, uv + 0.5);
	COLOR.a *= step(max(abs(uv.x), abs(uv.y)), 0.5);

	if (AT_LIGHT_PASS) {
		vec2 text_uv = UV;
		text_uv = (text_uv - 0.5) * (1.0 + p.z * 0.1) + 0.5;
		COLOR = texture(TEXTURE, text_uv);
	}
}