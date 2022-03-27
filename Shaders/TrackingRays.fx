// Translation of the UI into Chinese by Lilidream.
//#region Includes

#include "FXShadersCommon.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

//#endregion

//#region Preprocessor

#ifndef TRACKING_RAYS_SAMPLES
#define TRACKING_RAYS_SAMPLES 13
#endif

//#endregion

namespace FXShaders
{

//#region Constants

static const int Samples = TRACKING_RAYS_SAMPLES;
static const int TrackPass0Size = 16;

//#endregion

//#region Uniforms

FXSHADERS_WIP_WARNING();

uniform float Intensity
<
	ui_label = "强度";
	ui_tooltip = "Default: 1.0";
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 1.0;
	ui_step = 0.05;
> = 1.0;

uniform float Curve
<
	ui_label = "曲线";
	ui_tooltip = "Default: 3.0";
	ui_type = "slider";
	ui_min = 1.0;
	ui_max = 5.0;
	ui_step = 0.1;
> = 3.0;

uniform float Scale
<
	ui_label = "大小";
	ui_tooltip = "Default: 10.0";
	ui_type = "slider";
	ui_min = 1.0;
	ui_max = 10.0;
	ui_step = 0.1;
> = 10.0;

uniform float Delay
<
	ui_label = "延迟";
	ui_tooltip = "Default: 1.0";
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 10.0;
	ui_step = 0.1;
> = 1.0;

uniform float MergeTolerance
<
	ui_label = "合并容忍度";
	ui_tooltip = "Default: 0.1";
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 0.3;
	ui_step = 0.01;
> = 0.1;

uniform float FrameTime <source = "frametime";>;

//#endregion

//#region Techniques

texture BackBufferTex : COLOR;

sampler BackBuffer
{
	Texture = BackBufferTex;
	SRGBTexture = true;
};

texture CoarseTex
{
	Width = TrackPass0Size;
	Height = TrackPass0Size;
	Format = R8;
};

sampler Coarse
{
	Texture = CoarseTex;
};

texture PivotTex
{
	Format = RG16F;
};

sampler Pivot
{
	Texture = PivotTex;
};

texture LastPivotTex
{
	Format = RG16F;
};

sampler LastPivot
{
	Texture = LastPivotTex;
};

//#endregion

//#region Techniques

float4 ZoomBlur(sampler sp, float2 uv, float2 pivot, float scale, int samples)
{
	float4 color = tex2D(sp, uv);
	//float4 maxColor = color;

	[unroll]
	for (int i = 1; i < samples; ++i)
	{
		uv = ScaleCoord(uv, rcp(scale), pivot);

		float4 pixel = tex2D(sp, uv);
		color += pixel;
		//maxColor = max(maxColor, pixel);
	}

	color /= samples;
	//color = lerp(color, maxColor, color);

	return color;
}

//#endregion

//#region Shaders

float4 GetCoarsePS(float4 p : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET
{
	return tex2D(BackBuffer, uv);
}

float4 TrackPass0PS(float4 p : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET
{
	float2 pivot = 0.5;
	float bright = 0.0;

	[unroll]
	for (int x = 0; x < TrackPass0Size; ++x)
	{
		[unroll]
		for (int y = 0; y < TrackPass0Size; ++y)
		{
			float2 pos = float2(x, y) / TrackPass0Size;
			float pixel = tex2D(Coarse, pos).x;

			if (abs(pixel - bright) < MergeTolerance)
			{
				bright = (bright + pixel) * 0.5;
				pivot = (pivot + pos) * 0.5;
			}
			else if (pixel > bright)
			{
				pivot = pos;
				bright = pixel;
			}
		}
	}

	if (Delay > 0.0)
	{
		pivot = lerp(tex2Dfetch(LastPivot, 0).xy, pivot, saturate((FrameTime * 0.001) / Delay));
	}

	return float4(pivot, 0.0, 1.0);
}

float4 SavePivotPS(float4 p : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET
{
	return tex2Dfetch(Pivot, 0);
}

float4 MainPS(float4 p : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET
{
	float4 color = tex2D(BackBuffer, uv);

	float4 rays = ZoomBlur(BackBuffer, uv, tex2Dfetch(Pivot, 0).xy, 1.0 + (Scale - 1.0) / Samples * 0.1, Samples);
	rays.rgb = pow(abs(rays.rgb), Curve);

#if GSHADE_DITHER
	const float4 outcolor = 1.0 - (1.0 - color) * (1.0 - rays * Intensity);
	return float4(outcolor.rgb + TriDither(outcolor.rgb, uv, BUFFER_COLOR_BIT_DEPTH), outcolor.a);
#else
	return 1.0 - (1.0 - color) * (1.0 - rays * Intensity);
#endif
}

//#endregion

//#region Techniques

technique TrackingRays
<
	ui_tooltip =
		"FXShaders - 实验性的太阳光线效果，跟踪图像中的亮光。";ui_label="追踪光线";
>
{
	pass GetCoarse
	{
		VertexShader = ScreenVS;
		PixelShader = GetCoarsePS;
		RenderTarget = CoarseTex;
	}
	pass TrackPass0
	{
		VertexShader = ScreenVS;
		PixelShader = TrackPass0PS;
		RenderTarget = PivotTex;
	}
	pass SavePivot
	{
		VertexShader = ScreenVS;
		PixelShader = SavePivotPS;
		RenderTarget = LastPivotTex;
	}
	pass Main
	{
		VertexShader = ScreenVS;
		PixelShader = MainPS;
		SRGBWriteEnable = true;
	}
}

//#endregion

} // Namespace.
