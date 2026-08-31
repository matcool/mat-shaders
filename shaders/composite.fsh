#version 330 compatibility

#include "core/utils.glsl"
#include "core/space_trans.glsl"
#include "core/brdf.glsl"
#include "core/water_caustics.glsl"
#include "core/options.glsl"
#include "core/debug.glsl"
#include "core/blocks.glsl"

// buffers written by our gbuffer shader
uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex3;

uniform sampler2DShadow shadowtex0;
uniform sampler2DShadow shadowtex1;
uniform sampler2D shadowcolor0;
uniform sampler2D shadowcolor1;
uniform sampler2D depthtex0;
uniform sampler2D lightmap;

uniform vec4 entityColor;

uniform vec3 shadowLightPosition;
uniform vec3 eyePosition;
uniform vec3 playerLookVector;
uniform int heldBlockLightValue;

uniform float alphaTestRef;
uniform float frameTimeCounter;

uniform mat4 gbufferProjectionInverse;

in vec2 texCoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outColor0;

vec3 screenToView(vec2 screenPos, float depth) {
	vec4 ndcPos = vec4(screenPos, depth, 1.0) * 2.0 - 1.0;
	vec4 tmp = gbufferProjectionInverse * ndcPos;
	return tmp.xyz / tmp.w;
}

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

// cant access the lightmap texture here, so just estimate

vec3 getBlockLightColor(float amt) {
    // not great, values close to 1.0 should explode to white
    return unlinearColor(vec3(1.0, 0.5, 0.08)) * smoothstep(0.0, 1.0, amt);
}

vec3 getSkyLightColor(float amt) {
    return vec3(smoothstep(0.0, 1.0, amt));
}

void main() {
    vec4 rawColortex0 = texture(colortex0, texCoord);
    vec4 rawNormal = texture(colortex2, texCoord);

    // not rendered by our gbuffer shader
	if (rawNormal.a == 0.0) {
		outColor0 = rawColortex0;
        return;
	}

    vec4 rawLightCoord = texture(colortex1, texCoord);
    vec4 rawMaterial = texture(colortex3, texCoord);

    vec2 lightCoord = rawLightCoord.rg;
    float aoAmount = rawLightCoord.b;
    vec3 normal = normalize((rawNormal.rgb - 0.5) * 2.0);
    vec4 albedoColor = linearColor(rawColortex0);

    float depth = texture(depthtex0, texCoord).r;

    vec3 viewSpacePos = screenToView(texCoord.xy, depth);
    vec3 worldPos = viewPosToWorldPos(viewSpacePos.xyz);

    // points towards the sun
    vec3 lightDir = viewDirToWorldDir(normalize(shadowLightPosition));
    // points towards the camera
    vec3 viewDir = normalize(cameraPosition - worldPos);

    /// material properties
    vec2 specularTexture = rawMaterial.rg;
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
    vec3 shadowColor = vec3(linearMap(smoothstep(0.9, 0.95, lightCoord.y), 0.0, 1.0, 0.4, 1.0));
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
    vec3 blockLightColor = linearColor(vec3(clamp(blockLightLevel, 0.1, 1.0)));
#else
    vec3 blockLightColor = getBlockLightColor(blockLightLevel);
#endif
    vec3 skyLightColor = getSkyLightColor(lightCoord.y);

    vec3 ambientLight = clamp(blockLightColor + 0.2 * skyLightColor, 0.0, 0.9) * clamp(dot(normal, normal), 0.0, 1.0) * aoAmount;

    // also use sky light here for night time blueish light
    vec3 finalColor = skyLightColor * shadowColor * brdf(lightDir, viewDir, roughness, normal, albedoColor.rgb, metallic, reflectance);
    // prevents the block from being too dark
    finalColor += ambientLight * albedoColor.rgb;

    outColor0 = unlinearColor(vec4(finalColor, albedoColor.a));
}
