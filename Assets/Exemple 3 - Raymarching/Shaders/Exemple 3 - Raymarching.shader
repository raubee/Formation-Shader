Shader "Exemple 3/Raymarching"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        [Toggle]_Debug("Debug", Float) = 0
        _Specular("Specular", Range(1,48)) = 0
        [HideInInspector]_WorldPos("World Pos", Vector) = (0,0,0)
    }
    SubShader
    {
        GrabPass{
          "_BackgroundColor"      
        }
        
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf NoLighting fullforwardshadows alpha:auto

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        half4 LightingNoLighting (SurfaceOutput s, half3 lightDir, half3 viewDir, half atten) 
        {
            return half4(0,0,0,s.Alpha);
            //return half4(s.Albedo * 0.5f, s.Alpha);
        }

        sampler2D _MainTex;

        struct Input
        {
            float2 uv_MainTex;
            float3 viewDir;
            float3 worldPos;
            float3 objectPos;
            float4 grabPos : TEXCOORD0;
        };

        sampler2D _BackgroundTexture;

        float _Debug;
        float _Specular;
        float3 _WorldPos;

        #define MAXIMUM_RAY_STEPS 255
        #define EPSILON 0.0001

        /**** Distance field functions ****/
        /*** http://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm ***/
        /**** Sphere SDF ****/
        float sdfSphere(float3 p, float s)
        {
            return length(p)-s;
        }

        /**** RoundBox SDF ****/
        float udRoundBox(float3 p, float3 b, float r)
        {
            return length(max(abs(p)-b,0.0))-r;
        }

        /**** Smooth Interpolation ****/
        /*** http://iquilezles.org/www/articles/smin/smin.htm ***/
        float smin( float a, float b, float k )
        {
            float res = exp( -k*a ) + exp( -k*b );
            return -log( res )/k;
        }
        /**** Scene SDF ****/
        float sdfScene(float3 p)
        {
            p -= _WorldPos;

            float d = sdfSphere(p,.50*((sin(_Time * 30)/2.0)+1.0) );
            float r = udRoundBox(p, float3(.40,.40,.40), 0.02);
            return smin(r, d, 10.0);
        }

        /**** Gradient estimated normal ****/ 
        /*** https://en.wikipedia.org/wiki/Gradient ***/
        float3 gradientNormal(float3 p) 
        {
            return normalize(float3(
                sdfScene( float3( p.x + EPSILON, p.y, p.z )) - sdfScene( float3( p.x - EPSILON, p.y, p.z )),
                sdfScene( float3( p.x, p.y + EPSILON, p.z )) - sdfScene( float3( p.x, p.y - EPSILON, p.z )),
                sdfScene( float3( p.x, p.y, p.z + EPSILON )) - sdfScene( float3( p.x, p.y, p.z - EPSILON ))
            ));
        }

        /**** Raymarching ****/
        float rayMarch(float3 cam, float3 dir, float minDist, float maxDist)
        {
            // Create array of 2 float that store [0] -> current distance value, [1] ->  last distance value
            float2 dist = float2(minDist,minDist);
            
            for(int i = 0; i < MAXIMUM_RAY_STEPS; i++)
            { 
                // Get last dist point on the direction array
                float3 p = cam + dir * dist.y;

                // Determine minimal distance from all objects in the scene
                dist.x = sdfScene(p);
                
                // Are we touching an object ?
                if(dist.x < EPSILON)
                {
                // Yes so return last depth
                return dist.y;
                }
                
                dist.y += dist.x;
                
                // Is there any object in the scene ?
                if(dist.y >= maxDist)
                {
                    return maxDist;
                }
            }
            
            // All steps have been finished without object collision
            // Then return max distance
            return maxDist;
        }

        /**** Determines Classic Phong lighting calculation ****/ 
        /**** https://en.wikipedia.org/wiki/Phong_reflection_model ****/
        float3 phongIllumination(float3 p, float3 viewDir)
        {
            /*** Ambient Light ***/
            float3 c_a = unity_AmbientSky; // Ambient intensity color ; c_a = i_a * k_a
            
            /*** One non-directionnal light ***/
            float3 p_1stLight = _WorldSpaceLightPos0 + _WorldPos; // 1st light position
            float3 i_1stLight = _LightColor0; // 1st light intensity
            float3 k_d; // Diffuse reflection constant
            float3 k_s = float3(1.0, 1.0, 1.0); // Specular reflection constant
            
            /*** Angular calculations ***/
            float3 N = gradientNormal(p); // Calculate gradient normal
            float3 l = p_1stLight - p; // Light direction
            float3 L = normalize(l); // Normalized light direction
            float3 V = normalize(-viewDir); // Vector p to cam
            float3 R = normalize(reflect(-L, N));
            
            // Diffuse normal
            k_d = N * 0.5 + 0.5;
            
            /*** Diffuse ***/
            float LN = max(0, dot(N, L));
            
            /*** Specular ***/
            float kSpec = _Specular;
            float RV = max(0, dot(R, V));
            float sp = pow(RV, kSpec);
            
            /*** Attenuation ***/
            float dl = length(l);
            float c_1 = 0.1;
            float c_2 = 0.0005;
            float c_3 = 0.000007;
            
            float fatt = min(1.0 / (c_1 + c_2*dl + c_3*dl*dl), 1.0);
            
            return c_a + fatt * (i_1stLight * LN * k_d + k_s * sp );
        }

        void surf (Input IN, inout SurfaceOutput o)
        {
            half4 bgcolor = tex2Dproj(_BackgroundTexture, IN.grabPos);
            bgcolor.a = 0;
            float4 c = float4(1.0,1.0,1.0, 1.0);
            
            float3 viewDirection = normalize(IN.worldPos  - _WorldSpaceCameraPos);

            /*** Raymarching ***/
            float hitDist = rayMarch(_WorldSpaceCameraPos, viewDirection, _ProjectionParams.y, 100);

            /*** Didn't hit anything ***/
            if ( hitDist > 100 - EPSILON ) {
                c = bgcolor;
            } 
            else
            {
                float3 p = _WorldSpaceCameraPos + viewDirection * hitDist;
                
                c = float4(phongIllumination(p, viewDirection), 1.0);
            }  
            
            if(_Debug)
            {
                o.Albedo = c.rgb;
                o.Emission = c.rgb;
                o.Alpha = 1.0;          
            }
            else
            {
               o.Albedo = 0;
                o.Emission = c.rgb;
                o.Alpha = c.a; 
            }
        }

        ENDCG
    }

    FallBack "Diffuse"
}
