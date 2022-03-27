///////////////////////////////////////////////////////////////////
// This effect works like a one-side DoF for distance haze, which slightly
// blurs far away elements. A normal DoF has a focus point and blurs using
// two planes. 
//
// It works by first blurring the screen buffer using 2-pass block blur and
// then blending the blurred result into the screen buffer based on depth
// it uses depth-difference for extra weight in the blur method so edges
// of high-contrasting lines with high depth diffence don't bleed.
///////////////////////////////////////////////////////////////////
// By Otis / Infuse Project
///////////////////////////////////////////////////////////////////
// Lightly optimized by Marot Satil for the GShade project.
// Translation of the UI into Chinese by Lilidream.

uniform float EffectStrength <
	ui_label = "效果强度";
	ui_type = "slider";
	ui_min = 0.0; ui_max=1.0;
	ui_tooltip = "效果的强度。0为无效果，1为像素100%被模糊。";
> = 0.9;
uniform float3 FogColor <
	ui_label  = "雾颜色";
	ui_type= "color";
	ui_tooltip = "雾的颜色";
> = float3(0.8,0.8,0.8);
uniform float FogStart <
	ui_label = "雾开始";
	ui_type = "slider";
	ui_min = 0.0; ui_max=1.0;
	ui_tooltip = "雾开始的位置。0.0为在镜头处，1.0为远处地平线，0.5为中间。在此点之前不会有雾产生。";
> = 0.2;
uniform float FogFactor <
	ui_label = "雾因子";
	ui_type = "slider";
	ui_min = 0.0; ui_max=1.0;
	ui_tooltip = "雾的强度因子，0为无雾，1为最强的雾。";
> = 0.2;

#include "ReShade.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

//////////////////////////////////////
// textures
//////////////////////////////////////
texture   Otis_FragmentBuffer1 	{ Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8;};	
texture   Otis_FragmentBuffer2 	< pooled = true; > { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8;};	

//////////////////////////////////////
// samplers
//////////////////////////////////////
sampler2D Otis_SamplerFragmentBuffer2 { Texture = Otis_FragmentBuffer2; };
sampler2D Otis_SamplerFragmentBuffer1 {	Texture = Otis_FragmentBuffer1; };

//////////////////////////////////////
// code
//////////////////////////////////////
float CalculateWeight(float distanceFromSource, float sourceDepth, float neighborDepth)
{
	return (1.0 - abs(sourceDepth - neighborDepth)) * (1/distanceFromSource) * neighborDepth;
}

void PS_Otis_DEH_BlockBlurHorizontal(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD, out float4 outFragment : SV_Target0)
{
	float4 color = tex2D(ReShade::BackBuffer, texcoord);
	const float colorDepth = ReShade::GetLinearizedDepth(texcoord).r;
	float n = 1.0f;

	[loop]
	for(float i = 1; i < 5; ++i) 
	{
		float2 sourceCoords = texcoord + float2(i * BUFFER_PIXEL_SIZE.x, 0.0);
		float weight = CalculateWeight(i, colorDepth, ReShade::GetLinearizedDepth(sourceCoords).r);
		color += (tex2D(ReShade::BackBuffer, sourceCoords) * weight);
		n+=weight;
		
		sourceCoords = texcoord - float2(i * BUFFER_PIXEL_SIZE.x, 0.0);
		weight = CalculateWeight(i, colorDepth, ReShade::GetLinearizedDepth(sourceCoords).r);
		color += (tex2D(ReShade::BackBuffer, sourceCoords) * weight);
		n+=weight;
	}
	outFragment = color/n;
}

void PS_Otis_DEH_BlockBlurVertical(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD, out float4 outFragment : SV_Target0)
{
	float4 color = tex2D(Otis_SamplerFragmentBuffer1, texcoord);
	const float colorDepth = ReShade::GetLinearizedDepth(texcoord).r;
	float n=1.0f;
	
	[loop]
	for(float j = 1; j < 5; ++j) 
	{
		float2 sourceCoords = texcoord + float2(0.0, j * BUFFER_PIXEL_SIZE.y);
		float weight = CalculateWeight(j, colorDepth, ReShade::GetLinearizedDepth(sourceCoords).r);
		color += (tex2D(Otis_SamplerFragmentBuffer1, sourceCoords) * weight);
		n+=weight;

		sourceCoords = texcoord - float2(0.0, j * BUFFER_PIXEL_SIZE.y);
		weight = CalculateWeight(j, colorDepth, ReShade::GetLinearizedDepth(sourceCoords).r);
		color += (tex2D(Otis_SamplerFragmentBuffer1, sourceCoords) * weight);
		n+=weight;
	}
	outFragment = color/n;
}

void PS_Otis_DEH_BlendBlurWithNormalBuffer(float4 vpos: SV_Position, float2 texcoord: TEXCOORD, out float4 fragment: SV_Target0)
{
	const float depth = ReShade::GetLinearizedDepth(texcoord).r;
	const float4 blendedFragment = lerp(tex2D(ReShade::BackBuffer, texcoord), tex2D(Otis_SamplerFragmentBuffer2, texcoord), clamp(depth  * EffectStrength, 0.0, 1.0)); 
	float yFactor;
	if (texcoord.y > 0.5)
		yFactor = clamp(1-((texcoord.y-0.5)*2.0), 0, 1);
	else
		yFactor = clamp(texcoord.y * 2.0, 0, 1);
	fragment = lerp(blendedFragment, float4(FogColor, blendedFragment.r), clamp((depth-FogStart) * yFactor * FogFactor, 0.0, 1.0));

#if GSHADE_DITHER
	fragment.rgb += TriDither(fragment.rgb, texcoord, BUFFER_COLOR_BIT_DEPTH);
#endif
}

technique DepthHaze <ui_label="深度雾";>
{
	// 3 passes. First 2 passes blur screenbuffer into Otis_FragmentBuffer2 using 2 pass block blur with 10 samples each (so 2 passes needed)
	// 3rd pass blends blurred fragments based on depth with screenbuffer.
	pass Otis_DEH_Pass0
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_Otis_DEH_BlockBlurHorizontal;
		RenderTarget = Otis_FragmentBuffer1;
	}

	pass Otis_DEH_Pass1
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_Otis_DEH_BlockBlurVertical;
		RenderTarget = Otis_FragmentBuffer2;
	}
	
	pass Otis_DEH_Pass2
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_Otis_DEH_BlendBlurWithNormalBuffer;
	}
}
