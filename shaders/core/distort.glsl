#define SHADOW_DISTORT_FACTOR 0.08 // [0.03 0.04 0.05 0.06 0.07 0.08 0.09 0.1]
#define ENABLE_SHADOW_DISTORT

vec2 distortShadowSpace(vec2 coordNDC) {
#ifdef ENABLE_SHADOW_DISTORT
    float playerDist = length(coordNDC);
    return coordNDC / (SHADOW_DISTORT_FACTOR + playerDist);
#else
    return coordNDC;
#endif
}
