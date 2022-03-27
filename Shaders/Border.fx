/**
 * Border version 1.4.2
 *
 * -- Version 1.0 by Oomek --
 * Fixes light, one pixel thick border in some games when forcing MSAA like i.e. Dishonored
 * -- Version 1.1 by CeeJay.dk --
 * Optimized the shader. It still does the same but now it runs faster.
 * -- Version 1.2 by CeeJay.dk --
 * Added border_width and border_color features
 * -- Version 1.3 by CeeJay.dk --
 * Optimized the performance further
 * -- Version 1.4 by CeeJay.dk --
 * Added the border_ratio feature
 * -- Version 1.4.1 by CeeJay.dk --
 * Cleaned up setting for Reshade 3.x
 * -- Version 1.4.2 by Marot --
 * Added opacity slider & modified for Reshade 4.0 compatibility.
 *
 * Translation of the UI into Chinese by Lilidream.
 */

#include "ReShade.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

uniform float2 border_width <
	ui_type = "slider";
	ui_label = "大小";
	ui_tooltip = "以像素为单位。如果设置为0则会使用比例";
	ui_min = 0.0; ui_max = (BUFFER_WIDTH * 0.5);
	ui_step = 1.0;
	> = float2(0.0, 1.0);

uniform float border_ratio <
	ui_type = "input";
	ui_label = "大小比例";
	ui_tooltip = "设置可视区域为想要的比例";
> = 2.35;

uniform float4 border_color <
	ui_type = "color";
	ui_label = "边框颜色";
> = float4(0.7, 0.0, 0.0, 1.0);

float3 BorderPass(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	const float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;
	// -- calculate the right border_width for a given border_ratio --
	float2 border_width_variable = border_width;
	if (border_width.x == -border_width.y) // If width is not used
		if (BUFFER_ASPECT_RATIO < border_ratio)
			border_width_variable = float2(0.0, (BUFFER_HEIGHT - (BUFFER_WIDTH / border_ratio)) * 0.5);
		else
			border_width_variable = float2((BUFFER_WIDTH - (BUFFER_HEIGHT * border_ratio)) * 0.5, 0.0);

	const float2 border = (BUFFER_PIXEL_SIZE * border_width_variable); // Translate integer pixel width to floating point

	if (all(saturate((-texcoord * texcoord + texcoord) - (-border * border + border)))) // Becomes positive when inside the border and zero when outside
	{
#if GSHADE_DITHER
		return color + TriDither(color, texcoord, BUFFER_COLOR_BIT_DEPTH);
#else
		return color;
#endif
	}
	else
	{
#if GSHADE_DITHER
		const float3 outcolor = lerp(color, border_color.rgb, border_color.a);
		return outcolor + TriDither(outcolor, texcoord, BUFFER_COLOR_BIT_DEPTH);
#else
		return lerp(color, border_color.rgb, border_color.a);
#endif
	}
}

technique Border <ui_label="边框";>
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = BorderPass;
	}
}
