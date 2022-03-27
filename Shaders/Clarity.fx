
//Clarity by Ioxa
//Version 1.5 for ReShade 3.0
// Lightly optimized by Marot Satil for the GShade project.
// Translation of the UI into Chinese by Lilidream.

//>Clarity Settings<\\
uniform int ClarityRadius
<
	ui_label = "半径";
	ui_type = "slider";
	ui_min = 0; ui_max = 4;
	ui_tooltip = "[0|1|2|3|4]高的值会增加效果半径。";
	ui_step = 1.00;
> = 3;

uniform float ClarityOffset
<
	ui_label = "偏移";
	ui_type = "slider";
	ui_min = 1.00; ui_max = 5.00;
	ui_tooltip = "半径的额外调整，增加此值会增加半径。";
	ui_step = 1.00;
> = 2.00;

uniform int ClarityBlendMode
<
	ui_label = "混合模式";
	ui_type = "combo";
	ui_items = "\柔光\0覆盖\0硬光\0相乘\0亮光\0线性光\0相加";
	ui_tooltip = "混合模式决定了清晰化图片如何作用在原始画面上。";
> = 2;

uniform int ClarityBlendIfDark
<
	ui_label = "暗阈值";
	ui_type = "slider";
	ui_min = 0; ui_max = 255;
	ui_tooltip = "任何像素低于此值会被排除在效果外。设置50调准为中间调。";
	ui_step = 5;
> = 50;

uniform int ClarityBlendIfLight
<
	ui_label = "亮阈值";
	ui_type = "slider";
	ui_min = 0; ui_max = 255;
	ui_tooltip = "任何像素高于此值会被排除在效果外。设置205调准为中间调。";
	ui_step = 5;
> = 205;

uniform bool ClarityViewBlendIfMask
<
	ui_label = "阈值遮罩";
	ui_tooltip = "阈值设置的遮罩。此效果不会再被黑色覆盖的区域生效。";
> = false;

uniform float ClarityStrength
<
	ui_label = "强度";
	ui_type = "slider";
	ui_min = 0.00; ui_max = 1.00;
	ui_tooltip = "调整效果强度";
> = 0.400;

uniform float ClarityDarkIntensity
<
	ui_label = "暗强度";
	ui_type = "slider";
	ui_min = 0.00; ui_max = 1.00;
	ui_tooltip = "调整暗光晕强度";
> = 0.400;

uniform float ClarityLightIntensity
<
	ui_label = "亮强度";
	ui_type = "slider";
	ui_min = 0.00; ui_max = 1.00;
	ui_tooltip = "调整亮光晕强度";
> = 0.000;

uniform bool ClarityViewMask
<	
	ui_label = "查看遮罩";
	ui_tooltip = "此效果的遮罩，通过查看可以更好地调整到想要的效果。";
> = false;

#include "ReShade.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

texture ClarityTex < pooled = true; > { Width = BUFFER_WIDTH * 0.5; Height = BUFFER_HEIGHT * 0.5; Format = R8; };
texture ClarityTex2 { Width = BUFFER_WIDTH * 0.5; Height = BUFFER_HEIGHT * 0.5; Format = R8; };
texture ClarityTex3 < pooled = true; > { Width = BUFFER_WIDTH * 0.25; Height = BUFFER_HEIGHT * 0.25; Format = R8; };

sampler ClaritySampler { Texture = ClarityTex;};
sampler ClaritySampler2 { Texture = ClarityTex2;};
sampler ClaritySampler3 { Texture = ClarityTex3;};

