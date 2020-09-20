Shader "WX/URP/Post/scan"
{

    Properties
    {
        [Header(Scan Texture)]
        [HideInInspector]_MainTex ("MainTex", 2D) = "white" { }
        _scantex ("Scan Tex", 2D) = "white" { }
        _NScale ("Scan Tex Scale", Range(0, 10)) = 1

        [Header(Scan Line)]
        [HDR]_color ("Color", Color) = (1, 1, 1, 1)
        _width ("Width", Range(0, 0.5)) = 0.02
        _Speed ("Speed", float) = 1
        _Smoothness ("Smoothness Innerline", Range(0, 10)) = 2
    }

    SubShader
    {
        Tags { "RenderPipeline" = "UniversalRenderPipeline" }
        Cull Off ZWrite Off ZTest Always

        HLSLINCLUDE

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        CBUFFER_START(UnityPerMaterial)
        float4 _MainTex_ST;
        float4 _scantex_ST;
        real4 _color;
        half _width;
        half _Speed, _SpeedRange, _Smoothness;
        half _time,_Disappear;
        half _NScale;
        float3 _ScanPosition;
        CBUFFER_END

        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);
        TEXTURE2D(_scantex);
        SAMPLER(sampler_scantex);
        TEXTURE2D(_CameraDepthTexture);
        SAMPLER(sampler_CameraDepthTexture);
        TEXTURE2D(_CameraDepthNormalsTexture);
        SAMPLER(sampler_CameraDepthNormalsTexture);
        

        float4x4 Matrix;

        struct a2v
        {
            float4 positionOS: POSITION;
            float2 texcoord: TEXCOORD;
        };

        struct v2f
        {
            float4 positionCS: SV_POSITION;
            float2 texcoord: TEXCOORD;
            float3 Dirction: TEXCOORD1;
        };
        
        ENDHLSL
        
        pass
        {
            HLSLPROGRAM
            
            #pragma vertex VERT
            #pragma fragment FRAG

            float easeInOutCubic(float x) {
                return x < 0.5 ? 4 * x * x * x : 1 - pow(-2 * x + 2, 3) / 2;
            }

            v2f VERT(a2v i)
            {
                v2f o;
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                o.texcoord = i.texcoord;
                int t = 0;
                if (i.texcoord.x < 0.5 && i.texcoord.y < 0.5)
                t = 0;
                else if(i.texcoord.x > 0.5 && i.texcoord.y < 0.5)
                t = 1;
                else if(i.texcoord.x > 0.5 && i.texcoord.y > 0.5)
                t = 2;
                else
                t = 3;
                o.Dirction = Matrix[t].xyz;
                return o;
            }

            real4 FRAG(v2f i): SV_TARGET
            {
                //_MainTex在这里默认为后处理前的源屏幕颜色
                real4 tex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord);
                half depth = LinearEyeDepth(SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, i.texcoord).x, _ZBufferParams).x;
                float3 WSpos = _WorldSpaceCameraPos.xyz + depth * i.Dirction;//得到世界坐标


                float3 disWS = distance(_ScanPosition + 0, WSpos);
                half speed = _Speed * _SpeedRange * 5;
                float3 sphere1 =  1 - saturate(disWS / ((_time + 0.001) * speed));
                float3 sphere2 = saturate(saturate(disWS / ((_time + 0.001) * speed) - _width)*_Smoothness/_width);


                float sphere = sphere1.r * sphere2.r *easeInOutCubic(saturate(_Disappear));
                float4 col = sphere * _color;

                float2 uv = i.texcoord;

                //获取世界坐标下的法线深度图:_CameraDepthNormalsTexture的xyz是法线信息，w是深度信息
                float4 normal = SAMPLE_TEXTURE2D(_CameraDepthNormalsTexture, sampler_CameraDepthNormalsTexture, i.texcoord);
                //三面映射做纹理
                float4 blendNormal = saturate(pow(normal * 1.4, 4));
                half4 nSide1 = SAMPLE_TEXTURE2D(_scantex, sampler_scantex, WSpos.xy * (normal.xy + 1) * 0.01 * _NScale);
                half4 nSide2 = SAMPLE_TEXTURE2D(_scantex, sampler_scantex, WSpos.xz * (normal.xz + 1) * 0.01 * _NScale);
                half4 nTop = SAMPLE_TEXTURE2D(_scantex, sampler_scantex, WSpos.yz * (normal.yz + 1) * 0.01 * _NScale);

                float3 noisetexture = nSide1.rgb;
                noisetexture = lerp(noisetexture, nTop.rgb, blendNormal.x);
                noisetexture = lerp(noisetexture, nSide2.rgb, blendNormal.y);
                
                
                return col * half4(1-noisetexture, 1) + tex;
                //return float4(normal.xyz,1);
            }
            ENDHLSL
            
        }
    }
}