Shader "Exemple 5/Wireframe"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma geometry geom

            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            // Vertex shader Input
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            // Vertex shader Output
            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            // Geometry shader Ouput - Fragment shader Input
            struct g2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                //float dist : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }
            
            #define COUNT 3 
            [maxvertexcount(COUNT)]
            void geom(triangle v2f input[COUNT], inout TriangleStream<g2f> st)
            {
                // Inputs
                v2f v1 = input[0];
                v2f v2 = input[1];
                v2f v3 = input[2];

                // Outputs
                g2f o1;
                g2f o2;
                g2f o3;

                // First vertex 
                o1.vertex = v1.vertex;
                o1.uv = v1.uv;

                // Second vertex
                o2.vertex = v2.vertex;
                o2.uv = v2.uv;

                // Third vertex
                o3.vertex = v3.vertex;
                o3.uv = v3.uv;

                // Compile distance
                

                // Append output in stream
                st.Append(o1);
                st.Append(o2);
                st.Append(o3);
            }

            fixed4 frag (g2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }

            ENDCG
 
        }
    }
}
