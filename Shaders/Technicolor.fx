/**
 * Technicolor version 1.1
 * Original by DKT70
 * Optimized by CeeJay.dk
 */
 // Lightly optimized by Marot Satil for the GShade project.
 // Translation of the UI into Chinese by Lilidream.

uniform float Power <
	ui_label = "幂(Power)";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 8.0;
> = 4.0;
uniform float3 RGBNegativeAmount <
	ui_label = "RGB负值数";
	ui_type = "color";
> = float3(0.88, 0.88, 0.88);

uniform float Strength <
	ui_label = "强度";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_tooltip = "调整效果强度";
> = 0.4;

#include "ReShade.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

float3 TechnicolorPass(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	const float3 cyanfilter = float3(0.0, 1.30, 1.0);
	const float3 magentafilter = float3(1.0, 0.0, 1.05);
	const float3 yellowfilter = float3(1.6, 1.6, 0.05);
	const float2 redorangefilter = float2(1.05, 0.620); // RG_
	const float2 greenfilter = float2(0.30, 1.0);       // RG_
	const float2 magentafilter2 = magentafilter.rb;     // R_B

	const float3 tcol = tex2D(ReShade::BackBuffer, texcoord).rgb;
	
	const float2 negative_mul_r = tcol.rg * (1.0 / (RGBNegativeAmount.r * Power));
	const float2 negative_mul_g = tcol.rg * (1.0 / (RGBNegativeAmount.g * Power));
	const float2 negative_mul_b = tcol.rb * (1.0 / (RGBNegativeAmount.b * Power));
	const float3 output_r = dot(redorangefilter, negative_mul_r).xxx + cyanfilter;
	const float3 output_g = dot(greenfilter, negative_mul_g).xxx + magentafilter;
	const float3 output_b = dot(magentafilter2, negative_mul_b).xxx + yellowfilter;

#if GSHADE_DITHER
	const float3 outcolor = lerp(tcol, output_r * output_g * output_b, Strength);
	return outcolor + TriDither(outcolor, texcoord, BUFFER_COLOR_BIT_DEPTH);
#else
	return lerp(tcol, output_r * output_g * output_b, Strength);
#endif
}

technique Technicolor <ui_label="彩色印片(Technicolor)";>
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = TechnicolorPass;
	}
}
