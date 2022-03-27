//////////////////////////////////////////////////////////////////
// This effect works like a simple DoF for desaturating what otherwise would have been blurred.
//
// It works by determining whether a pixel is outside the emphasize zone using the depth buffer
// if so, the pixel is desaturated and blended with the color specified in the cfg file. 
///////////////////////////////////////////////////////////////////
// Main shader by Otis / Infuse Project
// 3D emphasis code by SirCobra. 
///////////////////////////////////////////////////////////////////
// Translation of the UI into Chinese by Lilidream.
uniform float FocusDepth <
	ui_label = "焦点深度";
	ui_type = "slider";
	ui_min = 0.000; ui_max = 1.000;
	ui_step = 0.001;
	ui_tooltip = "手动设置对焦点深度。0表示镜头位置，1表示无限远。";
> = 0.026;
uniform float FocusRangeDepth <
	ui_label = "焦点范围深度";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.000;
	ui_step = 0.001;
	ui_tooltip = "手动对焦深度的强度范围深度。在此范围外，添加反强度效果。";
> = 0.001;
uniform float FocusEdgeDepth <
	ui_label = "焦点边缘深度";
	ui_type = "slider";
	ui_min = 0.000; ui_max = 1.000;
	ui_tooltip = "焦点范围的边缘深度。焦点范围边缘过渡的平滑深度。";
	ui_step = 0.001;
> = 0.050;
uniform bool Spherical <
	ui_label = "球形";
	ui_tooltip = "强调区域为球形而不是平面";
> = false;
uniform int Sphere_FieldOfView <
	ui_label = "球形视角";
	ui_type = "slider";
	ui_min = 1; ui_max = 180;
	ui_tooltip = "设置你当前游戏估计的视角大小。以度为单位。";
> = 75;
uniform float Sphere_FocusHorizontal <
	ui_label = "球形水平焦点";
	ui_type = "slider";
	ui_min = 0; ui_max = 1;
	ui_tooltip = "设置水平轴上的焦点位置。0表示左屏幕边缘，1表示右屏幕边缘。";
> = 0.5;
uniform float Sphere_FocusVertical <
	ui_label = "球形垂直焦点";
	ui_type = "slider";
	ui_min = 0; ui_max = 1;
	ui_tooltip = "设置垂直轴上的焦点位置。0表示上屏幕边缘，1表示下屏幕边缘。";
> = 0.5;
uniform float3 BlendColor <
	ui_label = "混合颜色";
	ui_type = "color";
	ui_tooltip = "设置灰度混合颜色。使用暗色来让远处物体变暗。";
> = float3(0.0, 0.0, 0.0);
uniform float BlendFactor <
	ui_label = "混合因子";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_tooltip = "设置混合颜色的混合的因子。0代表完全黑白，1代表完全为混合颜色。";
> = 0.0;
uniform float EffectFactor <
	ui_label = "效果因子";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_tooltip = "设置应用的去饱和度因子。0表示效果关闭，1表示去饱和部分变为全黑白。";
> = 0.9;

#include "ReShade.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

#ifndef M_PI
	#define M_PI 3.1415927
#endif

float CalculateDepthDiffCoC(float2 texcoord : TEXCOORD)
{
	const float scenedepth = ReShade::GetLinearizedDepth(texcoord);
	const float scenefocus =  FocusDepth;
	const float desaturateFullRange = FocusRangeDepth+FocusEdgeDepth;
	float depthdiff;
	
	if(Spherical == true)
	{
		texcoord.x = (texcoord.x-Sphere_FocusHorizontal)*BUFFER_WIDTH;
		texcoord.y = (texcoord.y-Sphere_FocusVertical)*BUFFER_HEIGHT;
		const float degreePerPixel = Sphere_FieldOfView*BUFFER_RCP_WIDTH;
		const float fovDifference = sqrt((texcoord.x*texcoord.x)+(texcoord.y*texcoord.y))*degreePerPixel;
		depthdiff = sqrt((scenedepth*scenedepth)+(scenefocus*scenefocus)-(2*scenedepth*scenefocus*cos(fovDifference*(2*M_PI/360))));
	}
	else
	{
		depthdiff = abs(scenedepth-scenefocus);
	}

	if (depthdiff > desaturateFullRange)
		return saturate(1.0);
	else
		return saturate(smoothstep(0, desaturateFullRange, depthdiff));
}

void PS_Otis_EMZ_Desaturate(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 outFragment : SV_Target)
{
	const float depthDiffCoC = CalculateDepthDiffCoC(texcoord.xy);	
	const float4 colFragment = tex2D(ReShade::BackBuffer, texcoord);
	const float greyscaleAverage = (colFragment.x + colFragment.y + colFragment.z) / 3.0;
	float4 desColor = float4(greyscaleAverage, greyscaleAverage, greyscaleAverage, depthDiffCoC);
	desColor = lerp(desColor, float4(BlendColor, depthDiffCoC), BlendFactor);
	outFragment = lerp(colFragment, desColor, saturate(depthDiffCoC * EffectFactor));

#if GSHADE_DITHER
	outFragment.rgb += TriDither(outFragment.rgb, texcoord, BUFFER_COLOR_BIT_DEPTH);
#endif
}

technique Emphasize <ui_label="强调";>
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_Otis_EMZ_Desaturate;
	}
}
