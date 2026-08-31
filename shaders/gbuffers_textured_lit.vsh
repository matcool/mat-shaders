#version 330 compatibility

in vec4 at_tangent;
in vec3 mc_Entity;

uniform mat3 normalMatrix;

uniform vec3 chunkOffset;
uniform vec3 cameraPosition;

out vec4 viewSpacePos;
out vec2 texCoord;
out vec4 vexColor;
out vec2 lightCoord;
out vec3 geoNormal;
out vec3 tangent;
out vec3 blockData;

void main() {
    vec4 viewPos = gl_ModelViewMatrix * vec4(gl_Vertex.xyz, 1.0);

    gl_Position = ftransform();

    texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    vexColor = gl_Color;
    geoNormal = gl_Normal.xyz;
    tangent = gl_NormalMatrix * normalize(at_tangent.xyz);
    viewSpacePos = viewPos;
    blockData = mc_Entity;

    lightCoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
}
