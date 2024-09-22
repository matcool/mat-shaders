#version 460

#include "core/utils.glsl"
#include "core/space_trans.glsl"
#include "core/brdf.glsl"
#include "core/water_caustics.glsl"
#include "core/options.glsl"
#include "core/debug.glsl"
#include "core/blocks.glsl"
#ifdef ENABLE_EASTER_EGG
#include "core/special_block.glsl"
#endif

uniform sampler2D gtexture;
uniform sampler2D lightmap;
uniform sampler2D normals;
uniform sampler2D specular;
uniform sampler2DShadow shadowtex0;
uniform sampler2DShadow shadowtex1;
uniform sampler2D shadowcolor0;
uniform sampler2D shadowcolor1;

uniform vec3 shadowLightPosition;
uniform vec3 eyePosition;
uniform vec3 playerLookVector;

uniform float alphaTestRef;
uniform float frameTimeCounter;
uniform float viewWidth;
uniform float viewHeight;

uniform int heldBlockLightValue;

/* DRAWBUFFERS:0 */
out vec4 outColor0;

in vec4 viewSpacePos;
in vec2 texCoord;
in vec4 vexColor;
in vec2 lightCoord;
in vec3 geoNormal;
in vec3 tangent;
in vec3 blockData;

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
    vec4 albedoColor = linearColor(texture(gtexture, texCoord)) * vec4(linearColor(vexColor.rgb), 1.0);
    if (albedoColor.a <= alphaTestRef) discard;

    vec3 worldPos = viewPosToWorldPos(viewSpacePos.xyz);

    // points towards the sun
    vec3 lightDir = viewDirToWorldDir(normalize(shadowLightPosition));
    // points towards the camera
    vec3 viewDir = normalize(cameraPosition - worldPos);

#ifdef ENABLE_EASTER_EGG
    if (IS_BLOCK(blockData.x, BLOCK_ID_SPECIAL)) {
        outColor0 = calcSpecialBlock(fract(worldPos - 0.0001 * geoNormal), -viewDir, frameTimeCounter);
        return;
    }
#endif

    /// normal
    vec3 normalTexture = texture(normals, texCoord).rgb * 2.0 - 1.0;
    normalTexture.b = sqrt(1.0 - dot(normalTexture.xy, normalTexture.xy));
    vec3 normal = tbnNormalTangent(geoNormal, viewDirToWorldDir(tangent)) * normalTexture.rgb;

    /// material properties
    vec4 specularTexture = texture(specular, texCoord);
    float roughness = pow(1.0 - specularTexture.r, 2.0);
    // reflectance only goes up to 229, as defined by labPBR
    float metallic = specularTexture.g * 255.0 > 229.0 ? 1.0 : 0.0;
    vec3 reflectance = mix(vec3(specularTexture.g), vec3(0.3), metallic);

    /// shadows
#ifdef ENABLE_SHADOWS
    vec3 shadowScreenPos = worldPosToShadowScreenPos(worldPos, normal);
    float acneBias = 0.001;
    float shadowMult = calculateShadowVisibility(shadowtex0, shadowScreenPos, acneBias);
    float shadowSolidMult = calculateShadowVisibility(shadowtex1, shadowScreenPos, acneBias);
    vec3 shadowBlockColor = texture(shadowcolor0, shadowScreenPos.xy).rgb;
    vec3 shadowBlockData = texture(shadowcolor1, shadowScreenPos.xy).rgb;

    // TODO: should be BLOCK_ID_WATER here but it doesnt work..
    if (shadowBlockData.x == 1) {
        // block is water, so apply fake caustics
        vec3 causticsPos = worldPos + cross(worldPos, lightDir) * 0.01;
        // DEBUG_COLOR(fract(causticsPos));
        shadowBlockColor = calculateWaterCaustics(causticsPos, shadowBlockColor, frameTimeCounter);
        // DEBUG_COLOR(shadowBlockColor);
    }
    vec3 shadowColor = mix(vec3(shadowMult), shadowBlockColor, clamp(shadowSolidMult - shadowMult, 0.0, 1.0));
#else
    // use skylight amount for shadow color /shrug
    vec3 shadowColor = vec3(lightCoord.y);
#endif

    /// lighting and colors
    float blockLightLevel = lightCoord.x;
    // dynamic lighting on held items
    if (heldBlockLightValue > 0) {
        float cameraDist = length(worldPos - eyePosition);
        float held = clamp(1.0 - (cameraDist / heldBlockLightValue), 0.0, 1.0);
        // bigger fall off
        held = pow(held, 3.0);
        held = held * (heldBlockLightValue / 16.0);
        blockLightLevel = max(held, blockLightLevel);
    }
#ifdef DISABLE_BLOCK_LIGHT_TINT
    vec3 blockLightColor = linearColor(vec3(blockLightLevel));
#else
    vec3 blockLightColor = linearColor(texture(lightmap, vec2(blockLightLevel, 1.0 / 32.0)).rgb);
#endif
    vec3 skyLightColor = linearColor(texture(lightmap, vec2(1.0 / 32.0, lightCoord.y)).rgb);
    float aoAmount = vexColor.a;

    vec3 ambientLight = clamp(blockLightColor * aoAmount + 0.2 * skyLightColor, 0.0, 0.9) * clamp(dot(geoNormal, normal), 0.0, 1.0);

    // also use sky light here for night time blueish light
    vec3 finalColor = skyLightColor * shadowColor * brdf(lightDir, viewDir, roughness, normal, albedoColor.rgb, metallic, reflectance);
    // prevents the block from being too dark
    finalColor += ambientLight * albedoColor.rgb;

    outColor0 = unlinearColor(vec4(finalColor, albedoColor.a));
}
