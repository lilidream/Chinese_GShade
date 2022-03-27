//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//LICENSE AGREEMENT AND DISTRIBUTION RULES:
//1 Copyrights of the Master Effect exclusively belongs to author - Gilcher Pascal aka Marty McFly.
//2 Master Effect (the SOFTWARE) is DonateWare application, which means you may or may not pay for this software to the author as donation.
//3 If included in ENB presets, credit the author (Gilcher Pascal aka Marty McFly).
//4 Software provided "AS IS", without warranty of any kind, use it on your own risk. 
//5 You may use and distribute software in commercial or non-commercial uses. For commercial use it is required to warn about using this software (in credits, on the box or other places). Commercial distribution of software as part of the games without author permission prohibited.
//6 Author can change license agreement for new versions of the software.
//7 All the rights, not described in this license agreement belongs to author.
//8 Using the Master Effect means that user accept the terms of use, described by this license agreement.
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// For more information about license agreement contact me:
// https://www.facebook.com/MartyMcModding
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Advanced Depth of Field 4.21 by Marty McFly 
// Version for release
// Copyright © 2008-2015 Marty McFly
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Credits :: Matso (Matso DOF), PetkaGtA, gp65cj042
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Modified by Marot for ReShade 4.0 compatibility and lightly optimized for the GShade project.
// Translation of the UI into Chinese by Lilidream.

uniform bool DOF_AUTOFOCUS <
	ui_label = "自动对焦";
	ui_tooltip = "基于自动对焦中心附近采样识别的自动对焦。";
	ui_category = "景深";
> = true;
uniform bool DOF_MOUSEDRIVEN_AF <
	ui_label = "鼠标驱动自动对焦";
	ui_tooltip = "使用鼠标驱动自动对焦，如果为1，则跟踪鼠标坐标，否则使用对焦点。";
	ui_category = "景深";
> = false;
uniform float2 DOF_FOCUSPOINT <
	ui_label = "对焦点";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_tooltip = "自动对焦中心的X与Y坐标，坐标轴起始于左上角。";
	ui_category = "景深";
> = float2(0.5, 0.5);
uniform float DOF_FOCUSSAMPLES <
	ui_label = "对焦采样";
	ui_type = "slider";
	ui_min = 3; ui_max = 10;
	ui_tooltip = "调整对焦点周围的采样数量来获得更好地焦平面检测。";
	ui_category = "景深";
> = 6;
uniform float DOF_FOCUSRADIUS <
	ui_label = "对焦采样半径";
	ui_type = "slider";
	ui_min = 0.02; ui_max = 0.20;
	ui_tooltip = "对焦点采样半径。";
	ui_category = "景深";
> = 0.05;
uniform float DOF_NEARBLURCURVE <
	ui_label = "近模糊曲线";
	ui_type = "slider";
	ui_min = 0.5; ui_max = 1000.0;
	ui_step = 0.5;
	ui_tooltip = "离焦平面前面的模糊的曲线，值越大模糊越少。";
	ui_category = "景深";
> = 1.60;
uniform float DOF_FARBLURCURVE <
	ui_label = "远模糊曲线";
	ui_type = "slider";
	ui_min = 0.05; ui_max = 5.0;
	ui_tooltip = "离焦平面后面的模糊的曲线，值越大模糊越少。";
	ui_category = "景深";
> = 2.00;
uniform float DOF_MANUALFOCUSDEPTH <
	ui_label = "手动对焦深度";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_tooltip = "自动对焦关闭时的对焦平面深度，0.0表示镜头处，1.0表示无穷远。";
	ui_category = "景深";
> = 0.02;
uniform float DOF_INFINITEFOCUS <
	ui_label = "无穷距离";
	ui_type = "slider";
	ui_min = 0.01; ui_max = 1.0;
	ui_tooltip = "认为是无穷远的深度。标准为1.0\n当对焦物体离镜头很近时，低的数值只产生焦外模糊，推荐游戏时使用。";
	ui_category = "景深";
> = 1.00;
uniform float DOF_BLURRADIUS <
	ui_label = "模糊半径";
	ui_type = "slider";
	ui_min = 2.0; ui_max = 100.0;
	ui_tooltip = "以像素为单位的最大模糊半径";
	ui_category = "景深";
> = 15.0;

// Ring DOF Settings
uniform float iRingDOFSamples <
	ui_label = "采样";
	ui_type = "slider";
	ui_min = 5; ui_max = 30;
	ui_tooltip = "第一圆环的采样。周围的其他圆环有更多的采样。";
	ui_category = "圆环景深";
> = 6;
uniform float iRingDOFRings <
	ui_label = "圆环数";
	ui_type = "slider";
	ui_min = 1; ui_max = 8;
	ui_tooltip = "圆环数";
	ui_category = "圆环景深";
> = 4;
uniform float fRingDOFThreshold <
	ui_label = "阈值";
	ui_type = "slider";
	ui_min = 0.5; ui_max = 3.0;
	ui_tooltip = "散景亮度阈值，大于这个值的散景将变得更亮。\n1.0为LDR游戏例如GTASA的最大值，更高的值只有在HDR游戏有效，例如Skyrim。";
	ui_category = "圆环景深";
> = 0.7;
uniform float fRingDOFGain <
	ui_label = "增益";
	ui_type = "slider";
	ui_min = 0.1; ui_max = 30.0;
	ui_tooltip = "超过阈值的发光增益";
	ui_category = "圆环景深";
> = 27.0;
uniform float fRingDOFBias <
	ui_label = "偏置";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 2.0;
	ui_tooltip = "散景偏置";
	ui_category = "圆环景深";
> = 0.0;
uniform float fRingDOFFringe <
	ui_label = "色差";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_tooltip = "色差数量";
	ui_category = "圆环景深";
> = 0.5;

// Magic DOF Settings
uniform float iMagicDOFBlurQuality <
	ui_label = "模糊质量";
	ui_type = "slider";
	ui_min = 1; ui_max = 30;
	ui_tooltip = "模糊质量是对tap数的控制值。质量为15可产生721个tap，这在其他景深着色器中是不可能的，它们最多只能做到150个。";
	ui_category = "魔法景深";
> = 8;
uniform float fMagicDOFColorCurve <
	ui_label = "颜色曲线";
	ui_type = "slider";
	ui_min = 1.0; ui_max = 10.0;
	ui_tooltip = "景深权重曲线";
	ui_category = "魔法景深";
> = 4.0;

// GP65CJ042 DOF Settings
uniform float iGPDOFQuality <
	ui_label = "质量";
	ui_type = "slider";
	ui_min = 0; ui_max = 7;
	ui_tooltip = "0 = 只有轻微的高斯远模糊但没有散景。1-7 散景模糊, 更高意味着更好地模糊但更低的FPS。";
	ui_category = "GP65CJ042景深";
> = 6;
uniform bool bGPDOFPolygonalBokeh <
	ui_label = "多边形散景";
	ui_tooltip = "开启多边形散景形状。例如多边形边数为5是五边形散景。不选此项则为圆形散景。";
	ui_category = "GP65CJ042景深";
> = true;
uniform float iGPDOFPolygonCount <
	ui_label = "多边形边数";
	ui_type = "slider";
	ui_min = 3; ui_max = 9;
	ui_tooltip = "多边形散景的边数。";
	ui_category = "GP65CJ042景深";
> = 5;
uniform float fGPDOFBias <
	ui_label = "景深偏置";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 20.0;
	ui_tooltip = "调整散景形状边缘的散景权重。设置为0以获得均匀明亮的散景形状，提高它以获得中心较暗的散景形状和边缘较亮的散景形状。";
	ui_category = "GP65CJ042景深";
> = 10.0;
uniform float fGPDOFBiasCurve <
	ui_label = "偏置曲线";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 3.0;
	ui_tooltip = "散景偏置强度。增大来增加散景边界的清晰。";
	ui_category = "GP65CJ042景深";
> = 2.0;
uniform float fGPDOFBrightnessThreshold <
	ui_label = "亮度阈值";
	ui_type = "slider";
	ui_min = 0.5; ui_max = 2.0;
	ui_tooltip = "散景亮度阈值。超过此值，所有东西都会变得更亮。\n1.0为LDR游戏例如GTASA的最大值，更高的值只有在HDR游戏有效，例如Skyrim。";
	ui_category = "GP65CJ042景深";
