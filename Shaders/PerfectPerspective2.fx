/**
Pantomorphic PS, version 4.5.0
(c) 2021 Jakub Maksymilian Fober (the Author).

The Author provides this shader (the Work)
under the Creative Commons CC BY-NC-ND 3.0 license available online at
	http://creativecommons.org/licenses/by-nc-nd/3.0/.
The Author further grants permission for reuse of screen-shots and game-play
recordings derived from the Work, provided that the reuse is for the purpose of
promoting and/or summarizing the Work, or is a part of an online forum post or
social media post and that any use is accompanied by a link to the Work and a
credit to the Author. (crediting Author by pseudonym "Fubax" is acceptable)

For all other uses and inquiries please contact the Author,
jakub.m.fober@pm.me
For updates visit GitHub repository,
https://github.com/Fubaxiusz/fubax-shaders


版权所有(C) 2021 Jakub Maksymilian Fober (作者)。

作者基于“署名-非商业性使用-禁止演绎 4.0 国际”协议(https://creativecommons.org/licenses/by-nc-nd/4.0/deed.zh)
来提供此着色器。
作者还允许重新使用来自作品(此着色器)的屏幕截图和游戏录像画面，
但再使用的目的是为了推进和/或总结作品，或作为在线论坛帖子或社交媒体帖子的一部分。
而且任何使用都必须附有作品的链接和对作者的版权。(可使用笔名 "Fubax "注明作者的名字)

对于其他方式的使用与咨询请联系作者：jakub.m.fober@pm.me
更新请访问Github仓库 https://github.com/Fubaxiusz/fubax-shaders/
*/


  ////////////
 /// MENU ///
////////////

// FIELD OF VIEW

uniform int FovAngle <
	ui_type = "slider";
	ui_category = "游戏视场"; ui_category_closed = false;
	ui_label = "视场(FOV)角度";
	ui_tooltip = "设置视场角度符合游戏中的视场角度(以角度为单位)";
	ui_step = 0.2;
	ui_min = 0; ui_max = 170;
> = 90;

uniform int FovType <
	ui_type = "combo";
	ui_category = "游戏视场";
	ui_label = "视场(FOV)类型";
	ui_tooltip = 
		"这个设置应该与游戏特定的FOV类型相匹配 \n提示: 如果图像在运动中隆起（FOV太高），把它改为 \"对角线\"。\n当比例在外围被扭曲时（FOV太低），选择 \"垂直 \"或 \"4:3\"。对于超宽显示屏，你可能想用'16:9'代替。\n调整后，圆形物体在转角处仍然是圆形，而不是长方形。\n倾斜头部以看得更清楚。\n* 这个方法只在 \"形状 \"预设中起作用，或者在专家模式下k=0.5。";
	ui_items =
		"水平的\0"
		"对角线的\0"
		"垂直的\0"
		"4:3\0"
		"16:9\0";
> = 0;

// PERSPECTIVE

uniform int SimplePresets <
	ui_type = "radio";
	ui_category = "预设"; ui_category_closed = false;
	ui_label = "游戏风格";
	ui_tooltip = "选择喜欢的游戏风格。\n\n"
		"射击     [0.0 0.75 -0.5]  (aiming, panini, distance)\n"
		"竞速     [0.5 -0.5 0.0]   (cornering, distance, speed)\n"
		"滑冰     [0.5 0.5]        (stereographic lens)\n"
		"飞行     [-0.5 0.0]       (distance, pitch)\n"
		"立体视觉  [0.0 -0.5]       (aiming, distance)\n"
		"电影     [0.618 0.862]    (panini-anamorphic)\n";
	ui_items =
		"射击 (as.)\0"
		"竞速 (as.)\0"
		"滑冰 (ref.)\0"
		"飞行\0"
		"立体视觉\0"
		"电影\0";
> = 0;

uniform bool Manual <
	ui_type = "input";
	ui_category = "手动"; ui_category_closed = true;
	ui_label = "开启手动";
	ui_tooltip = "手动改变水平和垂直透视。";
> = false;

uniform bool AsymmetricalManual <
	ui_type = "input";
	ui_category = "手动";
	ui_label = "开启不对称";
	ui_spacing = 1;
	ui_tooltip = "第三个选项驱动屏幕的下半部分。";
> = false;

uniform int PresetKx <
	ui_type = "list";
	ui_category = "手动";
	ui_label = "水平透视";
	ui_tooltip = "Kx\n"
		"\n水平轴的投影类型。";
	ui_items =
		"形状,角度\0"
		"速度,瞄准\0"
		"距离,大小\0";
> = 0;

uniform int PresetKy <
	ui_type = "list";
	ui_category = "手动";
	ui_label = "垂直透视";
	ui_tooltip = "Ky\n"
		"\n垂直轴的投影类型。";
	ui_items =
		"形状,角度\0"
		"速度,瞄准\0"
		"距离,大小\0";
