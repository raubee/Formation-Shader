Shader "Exemple 1/Sliced" 
{
    Properties 
    {
      _MainTex ("Texture", 2D) = "white" {}
      _Color ("Color", Color) = (1,1,1,1)
      _SlicedAmount("Sliced Amount", Range(0,10)) = 0.1
    }

    SubShader 
    {
      Tags { "RenderType" = "Opaque" }

      Cull Off

      CGPROGRAM

      #pragma surface surf Lambert
      
      struct Input 
      {
          float2 uv_MainTex;
          float3 worldPos;
      };

      sampler2D _MainTex;
      sampler2D _BumpMap;
      fixed4 _Color;

      float _SlicedAmount;

      void surf (Input IN, inout SurfaceOutput o) 
      {
          clip (frac((IN.worldPos.y+IN.worldPos.y*0.1) * _SlicedAmount) - 0.5);
          o.Albedo = tex2D (_MainTex, IN.uv_MainTex).rgb * _Color.rgb;
      }

      ENDCG
    } 

    Fallback "Diffuse"
  }