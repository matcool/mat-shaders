const int MAX_ITER = 100;
const float MAX_DIST = 20.0;
const float EPSILON = 0.001;


vec2 hash( in vec2 x )  // replace this by something better
{
    const vec2 k = vec2( 0.3183099, 0.3678794 );
    x = x*k + k.yx;
    return -1.0 + 2.0*fract( 16.0 * k*fract( x.x*x.y*(x.x+x.y)) );
}


// return gradient noise (in x) and its derivatives (in yz)
vec3 noised( in vec2 p )
{
    vec2 i = floor( p );
    vec2 f = fract( p );

#if 1
    // quintic interpolation
    vec2 u = f*f*f*(f*(f*6.0-15.0)+10.0);
    vec2 du = 30.0*f*f*(f*(f-2.0)+1.0);
#else
    // cubic interpolation
    vec2 u = f*f*(3.0-2.0*f);
    vec2 du = 6.0*f*(1.0-f);
#endif

    vec2 ga = hash( i + vec2(0.0,0.0) );
    vec2 gb = hash( i + vec2(1.0,0.0) );
    vec2 gc = hash( i + vec2(0.0,1.0) );
    vec2 gd = hash( i + vec2(1.0,1.0) );

    float va = dot( ga, f - vec2(0.0,0.0) );
    float vb = dot( gb, f - vec2(1.0,0.0) );
    float vc = dot( gc, f - vec2(0.0,1.0) );
    float vd = dot( gd, f - vec2(1.0,1.0) );

    return vec3( va + u.x*(vb-va) + u.y*(vc-va) + u.x*u.y*(va-vb-vc+vd),   // value
                 ga + u.x*(gb-ga) + u.y*(gc-ga) + u.x*u.y*(ga-gb-gc+gd) +  // derivatives
                 du * (u.yx*(va-vb-vc+vd) + vec2(vb,vc) - va));
}

float sdTorus(vec3 p, vec2 t) {
    vec2 q = vec2(length(p.xz)-t.x,p.y);
    return length(q)-t.y;
}

float smin( float a, float b, float k )
{
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

float sphereSDF(vec3 pos, float radius) {
    return length(pos) - radius;
}

float boxSDF(vec3 pos, vec3 size) {
    return length(max(abs(pos) - size, 0.0));
}

float planeSDF(vec3 pos, vec2 size) {
  return boxSDF(pos, vec3(size.x, 0.001, size.y));
}

float sceneSDF(vec3 pos, float time) {
    pos.y = -pos.y;
    return smin(-pos.y + noised(pos.xz * 0.4 + time).x * 3.0, boxSDF(pos + vec3(0.0, 1.0, 0.0), vec3(1.0)), 1.0);
}


vec3 calcNormal(vec3 pos, float time) {
    vec2 eps = vec2(0.0, EPSILON);
    return normalize(vec3(
        sceneSDF(pos + eps.yxx, time) - sceneSDF(pos - eps.yxx, time),
        sceneSDF(pos + eps.xyx, time) - sceneSDF(pos - eps.xyx, time),
        sceneSDF(pos + eps.xxy, time) - sceneSDF(pos - eps.xxy, time)
    ));
}

vec4 calcSpecialBlock(vec3 blockPos, vec3 viewDir, float time) {
    vec3 cameraOrigin = (blockPos - 0.5) * 7.0; //vec3(2.0);
    vec3 cameraTarget = vec3(0.0, 0.0, 0.0);
    vec3 upDirection = vec3(0.0, -1.0, 0.0);

    vec3 cameraDir = viewDir; // normalize(cameraTarget - cameraOrigin);
    vec3 cameraRight = normalize(cross(upDirection, cameraOrigin));
    vec3 cameraUp = cross(cameraDir, cameraRight);

    vec3 rayDir = viewDir; // normalize(cameraRight * screenPos.x + cameraUp * screenPos.y + cameraDir);

    float totalDist = 0.0;
    vec3 pos = cameraOrigin;
    float dist = EPSILON;
    float steps;
    for (int i = 0; i < MAX_ITER; i++) {
        if (dist < EPSILON || totalDist > MAX_DIST) break;
        dist = sceneSDF(pos, time);
        totalDist += dist;
        pos += dist * rayDir;
        steps = float(i);
    }
    steps = steps / float(MAX_ITER - 30);

    if (dist < EPSILON) {
        vec3 normal = calcNormal(pos, time);
        float diffuse = max(0.0, dot(-rayDir, normal));
        float specular = pow(diffuse, 100.0);
        vec3 color = vec3(diffuse + specular);
        return vec4(vec3(smin(color.x, steps, 0.2)), 0.0);
    } else {
        return vec4(steps);
        // discard;
    }
}