> = 0;

uniform int PresetKz <
	ui_type = "list";
	ui_category = "手动";
	ui_label = "垂直底部 (as.)";
	ui_tooltip = "Kz\n"
		"\n底部垂直轴的投影类型。\n"
		"是不对称透视。";
	ui_items =
		"形状,角度\0"
		"速度,瞄准\0"
		"距离,大小\0";
> = 0;


uniform bool Expert <
	ui_type = "input";
	ui_category = "专家"; ui_category_closed = true;
	ui_label = "开启专家模式";
	ui_tooltip = "手动改变各种形状的K值。";
> = false;

uniform bool AsymmetricalExpert <
	ui_type = "input";
	ui_category = "专家";
	ui_label = "开启不对称";
	ui_spacing = 1;
	ui_tooltip = "K的第三个值，驱动屏幕的下半部分。";
> = false;

uniform float3 K <
	ui_type = "slider";
	ui_category = "专家";
	ui_label = "K各种形态";
	ui_tooltip =
		"K 1 直线投影（标准），保留直线，但不保留比例、角度或比例。\nK 0.5 立体投影（导航，形状），保留角度和比例，最适合在狭小空间内导航。\nK 0 等距（瞄准）保持运动的角度速度，最适合于瞄准快速目标。\nK -0.5 等距投影（距离）保留了面积关系，最适合在开放空间的导航。\nK -1 正投影保留了平面亮度的余弦律，具有极端的径向压缩。在窥视器中发现。";
	ui_min = -1; ui_max = 1;
> = float3(1, 1, 1);

// BORDER

uniform float Zoom <
	ui_type = "drag";
	ui_category = "边框设置"; ui_category_closed = true;
	ui_label = "缩放图像";
	ui_tooltip = "调整图像缩放与裁剪区域";
	ui_min = 0.8; ui_max = 1.5; ui_step = 0.001;
> = 1;

uniform float4 BorderColor <
	ui_type = "color";
	ui_category = "边框设置";
	ui_label = "边框颜色";
	ui_tooltip = "使用Alpha来改变透明度";
> = float4(0.027, 0.027, 0.027, 0.5);


uniform float BorderCorners <
	ui_type = "slider";
	ui_category = "边框设置";
	ui_label = "边角圆化";
	ui_spacing = 2;
	ui_tooltip = "代表角度的曲率。\n"
		"0的时候是尖锐的角度。";
	ui_min = 0; ui_max = 1;
> = 0.0862;

uniform bool MirrorBorder <
	ui_type = "input";
	ui_category = "边框设置";
	ui_label = "镜像背景";
	ui_tooltip = "选择边框上的原始或镜像图像。";
> = true;

uniform int VignettingStyle <
	ui_type = "radio";
	ui_category = "边框设置";
	ui_label = "暗角风格";
	ui_spacing = 1;
	ui_tooltip = "自动暗角的渲染选项。";
	ui_items =
		"暗角关闭\0"
		"暗角内部\0"
		"边框上暗角\0";
> = 1;

#ifndef G_CONTINUITY_CORNER_ROUNDING
	#define G_CONTINUITY_CORNER_ROUNDING 2
#endif

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
	AddressU = MIRROR;
	AddressV = MIRROR;
	#if BUFFER_COLOR_BIT_DEPTH != 10
		SRGBTexture = true;
	#endif
};


  /////////////////
 /// FUNCTIONS ///
/////////////////

// Get reciprocal screen aspect ratio (1/x)
#define BUFFER_RCP_ASPECT_RATIO (BUFFER_HEIGHT*BUFFER_RCP_WIDTH)
// Convert to linear gamma all vector types
#define sRGB_TO_LINEAR(g) pow(abs(g), 2.2)
/**
Linear pixel step function for anti-aliasing by Jakub Max Fober.
This algorithm is part of scientific paper:
	arXiv: 20104077 [cs.GR] (2020)
*/
float aastep(float grad)
{
	float2 Del = float2(ddx(grad), ddy(grad));
	return saturate(rsqrt(dot(Del, Del))*grad+0.5);
}

/**
G continuity distance function by Jakub Max Fober.
Determined empirically. (G from 0, to 3)
	G=0 -> Sharp corners
	G=1 -> Round corners
	G=2 -> Smooth corners
	G=3 -> Luxury corners
*/
float glength(int G, float2 pos)
{
	if (G<=0) return max(abs(pos.x), abs(pos.y)); // G0
	pos = pow(abs(pos), ++G); // Power of G+1
	return pow(pos.x+pos.y, rcp(G)); // Power G+1 root
}

