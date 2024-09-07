#version 460

#include "programs/utils.glsl"
#include "programs/frag_utils.glsl"
#include "programs/brdf.glsl"

uniform sampler2D gtexture;
uniform sampler2D lightmap; 
uniform sampler2D normals;
uniform sampler2D specular;

uniform vec3 shadowLightPosition;

uniform float alphaTestRef;

/* DRAWBUFFERS:0 */
out vec4 outColor0;

in vec4 viewSpacePos;
in vec2 texCoord;
in vec4 vexColor;
in vec2 lightCoord;
in vec3 geoNormal;
in vec3 tangent;

const float ambientOcclusionLevel = 0.8;


void main() {
    vec4 lightColor = linearColor(texture(lightmap, lightCoord));
    vec4 albedoColor = linearColor(texture(gtexture, texCoord)) * vec4(linearColor(vexColor.rgb), 1.0);
    float aoAmount = vexColor.a;
    if (albedoColor.a <= alphaTestRef) discard;

    vec3 normalTexture = texture(normals, texCoord).rgb * 2.0 - 1.0;
    normalTexture.b = sqrt(1.0 - dot(normalTexture.xy, normalTexture.xy));
    
    vec3 normal = tbnNormalTangent(geoNormal, viewDirToWorldDir(tangent)) * normalTexture.rgb;
    vec3 shadowDir = viewDirToWorldDir(normalize(shadowLightPosition));

    // specular
    vec4 specularTexture = texture(specular, texCoord);
    float perceptualSmoothness = specularTexture.r;

    // material properties
    float roughness = pow(1.0 - perceptualSmoothness, 2.0);
    float smoothness = 1.0 - sqrt(roughness);
    // reflectance only goes up to 229, as defined by labPBR
    float metallic = specularTexture.g * 255.0 > 229.0 ? 1.0 : 0.0;
    // metallic will use albedo color, use specular texture otherwise
    vec3 reflectance = mix(vec3(specularTexture.g), albedoColor.rgb, metallic);

    // points towards the camera
    vec3 viewDir = normalize(cameraPosition - viewPosToWorldPos(viewSpacePos.xyz));

    vec3 blockColor = 0.2 * albedoColor.rgb + brdf(shadowDir, viewDir, roughness, normal, albedoColor.rgb, metallic, reflectance);
    blockColor *= lightColor.rgb;
    blockColor *= aoAmount;

    outColor0 = unlinearColor(vec4(blockColor, albedoColor.a));

    // outColor0 = vec4(vec3(roughness), 1.0);
    // outColor0 = vec4(vec3(albedoColor.a), 1.0);
}