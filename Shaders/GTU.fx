////////////////////////////////////////////////////////
// GTU version 0.50
// Author: aliaspider - aliaspider@gmail.com
// License: GPLv3
// Ported to ReShade by Matsilagi
////////////////////////////////////////////////////////
// Translation of the UI into Chinese by Lilidream.

#include "ReShade.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

uniform float texture_sizeX <
	ui_type = "slider";
	ui_min = 1.0;
	ui_max = BUFFER_WIDTH;
	ui_label = "屏幕宽度(GTU)";
> = 320.0;

uniform float texture_sizeY <
	ui_type = "slider";
	ui_min = 1.0;
	ui_max = BUFFER_HEIGHT;
	ui_label = "屏幕高度(GTU)";
> = 240.0;

uniform float video_sizeX <
	ui_type = "slider";
	ui_min = 1.0;
	ui_max = BUFFER_WIDTH;
	ui_label = "帧宽度(GTU)";
	ui_tooltip = "这应该是根据贴图里的视频数据调整大小 (如果你使用仿真器，将其设置为Emu视频帧的大小，否则，保持与屏幕宽度/高度或全屏分辨率相同。)";
> = 320.0;

uniform float video_sizeY <
	ui_type = "slider";
	ui_min = 1.0;
	ui_max = BUFFER_HEIGHT;
	ui_label = "帧高度(GTU)";
	ui_tooltip = "这应该是根据贴图里的视频数据调整大小 (如果你使用仿真器，将其设置为Emu视频帧的大小，否则，保持与屏幕宽度/高度或全屏分辨率相同。)";
> = 240.0;

uniform bool compositeConnection <
	ui_label = "开启合成连接(GTU)";
> = 0;

uniform bool noScanlines <
	ui_label = "关闭扫描线(GTU)";
> = 0;

uniform float signalResolution <
	ui_type = "slider";
	ui_min = 16.0; ui_max = 1024.0;
	ui_tooltip = "信号分辨率Y (GTU)";
	ui_label = "信号分辨率Y (GTU)";
	ui_step = 16.0;
> = 256.0;

uniform float signalResolutionI <
	ui_type = "slider";
	ui_min = 1.0; ui_max = 350.0;
	ui_tooltip = "信号分辨率I (GTU)";
	ui_label = "信号分辨率I (GTU)";
	ui_step = 2.0;
> = 83.0;

uniform float signalResolutionQ <
	ui_type = "slider";
	ui_min = 1.0; ui_max = 350.0;
	ui_tooltip = "信号分辨率Q (GTU)";
	ui_label = "信号分辨率Q (GTU)";
	ui_step = 2.0;
> = 25.0;

uniform float tvVerticalResolution <
	ui_type = "slider";
	ui_min = 20.0; ui_max = 1000.0;
	ui_tooltip = "电视垂直分辨率 (GTU)";
	ui_label = "电视垂直分辨率 (GTU)";
	ui_step = 10.0;
> = 250.0;

uniform float blackLevel <
	ui_type = "slider";
	ui_min = -0.30; ui_max = 0.30;
	ui_tooltip = "黑阶 (GTU)";
	ui_label = "黑阶 (GTU)";
	ui_step = 0.01;
> = 0.07;

uniform float contrast <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 2.0;
	ui_tooltip = "对比度 (GTU)";
	ui_label = "对比度 (GTU)";
	ui_step = 0.1;
> = 1.0;

texture target0_gtu
{
    Width = BUFFER_WIDTH;
    Height = BUFFER_HEIGHT;
	Format = RGBA32F;
};
sampler s0 { Texture = target0_gtu; };

#define texture_size float2(texture_sizeX, texture_sizeY)
#define video_size float2(video_sizeX, video_sizeY)

#define pi        3.14159265358

//PASS 2
#define d(x, b) (pi * b * min(abs(x) + 0.5, 1.0 / b))
#define e(x, b) (pi * b * min(max(abs(x) - 0.5, -1.0 / b), 1.0 / b))
#define STU(x, b) ((d(x, b) + sin(d(x, b)) - e(x, b) - sin(e(x, b))) / (2.0 * pi))

float normalGaussIntegral(float x)
{
	const float t = 1.0 / (1.0 + 0.3326700 * abs(x));
	return (0.5 - ((exp(-(x) * (x) * 0.5)) / sqrt(2.0 * pi)) * (t * (0.4361836 + t * (-0.1201676 + 0.9372980 * t)))) * sign(x);
}

