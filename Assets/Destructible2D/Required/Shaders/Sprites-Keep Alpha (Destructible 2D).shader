Shader "Sprites/Keep Alpha (Destructible 2D)"
{
	Properties
	{
		_MainTex ("Sprite Texture", 2D) = "white" {}
		_AlphaTex ("Alpha Tex", 2D) = "white" {}
		_AlphaScale ("Alpha Scale", Vector) = (1,1,0,0)
		_AlphaOffset ("Alpha Offset", Vector) = (0,0,0,0)
		_Sharpness ("Sharpness", Float) = 1.0
		_Color ("Tint", Color) = (1,1,1,1)
		[MaterialToggle] PixelSnap ("Pixel snap", Float) = 0
	}

	SubShader
	{
		Tags
		{ 
			"Queue"="Transparent" 
			"IgnoreProjector"="True" 
			"RenderType"="Transparent" 
			"PreviewType"="Plane"
			"CanUseSpriteAtlas"="True"
		}

		Cull Off
		Lighting Off
		ZWrite Off
		Fog { Mode Off }
		Blend One OneMinusSrcAlpha

		Pass
		{
			CGPROGRAM
				#pragma vertex Vert
				#pragma fragment Frag
				#pragma multi_compile DUMMY PIXELSNAP_ON
				
				#include "UnityCG.cginc"
				
				sampler2D _MainTex;
				sampler2D _AlphaTex;
				float     _Sharpness;
				float4    _Color;
				float2    _AlphaScale;
				float2    _AlphaOffset;
				
				struct a2v
				{
					float4 vertex    : POSITION;
					float4 color     : COLOR;
					float2 texcoord0 : TEXCOORD0;
				};
				
				struct v2f
				{
					float4 vertex    : SV_POSITION;
					float4 color     : COLOR;
					float2 texcoord0 : TEXCOORD0;
					float2 texcoord1 : TEXCOORD1;
				};
				
				void Vert(a2v i, out v2f o)
				{
					o.vertex    = mul(UNITY_MATRIX_MVP, i.vertex);
					o.color     = i.color * _Color;
					o.texcoord0 = i.texcoord0;
					o.texcoord1 = (i.texcoord0 - _AlphaOffset) * _AlphaScale;
#if PIXELSNAP_ON
					o.vertex = UnityPixelSnap(o.vertex);
#endif
				}
				
				void Frag(v2f i, out float4 o:COLOR0)
				{
					float4 mainTex  = tex2D(_MainTex, i.texcoord0);
					float4 alphaTex = tex2D(_AlphaTex, i.texcoord1);
					
					// Clip the alpha if it's outside the range
					float2 clipUV = abs(i.texcoord1 - 0.5f);
					
					alphaTex.a *= max(clipUV.x, clipUV.y) <= 0.5f;
					
					// Multiply the color
					o.rgba = mainTex * i.color;
					
					// Apply alpha tex
					o.a *= saturate(0.5f + (alphaTex.a - 0.5f) * _Sharpness);
					
					// Premultiply alpha
					o.rgb *= o.a;
				}
			ENDCG
		}
	}
}
