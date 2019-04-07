// Geometry shader
//

#include "CustomTesselation.cginc"
#include "Lighting.cginc"
#include "AutoLight.cginc"


float _BendRotationRandom;
float _BladeHeight;
float _BladeHeightRandom;	
float _BladeWidth;
float _BladeWidthRandom;

sampler2D _WindDistortionMap;
float4 _WindDistortionMap_ST;

float2 _WindFrequency;
float _WindStrength;

float _TranslucentGain;

struct geometryOutput
{
    float4 pos : SV_POSITION;
    float2 uv : TEXCOORD;
    float3 normal : NORMAL;
    unityShadowCoord4 _ShadowCoord : TEXCOORD1;
};

geometryOutput VertexOutput(float3 pos, float2 uv, float3 localNormal)
{
    geometryOutput o;
    o.pos = UnityObjectToClipPos(pos);
    o.uv = uv;
    o._ShadowCoord = ComputeScreenPos(o.pos);
    o.normal = UnityObjectToWorldNormal(localNormal);
    #if UNITY_PASS_SHADOWCASTER
	// Applying the bias prevents artifacts from appearing on the surface.
	o.pos = UnityApplyLinearShadowBias(o.pos);
    #endif
    return o;
}

float rand(float3 myVector){
    return frac(sin( dot(myVector ,float3(12.9898,78.233,45.5432) )) * 43758.5453);
}

float3x3 AngleAxis3x3(float v, float3 a)
{
    float c = cos(v);
    float s = sin(v);
    return float3x3(
        a.x*a.x*(1-c)+c, a.x*a.y*(1-c)-a.z*s, a.x*a.z*(1-c)+a.y*s,
        a.x*a.y*(1-c)+a.z*s, a.y*a.y*(1-c)+c, a.y*a.z*(1-c)-a.x*s,
        a.x*a.z*(1-c)-a.y*s, a.y*a.z*(1-c)+a.x*s, a.z*a.z*(1-c)+c
    );
}

[maxvertexcount(3)]
void geo(point InterpolatorsVertex IN[1] : SV_POSITION, inout TriangleStream<geometryOutput> triStream)
{
    float3 pos = IN[0].pos;
    float3 vNormal = IN[0].normal;
    float4 vTangent = IN[0].tangent;
    float3 vBinormal = cross(vNormal, vTangent) * vTangent.w;

    float3x3 tangentToLocal = float3x3(
        vTangent.x, vBinormal.x, vNormal.x,
        vTangent.y, vBinormal.y, vNormal.y,
        vTangent.z, vBinormal.z, vNormal.z
    );

    float2 uv = pos.xz * _WindDistortionMap_ST.xy + _WindDistortionMap_ST.zw + _WindFrequency * _Time.y;
    
    float2 windSample = (tex2Dlod(_WindDistortionMap, float4(uv, 0, 0)).xy * 2 - 1) * _WindStrength;
    float3 wind = normalize(float3(windSample.x, windSample.y, 0));
    float3x3 windRotation = AngleAxis3x3(UNITY_PI * windSample, wind);

    float3x3 facingRotationMatrix = AngleAxis3x3(rand(pos) * UNITY_TWO_PI, float3(0,0,1));
    float3x3 bendRotationMatrix = AngleAxis3x3(rand(pos.zzx) * _BendRotationRandom * UNITY_PI * 0.5, float3(1, 0, 0));
    
    float3x3 transformationMatrix = mul(mul(mul(tangentToLocal, windRotation), facingRotationMatrix), bendRotationMatrix);
    float3x3 transformationMatrixFacing = mul(tangentToLocal, facingRotationMatrix);
    float3 tangentNormal = float3(0, -1, 0);
    float3 localNormal = mul(transformationMatrix, tangentNormal);
    
    float height = (rand(pos.zyx) * 2 - 1) * _BladeHeightRandom + _BladeHeight;
    float width = (rand(pos.xzy) * 2 - 1) * _BladeWidthRandom + _BladeWidth;

    triStream.Append(VertexOutput(pos + mul(transformationMatrixFacing, float3(width,0,0)), float2(0, 0), localNormal));
    triStream.Append(VertexOutput(pos + mul(transformationMatrixFacing, float3(-width,0,0)), float2(1, 0), localNormal));
    triStream.Append(VertexOutput(pos + mul(transformationMatrix, float3(0,0,height)), float2(0.5, 1), localNormal));
}

// Fragment Program
//
float4 _TopColor;
float4 _BottomColor;

fixed4 fragmentGrass (geometryOutput i) : SV_Target {
	UNITY_SETUP_INSTANCE_ID(i);
    float NdotL = saturate(saturate(dot(i.normal, _WorldSpaceLightPos0)) + _TranslucentGain);

    float3 ambient = ShadeSH9(float4(i.normal, 1));
    float4 lightIntensity = NdotL * _LightColor0 + float4(ambient, 1);

    #if defined (SHADOWS_SCREEN)  
        return lerp(_BottomColor, _TopColor * lightIntensity, i.uv.y) * LIGHT_ATTENUATION(i);
    #else
        return lerp(_BottomColor, _TopColor * lightIntensity, i.uv.y);
    #endif
}