float3 ClarityFinal(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD) : COLOR
{

	float color = tex2D(ClaritySampler3, texcoord).r;
	
if(ClarityRadius == 0)	
{
	const float offset[4] = { 0.0, 1.1824255238, 3.0293122308, 5.0040701377 };
	const float weight[4] = { 0.39894, 0.2959599993, 0.0045656525, 0.00000149278686458842 };
	
	color *= weight[0];
	
	[loop]
	for(int i = 1; i < 4; ++i)
	{
		color += tex2Dlod(ClaritySampler3, float4(texcoord + float2(0.0, offset[i] * BUFFER_PIXEL_SIZE.y) * ClarityOffset, 0.0, 0.0)).r * weight[i];
		color += tex2Dlod(ClaritySampler3, float4(texcoord - float2(0.0, offset[i] * BUFFER_PIXEL_SIZE.y) * ClarityOffset, 0.0, 0.0)).r * weight[i];
	}
}	

if(ClarityRadius == 1)	
{
	const float offset[6] = { 0.0, 1.4584295168, 3.40398480678, 5.3518057801, 7.302940716, 9.2581597095 };
	const float weight[6] = { 0.13298, 0.23227575, 0.1353261595, 0.0511557427, 0.01253922, 0.0019913644 };
	
	color *= weight[0];
	
	[loop]
	for(int i = 1; i < 6; ++i)
	{
		color += tex2Dlod(ClaritySampler3, float4(texcoord + float2(0.0, offset[i] * BUFFER_PIXEL_SIZE.y) * ClarityOffset, 0.0, 0.0)).r * weight[i];
		color += tex2Dlod(ClaritySampler3, float4(texcoord - float2(0.0, offset[i] * BUFFER_PIXEL_SIZE.y) * ClarityOffset, 0.0, 0.0)).r * weight[i];
	}
}	

if(ClarityRadius == 2)	
{
	const float offset[11] = { 0.0, 1.4895848401, 3.4757135714, 5.4618796741, 7.4481042327, 9.4344079746, 11.420811147, 13.4073334, 15.3939936778, 17.3808101174, 19.3677999584 };
	const float weight[11] = { 0.06649, 0.1284697563, 0.111918249, 0.0873132676, 0.0610011113, 0.0381655709, 0.0213835661, 0.0107290241, 0.0048206869, 0.0019396469, 0.0006988718 };
	
	color *= weight[0];
	
	[loop]
	for(int i = 1; i < 11; ++i)
	{
		color += tex2Dlod(ClaritySampler3, float4(texcoord + float2(0.0, offset[i] * BUFFER_PIXEL_SIZE.y) * ClarityOffset, 0.0, 0.0)).r * weight[i];
		color += tex2Dlod(ClaritySampler3, float4(texcoord - float2(0.0, offset[i] * BUFFER_PIXEL_SIZE.y) * ClarityOffset, 0.0, 0.0)).r * weight[i];
	}
}	

if(ClarityRadius == 3)	
{
	const float offset[15] = { 0.0, 1.4953705027, 3.4891992113, 5.4830312105, 7.4768683759, 9.4707125766, 11.4645656736, 13.4584295168, 15.4523059431, 17.4461967743, 19.4401038149, 21.43402885, 23.4279736431, 25.4219399344, 27.4159294386 };
	const float weight[15] = { 0.0443266667, 0.0872994708, 0.0820892038, 0.0734818355, 0.0626171681, 0.0507956191, 0.0392263968, 0.0288369812, 0.0201808877, 0.0134446557, 0.0085266392, 0.0051478359, 0.0029586248, 0.0016187257, 0.0008430913 };
	
	color *= weight[0];
	
	[loop]
	for(int i = 1; i < 15; ++i)
	{
		color += tex2Dlod(ClaritySampler3, float4(texcoord + float2(0.0, offset[i] * BUFFER_PIXEL_SIZE.y) * ClarityOffset, 0.0, 0.0)).r * weight[i];
		color += tex2Dlod(ClaritySampler3, float4(texcoord - float2(0.0, offset[i] * BUFFER_PIXEL_SIZE.y) * ClarityOffset, 0.0, 0.0)).r * weight[i];
	}
}

if(ClarityRadius == 4)	
{
	const float offset[18] = { 0.0, 1.4953705027, 3.4891992113, 5.4830312105, 7.4768683759, 9.4707125766, 11.4645656736, 13.4584295168, 15.4523059431, 17.4461967743, 19.4661974725, 21.4627427973, 23.4592916956, 25.455844494, 27.4524015179, 29.4489630909, 31.445529535, 33.4421011704 };
	const float weight[18] = { 0.033245, 0.0659162217, 0.0636705814, 0.0598194658, 0.0546642566, 0.0485871646, 0.0420045997, 0.0353207015, 0.0288880982, 0.0229808311, 0.0177815511, 0.013382297, 0.0097960001, 0.0069746748, 0.0048301008, 0.0032534598, 0.0021315311, 0.0013582974 };
	
	color *= weight[0];
	
	[loop]
	for(int i = 1; i < 18; ++i)
	{
		color += tex2Dlod(ClaritySampler3, float4(texcoord + float2(0.0, offset[i] * BUFFER_PIXEL_SIZE.y) * ClarityOffset, 0.0, 0.0)).r * weight[i];
		color += tex2Dlod(ClaritySampler3, float4(texcoord - float2(0.0, offset[i] * BUFFER_PIXEL_SIZE.y) * ClarityOffset, 0.0, 0.0)).r * weight[i];
	}
}	
	
	float3 orig = tex2D(ReShade::BackBuffer, texcoord).rgb; //Original Image
	float luma = dot(orig.rgb,float3(0.32786885,0.655737705,0.0163934436));
	float3 chroma = orig.rgb/luma;
	
	float sharp = 1-color;
	sharp = (luma+sharp)*0.5;
	
	float sharpMin = lerp(0.0,1.0,smoothstep(0.0,1.0,sharp));
	float sharpMax = sharpMin;
	sharpMin = lerp(sharp,sharpMin,ClarityDarkIntensity);
	sharpMax = lerp(sharp,sharpMax,ClarityLightIntensity);
	sharp = lerp(sharpMin,sharpMax,step(0.5,sharp));

	if(ClarityViewMask)
	{
		orig.rgb = sharp;
		luma = sharp;
		chroma = 1.0;
	}
	else
	{
		if(ClarityBlendMode == 0)
		{
			//softlight
			sharp = lerp(2*luma*sharp + luma*luma*(1.0-2*sharp), 2*luma*(1.0-sharp)+pow(luma,0.5)*(2*sharp-1.0), step(0.49,sharp));
		}
		
		if(ClarityBlendMode == 1)
		{
			//overlay
			sharp = lerp(2*luma*sharp, 1.0 - 2*(1.0-luma)*(1.0-sharp), step(0.50,luma));
		}
		
		if(ClarityBlendMode == 2)
		{
			//Hardlight
			sharp = lerp(2*luma*sharp, 1.0 - 2*(1.0-luma)*(1.0-sharp), step(0.50,sharp));
		}
		
		if(ClarityBlendMode == 3)
		{
			//Multiply
			sharp = saturate(2 * luma * sharp);
		}
		
		if(ClarityBlendMode == 4)
		{
			//vivid light
			sharp = lerp(2*luma*sharp, luma/(2*(1-sharp)), step(0.5,sharp));
		}
		
		if(ClarityBlendMode == 5)
		{
			//Linear Light
			sharp = luma + 2.0*sharp-1.0;
		}
		
		if(ClarityBlendMode == 6)
		{
			//Addition
			sharp = saturate(luma + (sharp - 0.5));
		}
	}
	
	if( ClarityBlendIfDark > 0 || ClarityBlendIfLight < 255 || ClarityViewBlendIfMask)
	{
		const float ClarityBlendIfD = (ClarityBlendIfDark/255.0)+0.0001;
		const float ClarityBlendIfL = (ClarityBlendIfLight/255.0)-0.0001;
		const float mix = dot(orig.rgb, 0.333333);
		float mask = 1.0;
		
		if(ClarityBlendIfDark > 0)
		{
			mask = lerp(0.0,1.0,smoothstep(ClarityBlendIfD-(ClarityBlendIfD*0.2),ClarityBlendIfD+(ClarityBlendIfD*0.2),mix));
		}
						
		if(ClarityBlendIfLight < 255)
		{
			mask = lerp(mask,0.0,smoothstep(ClarityBlendIfL-(ClarityBlendIfL*0.2),ClarityBlendIfL+(ClarityBlendIfL*0.2),mix));
		}
			
		sharp = lerp(luma,sharp,mask);
		
		if (ClarityViewBlendIfMask)
		{
			sharp = mask;
			luma = mask;
			chroma = 1.0;
		}
	}
					
	orig.rgb = lerp(luma, sharp, ClarityStrength);
	orig.rgb *= chroma;
		

#if GSHADE_DITHER
	orig = saturate(orig);
	return orig + TriDither(orig, texcoord, BUFFER_COLOR_BIT_DEPTH);
#else
	return saturate(orig);
#endif
}	

