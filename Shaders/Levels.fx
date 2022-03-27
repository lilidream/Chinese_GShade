/**
 * Levels version 1.2
 * by Christian Cann Schuldt Jensen ~ CeeJay.dk
 *
 * Allows you to set a new black and a white level.
 * This increases contrast, but clips any colors outside the new range to either black or white
 * and so some details in the shadows or highlights can be lost.
 *
 * The shader is very useful for expanding the 16-235 TV range to 0-255 PC range.
 * You might need it if you're playing a game meant to display on a TV with an emulator that does not do this.
 * But it's also a quick and easy way to uniformly increase the contrast of an image.
 *
 * -- Version 1.0 --
 * First release
 * -- Version 1.1 --
 * Optimized to only use 1 instruction (down from 2 - a 100% performance increase :) )
 * -- Version 1.2 --
 * Added the ability to highlight clipping regions of the image with #define HighlightClipping 1
 */
 // Lightly optimized by Marot Satil for the GShade project.
 // Translation of the UI into Chinese by Lilidream.

uniform int BlackPoint <
	ui_type = "slider";
	ui_min = 0; ui_max = 255;
	ui_label = "黑点";
	ui_tooltip = "黑点是新的黑色--字面上的意思。一切比这更暗的东西都将变成完全的黑色。";
> = 16;

uniform int WhitePoint <
	ui_type = "slider";
	ui_min = 0; ui_max = 255;
	ui_label = "白点";
	ui_tooltip = "新的白点。所有比这更亮的东西都变成了完全的白色";
> = 235;

uniform bool HighlightClipping <
	ui_label = "高光裁切像素";
	ui_tooltip = "两点之间的颜色会被拉伸，从而增加对比度，但点上和点下的细节会丢失（这被称为裁切）。这个设置可以标记出剪辑的像素。\n"
		"红色: 一些细节会在高光中丢失\n"
		"黄色: 所有细节会在高光中丢失\n"
		"蓝色: 一些细节会在阴影中丢失\n"
		"青色: 所有细节会在阴影中丢失。";
> = false;

#include "ReShade.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

float3 LevelsPass(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	const float black_point_float = BlackPoint / 255.0;

	float white_point_float;
	// Avoid division by zero if the white and black point are the same
	if (WhitePoint == BlackPoint)
		white_point_float = (255.0 / 0.00025);
	else
		white_point_float = 255.0 / (WhitePoint - BlackPoint);

	float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;
	color = color * white_point_float - (black_point_float *  white_point_float);

	if (HighlightClipping)
	{
		float3 clipped_colors;

		// any colors whiter than white?
		if (any(color > saturate(color)))
			clipped_colors = float3(1.0, 0.0, 0.0);
		else
			clipped_colors = color;

		// all colors whiter than white?
		if (all(color > saturate(color)))
			clipped_colors = float3(1.0, 1.0, 0.0);

		// any colors blacker than black?
		if (any(color < saturate(color)))
			clipped_colors = float3(0.0, 0.0, 1.0);

		// all colors blacker than black?
		if (all(color < saturate(color)))
			clipped_colors = float3(0.0, 1.0, 1.0);

		color = clipped_colors;
	}

#if GSHADE_DITHER
	return color + TriDither(color, texcoord, BUFFER_COLOR_BIT_DEPTH);
#else
	return color;
#endif
}

technique Levels <ui_label="色阶";>
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = LevelsPass;
	}
}
