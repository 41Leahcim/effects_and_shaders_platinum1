Shader "Unlit/UnlitShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _MinimumScale ("Minimum Scale", Vector) = (0.0, 0.0, 0.0)
        _MaximumScale ("Maximum Scale", Vector) = (1.0, 1.0, 1.0)
        _MinimumScalePosition ("Minimum Scale Position", Vector) = (0.0, 0.0, 0.0)
        _MaximumScalePosition ("Maximum Scale Position", Vector) = (0.0, 0.0, 0.0)
        _ScaleSpeed ("Scale Speed", float) = 1.0
        _TwirlStrength ("Twirl Strength", float) = 1.0
        _RotateSpeed ("Rotate Speed", float) = 1.0
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
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float4 _MinimumScale;
            float4 _MaximumScale;
            float4 _MinimumScalePosition;
            float4 _MaximumScalePosition;
            float  _ScaleSpeed;
            float  _TwirlStrength;
            float _RotateSpeed;

            v2f vert (appdata v)
            {
                // Select a point between minimum and maximum scale.
                // By multiplying the time with the scale speed.
                // Taking the sine of the result, and making it >= 0
                const float selection = abs(sin(_Time.x * _ScaleSpeed));

                // Get the selected scale and corresponding position
                const float4 scale = lerp(_MinimumScale, _MaximumScale, selection);
                const float4 position = lerp(_MinimumScalePosition, _MaximumScalePosition, selection);

                // Calculate the position of this vertex by multiplying the vertex with the scale
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex * scale + position);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                // Enable fog
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            float2 twirl(const float2 textureCoordinates, const float2 twirlCenter, const float rotation)
            {
                // subtract the center from the actual position of the  fragment
                const float2 offset = textureCoordinates - twirlCenter;

                // Calculate the angle on this fragment
                const float2 angle = _TwirlStrength * length(offset) + rotation;

                // Calculate the pixel offset for this fragment
                const float2 newOffset = (
                    offset.x * cos(angle) - offset.y * sin(angle),
                    offset.y * sin(angle) + offset.x * cos(angle)
                );

                // Calculate the pixel position for this fragment
                return twirlCenter + newOffset;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // Get the required texture coordinates for a twirl effect
                const float2 newUV = twirl(i.uv, (0.5, 0.5), _Time.x * _RotateSpeed);

                // Sample the texture at the calculated position
                const fixed4 col = tex2D(_MainTex, newUV);

                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
