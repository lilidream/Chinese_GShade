/*
	Original code by Marty McFly
	Amateur port by Insomnia 
*/
// Translation of the UI into Chinese by Lilidream.

uniform float ReinhardWhitepoint <
	ui_label = "莱因哈特白点";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 10.0;
	ui_tooltip = "线性点的色彩曲线有多陡峭";
> = 1.250;
uniform float ReinhardScale <
	ui_label = "莱因哈特尺寸";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 3.0;
	ui_tooltip = "线性点的色彩曲线有多陡峭";
> = 0.50;

#include "ReShade.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

float3 ReinhardPass(float4 position : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	const float3 x = tex2D(ReShade::BackBuffer, texcoord).rgb;
	const float W =  ReinhardWhitepoint;	// Linear White Point Value
	const float K =  ReinhardScale;        // Scale

	// gamma space or not?
#if GSHADE_DITHER
	const float3 outcolor = (1 + K * x / (W * W)) * x / (x + K);
	return outcolor + TriDither(outcolor, texcoord, BUFFER_COLOR_BIT_DEPTH);
#else
	return (1 + K * x / (W * W)) * x / (x + K);
#endif
}

technique Reinhard <ui_label="莱因哈特(Reinhard)";ui_tooltip="一种色调映射算法";>
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = ReinhardPass;
	}
}
