#version 460 compatibility

#include "programs/shadow_utils.glsl"

out vec2 texCoord;
out vec3 vexColor;

void main() {
    gl_Position = ftransform();

    float playerDist = length(gl_Position.xy);
    gl_Position.xy = transformShadowSpace(gl_Position.xy, playerDist);

    texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    vexColor = gl_Color.rgb;
}