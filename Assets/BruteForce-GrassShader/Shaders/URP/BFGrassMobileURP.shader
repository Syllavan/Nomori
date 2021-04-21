// MADE BY MATTHIEU HOULLIER
// Copyright 2021 BRUTE FORCE, all rights reserved.
// You are authorized to use this work if you have purchased the asset.
// Mail me at bruteforcegamesstudio@gmail.com if you have any questions or improvements you want.
Shader "BruteForceURP/InteractiveGrassMobileURP"
{
	Properties
	{
		[Header(Tint Colors)]
		[Space]
		[MainColor]_Color("ColorTint",Color) = (0.5 ,0.5 ,0.5,1.0)
		_GroundColor("GroundColorTint",Color) = (0.7 ,0.68 ,0.68,1.0)
		_SelfShadowColor("ShadowColor",Color) = (0.41 ,0.41 ,0.36,1.0)
		_ProjectedShadowColor("ProjectedShadowColor",Color) = (0.45 ,0.42 ,0.04,1.0)
		_GrassShading("GrassShading", Range(0.0, 1)) = 0.197
		_GrassSaturation("GrassSaturation", Float) = 2

		[Header(Textures)]
		[Space]
		[MainTexture]_MainTex("Color Grass", 2D) = "white" {}
		[NoScaleOffset]_GroundTex("Ground Texture", 2D) = "white" {}
		[NoScaleOffset]_NoGrassTex("NoGrassTexture", 2D) = "white" {}
		[NoScaleOffset]_GrassTex("Grass Pattern", 2D) = "white" {}
		[NoScaleOffset]_Noise("NoiseColor", 2D) = "white" {}
		[NoScaleOffset]_Distortion("DistortionWind", 2D) = "white" {}

		[Header(Grass Values)]
		[Space]
		_GrassThinness("GrassThinness", Range(0.01, 2.5)) = 0.66
		_GrassThinnessIntersection("GrassThinnessIntersection", Range(0.01, 2)) = 0.13
		_TilingN1("TilingOfGrass", Float) = 6.06
		_WindMovement("WindMovementSpeed", Float) = 0.55
		_WindForce("WindForce", Float) = 0.25
		_TilingN3("WindNoiseTiling", Float) = 1
		_TilingN2("TilingOfNoise", Float) = 0.05
		_NoisePower("NoisePower", Float) = 1
		_FadeDistanceStart("FadeDistanceStart", Float) = 2
		_FadeDistanceEnd("FadeDistanceEnd", Float) = 20
		[Toggle(USE_RT)] _UseRT("Use RenderTexture Effect", Float) = 1
		[Toggle(USE_S)] _UseShadow("Use Shadows", Float) = 1
		[Toggle(USE_SC)] _UseShadowCast("Use Shadow Casting", Float) = 0 }
		SubShader
		{ 
			pass
			{
			Tags{"DisableBatching" = "true" "RenderPipeline" = "UniversalPipeline" }
			LOD 100
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fog
			#pragma multi_compile_instancing
			#pragma prefer_hlslcc gles
			#pragma shader_feature USE_RT
			#pragma shader_feature USE_SC
			#pragma shader_feature USE_S

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
			#pragma multi_compile _ _SHADOWS_SOFT
			#pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE
			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				half1 color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct v2f
			{
				float3 worldPos : TEXCOORD3;
				float2 uv : TEXCOORD0;
				float4 pos : SV_POSITION;
				float fogCoord : TEXCOORD1;
				half1 color : TEXCOORD2;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};
			// Render Texture Effects //
			uniform sampler2D _GlobalEffectRT;
			uniform float3 _Position;
			uniform float _OrthographicCamSize;
			uniform float _HasRT;

			sampler2D _MainTex;
			sampler2D _NoGrassTex;
			float4 _MainTex_ST;
			sampler2D _Distortion;
			sampler2D _GrassTex;
			sampler2D _Noise;
			sampler2D _GroundTex;
			float _TilingN1;
			float _TilingN2, _WindForce;
			float4 _Color, _SelfShadowColor, _GroundColor, _ProjectedShadowColor;
			float _TilingN3;
			float _WindMovement, _OffsetValue;
			half _GrassThinness, _GrassShading, _GrassThinnessIntersection;
			half _NoisePower, _GrassSaturation, _FadeDistanceStart, _FadeDistanceEnd;

#define UnityObjectToWorld(o) mul(unity_ObjectToWorld, float4(o.xyz,1.0))
			v2f vert(appdata v)
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				VertexPositionInputs vertexInput = GetVertexPositionInputs(v.vertex.xyz);

				o.pos = GetVertexPositionInputs(v.vertex).positionCS;
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.color = v.color;
				o.worldPos = UnityObjectToWorld(v.vertex);
				o.fogCoord = ComputeFogFactor(vertexInput.positionCS.z);
				return o;
			}
			half4 frag(v2f i) : SV_Target
			{
				half FadeStacks = 1;
				float dist = distance(_WorldSpaceCameraPos, i.worldPos);
				if (dist > 0)
				{
					FadeStacks = lerp(1, 0, (dist - _FadeDistanceStart)*(1 / max(_FadeDistanceEnd - _FadeDistanceStart, 0.0001)));//Clamp because people will start dividing by 0
				}
				float2 uv = i.worldPos.xz - _Position.xz;
				uv = uv / (_OrthographicCamSize * 2);
				uv += 0.5;

				float bRipple = 1;
#ifdef USE_RT
				if (_HasRT)
				{
					bRipple = 1 - clamp(tex2D(_GlobalEffectRT, uv).b * 5, 0, 2);
				}
#endif
				float2 dis = tex2D(_Distortion, i.uv  *_TilingN3 + _Time.xx * 3 * _WindMovement);
				float displacementStrengh = 0.6* (((sin(_Time.y + dis * 5) + sin(_Time.y*0.5 + 1.051)) / 5.0) + 0.15*dis)*bRipple; //hmm math
				dis = dis * displacementStrengh*(i.color.r*1.3)*_WindForce*bRipple;

				float ripples = 0.25;
				float ripples2 = 0;
				float ripples3 = 0;
				float ripplesG = 0;
#ifdef USE_RT
				if (_HasRT)
				{
					// .b(lue) = Grass height / .r(ed) = Grass shadow / .g(reen) is unassigned you can put anything you want if you need a new effect
					ripples = (0.25 - tex2D(_GlobalEffectRT, uv + dis.xy*0.04).b);
					ripples2 = (tex2D(_GlobalEffectRT, uv + dis.xy*0.04).r);
					ripplesG = (0 - tex2D(_GlobalEffectRT, uv + dis.xy*0.04).g);
					ripples3 = (0 - ripples2)*ripples2;
				}
#endif
				half4 col = tex2D(_MainTex, i.uv + dis.xy*0.09);
				half4 colGround = tex2D(_GroundTex, i.uv + dis.xy*0.05);

				float3 noise = tex2D(_Noise, i.uv*_TilingN2 + dis.xy)*_NoisePower;
				float3 grassPattern = tex2D(_GrassTex, i.uv*_TilingN1 + dis.xy);
				half3 NoGrass = tex2D(_NoGrassTex, i.uv + dis.xy*0.05);
				NoGrass.r = saturate(NoGrass.r + ripplesG);

				half alpha = step(1 - ((col.x + grassPattern.x) * _GrassThinness)*((2 - i.color.r)*NoGrass.r*grassPattern.x), (1 - i.color.r)*(NoGrass.r*grassPattern.x)*_GrassThinness - dis.x * 5);
				alpha = lerp(alpha, alpha + (grassPattern.x*NoGrass.r*(1 - i.color.r))*_GrassThinnessIntersection ,1 - NoGrass.r);

				if (i.color.r >= 0.01 && FadeStacks > 0.1)
				{
					clip(alpha*((ripples3 + 1)+ripples- (i.color.r)) -0.02);
				}

				_Color *= 2;
				col.xyz = (pow(col, _GrassSaturation) * _GrassSaturation)*float3(_Color.x, _Color.y, _Color.z);
				col.xyz *= saturate(lerp(_SelfShadowColor, 1, pow(i.color.x, 1.1)) + (_GrassShading  * (ripples * 1 + 1) - noise.x*dis.x * 2) + (1 - NoGrass.r) - noise.x*dis.x * 2);
				col.xyz *= _Color * (ripples*-0.1 + 1);
				col.xyz *= 1 - (ripples2*(1 - saturate(i.color.r - 0.7)));

				if (i.color.r <= 0.01)
				{
					colGround.xyz *= ((1 - NoGrass.r)*_GroundColor*_GroundColor * 2);
					col.xyz = lerp(col.xyz, colGround.xyz, 1 - NoGrass.r);
				}
				Light mainLight = GetMainLight(TransformWorldToShadowCoord(i.worldPos));

#ifdef USE_S
				float shadowmap = mainLight.shadowAttenuation;
				half3 shadowmapColor = lerp(_ProjectedShadowColor, 1, shadowmap);

				col.xyz = col.xyz * saturate(shadowmapColor);
#endif
				col.xyz *= mainLight.color;
				col.xyz = MixFog(col.xyz, i.fogCoord);
				return col;
			}
				ENDHLSL
		}
		
		// SHADOW CASTING PASS, this will redraw geometry so keep this pass disabled if you want to save performance
		// Keep it if you want depth for post process or if you're using deferred rendering
		Pass{
				Tags {"LightMode" = "ShadowCaster" "DisableBatching" = "true" "RenderPipeline" = "UniversalPipeline" }
				//Tags{ "LightMode" = "ForwardBase" "DisableBatching" = "true" }
				//Tag for debugging only
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma shader_feature USE_RT
			#pragma shader_feature USE_SC

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

			float3 _LightDirection;
			float3 _LightPosition;

		struct appdata
		{
			float4 vertex : POSITION;
			float2 uv : TEXCOORD0;
			half1 color : COLOR;
			float4 normal : NORMAL;
		};

		struct v2f
		{
			float3 worldPos : TEXCOORD2;
			float2 uv : TEXCOORD0;
			float4 pos : SV_POSITION;
			half1 color : COLOR;
			float3 normal : TEXCOORD3;
		};

		// Render Texture Effects //
		uniform sampler2D _GlobalEffectRT;
		uniform float3 _Position;
		uniform float _OrthographicCamSize;
		uniform float _HasRT;

		sampler2D _MainTex;
		sampler2D _NoGrassTex;
		float4 _MainTex_ST;
		sampler2D _Distortion;
		sampler2D _GrassTex;
		sampler2D _Noise;
		sampler2D _GroundTex;
		float _TilingN1;
		float _TilingN2, _WindForce;
		float4 _Color, _SelfShadowColor, _GroundColor;
		float _TilingN3;
		float _WindMovement;
		half _GrassThinness, _GrassShading, _GrassThinnessIntersection;
		half _NoisePower, _GrassSaturation, _FadeDistanceStart, _FadeDistanceEnd;

#define UnityObjectToWorld(o) mul(unity_ObjectToWorld, float4(o.xyz,1.0))
		v2f vert(appdata v)
		{
			v2f o;
			//o.pos = UnityObjectToClipPos(v.vertex);
			o.pos = 0;
			o.normal = 0;
#ifdef USE_SC
			o.pos = TransformWorldToHClip(ApplyShadowBias(GetVertexPositionInputs(v.vertex).positionWS, GetVertexNormalInputs(v.normal).normalWS, _LightDirection));
			o.normal = v.normal;
			o.uv = TRANSFORM_TEX(v.uv, _MainTex);
			o.color = v.color;
			o.worldPos = UnityObjectToWorld(v.vertex);
#endif
			return o;
		}

			half4 frag(v2f i) : SV_Target
			{
#ifdef USE_SC
				half FadeStacks = 1;
				float dist = distance(_WorldSpaceCameraPos, i.worldPos);
				if (dist > 0)
				{
					FadeStacks = lerp(1, 0, (dist - _FadeDistanceStart)*(1 / max(_FadeDistanceEnd - _FadeDistanceStart, 0.0001)));//Clamp because people will start dividing by 0
				}
				float2 uv = i.worldPos.xz - _Position.xz;
				uv = uv / (_OrthographicCamSize * 2);
				uv += 0.5;

				float bRipple = 1;
#ifdef USE_RT
				if (_HasRT)
				{
					bRipple = 1 - clamp(tex2D(_GlobalEffectRT, uv).b * 5, 0, 2);
				}
#endif
				float2 dis = tex2D(_Distortion, i.uv  *_TilingN3 + _Time.xx * 3 * _WindMovement);
				float displacementStrengh = 0.6* (((sin(_Time.y + dis * 5) + sin(_Time.y*0.5 + 1.051)) / 5.0) + 0.15*dis)*bRipple; //hmm math
				dis = dis * displacementStrengh*(i.color.r*1.3)*_WindForce*bRipple;

				float ripples = 0.25;
				float ripples2 = 0;
				float ripples3 = 0;
				float ripplesG = 0;
#ifdef USE_RT
				if (_HasRT)
				{
					// .b(lue) = Grass height / .r(ed) = Grass shadow / .g(reen) is unassigned you can put anything you want if you need a new effect
					ripples = (0.25 - tex2D(_GlobalEffectRT, uv + dis.xy*0.04).b);
					ripples2 = (tex2D(_GlobalEffectRT, uv + dis.xy*0.04).r);
					ripplesG = (0 - tex2D(_GlobalEffectRT, uv + dis.xy*0.04).g);
					ripples3 = (0 - ripples2)*ripples2;
				}
#endif
				half4 col = tex2D(_MainTex, i.uv + dis.xy*0.09);
				half4 colGround = tex2D(_GroundTex, i.uv + dis.xy*0.05);

				float3 noise = tex2D(_Noise, i.uv*_TilingN2 + dis.xy)*_NoisePower;
				float3 grassPattern = tex2D(_GrassTex, i.uv*_TilingN1 + dis.xy);
				half3 NoGrass = tex2D(_NoGrassTex, i.uv + dis.xy*0.05);
				NoGrass.r = saturate(NoGrass.r + ripplesG);

				half alpha = step(1 - ((col.x + grassPattern.x) * _GrassThinness)*((2 - i.color.r)*NoGrass.r*grassPattern.x), (1 - i.color.r)*(NoGrass.r*grassPattern.x)*_GrassThinness - dis.x * 5);
				alpha = lerp(alpha, alpha + (grassPattern.x*NoGrass.r*(1 - i.color.r))*_GrassThinnessIntersection, 1 - (NoGrass.r)*(ripples*NoGrass.r + 0.75));

				if (i.color.r >= 0.01 && FadeStacks > 0.1)
				{
					clip(alpha*((ripples3 + 1) + ripples - (i.color.r)) - 0.02);
				}
				//SHADOW_CASTER_FRAGMENT(i)
				return 0;
#endif
				return (0,0,0,0);
			}
				ENDHLSL
		}

		} //Fallback "VertexLit"
}