float Clarity1(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD) : COLOR
{
	float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;
	
if(ClarityRadius == 0)	
{
	const float offset[4] = { 0.0, 1.1824255238, 3.0293122308, 5.0040701377 };
	const float weight[4] = { 0.39894, 0.2959599993, 0.0045656525, 0.00000149278686458842 };
	
	color *= weight[0];
	
	[loop]
	for(int i = 1; i < 4; ++i)
	{
		color += tex2Dlod(ReShade::BackBuffer, float4(texcoord + float2(offset[i] * BUFFER_PIXEL_SIZE.x, 0.0) * ClarityOffset, 0.0, 0.0)).rgb * weight[i];
		color += tex2Dlod(ReShade::BackBuffer, float4(texcoord - float2(offset[i] * BUFFER_PIXEL_SIZE.x, 0.0) * ClarityOffset, 0.0, 0.0)).rgb * weight[i];
	}
}	

if(ClarityRadius == 1)	
{
	const float offset[6] = { 0.0, 1.4584295168, 3.40398480678, 5.3518057801, 7.302940716, 9.2581597095 };
	const float weight[6] = { 0.13298, 0.23227575, 0.1353261595, 0.0511557427, 0.01253922, 0.0019913644 };
	
	color *= weight[0];
	
	[loop]
	for(int i = 1; i < 6; ++i)
	{
		color += tex2Dlod(ReShade::BackBuffer, float4(texcoord + float2(offset[i] * BUFFER_PIXEL_SIZE.x, 0.0) * ClarityOffset, 0.0, 0.0)).rgb * weight[i];
		color += tex2Dlod(ReShade::BackBuffer, float4(texcoord - float2(offset[i] * BUFFER_PIXEL_SIZE.x, 0.0) * ClarityOffset, 0.0, 0.0)).rgb * weight[i];
	}
}	

if(ClarityRadius == 2)	
{
	const float offset[11] = { 0.0, 1.4895848401, 3.4757135714, 5.4618796741, 7.4481042327, 9.4344079746, 11.420811147, 13.4073334, 15.3939936778, 17.3808101174, 19.3677999584 };
	const float weight[11] = { 0.06649, 0.1284697563, 0.111918249, 0.0873132676, 0.0610011113, 0.0381655709, 0.0213835661, 0.0107290241, 0.0048206869, 0.0019396469, 0.0006988718 };
	
	color *= weight[0];
	
	[loop]
	for(int i = 1; i < 11; ++i)
	{
		color += tex2Dlod(ReShade::BackBuffer, float4(texcoord + float2(offset[i] * BUFFER_PIXEL_SIZE.x, 0.0) * ClarityOffset, 0.0, 0.0)).rgb * weight[i];
		color += tex2Dlod(ReShade::BackBuffer, float4(texcoord - float2(offset[i] * BUFFER_PIXEL_SIZE.x, 0.0) * ClarityOffset, 0.0, 0.0)).rgb * weight[i];
	}
}	

if(ClarityRadius == 3)	
{
	const float offset[15] = { 0.0, 1.4953705027, 3.4891992113, 5.4830312105, 7.4768683759, 9.4707125766, 11.4645656736, 13.4584295168, 15.4523059431, 17.4461967743, 19.4401038149, 21.43402885, 23.4279736431, 25.4219399344, 27.4159294386 };
	const float weight[15] = { 0.0443266667, 0.0872994708, 0.0820892038, 0.0734818355, 0.0626171681, 0.0507956191, 0.0392263968, 0.0288369812, 0.0201808877, 0.0134446557, 0.0085266392, 0.0051478359, 0.0029586248, 0.0016187257, 0.0008430913 };
	
	color *= weight[0];
	
	[loop]
	for(int i = 1; i < 15; ++i)
	{
		color += tex2Dlod(ReShade::BackBuffer, float4(texcoord + float2(offset[i] * BUFFER_PIXEL_SIZE.x, 0.0) * ClarityOffset, 0.0, 0.0)).rgb * weight[i];
		color += tex2Dlod(ReShade::BackBuffer, float4(texcoord - float2(offset[i] * BUFFER_PIXEL_SIZE.x, 0.0) * ClarityOffset, 0.0, 0.0)).rgb * weight[i];
	}
}	

if(ClarityRadius == 4)	
{
	const float offset[18] = { 0.0, 1.4953705027, 3.4891992113, 5.4830312105, 7.4768683759, 9.4707125766, 11.4645656736, 13.4584295168, 15.4523059431, 17.4461967743, 19.4661974725, 21.4627427973, 23.4592916956, 25.455844494, 27.4524015179, 29.4489630909, 31.445529535, 33.4421011704 };
	const float weight[18] = { 0.033245, 0.0659162217, 0.0636705814, 0.0598194658, 0.0546642566, 0.0485871646, 0.0420045997, 0.0353207015, 0.0288880982, 0.0229808311, 0.0177815511, 0.013382297, 0.0097960001, 0.0069746748, 0.0048301008, 0.0032534598, 0.0021315311, 0.0013582974 };
	
	color *= weight[0];
	
	[loop]
	for(int i = 1; i < 18; ++i)
	{
		color += tex2Dlod(ReShade::BackBuffer, float4(texcoord + float2(offset[i] * BUFFER_PIXEL_SIZE.x, 0.0) * ClarityOffset, 0.0, 0.0)).rgb * weight[i];
		color += tex2Dlod(ReShade::BackBuffer, float4(texcoord - float2(offset[i] * BUFFER_PIXEL_SIZE.x, 0.0) * ClarityOffset, 0.0, 0.0)).rgb * weight[i];
	}
}	
	
	return dot(color.rgb,float3(0.32786885,0.655737705,0.0163934436));
}

