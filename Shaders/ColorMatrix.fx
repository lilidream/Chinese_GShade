/**
 * Color Matrix version 1.0
 * by Christian Cann Schuldt Jensen ~ CeeJay.dk
 *
 * ColorMatrix allow the user to transform the colors using a color matrix
 */
 // Lightly optimized by Marot Satil for the GShade project.
// Translation of the UI into Chinese by Lilidream.

uniform float3 ColorMatrix_Red <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "红色矩阵";
	ui_tooltip = "新的红色值应该包含多少红色、绿色和蓝色的色调。如果你不希望改变亮度，总和应该是1.0。";
> = float3(0.817, 0.183, 0.000);
uniform float3 ColorMatrix_Green <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "绿色矩阵";
	ui_tooltip = "新的绿色值应该包含多少红色、绿色和蓝色的色调。如果你不希望改变亮度，总和应该是1.0。";
> = float3(0.333, 0.667, 0.000);
uniform float3 ColorMatrix_Blue <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "蓝色矩阵";
	ui_tooltip = "新的蓝色值应该包含多少红色、绿色和蓝色的色调。如果你不希望改变亮度，总和应该是1.0。";
> = float3(0.000, 0.125, 0.875);

uniform float Strength <
	ui_label = "强度";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
> = 1.0;

#include "ReShade.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

float3 ColorMatrixPass(float4 position : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	const float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;

	const float3x3 ColorMatrix = float3x3(ColorMatrix_Red, ColorMatrix_Green, ColorMatrix_Blue);

#if GSHADE_DITHER
	const float3 outcolor = saturate(lerp(color, mul(ColorMatrix, color), Strength));
	return outcolor + TriDither(outcolor, texcoord, BUFFER_COLOR_BIT_DEPTH);
#else
	return saturate(lerp(color, mul(ColorMatrix, color), Strength));
#endif
}

technique ColorMatrix <ui_label="色彩矩阵";>
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = ColorMatrixPass;
	}
}
