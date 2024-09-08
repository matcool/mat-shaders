#version 460

#include "programs/utils.glsl"
#include "programs/frag_utils.glsl"
#include "programs/brdf.glsl"

uniform sampler2D gtexture;
uniform sampler2D lightmap; 
uniform sampler2D normals;
uniform sampler2D specular;
uniform sampler2D shadowtex0;
uniform sampler2D shadowcolor0;

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
const int shadowMapResolution = 1024; // [512 1024 2048 4096 8192]

void main() {
    // lightCoord is (blockLightAmt, skyLightAmt), and it starts at 1/32
    vec3 blockLightColor = linearColor(texture(lightmap, vec2(lightCoord.x, 1.0 / 32.0)).rgb);
    vec3 skyLightColor = linearColor(texture(lightmap, vec2(1.0 / 32.0, lightCoord.y)).rgb);

    vec4 albedoColor = linearColor(texture(gtexture, texCoord)) * vec4(linearColor(vexColor.rgb), 1.0);
    float aoAmount = vexColor.a;
    if (albedoColor.a <= alphaTestRef) discard;


    vec3 worldPos = viewPosToWorldPos(viewSpacePos.xyz);

    vec3 shadowDir = viewDirToWorldDir(normalize(shadowLightPosition));
    // points towards the camera
    vec3 viewDir = normalize(cameraPosition - worldPos);

    /// normal
    vec3 normalTexture = texture(normals, texCoord).rgb * 2.0 - 1.0;
    normalTexture.b = sqrt(1.0 - dot(normalTexture.xy, normalTexture.xy));
    vec3 normal = tbnNormalTangent(geoNormal, viewDirToWorldDir(tangent)) * normalTexture.rgb;

    /// specular
    vec4 specularTexture = texture(specular, texCoord);
    float perceptualSmoothness = specularTexture.r;

    /// material properties
    float roughness = pow(1.0 - perceptualSmoothness, 2.0);
    float smoothness = 1.0 - sqrt(roughness);
    // reflectance only goes up to 229, as defined by labPBR
    float metallic = specularTexture.g * 255.0 > 229.0 ? 1.0 : 0.0;
    vec3 reflectance = mix(vec3(specularTexture.g), vec3(0.3), metallic);

    /// shadows
    vec3 shadowScreenPos = worldPosToShadowScreenPos(worldPos, normal);
    float shadowTextureValue = texture(shadowtex0, shadowScreenPos.xy).r;
    // float shadowFarAway = pow(abs(shadowTextureValue - shadowScreenPos.z), 1.0 / 2.0);
    // shadowScreenPos.z is the depth from the light's perspective,
    // so values less than the depth are in shadow, because another block was closer
    float shadow = smoothstep(shadowScreenPos.z - 0.001, shadowScreenPos.z, shadowTextureValue);
    vec3 shadowColor = texture(shadowcolor0, shadowScreenPos.xy).rgb;


    /// lighting and colors
    vec3 ambientLight = (blockLightColor * aoAmount + 0.2 * skyLightColor) * clamp(dot(geoNormal, normal), 0.0, 1.0);

    // also use sky light here for night time blueish light
    vec3 finalColor = skyLightColor * shadow * brdf(shadowDir, viewDir, roughness, normal, albedoColor.rgb, metallic, reflectance);
    // prevents the block from being too dark
    finalColor += ambientLight * albedoColor.rgb;
    // finalColor = max(finalColor, ambientLight * albedoColor.rgb);

    outColor0 = unlinearColor(vec4(finalColor, albedoColor.a));

    // outColor0 = vec4(vec3(shadow), 1.0);
    // outColor0 = vec4(vec3(albedoColor.a), 1.0);
    // outColor0 = vec4(vec3(shadow), 1.0);

    // outColor0 = texture(shadowtex0, gl_FragCoord.xy / vec2(1920, 1080));
}