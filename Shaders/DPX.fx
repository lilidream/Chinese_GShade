/**
 * DPX/Cineon shader by Loadus
 */
 // Lightly optimized by Marot Satil for the GShade project.
 // Translation of the UI into Chinese by Lilidream.
uniform float3 RGB_Curve <
	ui_type = "slider";
	ui_min = 1.0; ui_max = 15.0;
	ui_label = "RGB曲线";
> = float3(8.0, 8.0, 8.0);
uniform float3 RGB_C <
	ui_type = "slider";
	ui_min = 0.2; ui_max = 0.5;
	ui_label = "RGB C";
> = float3(0.36, 0.36, 0.34);

uniform float Contrast <
	ui_label = "对比度";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
> = 0.1;
uniform float Saturation <
	ui_label = "饱和度";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 8.0;
> = 3.0;
uniform float Colorfulness <
	ui_label = "鲜艳度";
	ui_type = "slider";
	ui_min = 0.1; ui_max = 2.5;
> = 2.5;

uniform float Strength <
	ui_label = "强度";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_tooltip = "调整效果强度";
> = 0.20;

#include "ReShade.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

static const float3x3 RGB = float3x3(
	 2.6714711726599600, -1.2672360578624100, -0.4109956021722270,
	-1.0251070293466400,  1.9840911624108900,  0.0439502493584124,
	 0.0610009456429445, -0.2236707508128630,  1.1590210416706100
);
static const float3x3 XYZ = float3x3(
	 0.5003033835433160,  0.3380975732227390,  0.1645897795458570,
	 0.2579688942747580,  0.6761952591447060,  0.0658358459823868,
	 0.0234517888692628,  0.1126992737203000,  0.8668396731242010
);

float3 DPXPass(float4 vois : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float3 input = tex2D(ReShade::BackBuffer, texcoord).rgb;

	float3 B = input;
	B = B * (1.0 - Contrast) + (0.5 * Contrast);
	const float3 Btemp = (1.0 / (1.0 + exp(RGB_Curve / 2.0)));
	B = ((1.0 / (1.0 + exp(-RGB_Curve * (B - RGB_C)))) / (-2.0 * Btemp + 1.0)) + (-Btemp / (-2.0 * Btemp + 1.0));

	const float value = max(max(B.r, B.g), B.b);
	float3 color = B / value;
	color = pow(abs(color), 1.0 / Colorfulness);

	float3 c0 = color * value;
	c0 = mul(XYZ, c0);
	const float luma = dot(c0, float3(0.30, 0.59, 0.11));
	c0 = (1.0 - Saturation) * luma + Saturation * c0;
	c0 = mul(RGB, c0);

#if GSHADE_DITHER
	c0 = lerp(input, c0, Strength);
	return c0 + TriDither(c0, texcoord, BUFFER_COLOR_BIT_DEPTH);
#else
	return lerp(input, c0, Strength);
#endif
}

technique DPX
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = DPXPass;
	}
}
