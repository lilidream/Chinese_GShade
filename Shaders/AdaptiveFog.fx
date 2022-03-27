///////////////////////////////////////////////////////////////////
// Simple depth-based fog powered with bloom to fake light diffusion.
// The bloom is borrowed from SweetFX's bloom by CeeJay.
//
// As Reshade 3 lets you tweak the parameters in-game, the mouse-oriented
// feature of the v2 Adaptive Fog is no longer needed: you can select the
// fog color in the reshade settings GUI instead.
//
///////////////////////////////////////////////////////////////////
// By Otis / Infuse Project
///////////////////////////////////////////////////////////////////
// Lightly optimized by Marot Satil for the GShade project.
// Translation of the UI into Chinese by Lilidream.

uniform float3 FogColor <
	ui_label = "雾的颜色";
	ui_type= "color";
	ui_tooltip = "Color of the fog, in (red , green, blue)";
> = float3(0.9,0.9,0.9);

uniform float MaxFogFactor <
	ui_label = "雾的强度";
	ui_type = "slider";
	ui_min = 0.000; ui_max=1.000;
	ui_tooltip = "1.0将会使远处的物体完全被雾遮挡，较小的值可以让远处物体透过雾若隐若现";
	ui_step = 0.001;
> = 0.8;

uniform float FogCurve <
	ui_label = "雾衰减曲线";
	ui_type = "slider";
	ui_min = 0.00; ui_max=175.00;
	ui_step = 0.01;
	ui_tooltip = "雾的衰减速度曲线。较小的值会使雾随着距离缓慢出现，较大的值会使雾随距离快速增强。";
> = 1.5;

uniform float FogStart <
	ui_label = "雾出现位置";
	ui_type = "slider";
	ui_min = 0.000; ui_max=1.000;
	ui_step = 0.001;
	ui_tooltip = "雾开始出现的位置。0.0为镜头处，1.0为地平线处。在此位置之前不会有雾出现。";
> = 0.050;

uniform float BloomThreshold <
	ui_label = "泛光阈值";
	ui_type = "slider";
	ui_min = 0.00; ui_max=50.00;
	ui_step = 0.1;
	ui_tooltip = "达到此亮度的物体将出现泛光";
> = 10.25;

uniform float BloomPower <
	ui_label = "泛光强度";
	ui_type = "slider";
	ui_min = 0.000; ui_max=100.000;
	ui_step = 0.1;
	ui_tooltip = "泛光的强度";
> = 10.0;

uniform float BloomWidth <
	ui_label = "泛光宽度";
	ui_type = "slider";
	ui_min = 0.0000; ui_max=1.0000;
	ui_tooltip = "泛光的宽度";
> = 0.2;

#include "ReShade.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

//////////////////////////////////////
// textures
//////////////////////////////////////
texture   Otis_BloomTarget < pooled = true; > { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8;};	

//////////////////////////////////////
// samplers
//////////////////////////////////////
sampler2D Otis_BloomSampler { Texture = Otis_BloomTarget; };

// pixel shader which performs bloom, by CeeJay. 
void PS_Otis_AFG_PerformBloom(float4 position : SV_Position, float2 texcoord : TEXCOORD, out float4 fragment: SV_Target0)
{
	float4 color = tex2D(ReShade::BackBuffer, texcoord);
	float3 BlurColor2 = 0;
	float3 Blurtemp = 0;
	const float MaxDistance = 8*BloomWidth;
	float CurDistance = 0;
	const float Samplecount = 25.0;
	const float2 blurtempvalue = texcoord * BUFFER_PIXEL_SIZE * BloomWidth;
	float2 BloomSample = float2(2.5,-2.5);
	float2 BloomSampleValue;
	
	for(BloomSample.x = (2.5); BloomSample.x > -2.0; BloomSample.x = BloomSample.x - 1.0)
	{
		BloomSampleValue.x = BloomSample.x * blurtempvalue.x;
		float2 distancetemp = BloomSample.x * BloomSample.x * BloomWidth;
		
		for(BloomSample.y = (- 2.5); BloomSample.y < 2.0; BloomSample.y = BloomSample.y + 1.0)
		{
			distancetemp.y = BloomSample.y * BloomSample.y;
			CurDistance = (distancetemp.y * BloomWidth) + distancetemp.x;
			BloomSampleValue.y = BloomSample.y * blurtempvalue.y;
			Blurtemp.rgb = tex2D(ReShade::BackBuffer, float2(texcoord + BloomSampleValue)).rgb;
			BlurColor2.rgb += lerp(Blurtemp.rgb,color.rgb, sqrt(CurDistance / MaxDistance));
		}
	}
	BlurColor2.rgb = (BlurColor2.rgb / (Samplecount - (BloomPower - BloomThreshold*5)));
	const float Bloomamount = (dot(color.rgb,float3(0.299f, 0.587f, 0.114f)));
	const float3 BlurColor = BlurColor2.rgb * (BloomPower + 4.0);
	color.rgb = lerp(color.rgb,BlurColor.rgb, Bloomamount);	
	fragment = saturate(color);
#if GSHADE_DITHER
	fragment.rgb += TriDither(fragment.rgb, texcoord, BUFFER_COLOR_BIT_DEPTH);
#endif
}


void PS_Otis_AFG_BlendFogWithNormalBuffer(float4 vpos: SV_Position, float2 texcoord: TEXCOORD, out float4 fragment: SV_Target0)
{
	const float depth = ReShade::GetLinearizedDepth(texcoord).r;
	const float fogFactor = clamp(saturate(depth - FogStart) * FogCurve, 0.0, MaxFogFactor); 
	fragment = lerp(tex2D(ReShade::BackBuffer, texcoord), lerp(tex2D(Otis_BloomSampler, texcoord), float4(FogColor, 1.0), fogFactor), fogFactor);
#if GSHADE_DITHER
	fragment.rgb += TriDither(fragment.rgb, texcoord, BUFFER_COLOR_BIT_DEPTH);
#endif
}

technique AdaptiveFog <ui_label="自适应雾";>
{
	pass Otis_AFG_PassBloom0
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_Otis_AFG_PerformBloom;
		RenderTarget = Otis_BloomTarget;
	}
	
	pass Otis_AFG_PassBlend
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_Otis_AFG_BlendFogWithNormalBuffer;
	}
}
