#pragma once

vec2 transformShadowSpace(vec2 coord, float playerDist) {
    return coord / (0.08 + playerDist);
}
