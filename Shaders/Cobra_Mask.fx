////////////////////////////////////////////////////////////////////////////////////////////////////////
// Cobra_Mask.fx by SirCobra
// Version 0.2
// You can find info and my repository here: https://github.com/LordKobra/CobraFX
// This effect is designed to be used with the ColorSort and Gravity shader, to apply a Mask with
// similar settings to the scene. All shaders between Cobra_Masking_Start and Cobra_Masking_End
// are only affecting the unmasked area.
// The effect can be applied to a specific area like a DoF shader. The basic methods for this were taken with permission
// from https://github.com/FransBouma/OtisFX/blob/master/Shaders/Emphasize.fx
////////////////////////////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////////////////////////////
//***************************************                  *******************************************//
//***************************************   UI & Defines   *******************************************//
//***************************************                  *******************************************//
////////////////////////////////////////////////////////////////////////////////////////////////////////
// Translation of the UI into Chinese by Lilidream.

// Shader Start
#include "Reshade.fxh"

// Namespace everything
namespace Cobra_Masking
{

	//defines
	#define MASKING_M "一般选项\n"
	#define MASKING_C "颜色选项\n"
	#define MASKING_D "深度遮罩\n"

	#ifndef M_PI
		#define M_PI 3.1415927
	#endif

	//ui
	uniform int Buffer1 <
		ui_type = "radio"; ui_label = " ";
	>;	
	uniform bool InvertMask <
		ui_label = "反转遮罩";
		ui_tooltip = "反转遮罩";
		ui_category = MASKING_M;
	> = false;
	uniform bool ShowMask <
		ui_label = "显示遮罩";
		ui_tooltip = "显示被遮住的像素";
		ui_category = MASKING_M;
	> = false;
	uniform int Buffer2 <
		ui_type = "radio"; ui_label = " ";
	>;
	uniform bool FilterColor <
		ui_label = "过滤颜色";
		ui_tooltip = "激活颜色过滤选项";
		ui_category = MASKING_C;
	> = false;
	uniform bool ShowSelectedHue <
		ui_label = "显示已选Hue";
		ui_tooltip = "在画面顶部显示已选的hue范围";
		ui_category = MASKING_C;
	> = false;
	uniform float Value <
		ui_label = "值";
		ui_type = "slider";
		ui_min = 0.000; ui_max = 1.001;
		ui_step = 0.001;
		ui_tooltip = "值描述了hue的亮度。0是黑色/无hue，1是最大hue";
		ui_category = MASKING_C;
	> = 1.0;
	uniform float ValueRange <
		ui_label = "值范围";
		ui_type = "slider";
		ui_min = 0.000; ui_max = 1.001;
		ui_step = 0.001;
		ui_tooltip = "值的容差范围";
		ui_category = MASKING_C;
	> = 1.0;
	uniform float ValueEdge <
		ui_label = "值边缘";
		ui_type = "slider";
		ui_min = 0.000; ui_max = 1.000;
		ui_step = 0.001;
		ui_tooltip = "值范围上的平滑程度";
		ui_category = MASKING_C;
	> = 0.0;
	uniform float Hue <
		ui_label = "Hue";
		ui_type = "slider";
		ui_min = 0.000; ui_max = 1.000;
		ui_step = 0.001;
		ui_tooltip = "Hue描述了颜色分类。他可以是红、绿、蓝或它们的混合。";
		ui_category = MASKING_C;
	> = 1.0;
	uniform float HueRange <
		ui_label = "Hue范围";
		ui_type = "slider";
		ui_min = 0.000; ui_max = 0.500;
		ui_step = 0.001;
		ui_tooltip = "Hue的容差";
		ui_category = MASKING_C;
	> = 0.5;
	uniform float Saturation <
		ui_label = "饱和度";
		ui_type = "slider";
		ui_min = 0.000; ui_max = 1.000;
		ui_step = 0.001;
		ui_tooltip = "色彩饱和度。0为黑白，1为全彩。";
		ui_category = MASKING_C;
	> = 1.0;
	uniform float SaturationRange <
		ui_label = "饱和度范围";
		ui_type = "slider";
		ui_min = 0.000; ui_max = 1.000;
		ui_step = 0.001;
		ui_tooltip = "饱和度的容差范围";
		ui_category = MASKING_C;
	> = 1.0;
	uniform int Buffer3 <
		ui_type = "radio"; ui_label = " ";
	>;
	uniform bool FilterDepth <
		ui_label = "过滤器深度";
		ui_tooltip = "激活深度过滤器选项";
		ui_category = MASKING_D;
	> = false;
	uniform float FocusDepth <
		ui_label = "对焦深度";
		ui_type = "slider";
		ui_min = 0.000; ui_max = 1.000;
		ui_step = 0.001;
		ui_tooltip = "手动对焦平面。0表示镜头位置，1表示地平线。";
		ui_category = MASKING_D;
	> = 0.026;
	uniform float FocusRangeDepth <
		ui_label = "对焦深度范围";
		ui_type = "slider";
		ui_min = 0.0; ui_max = 1.000;
		ui_step = 0.001;
		ui_tooltip = "着色器效果生效的手动对焦深度周围的范围。在这个范围之外，着色器效果不生效。";
		ui_category = MASKING_D;
	> = 0.010;	
	uniform float FocusEdgeDepth <
		ui_label = "对焦深度边缘过渡";
		ui_type = "slider";
		ui_min = 0.000; ui_max = 1.000;
		ui_tooltip = "对焦范围的边缘过渡平滑程度。 0表示硬边缘，着色器效果在对焦范围边缘硬变化，1为边缘过渡至无穷远。";
		ui_step = 0.001;
	> = 0.050;
	uniform bool Spherical <
		ui_label = "球形";
		ui_tooltip = "将遮罩区域调整为球形而不是平面。";
		ui_category = MASKING_D;
	> = false;
	uniform int Sphere_FieldOfView <
		ui_label = "球的视场";
		ui_type = "slider";
		ui_min = 1; ui_max = 180;
		ui_tooltip = "设置你的视场，以度为单位";
		ui_category = MASKING_D;
	> = 75;
	uniform float Sphere_FocusHorizontal <
		ui_label = "球水平位置";
		ui_type = "slider";
		ui_min = 0; ui_max = 1;
		ui_tooltip = "球的水平位置，0表示屏幕左边，1表示屏幕右边。";
		ui_category = MASKING_D;
	> = 0.5;
	uniform float Sphere_FocusVertical <
		ui_label = "球垂直位置";
		ui_type = "slider";
		ui_min = 0; ui_max = 1;
		ui_tooltip = "球的水平位置，0表示屏幕上边，1表示屏幕下边。";
		ui_category = MASKING_D;
	> = 0.5;
	uniform int Buffer4 <
		ui_type = "radio"; ui_label = " ";
	>;


