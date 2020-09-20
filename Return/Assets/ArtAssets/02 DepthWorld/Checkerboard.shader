Shader "Universal Render Pipeline/Custom/Checkerboard"
{
    Properties
    {
        _Color ("Color", Color) = (1, 1, 1, 1)
        _Smooth("Smooth",float) = 5
        _DeepColor ("DeepColor", Color) = (1, 1, 1, 1)
        _DeepOffset ("Deep", float) = 0.5
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalRenderPipeline" }
        Cull front

        Pass
        {
            Tags { "LightMode" = "UniversalForward" }
            
            HLSLPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct a2v
            {
                float4 vertex: POSITION;
                float2 uv: TEXCOORD0;
            };

            struct v2f
            {
                float2 uv: TEXCOORD0;
                float4 pos: SV_POSITION;
                float3 localPos: TEXCOORD1;
            };

            // TEXTURE2D(_MainTex);
            // SAMPLER(sampler_MainTex);
            // float4 _MainTex_ST;

            CBUFFER_START(UnityPerMaterial)
            half4 _Color,_DeepColor;
            half _Sheet, _DeepOffset,_Smooth;
            CBUFFER_END


            v2f vert(a2v v)
            {
                v2f o;
                o.pos = TransformObjectToHClip(v.vertex.xyz);
                o.uv = v.uv;
                o.localPos = v.vertex.xyz;
                return o;
            }

            half4 frag(v2f i): SV_Target
            {


                float mask = smoothstep(-_Smooth,_Smooth,i.localPos.y  - _DeepOffset);
                float4 col =  _Color * mask+(1-mask)*_DeepColor;

                return col;
            }
            ENDHLSL
            
        }

        Pass
        {
            Tags{ "LightMode" = "DepthOnly" }

            ZWrite On
            ColorMask 0

            HLSLPROGRAM

            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment


            #include "Packages/com.unity.render-pipelines.universal/Shaders/UnlitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"
            ENDHLSL
        }

        
    }


}