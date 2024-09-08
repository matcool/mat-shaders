// Source: https://www.shadertoy.com/view/3dVXDc

// Hash by David_Hoskins
#define UI0 1597334673U
#define UI1 3812015801U
#define UI2 uvec2(UI0, UI1)
#define UI3 uvec3(UI0, UI1, 2798796415U)
#define UIF (1.0 / float(0xffffffffU))

vec3 hash33(vec3 p) {
    uvec3 q = uvec3(ivec3(p)) * UI3;
    q = (q.x ^ q.y ^ q.z) * UI3;
    return -1. + 2. * vec3(q) * UIF;
}

// Tileable 3D worley noise
float worleyNoise(vec3 uv, float freq) {
    vec3 id = floor(uv);
    vec3 p = fract(uv);

    float minDist = 10000.;
    for (float x = -1.; x <= 1.; ++x) {
        for (float y = -1.; y <= 1.; ++y) {
            for (float z = -1.; z <= 1.; ++z) {
                vec3 offset = vec3(x, y, z);
                vec3 h = hash33(mod(id + offset, vec3(freq))) * .5 + .5;
                h += offset;
                vec3 d = p - h;
                   minDist = min(minDist, dot(d, d));
            }
        }
    }

    return minDist;
}

vec3 calculateWaterCaustics(vec3 uv, vec3 waterColor, float time) {
    float d = worleyNoise(uv * 4.0 - time * 0.5, 3.0);
    vec3 col = pow(waterColor, vec3(0.4)) * mix(0.4, 1.0, d);

    return col;
}
