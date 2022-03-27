/**
 * HDR
 * by Christian Cann Schuldt Jensen ~ CeeJay.dk
 *
 * Not actual HDR - It just tries to mimic an HDR look (relatively high performance cost)
 * 
 * Updated for Reshade 4.0
 */
 // Lightly optimized by Marot Satil for the GShade project.
 // Translation of the UI into Chinese by Lilidream.

uniform float HDRPower <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 8.0;
	ui_label = "力度";
> = 1.30;
uniform float radius1 <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 8.0;
	ui_label = "半径 1";
> = 0.793;
uniform float radius2 <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 8.0;
	ui_label = "半径 2";
	ui_tooltip = "提高这个使效果对比度与亮度更大。";
> = 0.87;

#include "ReShade.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

float3 HDRPass(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	const float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;

	float3 bloom_sum1 = tex2D(ReShade::BackBuffer, texcoord + float2(1.5, -1.5) * radius1).rgb;
	bloom_sum1 += tex2D(ReShade::BackBuffer, texcoord + float2(-1.5, -1.5) * radius1).rgb;
	bloom_sum1 += tex2D(ReShade::BackBuffer, texcoord + float2( 1.5,  1.5) * radius1).rgb;
	bloom_sum1 += tex2D(ReShade::BackBuffer, texcoord + float2(-1.5,  1.5) * radius1).rgb;
	bloom_sum1 += tex2D(ReShade::BackBuffer, texcoord + float2( 0.0, -2.5) * radius1).rgb;
	bloom_sum1 += tex2D(ReShade::BackBuffer, texcoord + float2( 0.0,  2.5) * radius1).rgb;
	bloom_sum1 += tex2D(ReShade::BackBuffer, texcoord + float2(-2.5,  0.0) * radius1).rgb;
	bloom_sum1 += tex2D(ReShade::BackBuffer, texcoord + float2( 2.5,  0.0) * radius1).rgb;

	bloom_sum1 *= 0.005;

	float3 bloom_sum2 = tex2D(ReShade::BackBuffer, texcoord + float2(1.5, -1.5) * radius2).rgb;
	bloom_sum2 += tex2D(ReShade::BackBuffer, texcoord + float2(-1.5, -1.5) * radius2).rgb;
	bloom_sum2 += tex2D(ReShade::BackBuffer, texcoord + float2( 1.5,  1.5) * radius2).rgb;
	bloom_sum2 += tex2D(ReShade::BackBuffer, texcoord + float2(-1.5,  1.5) * radius2).rgb;
	bloom_sum2 += tex2D(ReShade::BackBuffer, texcoord + float2( 0.0, -2.5) * radius2).rgb;	
	bloom_sum2 += tex2D(ReShade::BackBuffer, texcoord + float2( 0.0,  2.5) * radius2).rgb;
	bloom_sum2 += tex2D(ReShade::BackBuffer, texcoord + float2(-2.5,  0.0) * radius2).rgb;
	bloom_sum2 += tex2D(ReShade::BackBuffer, texcoord + float2( 2.5,  0.0) * radius2).rgb;

	bloom_sum2 *= 0.010;

	const float dist = radius2 - radius1;
	const float3 HDR = (color + (bloom_sum2 - bloom_sum1)) * dist;
	const float3 blend = HDR + color;
	 
	// pow - don't use fractions for HDRpower
#if GSHADE_DITHER
	const float3 outcolor = saturate(pow(abs(blend), HDRPower) + HDR);
	return outcolor + TriDither(outcolor, texcoord, BUFFER_COLOR_BIT_DEPTH);
#else
	return saturate(pow(abs(blend), HDRPower) + HDR);
#endif
}

technique HDR <ui_label="高动态范围(HDR)";>
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = HDRPass;
	}
}
