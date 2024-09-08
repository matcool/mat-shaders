#pragma once

#include "shadow_utils.glsl"

uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform vec3 cameraPosition;

vec3 viewPosToWorldPos(vec3 vPos) {
    vec3 feetPos = (gbufferModelViewInverse * vec4(vPos, 1.0)).xyz;
    return feetPos + cameraPosition;
}

vec3 viewDirToWorldDir(vec3 vDir) {
    return mat3(gbufferModelViewInverse) * vDir;
}

vec3 worldPosToShadowScreenPos(vec3 worldPos, vec3 normal) {
    vec3 feetPos = worldPos - cameraPosition;
    // prevents some issues on sides of blocks
    feetPos += normal * 0.1;
    vec3 shadowViewPos = (shadowModelView * vec4(feetPos, 1.0)).xyz;
    vec4 shadowClipPos = shadowProjection * vec4(shadowViewPos, 1.0);
    vec3 shadowNdcPos = shadowClipPos.xyz / shadowClipPos.w;
    // apply player distortion
    float playerDist = length(shadowNdcPos.xy);
    shadowNdcPos.xy = transformShadowSpace(shadowNdcPos.xy, playerDist);
    return shadowNdcPos * 0.5 + 0.5;
}
