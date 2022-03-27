/*
	PandaFX version 2.2.2 for ReShade 4
	by Jukka Korhonen aka Loadus ~ twitter.com/thatbonsaipanda
	November 2018
	jukka.korhonen@gmail.com
	
	Modified by Marot Satil for ReShade 4.0 compatibility and lightly optimized for the GShade project.
	
	Applies cinematic lens effects and color grading.
	Free licence to copy, modify, tweak and publish but
	if you can, give credit. Thanks. o/
	
	- jP
 */
 // Translation of the UI into Chinese by Lilidream.

#include "ReShade.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

// UNIFORMS
//------------------------------------


uniform float Blend_Amount <
	ui_label = "混合数量";
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 1.0;
	ui_tooltip = "将原画面与效果混合";
	ui_category = "一般设置";
> = 1.0;

uniform float Contrast_R <
    ui_label = "对比度 (红)";
	ui_type = "slider";
	ui_min = 0.00001;
	ui_max = 20.0;
	ui_tooltip = "对红色应用对比度";
	ui_category = "一般设置";
> = 2.2;

uniform float Contrast_G <
    ui_label = "对比度 (绿)";
	ui_type = "slider";
	ui_min = 0.00001;
	ui_max = 20.0;
	ui_tooltip = "对绿色应用对比度";
	ui_category = "一般设置";
> = 2.0;

uniform float Contrast_B <
    ui_label = "对比度 (蓝)";
	ui_type = "slider";
	ui_min = 0.00001;
	ui_max = 20.0;
	ui_tooltip = "对蓝色应用对比度";
	ui_category = "一般设置";
> = 2.0;

uniform float Gamma_R <
    ui_label = "Gamma (红)";
	ui_type = "slider";
	ui_min = 0.02;
	ui_max = 5.0;
	ui_tooltip = "对红色应用Gamma";
	ui_category = "一般设置";
> = 1.0;

uniform float Gamma_G <
    ui_label = "Gamma (绿)";
	ui_type = "slider";
	ui_min = 0.02;
	ui_max = 5.0;
	ui_tooltip = "Apply Gamma to green.";
	ui_tooltip = "对绿色应用Gamma";
	ui_category = "一般设置";
> = 1.0;

uniform float Gamma_B <
    ui_label = "Gamma (蓝)";
	ui_type = "slider";
	ui_min = 0.02;
	ui_max = 5.0;
	ui_tooltip = "对蓝色应用Gamma";
	ui_category = "一般设置";
> = 1.0;

uniform bool Enable_Diffusion <
	ui_label = "开启镜头漫射效果";
	ui_tooltip = "启用模仿相机镜头眩光的光扩散装置。";
	ui_category = "镜头漫射";
	ui_bind = "PANDAFX_ENABLE_DIFFUSION";
> = true;

#ifndef PANDAFX_ENABLE_DIFFUSION
	#define PANDAFX_ENABLE_DIFFUSION 1
#endif

#if PANDAFX_ENABLE_DIFFUSION
uniform bool Enable_Static_Dither <
	ui_label = "应用静态抖动";
	ui_tooltip = "抖动漫射。仅应用一张静态抖动贴图。";
	ui_category = "镜头漫射";
	ui_bind = "PANDAFX_ENABLE_STATIC_DITHER";
> = true;

#ifndef PANDAFX_ENABLE_STATIC_DITHER
	#define PANDAFX_ENABLE_STATIC_DITHER 1
#endif

uniform float Diffusion_1_Amount <
    ui_label = "漫射1数量";
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 1.0;
	ui_tooltip = "调整第一漫射图层数量";
	ui_category = "镜头漫射";
> = 0.5;

uniform int Diffusion_1_Radius <
	ui_label = "漫射1半径";
	ui_type = "slider";
	ui_min = 5;
	ui_max = 20;
	ui_tooltip = "第一漫射图层的半径";
	ui_category = "镜头漫射";
	ui_bind = "PANDAFX_DIFFUSION_1_RADIUS";
> = 8;

#ifndef PANDAFX_DIFFUSION_1_RADIUS
	#define PANDAFX_DIFFUSION_1_RADIUS 8
#endif

