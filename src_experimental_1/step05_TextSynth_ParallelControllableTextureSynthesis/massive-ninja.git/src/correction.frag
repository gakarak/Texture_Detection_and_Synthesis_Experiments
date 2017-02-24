// Fragment Shader - file "correction.frag"

#version 330

precision highp float; // needed only for version 1.30

uniform sampler2D example_texture; // example texture
uniform sampler2D res; // synthesized texture
uniform sampler2D coords_x;
uniform sampler2D coords_y;
in vec4 gl_FragCoord; // coordinate of current fragment on screen
in vec2 uv_coord; // uv coordinate
out vec4 colorOut; // output color at this pixel

// calculate squared neighborhood distance for neighborhood of size k
float nbhd_dist(ivec2 res_ij, ivec2 ex_ij, int k) {
    int shift = int(k * 0.5);

    // check if center is far enough away from boundary if not, shift the 
    //  position of the pixel in the neighborhood so that the neighborhood
    //  fits into the boundaries of the image
    ivec2 c_res = clamp(res_ij, ivec2(shift), textureSize(res, 0) - ivec2(shift));
    ivec2 c_ex = clamp(ex_ij, ivec2(shift), textureSize(example_texture, 0) - ivec2(shift));
    
    // calculate summed squared euclidean distance for each channel for each
    //  pixel in the neighborhood
    vec4 dist = vec4(0.0f, 0.0f, 0.0f, 0.0f);
    for (int i = -1 * shift; i <= shift; i++) {
        for (int j = -1 * shift; j <= shift; j++) {
            dist += pow(texture(example_texture, (c_ex + ivec2(i, j))/textureSize(example_texture, 0)) - texture(example_texture, texelFetch(res, c_res + ivec2(i, j),0).xy), vec4(2));
        }
    }
 
    // return summed channels for the neighborhood
    return dist.r + dist.g + dist.b + dist.a;
}

ivec2 unpackCoord(float coord) {
    int icoord = floatBitsToInt(coord);
    return ivec2(icoord/65536, (icoord*65536)/65536);
}

void main(void) {
    colorOut = vec4(texture(coords_x,uv_coord).x, texture(coords_y,uv_coord).x, 0, 0);
    //colorOut = texture(coords_x, uv_coord);
    return;
    //nbhd_dist(glFragCoord, ivec2(uv_coord * textureSize(example_texture, 0)), 5);
    ivec2 size = textureSize(res,0);
    ivec2 my_pos = ivec2(vec2(size) * uv_coord);
    vec4 texcoord_x = texelFetch(coords_x,ivec2(uv_coord * textureSize(coords_x, 0)), 0);
    vec4 texcoord_y = texelFetch(coords_y,ivec2(uv_coord * textureSize(coords_y, 0)), 0);
    ivec2 coord = ivec2(vec2(texcoord_x.x, texcoord_y.x) * textureSize(coords_x, 0));
    float dist1 = nbhd_dist(ivec2(gl_FragCoord.xy), coord, 5);
    coord = ivec2(vec2(texcoord_x.y, texcoord_y.y) * textureSize(coords_y, 0));
    float dist2 = nbhd_dist(ivec2(gl_FragCoord.xy), coord, 5);
    coord = ivec2(vec2(texcoord_x.z, texcoord_y.z) * textureSize(coords_y, 0));
    float dist3 = nbhd_dist(ivec2(gl_FragCoord.xy), coord, 5);
    coord = ivec2(vec2(texcoord_x.w, texcoord_y.w) * textureSize(coords_y, 0));
    float dist4 = nbhd_dist(ivec2(gl_FragCoord.xy), coord, 5);

    float dist = min(dist1,min(dist2,min(dist3,dist4)));
    vec2 newCoord;
    newCoord.x = texcoord_x.x*float(dist==dist1) + texcoord_x.y*float(dist==dist2) + texcoord_x.z*float(dist==dist3) + texcoord_x.w*float(coord==dist3);
    newCoord.y = texcoord_y.x*float(dist==dist1) + texcoord_y.y*float(dist==dist2) + texcoord_y.z*float(dist==dist3) + texcoord_y.w*float(coord==dist3);
    
    //vec2 newCoord = vec2(coord) / vec2(textureSize(res,0));
     
    colorOut = vec4(newCoord,0,0);
    //colorOut = texture(res,uv_coord);
    //colorOut = texture(coords_y, uv_coord);
    //colorOut = texture(coords, uv_coord); // for now, just output the same texture coord
}
