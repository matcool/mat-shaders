#version 460 compatibility

#include "core/distort.glsl"

in vec3 mc_Entity;

out vec2 texCoord;
out vec3 vexColor;
out vec3 blockData;

void main() {
    gl_Position = ftransform();

    gl_Position.xy = distortShadowSpace(gl_Position.xy);

    texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    vexColor = gl_Color.rgb;

    blockData = mc_Entity;
}
