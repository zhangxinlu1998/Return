Shader "Universal Render Pipeline/Custom/Hair"
{
    Properties
    {
        _MaskTex("MaskTex", 2D) = "white" {}
        _HairAlpha("HairAlpha",2D) = "Gray"{}
        _Normal("Normal",2D) = "bump"{}
        _LerpColor1("LerpColor1", Color) = (1,1,1,1)
        _LerpColor2("LerpColor2", Color) = (1,1,1,1)
        [HDR]_UpLayerColor("UpLayerColor",Color) = (1,1,1,1)
        _DownLayerColor("DownLayerColor",Color) = (1,1,1,1)
        _AnisotropyUpLayer("Anisotropy UpLayer",Range(1,1000)) = 500
        _AnisotropyDownLayer("Anisotropy DownLayer",Range(1,1000)) = 500
        _Ramp("Ramp",Range(0,1)) = 0.5
        _HeightRange("Height Range",Range(0,5)) = 1
        _AnisotropyTensity("Anisotropy Intensity",Range(0,1)) = 1
        _HairGPower("HairGPower",float) = 0
        _HeightPower("Height Power",float) = 1
        _HeightOffset("Height Offset",float) = 0

    }

    SubShader
    {
        Tags { "Queue"="Transparent" "RenderPipeline"="UniversalRenderPipeline"}

        Pass
        {
            Tags { "LightMode"="UniversalForward" }
            Blend SrcAlpha OneMinusSrcAlpha

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct a2v
            {
                float4 vertex  : POSITION;
                float2 uv        : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent:TANGENT;
            };

            struct v2f
            {
                float2 uv        : TEXCOORD0;
                float4 pos  : SV_POSITION;
                float3 PosWS :TEXCOORD1;
                float3 BitangentWS :TEXCOORD2;
                float3 NormalWS :TEXCOORD3;
                float3 TangentWS :TEXCOORD4;
            };

            TEXTURE2D(_MaskTex);
            SAMPLER(sampler_MaskTex);
            TEXTURE2D(_HairAlpha);
            SAMPLER(sampler_HairAlpha);
            TEXTURE2D(_Normal);
            SAMPLER(sampler_Normal);

            CBUFFER_START(UnityPerMaterial)
            half4 _LerpColor1,_LerpColor2,_UpLayerColor,_DownLayerColor;
            float4 _MaskTex_ST;
            real _AnisotropyUpLayer,_AnisotropyDownLayer,_Ramp,_HeightRange,_AnisotropyTensity,_HairGPower,_HeightPower,_HeightOffset;
            CBUFFER_END


            v2f vert(a2v v)
            {
                v2f o;
                o.pos = TransformObjectToHClip(v.vertex.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _MaskTex);
                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                return SAMPLE_TEXTURE2D(_MaskTex, sampler_MaskTex, i.uv) * _LerpColor1;
            }
            ENDHLSL
        }

    }
}