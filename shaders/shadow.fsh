#version 460 compatibility

uniform sampler2D gtexture;

uniform float alphaTestRef;

/* RENDERTARGETS: 0,1 */
out vec4 outColor0;
out vec4 outColor1;

in vec2 texCoord;
in vec4 vexColor;
in vec3 blockData;

void main() {
    vec4 albedoColor = texture(gtexture, texCoord) * vec4(vexColor.rgb, 1.0);
    if (albedoColor.a <= alphaTestRef) discard;

    outColor0 = albedoColor;
    outColor1 = vec4(blockData, 0.0);
}
