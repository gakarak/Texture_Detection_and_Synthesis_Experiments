// Fragment Shader - file "correction.frag"

#version 330

precision highp float; // needed only for version 1.30

uniform sampler2D example_texture; // example texture
uniform sampler2D res; // synthesized texture
uniform sampler2D matches_x;
uniform sampler2D matches_y;

in vec2 uv_coord; // uv coordinate
#define k_val 4 // the number of values to return in the set
#define nbhd 5

out vec4 kcoh_set_x; // output x values
out vec4 kcoh_set_y; // output y values
vec4 kcoh_set_dist;
// calculate squared neighborhood distance for neighborhood of size k
float nbhd_dist(ivec2 ex_ij, ivec2 cur_ij, int k) {
    // calculate the shift
    int shift = int(k * 0.5);

    // check if center is far enough away from boundary if not, shift the 
    //  position of the pixel in the neighborhood so that the neighborhood
    //  fits into the boundaries of the image
    
    ivec2 s_min = min(min(ex_ij-ivec2(shift),0),min(cur_ij-ivec2(shift),0));
    ivec2 s_max = ivec2(-1) * min(min(textureSize(example_texture,0)-ex_ij-ivec2(shift),0),min(textureSize(res,0)-cur_ij-ivec2(shift),0));

    // calculate summed squared euclidean distance for each channel for each
    //  pixel in the neighborhood; k is assumed to be odd
    vec4 dist = vec4(0.0f);
    vec4 cur_val;
    vec4 ex_val;
    for (int i = s_min.y; i <= s_max.y; i++) {
        for (int j = s_min.x; j <= s_max.x; j++) {
            ex_val = texelFetch(example_texture, ex_ij+ivec2(i,j), 0);
            cur_val = texelFetch(res, cur_ij+ivec2(i,j), 0);
            cur_val = texture(example_texture, cur_val.xy);
            dist += pow(cur_val - ex_val, vec4(2));
        }
    }
    //dist /= vec4((s_max.x-s_min.x)*(s_max.y-s_min.y)); 
    // return summed channels for the neighborhood
    return dist.r + dist.g + dist.b + dist.a;
}

ivec2 imsize;
ivec4 initialized;
void doComparison(ivec2 lc, ivec2 c_cur) {
    float dist, tmp, equiv;
    vec4 finder, ifinder;
    // calc the distance
    dist = nbhd_dist(lc, c_cur, 5);
    // if any of the slots are empty, use them first
    if (initialized.x == 0) {
        initialized.x = 1;
        kcoh_set_dist.x = dist;
        kcoh_set_x.x = float(lc.x)/float(imsize.x);
        kcoh_set_y.x = float(lc.y)/float(imsize.y);
        return;
    }
    if (initialized.y == 0) {
        initialized.y = 1;
        kcoh_set_dist.y = dist;
        kcoh_set_x.y = float(lc.x)/float(imsize.x);
        kcoh_set_y.y = float(lc.y)/float(imsize.y);
        return;
    }
    if (initialized.z == 0) {
        initialized.z = 1;
        kcoh_set_dist.z = dist;
        kcoh_set_x.z = float(lc.x)/float(imsize.x);
        kcoh_set_y.z = float(lc.y)/float(imsize.y);
        return;
    }
    if (initialized.w == 0) {
        initialized.w = 1;
        kcoh_set_dist.w = dist;
        kcoh_set_x.w = float(lc.x)/float(imsize.x);
        kcoh_set_y.w = float(lc.y)/float(imsize.y);
        return;
    }
    // otherwise, figure out if it belongs in the top 4
    tmp = max(dist,max(kcoh_set_dist.x,max(kcoh_set_dist.y,max(kcoh_set_dist.z,kcoh_set_dist.w))));
    if (tmp == kcoh_set_dist.x) {
        kcoh_set_dist.x = dist;
        kcoh_set_x.x = float(lc.x)/float(imsize.x);
        kcoh_set_y.x = float(lc.y)/float(imsize.y);
        return;
    }
    if (tmp == kcoh_set_dist.y) {
        kcoh_set_dist.y = dist;
        kcoh_set_x.y = float(lc.x)/float(imsize.x);
        kcoh_set_y.y = float(lc.y)/float(imsize.y);
        return;
    }
    if (tmp == kcoh_set_dist.z) {
        kcoh_set_dist.z = dist;
        kcoh_set_x.z = float(lc.x)/float(imsize.x);
        kcoh_set_y.z = float(lc.y)/float(imsize.y);
        return;
    }
    if (tmp == kcoh_set_dist.w) {
        kcoh_set_dist.w = dist;
        kcoh_set_x.w = float(lc.x)/float(imsize.x);
        kcoh_set_y.w = float(lc.y)/float(imsize.y);
        return;
    }
    return;
    // stick this value in the top 4 if it belongs there
    tmp = max(dist,max(kcoh_set_dist.x,max(kcoh_set_dist.y,max(kcoh_set_dist.z,kcoh_set_dist.w))));
    //if (tmp == dist) {return;}
    //if (tmp == kcoh_set_dist.x
    finder = vec4(tmp==kcoh_set_dist.x, tmp==kcoh_set_dist.y, tmp==kcoh_set_dist.z, tmp==kcoh_set_dist.w);
    ifinder = vec4(1) - finder;
    kcoh_set_dist = ifinder * kcoh_set_dist + finder * vec4(tmp);
    kcoh_set_x = ifinder * kcoh_set_x + finder * vec4(float(lc.x)/float(imsize.x));
    kcoh_set_y = ifinder * kcoh_set_y + finder * vec4(float(lc.y)/float(imsize.y));
}

