Shader "Raymarching/Test"
{

Properties
{
    _MainTex ("Main Texture", 2D) = "" {}
}

SubShader
{

Tags { "RenderType" = "Opaque" "DisableBatching" = "True" "Queue" = "Geometry+10" }
Cull Off

Pass
{
    Tags { "LightMode" = "Deferred" }

    Stencil 
    {
        Comp Always
        Pass Replace
        Ref 128
    }

    CGPROGRAM
    #pragma vertex vert
    #pragma fragment frag
    #pragma target 3.0
    #pragma multi_compile ___ UNITY_HDR_ON

    #include "UnityCG.cginc"
    #include "Utils.cginc"
    #include "Primitives.cginc"

    #define PI 3.14159265358979

    float DistanceFunc(float3 pos)
    {
        //float r = abs(sin(2 * PI * _Time.y / 2.0));
        float r = 0.2;
        float d1 = roundBox(repeat(pos, float3(6, 6, 6)), 1, r);
        float d2 = sphere(pos, 3.0);
        float d3 = floor(pos - float3(0, -3, 0));
        return smoothMin(smoothMin(d1, d2, 1.0), d3, 1.0);
    }

    #include "Raymarching.cginc"

    sampler2D _MainTex;

    GBufferOut frag(VertOutput i)
    {
        float3 rayDir = GetRayDirection(i.screenPos);

        float3 camPos = GetCameraPosition();
        float maxDist = GetCameraMaxDistance();

        float distance = 0.0;
        float len = 0.0;
        float3 pos = camPos + _ProjectionParams.y * rayDir;
        for (int i = 0; i < 100; ++i) {
            distance = DistanceFunc(pos);
            len += distance;
            pos += rayDir * distance;
            if (distance < 0.001 || len > maxDist) break;
        }

        if (distance > 0.001) discard;

        float depth = GetDepth(pos);
        float3 normal = GetNormal(pos);

		float u = (1.0 - floor(fmod(pos.x, 2.0))) * 5;
		float v = (1.0 - floor(fmod(pos.y, 2.0))) * 5;

        GBufferOut o;
        o.diffuse  = float4(1.0, 1.0, 1.0, 1.0);
        o.specular = float4(0.5, 0.5, 0.5, 1.0);
        o.emission = tex2D(_MainTex, float2(u, v)) * 3;
        o.depth    = depth;
        o.normal   = float4(normal, 1.0);

#ifndef UNITY_HDR_ON
        o.emission = exp2(-o.emission);
#endif

        return o;
    }

    ENDCG
}

}

Fallback Off
}