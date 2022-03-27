/**
Perfect Perspective PS, version 4.0.1
All rights (c) 2018 Jakub Maksymilian Fober (the Author).

The Author provides this shader (the Work) under
the Creative Commons CC BY-NC-ND 3.0 license
available online at
http://creativecommons.org/licenses/by-nc-nd/3.0/

The Author further grants permission for commercial reuse of
screen-shots and game-play recordings derived from the Work, provided
that any use is accompanied by the link to the Work and a credit to the
Author. (crediting Author by pseudonym "Fubax" is acceptable)

For inquiries please contact jakub.m.fober@pm.me
For updates visit GitHub repository at
https://github.com/Fubaxiusz/fubax-shaders/

This shader version is based upon research papers
by Fober, J. M.
	Perspective picture from Visual Sphere:
	a new approach to image rasterization
	arXiv: 2003.10558 [cs.GR] (2020)
	https://arxiv.org/abs/2003.10558
and
	Temporally-smooth Antialiasing and Lens Distortion
	with Rasterization Map
	arXiv: 2010.04077 [cs.GR] (2020)
	https://arxiv.org/abs/2010.04077


版权所有(C) 2018 Jakub Maksymilian Fober (作者)。

作者基于“署名-非商业性使用-禁止演绎 4.0 国际”协议(https://creativecommons.org/licenses/by-nc-nd/4.0/deed.zh)
来提供此着色器。
作者还允许重新使用来自作品(此着色器)的屏幕截图和游戏录像画面，
但再使用的目的是为了推进和/或总结作品，或作为在线论坛帖子或社交媒体帖子的一部分。
而且任何使用都必须附有作品的链接和对作者的版权。(可使用笔名 "Fubax "注明作者的名字)

咨询请联系jakub.m.fober@pm.me
更新请访问Github仓库 https://github.com/Fubaxiusz/fubax-shaders/

由作者授权Lilidream将UI翻译为中文。

此着色器版本基于以下 Forer, J. M. 的论文：
	Perspective picture from Visual Sphere:
	a new approach to image rasterization
	arXiv: 2003.10558 [cs.GR] (2020)
	https://arxiv.org/abs/2003.10558
与
	Temporally-smooth Antialiasing and Lens Distortion
	with Rasterization Map
	arXiv: 2010.04077 [cs.GR] (2020)
	https://arxiv.org/abs/2010.04077
*/


  ////////////
 /// MENU ///
////////////

// FIELD OF VIEW

uniform uint FOV <
	ui_type = "slider";
	ui_text =
		"第一调整,\n"
		"符合游戏设置";
	ui_category = "游戏设置";
	ui_category_closed = true;
	ui_label = "视场(FOV)";
	ui_tooltip = "此设置应该符合你的游戏里的视场设置(以度为单位)";
	#if __RESHADE__ < 40000
		ui_step = 0.2;
	#endif
	ui_max = 170u;
> = 90u;

uniform uint FovType <
	ui_type = "combo";
	ui_category = "游戏设置";
	ui_label = "视场类型";
	ui_tooltip =
		"这个设置应该与游戏特定的FOV类型相匹配 \n提示: 如果图像在运动中隆起（FOV太高），把它改为 \"对角线\"。\n当比例在外围被扭曲时（FOV太低），选择 \"垂直 \"或 \"4:3\"。对于超宽显示屏，你可能想用'16:9'代替。\n调整后，圆形物体在转角处仍然是圆形，而不是长方形。\n倾斜头部以看得更清楚。\n* 这个方法只在 \"形状 \"预设中起作用，或者在专家模式下k=0.5。";
	ui_items =
		"水平的\0"
		"对角线的\0"
		"垂直的\0"
		"4:3\0"
		"16:9\0";
> = 0u;

// PERSPECTIVE

uniform uint Projection <
	ui_type = "combo";
	ui_text =
		"第二调整,\n"
		"扭曲数量";
	ui_category = "透视 (预设)";
	ui_category_closed = true;
	ui_label = "透视类型";
	ui_tooltip =
		"根据游戏风格选择透视类型\n\n"
		" 透视   |  K   | 投影\n"
		" -------------------------------\n"
		" 形状   |  0.5 | 球极面投影\n"
		" 位置   |  0   | 等距投影\n"
		" 距离   | -0.5 | 等立体投影";
	ui_items =
		"形状透视\0"
		"位置透视\0"
		"距离透视\0";
> = 0u;

