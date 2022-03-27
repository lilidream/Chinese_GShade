/*
DeHaze for Reshade
By: Lord of Lunacy


This shader attempts to remove fog using a dark channel prior technique that has been
refined using 2 passes over an iterative guided Wiener filter ran on the image dark channel.

The purpose of the Wiener filters is to minimize the root mean square error between
the given dark channel, and the true dark channel, making the removal more accurate.

The airlight of the image is estimated by using the max values that appears in the each
window of the dark channel. This window is then averaged together with every mip level
that is larger than the current window size.

Koschmeider's airlight equation is then used to remove the veil from the image.

This method was adapted from the following paper:
Gibson, Kristofor & Nguyen, Truong. (2013). Fast single image fog removal using the adaptive Wiener filter.
2013 IEEE International Conference on Image Processing, ICIP 2013 - Proceedings. 714-718. 10.1109/ICIP.2013.6738147. 

The airlight thresholding was adapted from this paper:
W. Wang, F. Chang, T. Ji and X. Wu, "A Fast Single-Image Dehazing Method Based on a Physical Model and Gray Projection,"
in IEEE Access, vol. 6, pp. 5641-5653, 2018, doi: 10.1109/ACCESS.2018.2794340.
*/
// Translation of the UI into Chinese by Lilidream.

#include "ReShade.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

#define CONST_LOG2(x) (\
    (uint((x) & 0xAAAAAAAA) != 0) | \
    (uint(((x) & 0xFFFF0000) != 0) << 4) | \
    (uint(((x) & 0xFF00FF00) != 0) << 3) | \
    (uint(((x) & 0xF0F0F0F0) != 0) << 2) | \
    (uint(((x) & 0xCCCCCCCC) != 0) << 1))
	
#define BIT2_LOG2(x) ( (x) | (x) >> 1)
#define BIT4_LOG2(x) ( BIT2_LOG2(x) | BIT2_LOG2(x) >> 2)
#define BIT8_LOG2(x) ( BIT4_LOG2(x) | BIT4_LOG2(x) >> 4)
#define BIT16_LOG2(x) ( BIT8_LOG2(x) | BIT8_LOG2(x) >> 8)

#define LOG2(x) (CONST_LOG2( (BIT16_LOG2(x) >> 1) + 1))

#define MAXIMUM(a, b) (int((a) > (b)) * (a) + int((b) > (a)) * (b))

#define GET_MAX_MIP(w, h) \
(LOG2((MAXIMUM((w), (h))) + 1))

#define WINDOW_SIZE 15
#define WINDOW_SIZE_SQUARED (WINDOW_SIZE * WINDOW_SIZE)
#define RENDER_WIDTH (BUFFER_WIDTH / 4)
#define RENDER_HEIGHT (BUFFER_HEIGHT / 4)
#define RENDER_RCP_WIDTH (1/float(RENDER_WIDTH))
#define RENDER_RCP_HEIGHT (1/float(RENDER_HEIGHT))
#define MAX_MIP GET_MAX_MIP(RENDER_WIDTH, RENDER_HEIGHT)

uniform float Alpha<
	ui_type = "slider";
	ui_label = "透明度";
	ui_category = "一般设置";
	ui_min = 0; ui_max = 1;
> = 0.5;

uniform float TransmissionMultiplier<
	ui_type = "slider";
	ui_label = "强度";
	ui_category = "一般设置";
	ui_tooltip = "移除总强度，正值表示移除更多，负值表示更少。";
	ui_min = -1; ui_max = 1;
	ui_step = 0.001;
> = -0.5;

uniform float DepthMultiplier<
	ui_type = "slider";
	ui_label = "深度敏感度";
	ui_category = "一般设置";
	ui_tooltip = "基于深度的移除量，若为负值，则实际上是增加雾，0表示不受深度影响。";
	ui_min = -1; ui_max = 1;
	ui_step = 0.001;
> = 0.175;

uniform bool IgnoreSky<
	ui_label = "忽略天空";
	ui_tooltip = "可能导致地平线上的急速转变。";
> = 0;

uniform int Debug <
ui_type = "combo";
ui_items = "无\0传输映射(Transmission map)\0";
ui_label = "Debug视图";
ui_category = "Debug";
> = 0;

texture BackBuffer : COLOR;
texture Mean <Pooled = true;> {Width = RENDER_WIDTH; Height = RENDER_HEIGHT; Format = R16f; MipLevels = MAX_MIP;};
texture Variance <Pooled = true;> {Width = RENDER_WIDTH; Height = RENDER_HEIGHT; Format = R16f; MipLevels = MAX_MIP;};
texture MeanAndVariance <Pooled = true;> {Width = RENDER_WIDTH; Height = RENDER_HEIGHT; Format = RG16f;};
texture Maximum0 <Pooled = true;> {Width = RENDER_WIDTH; Height = RENDER_HEIGHT; Format = R8;};
texture Maximum <Pooled = true;> {Width = RENDER_WIDTH; Height = RENDER_HEIGHT; Format = R8; MipLevels = MAX_MIP;};

sampler sBackBuffer {Texture = BackBuffer;};
sampler sMean {Texture = Mean;};
sampler sVariance {Texture = Variance;};
sampler sMaximum {Texture = Maximum;};
sampler sMeanAndVariance {Texture = MeanAndVariance;};
sampler sMaximum0 {Texture = Maximum0;};


