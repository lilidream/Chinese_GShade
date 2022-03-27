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
// Credits :: PetkaGtA
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Modified by Marot for ReShade 4.0 compatibility and lightly optimized for the GShade project.
// Translation of the UI into Chinese by Lilidream.

uniform bool DOF_AUTOFOCUS <
	ui_label = "自动对焦";
	ui_tooltip = "启用基于自动对焦中心周围样本的自动对焦识别。";
	ui_category = "景深";
> = true;
uniform bool DOF_MOUSEDRIVEN_AF <
	ui_label = "鼠标驱动自动对焦";
	ui_tooltip = "启用鼠标驱动的自动对焦。如果开启，自动对焦点从鼠标坐标中读取，否则就使用对焦点。";
	ui_category = "景深";
> = false;
uniform float2 DOF_FOCUSPOINT <
	ui_label = "对焦点";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_tooltip = "自动对焦中心的X和Y坐标。轴线从屏幕左上角开始。";
	ui_category = "景深";
> = float2(0.5, 0.5);
uniform float DOF_FOCUSSAMPLES <
	ui_label = "对焦采样";
	ui_type = "slider";
	ui_min = 3; ui_max = 10;
	ui_tooltip = "焦点周围的样本量，用于更平滑的焦平面检测。";
	ui_category = "景深";
> = 6;
uniform float DOF_FOCUSRADIUS <
	ui_label = "焦点半径";
	ui_type = "slider";
	ui_min = 0.02; ui_max = 0.20;
	ui_tooltip = "焦点附近的采样半径。";
	ui_category = "景深";
> = 0.05;
uniform float DOF_NEARBLURCURVE <
	ui_label = "近模糊曲线";
	ui_type = "slider";
	ui_min = 0.5; ui_max = 1000.0;
	ui_step = 0.5;
	ui_tooltip = "靠近焦平面的模糊曲线。越高意味着模糊度越小。";
	ui_category = "景深";
> = 1.60;
uniform float DOF_FARBLURCURVE <
	ui_label = "远模糊曲线";
	ui_type = "slider";
	ui_min = 0.05; ui_max = 5.0;
	ui_tooltip = "焦点平面后的模糊曲线。越高意味着模糊度越小。";
	ui_category = "景深";
> = 2.00;
uniform float DOF_MANUALFOCUSDEPTH <
	ui_label = "手动对焦深度";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_tooltip = "自动对焦关闭时的焦平面深度。0.0表示相机，1.0表示无限距离。";
	ui_category = "景深";
> = 0.02;
uniform float DOF_INFINITEFOCUS <
	ui_label = "无限焦点";
	ui_type = "slider";
	ui_min = 0.01; ui_max = 1.0;
	ui_tooltip = "深度被认为是无限的距离。1.0是标准值。低值只在焦点物体非常接近相机时产生失焦模糊。建议用于游戏。";
	ui_category = "景深";
> = 1.00;
uniform float DOF_BLURRADIUS <
	ui_label = "模糊半径";
	ui_type = "slider";
	ui_min = 2.0; ui_max = 100.0;
	ui_tooltip = "像素的最大模糊半径。";
	ui_category = "景深";
> = 15.0;

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


uniform int iADOF1_ShapeType <
	ui_label = "形状类型";
	ui_type = "combo";
	ui_items = "圆 (GShade/Angelite)\0五边形 (ReShade 3/4)\0四边形\0三角形\0";
	ui_tooltip = "景深形状";
	ui_category = "MartyMcFly景深";
> = 0;
uniform int iADOF2_ShapeType <
	ui_label = "形状类型";
	ui_type = "combo";
	ui_items = "圆 (GShade/Angelite)\0五边形 (ReShade 3/4)\0四边形\0三角形\0";
	ui_tooltip = "景深形状";
	ui_category = "MartyMcFly景深";