uniform uint AnamorphicSqueeze <
	ui_type = "combo";
	ui_category = "透视 (预设)";
	ui_label = "挤压系数";
	ui_tooltip =
		"调整垂直变形数量\n\n"
		" 挤压 | 例子\n"
		" -----------------\n"
		"      1x | 方形\n"
		"   1.25x | Ultra Panavision 70\n"
		// "   1.33x | 16x9 TV\n"
		"    1.5x | Technirama\n"
		// "    1.6x | digital anamorphic\n"
		"      2x | 黄金比例\n";
	ui_items =
		"失真 1x\0"
		"失真 1.25x\0"
		// "失真 1.33x\0"
		"失真 1.5x\0"
		// "失真 1.6x\0"
		"失真 2x\0";
> = 2u;

uniform bool ExpertMode <
	ui_category = "透视 (专家)";
	ui_category_closed = true;
	ui_tooltip = "手动调整投影类型与失真挤压程度";
	ui_label = "专家模式";
> = false;

uniform float K <
	ui_type = "slider";
	ui_category = "透视 (专家)";
	ui_label = "K (投影)";
	ui_tooltip =
		"Projection coefficient\n\n"
		"  K   | perception   | projection\n"
		" --------------------------------\n"
		"  1   | Path         | Rectilinear\n"
		"  0.5 | Shape        | Stereographic\n"
		"  0   | Position     | Equidistant\n"
		" -0.5 | Distance     | Equisolid\n"
		" -1   | Illumination | Orthographic\n\n"
		"Rectilinear projection (standard):\n"
		" * doesn't preserve proportion, angle or scale\n"
		" * common standard projection (pinhole model)\n"
		"Stereographic projection (navigation, shape):\n"
		" * preserves angle and proportion\n"
		" * best for navigation through tight space\n"
		"Equidistant projection (aiming, speed):\n"
		" * maintains angular speed of motion\n"
		" * best for aiming at target\n"
		"Equisolid projection (distance):\n"
		" * preserves area relation\n"
		" * best for navigation in open space\n"
		"Orthographic projection:\n"
		" * preserves planar luminance as cosine-law\n"
		" * found in peephole viewer";
	ui_min = -1f; ui_max = 1f;
> = 1f;

uniform float S <
	ui_type = "slider";
	ui_category = "透视 (专家)";
	ui_label = "S (挤压)";
	ui_tooltip =
		"Anamorphic squeeze factor\n\n"
		" squeeze power | example\n"
		" -----------------------\n"
		"            1x | square\n"
		"         1.25x | Ultra Panavision 70\n"
		"         1.33x | 16x9 TV\n"
		"          1.5x | Technirama\n"
		"          1.6x | digital anamorphic\n"
		"          1.8x | 4x3 full-frame\n"
		"            2x | golden-standard\n";
	ui_min = 1f; ui_max = 4f; ui_step = 0.01;
> = 1f;

// PICTURE

uniform float CroppingFactor <
	ui_type = "slider";
	ui_text =
		"第三调整,\n"
		"缩放图像";
	ui_category = "图像调整";
	ui_category_closed = true;
	ui_label = "图像裁剪";
	ui_tooltip =
		"调整画面缩放与裁剪区域"
		" 值    | 裁剪类型\n"
		" -----------------\n"
		" 0     | 圆形\n"
		" 0.5   | 裁剪的圆\n"
		" 1     | 全屏";
	ui_min = 0f; ui_max = 1f;
> = 0.5;

uniform bool UseVignette <
	ui_type = "input";
	ui_category = "图像调整";
	ui_label = "添加暗角";
	ui_tooltip = "应用镜头校正自然暗角效果";
> = true;

// BORDER

uniform float4 BorderColor <
	ui_type = "color";
	ui_category = "边框设置";
	ui_category_closed = true;
	ui_label = "分辨率尺度映射";
	ui_tooltip = "分辨率尺度的颜色映射:\n"
		" 红 - 低采样\n"
		" 绿 - 超采样\n"
		" 蓝 - 中性采样";
	ui_label = "边框颜色";
	ui_tooltip = "使用Alpha通道来改变边框透明度";
> = float4(0.027, 0.027, 0.027, 0.96);

uniform bool MirrorBorder <
	ui_type = "input";
	ui_category = "边框设置";
	ui_label = "镜像边框";
	ui_tooltip = "选择边框上的镜像或原始图像";
> = true;

uniform bool BorderVignette <
	ui_type = "input";
	ui_category = "边框设置";
	ui_label = "边框暗角";
	ui_tooltip = "应用暗角效果到边框上";
