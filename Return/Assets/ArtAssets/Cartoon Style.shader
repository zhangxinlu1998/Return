Shader "URP/Cartoon Style"
{

    Properties
    {
        _MainTex ("MainTex", 2D) = "white" { }
        _Color ("BaseColor", Color) = (1, 1, 1, 1)
        //[IntRange]_step ("Color Step", Range(1, 10)) = 5

        [Header(Normal)]
        [Normal]_NormalTex ("Normal", 2D) = "bump" { }
        _NormalScale ("NormalScale", Range(0, 1)) = 1

        [Header(Specular)]
        [Toggle]_Spe ("If Sep", Int) = 0
        [IntRange]_SpecularRange ("SpecularRange", Range(1, 200)) = 50
        [HDR]_SpecularColor ("SpecularColor", Color) = (1, 1, 1, 1)
        [IntRange]_Step ("Spe Step", Range(1, 10)) = 4

        [Header(Shadow)]
        _Shadow ("Shadow Strength", Range(0, 1)) = 0.5
        _ShadowColor ("Shadow Color", Color) = (0, 0, 0, 0)
        _ShadowSmoothness ("Shadow Smoothness", Range(0.01, 2)) = 0.5
        _ShadowOffset ("ShadowOffset", Range(-1, 1)) = 0
        _lineRange ("lineRange", Range(0.01, 1)) = 0.05
        _lineSmoothness("line Smoothness",Range(0.01,1)) = 0.01
        _lineAlpha ("lineAlpha", Range(0, 1)) = 1
        _lineColor ("lineColor", Color) = (1, 1, 1, 1)
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "IgnoreProjector" = "True" "RenderPipeline" = "UniversalRenderPipeline"  }

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
        #pragma multi_compile _ _SHADOWS_SOFT


        CBUFFER_START(PerMaterials)
        float4 _NormalTex_ST;
        float4 _MainTex_ST;
        real4 _Color;
        real _NormalScale;
        real _SpecularRange, _Shadow, _ShadowSmoothness;
        real4 _SpecularColor;
        real4 _ShadowColor;
        real4 _lineColor;
        real _ShadowOffset, _lineRange, _lineAlpha;
        half _Step, _Spe,_lineSmoothness;
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
                half shadow = saturate(mainLight.shadowAttenuation + _Shadow) ;
                

                Light mylight = GetMainLight();
                float3 WS_L = normalize(mylight.direction);
                float3 WS_N = normalize(i.normalWS.xyz);
                float3 WS_V = normalize(_WorldSpaceCameraPos - WSpos);
                float3 WS_H = normalize(WS_V + WS_L);
                float lambert = dot(norWS, WS_L);//计算兰伯特
                lambert = saturate(saturate(lambert / _ShadowSmoothness) + _Shadow);
                half3 lambertcol = (1 - lambert) * _ShadowColor.rgb;
                real4 diff = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord.xy) * _Color * real4(mylight.color, 1) * (half4(lambertcol * (1 - lambert.r), 1) + lambert);
                float spe = saturate(dot(normalize(WS_L + WS_V), norWS));//计算高光
                float4 finalspe = pow(spe, _SpecularRange) * _SpecularColor * _Spe;
                finalspe = floor(finalspe * _Step) / _Step;
                half4 finalcol = (finalspe + diff) * shadow;

                //line
                //half l = saturate(2*dot(WS_L,WS_N))-_ShadowOffset;
                half lineone = smoothstep(0,_lineSmoothness, saturate(2 * dot(WS_L, WS_N) - _ShadowOffset));
                half linetwo = smoothstep(0,_lineSmoothness, saturate(2 * dot(WS_L, WS_N) - _ShadowOffset +_lineRange));
                half L = (1 - lineone) * linetwo;
                half4 linecol = half4(_lineColor.rgb * L, L);

                //卡通色阶效果
                //finalcol = floor(finalcol * _step) / _step;

                return linecol * _lineAlpha + finalcol * (1 - L*_lineAlpha);
                //return L;
            }
            ENDHLSL
            
        }


        // pass
        // {
        //     Tags { "LightMode" = "ShadowCaster" }
        //     HLSLPROGRAM
            
        //     #pragma vertex vert
        //     #pragma fragment frag
        //     #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            
            

        //     v2f vert(a2v v)
        //     {
        //         v2f o;
        //         ZERO_INITIALIZE(v2f, o);
        //         o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
        //         return o;
        //     }

        //     float4 frag(v2f i): SV_Target
        //     {
        //         float4 color;
        //         color.xyz = float3(0, 0, 0);
        //         return color;
        //     }
        //     ENDHLSL
            
        // }

        Pass
        {
            Name "ShadowCaster"
            Tags{"LightMode" = "ShadowCaster"}

            ZWrite On
            ZTest LEqual
            Cull[_Cull]

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature _ALPHATEST_ON
            #pragma shader_feature _GLOSSINESS_FROM_BASE_ALPHA

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            #include "Packages/com.unity.render-pipelines.universal/Shaders/SimpleLitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"
            ENDHLSL
        }

        Pass
        {
            Tags{"LightMode" = "DepthOnly"}

            ZWrite On
            ColorMask 0

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            // -------------------------------------
            // Material Keywords
            //#pragma shader_feature _ALPHATEST_ON

            //--------------------------------------
            // GPU Instancing
            //#pragma multi_compile_instancing

            #include "Packages/com.unity.render-pipelines.universal/Shaders/UnlitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"
            ENDHLSL
        }
    }
}