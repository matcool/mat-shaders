#version 460

in vec3 vaPosition;
// includes both foliage color and also ambient occlusion
in vec4 vaColor;
// texture (u, v)
in vec2 vaUV0;
// lightmap (u, v)
in ivec2 vaUV2;
in vec3 vaNormal;
in vec4 at_tangent;

uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;
uniform mat4 gbufferModelViewInverse;
uniform mat3 normalMatrix;

uniform vec3 chunkOffset;
uniform vec3 cameraPosition;

out vec4 viewSpacePos;
out vec2 texCoord;
out vec4 vexColor;
out vec2 lightCoord;
out vec3 geoNormal;
out vec3 tangent;

void main() {
    vec4 viewPos = modelViewMatrix * vec4(vaPosition + chunkOffset, 1.0);
    vec4 worldPos = vec4(cameraPosition, 1.0) + gbufferModelViewInverse * viewPos;

    gl_Position = projectionMatrix * viewPos;

    texCoord = vaUV0;
    vexColor = vaColor;
    geoNormal = vaNormal;
    tangent = normalize(normalMatrix * at_tangent.xyz);
    viewSpacePos = viewPos;

    lightCoord = vaUV2 * (1.0 / 256.0) + (1.0 / 32.0);
}