/**
Pantomorphic perspective model by Jakub Max Fober,
Gnomonic to anamorphic-fisheye variant.
This algorithm is a part of scientific paper:
	arXiv: 2102.12682 [cs.GR] (2021)
Input data:
	k [x, y]  -> distortion parameter (from -1, to 1).
	halfOmega -> Camera half Field of View in radians.
	viewcoord -> view coordinates (centered at 0), with correct aspect ratio.
Output data:
	viewcoord -> rectilinear lookup view coordinates
	vignette  -> vignetting mask in linear space
*/
float pantomorphic(float halfOmega, float2 k, inout float2 viewcoord)
{
	// Bypass
	if (halfOmega==0.0) return 1.0;

	// Get reciprocal focal length from horizontal FOV
	float rcp_f;
	{
		// Horizontal
		if      (k.x>0.0) rcp_f = tan(k.x*halfOmega)/k.x;
		else if (k.x<0.0) rcp_f = sin(k.x*halfOmega)/k.x;
		else              rcp_f = halfOmega;
	}

	// Get radius
	float r = length(viewcoord);

	// Get incident angle
	float2 theta2;
	{
		// Horizontal
		if      (k.x>0.0) theta2.x = atan(r*k.x*rcp_f)/k.x;
		else if (k.x<0.0) theta2.x = asin(r*k.x*rcp_f)/k.x;
		else              theta2.x = r*rcp_f;
		// Vertical
		if      (k.y>0.0) theta2.y = atan(r*k.y*rcp_f)/k.y;
		else if (k.y<0.0) theta2.y = asin(r*k.y*rcp_f)/k.y;
		else              theta2.y = r*rcp_f;
	}

	// Get phi interpolation weights
	float2 philerp = viewcoord*viewcoord; philerp /= philerp.x+philerp.y; // cos^2 sin^2 of phi angle

	// Generate vignette
	float vignetteMask; if (VignettingStyle!=0)
	{	// Limit FOV span, k-+ in [0.5, 1] range
		float2 vignetteMask2 = cos(max(abs(k), 0.5)*theta2);
		// Mix cosine-law of illumination and inverse-square law
		vignetteMask2 = pow(abs(vignetteMask2), k*0.5+1.5);
		// Blend horizontal and vertical vignetting
		vignetteMask = dot(vignetteMask2, philerp);
	} else vignetteMask = 1.0; // Bypass

	// Blend projections
	float theta = dot(theta2, philerp);
	// Transform screen coordinates and normalize to FOV
	viewcoord *= tan(theta)/(tan(halfOmega)*r);

	return vignetteMask;
}


  //////////////
 /// SHADER ///
//////////////

// Border mask shader with rounded corners
float BorderMaskPS(float2 borderCoord)
{
	// Get coordinates for each corner
	borderCoord = abs(borderCoord);
	if (BorderCorners!=0.0) // If round corners
	{
		// Correct corner aspect ratio
		if (BUFFER_ASPECT_RATIO>1.0) // If in landscape mode
			borderCoord.x = borderCoord.x*BUFFER_ASPECT_RATIO+(1.0-BUFFER_ASPECT_RATIO);
		else if (BUFFER_ASPECT_RATIO<1.0) // If in portrait mode
			borderCoord.y = borderCoord.y*BUFFER_RCP_ASPECT_RATIO+(1.0-BUFFER_RCP_ASPECT_RATIO);
		// Generate scaled coordinates
		borderCoord = max(borderCoord+(BorderCorners-1.0), 0.0)/BorderCorners;
		// Round corner
		return aastep(glength(G_CONTINUITY_CORNER_ROUNDING, borderCoord)-1.0); // with G1 to 3 continuity
	} // Just sharp corner, G0
	else return aastep(glength(0, borderCoord)-1.0);
}

