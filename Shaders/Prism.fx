/*
Copyright (c) 2018 Jacob Maximilian Fober

This work is licensed under the Creative Commons
Attribution-NonCommercial-ShareAlike 4.0 International License.
To view a copy of this license, visit
http://creativecommons.org/licenses/by-nc-sa/4.0/.

Modified by Marot for ReShade 4.0 compatibility and lightly optimized for the GShade project.
Translation of the UI into Chinese by Lilidream.
*/

// Chromatic Aberration PS (Prism) v1.3.2
// inspired by Marty McFly YACA shader


	  ////////////
	 /// MENU ///
	////////////

uniform int Aberration <
	ui_label = "像素内色差";
	ui_type = "slider";
	ui_min = -48; ui_max = 48;
> = 6;

uniform float Curve <
	ui_label = "色差曲线";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 4.0; ui_step = 0.01;
> = 1.0;

uniform bool Automatic <
	ui_label = "自动采样数";
	ui_tooltip = "将会自动调整的采样数量";
	ui_category = "性能";
	ui_category_closed = true;
> = true;

uniform int SampleCount <
	ui_label = "采样";
	ui_tooltip = "采样数量(只接受偶数，奇数将被限制。)";
	ui_type = "slider";
	ui_min = 6; ui_max = 32;
	ui_category = "性能";
> = 8;

	  //////////////
	 /// SHADER ///
	//////////////

#include "ReShade.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

// Special Hue generator by JMF
float3 Spectrum(float Hue)
{
	float3 HueColor;
	Hue *= 4.0;
	HueColor.rg = Hue-float2(1.0, 2.0);
	HueColor.rg = saturate(1.5-abs(HueColor.rg));
	HueColor.r += saturate(Hue-3.5);
	HueColor.b = 1.0-HueColor.r;
	return HueColor;
}

// Define screen texture with mirror tiles
sampler SamplerColor
{
	Texture = ReShade::BackBufferTex;
	AddressU = MIRROR;
	AddressV = MIRROR;
	#if BUFFER_COLOR_BIT_DEPTH != 10
		SRGBTexture = true;
	#endif
};

void ChromaticAberrationPS(float4 vois : SV_Position, float2 texcoord : TexCoord, out float3 BluredImage : SV_Target)
{
	// Adjust number of samples
	float Samples;
	if (Automatic)
		Samples = clamp(2.0 * ceil(abs(Aberration) * 0.5) + 2.0, 6.0, 48.0); // Ceil odd numbers to even with minimum 6, maximum 48
	else
		Samples = floor(SampleCount * 0.5) * 2.0; // Clamp odd numbers to even

	// Calculate sample offset
	const float Sample = 1.0 / Samples;

	// Convert UVs to centered coordinates with correct Aspect Ratio
	float2 RadialCoord = texcoord - 0.5;
	RadialCoord.x *= BUFFER_ASPECT_RATIO;

	// Generate radial mask from center (0) to the corner of the screen (1)
	const float Mask = pow(2.0 * length(RadialCoord) * rsqrt(BUFFER_ASPECT_RATIO * BUFFER_ASPECT_RATIO + 1.0), Curve);

	const float OffsetBase = Mask * Aberration * BUFFER_RCP_HEIGHT * 2.0;

	// Each loop represents one pass
	if(abs(OffsetBase) < BUFFER_RCP_HEIGHT)
		BluredImage = tex2D(SamplerColor, texcoord).rgb;
	else
	{
		BluredImage = 0.0;
		for (float P = 0.0; P < Samples; P++)
		{
			float Progress = P * Sample;

			// Scale UVs at center
			float2 Position = RadialCoord / (OffsetBase * (Progress - 0.5) + 1.0);
			// Convert aspect ratio back to square
			Position.x /= BUFFER_ASPECT_RATIO;
			// Convert centered coordinates to UV
			Position += 0.5;

			// Multiply texture sample by HUE color
			BluredImage += Spectrum(Progress) * tex2Dlod(SamplerColor, float4(Position, 0.0, 0.0)).rgb;
		}
		BluredImage *= 2.0 * Sample;
	}

#if GSHADE_DITHER
	BluredImage += TriDither(BluredImage, texcoord, BUFFER_COLOR_BIT_DEPTH);
#endif
}


	  //////////////
	 /// OUTPUT ///
	//////////////

technique ChromaticAberration < ui_label = "色差"; >
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = ChromaticAberrationPS;
		SRGBWriteEnable = true;
	}
}
