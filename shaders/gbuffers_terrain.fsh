#version 460

#include "programs/utils.glsl"
#include "programs/frag_utils.glsl"

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
    
    // normal direction mixed with the texture normals
    vec3 mixedNormal = tbnNormalTangent(geoNormal, viewDirToWorldDir(tangent)) * normalTexture.rgb;

    // calculating light based on the direction of the sun/moon
    vec3 shadowDir = viewDirToWorldDir(normalize(shadowLightPosition));

    // sunLightFactor = sunLightFactor * 0.5 + 0.5;

    // specular
    vec4 specularTexture = texture(specular, texCoord);
    float perceptualSmoothness = specularTexture.r;

    float roughness = pow(1.0 - perceptualSmoothness, 2.0);
    float smoothness = 1.0 - sqrt(roughness);
    float shininess = 1.0 + roughness * 100.0;

    vec3 reflectionDir = reflect(-shadowDir, mixedNormal);
    // points towards the camera
    vec3 viewDir = normalize(cameraPosition - viewPosToWorldPos(viewSpacePos.xyz));

    float diffuseLight = roughness * clamp(dot(normalize(mixedNormal), shadowDir), 0.0, 1.0);
    float specularLight = smoothness * pow(clamp(dot(reflectionDir, viewDir), 0.0, 1.0), shininess);

    float totalLight = clamp(diffuseLight + specularLight, 0.2, 1.0);
    // totalLight = totalLight * 0.5 + 0.5;

    vec3 blockLight = lightColor.rgb * totalLight;

    outColor0 = vec4(albedoColor.rgb * blockLight * aoAmount, albedoColor.a);

    // outColor0 = albedoColor * linearColor(vexColor) * lightColor;

    outColor0 = unlinearColor(outColor0);

    // outColor0 = vec4(vec3(roughness), 1.0);
    // outColor0 = vec4(vec3(albedoColor.a), 1.0);
    // outColor0 = vec4(blockLight, 1.0);
}