float Clarity2(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD) : COLOR
{
	float color = tex2D(ClaritySampler, texcoord).r;
	
if(ClarityRadius == 0)	
{
	const float offset[4] = { 0.0, 1.1824255238, 3.0293122308, 5.0040701377 };
	const float weight[4] = { 0.39894, 0.2959599993, 0.0045656525, 0.00000149278686458842 };
	
	color *= weight[0];
	
	[loop]
	for(int i = 1; i < 4; ++i)
	{
		color += tex2Dlod(ClaritySampler, float4(texcoord + float2(0.0, offset[i] * BUFFER_PIXEL_SIZE.y) * ClarityOffset, 0.0, 0.0)).r* weight[i];
		color += tex2Dlod(ClaritySampler, float4(texcoord - float2(0.0, offset[i] * BUFFER_PIXEL_SIZE.y) * ClarityOffset, 0.0, 0.0)).r* weight[i];
	}
}	

if(ClarityRadius == 1)	
{
	const float offset[6] = { 0.0, 1.4584295168, 3.40398480678, 5.3518057801, 7.302940716, 9.2581597095 };
	const float weight[6] = { 0.13298, 0.23227575, 0.1353261595, 0.0511557427, 0.01253922, 0.0019913644 };
	
	color *= weight[0];
	
	[loop]
	for(int i = 1; i < 6; ++i)
	{
		color += tex2Dlod(ClaritySampler, float4(texcoord + float2(0.0, offset[i] * BUFFER_PIXEL_SIZE.y) * ClarityOffset, 0.0, 0.0)).r* weight[i];
		color += tex2Dlod(ClaritySampler, float4(texcoord - float2(0.0, offset[i] * BUFFER_PIXEL_SIZE.y) * ClarityOffset, 0.0, 0.0)).r* weight[i];
	}
}	

if(ClarityRadius == 2)	
{
	const float offset[11] = { 0.0, 1.4895848401, 3.4757135714, 5.4618796741, 7.4481042327, 9.4344079746, 11.420811147, 13.4073334, 15.3939936778, 17.3808101174, 19.3677999584 };
	const float weight[11] = { 0.06649, 0.1284697563, 0.111918249, 0.0873132676, 0.0610011113, 0.0381655709, 0.0213835661, 0.0107290241, 0.0048206869, 0.0019396469, 0.0006988718 };
	
	color *= weight[0];
	
	[loop]
	for(int i = 1; i < 11; ++i)
	{
		color += tex2Dlod(ClaritySampler, float4(texcoord + float2(0.0, offset[i] * BUFFER_PIXEL_SIZE.y) * ClarityOffset, 0.0, 0.0)).r* weight[i];
		color += tex2Dlod(ClaritySampler, float4(texcoord - float2(0.0, offset[i] * BUFFER_PIXEL_SIZE.y) * ClarityOffset, 0.0, 0.0)).r* weight[i];
	}
}	

if(ClarityRadius == 3)	
{
	const float offset[15] = { 0.0, 1.4953705027, 3.4891992113, 5.4830312105, 7.4768683759, 9.4707125766, 11.4645656736, 13.4584295168, 15.4523059431, 17.4461967743, 19.4401038149, 21.43402885, 23.4279736431, 25.4219399344, 27.4159294386 };
	const float weight[15] = { 0.0443266667, 0.0872994708, 0.0820892038, 0.0734818355, 0.0626171681, 0.0507956191, 0.0392263968, 0.0288369812, 0.0201808877, 0.0134446557, 0.0085266392, 0.0051478359, 0.0029586248, 0.0016187257, 0.0008430913 };
	
	color *= weight[0];
	
	[loop]
	for(int i = 1; i < 15; ++i)
	{
		color += tex2Dlod(ClaritySampler, float4(texcoord + float2(0.0, offset[i] * BUFFER_PIXEL_SIZE.y) * ClarityOffset, 0.0, 0.0)).r* weight[i];
		color += tex2Dlod(ClaritySampler, float4(texcoord - float2(0.0, offset[i] * BUFFER_PIXEL_SIZE.y) * ClarityOffset, 0.0, 0.0)).r* weight[i];
	}
}

if(ClarityRadius == 4)	
{
	const float offset[18] = { 0.0, 1.4953705027, 3.4891992113, 5.4830312105, 7.4768683759, 9.4707125766, 11.4645656736, 13.4584295168, 15.4523059431, 17.4461967743, 19.4661974725, 21.4627427973, 23.4592916956, 25.455844494, 27.4524015179, 29.4489630909, 31.445529535, 33.4421011704 };
	const float weight[18] = { 0.033245, 0.0659162217, 0.0636705814, 0.0598194658, 0.0546642566, 0.0485871646, 0.0420045997, 0.0353207015, 0.0288880982, 0.0229808311, 0.0177815511, 0.013382297, 0.0097960001, 0.0069746748, 0.0048301008, 0.0032534598, 0.0021315311, 0.0013582974 };
	
	color *= weight[0];
	
	[loop]
	for(int i = 1; i < 18; ++i)
	{
		color += tex2Dlod(ClaritySampler, float4(texcoord + float2(0.0, offset[i] * BUFFER_PIXEL_SIZE.y) * ClarityOffset, 0.0, 0.0)).r* weight[i];
		color += tex2Dlod(ClaritySampler, float4(texcoord - float2(0.0, offset[i] * BUFFER_PIXEL_SIZE.y) * ClarityOffset, 0.0, 0.0)).r* weight[i];
	}
}	

	return color;
}

