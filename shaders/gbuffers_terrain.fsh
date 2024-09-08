#version 460

#include "programs/utils.glsl"
#include "programs/frag_utils.glsl"
#include "programs/brdf.glsl"

uniform sampler2D gtexture;
uniform sampler2D lightmap; 
uniform sampler2D normals;
uniform sampler2D specular;
uniform sampler2DShadow shadowtex0;
uniform sampler2DShadow shadowtex1;
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
const bool shadowHardwareFiltering = true;

vec2 poissonDisk[4] = vec2[] (
    vec2(-0.94201624, -0.39906216),
    vec2(0.94558609, -0.76890725),
    vec2(-0.094184101, -0.92938870),
    vec2(0.34495938, 0.29387760)
);

float calculateShadowVisibility(sampler2DShadow s, vec3 shadowScreenPos, float acneBias) {
    float visibility = 0.0;
    for (int i = 0; i < 4; i++) {
        visibility += texture(s, vec3(shadowScreenPos.xy + poissonDisk[i] / shadowMapResolution, shadowScreenPos.z), acneBias);
    }
    return visibility / 4.0;
    // return texture(s, shadowScreenPos, acneBias);
}

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
    float acneBias = 0.001;
    float shadowMult = calculateShadowVisibility(shadowtex0, shadowScreenPos, acneBias);
    float shadowSolidMult = calculateShadowVisibility(shadowtex1, shadowScreenPos, acneBias);
    vec3 shadowBlockColor = texture(shadowcolor0, shadowScreenPos.xy).rgb;

    vec3 shadowColor = mix(vec3(shadowMult), shadowBlockColor, clamp(shadowSolidMult - shadowMult, 0.0, 1.0));

    /// lighting and colors
    vec3 ambientLight = clamp(blockLightColor * aoAmount + 0.2 * skyLightColor, 0.0, 0.9) * clamp(dot(geoNormal, normal), 0.0, 1.0);

    // also use sky light here for night time blueish light
    vec3 finalColor = skyLightColor * shadowColor * brdf(shadowDir, viewDir, roughness, normal, albedoColor.rgb, metallic, reflectance);
    // prevents the block from being too dark
    finalColor += ambientLight * albedoColor.rgb;
    // finalColor = max(finalColor, ambientLight * albedoColor.rgb);

    outColor0 = unlinearColor(vec4(finalColor, albedoColor.a));

    // outColor0 = vec4(vec3(calculateShadowVisibility(shadowtex0, shadowScreenPos, acneBias)), 1.0);
    // outColor0 = vec4(vec3(ambientLight), 1.0);

    // outColor0 = texture(shadowtex0, gl_FragCoord.xy / vec2(1920, 1080));
}