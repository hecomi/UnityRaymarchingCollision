Shader "Hidden/Image Effects/RimLight" 
{

Properties
{
    _MainTex("Base (RGB)", 2D) = "" {}
}

SubShader
{

ZTest Always
ZWrite Off
Cull Off

CGINCLUDE

#include "UnityCG.cginc"

sampler2D _MainTex;
float4 _Color;
float4 _Params1;
float4 _Params2;

#define _Intensity      _Params1.w
#define _FresnelBias    _Params1.x
#define _FresnelScale   _Params1.y
#define _FresnelPow     _Params1.z
#define _EdgeIntensity  _Params2.x
#define _EdgeThreshold  _Params2.y
#define _EdgeRadius     _Params2.z


struct VertexShaderIn
{
    float4 vertex : POSITION;
};

struct Vert2Frag
{
    float4 vertex    : SV_POSITION;
    float4 screenPos : TEXCOORD0;
};

struct FragmentShaderOut
{
    half4 color : SV_Target;
};


Vert2Frag vert(VertexShaderIn v)
{
    Vert2Frag o;
    o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
    o.screenPos = ComputeScreenPos(o.vertex);
    return o;
}


#define HalfPixelSize ((_ScreenParams.zw-1.0)*0.5)

sampler2D _CameraGBufferTexture0;   // diffuse color (rgb), occlusion (a)
sampler2D _CameraGBufferTexture1;   // spec color (rgb), smoothness (a)
sampler2D _CameraGBufferTexture2;   // normal (rgb), --unused, very low precision-- (a) 
sampler2D _CameraGBufferTexture3;   // emission (rgb), --unused-- (a)
sampler2D _CameraDepthTexture;

float4x4 _InvViewProj;

half4 GetAlbedo(float2 uv)          { return tex2D(_CameraGBufferTexture0, uv); }
half4 GetSpecular(float2 uv)        { return tex2D(_CameraGBufferTexture1, uv); }
half3 GetNormal(float2 uv)          { return tex2D(_CameraGBufferTexture2, uv).xyz * 2.0 - 1.0; }
half4 GetEmission(float2 uv)        { return tex2D(_CameraGBufferTexture3, uv); }
float GetDepth(float2 uv)           { return SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv); }

FragmentShaderOut frag(Vert2Frag i)
{
    float2 uv = i.screenPos.xy / i.screenPos.w;

    float depth = GetDepth(uv);
    if (depth >= 1.0) {
        FragmentShaderOut r;
        r.color = tex2D(_MainTex, uv);
        return r;
    }

    float3 p = mul(_InvViewProj, float4(uv, depth, 1.0)).xyz;
    float3 camDir = normalize(p.xyz - _WorldSpaceCameraPos.xyz);
    float3 n1 = GetNormal(uv).xyz * 2.0 - 1.0;
    float h = saturate(_FresnelBias + pow(dot(camDir, n1) + 1.0, _FresnelPow) * _FresnelScale) * _Intensity;

    float2 pixelSize = (_ScreenParams.zw - 1.0) * _EdgeRadius;
    float3 n2 = GetNormal(uv + float2(pixelSize.x, 0.0)).xyz;
    float3 n3 = GetNormal(uv + float2(0.0, pixelSize.y)).xyz;

    float t1 = dot(n1, n2) - _EdgeThreshold;
    float t2 = dot(n1, n3) - _EdgeThreshold;
    float t = clamp(min(min(t1, t2), 0.0) * -100000.0, 0.0, 1.0);
    h += _EdgeIntensity * t;

    h *= GetSpecular(uv).w;

    FragmentShaderOut r;
    r.color = tex2D(_MainTex, uv) + _Color * h;
    return r;
}

ENDCG

Pass 
{
    CGPROGRAM
    #pragma multi_compile ___ ENABLE_EDGE_HIGHLIGHTING
    #pragma multi_compile ___ ENABLE_SMOOTHNESS_ATTENUAION
    #pragma vertex vert
    #pragma fragment frag
    ENDCG
}

}

}