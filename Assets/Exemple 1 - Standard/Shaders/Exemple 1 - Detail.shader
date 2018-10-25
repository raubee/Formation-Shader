Shader "Exemple 1/Detail" 
{
    Properties 
    {
      _MainTex ("Texture", 2D) = "white" {}
      _Detail ("Detail", 2D) = "gray" {}
    }

    SubShader 
    {

      Tags { "RenderType" = "Opaque" }

      CGPROGRAM

      #pragma surface surf Lambert

      struct Input 
      {
          float2 uv_MainTex;
          float2 uv_Detail;
      };

      sampler2D _MainTex;
      sampler2D _Detail;

      void surf (Input IN, inout SurfaceOutput o) 
      {
          o.Albedo = tex2D (_MainTex, IN.uv_MainTex).rgb;
          o.Albedo *= tex2D (_Detail, IN.uv_Detail).rgb * 2;
      }

      ENDCG

    } 

    Fallback "Diffuse"
  }