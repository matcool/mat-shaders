#include "options.glsl"

vec2 distortShadowSpace(vec2 coordNDC) {
#ifdef ENABLE_SHADOW_DISTORT
    float playerDist = length(coordNDC);
    return coordNDC / (SHADOW_DISTORT_FACTOR + playerDist);
#else
    return coordNDC;
#endif
}
