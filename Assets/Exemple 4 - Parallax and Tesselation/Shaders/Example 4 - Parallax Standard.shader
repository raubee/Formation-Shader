Shader "Exemple 4/Parallax Standard"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
        _HeightTex ("Height", 2D) = "black" {}
        _HeightScale ("Height Scale", Range(0,0.08)) = 0.08
        _BumpMapTex("Bump map", 2D) = "black" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        
        LOD 200
        Offset -1, -1

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard fullforwardshadows

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        sampler2D _MainTex;
        sampler2D _HeightTex;
        sampler2D _BumpMapTex;

        struct Input
        {
            float2 uv_MainTex;
            float3 viewDir;
            float3 worldNormal;
        };

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;
        half _HeightScale;

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            float h = tex2D (_HeightTex, IN.uv_MainTex).r;
            IN.uv_MainTex += ParallaxOffset(h, _HeightScale, IN.viewDir);

            // Albedo comes from a texture tinted by color
            //fixed4 c = lerp(tex2D (_MainTex, IN.uv_MainTex) * _Color, fixed4(0,0,0,0), h)*/ ;
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex);
            o.Albedo = c.rgb;
            o.Normal = UnpackNormal(tex2D(_BumpMapTex, IN.uv_MainTex));
            // Metallic and smoothness come from slider variables
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
