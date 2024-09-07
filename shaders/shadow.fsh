#version 460 compatibility

uniform sampler2D gtexture;

uniform float alphaTestRef;

/* DRAWBUFFERS:0 */
out vec4 outColor0;

in vec2 texCoord;
in vec4 vexColor;

void main() {
    vec4 albedoColor = texture(gtexture, texCoord) * vec4(vexColor.rgb, 1.0);
    if (albedoColor.a <= alphaTestRef) discard;

    outColor0 = albedoColor;
}