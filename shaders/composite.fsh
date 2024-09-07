#version 460

uniform sampler2D colortex0;
uniform sampler2D depthtex0;
uniform sampler2D colortex2;

/* DRAWBUFFERS:0 */
out vec4 outColor0;

in vec2 texCoord;

void main() {
    outColor0 = texture(colortex0, texCoord);
    // outColor0 = vec4(vec3(sin(texCoord.x * 3.14 * 10)), 1.0);
}