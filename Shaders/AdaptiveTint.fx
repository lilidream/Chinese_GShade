/*******************************************************
	ReShade Shader: Adaptive Tint
	https://github.com/Daodan317081/reshade-shaders
	Modified by Marot for ReShade 4.0 compatibility and optimized for the GShade project.
	Translation of the UI into Chinese by Lilidream.
*******************************************************/

#include "ReShade.fxh"
#include "Stats.fxh"
#include "Tools.fxh"
#include "Canvas.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

#ifndef UI_ADAPTIVE_TINT_DEBUG_WINDOW_WIDTH
	#define UI_ADAPTIVE_TINT_DEBUG_WINDOW_WIDTH 300
#endif

#define UI_CATEGORY_CURVES "曲线"
#define UI_CATEGORY_COLOR "颜色"
#define UI_CATEGORY_DEBUG "Debug"
#define UI_CATEGORY_GENERAL "一般设置"
#define UI_TOOLTIP_DEBUG "启用着色器'AdaptiveTintDebug'\n定义自适应色调Debug窗口=xyz\n默认宽度为300"

uniform int iUIInfo<
	ui_type = "combo";
	ui_label = "Info";
	ui_items = "Info\0";
	ui_tooltip = "激活 Technique 'CalculateStats_MoveToTop'";
> = 0;

uniform int ChineseInfo<
	ui_type = "combo";
	ui_label = "着色器说明";
	ui_items = "说明\0";
	ui_tooltip = "通过调整黑白两条曲线，与整体画面平均亮度计算得到调整遮罩，在遮罩内应用冷暖两个LUT滤镜效果。";
> = 0;

uniform int iUIWhiteLevelFormula <
	ui_type = "combo";
	ui_category = UI_CATEGORY_CURVES;
	ui_label = "白色色阶曲线形式(红色线)";
	ui_tooltip = UI_TOOLTIP_DEBUG;
	ui_items = "线性: x * (value - y) + z\0抛物线: x * (value - y)^2 + z\0三次曲线: x * (value - y)^3 + z\0";
> = 1;

uniform float3 f3UICurveWhiteParam <
	ui_type = "slider";
	ui_category = UI_CATEGORY_CURVES;
	ui_label = "曲线参数";
	ui_tooltip = UI_TOOLTIP_DEBUG;
	ui_min = -10.0; ui_max = 10.0;
	ui_step = 0.01;
> = float3(-0.5, 1.0, 1.0);

uniform int iUIBlackLevelFormula <
	ui_type = "combo";
	ui_category = UI_CATEGORY_CURVES;
	ui_label = "黑色色阶曲线形式(青色线)";
	ui_tooltip = UI_TOOLTIP_DEBUG;
	ui_items = "线性: x * (value - y) + z\0抛物线: x * (value - y)^2 + z\0三次曲线: x * (value - y)^3 + z\0";
> = 1;

uniform float3 f3UICurveBlackParam <
	ui_type = "slider";
	ui_category = UI_CATEGORY_CURVES;
	ui_label = "曲线参数";
	ui_tooltip = UI_TOOLTIP_DEBUG;
	ui_min = -10.0; ui_max = 10.0;
	ui_step = 0.01;
> = float3(0.5, 0.0, 0.0);

uniform float fUIColorTempScaling <
	ui_type = "slider";
	ui_category = UI_CATEGORY_CURVES;
	ui_label = "色温范围";
	ui_tooltip = UI_TOOLTIP_DEBUG;
	ui_min = 1.0; ui_max = 10.0;
	ui_step = 0.01;
> = 2.0;

uniform float fUISaturation <
	ui_type = "slider";
	ui_label = "饱和度";
	ui_category = UI_CATEGORY_COLOR;
	ui_min = -1.0; ui_max = 1.0;
	ui_step = 0.001;
> = 0.0;

uniform float3 fUITintWarm <
	ui_type = "color";
	ui_category = UI_CATEGORY_COLOR;
    ui_label = "暖色调";
> = float3(0.04, 0.04, 0.02);

uniform float3 fUITintCold <
	ui_type = "color";
	ui_category = UI_CATEGORY_COLOR;
    ui_label = "冷色调";
> = float3(0.02, 0.04, 0.04);

uniform int iUIDebug <
	ui_type = "combo";
	ui_category = UI_CATEGORY_DEBUG;
	ui_label = "显示色调层";
	ui_items = "Off\0Tint\0Factor\0";
> = 0;

uniform float fUIStrength <
	ui_type = "slider";
	ui_category = UI_CATEGORY_GENERAL;
	ui_label = "强度";
	ui_min = 0.0; ui_max = 1.0;
> = 1.0;


/*******************************************************
	Debug image
*******************************************************/
CANVAS_SETUP(AdaptiveTintDebug, BUFFER_WIDTH/4, BUFFER_HEIGHT/4)

