Shader "Workshop 1/SelfOccludedTransparent"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Tint("Tint", Color) = (0,0,0,0)
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        LOD 100

        Pass
        {
            Name "DEPTH-PREPASS"

            Zwrite On
            ColorMask 0
        }

        Usepass "Workshop 1/NoneOccludedTransparent/UNLIT"
    }
}
