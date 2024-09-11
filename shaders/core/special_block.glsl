#include "utils.glsl"

// https://www.shadertoy.com/view/tdSXRt

vec2 special_hash(vec2 x) {
    const vec2 k = vec2( 0.3183099, 0.3678794 );
    x = x*k + k.yx;
    return -1.0 + 2.0*fract( 16.0 * k*fract( x.x*x.y*(x.x+x.y)) );
}

float special_noised(in vec2 p) {
    vec2 i = floor( p );
    vec2 f = fract( p );

    vec2 u = f*f*(3.0-2.0*f);
    vec2 du = 6.0*f*(1.0-f);

    vec2 ga = special_hash(i + vec2(0.0,0.0));
    vec2 gb = special_hash(i + vec2(1.0,0.0));
    vec2 gc = special_hash(i + vec2(0.0,1.0));
    vec2 gd = special_hash(i + vec2(1.0,1.0));

    float va = dot(ga, f - vec2(0.0,0.0));
    float vb = dot(gb, f - vec2(1.0,0.0));
    float vc = dot(gc, f - vec2(0.0,1.0));
    float vd = dot(gd, f - vec2(1.0,1.0));

    return va + u.x*(vb-va) + u.y*(vc-va) + u.x*u.y*(va-vb-vc+vd);
}

float special_boxSDF(vec3 pos, vec3 size) {
    return length(max(abs(pos) - size, 0.0));
}

float special_sceneSDF(vec3 pos, float time) {
    pos.y = -pos.y;
    return smin(-pos.y + special_noised(pos.xz * 0.4 + time) * 3.0, special_boxSDF(pos + vec3(0.0, 1.0, 0.0), vec3(1.0)), 1.0);
}

vec3 special_calcNormal(vec3 pos, float time) {
    const float EPSILON = 0.001;

    vec2 eps = vec2(0.0, EPSILON);
    return normalize(vec3(
        special_sceneSDF(pos + eps.yxx, time) - special_sceneSDF(pos - eps.yxx, time),
        special_sceneSDF(pos + eps.xyx, time) - special_sceneSDF(pos - eps.xyx, time),
        special_sceneSDF(pos + eps.xxy, time) - special_sceneSDF(pos - eps.xxy, time)
    ));
}

vec4 calcSpecialBlock(vec3 blockPos, vec3 viewDir, float time) {
    const int MAX_ITER = 100;
    const float MAX_DIST = 20.0;
    const float EPSILON = 0.001;

    vec3 cameraOrigin = (blockPos - 0.5) * 7.0;
    vec3 rayDir = viewDir;

    float totalDist = 0.0;
    vec3 pos = cameraOrigin;
    float dist = EPSILON;
    float steps = 0.0;
    for (int i = 0; i < MAX_ITER; i++) {
        if (dist < EPSILON || totalDist > MAX_DIST) break;
        dist = special_sceneSDF(pos, time);
        totalDist += dist;
        pos += dist * rayDir;
        steps = float(i);
    }
    steps = steps / float(MAX_ITER - 30);

    if (dist < EPSILON) {
        vec3 normal = special_calcNormal(pos, time);
        float diffuse = max(0.0, dot(-rayDir, normal));
        float specular = pow(diffuse, 100.0);
        vec3 color = vec3(diffuse + specular);
        return vec4(vec3(smin(color.x, steps, 0.2)), 0.0);
    } else {
        return vec4(steps);
    }
}
