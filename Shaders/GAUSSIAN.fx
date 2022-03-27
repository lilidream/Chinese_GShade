// Implementation based on the article "Efficient Gaussian blur with linear sampling"
// http://rastergrid.com/blog/2010/09/efficient-gaussian-blur-with-linear-sampling/
// Updated and Modified by Marot Satil for ReShade 4.0 and lightly optimized for the GShade project.
// Translation of the UI into Chinese by Lilidream.

 /*-----------------------------------------------------------.
/                  Gaussian Blur settings                     /
'-----------------------------------------------------------*/

#include "ReShade.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

//BrightPass *also affects blur and unsharpmask* *Recommend off for blur*
//Doesn't seem to be working right but it makes bloom look better. 1 = on, 0 = off.
#ifndef gUSE_BP
#define gUSE_BP 1
#endif

//Bloom / Blur direction
//The direction the pixels are being shifted during the gaussian passes. 1 = on, 0 = off.
#ifndef gUSE_HorizontalGauss
#define gUSE_HorizontalGauss 1
#endif

#ifndef gUSE_VerticalGauss
#define gUSE_VerticalGauss 1
#endif

#ifndef gUSE_SlantGauss
#define gUSE_SlantGauss 1
#endif

//GaussQuality
//0 = original, 1 = new. New is the same as original but has additional sample points in-between.
//When using 1, setting N_PASSES to 9 can help smooth wider bloom settings.
#define gGaussQuality 0

uniform int gGaussEffect <
    ui_label = "高斯效果";
    ui_type = "combo";
    ui_items="关\0模糊\0USM锐化 (expensive)\0泛光\0Sketchy\0Effects Image Only\0";
> = 1;

uniform float gGaussStrength <
    ui_label = "高斯强度";
    ui_tooltip = "融合到最终画面的效果强度。";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.001;
> = 0.3;

uniform bool gAddBloom <
    ui_label = "添加泛光";
> = 0;

//Bloom Strength
//[0.00 to 1.00] Amount of gAddBloom added to the final image.
#define BloomStrength 0.33

uniform float gBloomStrength <
    ui_label = "泛光强度";
    ui_tooltip = "添加到最终画面的泛光数量。";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.001;
> = 0.33;

uniform float gBloomIntensity <
    ui_label = "泛光强度";
    ui_tooltip = "使亮点更亮。同样影响模糊与USM锐化。";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 6.0;
    ui_step = 0.001;
> = 3.0;

uniform int gGaussBloomWarmth <
    ui_label = "泛光类型";
    ui_tooltip = "选择适合你的色调映射算法。";
    ui_type = "combo";
    ui_items="中性\0温暖\0朦胧/有雾的\0";
> = 0;

uniform int gN_PASSES <
    ui_label = "高斯通道数量";
    ui_tooltip = "当gGaussQuality = 0, 则此值一定设置为 3, 4, 或 5。\n当使用gGaussQuality = 1, 此值一定为3,4,5,6,7,8, 或 9。\n改变通道的数量会影响亮度。";
    ui_type = "slider";
    ui_min = 3;
    ui_max = 9;
    ui_step = 1;
> = 5;

uniform float gBloomHW <
    ui_label = "水平泛光宽度";
    ui_tooltip = "高值 = 宽泛光";
    ui_type = "slider";
    ui_min = 0.001;
    ui_max = 10.0;
    ui_step = 0.001;
> = 1.0;

uniform float gBloomVW <
    ui_label = "垂直泛光宽度";
    ui_tooltip = "高值 = 宽泛光";
    ui_type = "slider";
    ui_min = 0.001;
    ui_max = 10.0;
    ui_step = 0.001;
> = 1.0;

uniform float gBloomSW <
    ui_label = "泛光偏离";
    ui_tooltip = "高值 = 宽泛光";
    ui_type = "slider";
    ui_min = 0.001;
    ui_max = 10.0;
    ui_step = 0.001;
> = 2.0;


#define PIXEL_SIZE float2(BUFFER_RCP_WIDTH,BUFFER_RCP_HEIGHT)
#define CoefLuma_G            float3(0.2126, 0.7152, 0.0722)      // BT.709 & sRBG luma coefficient (Monitors and HD Television)
#define sharp_strength_luma_G (CoefLuma_G * gGaussStrength + 0.2)
#define sharp_clampG        0.035


texture origframeTex2D
{
	Width = BUFFER_WIDTH;
	Height = BUFFER_HEIGHT;
	Format = R8G8B8A8; 
};

sampler origframeSampler
{
    Texture = origframeTex2D;
    AddressU  = Clamp; AddressV = Clamp;
    MipFilter = None; MinFilter = Linear; MagFilter = Linear;
    SRGBTexture = false;
};

