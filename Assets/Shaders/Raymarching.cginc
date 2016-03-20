#ifndef raymarching_h
#define raymarching_h

#include "UnityCG.cginc"

float3 GetCameraPosition()    { return _WorldSpaceCameraPos;      }
float3 GetCameraForward()     { return -UNITY_MATRIX_V[2].xyz;    }
float3 GetCameraUp()          { return UNITY_MATRIX_V[1].xyz;     }
float3 GetCameraRight()       { return UNITY_MATRIX_V[0].xyz;     }
float  GetCameraFocalLength() { return abs(UNITY_MATRIX_P[1][1]); }
float  GetCameraMaxDistance() { return _ProjectionParams.z - _ProjectionParams.y; }

float2 GetScreenPos(float4 screenPos)
{
#if UNITY_UV_STARTS_AT_TOP
    screenPos.y *= -1.0;
#endif
    screenPos.x *= _ScreenParams.x / _ScreenParams.y;
    return float2(screenPos.x, screenPos.y);
}

float3 GetRayDirection(float4 screenPos)
{
    float2 sp = GetScreenPos(screenPos);

    float3 camPos      = GetCameraPosition();
    float3 camDir      = GetCameraForward();
    float3 camUp       = GetCameraUp();
    float3 camSide     = GetCameraRight();
    float  focalLen    = GetCameraFocalLength();
    float  maxDistance = GetCameraMaxDistance();

    return normalize((camSide * sp.x) + (camUp * sp.y) + (camDir * focalLen));
}

float GetDepth(float3 pos)
{
    float4 vpPos = mul(UNITY_MATRIX_VP, float4(pos, 1.0));
#if defined(SHADER_TARGET_GLSL)
    return (vpPos.z / vpPos.w) * 0.5 + 0.5;
#else 
    return vpPos.z / vpPos.w;
#endif 
}

float3 GetNormal(float3 pos)
{
    const float d = 0.001;
    return 0.5 + 0.5 * normalize(float3(
        DistanceFunc(pos + float3(  d, 0.0, 0.0)) - DistanceFunc(pos + float3( -d, 0.0, 0.0)),
        DistanceFunc(pos + float3(0.0,   d, 0.0)) - DistanceFunc(pos + float3(0.0,  -d, 0.0)),
        DistanceFunc(pos + float3(0.0, 0.0,   d)) - DistanceFunc(pos + float3(0.0, 0.0,  -d))));
}

struct VertInput
{
    float4 vertex : POSITION;
};

struct VertOutput
{
    float4 vertex    : SV_POSITION;
    float4 screenPos : TEXCOORD0;
};

struct GBufferOut
{
    half4 diffuse  : SV_Target0; // rgb: diffuse,  a: occlusion
    half4 specular : SV_Target1; // rgb: specular, a: smoothness
    half4 normal   : SV_Target2; // rgb: normal,   a: unused
    half4 emission : SV_Target3; // rgb: emission, a: unused
    float depth    : SV_Depth;
};

VertOutput vert(VertInput v)
{
    VertOutput o;
    o.vertex = v.vertex;
    o.screenPos = o.vertex;
    return o;
}

#endif