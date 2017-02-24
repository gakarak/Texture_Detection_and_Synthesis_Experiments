// Fragment Shader - file "minimal.frag"

#version 130

precision highp float; // needed only for version 1.30

uniform sampler2D tex;
uniform sampler2D exemplar;
uniform sampler2D matches_x;
uniform sampler2D matches_y; 
uniform int mode;
in  vec3 ex_Color;
in  vec2 uv_coord;
out vec4 out_Color;

void main(void) {
	if (mode==0)
		out_Color = texture(tex,uv_coord);
	else if (mode==1)
		out_Color = texture(exemplar,texture(tex,uv_coord).xy);
	else if (mode==2)
		out_Color = vec4(texture(exemplar,uv_coord).w);
    else
        //out_Color = vec4(texture(matches_x,uv_coord).x,texture(matches_y,uv_coord).x,0,0);
        out_Color = texture(exemplar,vec2(texture(matches_x,uv_coord).x,texture(matches_y,uv_coord).x));
	//out_Color = vec4(ex_Color,1.0);
}