> = 0.5;
uniform float fGPDOFBrightnessMultiplier <
	ui_label = "亮度倍数";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 2.0;
	ui_tooltip = "超过亮度阈值的像素亮度增强数量。";
	ui_category = "GP65CJ042景深";
> = 2.0;
uniform float fGPDOFChromaAmount <
	ui_label = "色度数量";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 0.4;
	ui_tooltip = "模糊区域的颜色偏移数量。";
	ui_category = "GP65CJ042景深";
> = 0.15;

// MATSO DOF Settings
uniform bool bMatsoDOFChromaEnable <
	ui_label = "色差";
	ui_tooltip = "开启色差";
	ui_category = "Matso景深";
> = true;
uniform float fMatsoDOFChromaPow <
	ui_label = "色差强度";
	ui_type = "slider";
	ui_min = 0.2; ui_max = 3.0;
	ui_tooltip = "色差颜色偏移数量。";
	ui_category = "Matso景深";
> = 1.4;
uniform float fMatsoDOFBokehCurve <
	ui_label = "散景曲线";
	ui_type = "slider";
	ui_min = 0.5; ui_max = 20.0;
	ui_tooltip = "散景曲线";
	ui_category = "Matso景深";
> = 8.0;
uniform float iMatsoDOFBokehQuality <
	ui_label = "散景质量";
	ui_type = "slider";
	ui_min = 1; ui_max = 10;
	ui_tooltip = "散景质量是tap数的控制值。";
	ui_category = "Matso景深";
> = 2;
uniform float fMatsoDOFBokehAngle <
	ui_label = "散景旋转角度";
	ui_type = "slider";
	ui_min = 0; ui_max = 360; ui_step = 1;
	ui_tooltip = "散景的旋转角度";
	ui_category = "Matso景深";
> = 0;

// MCFLY ADVANCED DOF Settings - SHAPE
#ifndef bADOF_ShapeTextureEnable
	#define bADOF_ShapeTextureEnable 0 // Enables the use of a texture overlay. Quite some performance drop.
	#define iADOF_ShapeTextureSize 63 // Higher texture size means less performance. Higher quality integers better work with detailed shape textures. Uneven numbers recommended because even size textures have no center pixel.
#endif

#ifndef iADOF_ShapeVertices
	#if __RENDERER__ <= 0x9300 // Set polygon count of bokeh to 10 for DX9, as the DX9 compiler can't handle computation for values past 10.
		#define iADOF_ShapeVertices 10
	#else
		#define iADOF_ShapeVertices 12 // Polygon count of bokeh shape. 4 = square, 5 = pentagon, 6 = hexagon and so on.
	#endif
#endif

#ifndef iADOF_ShapeVerticesP
  #define iADOF_ShapeVerticesP 5
#endif

#ifndef iADOF_ShapeVerticesD
  #define iADOF_ShapeVerticesD 4
#endif

#ifndef iADOF_ShapeVerticesT
  #define iADOF_ShapeVerticesT 3
#endif


uniform int iADOF_ShapeType <
	ui_label = "形状类型";
	ui_type = "combo";
	ui_items = "圆 (GShade/Angelite)\0五边形 (ReShade 3/4)\0四边形\0三角形\0";
	ui_tooltip = "景深形状";
	ui_category = "MartyMcFly景深";
> = 0;
uniform float iADOF_ShapeQuality <
	ui_label = "形状质量";
	ui_type = "slider";
	ui_min = 1; ui_max = 255;
	ui_tooltip = "景深形状质量等级。更高意味着采取更多的偏移量，更干净的形状，但也意味着更低的性能。编译时间保持不变。";
	ui_category = "MartyMcFly景深";
> = 17;
uniform float fADOF_ShapeRotation <
	ui_label = "形状旋转";
	ui_type = "slider";
	ui_min = 0; ui_max = 360; ui_step = 1;
	ui_tooltip = "散景形状的静态旋转";
	ui_category = "MartyMcFly景深";
> = 15;
uniform bool bADOF_RotAnimationEnable <
	ui_label = "旋转动画";
	ui_tooltip = "开启固定形状的旋转动画";
	ui_category = "MartyMcFly景深";
> = false;
uniform float fADOF_RotAnimationSpeed <
	ui_label = "旋转动画速度";
	ui_type = "slider";
	ui_min = -5; ui_max = 5;
	ui_tooltip = "形状旋转速度。负值为反方向。";
	ui_category = "MartyMcFly景深";
> = 2.0;
uniform bool bADOF_ShapeCurvatureEnable <
	ui_label = "形状弯曲";
	ui_tooltip = "将多边形的边缘向外（或向内）弯曲。顶点大于7的圆形形状最好。";
	ui_category = "MartyMcFly景深";
> = false;
uniform float fADOF_ShapeCurvatureAmount <
	ui_label = "形状弯曲数量";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_tooltip = "形状边缘弯曲数量，1.0为圆形，小于0为星型。";
	ui_category = "MartyMcFly景深";
> = 0.3;
uniform bool bADOF_ShapeApertureEnable <
	ui_label = "光圈形状";
	ui_tooltip = "能够将散景的形状变形为漩涡状的光圈。你试了就知道。对大的散景形状效果最好。";
	ui_category = "MartyMcFly景深";
> = false;
uniform float fADOF_ShapeApertureAmount <
	ui_label = "光圈数";
	ui_type = "slider";
	ui_min = -0.300; ui_max = 0.800;
	ui_tooltip = "变形数量，负值表示镜像。";
	ui_category = "MartyMcFly景深";
> = 0.01;
uniform bool bADOF_ShapeAnamorphEnable <
	ui_label = "失真形状";
	ui_tooltip = "更少的形状水平宽度来模拟电影中的失真。";
	ui_category = "MartyMcFly景深";
> = false;
uniform float fADOF_ShapeAnamorphRatio <
	ui_label = "失真形状比例";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_tooltip = "水平宽度因子。 1.0表示100%宽度，0.0表示0%宽度(散景形状为垂直线)。";
	ui_category = "MartyMcFly景深";
> = 0.2;
uniform bool bADOF_ShapeDistortEnable <
	ui_label = "形状扭曲";
	ui_tooltip = "弯曲屏幕边缘的散景来模拟镜头畸变。屏幕边缘的散景看起来像鸡蛋。";
	ui_category = "MartyMcFly景深";
> = false;
uniform float fADOF_ShapeDistortAmount <
	ui_label = "形状扭曲数量";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_tooltip = "弯曲数量";
	ui_category = "MartyMcFly景深";
> = 0.2;
uniform bool bADOF_ShapeDiffusionEnable <
	ui_label = "形状扩散";
	ui_tooltip = "使得散景的形状有些模糊，使其不那么清晰。";
	ui_category = "MartyMcFly景深";
> = false;
uniform float fADOF_ShapeDiffusionAmount <
	ui_label = "形状扩散数量";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_tooltip = "形状扩散数量，大的值散景看起来像爆炸。";
	ui_category = "MartyMcFly景深";
> = 0.1;
uniform bool bADOF_ShapeWeightEnable <
	ui_label = "形状权重";
	ui_tooltip = "启用散景形状权重偏差，并将颜色转移到形状边界。";
	ui_category = "MartyMcFly景深";
> = false;
uniform float fADOF_ShapeWeightCurve <
	ui_label = "形状权重曲线";
	ui_type = "slider";
	ui_min = 0.5; ui_max = 8.0;
	ui_tooltip = "形状权重偏差曲线";
	ui_category = "MartyMcFly景深";
> = 4.0;
uniform float fADOF_ShapeWeightAmount <
	ui_label = "形状权重数量";
	ui_type = "slider";
	ui_min = 0.5; ui_max = 8.0;
	ui_tooltip = "形状权重偏差数量";
	ui_category = "MartyMcFly景深";
> = 1.0;
uniform float fADOF_BokehCurve <
	ui_label = "散景曲线";
	ui_type = "slider";
	ui_min = 1.0; ui_max = 20.0;
	ui_tooltip = "散景因子，大的值使分散光点产生的散景的边缘更加清晰。";
	ui_category = "MartyMcFly景深";
> = 4.0;

