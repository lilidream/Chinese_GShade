/*
	Spotlight shader based on the Flashlight shader by luluco250

	MIT Licensed.

  Modifications by ninjafada and Marot Satil
*/
// Translation of the UI into Chinese by Lilidream.

#include "ReShade.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

uniform float uXCenter <
  ui_label = "X位置";
	ui_type = "slider";
	ui_min = -1.0; ui_max = 1.0;
	ui_tooltip = "光束中心的X轴位置，坐标轴开始于左上角";
> = 0;

uniform float uYCenter <
  ui_label = "Y位置";
	ui_type = "slider";
	ui_min = -1.0; ui_max = 1.0;
	ui_tooltip = "光束中心的Y轴位置，坐标轴开始于左上角";
> = 0;

uniform float uBrightness <
	ui_label = "亮度";
	ui_tooltip =
		"聚光灯光圈亮度\n"
		"\n默认: 10.0";
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 100.0;
	ui_step = 0.01;
> = 10.0;

uniform float uSize <
	ui_label = "大小";
	ui_tooltip =
		"聚光灯光圈的像素大小\n"
		"\n默认: 420.0";
	ui_type = "slider";
	ui_min = 10.0;
	ui_max = 1000.0;
	ui_step = 1.0;
> = 420.0;

uniform float3 uColor <
	ui_label = "颜色";
	ui_tooltip =
		"聚光灯光圈颜色\n"
		"\n默认: R:255 G:230 B:200";
	ui_type = "color";
> = float3(255, 230, 200) / 255.0;

uniform float uDistance <
	ui_label = "距离";
	ui_tooltip =
		"聚光灯可以照亮的距离。\n只有在游戏有深度缓存的情况下才有效。\n"
		"\n默认: 0.1";
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 1.0;
	ui_step = 0.001;
> = 0.1;

uniform bool uBlendFix <
  ui_label = "切换混合固定";
	ui_tooltip = "开启使用原始混合模式";
> = 0;

uniform bool uToggleTexture <
	ui_label = "切换贴图";
	ui_tooltip = "开启或关闭聚光灯贴图";
> = 1;

uniform bool uToggleDepth <
	ui_label = "切换深度";
	ui_tooltip = "开启或切换深度";
> = 1;

sampler2D sColor {
	Texture = ReShade::BackBufferTex;
	SRGBTexture = true;
	MinFilter = POINT;
	MagFilter = POINT;
};

#define nsin(x) (sin(x) * 0.5 + 0.5)

float4 PS_Spotlight(float4 p : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
	const float2 res = BUFFER_SCREEN_SIZE;
	const float2 uCenter = uv - float2(uXCenter, -uYCenter);
	float2 coord = res * uCenter;

	float halo = distance(coord, res * 0.5);
	float spotlight = uSize - min(halo, uSize);
	spotlight /= uSize;
	
	// Add some texture to the halo by using some sin lines + reduce intensity
	// when nearing the center of the halo.
	if (uToggleTexture == 0)
	{
		float defects = sin(spotlight * 30.0) * 0.5 + 0.5;
		defects = lerp(defects, 1.0, spotlight * 2.0);

		static const float contrast = 0.125;

		defects = 0.5 * (1.0 - contrast) + defects * contrast;
		spotlight *= defects * 4.0;
	}
	else
	{
    spotlight *= 2.0;
  }

	if (uToggleDepth == 1)
  {
    float depth = 1.0 - ReShade::GetLinearizedDepth(uv);
    depth = pow(abs(depth), 1.0 / uDistance);
    spotlight *= depth;
  }

	float3 colored_spotlight = spotlight * uColor;
	colored_spotlight *= colored_spotlight * colored_spotlight;

	float3 result = 1.0 + colored_spotlight * uBrightness;

	float3 color = tex2D(sColor, uv).rgb;
	color *= result;

	if (!uBlendFix)
    // Add some minimum amount of light to very dark pixels.	
    color = max(color, (result - 1.0) * 0.001);

#if GSHADE_DITHER
	return float4(color + TriDither(color, uv, BUFFER_COLOR_BIT_DEPTH), 1.0);
#else
	return float4(color, 1.0);
#endif
}

technique Spotlight <ui_label="聚光灯";>{
	pass {
		VertexShader = PostProcessVS;
		PixelShader = PS_Spotlight;
		SRGBWriteEnable = true;
	}
}
