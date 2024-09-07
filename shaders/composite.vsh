#version 460

in vec3 vaPosition;

uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;

out vec2 texCoord;

void main() {
    vec4 viewPos = modelViewMatrix * vec4(vaPosition, 1.0);
    texCoord = vaPosition.xy;

    gl_Position = projectionMatrix * viewPos;
}