> = false;

uniform float BorderCorner <
	ui_type = "slider";
	ui_category = "边框设置";
	ui_label = "边角大小";
	ui_tooltip = "0.0获得尖锐的角";
	ui_min = 0f; ui_max = 1f;
> = 0.062;

uniform uint BorderGContinuity <
	ui_type = "slider";
	ui_category = "边框设置";
	ui_label = "边角圆化";
	ui_tooltip =
		"G-surfacing continuity level for\n"
		"the corners\n\n"
		" G  | corner type\n"
		" ----------------\n"
		" G0 | sharp\n"
		" G1 | circular\n"
		" G2 | round\n"
		" G3 | smooth";
	ui_min = 1u; ui_max = 3u;
> = 2u;

// DEBUG OPTIONS

uniform bool DebugPreview <
	ui_type = "input";
	ui_text =
		"可视图像缩放,\n"
		"为超分辨率获得最佳值";
	ui_category = "Debug工具";
	ui_category_closed = true;
	ui_label = "Debug模式";
	ui_tooltip =
		"显示分辨率尺度的颜色映射\n\n"
		" 颜色 | 采样类型\n"
		" ---------------------\n"
		" 绿色 | 超过\n"
		" 蓝色 | 1:1\n"
		" 红色 | 不足";
> = false;

uniform uint ResScaleScreen <
	ui_type = "input";
	ui_category = "Debug工具";
	ui_label = "屏幕（原生）分辨率";
	ui_tooltip = "设置为屏幕原始分辨率";
> = 1920u;

uniform uint ResScaleVirtual <
	ui_type = "drag";
	ui_category = "Debug工具";
	ui_label = "虚拟分辨率";
	ui_tooltip =
		"模拟应用程序的运行超出原始屏幕分辨率（使用VSR或DSR）。";
	ui_step = 0.2;
	ui_min = 16u; ui_max = 16384u;
> = 1920u;

// Stereo 3D mode
#ifndef SIDE_BY_SIDE_3D
	#define SIDE_BY_SIDE_3D 0
#endif


  ////////////////
 /// TEXTURES ///
////////////////

#include "ReShade.fxh"

// Define screen texture with mirror tiles
sampler BackBuffer
{
	Texture = ReShade::BackBufferTex;

	// Border style
	AddressU = MIRROR;
	AddressV = MIRROR;

	// Linear workflow
	#if BUFFER_COLOR_BIT_DEPTH != 10
		SRGBTexture = true;
	#endif
};


  /////////////////
 /// FUNCTIONS ///
/////////////////

// ITU REC 601 YCbCr coefficients
#define KR 0.299
#define KB 0.114
// RGB to YCbCr-luma matrix
static const float3 LumaMtx = float3(KR, 1f-KR-KB, KB); // Luma (Y)

// Convert gamma between linear and sRGB
#define TO_DISPLAY_GAMMA_HQ(g) ((g)<0.0031308? (g)*12.92 : pow(abs(g), rcp(2.4))*1.055-0.055)
#define TO_LINEAR_GAMMA_HQ(g) ((g)<0.04045? (g)/12.92 : pow((abs(g)+0.055)/1.055, 2.4))

// Get reciprocal screen aspect ratio (1/x)
#define BUFFER_RCP_ASPECT_RATIO (BUFFER_HEIGHT*BUFFER_RCP_WIDTH)

/**
G continuity distance function by Jakub Max Fober.
Determined empirically. (G from 0, to 3)
	G=0 -> Sharp corners
	G=1 -> Round corners
	G=2 -> Smooth corners
	G=3 -> Luxury corners
*/
float glength(uint G, float2 pos)
{
	// Sharp corner
	if (G==0u) return max(abs(pos.x), abs(pos.y)); // G0
	// Higher-power length function
	pos = pow(abs(pos), ++G); // Power of G+1
	return pow(pos.x+pos.y, rcp(G)); // Power G+1 root
}

/**
Linear pixel step function for anti-aliasing by Jakub Max Fober.
This algorithm is part of scientific paper:
	arXiv: 20104077 [cs.GR] (2020)
*/
float aastep(float grad)
{
	// Differential vector
	float2 Del = float2(ddx(grad), ddy(grad));
	// Gradient normalization to pixel size, centered at the step edge
	return saturate(rsqrt(dot(Del, Del))*grad+0.5); // half-pixel offset
}