float4 BrightPassFilterPS(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD) : COLOR
{
#if GSHADE_DITHER
	float4 color = tex2D(ReShade::BackBuffer, texcoord);
	color = float4(color.rgb * pow (abs (max (color.r, max (color.g, color.b))), 2.0), 2.0f)*gBloomIntensity;
	return float4(color.rgb + TriDither(color.rgb, texcoord, BUFFER_COLOR_BIT_DEPTH), color.a);
#else
	const float4 color = tex2D(ReShade::BackBuffer, texcoord);
	return float4(color.rgb * pow (abs (max (color.r, max (color.g, color.b))), 2.0), 2.0f)*gBloomIntensity;
#endif
}

float4 HGaussianBlurPS(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD) : COLOR
{
	#if (gGaussQuality == 0)
	const float sampleOffsets[5] = { 0.0, 1.4347826, 3.3478260, 5.2608695, 7.1739130 };
	const float sampleWeights[5] = { 0.16818994, 0.27276957, 0.11690125, 0.024067905, 0.0021112196 };
	#else
	const float sampleOffsets[9] = { 0.0, 1.43*.50, 1.43, 2, 3.35, 4, 5.26, 6, 7.17 };
	const float sampleWeights[9] = { 0.168, 0.273, 0.273, 0.117, 0.117, 0.024, 0.024, 0.002, 0.002};
	#endif
	
	float4 color = tex2D(ReShade::BackBuffer, texcoord) * sampleWeights[0];
	for(int i = 1; i < gN_PASSES; ++i) {
		color += tex2Dlod(ReShade::BackBuffer, float4(texcoord + float2(sampleOffsets[i]*gBloomHW * PIXEL_SIZE.x, 0.0), 0.0, 0.0)) * sampleWeights[i];
		color += tex2Dlod(ReShade::BackBuffer, float4(texcoord - float2(sampleOffsets[i]*gBloomHW * PIXEL_SIZE.x, 0.0), 0.0, 0.0)) * sampleWeights[i];
	}
#if GSHADE_DITHER
	return float4(color.rgb + TriDither(color.rgb, texcoord, BUFFER_COLOR_BIT_DEPTH), color.a);
#else
	return color;
#endif
}

float4 VGaussianBlurPS(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD) : COLOR
{
	#if (gGaussQuality == 0)
	const float sampleOffsets[5] = { 0.0, 1.4347826, 3.3478260, 5.2608695, 7.1739130 };
	const float sampleWeights[5] = { 0.16818994, 0.27276957, 0.11690125, 0.024067905, 0.0021112196 };
	#else 
	const float sampleOffsets[9] = { 0.0, 1.4347826*.50, 1.4347826, 2, 3.3478260, 4, 5.2608695, 6, 7.1739130 };
	const float sampleWeights[9] = { 0.16818994, 0.27276957, 0.27276957, 0.11690125, 0.11690125, 0.024067905, 0.024067905, 0.0021112196 , 0.0021112196};
	#endif

	float4 color = tex2D(ReShade::BackBuffer, texcoord) * sampleWeights[0];
	for(int i = 1; i < gN_PASSES; ++i) {
		color += tex2Dlod(ReShade::BackBuffer, float4(texcoord + float2(0.0, sampleOffsets[i]*gBloomVW * PIXEL_SIZE.y), 0.0, 0.0)) * sampleWeights[i];
		color += tex2Dlod(ReShade::BackBuffer, float4(texcoord - float2(0.0, sampleOffsets[i]*gBloomVW * PIXEL_SIZE.y), 0.0, 0.0)) * sampleWeights[i];
	}
#if GSHADE_DITHER
	return float4(color.rgb + TriDither(color.rgb, texcoord, BUFFER_COLOR_BIT_DEPTH), color.a);
#else
	return color;
#endif
}

float4 SGaussianBlurPS(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD) : COLOR
{
	#if (gGaussQuality == 0)
	const float sampleOffsets[5] = { 0.0, 1.4347826, 3.3478260, 5.2608695, 7.1739130 };
	const float sampleWeights[5] = { 0.16818994, 0.27276957, 0.11690125, 0.024067905, 0.0021112196 };
	#else 
	const float sampleOffsets[9] = { 0.0, 1.4347826*.50, 1.4347826, 2, 3.3478260, 4, 5.2608695, 6, 7.1739130 };
	const float sampleWeights[9] = { 0.16818994, 0.27276957, 0.27276957, 0.11690125, 0.11690125, 0.024067905, 0.024067905, 0.0021112196 , 0.0021112196};
	#endif

	float4 color = tex2D(ReShade::BackBuffer, texcoord) * sampleWeights[0];
	for(int i = 1; i < gN_PASSES; ++i) {
		color += tex2Dlod(ReShade::BackBuffer, float4(texcoord + float2(sampleOffsets[i]*gBloomSW * PIXEL_SIZE.x, sampleOffsets[i] * PIXEL_SIZE.y), 0.0, 0.0)) * sampleWeights[i];
		color += tex2Dlod(ReShade::BackBuffer, float4(texcoord - float2(sampleOffsets[i]*gBloomSW * PIXEL_SIZE.x, sampleOffsets[i] * PIXEL_SIZE.y), 0.0, 0.0)) * sampleWeights[i];
		color += tex2Dlod(ReShade::BackBuffer, float4(texcoord + float2(-sampleOffsets[i]*gBloomSW * PIXEL_SIZE.x, sampleOffsets[i] * PIXEL_SIZE.y), 0.0, 0.0)) * sampleWeights[i];
		color += tex2Dlod(ReShade::BackBuffer, float4(texcoord + float2(sampleOffsets[i]*gBloomSW * PIXEL_SIZE.x, -sampleOffsets[i] * PIXEL_SIZE.y), 0.0, 0.0)) * sampleWeights[i];
	}
#if GSHADE_DITHER
	color *= 0.50;
	return float4(color.rgb + TriDither(color.rgb, texcoord, BUFFER_COLOR_BIT_DEPTH), color.a);
#else
	return color * 0.50;
#endif
}	

