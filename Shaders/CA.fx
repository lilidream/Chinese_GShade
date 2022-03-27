/**
 * Chromatic Aberration
 * by Christian Cann Schuldt Jensen ~ CeeJay.dk
 *
 * Distorts the image by shifting each color component, which creates color artifacts similar to those in a very cheap lens or a cheap sensor.
 *
 * Updated for Reshade 4.0
 *
 * Translation of the UI into Chinese by Lilidream.
 */

uniform float2 Shift <
	ui_label = "偏移";
	ui_type = "slider";
	ui_min = -10; ui_max = 10;
	ui_tooltip = "以像素为单位的(X,Y)来偏移颜色成分，对于轻微模糊效果请尝试使用两像素之间的小数值(0.5)";
> = float2(2.5, -0.5);
uniform float Strength <
	ui_label = "强度";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
> = 0.5;

#include "ReShade.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

float3 ChromaticAberrationPass(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float3 color, colorInput = tex2D(ReShade::BackBuffer, texcoord).rgb;
	// Sample the color components
	color.r = tex2D(ReShade::BackBuffer, texcoord + (BUFFER_PIXEL_SIZE * Shift)).r;
	color.g = colorInput.g;
	color.b = tex2D(ReShade::BackBuffer, texcoord - (BUFFER_PIXEL_SIZE * Shift)).b;

	// Adjust the strength of the effect
#if GSHADE_DITHER
	color = lerp(colorInput, color, Strength);
	return color + TriDither(color, texcoord, BUFFER_COLOR_BIT_DEPTH);
#else
	return lerp(colorInput, color, Strength);
#endif
}

technique CAb <ui_label="色差";>
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = ChromaticAberrationPass;
	}
}