/**
Universal perspective model by Jakub Max Fober,
Gnomonic to custom perspective variant.
This algorithm is part of a scientific paper:
	arXiv: 2003.10558 [cs.GR] (2020)
	arXiv: 2010.04077 [cs.GR] (2020)
Input data:
	FOV -> Camera Field of View in degrees.
	viewCoord -> screen coordinates [-1, 1] in R^2,
		where point [0 0] is at the center of the screen.
	k -> distortion parameter [-1, 1] in R
	s -> anamorphic squeeze power [1, 2] in R
Output data:
	vignette -> vignetting mask in linear space
	viewCoord -> texture lookup perspective coordinates
*/
float UniversalPerspective_vignette(inout float2 viewCoord, float k, float s) // Returns vignette
{
	// Get half field of view
	const float halfOmega = radians(FOV*0.5);

	// Get radius
	float R = (s==1f)?
		dot(viewCoord, viewCoord) : // Spherical
		(viewCoord.x*viewCoord.x)+(viewCoord.y*viewCoord.y)/s; // Anamorphic
	float rcpR = rsqrt(R); R = sqrt(R);

	// Get incident angle
	float theta;
	     if (k>0f) theta = atan(tan(k*halfOmega)*R)/k;
	else if (k<0f) theta = asin(sin(k*halfOmega)*R)/k;
	else /*k==0f*/ theta = halfOmega*R;

	// Generate vignette
	float vignetteMask;
	if (UseVignette && !DebugPreview)
	{
		// Limit FOV span, k+- in [0.5, 1] range
		float thetaLimit = max(abs(k), 0.5)*theta;
		// Create spherical vignette
		vignetteMask = cos(thetaLimit);
		vignetteMask = lerp(
			vignetteMask, // Cosine law of illumination
			vignetteMask*vignetteMask, // Inverse square law
			clamp(k+0.5, 0f, 1f) // For k in [-0.5, 0.5] range
		);
		// Anamorphic vignette
		if (s!=1f)
		{
			// Get anamorphic-incident 3D vector
			float3 perspVec = float3((sin(theta)*rcpR)*viewCoord, cos(theta));
			vignetteMask /= dot(perspVec, perspVec); // Inverse square law
		}
	}
	else // Bypass
		vignetteMask = 1f;

	// Radius for gnomonic projection wrapping
	const float rTanHalfOmega = rcp(tan(halfOmega));
	// Transform screen coordinates and normalize to FOV
	viewCoord *= tan(theta)*rcpR*rTanHalfOmega;

	// Return vignette
	return vignetteMask;
}

// Inverse transformation of universal perspective algorithm
float UniversalPerspective_inverse(float2 viewCoord, float k, float s) // Returns reciprocal radius
{
	// Get half field of view
	const float halfOmega = radians(FOV*0.5);

	// Get incident vector
	float3 incident;
	incident.xy = viewCoord;
	incident.z = rcp(tan(halfOmega));

	// Get theta angle
	float theta = (s==1f)?
		acos(normalize(incident).z) : // Spherical
		acos(incident.z*rsqrt((incident.y*incident.y)/s+dot(incident.xz, incident.xz))); // Anamorphic

	// Get radius
	float R;
	     if (k>0f) R = tan(k*theta)/tan(k*halfOmega);
	else if (k<0f) R = sin(k*theta)/sin(k*halfOmega);
	else /*k==0f*/ R = theta/halfOmega;

	// Calculate transformed position reciprocal radius
	if (s==1f) return R*rsqrt(dot(viewCoord, viewCoord));
	else return R*rsqrt((viewCoord.y*viewCoord.y)/s+(viewCoord.x*viewCoord.x));
}


  //////////////
 /// SHADER ///
//////////////

// Border mask shader with rounded corners
float GetBorderMask(float2 borderCoord)
{
	// Get coordinates for each corner
	borderCoord = abs(borderCoord);
	if (BorderGContinuity!=0u && BorderCorner!=0f) // If round corners
	{
		// Correct corner aspect ratio
		if (BUFFER_ASPECT_RATIO>1f) // If in landscape mode
			borderCoord.x = borderCoord.x*BUFFER_ASPECT_RATIO+(1f-BUFFER_ASPECT_RATIO);
		else if (BUFFER_ASPECT_RATIO<1f) // If in portrait mode
			borderCoord.y = borderCoord.y*BUFFER_RCP_ASPECT_RATIO+(1f-BUFFER_RCP_ASPECT_RATIO);
		// Generate scaled coordinates
		borderCoord = max(borderCoord+(BorderCorner-1f), 0f)/BorderCorner;

		// Round corner
		return aastep(glength(BorderGContinuity, borderCoord)-1f); // ...with G1 to G3 continuity
	}
	else // Just sharp corner, G0
		return aastep(glength(0u, borderCoord)-1f);
}