void main(void) {
    initialized = ivec4(0,0,0,0);
    //kcoh_set_dist = vec4(999999998,999999997,999999996,999999999);
    int shift = int(0.5 * nbhd);
    //  find our center
    ivec2 c_cur = ivec2(uv_coord * textureSize(res, 0));

    // define the beginning end ending offsets for our search
    ivec2 lc;
    ivec2 begin = max(c_cur - ivec2(shift),ivec2(0));
    ivec2 end = min(c_cur + ivec2(shift),textureSize(res,0)- ivec2(1,1));
    // short-circuit if we don't have a full neighborhood
    imsize = textureSize(example_texture, 0);
    //return;
    if (begin != ivec2(c_cur-ivec2(shift)) || end != ivec2(c_cur+ivec2(shift))) {
        ivec2 mc = ivec2(texelFetch(res,c_cur,0).xy * textureSize(example_texture,0).xy);
        kcoh_set_x = vec4(texelFetch(matches_x,mc,0).x);//vec4(float(mc.x)/imsize.x);//
        kcoh_set_y = vec4(texelFetch(matches_y,mc,0).x);//vec4(float(mc.y)/imsize.y);//
    
        //kcoh_set_x = vec4(texelFetch(res,c_cur,0).x);
        //kcoh_set_y = vec4(texelFetch(res,c_cur,0).y);
        return;
    }
    // find the top 4 best
    for (int i = begin.x; i<=end.x; i++) {
        for (int j = begin.y; j<=end.y; j++) {
            ivec2 match_coord = ivec2(texelFetch(res, ivec2(i,j), 0).xy * imsize);
            vec4 match_x = texelFetch(matches_x,match_coord,0);
            vec4 match_y = texelFetch(matches_y,match_coord,0);
            lc = ivec2(match_x.x*imsize.x, match_y.x*imsize.y);
            doComparison(lc,c_cur);
            lc = ivec2(match_x.y*imsize.x, match_y.y*imsize.y);
            doComparison(lc,c_cur);
            lc = ivec2(match_x.z*imsize.x, match_y.z*imsize.y);
            doComparison(lc,c_cur);
            lc = ivec2(match_x.w*imsize.x, match_y.w*imsize.y);
            doComparison(lc,c_cur);
            //doComparison(match_coord,c_cur);
        }
    }
    if (initialized.x == 0) {
        kcoh_set_x = vec4(0);
        kcoh_set_y = vec4(0);
        return;
    }
    // sort the top 1 to the top of the list
    float tmp = min(kcoh_set_dist.x, min(kcoh_set_dist.y, min(kcoh_set_dist.z, kcoh_set_dist.w)));
    if (initialized.y == 0) {
        tmp = kcoh_set_dist.x;
    } else if (initialized.z == 0) {
        tmp = min(kcoh_set_dist.x, kcoh_set_dist.y);
    } else if (initialized.w == 0) {
        tmp = min(kcoh_set_dist.x, min(kcoh_set_dist.y, kcoh_set_dist.z));
    }
    
    if (tmp == kcoh_set_dist.y) {
        tmp = kcoh_set_x.x;
        kcoh_set_x.x = kcoh_set_x.y;
        kcoh_set_x.y = tmp;

        tmp = kcoh_set_y.x;
        kcoh_set_y.x = kcoh_set_y.y;
        kcoh_set_y.y = tmp;
    } else if (tmp == kcoh_set_dist.z) {
        tmp = kcoh_set_x.x;
        kcoh_set_x.x = kcoh_set_x.z;
        kcoh_set_x.z = tmp;

        tmp = kcoh_set_y.x;
        kcoh_set_y.x = kcoh_set_y.z;
        kcoh_set_y.z = tmp;
    } else if (tmp == kcoh_set_dist.w) {
        tmp = kcoh_set_x.x;
        kcoh_set_x.x = kcoh_set_x.w;
        kcoh_set_x.w = tmp;

        tmp = kcoh_set_y.x;
        kcoh_set_y.x = kcoh_set_y.w;
        kcoh_set_y.w = tmp;
    }
    return;
}

