Shader "Exemple 4/Tessellation"
{
    Properties
    {
        _Tess ("Tessellation", Range(1,32)) = 4
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Color ("Color", Color) = (1,1,1,1)
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
        _Displacement("Displacement", Range(0,2)) = 0
        _DispTex("Displacement Map", 2D) = "black" {}
        _HeightTex ("Height", 2D) = "black" {}
        _HeightScale ("Height Scale", Range(0,0.08)) = 0.08
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200
        Offset -1, -1

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard fullforwardshadows tessellate:tes vertex:vert nolightmap

        // Use shader model 4.6 target
        #pragma target 4.6

        sampler2D _MainTex;
        sampler2D _DispTex;

        struct appdata{
            float4 vertex : POSITION;
            float3 normal : NORMAL;
            float4 tangent : TANGENT;
            float2 texcoord : TEXCOORD0;
        };

        struct Input
        {
            float2 uv_MainTex;
            float3 viewDir;
        };

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;
        sampler2D _HeightTex;
        sampler2D _BumpMapTex;
        half _HeightScale;
        float _Tess;
        
        float4 tes()
        {
            return _Tess;
        }

        float _Displacement;

        void vert(inout appdata v)
        {
            float d = tex2Dlod(_DispTex, float4(v.texcoord.xy,0,0)).r * _Displacement;
            v.vertex.xyz += v.normal * d;
        }

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            float h = tex2D (_HeightTex, IN.uv_MainTex).r;
            IN.uv_MainTex += ParallaxOffset(h, _HeightScale, IN.viewDir);

            // Albedo comes from a texture tinted by color
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
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
