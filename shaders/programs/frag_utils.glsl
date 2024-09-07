#pragma once

uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;

vec3 viewPosToWorldPos(vec3 vPos) {
    vec3 feetPos = (gbufferModelViewInverse * vec4(vPos, 1.0)).xyz;
    return feetPos + cameraPosition;
}

vec3 viewDirToWorldDir(vec3 vDir) {
    return mat3(gbufferModelViewInverse) * vDir;
}