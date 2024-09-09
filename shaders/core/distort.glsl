#define SHADOW_DISTORT_FACTOR 0.08 // [0.03 0.04 0.05 0.06 0.07 0.08 0.09 0.1] Amount to distort shadow space by. Smaller values means higher quality near the player, but lower quality elsewhere.

vec2 distortShadowSpace(vec2 coordNDC) {
    float playerDist = length(coordNDC);
    return coordNDC / (SHADOW_DISTORT_FACTOR + playerDist);
}