	////////////////////////////////////////////////////////////////////////////////////////////////////////
	//*************************************                       ****************************************//
	//*************************************  Textures & Samplers  ****************************************//
	//*************************************                       ****************************************//
	////////////////////////////////////////////////////////////////////////////////////////////////////////


	texture texMask {Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; };

	sampler2D SamplerMask { Texture = texMask; };


	////////////////////////////////////////////////////////////////////////////////////////////////////////
	//***************************************                  *******************************************//
	//*************************************** Helper Functions *******************************************//
	//***************************************                  *******************************************//
	////////////////////////////////////////////////////////////////////////////////////////////////////////


	//vector mod and normal fmod
	float3 mod(float3 x, float y) 
	{
		return x - y * floor(x / y);
	}

	//HSV functions from iq (https://www.shadertoy.com/view/MsS3Wc)
	float4 hsv2rgb(float4 c)
	{
		float3 rgb = clamp(abs(mod(float3(c.x * 6.0, c.x * 6.0 + 4.0, c.x * 6.0 + 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
		rgb = rgb * rgb * (3.0 - 2.0 * rgb); // cubic smoothing
		return float4(c.z * lerp(float3(1.0, 1.0, 1.0), rgb, c.y), 1.0);
	}

	//From Sam Hocevar: http://lolengine.net/blog/2013/07/27/rgb-to-hsv-in-glsl
	float4 rgb2hsv(float4 c)
	{
		const float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
		float4 p = lerp(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
		float4 q = lerp(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));
		float d = q.x - min(q.w, q.y);
		const float e = 1.0e-10;
		return float4(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x, 1.0);
	}

	// show the color bar. inspired by originalcodrs design
	float4 showHue(float2 texcoord, float4 fragment)
	{
		float range = 0.145;
		float depth = 0.06;
		if (abs(texcoord.x - 0.5) < range && texcoord.y < depth)
		{
			float4 hsvval = float4(saturate(texcoord.x - 0.5 + range) / (2 * range), 1, 1, 1);
			float4 rgbval = hsv2rgb(hsvval);
			bool active = min(abs(hsvval.r - Hue), (1 - abs(hsvval.r - Hue))) < HueRange;
			fragment = active ? rgbval : float4(0.5, 0.5, 0.5, 1);
		}
		return fragment;
	}


	////////////////////////////////////////////////////////////////////////////////////////////////////////
	//***************************************                  *******************************************//
	//***************************************     Masking      *******************************************//
	//***************************************                  *******************************************//
	////////////////////////////////////////////////////////////////////////////////////////////////////////

	// returns a value between 0 and 1 (1 = in focus)
	float inFocus(float4 rgbval, float scenedepth, float2 texcoord)
	{
		//colorfilter
		float4 hsvval = rgb2hsv(rgbval);
		float d1_f = abs(hsvval.b - Value) - ValueRange;
		d1_f = 1 - smoothstep(0, ValueEdge, d1_f);
		bool d2 = abs(hsvval.r - Hue) < (HueRange + pow(2.71828, -(hsvval.g * hsvval.g) / 0.005)) || (1 - abs(hsvval.r - Hue)) < (HueRange + pow(2.71828, -(hsvval.g * hsvval.g) / 0.01));
		bool d3 = abs(hsvval.g - Saturation) <= SaturationRange;
		float is_color_focus = max(d3 * d2 * d1_f, FilterColor == 0); // color threshold
		//depthfilter
		const float desaturateFullRange = FocusRangeDepth + FocusEdgeDepth;
		texcoord.x = (texcoord.x - Sphere_FocusHorizontal) * ReShade::ScreenSize.x;
		texcoord.y = (texcoord.y - Sphere_FocusVertical) * ReShade::ScreenSize.y;
		const float degreePerPixel = Sphere_FieldOfView / ReShade::ScreenSize.x;
		const float fovDifference = sqrt((texcoord.x * texcoord.x) + (texcoord.y * texcoord.y)) * degreePerPixel;
		float depthdiff = Spherical ? sqrt((scenedepth * scenedepth) + (FocusDepth * FocusDepth) - (2 * scenedepth * FocusDepth * cos(fovDifference * (2 * M_PI / 360)))) : abs(scenedepth - FocusDepth);
		float depthval = 1 - saturate((depthdiff > desaturateFullRange) ? 1.0 : smoothstep(FocusRangeDepth, desaturateFullRange, depthdiff));
		depthval = max(depthval, FilterDepth == 0);
		return is_color_focus * depthval;
	}

	void mask_start(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 fragment : SV_Target)
	{
		float4 color = tex2D(ReShade::BackBuffer, texcoord);
		float scenedepth = ReShade::GetLinearizedDepth(texcoord);
		float in_focus = inFocus(color, scenedepth, texcoord);
		in_focus = (1 - InvertMask) * in_focus + InvertMask * (1 - in_focus);
		fragment = float4(color.rgb, in_focus);
	}

	void mask_end(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 fragment : SV_Target)
	{
		fragment = tex2D(SamplerMask, texcoord);
		fragment = ShowMask ? fragment.aaaa : fragment;
		fragment = (!ShowMask) ? lerp(tex2D(ReShade::BackBuffer, texcoord), fragment, 1 - fragment.aaaa) : fragment;
		fragment = (ShowSelectedHue * FilterColor * !ShowMask) ? showHue(texcoord, fragment) : fragment;
	}


	/////////////////////////////////////////////////////////////////////////////////////////////////////////
	//*****************************************                  ******************************************//
	//*****************************************     Pipeline     ******************************************//
	//*****************************************                  ******************************************//
	/////////////////////////////////////////////////////////////////////////////////////////////////////////


	technique Cobra_Masking_Start 
	< ui_tooltip = "这是一个着色器的遮罩部分。他需要放在'Cobra遮罩结束'前面。遮罩区域被复制并保存在这里，这意味着在'开始'与'结束'之间的所有着色器的效果只会作用在没有被遮罩遮挡的地方。"; ui_label = "Cobra遮罩开始(空间遮罩)";>
	{
		pass mask { VertexShader = PostProcessVS; PixelShader = mask_start; RenderTarget = texMask; }
	}

	technique CobraFX_Masking_End < ui_tooltip = "此遮罩区域再次应用到屏幕上。"; ui_label="Cobra遮罩结束";>
	{
		pass display { VertexShader = PostProcessVS; PixelShader = mask_end; }
	}
}
