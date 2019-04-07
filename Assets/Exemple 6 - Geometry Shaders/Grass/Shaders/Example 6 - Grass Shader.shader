Shader "Exemple 6/Grass"
{
    Properties
    {
        _TopColor("Top Color", Color) = (0, 0.6, 0, 0)
        _BottomColor("Bottom Color", Color) = (0, 0.4, 0, 0)
        _BendRotationRandom("Bend Rotation Random", Range(0, 1)) = 0.2
        _BladeWidth("Blade Width", Range(0, 0.2)) = 0.05
        [HideInInspector]_BladeWidthRandom("Blade Width Random", Float) = 0.02
        _BladeHeight("Blade Height", Range(0,2)) = 0.5
        [HideInInspector]_BladeHeightRandom("Blade Height Random", Float) = 0.3
        _TessellationUniform("Tessellation Uniform", Range(1, 64)) = 1
        _WindDistortionMap("Wind Distortion Map", 2D) = "white" {}
        _WindFrequency("Wind Frequency", Vector) = (0.05, 0.05, 0, 0)
        _WindStrength("Wind Strength", Range(0,2)) = 1
        _TranslucentGain("Translucent Gain", Range(0,1)) = 0
    }

    SubShader
    {
        LOD 100
        Cull Off

		Offset -1, 0

        Pass
        {
            Tags
            {
                "LightMode" = "ForwardBase"
            }

            CGPROGRAM

            #pragma target 4.6

            #pragma multi_compile_fwdbase
            #pragma vertex tesselationVertex
            #pragma fragment fragmentGrass
			#pragma geometry geo
            #pragma hull hull
            #pragma domain domain

            #define SHADOWS_SCREEN

            #include "Grass.cginc"

            ENDCG
        }

         /*Pass
        {
            Tags
            {
                "LightMode" = "ForwardAdd"
            }
            CGPROGRAM
            
            #pragma target 4.6

            #pragma multi_compile_fwdadd
            #pragma vertex tesselationVertex
            #pragma fragment fragmentGrass
			#pragma geometry geo
            #pragma hull hull
            #pragma domain domain

            #include "UnityCG.cginc"
            #include "Grass.cginc"

            ENDCG
        }*/

        Pass
        {
            Tags
            {
                "LightMode" = "ShadowCaster"
            }

            CGPROGRAM
            #pragma vertex tesselationVertex
            #pragma geometry geo
            #pragma fragment frag
            #pragma hull hull
            #pragma domain domain
            #pragma target 4.6
            #pragma multi_compile_shadowcaster
            
            #include "Grass.cginc"

            float4 frag(geometryOutput i) : SV_Target
            {
                SHADOW_CASTER_FRAGMENT(i);
            }

            ENDCG
        }
    }
}