uniform float Diffusion_1_Gamma <
    ui_label = "漫射1Gamma";
	ui_type = "slider";
	ui_min = 0.02;
	ui_max = 5.0;
	ui_tooltip = "应用Gamma到第一漫射图层上";
	ui_category = "镜头漫射";
> = 2.2;

uniform float Diffusion_1_Quality <
	ui_label = "漫射1采样质量";
	// ui_type = "slider";
	// ui_min = 1;
	// ui_max = 64;
	ui_tooltip = "设置第一漫射图层的质量。数字是贴图大小被分成两半的除数。较低的数字=较高的质量，但需要更多的处理。(不需要调整这个。)";
	ui_category = "镜头漫射";
> = 2;

uniform float Diffusion_1_Desaturate <
    ui_label = "漫射1去饱和度";
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 1.0;
	ui_tooltip = "调整第一漫射图层的饱和度";
	ui_category = "镜头漫射";
> = 0.0;

uniform float Diffusion_2_Amount <
    ui_label = "漫射2数量";
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 1.0;
	ui_tooltip = "Adjust the amount of the second diffusion layer.";
	ui_category = "镜头漫射";
> = 0.5;

uniform int Diffusion_2_Radius <
	ui_label = "漫射2半径";
	ui_type = "slider";
	ui_min = 5;
	ui_max = 20;
	ui_tooltip = "Set the radius of the second diffusion layer.";
	ui_category = "镜头漫射";
	ui_bind = "PANDAFX_DIFFUSION_2_RADIUS";
> = 8;

#ifndef PANDAFX_DIFFUSION_2_RADIUS
	#define PANDAFX_DIFFUSION_2_RADIUS 8
#endif

uniform float Diffusion_2_Gamma <
    ui_label = "漫射2Gamma";
	ui_type = "slider";
	ui_min = 0.02;
	ui_max = 5.0;
	ui_tooltip = "Apply Gamma to second diffusion layer.";
	ui_category = "镜头漫射";
> = 1.3;

uniform float Diffusion_2_Quality <
	ui_label = "漫射2采样质量";
	// ui_type = "slider";
	// ui_min = 1;
	// ui_max = 64;
	ui_tooltip = "Set the quality of the second diffusion layer. Number is the divider of how many times the texture size is divided in half. Lower number = higher quality, but more processing needed. (No need to adjust this.)";
	ui_category = "镜头漫射";
> = 16;

uniform float Diffusion_2_Desaturate <
    ui_label = "漫射2去饱和度";
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 1.0;
	ui_tooltip = "Adjust the saturation of the second diffusion layer.";
	ui_category = "镜头漫射";
> = 0.5;

uniform float Diffusion_3_Amount <
    ui_label = "漫射3数量";
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 1.0;
	ui_tooltip = "Adjust the amount of the third diffusion layer.";
	ui_category = "镜头漫射";
> = 0.5;

uniform int Diffusion_3_Radius <
	ui_label = "漫射3半径";
	ui_type = "slider";
	ui_min = 5;
	ui_max = 20;
	ui_tooltip = "Set the radius of the third diffusion layer.";
	ui_category = "镜头漫射";
	ui_bind = "PANDAFX_DIFFUSION_3_RADIUS";
> = 8;

#ifndef PANDAFX_DIFFUSION_3_RADIUS
	#define PANDAFX_DIFFUSION_3_RADIUS 8
#endif

uniform float Diffusion_3_Gamma <
    ui_label = "漫射3Gamma";
	ui_type = "slider";
	ui_min = 0.02;
	ui_max = 5.0;
	ui_tooltip = "Apply Gamma to third diffusion layer.";
	ui_category = "镜头漫射";
> = 1.0;

uniform float Diffusion_3_Quality <
	ui_label = "漫射3采样质量";
	// ui_type = "slider";
	// ui_min = 1;
	// ui_max = 64;
	ui_tooltip = "Set the quality of the third diffusion layer. Number is the divider of how many times the texture size is divided in half. Lower number = higher quality, but more processing needed. (No need to adjust this.)";
	ui_category = "镜头漫射";
> = 64;

uniform float Diffusion_3_Desaturate <
    ui_label = "漫射3去饱和度";
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 1.0;
	ui_tooltip = "Adjust the saturation of the third diffusion layer.";
	ui_category = "镜头漫射";
