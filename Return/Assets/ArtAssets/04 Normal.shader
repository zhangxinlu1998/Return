Shader "URP/normal"
{

    Properties
    {
        _MainTex ("MainTex", 2D) = "white" { }
        _BaseColor ("BaseColor", Color) = (1, 1, 1, 1)
        [Normal]_NormalTex ("Normal", 2D) = "bump" { }//注意这里是小写
        _NormalScale ("NormalScale", Range(0, 1)) = 1
        [IntRange]_SpecularRange ("SpecularRange", Range(1, 200)) = 50
        [HDR]_SpecularColor ("SpecularColor", Color) = (1, 1, 1, 1)
        _Shadow ("Shadow Strength", Range(0, 1)) = 0.5
        _ShadowSmoothness ("Shadow Smoothness", Range(0.01, 2)) = 0.5
    }

    SubShader
    {
        Tags { "RenderPipeline" = "UniversalRenderPipeline" }

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
        #pragma multi_compile _ _SHADOWS_SOFT

        CBUFFER_START(PerMaterials)
        float4 _NormalTex_ST;
        float4 _MainTex_ST;
        real4 _BaseColor;
        real _NormalScale;
        real _SpecularRange, _Shadow, _ShadowSmoothness;
        real4 _SpecularColor;
        CBUFFER_END

        TEXTURE2D(_MainTex);
        TEXTURE2D(_NormalTex);
        SAMPLER(sampler_MainTex);
        SAMPLER(sampler_NormalTex);

        struct a2v
        {
            float3 positionOS: POSITION;
            float2 texcoord: TEXCOORD0;
            float3 normalOS: NORMAL;
            float4 tangentOS: TANGENT;
        };

        struct v2f
        {
            float4 positionCS: SV_POSITION;
            float4 texcoord: TEXCOORD0;
            float4 tangentWS: TANGENT;
            float4 normalWS: NORMAL;
            float4 BtangentWS: TEXCOORD1;
            float3 positionWS: TEXCOORD2;
        };
        
        ENDHLSL
        
        Pass
        {

            NAME"MainPass"
            Tags { "LightMode" = "UniversalForward" }
            
            HLSLPROGRAM
            
            #pragma vertex vert
            #pragma fragment  frag



            v2f vert(a2v v)
            {
                v2f o;
                ZERO_INITIALIZE(v2f, o);
                o.texcoord.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.texcoord.zw = TRANSFORM_TEX(v.texcoord, _NormalTex);
                o.positionCS = TransformObjectToHClip(v.positionOS);
                o.normalWS.xyz = normalize(TransformObjectToWorldNormal(v.normalOS));
                o.tangentWS.xyz = normalize(TransformObjectToWorld(v.tangentOS.xyz));
                o.BtangentWS.xyz = cross(o.normalWS.xyz, o.tangentWS.xyz) * v.tangentOS.w * unity_WorldTransformParams.w;
                //这里乘一个unity_WorldTransformParams.w是为判断是否使用了奇数相反的缩放

                o.positionWS = TransformObjectToWorld(v.positionOS.xyz);
                o.tangentWS.w = o.positionWS.x;
                o.BtangentWS.w = o.positionWS.y;
                o.normalWS.w = o. positionWS.z;
                return o;
            }

            real4 frag(v2f i): SV_TARGET
            {

                float3 WSpos = float3(i.tangentWS.w, i.BtangentWS.w, i.normalWS.w);
                float3x3 T2W = {
                    i.tangentWS.xyz, i.BtangentWS.xyz, i.normalWS.xyz
                };
                real4 nortex = SAMPLE_TEXTURE2D(_NormalTex, sampler_NormalTex, i.texcoord.zw);
                float3 normalTS = UnpackNormalScale(nortex, _NormalScale);
                normalTS.z = pow((1 - pow(normalTS.x, 2) - pow(normalTS.y, 2)), 0.5);//规范化法线
                float3 norWS = normalize(mul(normalTS, T2W));//注意这里是右乘T2W的，等同于左乘T2W的逆

                //shadow
                float4 SHADOW_COORDS = TransformWorldToShadowCoord(i.positionWS);
                Light mainLight = GetMainLight(SHADOW_COORDS);
                half shadow = saturate(mainLight.shadowAttenuation + _Shadow);

                Light mylight = GetMainLight();
                //half shadow = mainLight.shadowAttenuation;
                float3 WS_L = normalize(mylight.direction);
                float3 WS_N = normalize(i.normalWS);
                float3 WS_V = normalize(_WorldSpaceCameraPos - WSpos);
                float3 WS_H = normalize(WS_V + WS_L);
                float lambert = dot(norWS, WS_L);//计算兰伯特
                lambert = saturate(saturate(lambert / _ShadowSmoothness) + _Shadow);
                real4 diff = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord.xy) * lambert * _BaseColor * real4(mylight.color, 1);
                float spe = saturate(dot(normalize(WS_L + WS_V), norWS));//计算高光
                spe = pow(spe, _SpecularRange) * _SpecularColor;

                return(spe + diff) * shadow;
            }
            ENDHLSL
            
        }


        pass
        {
            Tags { "LightMode" = "ShadowCaster" }
            HLSLPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            
            v2f vert(a2v v)
            {
                v2f o;
                ZERO_INITIALIZE(v2f, o);
                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
                return o;
            }

            float4 frag(v2f i): SV_Target
            {
                float4 color;
                color.xyz = float3(0.0, 0.0, 0.0);
                return color;
            }
            ENDHLSL
            
        }
    }
}