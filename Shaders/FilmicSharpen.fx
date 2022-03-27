/**
Filmic Sharpen PS v1.2.8 (c) 2018 Jakub Maximilian Fober

This work is licensed under the Creative Commons
Attribution-ShareAlike 4.0 International License.
To view a copy of this license, visit
http://creativecommons.org/licenses/by-sa/4.0/.
*/

// Lightly optimized by Marot Satil for the GShade project.
// Translation of the UI into Chinese by Lilidream.

  ////////////
 /// MENU ///
////////////

uniform float Strength <
	ui_label = "强度";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 100.0; ui_step = 0.01;
> = 60.0;

uniform float Offset <
	ui_label = "半径";
	ui_tooltip = "像素高通较差偏移";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 2.0; ui_step = 0.001;
> = 0.1;

uniform float Clamp <
	ui_label = "阈值";
	ui_type = "slider";
	ui_min = 0.5; ui_max = 1.0; ui_step = 0.001;
> = 0.65;

uniform bool UseMask <
	ui_label = "只锐化中心";
	ui_tooltip = "只锐化画面中心";
> = false;

uniform int Coefficient <
	ui_tooltip = "对于数字视频信号用BT.709, 对于模拟(例如VGA)用BT.601";
	ui_label = "YUV系数";
	ui_type = "radio";
	ui_items = "BT.709 - 数字\0BT.601 - 模拟\0";
	ui_category = "额外设置";
	ui_category_closed = true;
> = 0;

uniform bool Preview <
	ui_label = "预览锐化图层";
	ui_tooltip = "预览锐化图层与遮罩来调整它们。"
		"如果你没看到红色的stroke\n"
		"请尝试在设置中改变预处理定义";
	ui_category = "Debug视角";
	ui_category_closed = true;
> = false;

  ////////////////
 /// TEXTURES ///
////////////////

#include "ReShade.fxh"

// Define screen texture with mirror tiles
sampler BackBuffer
{
	Texture = ReShade::BackBufferTex;
	AddressU = MIRROR;
	AddressV = MIRROR;
	#if BUFFER_COLOR_BIT_DEPTH != 10
		SRGBTexture = true;
	#endif
};

  /////////////////
 /// FUNCTIONS ///
/////////////////

// RGB to YUV709 luma
static const float3 Luma709 = float3(0.2126, 0.7152, 0.0722);
// RGB to YUV601 luma
static const float3 Luma601 = float3(0.299, 0.587, 0.114);

// Overlay blending mode
float Overlay(float LayerA, float LayerB)
{
	const float MinA = min(LayerA, 0.5);
	const float MinB = min(LayerB, 0.5);
	const float MaxA = max(LayerA, 0.5);
	const float MaxB = max(LayerB, 0.5);
	return 2.0*((MinA*MinB+MaxA)+(MaxB-MaxA*MaxB))-1.5;
}

// Overlay blending mode for one input
float Overlay(float LayerAB)
{
	const float MinAB = min(LayerAB, 0.5);
	const float MaxAB = max(LayerAB, 0.5);
	return 2.0*((MinAB*MinAB+MaxAB)+(MaxAB-MaxAB*MaxAB))-1.5;
}

// Convert to linear gamma
float gamma(float grad) { return pow(abs(grad), 2.2); }

  //////////////
 /// SHADER ///
//////////////

// Sharpen pass
float3 FilmicSharpenPS(float4 pos : SV_Position, float2 UvCoord : TEXCOORD) : SV_Target
{
	// Sample display image
	const float3 Source = tex2D(BackBuffer, UvCoord).rgb;

	// Generate and apply radial mask
	float Mask;
	if (UseMask)
	{
		// Generate radial mask
		Mask = 1.0-length(UvCoord*2.0-1.0);
		Mask = Overlay(Mask)*Strength;
		// Bypass
		if (Mask <= 0) return Source;
	}
	else Mask = Strength;

	// Get pixel size
	const float2 Pixel = BUFFER_PIXEL_SIZE*Offset;

	// Sampling coordinates
	const float2 NorSouWesEst[4] = {
		float2(UvCoord.x, UvCoord.y+Pixel.y),
		float2(UvCoord.x, UvCoord.y-Pixel.y),
		float2(UvCoord.x+Pixel.x, UvCoord.y),
		float2(UvCoord.x-Pixel.x, UvCoord.y)
	};

	// Choose luma coefficient, if False BT.709 luma, else BT.601 luma
	float3 LumaCoefficient;
	if (bool(Coefficient))
		LumaCoefficient = Luma601;
	else
		LumaCoefficient = Luma709;

	// Luma high-pass
	float HighPass = 0.0;
	[unroll]
	for(int i=0; i<4; i++)
		HighPass += dot(tex2D(BackBuffer, NorSouWesEst[i]).rgb, LumaCoefficient);

	HighPass = 0.5-0.5*(HighPass*0.25-dot(Source, LumaCoefficient));

	// Sharpen strength
	HighPass = lerp(0.5, HighPass, Mask);

	// Clamping sharpen
	if (Clamp != 1.0)
		HighPass = clamp(HighPass, 1.0-Clamp, Clamp);

	if (Preview)
		return gamma(HighPass);
	else
		return float3(
		Overlay(Source.r, HighPass),
		Overlay(Source.g, HighPass),
		Overlay(Source.b, HighPass)
		);
}


  //////////////
 /// OUTPUT ///
//////////////

technique FilmicSharpen < ui_label = "胶片锐化"; >
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = FilmicSharpenPS;
		SRGBWriteEnable = true;
	}
}
