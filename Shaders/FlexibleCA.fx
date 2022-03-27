// Translation of the UI into Chinese by Lilidream.
//#region Preprocessor

#include "ReShade.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

//#endregion

//#region Uniforms

uniform int Mode
<
	ui_type = "combo";
	ui_text =
		"如何使用: \n"
		"首先，通过设置模式，选择你想使用的色差种类。检查它的描述以了解细节。\n"
		"其次，定义比例。这可以控制色差的颜色。\n"
		"最后，通过设置倍数来设定色差的大小。"
		" ";
	ui_tooltip =
		"模式定义色差是如何产生。\n"
		"移动: 在水平和垂直方向上移动通道。缩放: 将通道从中心放大。默认: 缩放";
	ui_items = "移动\0缩放\0";
> = 1;

uniform float3 Ratio
<
	ui_type = "slider";
	ui_tooltip =
		"每个通道的失真程度的比例。这些值分别控制红色、绿色和蓝色通道。\n"
		"\n"
		"默认: -1.0 0.0 1.0";
	ui_min = -1.0;
	ui_max = 1.0;
> = float3(-1.0, 0.0, 1.0);

uniform float Multiplier
<
	ui_type = "slider";
	ui_tooltip =
		"比例的倍数，控制失真程度。\n"
		"\n"
		"默认: 1.0";
	ui_min = 0.0;
	ui_max = 6.0;
	ui_step = 0.001;
> = 1.0;

//#endregion

//#region Functions

float2 scale_uv(float2 uv, float2 scale, float2 center)
{
	return (uv - center) * scale + center;
}

//#endregion

//#region Shaders

float4 MainPS(float4 p : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET
{
	const float2 ps = ReShade::PixelSize;

	float2 uv_r = uv;
	float2 uv_g = uv;
	float2 uv_b = uv;

	float3 ratio;

	switch (Mode)
	{
		case 0: // Translate
			ratio = Ratio * Multiplier;

			uv_r += ps * ratio.r;
			uv_g += ps * ratio.g;
			uv_b += ps * ratio.b;
			break;
		case 1: // Scale
			ratio = Multiplier * length(ps) + 1.0;
			ratio = lerp(ratio, 1.0 / ratio, Ratio * 0.5 + 0.5);

			uv_r = scale_uv(uv_r, ratio.r, 0.5);
			uv_g = scale_uv(uv_g, ratio.g, 0.5);
			uv_b = scale_uv(uv_b, ratio.b, 0.5);
			break;
	}

	const float3 color = float3(
		tex2D(ReShade::BackBuffer, uv_r).r,
		tex2D(ReShade::BackBuffer, uv_g).g,
		tex2D(ReShade::BackBuffer, uv_b).b);

#if GSHADE_DITHER
	return float4(color + TriDither(color, uv, BUFFER_COLOR_BIT_DEPTH), 1.0);
#else
	return float4(color, 1.0);
#endif
}

//#endregion

//#region Technique

technique FlexibleCA <ui_label = "可变色差";>
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = MainPS;
	}
}

//#endregion