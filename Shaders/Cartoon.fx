/**
 * Cartoon
 * by Christian Cann Schuldt Jensen ~ CeeJay.dk
 */
 // Lightly optimized by Marot Satil for the GShade project.
 // Translation of the UI into Chinese by Lilidream.

uniform float Power <
	ui_label = "强度";
	ui_type = "slider";
	ui_min = 0.1; ui_max = 10.0;
	ui_tooltip = "你想要的效果强度";
> = 1.5;
uniform float EdgeSlope <
	ui_type = "slider";
	ui_min = 0.1; ui_max = 6.0;
	ui_label = "边缘斜率";
	ui_tooltip = "提高此值来过滤不明显边缘，你可能需要提高效果强度来进行补偿。整数比较快。";
> = 1.5;

#include "ReShade.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

float3 CartoonPass(float4 position : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	const float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;
	const float3 coefLuma = float3(0.2126, 0.7152, 0.0722);

	float diff1 = dot(coefLuma, tex2D(ReShade::BackBuffer, texcoord + BUFFER_PIXEL_SIZE).rgb);
	diff1 = dot(float4(coefLuma, -1.0), float4(tex2D(ReShade::BackBuffer, texcoord - BUFFER_PIXEL_SIZE).rgb , diff1));
	float diff2 = dot(coefLuma, tex2D(ReShade::BackBuffer, texcoord + BUFFER_PIXEL_SIZE * float2(1, -1)).rgb);
	diff2 = dot(float4(coefLuma, -1.0), float4(tex2D(ReShade::BackBuffer, texcoord + BUFFER_PIXEL_SIZE * float2(-1, 1)).rgb , diff2));

	const float edge = dot(float2(diff1, diff2), float2(diff1, diff2));

#if GSHADE_DITHER
	const float3 outcolor = saturate(pow(abs(edge), EdgeSlope) * -Power + color);
	return outcolor + TriDither(outcolor, texcoord, BUFFER_COLOR_BIT_DEPTH);
#else
	return saturate(pow(abs(edge), EdgeSlope) * -Power + color);
#endif
}

technique Cartoon <ui_label = "卡通";>
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = CartoonPass;
	}
}