// MCFLY ADVANCED DOF Settings - CHROMATIC ABERRATION
uniform bool bADOF_ShapeChromaEnable <
	ui_tooltip = "Enables chromatic aberration at bokeh shape borders. This means 3 times more samples = less performance.";
	ui_category = "MartyMcFly景深高级设置";
> = false;
uniform int iADOF_ShapeChromaMode <
	ui_type = "combo";
	ui_items = "Mode 1\0Mode 2\0Mode 3\0Mode 4\0Mode 5\0Mode 6\0";
	ui_tooltip = "Switches through the possible R G B shifts.";
	ui_category = "MartyMcFly景深高级设置";
> = 3;
uniform float fADOF_ShapeChromaAmount <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 0.5;
	ui_tooltip = "Amount of color shifting.";
	ui_category = "MartyMcFly景深高级设置";
> = 0.125;
uniform bool bADOF_ImageChromaEnable <
	ui_tooltip = "Enables image chromatic aberration at screen corners.\nThis one is way more complex than the shape chroma (and any other chroma on the web).";
	ui_category = "MartyMcFly景深高级设置";
> = false;
uniform float iADOF_ImageChromaHues <
	ui_type = "slider";
	ui_min = 2; ui_max = 20;
	ui_tooltip = "Amount of samples through the light spectrum to get a smooth gradient.";
	ui_category = "MartyMcFly景深高级设置";
> = 5;
uniform float fADOF_ImageChromaCurve <
	ui_type = "slider";
	ui_min = 0.5; ui_max = 2.0;
	ui_tooltip = "Image chromatic aberration curve. Higher means less chroma at screen center areas.";
	ui_category = "MartyMcFly景深高级设置";
> = 1.0;
uniform float fADOF_ImageChromaAmount <
	ui_type = "slider";
	ui_min = 0.25; ui_max = 10.0;
	ui_tooltip = "Linearly increases image chromatic aberration amount.";
	ui_category = "MartyMcFly景深高级设置";
> = 3.0;

// MCFLY ADVANCED DOF Settings - POSTFX
uniform float fADOF_SmootheningAmount <
	ui_type = "slider";
	ui_min = 0.5; ui_max = 2.0;
	ui_tooltip = "Blur multiplicator of box blur after bokeh to smoothen shape. Box blur is better than gaussian.";
	ui_category = "MartyMcFly景深高级设置";
> = 1.0;

#ifndef bADOF_ImageGrainEnable
	#define bADOF_ImageGrainEnable 0 // Enables some fuzzyness in blurred areas. The more out of focus, the more grain
#endif

#if bADOF_ImageGrainEnable
uniform float fADOF_ImageGrainCurve <
	ui_type = "slider";
	ui_min = 0.5; ui_max = 5.0;
	ui_tooltip = "Curve of Image Grain distribution. Higher values lessen grain at moderately blurred areas.";
	ui_category = "MartyMcFly景深高级设置";
> = 1.0;
uniform float fADOF_ImageGrainAmount <
	ui_type = "slider";
	ui_min = 0.1; ui_max = 2.0;
	ui_tooltip = "Linearly multiplies the amount of Image Grain applied.";
	ui_category = "MartyMcFly景深高级设置";
> = 0.55;
uniform float fADOF_ImageGrainScale <
	ui_type = "slider";
	ui_min = 0.5; ui_max = 2.0;
	ui_tooltip = "Grain texture scale. Low values produce more coarse Noise.";
	ui_category = "MartyMcFly景深高级设置";
> = 1.0;
#endif

