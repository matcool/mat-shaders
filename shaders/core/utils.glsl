#ifndef _H_UTILS_
#define _H_UTILS_

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

// Smooth min(a, b), with k as a smoothing factor
float smin(float a, float b, float k) {
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

#endif