float Clarity3(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD) : COLOR
{
	float color = tex2D(ClaritySampler2, texcoord).r;
	
if(ClarityRadius == 0)	
{
	const float offset[4] = { 0.0, 1.1824255238, 3.0293122308, 5.0040701377 };
	const float weight[4] = { 0.39894, 0.2959599993, 0.0045656525, 0.00000149278686458842 };
	
	color *= weight[0];
	
	[loop]
	for(int i = 1; i < 4; ++i)
	{
		color += tex2Dlod(ClaritySampler2, float4(texcoord + float2(offset[i] * BUFFER_PIXEL_SIZE.x, 0.0) * ClarityOffset, 0.0, 0.0)).r* weight[i];
		color += tex2Dlod(ClaritySampler2, float4(texcoord - float2(offset[i] * BUFFER_PIXEL_SIZE.x, 0.0) * ClarityOffset, 0.0, 0.0)).r* weight[i];
	}
}	

if(ClarityRadius == 1)	
{
	const float offset[6] = { 0.0, 1.4584295168, 3.40398480678, 5.3518057801, 7.302940716, 9.2581597095 };
	const float weight[6] = { 0.13298, 0.23227575, 0.1353261595, 0.0511557427, 0.01253922, 0.0019913644 };
	
	color *= weight[0];
	
	[loop]
	for(int i = 1; i < 6; ++i)
	{
		color += tex2Dlod(ClaritySampler2, float4(texcoord + float2(offset[i] * BUFFER_PIXEL_SIZE.x, 0.0) * ClarityOffset, 0.0, 0.0)).r* weight[i];
		color += tex2Dlod(ClaritySampler2, float4(texcoord - float2(offset[i] * BUFFER_PIXEL_SIZE.x, 0.0) * ClarityOffset, 0.0, 0.0)).r* weight[i];
	}
}	

if(ClarityRadius == 2)	
{
	const float offset[11] = { 0.0, 1.4895848401, 3.4757135714, 5.4618796741, 7.4481042327, 9.4344079746, 11.420811147, 13.4073334, 15.3939936778, 17.3808101174, 19.3677999584 };
	const float weight[11] = { 0.06649, 0.1284697563, 0.111918249, 0.0873132676, 0.0610011113, 0.0381655709, 0.0213835661, 0.0107290241, 0.0048206869, 0.0019396469, 0.0006988718 };
	
	color *= weight[0];
	
	[loop]
	for(int i = 1; i < 11; ++i)
	{
		color += tex2Dlod(ClaritySampler2, float4(texcoord + float2(offset[i] * BUFFER_PIXEL_SIZE.x, 0.0) * ClarityOffset, 0.0, 0.0)).r* weight[i];
		color += tex2Dlod(ClaritySampler2, float4(texcoord - float2(offset[i] * BUFFER_PIXEL_SIZE.x, 0.0) * ClarityOffset, 0.0, 0.0)).r* weight[i];
	}
}	

if(ClarityRadius == 3)	
{
	const float offset[15] = { 0.0, 1.4953705027, 3.4891992113, 5.4830312105, 7.4768683759, 9.4707125766, 11.4645656736, 13.4584295168, 15.4523059431, 17.4461967743, 19.4401038149, 21.43402885, 23.4279736431, 25.4219399344, 27.4159294386 };
	const float weight[15] = { 0.0443266667, 0.0872994708, 0.0820892038, 0.0734818355, 0.0626171681, 0.0507956191, 0.0392263968, 0.0288369812, 0.0201808877, 0.0134446557, 0.0085266392, 0.0051478359, 0.0029586248, 0.0016187257, 0.0008430913 };
	
	color *= weight[0];
	
	[loop]
	for(int i = 1; i < 15; ++i)
	{
		color += tex2Dlod(ClaritySampler2, float4(texcoord + float2(offset[i] * BUFFER_PIXEL_SIZE.x, 0.0) * ClarityOffset, 0.0, 0.0)).r* weight[i];
		color += tex2Dlod(ClaritySampler2, float4(texcoord - float2(offset[i] * BUFFER_PIXEL_SIZE.x, 0.0) * ClarityOffset, 0.0, 0.0)).r* weight[i];
	}
}	

if(ClarityRadius == 4)	
{
	const float offset[18] = { 0.0, 1.4953705027, 3.4891992113, 5.4830312105, 7.4768683759, 9.4707125766, 11.4645656736, 13.4584295168, 15.4523059431, 17.4461967743, 19.4661974725, 21.4627427973, 23.4592916956, 25.455844494, 27.4524015179, 29.4489630909, 31.445529535, 33.4421011704 };
	const float weight[18] = { 0.033245, 0.0659162217, 0.0636705814, 0.0598194658, 0.0546642566, 0.0485871646, 0.0420045997, 0.0353207015, 0.0288880982, 0.0229808311, 0.0177815511, 0.013382297, 0.0097960001, 0.0069746748, 0.0048301008, 0.0032534598, 0.0021315311, 0.0013582974 };
	
	color *= weight[0];
	
	[loop]
	for(int i = 1; i < 18; ++i)
	{
		color += tex2Dlod(ClaritySampler2, float4(texcoord + float2(offset[i] * BUFFER_PIXEL_SIZE.x, 0.0) * ClarityOffset, 0.0, 0.0)).r* weight[i];
		color += tex2Dlod(ClaritySampler2, float4(texcoord - float2(offset[i] * BUFFER_PIXEL_SIZE.x, 0.0) * ClarityOffset, 0.0, 0.0)).r* weight[i];
	}
}	
	
	return color;
}

technique Clarity <ui_label = "清晰";>
{
	pass Clarity1
	{
		VertexShader = PostProcessVS;
		PixelShader = Clarity1;
		RenderTarget = ClarityTex;
	}
	
	pass Clarity2
	{
		VertexShader = PostProcessVS;
		PixelShader = Clarity2;
		RenderTarget = ClarityTex2;
	}
	
	pass Clarity3
	{
		VertexShader = PostProcessVS;
		PixelShader = Clarity3;
		RenderTarget = ClarityTex3;
	}
	
	pass ClarityFinal
	{
		VertexShader = PostProcessVS;
		PixelShader = ClarityFinal;
	}
}
