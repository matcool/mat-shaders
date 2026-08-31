#version 330 compatibility

#include "core/utils.glsl"
#include "core/space_trans.glsl"
#include "core/water_caustics.glsl"
#include "core/options.glsl"
#include "core/debug.glsl"
#include "core/blocks.glsl"

uniform sampler2D gtexture;
uniform sampler2D lightmap;
uniform sampler2D normals;
uniform sampler2D specular;
uniform sampler2DShadow shadowtex0;
uniform sampler2DShadow shadowtex1;
uniform sampler2D shadowcolor0;
uniform sampler2D shadowcolor1;

uniform vec4 entityColor;

uniform vec3 shadowLightPosition;
uniform vec3 eyePosition;
uniform vec3 playerLookVector;

uniform float alphaTestRef;
uniform float frameTimeCounter;
uniform float viewWidth;
uniform float viewHeight;

uniform int heldBlockLightValue;
uniform int entityId;
uniform int renderStage;

/* RENDERTARGETS: 0,1,2,3 */
layout(location = 0) out vec4 outColor0;
layout(location = 1) out vec4 outLightmap;
layout(location = 2) out vec4 outNormal;
layout(location = 3) out vec4 outMaterial;

in vec4 viewSpacePos;
in vec2 texCoord;
in vec4 vexColor;
in vec2 lightCoord;
in vec3 geoNormal;
in vec3 tangent;
in vec3 blockData;

void main() {
    vec4 albedoColor = linearColor(texture(gtexture, texCoord)) * vec4(linearColor(vexColor.rgb), 1.0);
    if (albedoColor.a <= alphaTestRef) discard;
    albedoColor.rgb = mix(albedoColor.rgb, entityColor.rgb, entityColor.a);

#ifdef MAT_PASS_ENTITIES
    albedoColor *= vexColor;

    // special entities, dont run lighting
    if (entityId == ENTITY_ID_SHADOW || entityId == 0) {
        outColor0 = unlinearColor(albedoColor);
        return;
    }
#endif

    /// normal
    vec3 normalTexture = texture(normals, texCoord).rgb * 2.0 - 1.0;
    normalTexture.b = sqrt(1.0 - dot(normalTexture.xy, normalTexture.xy));
    vec3 normal = tbnNormalTangent(geoNormal, viewDirToWorldDir(tangent)) * normalTexture.rgb;

    /// material properties
    vec4 specularTexture = texture(specular, texCoord);

    float aoAmount = vexColor.a;

    outColor0 = unlinearColor(albedoColor);
    outLightmap = vec4(lightCoord, aoAmount, 1.0);
    outNormal = vec4(normal * 0.5 + 0.5, 1.0);
    outMaterial = vec4(specularTexture.rg, 0.0, 1.0);
}
