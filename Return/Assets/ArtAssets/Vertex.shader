Shader "Unlit/Vertex"
{
    Properties
    {
        _MainTex ("Line Texture", 2D) = "white" {}
        
        _BaseColor ("BaseColor", Color) = (1, 1, 1, 1)
        _Shadow("Shadow Strength",Range(0,1)) = 0.5
        _Shadowcol("Shadow Color", Color) = (1, 1, 1, 1)

        [Header(Line)]
        [HDR]_LineColor ("LineColor", Color) = (1, 1, 1, 1)
        _LineStrength("Line Strength",Range(0,1)) = 0

        [Header(Movement)]
        _Transform("Transform",Range(0,1)) = 0
        _Gap("Transform Gap",Range(0,100)) = 100
        _MaxOffset("Max Offset",Range(1,30)) = 10
        _DirectionalVector("Directional Vector",Vector) = (1,1,1,1)


        

        
    }
    SubShader
    {
        Tags { "LightMode"="UniversalForward"}
        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag


            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            float easeOutBack(float x) {
                float c1 = 1.70158;
                float c3 = c1 + 1;
                return 1 + c3 * pow(x - 1, 3) + c1 * pow(x - 1, 2);
            }

            float easeBack(float x) {
                float c1 = 1.70158;
                float c2 = c1 * 1.525;
                return x < 0.5
                ? (pow(2 * x, 2) * ((c2 + 1) * 2 * x - c2)) / 2
                : (pow(2 * x - 2, 2) * ((c2 + 1) * (x * 2 - 2) + c2) + 2) / 2;
            }

            float Remap(float In, float2 InMinMax, float2 OutMinMax)
            {
                return OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
            }

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 color:COLOR;
                float3 normal:NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                float3 normal:NORMAL;
                float3 worldPos  : TEXCOORD1;
                float3 offset  : TEXCOORD2;
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST,_LineColor,_BaseColor,_DirectionalVector,_Shadowcol;
            real _Transform,_MaxOffset,_Gap,_Shadow,_LineStrength;
            CBUFFER_END


            v2f vert (appdata v)
            {
                v2f o;
                _Transform = Remap(_Transform,float2(0,1),float2(-0.6,1.2));
                float3 offset = ((v.color.r*100*_Gap-_Transform)) *_MaxOffset*_DirectionalVector.xyz;
                v.vertex.y =v.vertex.y+v.vertex.y*offset.y/100*easeOutBack(saturate(v.color.r-_Transform+0.1));
                o.offset = offset*easeBack(saturate(v.color.r-_Transform-0.02));
                v.vertex.xyz =v.vertex.xyz+ o.offset;
                o.offset = offset*easeBack(saturate(v.color.r-_Transform+0.5))*0.002;
                float3 worldPos = TransformObjectToWorld(v.vertex.xyz);
                //v.vertex.z *= saturate(1/abs(worldPos.y));
                
                o.pos = TransformObjectToHClip(v.vertex.xyz);
                o.worldPos = TransformObjectToWorld(v.vertex.xyz);
                o.normal = TransformObjectToWorldNormal(v.normal);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                
                
                float3 N = normalize(i.normal);
                Light mylight = GetMainLight();
                float3 LightDir = normalize(mylight.direction);
                float LightAtten = saturate(dot(LightDir, N)+_Shadow);
                half linerange = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv).r;

                half lineappear = linerange*saturate(i.offset.g);
                half4 tex = (1-lineappear)*_BaseColor+lineappear* _LineColor*saturate(i.offset.g)+linerange*_LineColor*_LineStrength;
                return float4(tex.rgb*LightAtten+_Shadowcol*(1-LightAtten),(1-saturate(i.offset.g))+lineappear);
            }
            ENDHLSL
        }
    }
}