> = 0.75;
#endif

uniform bool Enable_Bleach_Bypass <
	ui_label = "开启'Bleach Bypass(漂白旁路)'效果";
	ui_tooltip = "启用一个电影级的对比度效果，模仿电影中的漂白旁路。在战争电影中经常使用，使图像具有更多的砂砾感。";
	ui_category = "Bleach Bypass(漂白旁路)";
	ui_bind = "PANDAFX_ENABLE_BLEACH_BYPASS";
> = true;

#ifndef PANDAFX_ENABLE_BLEACH_BYPASS
	#define PANDAFX_ENABLE_BLEACH_BYPASS 1
#endif

#if PANDAFX_ENABLE_BLEACH_BYPASS
uniform float Bleach_Bypass_Amount <
	ui_label = "Bleach Bypass(漂白旁路)数量";
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 1.0;
	ui_tooltip = "Adjust the amount of the third diffusion layer.";
	ui_category = "Bleach Bypass(漂白旁路)";
> = 0.5;
#endif

uniform bool Enable_Dither <
	ui_label = "抖动最终输出";
	ui_tooltip = "对着色器的最终结果进行抖动。禁用该选项可以使用GShade的TriDither工具。";
	ui_category = "遗留设置";
	ui_bind = "PANDAFX_ENABLE_DITHER";
> = false;

#ifndef PANDAFX_ENABLE_DITHER
	#define PANDAFX_ENABLE_DITHER 0
#endif

#if PANDAFX_ENABLE_DITHER
uniform float Dither_Amount <
    ui_label = "抖动数量";
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 1.0;
	ui_tooltip = "调整扩散图层的抖动数量 (来平滑掉色带)。";
	ui_category = "遗留设置";
> = 0.15;
#endif

uniform float framecount < source = "framecount"; >;


