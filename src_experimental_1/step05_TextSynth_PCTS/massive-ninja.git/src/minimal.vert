// Vertex Shader - file "minimal.vert"

#version 130

uniform sampler2D tex;
in  vec3 in_Position;
in  vec3 in_Color;
in  vec2 in_UV;
out vec3 ex_Color;
out vec2 uv_coord;

void main(void) {
	ex_Color = in_Color;
    uv_coord = in_UV;
	gl_Position = vec4(in_Position, 1.0);
}
