Shader "Exemple 1/Screen Space" 
{
    Properties 
    {
      _MainTex ("Texture", 2D) = "white" {}
    }

    SubShader 
    {
      Tags { "RenderType" = "Opaque" }

      CGPROGRAM

      #pragma surface surf Lambert

      struct Input 
      {
          float2 uv_MainTex;
          float4 screenPos;
      };

      sampler2D _MainTex;
      float4 _MainTex_ST;
      sampler2D _Detail;

      void surf (Input IN, inout SurfaceOutput o) 
      {
          float2 screenUV = IN.screenPos.xy / IN.screenPos.w;
          screenUV *= float2(_MainTex_ST.x,_MainTex_ST.y);
          o.Albedo = tex2D (_MainTex, screenUV).rgb;
      }

      ENDCG

    } 

    Fallback "Diffuse"
  }