// TEXTURES
//--------------------------------------------
// Provide a noise texture, basically a gray surface with grain:
texture NoiseTex <source = "hd_noise.png"; > { Width = 1920; Height = 1080; Format = RGBA8; };
texture prePassLayer { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
texture blurLayerHorizontal { Width = BUFFER_WIDTH / 2; Height = BUFFER_HEIGHT / 2; Format = RGBA8; };
texture blurLayerVertical { Width = BUFFER_WIDTH / 2; Height = BUFFER_HEIGHT / 2; Format = RGBA8; };
texture blurLayerHorizontalMedRes { Width = BUFFER_WIDTH / 16; Height = BUFFER_HEIGHT / 16; Format = RGBA8; };
texture blurLayerVerticalMedRes { Width = BUFFER_WIDTH / 16; Height = BUFFER_HEIGHT / 16; Format = RGBA8; };
texture blurLayerHorizontalLoRes { Width = BUFFER_WIDTH / 64; Height = BUFFER_HEIGHT / 64; Format = RGBA8; };
texture blurLayerVerticalLoRes { Width = BUFFER_WIDTH / 64; Height = BUFFER_HEIGHT / 64; Format = RGBA8; };

// SAMPLERS
//--------------------------------------------
sampler NoiseSampler { Texture = NoiseTex; };
sampler2D PFX_PrePassLayer { Texture = prePassLayer; };
// ------- samplers for large radius blur
sampler2D PFX_blurHorizontalLayer {	Texture = blurLayerHorizontal; };
sampler2D PFX_blurVerticalLayer { Texture = blurLayerVertical; };
sampler2D PFX_blurHorizontalLayerMedRes { Texture = blurLayerHorizontalMedRes; };
sampler2D PFX_blurVerticalLayerMedRes {	Texture = blurLayerVerticalMedRes; };
sampler2D PFX_blurHorizontalLayerLoRes { Texture = blurLayerHorizontalLoRes; };
sampler2D PFX_blurVerticalLayerLoRes { Texture = blurLayerVerticalLoRes; };


// FUNCTIONS
//--------------------------------------------
float AdjustableSigmoidCurve (float value, float amount) {

	float curve = 1.0; 

    if (value < 0.5)
    {
        curve = pow(value, amount) * pow(2.0, amount) * 0.5; 
    }
        
    else
    { 	
    	curve = 1.0 - pow(max(0.0, 1.0 - value), amount) * pow(2.0, amount) * 0.5; 
    }

    return curve;
}

float Randomize (float2 coord) {
	return clamp((frac(sin(dot(coord, float2(12.9898, 78.233))) * 43758.5453)), 0.0, 1.0);
}

float SigmoidCurve (float value) {
	const value = value * 2.0 - 1.0;
	return -value * abs(value) * 0.5 + value + 0.5;	
}

float SoftLightBlend (float A, float B) {
	
	if (A > 0.5)
	{
		return (2 * A - 1) * (sqrt(B) - B) + B; 
	}

	else
	{
		return (2 * A - 1) * (B - (B * 2)) + B; 
	}	

	return 0;
}

float4 BlurH (sampler input, float2 uv, float radius, float sampling) {


	float2 coordinate = float2(0.0, 0.0);
	float4 A = float4(0.0, 0.0, 0.0, 1.0); 
	float4 C = float4(0.0, 0.0, 0.0, 1.0);
	float weight = 1.0; 
	const float width = 1.0 / BUFFER_WIDTH * sampling;					
	float divisor = 0.000001; 

		for (float x = -radius; x <= radius; x++)
		{
			coordinate = uv + float2(x * width, 0.0);
			coordinate = clamp(coordinate, 0.0, 1.0); 
			A = tex2Dlod(input, float4(coordinate, 0.0, 0.0));		
				weight = SigmoidCurve(1.0 - (abs(x) / radius));		
				C += A * weight; 		
			divisor += weight;
		}
	
	return C / divisor; 
}

float4 BlurV (sampler input, float2 uv, float radius, float sampling) {

	float2 coordinate = float2(0.0, 0.0);
	float4 A = float4(0.0, 0.0, 0.0, 1.0); 
	float4 C = float4(0.0, 0.0, 0.0, 1.0); 
	float weight = 1.0; 	
	const float height = 1.0 / BUFFER_HEIGHT * sampling;					
	float divisor = 0.000001; 

		for (float y = -radius; y <= radius; y++)
		{
			coordinate = uv + float2(0.0, y * height);
			coordinate = clamp(coordinate, 0.0, 1.0);		
			A = tex2Dlod(input, float4(coordinate, 0.0, 0.0));	
				weight = SigmoidCurve(1.0 - (abs(y) / radius)); 		
				C += A * weight; 		
			divisor += weight;
		}

	return C / divisor; 
}


void PS_PrePass (float4 pos : SV_Position, 
				 float2 uv : TEXCOORD, 
				 out float4 result : SV_Target) 
{

	float4 A = tex2D(ReShade::BackBuffer, uv);
		   A.r = pow(max(0.0, A.r), Gamma_R);
		   A.g = pow(max(0.0, A.g), Gamma_G);
		   A.b = pow(max(0.0, A.b), Gamma_B);
		   A.r = AdjustableSigmoidCurve(A.r, Contrast_R);
		   A.g = AdjustableSigmoidCurve(A.g, Contrast_G);
		   A.b = AdjustableSigmoidCurve(A.b, Contrast_B);
	
	// ------- Change color weights of the final render, similar to a printed film

		A.g = A.g * 0.8 + A.b * 0.2;

		float red = A.r - A.g - A.b;
		float green = A.g - A.r - A.b;
		float blue = A.b - A.r - A.g;

		red = clamp(red, 0.0, 1.0);
		green = clamp(green, 0.0, 1.0);
		blue = clamp(blue, 0.0, 1.0);

		A = A * (1.0 - red * 0.6);
		A = A * (1.0 - green * 0.8);
		A = A * (1.0 - blue * 0.3);
		
		// A.r = AdjustableSigmoidCurve(A.r, 1.4);
		// A.r = pow(A.r, 1.1);	
		
		result = A;
}


#if PANDAFX_ENABLE_DIFFUSION
void PS_HorizontalPass (float4 pos : SV_Position, 
						float2 uv : TEXCOORD, out float4 result : SV_Target) 
{
	result = BlurH(PFX_PrePassLayer, uv, Diffusion_1_Radius, Diffusion_1_Quality);
	// result = BlurH(ReShade::BackBuffer, uv, Diffusion_1_Radius, Diffusion_1_Quality);
}

void PS_VerticalPass (float4 pos : SV_Position, 
					  float2 uv : TEXCOORD, out float4 result : SV_Target) 
{
	result = BlurV(PFX_blurHorizontalLayer, uv, Diffusion_1_Radius, Diffusion_1_Quality);
}

void PS_HorizontalPassMedRes (float4 pos : SV_Position, 
						float2 uv : TEXCOORD, out float4 result : SV_Target) 
{
	result = BlurH(PFX_blurVerticalLayer, uv, Diffusion_2_Radius, Diffusion_2_Quality);
}

void PS_VerticalPassMedRes (float4 pos : SV_Position, 
					  float2 uv : TEXCOORD, out float4 result : SV_Target) 
{
	result = BlurV(PFX_blurHorizontalLayerMedRes, uv, Diffusion_2_Radius, Diffusion_2_Quality);
}

void PS_HorizontalPassLoRes (float4 pos : SV_Position, 
						float2 uv : TEXCOORD, out float4 result : SV_Target) 
{
	result = BlurH(PFX_blurVerticalLayerMedRes, uv, Diffusion_3_Radius, Diffusion_3_Quality);
}

void PS_VerticalPassLoRes (float4 pos : SV_Position, 
					  float2 uv : TEXCOORD, out float4 result : SV_Target) 
{
	result = BlurV(PFX_blurHorizontalLayerLoRes, uv, Diffusion_3_Radius, Diffusion_3_Quality);
}
#endif




float4 PandaComposition (float4 vpos : SV_Position, 
						 float2 uv : TEXCOORD) : SV_Target 
{
#if PANDAFX_ENABLE_DIFFUSION
	// ------- Create blurred layers for lens diffusion

		float4 blurLayer;
		float4 blurLayerMedRes;
		float4 blurLayerLoRes;

		// TODO enable/disable for performance >>
		blurLayer = tex2D(PFX_blurVerticalLayer, uv);
		blurLayerMedRes = tex2D(PFX_blurVerticalLayerMedRes, uv);
		blurLayerLoRes = tex2D(PFX_blurVerticalLayerLoRes, uv);
	

		// ------- Blur layer colors

		const float4 blurLayerGray = dot(0.3333, blurLayer.rgb);
		blurLayer = lerp(blurLayer, blurLayerGray, Diffusion_2_Desaturate);

		const float4 blurLayerMedResGray = dot(0.3333, blurLayerMedRes.rgb);
		blurLayerMedRes = lerp(blurLayerMedRes, blurLayerMedResGray, Diffusion_2_Desaturate);

		const float4 blurLayerLoResGray = dot(0.3333, blurLayerLoRes.rgb);
		blurLayerLoRes = lerp(blurLayerLoRes, blurLayerLoResGray, Diffusion_3_Desaturate);

		// blurLayerMedRes.g *= 0.75;
		// blurLayerMedRes.b *= 0.5;

		// blurLayerLoRes.g *= 0.75;
		// blurLayerLoRes.r *= 0.5;


		// ------- Set blur layer weights

		blurLayer *= Diffusion_1_Amount;
		blurLayerMedRes *= Diffusion_2_Amount;
		blurLayerLoRes *= Diffusion_3_Amount;
	
		blurLayer = pow(max(0.0, blurLayer), Diffusion_1_Gamma);
		blurLayerMedRes = pow(max(0.0, blurLayerMedRes), Diffusion_2_Gamma);
		blurLayerLoRes = pow(max(0.0, blurLayerLoRes), Diffusion_3_Gamma);

	#if PANDAFX_ENABLE_STATIC_DITHER
		const float3 hd_noise = 1.0 - (tex2D(NoiseSampler, uv).rgb * 0.01);
		blurLayer.rgb = 1.0 - hd_noise * (1.0 - blurLayer.rgb);
		blurLayerMedRes.rgb = 1.0 - hd_noise * (1.0 - blurLayerMedRes.rgb);
		blurLayerLoRes.rgb = 1.0 - hd_noise * (1.0 - blurLayerLoRes.rgb);
	#endif
#endif


	// ------- Read original image

		float4 A = tex2D(PFX_PrePassLayer, uv);
		const float4 O = tex2D(ReShade::BackBuffer, uv);

	// ------- Screen blend the blur layers to create lens diffusion

#if PANDAFX_ENABLE_DIFFUSION
		blurLayer = clamp(blurLayer, 0.0, 1.0);
		blurLayerMedRes = clamp(blurLayerMedRes, 0.0, 1.0);
		blurLayerLoRes = clamp(blurLayerLoRes, 0.0, 1.0);

		A.rgb = 1.0 - (1.0 - blurLayer.rgb) * (1.0 - A.rgb);
		A.rgb = 1.0 - (1.0 - blurLayerMedRes.rgb) * (1.0 - A.rgb);
		A.rgb = 1.0 - (1.0 - blurLayerLoRes.rgb) * (1.0 - A.rgb);
#endif


	// ------ Compress contrast using Hard Light blending ------
		
#if PANDAFX_ENABLE_BLEACH_BYPASS
		const float Ag = dot(float3(0.3333, 0.3333, 0.3333), A.rgb);
		float4 B = A;
		float4 C = 0;

		if (Ag > 0.5)
		{
			C = 1 - 2 * (1 - Ag) * (1 - B);
		}

		else
		{
			C = 2 * Ag * B;
		}

		C = pow(max(0.0, C), 0.6);
		A = lerp(A, C, Bleach_Bypass_Amount);
#endif


	// ------- Dither the composition to eliminate banding

#if PANDAFX_ENABLE_DITHER
		const float rndSample = tex2D(NoiseSampler, uv).x;
		const float uvRnd = Randomize(rndSample * framecount);
		const float uvRnd2 = Randomize(-rndSample * framecount);

		const float3 noise = float3(tex2D(NoiseSampler, uv * uvRnd).x, tex2D(NoiseSampler, uv * uvRnd2).x, tex2D(NoiseSampler, -uv * uvRnd).x);

		float4 Bb = A;

		Bb.r = SoftLightBlend(noise.r, A.r);
		Bb.g = SoftLightBlend(noise.g, A.g);
		Bb.b = SoftLightBlend(noise.b, A.b);

		A = lerp(A, Bb, Dither_Amount);
#endif

	// ------ Compress to TV levels if needed ------
		
		// A = A * 0.9373 + 0.0627;

#if GSHADE_DITHER && !PANDAFX_ENABLE_DITHER
		const float4 outcolor = lerp(O, A, Blend_Amount);
		return float4(outcolor.rgb + TriDither(outcolor.rgb, uv, BUFFER_COLOR_BIT_DEPTH), outcolor.a);
#else
		return lerp(O, A, Blend_Amount);
#endif
}


// TECHNIQUES
//--------------------------------------------
technique PandaFX <ui_label="熊猫特效(PandaFX)";>
{
		pass PreProcess	
		{
			VertexShader = PostProcessVS;
			PixelShader = PS_PrePass;
			RenderTarget = prePassLayer;
		}

#if PANDAFX_ENABLE_DIFFUSION
		pass HorizontalPass
		{
			VertexShader = PostProcessVS;
			PixelShader = PS_HorizontalPass;
			RenderTarget = blurLayerHorizontal;
		}

		pass VerticalPass
		{
			VertexShader = PostProcessVS;
			PixelShader = PS_VerticalPass;
			RenderTarget = blurLayerVertical;
		}

		pass HorizontalPassMedRes
		{
			VertexShader = PostProcessVS;
			PixelShader = PS_HorizontalPassMedRes;
			RenderTarget = blurLayerHorizontalMedRes;
		}

		pass VerticalPassMedRes
		{
			VertexShader = PostProcessVS;
			PixelShader = PS_VerticalPassMedRes;
			RenderTarget = blurLayerVerticalMedRes;
		}

		pass HorizontalPassLoRes
		{
			VertexShader = PostProcessVS;
			PixelShader = PS_HorizontalPassLoRes;
			RenderTarget = blurLayerHorizontalLoRes;
		}

		pass VerticalPassLoRes
		{
			VertexShader = PostProcessVS;
			PixelShader = PS_VerticalPassLoRes;
			RenderTarget = blurLayerVerticalLoRes;
		}
#endif

	pass CustomPass
	{
		VertexShader = PostProcessVS;
		PixelShader = PandaComposition;
	}
}