// Debug view mode shader
void DebugModeViewPass(inout float3 display, float2 sphCoord)
{
	// Define Mapping color
	const float3   underSmpl = TO_LINEAR_GAMMA_HQ(float3(1f, 0f, 0.2)); // Red
	const float3   superSmpl = TO_LINEAR_GAMMA_HQ(float3(0f, 1f, 0.5)); // Green
	const float3 neutralSmpl = TO_LINEAR_GAMMA_HQ(float3(0f, 0.5, 1f)); // Blue

	// Calculate Pixel Size difference
	float pixelScaleMap;
	// and simulate Dynamic Super Resolution (DSR) scalar
	pixelScaleMap  = ResScaleScreen*BUFFER_PIXEL_SIZE.x*BUFFER_PIXEL_SIZE.y;
	pixelScaleMap /= ResScaleVirtual*ddx(sphCoord.x)*ddy(sphCoord.y);
	pixelScaleMap -= 1f;

	// Generate super-sampled/under-sampled color map
	float3 resMap = lerp(
		superSmpl,
		underSmpl,
		step(0f, pixelScaleMap)
	);

	// Create black-white gradient mask of scale-neutral pixels
	pixelScaleMap = saturate(1f-4f*abs(pixelScaleMap)); // Clamp to more representative values

	// Color neutral scale pixels
	resMap = lerp(resMap, neutralSmpl, pixelScaleMap);

	// Blend color map with display image
	display = (0.8*dot(LumaMtx, display)+0.2)*resMap;
}