float4 CombinePS(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD) : COLOR
{
	// Unsharpmask ( Ref. http://www.bigano.com/index.php/en/consulting/40-davide-barranca/90-davide-barranca-notes-on-sharpening.html?start=1 )
	// return tex2D(origframeTex2D, texcoord); // Unprocessed image
	// return tex2D(ReShade::BackBuffer, texcoord);     // Blurred image

	float4 orig = tex2D(origframeSampler, texcoord);
	const float4 blur = tex2D(ReShade::BackBuffer, texcoord);
	float3 sharp;
	if (gGaussEffect == 0)
		orig = orig;
	else if (gGaussEffect == 1)
	{
		// Blur...
		orig = lerp(orig, blur, gGaussStrength);
	}
	else if (gGaussEffect == 2)
	{
		// Sharpening
		sharp = orig.rgb - blur.rgb;
		float sharp_luma = dot(sharp, sharp_strength_luma_G);
		sharp_luma = clamp(sharp_luma, -sharp_clampG, sharp_clampG);
		orig = orig + sharp_luma;
	}
	else if (gGaussEffect == 3)
	{
		// Bloom
		if (gGaussBloomWarmth == 0)
			orig = lerp(orig, blur *4, gGaussStrength);                                     
// Neutral
		else if (gGaussBloomWarmth == 1)
			orig = lerp(orig, max(orig *1.8 + (blur *5) - 1.0, 0.0), gGaussStrength);       // Warm and cheap
		else
			orig = lerp(orig, (1.0 - ((1.0 - orig) * (1.0 - blur *1.0))), gGaussStrength);  // Foggy bloom
	}
	else if (gGaussEffect == 4)
	{
		// Sketchy
		sharp = orig.rgb - blur.rgb;		
		orig = float4(1.0, 1.0, 1.0, 0.0) - min(orig, dot(sharp, sharp_strength_luma_G)) *3;
		// orig = float4(1.0, 1.0, 1.0, 0.0) - min(blur, orig);      // Negative
	}
	else
		orig = blur;

	if (gAddBloom == 1)
	{
		if (gGaussBloomWarmth == 0)
		{
			orig += lerp(orig, blur *4, gBloomStrength);
			orig = orig * 0.5;
		}
		else if (gGaussBloomWarmth == 1)
		{
			orig += lerp(orig, max(orig *1.8 + (blur *5) - 1.0, 0.0), gBloomStrength);
			orig = orig * 0.5;
		}
		else
		{
			orig += lerp(orig, (1.0 - ((1.0 - orig) * (1.0 - blur *1.0))), gBloomStrength);
			orig = orig * 0.5;
		}
	}
	else
		orig = orig;
	
	#if (USE_addBlur == 1)
		orig += lerp(orig, blur2, BlurStrength);
		//orig = blur2;
	#endif	

#if GSHADE_DITHER
	return float4(orig.rgb + TriDither(orig.rgb, texcoord, BUFFER_COLOR_BIT_DEPTH), orig.a);
#else
	return orig;
#endif
}

float4 PassThrough(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD) : COLOR
{
	return tex2D(ReShade::BackBuffer, texcoord);
}

technique GAUSSSIAN <ui_label="高斯模糊";>
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = PassThrough;
		RenderTarget = origframeTex2D;
	}
	
	#if (gUSE_BP == 1)
	pass P0
	{
		VertexShader = PostProcessVS;
		PixelShader = BrightPassFilterPS;
	}
	#endif
	
	#if (gUSE_HorizontalGauss == 1)
	pass P1
	{
		VertexShader = PostProcessVS;
		PixelShader = HGaussianBlurPS;
	}
	#endif

	#if (gUSE_VerticalGauss == 1)
	pass P2
	{
		VertexShader = PostProcessVS;
		PixelShader = VGaussianBlurPS;
	}
	#endif
	
	#if (gUSE_SlantGauss == 1)
	pass P3
	{
		VertexShader = PostProcessVS;
		PixelShader = SGaussianBlurPS;
	}
	#endif
		
	pass P5
	{
		VertexShader = PostProcessVS;
		PixelShader = CombinePS;
	}
}