float3 scanlines( float x , float3 c)
{
	const float temp = sqrt(2 * pi) * (tvVerticalResolution / texture_sizeY);

	const float rrr = 0.5 * (texture_sizeY / ReShade::ScreenSize.y);
	const float x1 = (x + rrr) * temp;
	const float x2 = (x - rrr) * temp;
	c.r = (c.r * (normalGaussIntegral(x1) - normalGaussIntegral(x2)));
	c.g = (c.g * (normalGaussIntegral(x1) - normalGaussIntegral(x2)));
	c.b = (c.b * (normalGaussIntegral(x1) - normalGaussIntegral(x2)));
	c *= (ReShade::ScreenSize.y / texture_sizeY);
	return c;
}

float4 PS_GTU1(float4 vpos : SV_Position, float2 tex : TexCoord) : SV_Target
{
	float4 c = tex2D(ReShade::BackBuffer, tex);
	if(compositeConnection)
	{
		c.rgb = mul(transpose(float3x3( 0.299 , 0.595716 , 0.211456 , 0.587 , -0.274453 , -0.522591 , 0.114 , -0.321263 , 0.311135 )), c.rgb);
	}
	return c;
}

float4 PS_GTU2(float4 vpos : SV_Position, float2 tex : TexCoord) : SV_Target
{
	const float offset   = frac((tex.x * texture_size.x) - 0.5);
	float3 tempColor = float3(0.0,0.0,0.0);
	float X;
	float3 c;
	float range;
	if (compositeConnection)
	{
		range = ceil(0.5 + video_size.x / min(min(signalResolution,signalResolutionI),signalResolutionQ));
	}
	else
	{
		range = ceil(0.5 + video_size.x / signalResolution);
	}

	float i;
	if(compositeConnection)
	{
		for (i = -range; i < range + 2.0; i++)
		{
			X = (offset - i);
			c = tex2Dlod(s0, float4(float2(tex.x - X / texture_size.x, tex.y), 0.0, 0.0)).rgb;
			tempColor += float3((c.x * STU(X, (signalResolution / video_size.x))), (c.y * STU(X, (signalResolutionI / video_size.x))), c.z * STU(X, (signalResolutionQ / video_size.x)));
		}
	}
	else
	{
		for (i = -range; i < range + 2.0; i++)
		{
			X = (offset - i);
			c = tex2Dlod(s0, float4(float2(tex.x - X / texture_size.x, tex.y), 0.0, 0.0)).rgb;
			tempColor += c * STU(X, (signalResolution / video_size.x));
		}
	}
	if(compositeConnection)
	{
		tempColor = clamp(mul(transpose(float3x3(1.0 , 1.0  , 1.0 , 0.9563 , -0.2721 , -1.1070 , 0.6210 , -0.6474 , 1.7046)), tempColor), 0.0, 1.0);
	}
	else
	{
		tempColor = clamp(tempColor, 0.0, 1.0);
	}

#if GSHADE_DITHER
	return float4(tempColor + TriDither(tempColor, tex, BUFFER_COLOR_BIT_DEPTH), 1.0);
#else
	return float4(tempColor, 1.0);
#endif
}

float4 PS_GTU3(float4 vpos : SV_Position, float2 tex : TexCoord) : SV_Target
{
	const float2 offset = frac((tex.xy * texture_size) - 0.5);
	float3 tempColor = float3(0.0, 0.0, 0.0);

	const float range = ceil(0.5 + video_size.y / tvVerticalResolution);

	float i;

	if (noScanlines)
	{
		for (i =- range; i < range + 2.0; i++)
		{
			tempColor += ((tex2Dlod(ReShade::BackBuffer, float4(float2(tex.x, tex.y - (offset.y - (i)) / texture_size.y), 0.0, 0.0)).xyz) * STU((frac((tex.xy * texture_size) - 0.5).y - (i)), (tvVerticalResolution / video_size.y)));
		}
	}
	else
	{
		for (i = -range; i < range + 2.0; i++)
		{
			tempColor += scanlines((offset.y - (i)), tex2Dlod(ReShade::BackBuffer, float4(float2(tex.x, tex.y - (offset.y - (i)) / texture_size.y), 0.0, 0.0)).xyz);
		}
	}

	tempColor -= float3(blackLevel, blackLevel, blackLevel);
	tempColor *= (contrast / float3(1.0 - blackLevel, 1.0 - blackLevel, 1.0 - blackLevel));
#if GSHADE_DITHER
	return float4(tempColor + TriDither(tempColor, tex, BUFFER_COLOR_BIT_DEPTH), 1.0);
#else
	return float4(tempColor, 1.0);
#endif
}

technique GTUV50 {
	pass GTU1
	{	
		RenderTarget = target0_gtu;
		
		VertexShader = PostProcessVS;
		PixelShader = PS_GTU1;
	}
	
	pass p2
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_GTU2;
	}
	
	pass p3
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_GTU3;
	}
}