/////////////////////////TEXTURES / INTERNAL PARAMETERS/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////TEXTURES / INTERNAL PARAMETERS/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#if bADOF_ImageGrainEnable
texture texNoise < source = "mcnoise.png"; > { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
sampler SamplerNoise { Texture = texNoise; };
#endif
#if bADOF_ShapeTextureEnable
texture texMask < source = "mcmask.png"; > { Width = iADOF_ShapeTextureSize; Height = iADOF_ShapeTextureSize; Format = R8; };
sampler SamplerMask { Texture = texMask; };
#endif

#define DOF_RENDERRESMULT 0.6

texture texHDR1 { Width = BUFFER_WIDTH * DOF_RENDERRESMULT; Height = BUFFER_HEIGHT * DOF_RENDERRESMULT; Format = RGBA8; };
texture texHDR2 { Width = BUFFER_WIDTH * DOF_RENDERRESMULT; Height = BUFFER_HEIGHT * DOF_RENDERRESMULT; Format = RGBA8; }; 
sampler SamplerHDR1 { Texture = texHDR1; };
sampler SamplerHDR2 { Texture = texHDR2; };

/////////////////////////FUNCTIONS//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////FUNCTIONS//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#include "ReShade.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

uniform float2 MouseCoords < source = "mousepoint"; >;

float GetCoC(float2 coords)
{
	float scenedepth = ReShade::GetLinearizedDepth(coords);
	float scenefocus, scenecoc = 0.0;

	if (DOF_AUTOFOCUS)
	{
		scenefocus = 0.0;

		float2 focusPoint;
		if (DOF_MOUSEDRIVEN_AF)
			focusPoint = MouseCoords * BUFFER_PIXEL_SIZE;
		else
			focusPoint = DOF_FOCUSPOINT;

		[loop]
		for (int r = DOF_FOCUSSAMPLES; 0 < r; r--)
		{
			sincos((6.2831853 / DOF_FOCUSSAMPLES) * r, coords.y, coords.x);
			coords.y *= BUFFER_ASPECT_RATIO;
			scenefocus += ReShade::GetLinearizedDepth(coords * DOF_FOCUSRADIUS + focusPoint);
		}
		scenefocus /= DOF_FOCUSSAMPLES;
	}
	else
	{
		scenefocus = DOF_MANUALFOCUSDEPTH;
	}

	scenefocus = smoothstep(0.0, DOF_INFINITEFOCUS, scenefocus);
	scenedepth = smoothstep(0.0, DOF_INFINITEFOCUS, scenedepth);

	if (scenedepth < scenefocus)
	{
		scenecoc = (scenedepth - scenefocus) / scenefocus;
	}
	else
	{
		scenecoc = saturate((scenedepth - scenefocus) / (scenefocus * pow(4.0, DOF_FARBLURCURVE) - scenefocus));
	}

	return saturate(scenecoc * 0.5 + 0.5);
}

/////////////////////////PIXEL SHADERS//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////PIXEL SHADERS//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

void PS_Focus(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 hdr1R : SV_Target0)
{
	hdr1R = tex2D(ReShade::BackBuffer, texcoord);
	hdr1R.w = GetCoC(texcoord);
}

// RING DOF
void PS_RingDOF1(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 hdr2R : SV_Target0)
{
	hdr2R = tex2D(SamplerHDR1, texcoord);

	const float centerDepth = hdr2R.w;
	const float blurAmount = abs(centerDepth * 2.0 - 1.0);
	float discRadius = blurAmount * DOF_BLURRADIUS;

	if (centerDepth < 0.5)
		discRadius *= (1.0 / max(DOF_NEARBLURCURVE * 2.0, 1.0));
	else
		discRadius *= 1.0;

	hdr2R.x = tex2Dlod(SamplerHDR1, float4(texcoord + float2( 0.000,  1.0) * fRingDOFFringe * discRadius * BUFFER_PIXEL_SIZE, 0, 0)).x;
	hdr2R.y = tex2Dlod(SamplerHDR1, float4(texcoord + float2(-0.866, -0.5) * fRingDOFFringe * discRadius * BUFFER_PIXEL_SIZE, 0, 0)).y;
	hdr2R.z = tex2Dlod(SamplerHDR1, float4(texcoord + float2( 0.866, -0.5) * fRingDOFFringe * discRadius * BUFFER_PIXEL_SIZE, 0, 0)).z;

	hdr2R.w = centerDepth;
}
void PS_RingDOF2(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 blurcolor : SV_Target)
{
	blurcolor = tex2D(SamplerHDR2, texcoord);
	const float3 noblurcolor = tex2D(ReShade::BackBuffer, texcoord).xyz;

	const float centerDepth = GetCoC(texcoord);

	const float blurAmount = abs(centerDepth * 2.0 - 1.0);
	float discRadius = blurAmount * DOF_BLURRADIUS;

	if (centerDepth < 0.5)
		discRadius *= 1.0 / max(DOF_NEARBLURCURVE * 2.0, 1.0);
	else
		discRadius *= 1.0;

	if (discRadius < 1.2)
	{
		blurcolor = float4(noblurcolor, centerDepth);
		return;
	}

	blurcolor.w = 1.0;

	const float s = 1.0;
	int ringsamples;

	[loop]
	for (int g = 1; g <= iRingDOFRings; g += 1)
	{
		ringsamples = g * iRingDOFSamples;

		[loop]
		for (int j = 0; j < ringsamples; j += 1)
		{
			float2 sampleoffset = 0.0;
			sincos(j * (6.283 / ringsamples), sampleoffset.y, sampleoffset.x);
			float4 tap = tex2Dlod(SamplerHDR2, float4(texcoord + sampleoffset * BUFFER_PIXEL_SIZE * discRadius * g / iRingDOFRings, 0, 0));

			tap.xyz *= 1.0 + max((dot(tap.xyz, 0.333) - fRingDOFThreshold) * fRingDOFGain, 0.0) * blurAmount;

			if (tap.w >= centerDepth * 0.99)
				tap.w = 1.0;
			else
				tap.w = pow(abs(tap.w * 2.0 - 1.0), 4.0);

			tap.w *= lerp(1.0, g / iRingDOFRings, fRingDOFBias);
			blurcolor.xyz += tap.xyz * tap.w;
			blurcolor.w += tap.w;
		}
	}

	blurcolor.xyz /= blurcolor.w;
	blurcolor.xyz = lerp(noblurcolor, blurcolor.xyz, smoothstep(1.2, 2.0, discRadius)); // smooth transition between full res color and lower res blur
	blurcolor.w = centerDepth;
#if GSHADE_DITHER
	blurcolor.xyz += TriDither(blurcolor.xyz, texcoord, BUFFER_COLOR_BIT_DEPTH);
#endif
}

// MAGIC DOF
void PS_MagicDOF1(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 hdr2R : SV_Target0)
{
	float4 blurcolor = tex2D(SamplerHDR1, texcoord);

	const float centerDepth = blurcolor.w;
	float discRadius = abs(centerDepth * 2.0 - 1.0) * DOF_BLURRADIUS;

	if (centerDepth < 0.5)
		discRadius *= (1.0 / max(DOF_NEARBLURCURVE * 2.0, 1.0));
	else
		discRadius *= 1.0;

	if (discRadius < 1.2)
	{
		hdr2R = float4(blurcolor.xyz, centerDepth);
	}
	else
	{
		blurcolor = 0.0;

		[loop]
		for (int i = -iMagicDOFBlurQuality; i <= iMagicDOFBlurQuality; ++i)
		{
			float4 tap = tex2Dlod(SamplerHDR1, float4(texcoord + (float2(1, 0) * i) * discRadius * BUFFER_PIXEL_SIZE.x / iMagicDOFBlurQuality, 0, 0));
			if (tap.w >= centerDepth*0.99)
				tap.w = 1.0;
			else
				tap.w = pow(abs(tap.w * 2.0 - 1.0), 4.0);
			blurcolor.xyz += tap.xyz*tap.w;
			blurcolor.w += tap.w;
		}

		blurcolor.xyz /= blurcolor.w;
		blurcolor.w = centerDepth;
		hdr2R = blurcolor;
	}
}
void PS_MagicDOF2(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 blurcolor : SV_Target)
{
	blurcolor = 0.0;
	const float3 noblurcolor = tex2D(ReShade::BackBuffer, texcoord).xyz;

	const float centerDepth = GetCoC(texcoord); //use fullres CoC data
	float discRadius = abs(centerDepth * 2.0 - 1.0) * DOF_BLURRADIUS;

	if (centerDepth < 0.5)
		discRadius *= 1.0 / max(DOF_NEARBLURCURVE * 2.0, 1.0);
	else
		discRadius *= 1.0;

	if (discRadius < 1.2)
	{
		blurcolor = float4(noblurcolor, centerDepth);
		return;
	}

	[loop]
	for (int i = -iMagicDOFBlurQuality; i <= iMagicDOFBlurQuality; ++i)
	{
		const float2 tapoffset1 = float2(0.5, 0.866) * i;

		blurcolor.xyz += pow(abs(min(tex2Dlod(SamplerHDR2, float4(texcoord + tapoffset1 * discRadius * BUFFER_PIXEL_SIZE / iMagicDOFBlurQuality, 0, 0)).xyz, tex2Dlod(SamplerHDR2, float4(texcoord + float2(-tapoffset1.x, tapoffset1.y) * discRadius * BUFFER_PIXEL_SIZE / iMagicDOFBlurQuality, 0, 0)).xyz)), fMagicDOFColorCurve);
		blurcolor.w += 1.0;
	}

	blurcolor.xyz /= blurcolor.w;
	blurcolor.xyz = pow(saturate(blurcolor.xyz), 1.0 / fMagicDOFColorCurve);
	blurcolor.xyz = lerp(noblurcolor, blurcolor.xyz, smoothstep(1.2, 2.0, discRadius));
#if GSHADE_DITHER
	blurcolor.xyz += TriDither(blurcolor.xyz, texcoord, BUFFER_COLOR_BIT_DEPTH);
#endif
}

// GP65CJ042 DOF
void PS_GPDOF1(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 hdr2R : SV_Target0)
{
	hdr2R = tex2D(SamplerHDR1, texcoord);

	const float centerDepth = hdr2R.w;
	float discRadius = saturate(abs(centerDepth * 2.0 - 1.0) - 0.1) * DOF_BLURRADIUS; //optimization to clean focus areas a bit

	if (centerDepth < 0.5)
		discRadius *= 1.0 / max(DOF_NEARBLURCURVE * 2.0, 1.0);
	else
		discRadius *= 1.0;

	float3 distortion = float3(-1.0, 0.0, 1.0);
	distortion *= fGPDOFChromaAmount;

	float4 chroma1 = tex2D(SamplerHDR1, texcoord + discRadius * BUFFER_PIXEL_SIZE * distortion.x);
	chroma1.w = smoothstep(0.0, centerDepth, chroma1.w);
	hdr2R.x = lerp(hdr2R.x, chroma1.x, chroma1.w);

	float4 chroma2 = tex2D(SamplerHDR1, texcoord + discRadius * BUFFER_PIXEL_SIZE * distortion.z);
	chroma2.w = smoothstep(0.0, centerDepth, chroma2.w);
	hdr2R.z = lerp(hdr2R.z, chroma2.z, chroma2.w);

	hdr2R.w = centerDepth;
}
void PS_GPDOF2(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 blurcolor : SV_Target)
{
	blurcolor = tex2D(SamplerHDR2, texcoord);
	const float4 noblurcolor = tex2D(ReShade::BackBuffer, texcoord);

	const float centerDepth = GetCoC(texcoord);

	const float blurAmount = abs(centerDepth * 2.0 - 1.0);
	float discRadius = blurAmount * DOF_BLURRADIUS;

	if (centerDepth < 0.5)
		discRadius *= 1.0 / max(DOF_NEARBLURCURVE * 2.0, 1.0);
	else
		discRadius *= 1.0;

	if (discRadius < 1.2)
	{
		blurcolor = float4(noblurcolor.xyz, centerDepth);
		return;
	}

	blurcolor.w = dot(blurcolor.xyz, 0.3333);
	blurcolor.w = max((blurcolor.w - fGPDOFBrightnessThreshold) * fGPDOFBrightnessMultiplier, 0.0);
	blurcolor.xyz *= (1.0 + blurcolor.w * blurAmount);
	blurcolor.xyz *= lerp(1.0, 0.0, saturate(fGPDOFBias));
	blurcolor.w = 1.0;

	int sampleCycle = 0;
	int sampleCycleCounter = 0;
	int sampleCounterInCycle = 0;
	const float basedAngle = 360.0 / iGPDOFPolygonCount;
	float2 currentVertex, nextVertex;

	int dofTaps;
	if (bGPDOFPolygonalBokeh)
		dofTaps = iGPDOFQuality * (iGPDOFQuality + 1) * iGPDOFPolygonCount / 2.0;
	else
		dofTaps = iGPDOFQuality * (iGPDOFQuality + 1) * 4;

	for (int i = 0; i < dofTaps; i++)
	{
		//dumb step incoming
		bool dothatstep = sampleCounterInCycle == 0;
		if (sampleCycle != 0)
		{
			if (float(sampleCounterInCycle) % float(sampleCycle) == 0)
				dothatstep = true;
		}
		//until here
		//ask yourself why so complicated? if(sampleCounterInCycle % sampleCycle == 0 ) gives warnings when sampleCycle=0
		//but it can only be 0 when sampleCounterInCycle is also 0 so it essentially is no division through 0 even if
		//the compiler believes it, it's 0/0 actually but without disabling shader optimizations this is the only way to workaround that.

		if (dothatstep)
		{
			sampleCounterInCycle = 0;
			sampleCycleCounter++;

			if (bGPDOFPolygonalBokeh)
			{
				sampleCycle += iGPDOFPolygonCount;
				currentVertex.xy = float2(1.0, 0.0);
				sincos(basedAngle* 0.017453292, nextVertex.y, nextVertex.x);
			}
			else
			{
				sampleCycle += 8;
			}
		}

		sampleCounterInCycle++;

		float2 sampleOffset;

		if (bGPDOFPolygonalBokeh)
		{
			const float sampleAngle = basedAngle / float(sampleCycleCounter) * sampleCounterInCycle;
			const float remainAngle = frac(sampleAngle / basedAngle) * basedAngle;

			if (remainAngle < 0.000001)
			{
				currentVertex = nextVertex;
				sincos((sampleAngle + basedAngle) * 0.017453292, nextVertex.y, nextVertex.x);
			}

			sampleOffset = lerp(currentVertex.xy, nextVertex.xy, remainAngle / basedAngle);
		}
		else
		{
			const float sampleAngle = 0.78539816 / float(sampleCycleCounter) * sampleCounterInCycle;
			sincos(sampleAngle, sampleOffset.y, sampleOffset.x);
		}

		sampleOffset *= sampleCycleCounter;

		float4 tap = tex2Dlod(SamplerHDR2, float4(texcoord + sampleOffset * discRadius * BUFFER_PIXEL_SIZE / iGPDOFQuality, 0, 0));

		const float brightMultipiler = max((dot(tap.xyz, 0.333) - fGPDOFBrightnessThreshold) * fGPDOFBrightnessMultiplier, 0.0);
		tap.xyz *= 1.0 + brightMultipiler * abs(tap.w * 2.0 - 1.0);

		if (tap.w >= centerDepth * 0.99)
			tap.w = 1.0;
		else
			tap.w = pow(abs(tap.w * 2.0 - 1.0), 4.0);
		float BiasCurve = 1.0 + fGPDOFBias * pow(abs((float)sampleCycleCounter / iGPDOFQuality), fGPDOFBiasCurve);

		blurcolor.xyz += tap.xyz * tap.w * BiasCurve;
		blurcolor.w += tap.w * BiasCurve;

	}

	blurcolor.xyz /= blurcolor.w;
	blurcolor.xyz = lerp(noblurcolor.xyz, blurcolor.xyz, smoothstep(1.2, 2.0, discRadius));
#if GSHADE_DITHER
	blurcolor.xyz += TriDither(blurcolor.xyz, texcoord, BUFFER_COLOR_BIT_DEPTH);
#endif
}

// MATSO DOF
float4 GetMatsoDOFCA(sampler col, float2 tex, float CoC)
{
	const float3 chroma = pow(float3(0.5, 1.0, 1.5), fMatsoDOFChromaPow * CoC);
	return float4(float3(tex2Dlod(col, float4(((2.0 * tex - 1.0) * chroma.r) * 0.5 + 0.5,0,0)).r, tex2Dlod(col, float4(((2.0 * tex - 1.0) * chroma.g) * 0.5 + 0.5,0,0)).g, tex2Dlod(col, float4(((2.0 * tex - 1.0) * chroma.b) * 0.5 + 0.5,0,0)).b) * (1.0 - CoC), 1.0);
}
float4 GetMatsoDOFBlur(int axis, float2 coord, sampler SamplerHDRX)
{
	float4 blurcolor = tex2D(SamplerHDRX, coord.xy);

	const float centerDepth = blurcolor.w;
	float discRadius = abs(centerDepth * 2.0 - 1.0) * DOF_BLURRADIUS; //optimization to clean focus areas a bit

	if (centerDepth < 0.5)
		discRadius *= 1.0 / max(DOF_NEARBLURCURVE * 2.0, 1.0);
	else
		discRadius *= 1.0;
	blurcolor = 0.0;

	const float2 tdirs[4] = { 
		float2(-0.306,  0.739),
		float2( 0.306,  0.739),
		float2(-0.739,  0.306),
		float2(-0.739, -0.306)
	};

	for (int i = -iMatsoDOFBokehQuality; i < iMatsoDOFBokehQuality; i++)
	{
		float2 taxis =  tdirs[axis];

		taxis.x = cos(fMatsoDOFBokehAngle * 0.0175) * taxis.x - sin(fMatsoDOFBokehAngle * 0.0175) * taxis.y;
		taxis.y = sin(fMatsoDOFBokehAngle * 0.0175) * taxis.x + cos(fMatsoDOFBokehAngle * 0.0175) * taxis.y;
		
		const float2 tcoord = coord.xy + (float)i * taxis * discRadius * BUFFER_PIXEL_SIZE * 0.5 / iMatsoDOFBokehQuality;

		float4 ct;
		if (bMatsoDOFChromaEnable)
			ct = GetMatsoDOFCA(SamplerHDRX, tcoord.xy, discRadius * BUFFER_PIXEL_SIZE.x * 0.5 / iMatsoDOFBokehQuality);
		else
			ct = tex2Dlod(SamplerHDRX, float4(tcoord.xy, 0, 0));
		// my own pseudo-bokeh weighting
		const float w = pow(abs(dot(ct.rgb, 0.333) + length(ct.rgb) + 0.1), fMatsoDOFBokehCurve) + abs((float)i);

		blurcolor.xyz += ct.xyz * w;
		blurcolor.w += w;
	}

	blurcolor.xyz /= blurcolor.w;
	blurcolor.w = centerDepth;
	return blurcolor;
}

void PS_MatsoDOF1(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 hdr2R : SV_Target0)
{
	hdr2R = GetMatsoDOFBlur(2, texcoord, SamplerHDR1);	
}
void PS_MatsoDOF2(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 hdr1R : SV_Target0)
{
	hdr1R = GetMatsoDOFBlur(3, texcoord, SamplerHDR2);	
}
void PS_MatsoDOF3(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 hdr2R : SV_Target0)
{
	hdr2R = GetMatsoDOFBlur(0, texcoord, SamplerHDR1);	
}
void PS_MatsoDOF4(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 blurcolor : SV_Target)
{
	blurcolor = GetMatsoDOFBlur(1, texcoord, SamplerHDR2);
	const float centerDepth = GetCoC(texcoord); //fullres coc data

	float discRadius = abs(centerDepth * 2.0 - 1.0) * DOF_BLURRADIUS;

	if (centerDepth < 0.5)
		discRadius *= 1.0 / max(DOF_NEARBLURCURVE * 2.0, 1.0);
	else
		discRadius *= 1.0;

	//not 1.2 - 2.0 because matso's has a weird bokeh weighting that is almost like a tonemapping and border between blur and no blur appears to harsh
	blurcolor.xyz = lerp(tex2D(ReShade::BackBuffer, texcoord).xyz,blurcolor.xyz,smoothstep(0.2,2.0,discRadius));
#if GSHADE_DITHER
	blurcolor.xyz += TriDither(blurcolor.xyz, texcoord, BUFFER_COLOR_BIT_DEPTH);
#endif
}

// MARTY MCFLY DOF
float2 GetDistortedOffsets(float2 intexcoord, float2 sampleoffset)
{
	const float2 tocenter = intexcoord - float2(0.5, 0.5);
	const float3 perp = normalize(float3(tocenter.y, -tocenter.x, 0.0));

	const float rotangle = length(tocenter) * 2.221 * fADOF_ShapeDistortAmount;
	const float3 oldoffset = float3(sampleoffset, 0);

	const float3 rotatedoffset =  oldoffset * cos(rotangle) + cross(perp, oldoffset) * sin(rotangle) + perp * dot(perp, oldoffset) * (1.0 - cos(rotangle));

	return rotatedoffset.xy;
}

float4 tex2Dchroma(sampler2D tex, float2 sourcecoord, float2 offsetcoord)
{

	const float3 sample1 = tex2Dlod(tex, float4(sourcecoord.xy + offsetcoord.xy * (1.0 - fADOF_ShapeChromaAmount), 0, 0)).xyz;
	const float4 sample2 = tex2Dlod(tex, float4(sourcecoord.xy + offsetcoord.xy, 0, 0));
	const float3 sample3 = tex2Dlod(tex, float4(sourcecoord.xy + offsetcoord.xy * (1.0 + fADOF_ShapeChromaAmount), 0, 0)).xyz;
	float4 res = (0.0, 0.0, 0.0, sample2.w);

	switch (iADOF_ShapeChromaMode)
	{
		case 0:
			res.xyz = float3(sample1.x, sample2.y, sample3.z);
			return res;
		case 1:
			res.xyz = float3(sample2.x, sample3.y, sample1.z);
			return res;
		case 2:
			res.xyz = float3(sample3.x, sample1.y, sample2.z);
			return res;
		case 3:
			res.xyz = float3(sample1.x, sample3.y, sample2.z);
			return res;
		case 4:
			res.xyz = float3(sample2.x, sample1.y, sample3.z);
			return res;
		default:
			res.xyz = float3(sample3.x, sample2.y, sample1.z);
			return res;
	}
}

#if bADOF_ShapeTextureEnable
	#undef iADOF_ShapeVertices
	#define iADOF_ShapeVertices 4
#endif

uniform float Timer < source = "timer"; >;

float3 BokehBlur(sampler2D tex, float2 coord, float CoC, float centerDepth)
{
	float4 res = float4(tex2Dlod(tex, float4(coord.xy, 0.0, 0.0)).xyz, 1.0);
	const int ringCount = round(lerp(1.0, (float)iADOF_ShapeQuality, CoC / DOF_BLURRADIUS));
	float rotAngle = fADOF_ShapeRotation;
	float2 discRadius = CoC * BUFFER_PIXEL_SIZE;
	int shapeVertices;
	float2 edgeVertices[iADOF_ShapeVertices + 1];
	float2 Grain;
	
	switch(iADOF_ShapeType)
	{
		//"Circular" Bokeh
		case 0:
			shapeVertices = iADOF_ShapeVertices;
			if (bADOF_ShapeWeightEnable)
				res.w = (1.0 - fADOF_ShapeWeightAmount);

			res.xyz = pow(abs(res.xyz), fADOF_BokehCurve)*res.w;

			if (bADOF_ShapeAnamorphEnable)
				discRadius.x *= fADOF_ShapeAnamorphRatio;

			if (bADOF_RotAnimationEnable)
				rotAngle += fADOF_RotAnimationSpeed * Timer * 0.005;

			if (bADOF_ShapeDiffusionEnable)
			{
				Grain = float2(frac(sin(coord.x + coord.y * 543.31) *  493013.0), frac(cos(coord.x - coord.y * 573.31) * 289013.0));
				Grain = (Grain - 0.5) * fADOF_ShapeDiffusionAmount + 1.0;
			}

			[unroll]
			for (int z = 0; z <= shapeVertices; z++)
			{
				sincos((6.2831853 / shapeVertices)*z + radians(rotAngle), edgeVertices[z].y, edgeVertices[z].x);
			}

			[loop]
			for (float i = 1; i <= ringCount; i++)
			{
				[loop]
				for (int j = 1; j <= shapeVertices; j++)
				{
					float radiusCoeff = i / ringCount;
					float blursamples = i;

#if bADOF_ShapeTextureEnable
					blursamples *= 2;
#endif

					[loop]
					for (float k = 0; k < blursamples; k++)
					{
						if (bADOF_ShapeApertureEnable)
							radiusCoeff *= 1.0 + sin(k / blursamples * 6.2831853 - 1.5707963)*fADOF_ShapeApertureAmount; // * 2 pi - 0.5 pi so it's 1x up and down in [0|1] space.

						float2 sampleOffset = lerp(edgeVertices[j - 1], edgeVertices[j], k / blursamples) * radiusCoeff;

						if (bADOF_ShapeCurvatureEnable)
							sampleOffset = lerp(sampleOffset, normalize(sampleOffset) * radiusCoeff, fADOF_ShapeCurvatureAmount);

						if (bADOF_ShapeDistortEnable)
							sampleOffset = GetDistortedOffsets(coord, sampleOffset);

						if (bADOF_ShapeDiffusionEnable)
							sampleOffset *= Grain;

						float4 tap;
						if (bADOF_ShapeChromaEnable)
							tap = tex2Dchroma(tex, coord, sampleOffset * discRadius);
						else
							tap = tex2Dlod(tex, float4(coord.xy + sampleOffset.xy * discRadius, 0, 0));

						if (tap.w >= centerDepth*0.99)
							tap.w = 1.0;
						else
							tap.w = pow(abs(tap.w * 2.0 - 1.0), 4.0);

						if (bADOF_ShapeWeightEnable)
							tap.w *= lerp(1.0, pow(length(sampleOffset), fADOF_ShapeWeightCurve), fADOF_ShapeWeightAmount);

#if bADOF_ShapeTextureEnable
						tap.w *= tex2Dlod(SamplerMask, float4((sampleOffset + 0.707) * 0.707, 0, 0)).x;
#endif

						res.xyz += pow(abs(tap.xyz), fADOF_BokehCurve) * tap.w;
						res.w += tap.w;
					}
				}
			}
			break;
		//Pentagonal Bokeh
		default:
			shapeVertices = iADOF_ShapeVerticesP;
			if (bADOF_ShapeWeightEnable)
				res.w = (1.0 - fADOF_ShapeWeightAmount);

			res.xyz = pow(abs(res.xyz), fADOF_BokehCurve)*res.w;

			if (bADOF_ShapeAnamorphEnable)
				discRadius.x *= fADOF_ShapeAnamorphRatio;

			if (bADOF_RotAnimationEnable)
				rotAngle += fADOF_RotAnimationSpeed * Timer * 0.005;

			if (bADOF_ShapeDiffusionEnable)
			{
				Grain = float2(frac(sin(coord.x + coord.y * 543.31) *  493013.0), frac(cos(coord.x - coord.y * 573.31) * 289013.0));
				Grain = (Grain - 0.5) * fADOF_ShapeDiffusionAmount + 1.0;
			}

			[unroll]
			for (int z = 0; z <= shapeVertices; z++)
			{
				sincos((6.2831853 / shapeVertices)*z + radians(rotAngle), edgeVertices[z].y, edgeVertices[z].x);
			}

			[loop]
			for (float i = 1; i <= ringCount; i++)
			{
				[loop]
				for (int j = 1; j <= shapeVertices; j++)
				{
					float radiusCoeff = i / ringCount;
					float blursamples = i;

#if bADOF_ShapeTextureEnable
					blursamples *= 2;
#endif

					[loop]
					for (float k = 0; k < blursamples; k++)
					{
						if (bADOF_ShapeApertureEnable)
							radiusCoeff *= 1.0 + sin(k / blursamples * 6.2831853 - 1.5707963)*fADOF_ShapeApertureAmount; // * 2 pi - 0.5 pi so it's 1x up and down in [0|1] space.

						float2 sampleOffset = lerp(edgeVertices[j - 1], edgeVertices[j], k / blursamples) * radiusCoeff;

						if (bADOF_ShapeCurvatureEnable)
							sampleOffset = lerp(sampleOffset, normalize(sampleOffset) * radiusCoeff, fADOF_ShapeCurvatureAmount);

						if (bADOF_ShapeDistortEnable)
							sampleOffset = GetDistortedOffsets(coord, sampleOffset);

						if (bADOF_ShapeDiffusionEnable)
							sampleOffset *= Grain;

						float4 tap;
						if (bADOF_ShapeChromaEnable)
							tap = tex2Dchroma(tex, coord, sampleOffset * discRadius);
						else
							tap = tex2Dlod(tex, float4(coord.xy + sampleOffset.xy * discRadius, 0, 0));

						if (tap.w >= centerDepth*0.99)
							tap.w = 1.0;
						else
							tap.w = pow(abs(tap.w * 2.0 - 1.0), 4.0);

						if (bADOF_ShapeWeightEnable)
							tap.w *= lerp(1.0, pow(length(sampleOffset), fADOF_ShapeWeightCurve), fADOF_ShapeWeightAmount);

#if bADOF_ShapeTextureEnable
						tap.w *= tex2Dlod(SamplerMask, float4((sampleOffset + 0.707) * 0.707, 0, 0)).x;
#endif

						res.xyz += pow(abs(tap.xyz), fADOF_BokehCurve) * tap.w;
						res.w += tap.w;
					}
				}
			}
			break;
		//Diamond Bokeh
		case 2:
			shapeVertices = iADOF_ShapeVerticesD;
			if (bADOF_ShapeWeightEnable)
				res.w = (1.0 - fADOF_ShapeWeightAmount);

			res.xyz = pow(abs(res.xyz), fADOF_BokehCurve)*res.w;

			if (bADOF_ShapeAnamorphEnable)
				discRadius.x *= fADOF_ShapeAnamorphRatio;

			if (bADOF_RotAnimationEnable)
				rotAngle += fADOF_RotAnimationSpeed * Timer * 0.005;

			if (bADOF_ShapeDiffusionEnable)
			{
				Grain = float2(frac(sin(coord.x + coord.y * 543.31) *  493013.0), frac(cos(coord.x - coord.y * 573.31) * 289013.0));
				Grain = (Grain - 0.5) * fADOF_ShapeDiffusionAmount + 1.0;
			}

			[unroll]
			for (int z = 0; z <= shapeVertices; z++)
			{
				sincos((6.2831853 / shapeVertices)*z + radians(rotAngle), edgeVertices[z].y, edgeVertices[z].x);
			}

			[loop]
			for (float i = 1; i <= ringCount; i++)
			{
				[loop]
				for (int j = 1; j <= shapeVertices; j++)
				{
					float radiusCoeff = i / ringCount;
					float blursamples = i;

#if bADOF_ShapeTextureEnable
					blursamples *= 2;
#endif

					[loop]
					for (float k = 0; k < blursamples; k++)
					{
						if (bADOF_ShapeApertureEnable)
							radiusCoeff *= 1.0 + sin(k / blursamples * 6.2831853 - 1.5707963)*fADOF_ShapeApertureAmount; // * 2 pi - 0.5 pi so it's 1x up and down in [0|1] space.

						float2 sampleOffset = lerp(edgeVertices[j - 1], edgeVertices[j], k / blursamples) * radiusCoeff;

						if (bADOF_ShapeCurvatureEnable)
							sampleOffset = lerp(sampleOffset, normalize(sampleOffset) * radiusCoeff, fADOF_ShapeCurvatureAmount);

						if (bADOF_ShapeDistortEnable)
							sampleOffset = GetDistortedOffsets(coord, sampleOffset);

						if (bADOF_ShapeDiffusionEnable)
							sampleOffset *= Grain;

						float4 tap;
						if (bADOF_ShapeChromaEnable)
							tap = tex2Dchroma(tex, coord, sampleOffset * discRadius);
						else
							tap = tex2Dlod(tex, float4(coord.xy + sampleOffset.xy * discRadius, 0, 0));

						if (tap.w >= centerDepth*0.99)
							tap.w = 1.0;
						else
							tap.w = pow(abs(tap.w * 2.0 - 1.0), 4.0);

						if (bADOF_ShapeWeightEnable)
							tap.w *= lerp(1.0, pow(length(sampleOffset), fADOF_ShapeWeightCurve), fADOF_ShapeWeightAmount);

#if bADOF_ShapeTextureEnable
						tap.w *= tex2Dlod(SamplerMask, float4((sampleOffset + 0.707) * 0.707, 0, 0)).x;
#endif

						res.xyz += pow(abs(tap.xyz), fADOF_BokehCurve) * tap.w;
						res.w += tap.w;
					}
				}
			}
			break;

		//Triangular Bokeh
		case 3:
			shapeVertices = iADOF_ShapeVerticesT;
			if (bADOF_ShapeWeightEnable)
				res.w = (1.0 - fADOF_ShapeWeightAmount);

			res.xyz = pow(abs(res.xyz), fADOF_BokehCurve)*res.w;

			if (bADOF_ShapeAnamorphEnable)
				discRadius.x *= fADOF_ShapeAnamorphRatio;

			if (bADOF_RotAnimationEnable)
				rotAngle += fADOF_RotAnimationSpeed * Timer * 0.005;

			if (bADOF_ShapeDiffusionEnable)
			{
				Grain = float2(frac(sin(coord.x + coord.y * 543.31) *  493013.0), frac(cos(coord.x - coord.y * 573.31) * 289013.0));
				Grain = (Grain - 0.5) * fADOF_ShapeDiffusionAmount + 1.0;
			}

			[unroll]
			for (int z = 0; z <= shapeVertices; z++)
			{
				sincos((6.2831853 / shapeVertices)*z + radians(rotAngle), edgeVertices[z].y, edgeVertices[z].x);
			}

			[loop]
			for (float i = 1; i <= ringCount; i++)
			{
				[loop]
				for (int j = 1; j <= shapeVertices; j++)
				{
					float radiusCoeff = i / ringCount;
					float blursamples = i;

#if bADOF_ShapeTextureEnable
					blursamples *= 2;
#endif

					[loop]
					for (float k = 0; k < blursamples; k++)
					{
						if (bADOF_ShapeApertureEnable)
							radiusCoeff *= 1.0 + sin(k / blursamples * 6.2831853 - 1.5707963)*fADOF_ShapeApertureAmount; // * 2 pi - 0.5 pi so it's 1x up and down in [0|1] space.

						float2 sampleOffset = lerp(edgeVertices[j - 1], edgeVertices[j], k / blursamples) * radiusCoeff;

						if (bADOF_ShapeCurvatureEnable)
							sampleOffset = lerp(sampleOffset, normalize(sampleOffset) * radiusCoeff, fADOF_ShapeCurvatureAmount);

						if (bADOF_ShapeDistortEnable)
							sampleOffset = GetDistortedOffsets(coord, sampleOffset);

						if (bADOF_ShapeDiffusionEnable)
							sampleOffset *= Grain;

						float4 tap;
						if (bADOF_ShapeChromaEnable)
							tap = tex2Dchroma(tex, coord, sampleOffset * discRadius);
						else
							tap = tex2Dlod(tex, float4(coord.xy + sampleOffset.xy * discRadius, 0, 0));

						if (tap.w >= centerDepth*0.99)
							tap.w = 1.0;
						else
							tap.w = pow(abs(tap.w * 2.0 - 1.0), 4.0);

						if (bADOF_ShapeWeightEnable)
							tap.w *= lerp(1.0, pow(length(sampleOffset), fADOF_ShapeWeightCurve), fADOF_ShapeWeightAmount);

#if bADOF_ShapeTextureEnable
						tap.w *= tex2Dlod(SamplerMask, float4((sampleOffset + 0.707) * 0.707, 0, 0)).x;
#endif

						res.xyz += pow(abs(tap.xyz), fADOF_BokehCurve) * tap.w;
						res.w += tap.w;
					}
				}
			}
			break;
		}

	res.xyz = max(res.xyz / res.w, 0.0);
	return pow(res.xyz, 1.0 / fADOF_BokehCurve);
}

void PS_McFlyDOF1(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 hdr2R : SV_Target0)
{
	texcoord /= DOF_RENDERRESMULT;

	hdr2R = tex2D(SamplerHDR1, saturate(texcoord));

	const float centerDepth = hdr2R.w;
	float discRadius = abs(centerDepth * 2.0 - 1.0) * DOF_BLURRADIUS;

	if (centerDepth < 0.5)
		discRadius *= 1.0 / max(DOF_NEARBLURCURVE * 2.0, 1.0);
	else
		discRadius *= 1.0;

	if (max(texcoord.x, texcoord.y) <= 1.05 && discRadius >= 1.2)
	{
		//doesn't bring that much with intelligent tap calculation
		if (discRadius >= 1.2)
			hdr2R.xyz = BokehBlur(SamplerHDR1, texcoord, discRadius, centerDepth);
			
		hdr2R.w = centerDepth;
	}
}
void PS_McFlyDOF2(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 scenecolor : SV_Target)
{   
	scenecolor = 0.0;
	
	const float centerDepth = GetCoC(texcoord); 
	float discRadius = abs(centerDepth * 2.0 - 1.0) * DOF_BLURRADIUS;

	if (centerDepth < 0.5)
		discRadius *= 1.0 / max(DOF_NEARBLURCURVE * 2.0, 1.0);
	else
		discRadius *= 1.0;

#if __RENDERER__ < 0xa000 && !__RESHADE_PERFORMANCE_MODE__
	[flatten]
#endif
	if (bADOF_ImageChromaEnable)
	{
		const float2 coord = texcoord * 2.0 - 1.0;
		float centerfact = length(coord);
		centerfact = pow(centerfact, fADOF_ImageChromaCurve) * fADOF_ImageChromaAmount;

		float3 chromadivisor = 0.0;

		for (float c = 0; c < iADOF_ImageChromaHues; c++)
		{
			const float temphue = c / iADOF_ImageChromaHues;
			float3 tempchroma = saturate(float3(abs(temphue * 6.0 - 3.0) - 1.0, 2.0 - abs(temphue * 6.0 - 2.0), 2.0 - abs(temphue * 6.0 - 4.0)));
			scenecolor.xyz += tex2Dlod(SamplerHDR2, float4((coord.xy * (1.0 + (BUFFER_RCP_WIDTH * centerfact * discRadius) * ((c + 0.5) / iADOF_ImageChromaHues - 0.5)) * 0.5 + 0.5) * DOF_RENDERRESMULT, 0, 0)).xyz*tempchroma.xyz;
			chromadivisor += tempchroma;
		}

		scenecolor.xyz /= dot(chromadivisor.xyz, 0.333);
	}
	else
	{
		scenecolor = tex2D(SamplerHDR2, texcoord*DOF_RENDERRESMULT);
	}

	scenecolor.xyz = lerp(scenecolor.xyz, tex2D(ReShade::BackBuffer, texcoord).xyz, smoothstep(2.0,1.2,discRadius));

	scenecolor.w = centerDepth;
}
void PS_McFlyDOF3(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 scenecolor : SV_Target)
{
	scenecolor = tex2D(ReShade::BackBuffer, texcoord);
	float4 blurcolor = 0.0001;

	//move all math out of loop if possible
	const float2 blurmult = smoothstep(0.3, 0.8, abs(scenecolor.w * 2.0 - 1.0)) * BUFFER_PIXEL_SIZE * fADOF_SmootheningAmount;

	const float weights[3] = { 1.0,0.75,0.5 };
	//Why not separable? For the glory of Satan, of course!
	for (int x = -2; x <= 2; x++)
	{
		for (int y = -2; y <= 2; y++)
		{
			const float offsetweight = weights[abs(x)] * weights[abs(y)];
			blurcolor.xyz += tex2Dlod(ReShade::BackBuffer, float4(texcoord + float2(x, y) * blurmult, 0, 0)).xyz * offsetweight;
			blurcolor.w += offsetweight;
		}
	}

	scenecolor.xyz = blurcolor.xyz / blurcolor.w;

#if bADOF_ImageGrainEnable
	const float ImageGrain = frac(sin(texcoord.x + texcoord.y * 543.31) *  893013.0 + Timer * 0.001);

	float3 AnimGrain = 0.5;
	const float2 GrainPixelSize = BUFFER_PIXEL_SIZE / fADOF_ImageGrainScale;
	//My emboss noise
	AnimGrain += lerp(tex2D(SamplerNoise, texcoord * fADOF_ImageGrainScale + float2(GrainPixelSize.x, 0)).xyz, tex2D(SamplerNoise, texcoord * fADOF_ImageGrainScale + 0.5 + float2(GrainPixelSize.x, 0)).xyz, ImageGrain) * 0.1;
	AnimGrain -= lerp(tex2D(SamplerNoise, texcoord * fADOF_ImageGrainScale + float2(0, GrainPixelSize.y)).xyz, tex2D(SamplerNoise, texcoord * fADOF_ImageGrainScale + 0.5 + float2(0, GrainPixelSize.y)).xyz, ImageGrain) * 0.1;
	AnimGrain = dot(AnimGrain.xyz, 0.333);

	//Photoshop overlay mix mode
	float3 graincolor;
	if (scenecolor.xyz < 0.5)
		graincolor = 2.0 * scenecolor.xyz * AnimGrain.xxx;
	else
		graincolor = 1.0 - 2.0 * (1.0 - scenecolor.xyz) * (1.0 - AnimGrain.xxx);
	scenecolor.xyz = lerp(scenecolor.xyz, graincolor.xyz, pow(outOfFocus, fADOF_ImageGrainCurve) * fADOF_ImageGrainAmount);
#endif

	//focus preview disabled!

#if GSHADE_DITHER
	blurcolor.xyz += TriDither(blurcolor.xyz, texcoord, BUFFER_COLOR_BIT_DEPTH);
#endif
}

/////////////////////////TECHNIQUES/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////TECHNIQUES/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

technique RingDOF <ui_label="圆环景深";>
{
	pass Focus { VertexShader = PostProcessVS; PixelShader = PS_Focus; RenderTarget = texHDR1; }
	pass RingDOF1 { VertexShader = PostProcessVS; PixelShader = PS_RingDOF1; RenderTarget = texHDR2; }
	pass RingDOF2 { VertexShader = PostProcessVS; PixelShader = PS_RingDOF2; /* renders to backbuffer*/ }
}

technique MagicDOF <ui_label="魔法景深";>
{
	pass Focus { VertexShader = PostProcessVS; PixelShader = PS_Focus; RenderTarget = texHDR1; }
	pass MagicDOF1 { VertexShader = PostProcessVS; PixelShader = PS_MagicDOF1; RenderTarget = texHDR2; }
	pass MagicDOF2 { VertexShader = PostProcessVS; PixelShader = PS_MagicDOF2; /* renders to backbuffer*/ }
}

technique GP65CJ042DOF <ui_label="GP65CJ042景深";>
{
	pass Focus { VertexShader = PostProcessVS; PixelShader = PS_Focus; RenderTarget = texHDR1; }
	pass GPDOF1 { VertexShader = PostProcessVS; PixelShader = PS_GPDOF1; RenderTarget = texHDR2; }
	pass GPDOF2 { VertexShader = PostProcessVS; PixelShader = PS_GPDOF2; /* renders to backbuffer*/ }
}

technique MatsoDOF <ui_label="Matso景深";>
{
	pass Focus { VertexShader = PostProcessVS; PixelShader = PS_Focus; RenderTarget = texHDR1; }
	pass MatsoDOF1 { VertexShader = PostProcessVS; PixelShader = PS_MatsoDOF1; RenderTarget = texHDR2; }
	pass MatsoDOF2 { VertexShader = PostProcessVS; PixelShader = PS_MatsoDOF2; RenderTarget = texHDR1; }
	pass MatsoDOF3 { VertexShader = PostProcessVS; PixelShader = PS_MatsoDOF3; RenderTarget = texHDR2; }
	pass MatsoDOF4 { VertexShader = PostProcessVS; PixelShader = PS_MatsoDOF4; /* renders to backbuffer*/ }
}

technique MartyMcFlyDOF <ui_label="MartyMcFly景深";>
{
	pass Focus { VertexShader = PostProcessVS; PixelShader = PS_Focus; RenderTarget = texHDR1; }
	pass McFlyDOF1 { VertexShader = PostProcessVS; PixelShader = PS_McFlyDOF1; RenderTarget = texHDR2; }
	pass McFlyDOF2 { VertexShader = PostProcessVS; PixelShader = PS_McFlyDOF2; /* renders to backbuffer*/ }
	pass McFlyDOF3 { VertexShader = PostProcessVS; PixelShader = PS_McFlyDOF3; /* renders to backbuffer*/ }
}
