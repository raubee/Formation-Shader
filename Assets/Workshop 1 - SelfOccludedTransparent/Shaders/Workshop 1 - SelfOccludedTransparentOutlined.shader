Shader "Workshop 1/SelfOccludedTransparentOutlined"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Tint("Tint", Color) = (1,1,1,1)
        _OutlineWidth("Outline Width", Range(0, 0.1)) = 0.01
        _OutlineColor("Outline Color", Color) = (1,1,1,1)
    }

    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        LOD 100

        Usepass "Workshop 1/SelfOccludedTransparent/DEPTH-PREPASS"

        Pass
        {
            Name "OUTLINE"

            Cull Front
            Blend SrcAlpha OneMinusSrcAlpha
            Zwrite Off
            Ztest Less

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct v2f 
            {
                float4 pos : SV_POSITION;
                fixed4 color : COLOR;
            };

            float _OutlineWidth;
            fixed4 _OutlineColor;

            v2f vert(appdata_base v)
            {
                v2f o;
                v.vertex.xyz += v.normal * _OutlineWidth;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.color = _OutlineColor;
                return o;
            }

            fixed4 frag(v2f i) : COLOR
            {
               return i.color;
            }

            ENDCG
        }

        Usepass "Workshop 1/NoneOccludedTransparent/UNLIT"
    }
}