void MeanAndVariancePS0(float4 vpos : SV_POSITION, float2 texcoord : TEXCOORD, out float2 meanAndVariance : SV_TARGET0, out float maximum : SV_TARGET1)
{
	float darkChannel;
	float sum = 0;
	float squaredSum = 0;
	maximum = 0;
	for(int i = -(WINDOW_SIZE / 2); i < ((WINDOW_SIZE + 1) / 2); i++)
	{
			float2 offset = float2(i * RENDER_RCP_WIDTH, 0);
			float3 color = tex2D(sBackBuffer, texcoord + offset).rgb;
			darkChannel = min(min(color.r, color.g), color.b);
			float darkChannelSquared = darkChannel * darkChannel;
			float darkChannelCubed = darkChannelSquared * darkChannel;
			sum += darkChannel;
			squaredSum += darkChannelSquared;
			maximum = max(maximum, darkChannel);
			
	}
	meanAndVariance = float2(sum, squaredSum);
}


void MeanAndVariancePS1(float4 vpos : SV_POSITION, float2 texcoord : TEXCOORD, out float mean : SV_TARGET0, out float variance : SV_TARGET1, out float maximum : SV_TARGET2)
{
	float2 meanAndVariance;
	float sum = 0;
	float squaredSum = 0;
	maximum = 0;
	for(int i = -(WINDOW_SIZE / 2); i < ((WINDOW_SIZE + 1) / 2); i++)
	{
			float2 offset = float2(0, i * RENDER_RCP_HEIGHT);
			meanAndVariance = tex2D(sMeanAndVariance, texcoord + offset).rg;
			sum += meanAndVariance.r;
			squaredSum += meanAndVariance.g;
			maximum = max(maximum, tex2D(sMaximum0, texcoord + offset).r);
	}
	float sumSquared = sum * sum;
	
	mean = sum / WINDOW_SIZE_SQUARED;
	variance = (squaredSum - ((sumSquared) / WINDOW_SIZE_SQUARED));
	variance /= WINDOW_SIZE_SQUARED;
}

void WienerFilterPS(float4 vpos : SV_POSITION, float2 texcoord : TEXCOORD, out float3 fogRemoved : SV_TARGET0)
{
	float depth = ReShade::GetLinearizedDepth(texcoord);
	
	if(IgnoreSky && depth >= 1)
	{
		discard;
	}

	float mean = tex2D(sMean, texcoord).r;
	float variance = tex2D(sVariance, texcoord).r;
	float noise = tex2Dlod(sVariance, float4(texcoord, 0, MAX_MIP - 1)).r;
	float3 color = tex2D(sBackBuffer, texcoord).rgb;
	float darkChannel = min(min(color.r, color.g), color.b);
	float maximum = 0;
	float averageGrey = tex2Dlod(sMean, float4(texcoord, 0, MAX_MIP - 1)).r;
	float maxColor = max(max(color.r, color.g), color.b);
	
	[unroll]
	for(int i = 4; i < MAX_MIP; i++)
	{
		maximum += tex2Dlod(sMaximum, float4(texcoord, 0, i)).r;
	}
	maximum /= MAX_MIP - 4;	
	
	float filter = saturate((max((variance - noise), 0) / variance) * (darkChannel - mean));
	float veil = saturate(mean + filter);
	//filter = ((variance - noise) / variance) * (darkChannel - mean);
	//mean += filter;
	float usedVariance = variance;
	
	float airlight = clamp(maximum, 0.05, 1);//max(saturate(mean + sqrt(usedVariance) * StandardDeviations), 0.05);
	
	float maxDifference = maxColor - airlight;
	float thresholdThreshold = airlight - averageGrey;
	float threshold;
	
	if(thresholdThreshold <= 0.25)
	{
		threshold = 0.55;
	}
	else if (thresholdThreshold < 0.35)
	{
		threshold = airlight - averageGrey + 0.4;
	}
	else
	{
		threshold = 0.75;
	}
	
	float transmission = (((veil * darkChannel) / airlight));
	if(maxDifference < threshold)//threshold)
	{
		transmission = min((threshold / maxColor) * transmission, 1);
	}
	transmission = 1 - transmission;
	transmission *= (exp(-DepthMultiplier * depth * 0.4));
	transmission *= exp(-TransmissionMultiplier * 0.4);
	transmission = clamp(transmission, 0.05, 1);  
	

	 
	float y = dot(color, float3(0.299, 0.587, 0.114));
	y = ((y - airlight) / transmission) + airlight;
	float cb = -0.168736 * color.r - 0.331264 * color.g + 0.500000 * color.b;
	float cr = +0.500000 * color.r - 0.418688 * color.g - 0.081312 * color.b;
	fogRemoved = float3(
		y + 1.402 * cr,
		y - 0.344136 * cb - 0.714136 * cr,
		y + 1.772 * cb);
	fogRemoved = lerp(color, fogRemoved, Alpha);
	
	if(Debug == 1)
	{
		fogRemoved = transmission.xxx;
	}

#if GSHADE_DITHER
	fogRemoved += TriDither(fogRemoved, texcoord, BUFFER_COLOR_BIT_DEPTH);
#endif
}

technique DeHaze<ui_tooltip = "此滤镜将雾从画面中移除\n\n"
							  "是Insane Shaders的一部分\n"
							  "By: Lord of Lunacy";ui_label="除雾";>
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = MeanAndVariancePS0;
		RenderTarget0 = MeanAndVariance;
		RenderTarget1 = Maximum0;
	}
	
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = MeanAndVariancePS1;
		RenderTarget0 = Mean;
		RenderTarget1 = Variance;
		RenderTarget2 = Maximum;
	}
	
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = WienerFilterPS;
	}
}
		