// Main perspective shader pass
float3 PerfectPerspectivePS(float4 pixelPos : SV_Position, float2 sphCoord : TEXCOORD0) : SV_Target
{
	// Bypass
	if (FOV==0u || ExpertMode && K==1f && !UseVignette)
		return tex2Dfetch(BackBuffer, uint2(pixelPos.xy)).rgb;

	#if SIDE_BY_SIDE_3D // Side-by-side 3D content
		float SBS3D = sphCoord.x*2f;
		sphCoord.x = frac(SBS3D);
		SBS3D = floor(SBS3D);
	#endif

	// Convert UV to centered coordinates
	sphCoord = sphCoord*2f-1f;
	// Correct aspect ratio
	sphCoord.y *= BUFFER_RCP_ASPECT_RATIO;

	// Get FOV type scalar
	float FovScalar; switch(FovType)
	{
		// Horizontal
		default: FovScalar = 1f; break;
		// Diagonal
		case 1: FovScalar = sqrt(BUFFER_RCP_ASPECT_RATIO*BUFFER_RCP_ASPECT_RATIO+1f); break;
		// Vertical
		case 2: FovScalar = BUFFER_RCP_ASPECT_RATIO; break;
		// Horizontal 4:3
		case 3: FovScalar = (4f/3f)*BUFFER_RCP_ASPECT_RATIO; break;
		// Horizontal 16:9
		case 4: FovScalar = (16f/9f)*BUFFER_RCP_ASPECT_RATIO; break;
	}

	// Adjust FOV type
	sphCoord /= FovScalar; // pass 1 of 2

	// Set perspective parameters
	float k, s; // Projection type and anamorphic squeeze factor
	if (!ExpertMode) // Perspective expert mode
	{
		// Choose projection type
		switch (Projection)
		{
			case 0u: k =  0.5; break; // Stereographic
			case 1u: k =  0f;  break; // Equidistant
			case 2u: k = -0.5; break; // Equisolid
		}

		// Choose anamorphic squeeze factor
		switch (AnamorphicSqueeze)
		{
			case 0u: s = 1f; break;
			case 1u: s = 1.25; break;
			// case 1u: s = 1.333; break;
			case 2u: s = 1.5; break;
			// case 2u: s = 1.6; break;
			case 3u: s = 2f; break;
		}
	}
	else // Manual perspective
	{
		k = clamp(K,-1f, 1f); // Projection type
		s = clamp(S, 1f, 4f); // Anamorphic squeeze factor
	}

	// Scale picture to cropping point
	{
		// Get cropping positions: vertical, horizontal, diagonal
		float2 normalizationPos[3u];
		normalizationPos[0u].x      // Vertical crop
			= normalizationPos[1u].y // Horizontal crop
			= 0f;
		normalizationPos[2u].x      // Diagonal crop
			= normalizationPos[1u].x // Horizontal crop
			= rcp(FovScalar);
		normalizationPos[2u].y      // Diagonal crop
			= normalizationPos[0u].y // Vertical crop
			= normalizationPos[2u].x*BUFFER_RCP_ASPECT_RATIO;

		// Get cropping option scalar
		float crop = CroppingFactor*2f;
		// Interpolate between cropping states
		sphCoord *= lerp(
			UniversalPerspective_inverse(normalizationPos[uint(floor(crop))], k, s),
			UniversalPerspective_inverse(normalizationPos[uint( ceil(crop))], k, s),
			frac(crop) // Weight interpolation
		);
	}

	// Perspective transform and create vignette
	float vignetteMask = UniversalPerspective_vignette(sphCoord, k, s);

	// Adjust FOV type
	sphCoord *= FovScalar; // pass 2 of 2

	// Aspect Ratio back to square
	sphCoord.y *= BUFFER_ASPECT_RATIO;

	// Outside border mask with anti-aliasing
	float borderMask = GetBorderMask(sphCoord);

	// Back to UV Coordinates
	sphCoord = sphCoord*0.5+0.5;

	#if SIDE_BY_SIDE_3D // Side-by-side 3D content
		sphCoord.x = (sphCoord.x+SBS3D)*0.5;
	#endif

	// Sample display image
	float3 display = (k==1f)?
		tex2Dfetch(BackBuffer, uint2(pixelPos.xy)).rgb : // No perspective change
		tex2D(BackBuffer, sphCoord).rgb; // Spherical perspective

	#if BUFFER_COLOR_BIT_DEPTH == 10 // Manually correct gamma
		display = TO_LINEAR_GAMMA_HQ(display);
	#endif

	if (k!=1f && CroppingFactor!=1f) // Visible borders
	{
		// Get border
		float3 border = lerp(
			// Border background
			MirrorBorder? display : tex2Dfetch(BackBuffer, uint2(pixelPos.xy)).rgb,
			// Border color
			TO_LINEAR_GAMMA_HQ(BorderColor.rgb),
			// Border alpha
			TO_LINEAR_GAMMA_HQ(BorderColor.a)
		);

		// Apply vignette with border
		display = BorderVignette?
			vignetteMask*lerp(display, border, borderMask) : // Vignette on border
			lerp(vignetteMask*display, border, borderMask);  // Vignette only inside
	}
	else
		display *= vignetteMask; // Apply vignette

	// Output type choice
	if (DebugPreview) DebugModeViewPass(display, sphCoord);

	#if BUFFER_COLOR_BIT_DEPTH == 10 // Manually correct gamma
		return TO_DISPLAY_GAMMA_HQ(display);
	#else
		return display;
	#endif
}


  //////////////
 /// OUTPUT ///
//////////////

technique PerfectPerspective <
	ui_label = "完美视角";
	ui_tooltip =
		"调整视角以获得无失真的画面:\n"
		" * 鱼眼\n"
		" * 帕尼尼(panini)\n"
		" * 失真\n"
		" * (自然) 暗角\n\n"
		"说明:\n\n"
		"首先选择适当的FOV角度和类型。\n如果FOV类型未知，在游戏中找到一个圆形物体，正面看它，然后旋转摄像机，使该物体位于角落。\n将挤压系数改为1倍，并调整FOV类型，使物体不具有鸡蛋形状，而是一个完美的圆形形状。\n其次根据游戏风格调整视角类型。\n如果你主要看地平线，可以增加变形挤压。如果是曲面显示校正，则设置得更高。\n第三，调整可见边界。\n你可以改变裁剪系数，使之没有边界可见，或没有图像区域丢失。此外，为了获得清晰的图像，可以使用FilmicSharpen.fx或在超级分辨率下运行游戏。\n调试选项可以帮助你找到合适的值。\n\n"
		"算法是以下科学论文的一部分:\n"
		"arXiv: 2003.10558 [cs.GR] (2020)\n"
		"arXiv: 2010.04077 [cs.GR] (2020)\n";
>
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = PerfectPerspectivePS;

		// Linear workflow
		#if BUFFER_COLOR_BIT_DEPTH != 10
			SRGBWriteEnable = true;
		#endif
	}
}
