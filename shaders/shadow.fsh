#version 330 compatibility

#include "core/options.glsl"

uniform sampler2D gtexture;

uniform float alphaTestRef;

#ifdef ENABLE_SHADOW_COLOR
/* RENDERTARGETS: 0,1 */
out vec4 outColor0;
out vec4 outColor1;
#endif

in vec2 texCoord;
in vec4 vexColor;
in vec3 blockData;

void main() {
    vec4 albedoColor = texture(gtexture, texCoord) * vexColor;
    if (albedoColor.a <= alphaTestRef) discard;

#ifdef ENABLE_SHADOW_COLOR
    outColor0 = albedoColor;
    outColor1 = vec4(blockData, 0.0);
#endif
}
