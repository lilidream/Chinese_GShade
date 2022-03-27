/**
 * Lift Gamma Gain version 1.1
 * by 3an and CeeJay.dk
 */
 // Translation of the UI into Chinese by Lilidream.

uniform float3 RGB_Lift <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 2.0;
	ui_label = "RGB Lift(提升)";
	ui_tooltip = "调整阴影为红、绿、蓝";
> = float3(1.0, 1.0, 1.0);
uniform float3 RGB_Gamma <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 2.0;
	ui_label = "RGB Gamma";
	ui_tooltip = "调整中间调为红、绿、蓝";
> = float3(1.0, 1.0, 1.0);
uniform float3 RGB_Gain <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 2.0;
	ui_label = "RGB Gain(增益)";
	ui_tooltip = "调整高光为红、绿、蓝";
> = float3(1.0, 1.0, 1.0);


#include "ReShade.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

float3 LiftGammaGainPass(float4 position : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;
	
	// -- Lift --
	color = color * (1.5 - 0.5 * RGB_Lift) + 0.5 * RGB_Lift - 0.5;
	color = saturate(color); // Is not strictly necessary, but does not cost performance
	
	// -- Gain --
	color *= RGB_Gain; 
	
	// -- Gamma --
#if GSHADE_DITHER
	color = saturate(pow(abs(color), 1.0 / RGB_Gamma));
	return color + TriDither(color, texcoord, BUFFER_COLOR_BIT_DEPTH);
#else
	return saturate(pow(abs(color), 1.0 / RGB_Gamma));
#endif
}


technique LiftGammaGain
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = LiftGammaGainPass;
	}
}
