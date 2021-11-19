Shader "Workshop 1/SelfOccludedTransparentRimOutlined"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Tint("Tint", Color) = (1,1,1,1)
        _OutlineWidth("Outline Width", Range(0, 0.1)) = 0.01
        _OutlineColor("Outline Color", Color) = (1,1,1,1)
        _RimColor("Rim Color", Color) = (1,1,1,1)
        _RimPower("Rim Power", Range(1,10)) = 1
    }

    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        LOD 100

        Usepass "Workshop 1/SelfOccludedTransparent/DEPTH-PREPASS"

        Pass
        {
            Name "RIM"

            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct v2f 
            {
                float4 pos : SV_POSITION;
                fixed4 color : COLOR;
                float3 wPos : TEXCOORD0;
                float3 normal : TEXCOORD1;
            };

            fixed4 _Tint;
            
            float _OutlineWidth;
            fixed4 _OutlineColor;

            float _RimPower;
            fixed4 _RimColor;

            v2f vert(appdata_base v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.wPos = mul(unity_ObjectToWorld, v.vertex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.color = _RimColor;
                return o;
            }

            fixed4 frag(v2f i) : COLOR
            {
                const float3 v = normalize(_WorldSpaceCameraPos - i.wPos);
                const float r = 1. - pow(dot(v, i.normal), _RimPower);
                fixed4 color = lerp(_Tint, _RimColor, r);
                return color;
            }

            ENDCG
        }

        Usepass "Workshop 1/SelfOccludedTransparentOutlined/OUTLINE"

    }
}
