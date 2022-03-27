/**
 * Tonemap version 1.1
 * by Christian Cann Schuldt Jensen ~ CeeJay.dk
 */
 // Lightly optimized by Marot Satil for the GShade project.
 // Translation of the UI into Chinese by Lilidream.

uniform float Gamma <
	ui_label = "Gamma";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 2.0;
	ui_tooltip = "调整中间调。1.0是中性。这个设置的作用与Lift Gamma Gain中的设置完全相同，只是控制力较弱。";
> = 1.0;
uniform float Exposure <
	ui_label = "曝光";
	ui_type = "slider";
	ui_min = -1.0; ui_max = 1.0;
	ui_tooltip = "调整曝光";
> = 0.0;
uniform float Saturation <
	ui_label = "饱和度";
	ui_type = "slider";
	ui_min = -1.0; ui_max = 1.0;
	ui_tooltip = "调整饱和度";
> = 0.0;

uniform float Bleach <
	ui_label = "漂白";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_tooltip = "使阴影变亮并且使颜色减淡";
> = 0.0;

uniform float Defog <
	ui_label = "除雾";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_tooltip = "多少色调被移除";
> = 0.0;
uniform float3 FogColor <
	ui_type = "color";
	ui_label = "除雾颜色";
	ui_tooltip = "哪一个色调被移除";
> = float3(0.0, 0.0, 1.0);


#include "ReShade.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

float3 TonemapPass(float4 position : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float3 color = saturate(tex2D(ReShade::BackBuffer, texcoord).rgb - Defog * FogColor * 2.55); // Defog
	color *= pow(2.0f, Exposure); // Exposure
	color = pow(color, Gamma); // Gamma

	const float lum = dot(float3(0.2126, 0.7152, 0.0722), color);

	const float3 A2 = Bleach * color;

	color += ((1.0f - A2) * (A2 * lerp(2.0f * color * lum, 1.0f - 2.0f * (1.0f - lum) * (1.0f - color), saturate(10.0 * (lum - 0.45)))));

	// !!! could possibly branch this with fast_ops
	// !!! to pre-calc 1.0/3.0 and skip calc'ing it each pass
	// !!! and have fast_ops != 1 have it calc each pass.
	// !!! can pre-calc once to use twice below
	const float3 diffcolor = (color - dot(color, (1.0 / 3.0))) * Saturation;

	color = (color + diffcolor) / (1 + diffcolor); // Saturation

#if GSHADE_DITHER
	return color + TriDither(color, texcoord, BUFFER_COLOR_BIT_DEPTH);
#else
	return color;
#endif
}

technique Tonemap <ui_label="色调映射";>
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = TonemapPass;
	}
}
