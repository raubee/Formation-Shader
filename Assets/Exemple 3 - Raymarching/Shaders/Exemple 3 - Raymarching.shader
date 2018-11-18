Shader "Exemple 3/Raymarching"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        [Toggle]_Debug("Debug", Float) = 0
        _Specular("Specular", Range(0,2)) = 0
        _Metallic("Metallic", Range(0,2)) = 0
        _Round("Round", Range(0,2)) = 0
        _Paste("Paste", Range(0,2)) = 0
        _Diffraction("Diffraction coef", Range(0,2)) = 1.0
        _Shininess("Shininess", Range(2,256)) = 0
        [HideInInspector]_WorldPos("World Pos", Vector) = (0,0,0)
    }
    SubShader
    {
        GrabPass
        {
          "_BackgroundTexture"      
        }
        
        Tags { "RenderType"="Opaque" }
        LOD 200

        ZWrite On

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard alpha:blend  vertex:vert addshadow

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        /*half4 LightingNoLighting (SurfaceOutput s, half3 lightDir, half3 viewDir, half atten) 
        {
            return half4(0,0,0,s.Alpha);
            //return half4(s.Albedo * 0.5f, s.Alpha);
        }*/

        struct Input
        {
            float2 uv_MainTex;
            float3 viewDir;
            float3 worldPos;
            float4 grabUV;
        };

        void vert(inout appdata_full input, out Input o )
        {
            UNITY_INITIALIZE_OUTPUT(Input, o);
            float4 objPos = UnityObjectToClipPos(input.vertex);
            o.grabUV = ComputeGrabScreenPos(objPos);
        }

        sampler2D _MainTex;
        sampler2D _BackgroundTexture;

        float _Debug;
        float _Specular;
        float _Metallic;
        float _Shininess;
        float3 _WorldPos;
        float3 _FirstPos;
        float3 _FirstScale;
        float3 _SecondPos;
        float3 _SecondScale;
        float4 _Color;
        float _Round;
        float _Paste;
        float _Diffraction;

        #define MAXIMUM_RAY_STEPS 255
        #define EPSILON 0.0001

        /**** Distance field functions ****/
        /*** http://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm ***/
        /**** Sphere SDF ****/
        float sdfSphere(float3 p, float s)
        {
            return length(p)-s;
        }

        float sdEllipsoid( float3 p, float3 r )
        {
            float k0 = length(p/r);
            float k1 = length(p/(r*r));
            return k0*(k0-1.0)/k1;
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
        
        float opSmoothUnion( float d1, float d2, float k ) 
        {
            float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
            return lerp( d2, d1, h ) - k*h*(1.0-h); 
        }
        
        float opSmoothSubtraction( float d1, float d2, float k ) 
        {
            float h = clamp( 0.5 - 0.5*(d2+d1)/k, 0.0, 1.0 );
            return lerp( d2, -d1, h ) + k*h*(1.0-h); 
        }

        float opSmoothIntersection( float d1, float d2, float k ) 
        {
            float h = clamp( 0.5 - 0.5*(d2-d1)/k, 0.0, 1.0 );
            return lerp( d2, d1, h ) + k*h*(1.0-h); 
        }
        
        /**** Scene SDF ****/
        float sdfScene(float3 p)
        { 
            p -= _FirstPos; 
            float s1 = sdEllipsoid(p, _FirstScale);
            p += _FirstPos;

            p -= _SecondPos;            
            float s2 = sdEllipsoid(p, _SecondScale);
            p += _SecondPos;

            return opSmoothUnion(s1, s2, _Paste);
            //return sdEllipsoid(p, _ObjectScale / 2.0);
            //return udRoundBox(p, _ObjectScale / 2.0 - _Round, _Round);
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
        float rayMarch(float3 dir)
        {
            float maxDist = 100;
            // Create array of 2 float that store [0] -> current distance value, [1] ->  last distance value
            float2 dist = float2(maxDist, _ProjectionParams.y);
            
            for(int i = 0; i < MAXIMUM_RAY_STEPS; i++)
            { 
                // Get last dist point on the direction array
                float3 p = _WorldSpaceCameraPos + dir * dist.y;

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

            return maxDist;
        }
     
        // /**** Determines Classic Phong lighting calculation ****/ 
        // /**** https://en.wikipedia.org/wiki/Phong_reflection_model ****/
        // float3 phongIllumination(float3 p, float3 viewDir, float4 grabPos)
        // {
        //     /*** Ambient Light ***/
        //     float3 c_a = unity_AmbientSky; // Ambient intensity color ; c_a = i_a * k_a
            
        //     /*** One non-directionnal light ***/
        //     float3 i_1stLight = _LightColor0; // 1st light intensity
        //     float3 k_s = float3(1.0, 1.0, 1.0); // Specular reflection constant
            
        //     /*** Angular calculations ***/
        //     float3 N = gradientNormal(p); // Calculate gradient normal
        //     float3 L = normalize(_WorldSpaceLightPos0); // Normalized light direction
        //     float3 V = normalize(-viewDir); // Vector p to cam
        //     float3 R = normalize(reflect(-L, N));
            
        //     /*** Diffuse ***/
        //     float diff = max(dot(N, L), 0.0);
        //     float3 vec_diff = diff * i_1stLight;
            
        //     /*** Specular ***/
        //     float RV = max(0, dot(R, V));
        //     float sp = pow(RV, _Shininess);
            
        //     float3 ambient = c_a;
        //     float3 spec = sp * _Specular * i_1stLight;

        //     float4 dif_uv = grabPos + float4(N,0) * _Diffraction;
        //     half4 df = tex2Dproj(_BackgroundTexture, dif_uv);

        //     vec_diff = lerp(df.rgb, ambient + vec_diff, _Color.a);
            
        //     return  vec_diff + spec; 
        //     //return df;
        // }

        /**** Render ****/
        void render(float3 dir, float4 grabPos, inout SurfaceOutputStandard o)
        {
            float hitDist = rayMarch(dir);
            float4 c = float4(1.0, 1.0, 1.0, 1.0);

            //half4 bgColor = c;
            half4 bgColor = tex2Dproj(_BackgroundTexture, grabPos);
            
            if(!_Debug)
            {
                bgColor.a = 0;
            }

            /*** Didn't hit anything ***/
            if ( hitDist > 100 - EPSILON ) {
                c = bgColor;
                o.Normal = 1.0;
                o.Alpha = 0;
                o.Metallic = 0;
                o.Smoothness = 0;
                o.Emission = 0;
            } 
            else
            {
                float3 p = _WorldSpaceCameraPos + dir * hitDist;
                //c.rgb = phongIllumination(p, dir, grabPos) * _Color.rgb;
                //c = bgColor;
                //c.a = _Color.a;

                o.Normal = -normalize(gradientNormal(p)); // Calculate gradient normal
                o.Albedo = _Color;
                o.Smoothness = _Specular;
                o.Metallic = _Metallic;
                o.Alpha = _Color.a;
            } 
        }

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            float3 viewDirection = normalize(IN.worldPos  - _WorldSpaceCameraPos);
            
            /*** Raymarching ***/
            render(viewDirection, IN.grabUV, o);
        }

        ENDCG
    }

    FallBack "Diffuse"
}
