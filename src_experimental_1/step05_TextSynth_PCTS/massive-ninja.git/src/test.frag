#version 330

precision highp float; // needed only for version 1.30

uniform sampler2D exemplar;
in vec2 uv_coord; // uv coordinate

out vec4 matches_x;
out vec4 matches_y;

void main() {
	matches_x = vec4(uv_coord.x);
	matches_y = vec4(uv_coord.y);
}