// Main perspective shader pass
float3 PantomorphicPS(float4 pos : SV_Position, float2 texCoord : TEXCOORD) : SV_Target
{
#if SIDE_BY_SIDE_3D
	// Side-by-side 3D content
	float SBS3D = texCoord.x*2f;
	texCoord.x = frac(SBS3D);
	SBS3D = floor(SBS3D);
#endif

	// Convert FOV to horizontal
	float halfHorizontalFov = tan(radians(FovAngle*0.5));
	// Scale to horizontal tangent
	switch(FovType)
	{
		// Diagonal
		case 1: halfHorizontalFov *= rsqrt(BUFFER_RCP_ASPECT_RATIO*BUFFER_RCP_ASPECT_RATIO+1); break;
		// Vertical
		case 2: halfHorizontalFov *= BUFFER_ASPECT_RATIO; break;
		// Horizontal 4:3
		case 3: halfHorizontalFov *= (3.0/4.0)*BUFFER_ASPECT_RATIO; break;
		// case 3: halfHorizontalFov /= (4.0/3.0)*BUFFER_RCP_ASPECT_RATIO; break;
		// Horizontal 16:9
		case 4: halfHorizontalFov *= (9.0/16.0)*BUFFER_ASPECT_RATIO; break;
		// case 4: halfHorizontalFov /= (16.0/9.0)*BUFFER_RCP_ASPECT_RATIO; break;
		// ...more
	}
	// Half-horizontal FOV in radians
	halfHorizontalFov = atan(halfHorizontalFov);

	// Convert UV to centered coordinates
	float2 sphCoord = texCoord*2.0-1.0;
	// Aspect Ratio correction
	sphCoord.y *= BUFFER_RCP_ASPECT_RATIO;
	// Zooming
	sphCoord *= clamp(Zoom, 0.8, 1.5); // Anti-cheat clamp

	// Manage presets
	float2 k;
	if (Expert) k = clamp(
		// Create asymmetrical anamorphic
		(AsymmetricalExpert && sphCoord.y >= 0.0)? K.xz : K.xy,
		-1.0, 1.0);
	else if (Manual)
	{
		switch (PresetKx)
		{
			default: k.x =  0.5; break; // x Shape/angle
			case 1:  k.x =  0.0; break; // x Speed/aim
			case 2:  k.x = -0.5; break; // x Distance/size
			// ...more
		}
		switch ((AsymmetricalManual && sphCoord.y >= 0.0)? PresetKz : PresetKy)
		{
			default: k.y =  0.5; break; // y Shape/angle
			case 1:  k.y =  0.0; break; // y Speed/aim
			case 2:  k.y = -0.5; break; // y Distance/size
			// ...more
		}
	}
	else switch (SimplePresets)
	{
		default: k = float2( 0.0, sphCoord.y < 0.0? 0.75 :-0.5); break; // Shooting
		case 1:  k = float2( 0.5, sphCoord.y < 0.0?-0.5  : 0.0); break; // Racing
		case 2:  k = float2( 0.5, 0.5); break; // Skating (reference)
		case 3:  k = float2(-0.5, 0.0); break; // Flying
		case 4:  k = float2( 0.0,-0.5); break; // Stereopsis
		case 5:  k = float2( 0.618, 0.862); break; // Cinematic
		// ...more
	}

	// Perspective transform and create vignette
	float vignetteMask = pantomorphic(halfHorizontalFov, k, sphCoord);

	// Aspect Ratio back to square
	sphCoord.y *= BUFFER_ASPECT_RATIO;
	// Get no-border flag
	bool noBorder = VignettingStyle!=1 && BorderColor.a==0.0 && MirrorBorder;
	// Outside border mask with Anti-Aliasing
	float borderMask = noBorder? 0f : BorderMaskPS(sphCoord);
	// Back to UV Coordinates
	sphCoord = sphCoord*0.5+0.5;

#if SIDE_BY_SIDE_3D
	// Side-by-side 3D content
	sphCoord.x = (sphCoord.x+SBS3D)*0.5;
	texCoord.x = (texCoord.x+SBS3D)*0.5;
#endif

	// Sample display image
	float3 display = tex2D(BackBuffer, sphCoord).rgb;
	// Return image if no border is visible
	if (noBorder) return vignetteMask*display;

	// Mask outside-border pixels or mirror
	if (VignettingStyle==2)
		return vignetteMask*lerp(
			display,
			lerp(
				MirrorBorder? display : tex2D(BackBuffer, texCoord).rgb,
				sRGB_TO_LINEAR(BorderColor.rgb),
				sRGB_TO_LINEAR(BorderColor.a)
			), borderMask);
	else return lerp(
		vignetteMask*display,
		lerp(
			MirrorBorder? display : tex2D(BackBuffer, texCoord).rgb,
			sRGB_TO_LINEAR(BorderColor.rgb),
			sRGB_TO_LINEAR(BorderColor.a)
		), borderMask);
}


  //////////////
 /// OUTPUT ///
//////////////

technique Pantomorphic <
	ui_tooltip =
		"调整视角以获得无扭曲的画面（不对称的变形、鱼眼和晕影）\n\n手动:\n首先选择适当的FOV角度和类型。如果FOV类型未知，将预设设置为 \"滑雪\"，并在游戏中找到一个圆形物体，正面观察，然后旋转摄像机，使物体位于角落。\n改变FOV类型，使该物体没有蛋的形状，而是一个完美的圆形。\n第二根据游戏风格调整透视类型。\n第三，调整可见边界。你可以放大图片来隐藏边框并显示UI。\n此外，为了获得清晰的图像，请使用FilmicSharpen.fx或以超级分辨率运行游戏。";ui_label="视角自由变化";
>
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = PantomorphicPS;
		SRGBWriteEnable = true;
	}
}
