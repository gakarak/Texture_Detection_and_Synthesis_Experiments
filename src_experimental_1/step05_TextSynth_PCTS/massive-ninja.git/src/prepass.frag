#version 330

precision highp float; // needed only for version 1.30

uniform sampler2D exemplar;
in vec2 uv_coord; // uv coordinate

out vec4 matches_x;
out vec4 matches_y;

// store the nearest 4 neighborhoods
vec3 nbhd_set[4];

// size of the neighborhood we're looking at
#define nbhd 5

// keep only the smallest 4 out of the 4 current smallest and the new value
void keepSmallest(vec3 new_val) {
    // store the current max value's index
    //int test_ind;
    // store the current max distance
    float test_z;
    // store which are the max
    // ivec4 find;
    // find the maximum value in the current set
    //test_z = max(nbhd_set[0].z, max(nbhd_set[1].z, max(nbhd_set[2].z, nbhd_set[3].z)));
    test_z = max(nbhd_set[0].z, max(nbhd_set[1].z, max(nbhd_set[2].z, max(nbhd_set[3].z, new_val.z))));
    //find = ivec4(test_z == nbhd_set[0].z, test_z == nbhd_set[1].z, test_z == nbhd_set[2].z, test_z == nbhd_set[3].z);// *  ivec4(0 == nbhd_set[0].z, 0 == nbhd_set[1].z, 0 == nbhd_set[2].z, 0 == nbhd_set[3].z);
    
    //test_ind = 1 * int(test_z == nbhd_set[1].z) + 2 * int(test_z == nbhd_set[2].z) + 3 * int(test_z == nbhd_set[3].z); 

    if (test_z == nbhd_set[0].z) {
        nbhd_set[0] = new_val;
    }
    else if (test_z == nbhd_set[1].z) {
        nbhd_set[1] = new_val;
    }
    else if (test_z == nbhd_set[2].z) {
        nbhd_set[2] = new_val;
    }
    else if (test_z == nbhd_set[3].z) {
        nbhd_set[3] = new_val;
    }
    
    // find the minimum between current max value and the new value
    //test_z = min(new_val.z, nbhd_set[test_ind].z);
    //nbhd_set[test_ind] = new_val * int(test_z == new_val.z) + nbhd_set[test_ind] * int(test_z != new_val.z);
}

// calculate squared neighborhood distance for neighborhood of size k
float nbhd_dist(ivec2 a_ij, ivec2 b_ij, int k) {
    // calculate the shift
    int shift = int(k * 0.5);

    // calculate summed squared euclidean distance for each channel for each
    //  pixel in the neighborhood; k is assumed to be odd
    vec4 dist = vec4(0.0f);
    vec4 a_val;
    vec4 b_val;
    for (int i = -1 * shift; i <= shift; i++) {
        for (int j = -1 * shift; j <= shift; j++) {
            a_val = texelFetch(exemplar, a_ij + ivec2(j, i), 0);
            b_val = texelFetch(exemplar, b_ij + ivec2(j, i), 0);
            dist += pow(a_val - b_val, vec4(2));
        }
    }
    // return summed channels for the neighborhood
    return dist.r + dist.g + dist.b + dist.a;
}

void main(void) {
    for (int i = 0; i < 4; i++) {
        nbhd_set[i] = vec3(99999, 99999, 99999 - i);
    }
    // calculate the shift
    int shift = int(nbhd * 0.5);
    ivec2 size = textureSize(exemplar, 0);
    ivec2 cur_pos = ivec2(size * uv_coord);

    
    // loop over all of the pixels in the image, only iterate over the middle
    //  to avoid the edge cases
    vec3 cur_vals;
    for (int i = shift; i < size.y - shift; i++) {
        for (int j = shift; j < size.x - shift; j++) {
            cur_vals.xy = vec2(j, i);
            cur_vals.z = nbhd_dist(ivec2(cur_vals.xy), cur_pos, nbhd);
            keepSmallest(cur_vals);
        }
    }
   
    if (cur_pos.x - shift < 0 || cur_pos.y - shift < 0 || cur_pos.x + shift >= size.x || cur_pos.y + shift >= size.y) {
        matches_x = vec4(uv_coord.x);
        matches_y = vec4(uv_coord.y);
        return;
    }
     
    float m = min(min(nbhd_set[1].z,nbhd_set[2].z),min(nbhd_set[3].z,nbhd_set[0].z));
    vec4 dist;
    if (m == nbhd_set[0].z) {
        matches_x = vec4(nbhd_set[0].x,nbhd_set[1].x,nbhd_set[2].x,nbhd_set[3].x);
        matches_y = vec4(nbhd_set[0].y,nbhd_set[1].y,nbhd_set[2].y,nbhd_set[3].y);
        dist =      vec4(nbhd_set[0].z,nbhd_set[1].z,nbhd_set[2].z,nbhd_set[3].z);
    } else if (m== nbhd_set[1].z) {
        matches_x = vec4(nbhd_set[1].x,nbhd_set[0].x,nbhd_set[2].x,nbhd_set[3].x);
        matches_y = vec4(nbhd_set[1].y,nbhd_set[0].y,nbhd_set[2].y,nbhd_set[3].y);
        dist =      vec4(nbhd_set[1].z,nbhd_set[0].z,nbhd_set[2].z,nbhd_set[3].z);
    } else if (m==nbhd_set[2].z) {
        matches_x = vec4(nbhd_set[2].x,nbhd_set[1].x,nbhd_set[0].x,nbhd_set[3].x);
        matches_y = vec4(nbhd_set[2].y,nbhd_set[1].y,nbhd_set[0].y,nbhd_set[3].y);
        dist =      vec4(nbhd_set[2].z,nbhd_set[1].z,nbhd_set[0].z,nbhd_set[3].z);
    } else if (m==nbhd_set[3].z) {
        matches_x = vec4(nbhd_set[3].x,nbhd_set[1].x,nbhd_set[0].x,nbhd_set[2].x);
        matches_y = vec4(nbhd_set[3].y,nbhd_set[1].y,nbhd_set[0].y,nbhd_set[2].y);
        dist =      vec4(nbhd_set[3].z,nbhd_set[1].z,nbhd_set[0].z,nbhd_set[2].z);
    }
    m = min(dist.y,min(dist.z,dist.w));
    if (m == dist.z) {
        matches_x = matches_x.xzyw;
        matches_y = matches_y.xzyw;
        dist = dist.xzyw;
    }
    if (m == dist.w) {
        matches_x = matches_x.xwyz;
        matches_y = matches_y.xwyz;
        dist = dist.xwyz;
    }
    m = min(dist.z,dist.w);
    if (m == dist.w) {
        matches_x = matches_x.xywz;
        matches_y = matches_y.xywz;
        dist = dist.xywz;
    }
    matches_x /= vec4(textureSize(exemplar, 0).x);
    matches_y /= vec4(textureSize(exemplar, 0).y);
    return;
    for (int i = 0; i < 4; i++) {
        matches_x[i] = nbhd_set[i].x;
        matches_y[i] = nbhd_set[i].y;
    }

    //matches_x /= vec4(textureSize(exemplar, 0).x);
    //matches_y /= vec4(textureSize(exemplar, 0).y);
}

