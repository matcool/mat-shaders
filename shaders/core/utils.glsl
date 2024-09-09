const float PI = 3.14159265359;

vec3 linearColor(vec3 color) { return pow(color, vec3(2.2)); }
vec4 linearColor(vec4 color) { return vec4(linearColor(color.rgb), color.a);}

vec3 unlinearColor(vec3 color) { return pow(color, vec3(1.0 / 2.2)); }
vec4 unlinearColor(vec4 color) { return vec4(unlinearColor(color.rgb), color.a); }

// Creates a TBN matrix from a normal and a tangent
mat3 tbnNormalTangent(vec3 normal, vec3 tangent) {
    vec3 bitangent = cross(tangent, normal);
    return mat3(tangent, bitangent, normal);
}
