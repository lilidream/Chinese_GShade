/*
 	Tonemap by Constantine 'MadCake' Rudenko

 	License: https://creativecommons.org/licenses/by/4.0/
	CC BY 4.0
	
	You are free to:

	Share — copy and redistribute the material in any medium or format
		
	Adapt — remix, transform, and build upon the material
	for any purpose, even commercially.

	The licensor cannot revoke these freedoms as long as you follow the license terms.
		
	Under the following terms:

	Attribution — You must give appropriate credit, provide a link to the license, and indicate if changes were made. 
	You may do so in any reasonable manner, but not in any way that suggests the licensor endorses you or your use.

	No additional restrictions — You may not apply legal terms or technological measures 
	that legally restrict others from doing anything the license permits.
*/
// Translation of the UI into Chinese by Lilidream.

uniform float Contrast <
	ui_type = "slider";
	ui_min = 1.0; ui_max = 16.0; ui_step = 0.01;
	ui_tooltip = "以牺牲阴影和高光为代价，增加可见亮度范围中部的对比度。";
	ui_label = "对比度";
> = 1.0;

uniform float Compression <
	ui_type = "slider";
	ui_min = 0.001; ui_max = 16.0; ui_step = 0.01;
	ui_tooltip = "压制高光";
	ui_label = "压制";
> = 0.00001;

uniform float BlackLevel <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0; ui_step = 0.0025;
	ui_tooltip = "从最终结果中减去这个值，以补偿显示器的漫反射。";
	ui_label = "黑阶";
> = 0.0;

uniform bool DeGamma <
	ui_label = "DeGamma";
	ui_tooltip = "假设颜色是以Gamma空间存储的";
> = false;

uniform float Exposure <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 2.0; ui_step = 0.025;
	ui_tooltip = "曝光";
	ui_label = "曝光";
> = 1.0;

uniform float SaturationLuma <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 8.0; ui_step = 0.1;
	ui_label = "饱和度 (亮度)";
	ui_tooltip = "使用基于亮度的压缩，而不是基于每个颜色的压缩（增加饱和度，给人以卡通的感觉）。";
> = 0.0;

uniform float Saturation <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 4.0; ui_step = 0.1;
	ui_tooltip = "饱和度";
> = 1.0;

uniform int LumaCoefs <
        ui_type = "combo";
        ui_label = "用于饱和度计算的亮度系数";
        ui_items = "均等 (0.33,0.33,0.33)\0杆状细胞 (0.0,0.59,0.41)\0sRGB (0.2126, 0.7152, 0.0722)\0";
> = 2;

#include "ReShade.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

float3 MadCakeToneMapPass(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float3 luma;	
	switch(LumaCoefs)
	{
		case 0:
			luma = float3(0.33, 0.33, 0.33);
			break;
		case 1:
			luma = float3(0.0, 0.59, 0.41);
			break;
		default:
			luma = float3(0.2126, 0.7152, 0.0722);
			break;
	}

	float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;

	if (DeGamma)
	{
		color.rgb = pow(max(color.rgb, 0.0), 0.45454545);
	}

	color = color * Exposure;
	
	const float r = 1.0 / Compression;
	const float a_mid = pow(0.5, Contrast - (Contrast - 1.0) * 0.5);
	const float r_fix = - (a_mid * r) / (-1.0 + a_mid - r + 2 * a_mid * r);
	
	color.rgb = max(color.rgb, 0); // suppress warning
	float4 color2 = float4(color.rgb, dot(color.rgb, luma));
	color.r = pow(color.r, Contrast - (Contrast - 1.0) * color.r) * (r_fix + 1.0) / (color.r + r_fix);
	color.g = pow(color.g, Contrast - (Contrast - 1.0) * color.g) * (r_fix + 1.0) / (color.g + r_fix);
	color.b = pow(color.b, Contrast - (Contrast - 1.0) * color.b) * (r_fix + 1.0) / (color.b + r_fix);
	color2.rgb = pow(color2.rgb, Contrast - (Contrast - 1.0) * color2.w) * (r_fix + 1.0) / (color2.w + r_fix);
	
	color += (color2.rgb - color) * SaturationLuma;
	color += (dot(color, luma) - color) * (1.0 - Saturation);
	
	color.rgb = color.rgb - BlackLevel;
	if (DeGamma)
	{
		color.rgb = pow(max(color.rgb, 0.0), 2.2);
	}

#if GSHADE_DITHER
	return color + TriDither(color, texcoord, BUFFER_COLOR_BIT_DEPTH);
#else
	return color;
#endif
}

technique MC_ToneMap <ui_label="MC色调映射";>
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = MadCakeToneMapPass;
	}
}