/*******************************************************
	Checkerboard
*******************************************************/
texture2D texAlphaCheckerboard < source = "alpha-checkerboard.png"; > { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
sampler2D SamplerAlphaCheckerboard { Texture = texAlphaCheckerboard; };

/*******************************************************
	Functions
*******************************************************/
float2 CalculateLevels(float avgLuma) {
	float2 level = float2(0.0, 0.0);

	if(iUIBlackLevelFormula == 2)
		level.x = f3UICurveBlackParam.x * pow(avgLuma - f3UICurveBlackParam.y, 3) + f3UICurveBlackParam.z;
	else if(iUIBlackLevelFormula == 1)
		level.x = f3UICurveBlackParam.x * ((avgLuma - f3UICurveBlackParam.y) * 2) + f3UICurveBlackParam.z;
	else
		level.x = f3UICurveBlackParam.x * (avgLuma - f3UICurveBlackParam.y) + f3UICurveBlackParam.z;
	
	if(iUIWhiteLevelFormula == 2)
		level.y = f3UICurveWhiteParam.x * pow(avgLuma - f3UICurveWhiteParam.y, 3) + f3UICurveWhiteParam.z;
	else if(iUIWhiteLevelFormula == 1)
		level.y = f3UICurveWhiteParam.x * ((avgLuma - f3UICurveWhiteParam.y) * 2) + f3UICurveWhiteParam.z;
	else
		level.y = f3UICurveWhiteParam.x * (avgLuma - f3UICurveWhiteParam.y) + f3UICurveWhiteParam.z;

	return saturate(level);
}

float GetColorTemp(float2 texcoord) {
	const float colorTemp = Stats::AverageColorTemp();
	return Tools::Functions::Map(colorTemp * fUIColorTempScaling, YIQ_I_RANGE, FLOAT_RANGE);
}

/*******************************************************
	Main Shader
*******************************************************/
float3 AdaptiveTint_PS(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	/*******************************************************
		Get BackBuffer and both LUTs
	*******************************************************/
	const float3 backbuffer = tex2D(ReShade::BackBuffer, texcoord).rgb;
	const float3 lutWarm = fUITintWarm * backbuffer;
	const float3 lutCold = fUITintCold * backbuffer;

	/*******************************************************
		Interpolate between both LUTs
	*******************************************************/
	const float colorTemp = GetColorTemp(texcoord);
	const float3 tint = lerp(lutCold, lutWarm, colorTemp);

	/*******************************************************
		Apply black and white levels to luma, desaturate
	*******************************************************/
	const float3 luma   = dot(backbuffer, LumaCoeff).rrr;
	const float2 levels = CalculateLevels(Stats::AverageLuma());
	const float3 factor = Tools::Functions::Level(luma.r, levels.x, levels.y).rrr;
	const float3 result = lerp(tint, lerp(luma, backbuffer, fUISaturation + 1.0), factor);

	/*******************************************************
		Debug
	*******************************************************/
	if(iUIDebug == 1) //tint
		return lerp(tint, tex2D(SamplerAlphaCheckerboard, texcoord).rgb, factor);
	if(iUIDebug == 2) //factor
		return lerp(BLACK, WHITE, factor);

#if GSHADE_DITHER
    const float3 color = lerp(backbuffer, result, fUIStrength);
	return color + TriDither(color, texcoord, BUFFER_COLOR_BIT_DEPTH);
#else
	return lerp(backbuffer, result, fUIStrength);
#endif
}

/*******************************************************
	Generate small image for shader debug/setup
*******************************************************/

CANVAS_DRAW_BEGIN(AdaptiveTintDebug, 0.0.rrr;);
	const float3 originalBackBuffer = Stats::OriginalBackBuffer(texcoord);
	const float3 originalLuma = dot(originalBackBuffer, LumaCoeff).xxx;
	const float avgLuma = Stats::AverageLuma();
	const float3 avgColor = Stats::AverageColor();
	const float2 curves = CalculateLevels(texcoord.x);
	const float2 levels = CalculateLevels(avgLuma);
	const float3 localFactor = saturate(Tools::Functions::Level(originalLuma.r, levels.x, levels.y).rrr);

    CANVAS_DRAW_BACKGROUND(AdaptiveTintDebug, localFactor);
	CANVAS_DRAW_SCALE(AdaptiveTintDebug, RED, BLUE, int2(0, 10), int2(10, BUFFER_HEIGHT/4-10), GetColorTemp(texcoord), BLACK);
	CANVAS_DRAW_SCALE(AdaptiveTintDebug, BLACK, WHITE, int2(10, 0), int2(BUFFER_WIDTH/4-10, 10), avgLuma, MAGENTA);
	CANVAS_DRAW_BOX(AdaptiveTintDebug, avgColor, int2(0, 0), int2(10, 10));
    CANVAS_DRAW_CURVE_XY(AdaptiveTintDebug, RED, curves.y);
    CANVAS_DRAW_CURVE_XY(AdaptiveTintDebug, CYAN, curves.x);
CANVAS_DRAW_END(AdaptiveTintDebug);

technique AdaptiveTint <ui_label="自适应色调";>
{
	pass {
		VertexShader = PostProcessVS;
		PixelShader = AdaptiveTint_PS;
	}
}

CANVAS_TECHNIQUE(AdaptiveTintDebug)