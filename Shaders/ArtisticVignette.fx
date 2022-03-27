//#region Includes

#include "ReShade.fxh"
#include "Blending.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

//#endregion
// Translation of the UI into Chinese by Lilidream.
//#region Constants

static const float Pi = 3.14159;
static const float HalfPi = Pi * 0.5;

static const int BlendMode_Mix = 0;
static const int BlendMode_Multiply = 1;
static const int BlendMode_DarkenOnly = 2;
static const int BlendMode_LightenOnly = 3;
static const int BlendMode_Overlay = 4;
static const int BlendMode_Screen = 5;
static const int BlendMode_HardLight = 6;
static const int BlendMode_SoftLight = 7;

static const int VignetteShape_None = 0;
static const int VignetteShape_Radial = 1;
static const int VignetteShape_TopBottom = 2;
static const int VignetteShape_LeftRight = 3;
static const int VignetteShape_Box = 4;
static const int VignetteShape_Sky = 5;
static const int VignetteShape_Ground = 6;

//#endregion

//#region Uniforms

uniform int _Help
<
	ui_text ="此特效为画面添加一个可调节的暗角图层。\n将鼠标移动到各个选项上可显示其帮助。\n暗角可通过颜色、Alpha 透明图层和混合模式调节，就像 Photoshop 或 GIMP。\n通过调节比例和渐变点可实现多种形状的暗角。";
	ui_category = "帮助";
	ui_category_closed = true;
	ui_label = " ";
	ui_type = "radio";
>;

uniform float4 VignetteColor
<
	ui_type = "color";
	ui_label = "颜色";
	ui_tooltip =
		"暗角颜色。\n"
		"支持通过Alpha通道调整透明度。\n"
		"\n默认: 0 0 0 255";
	ui_category = "外观";
> = float4(0.0, 0.0, 0.0, 1.0);

BLENDING_COMBO(BlendMode, "混合模式", "决定暗角层与图像的融合模式\n\n默认: 混合", "外观", false, 0, 0)

uniform float2 VignetteStartEnd
<
	ui_type = "slider";
	ui_label = "开始点/结束点";
	ui_tooltip =
		"暗角渐变的开始点与结束点。\n"
		"距离越长，暗角效果越柔和。\n"
		"\n默认: 0.0 1.0";
	ui_category = "形状";
	ui_min = 0.0;
	ui_max = 3.0;
	ui_step = 0.01;
> = float2(0.0, 1.0);

uniform float VignetteDepth
<
	ui_type = "slider";
	ui_label = "空间深度";
	ui_tooltip =
		"效果应用位置离镜头距离。\n"
		"值越低，暗角效果离镜头越远。\n"
		"\n默认: 1.0";
	ui_category = "形状";
	ui_min = 0.0;
	ui_max = 1.0;
	ui_step = 0.0001;
> = 1.0;

uniform float VignetteRatio
<
	ui_type = "slider";
	ui_label = "比例";
	ui_tooltip =
		"暗角形状的比例。\n"
		"0.0: 宽屏。\n"
		"1.0: 正形。\n"
		"\n"
		"例如，1.0是圆形。\n"
		"\n默认: 0.0";
	ui_category = "形状";
	ui_min = 0.0;
	ui_max = 1.0;
> = 0.0;

uniform int VignetteShape
<
	ui_type = "combo";
	ui_label = "形状";
	ui_tooltip =
		"暗角形状\n"
		"\n默认: 放射形";
	ui_category = "形状";
	ui_items = "无\0放射形\0顶部/底部\0左/右\0矩形\0天空\0地面\0";
> = 1;

//#endregion

//#region Shaders

float4 MainPS(float4 p : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET
{
	const float4 color = tex2D(ReShade::BackBuffer, uv);
	const float depth = 1 - ReShade::GetLinearizedDepth(uv).r;
	if (depth < VignetteDepth)
	{
		if (ReShade::AspectRatio > 1.0)
			const float2 ratio = float2(BUFFER_WIDTH * BUFFER_RCP_HEIGHT, 1.0);
		else
			const float2 ratio = float2(1.0, BUFFER_HEIGHT * BUFFER_RCP_WIDTH);

		uv = lerp(uv, (uv - 0.5) * ratio + 0.5, VignetteRatio);

		float vignette = 1.0;

		switch (VignetteShape)
		{
			case VignetteShape_Radial:
				vignette = distance(0.5, uv) * HalfPi;
				break;
			case VignetteShape_TopBottom:
				vignette = abs(uv.y - 0.5) * 2.0;
				break;
			case VignetteShape_LeftRight:
				vignette = abs(uv.x - 0.5) * 2.0;
				break;
			case VignetteShape_Box:
				float2 vig = abs(uv - 0.5) * 2.0;
				vignette = max(vig.x, vig.y);
				break;
			case VignetteShape_Sky:
				vignette = distance(float2(0.5, 1.0), uv);
				break;
			case VignetteShape_Ground:
				vignette = distance(float2(0.5, 0.0), uv);
				break;
		}

		vignette = smoothstep(VignetteStartEnd.x, VignetteStartEnd.y, vignette);

#if GSHADE_DITHER
		const float3 vig_color = ComHeaders::Blending::Blend(BlendMode, color.rgb, VignetteColor.rgb, vignette * VignetteColor.a);

		return float4(vig_color + TriDither(vig_color, uv, BUFFER_COLOR_BIT_DEPTH), color.a);
#else
		return float4(ComHeaders::Blending::Blend(BlendMode, color.rgb, VignetteColor.rgb, vignette * VignetteColor.a), color.a);
#endif
	}
	else
	{
#if GSHADE_DITHER
		return float4(color.rgb + TriDither(color.rgb, uv, BUFFER_COLOR_BIT_DEPTH), color.a);
#else
		return color;
#endif
	}
}

//#endregion

//#region Technique

technique ArtisticVignette
<
	ui_tooltip =
		"拥有可变形状与混合模式的漂亮暗角效果"
		;
	ui_label = "艺术暗角";
>
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = MainPS;
	}
}

//#endregion