> = 0;uniform int iADOF3_ShapeType <
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
texture tex123Noise < source = "mcnoise.png"; > { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
sampler Sampler123Noise { Texture = tex123Noise; };
#endif
#if bADOF_ShapeTextureEnable
texture tex123Mask < source = "mcmask.png"; > { Width = iADOF_ShapeTextureSize; Height = iADOF_ShapeTextureSize; Format = R8; };
sampler Sampler123Mask { Texture = tex123Mask; };
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
	
	switch(iADOF1_ShapeType)
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

float3 BokehBlur2(sampler2D tex, float2 coord, float CoC, float centerDepth)
{
	float4 res = float4(tex2Dlod(tex, float4(coord.xy, 0.0, 0.0)).xyz, 1.0);
	const int ringCount = round(lerp(1.0, (float)iADOF_ShapeQuality, CoC / DOF_BLURRADIUS));
	float rotAngle = fADOF_ShapeRotation;
	float2 discRadius = CoC * BUFFER_PIXEL_SIZE;
	int shapeVertices;
	float2 edgeVertices[iADOF_ShapeVertices + 1];
	float2 Grain;
	
	switch(iADOF2_ShapeType)
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

float3 BokehBlur3(sampler2D tex, float2 coord, float CoC, float centerDepth)
{
	float4 res = float4(tex2Dlod(tex, float4(coord.xy, 0.0, 0.0)).xyz, 1.0);
	const int ringCount = round(lerp(1.0, (float)iADOF_ShapeQuality, CoC / DOF_BLURRADIUS));
	float rotAngle = fADOF_ShapeRotation;
	float2 discRadius = CoC * BUFFER_PIXEL_SIZE;
	int shapeVertices;
	float2 edgeVertices[iADOF_ShapeVertices + 1];
	float2 Grain;
	
	switch(iADOF3_ShapeType)
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
void PS_McFlyDOF12(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 hdr2R : SV_Target0)
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
			hdr2R.xyz = BokehBlur2(SamplerHDR1, texcoord, discRadius, centerDepth);
			
		hdr2R.w = centerDepth;
	}
}
void PS_McFlyDOF13(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 hdr2R : SV_Target0)
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
			hdr2R.xyz = BokehBlur3(SamplerHDR1, texcoord, discRadius, centerDepth);
			
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

#if GSHADE_DITHER
	scenecolor.xyz += TriDither(scenecolor.xyz, texcoord, BUFFER_COLOR_BIT_DEPTH);
#endif
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
	AnimGrain += lerp(tex2D(Sampler123Noise, texcoord * fADOF_ImageGrainScale + float2(GrainPixelSize.x, 0)).xyz, tex2D(Sampler123Noise, texcoord * fADOF_ImageGrainScale + 0.5 + float2(GrainPixelSize.x, 0)).xyz, ImageGrain) * 0.1;
	AnimGrain -= lerp(tex2D(Sampler123Noise, texcoord * fADOF_ImageGrainScale + float2(0, GrainPixelSize.y)).xyz, tex2D(Sampler123Noise, texcoord * fADOF_ImageGrainScale + 0.5 + float2(0, GrainPixelSize.y)).xyz, ImageGrain) * 0.1;
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
	scenecolor.xyz += TriDither(scenecolor.xyz, texcoord, BUFFER_COLOR_BIT_DEPTH);
#endif
}

/////////////////////////TECHNIQUES/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////TECHNIQUES/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

technique MartyMcFlyDOF1 <ui_label="MartyMcFly景深1";>
{
	pass Focus { VertexShader = PostProcessVS; PixelShader = PS_Focus; RenderTarget = texHDR1; }
	pass McFlyDOF1 { VertexShader = PostProcessVS; PixelShader = PS_McFlyDOF1; RenderTarget = texHDR2; }
	pass McFlyDOF2 { VertexShader = PostProcessVS; PixelShader = PS_McFlyDOF2; /* renders to backbuffer*/ }
	pass McFlyDOF3 { VertexShader = PostProcessVS; PixelShader = PS_McFlyDOF3; /* renders to backbuffer*/ }
}
technique MartyMcFlyDOF2 <ui_label="MartyMcFly景深2";>
{
	pass Focus { VertexShader = PostProcessVS; PixelShader = PS_Focus; RenderTarget = texHDR1; }
	pass McFlyDOF1 { VertexShader = PostProcessVS; PixelShader = PS_McFlyDOF12; RenderTarget = texHDR2; }
	pass McFlyDOF2 { VertexShader = PostProcessVS; PixelShader = PS_McFlyDOF2; /* renders to backbuffer*/ }
	pass McFlyDOF3 { VertexShader = PostProcessVS; PixelShader = PS_McFlyDOF3; /* renders to backbuffer*/ }
}
technique MartyMcFlyDOF3 <ui_label="MartyMcFly景深3";>
{
	pass Focus { VertexShader = PostProcessVS; PixelShader = PS_Focus; RenderTarget = texHDR1; }
	pass McFlyDOF1 { VertexShader = PostProcessVS; PixelShader = PS_McFlyDOF13; RenderTarget = texHDR2; }
	pass McFlyDOF2 { VertexShader = PostProcessVS; PixelShader = PS_McFlyDOF2; /* renders to backbuffer*/ }
	pass McFlyDOF3 { VertexShader = PostProcessVS; PixelShader = PS_McFlyDOF3; /* renders to backbuffer*/ }
}
