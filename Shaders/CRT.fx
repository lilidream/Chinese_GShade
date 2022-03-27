// CRT shader
// 
// Copyright (C) 2010-2012 cgwg, Themaister and DOLLS
// 
// This program is free software; you can redistribute it and/or modify it
// under the terms of the GNU General Public License as published by the Free
// Software Foundation; either version 2 of the License, or (at your option)
// any later version.
// Translation of the UI into Chinese by Lilidream.

// Comment the next line to disable interpolation in linear gamma (and gain speed).
//#define LINEAR_PROCESSING

uniform float Amount <
	ui_label = "数量";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_tooltip = "显像管效果数量";
> = 1.00;
uniform float Resolution <
	ui_label = "分辨率";
	ui_type = "slider";
	ui_min = 1.0; ui_max = 8.0;
	ui_tooltip = "输入大小系数";
> = 1.15;
uniform float Gamma <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 4.0;
	ui_tooltip = "模拟显像管的Gamma值";
> = 2.4;
uniform float MonitorGamma <
	ui_label = "显示器Gamma";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 4.0;
	ui_tooltip = "显示器的Gamma";
> = 2.2;
uniform float Brightness <
	ui_label = "亮度";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 3.0;
	ui_tooltip = "用来使亮度提升一点";
> = 0.9;

uniform int ScanlineIntensity <
	ui_label = "扫描线强度";
	ui_type = "slider";
	ui_min = 2; ui_max = 4;
	ui_label = "扫描线强度";
> = 2;
uniform bool ScanlineGaussian <
	ui_label = "扫描线泛光效果";
	ui_tooltip = "使用新的非高斯扫描线泛光效果";
> = true;

uniform bool Curvature <
	ui_label = "弯曲";
	ui_tooltip = "桶型效果";
> = false;
uniform float CurvatureRadius <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 2.0;
	ui_label = "弯曲半径";
> = 1.5;
uniform float CornerSize <
	ui_type = "slider";
	ui_min = 0.00; ui_max = 0.02; ui_step = 0.001;
	ui_label = "倒角";
	ui_tooltip = "值越大角越圆";
> = 0.0100;
uniform float ViewerDistance <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 4.0;
	ui_label = "观察者距离";
	ui_tooltip = "模拟观察者看显示器的距离效果";
> = 2.00;
uniform float2 Angle <
	ui_label = "角度";
	ui_type = "slider";
	ui_min = -0.2; ui_max = 0.2;
	ui_tooltip = "弧度制的倾斜角度";
> = 0.00;

uniform float Overscan <
	ui_label = "过扫描";
	ui_type = "slider";
	ui_min = 1.0; ui_max = 1.10; ui_step = 0.01;
	ui_tooltip = "过扫描 (例如 1.02 表示 2% 过扫描).";
> = 1.01;
uniform bool Oversample <
	ui_label = "过采样";
	ui_tooltip = "开启三倍的波束特征过采样(警告: 对性能有影响)";
> = true;

#include "ReShade.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

#define CeeJay_aspect float2(1.0, 0.75)

// A bunch of useful values we'll need in the fragment shader.
#define sinangle sin(Angle)
#define cosangle cos(Angle)
#define stretch maxscale()

// Macros.
#define FIX(c) max(abs(c), 1e-5);

#ifndef PI
  #define PI 3.1415926535897932
#endif

// The size of one texel, in texture-coordinates.
#define coone 1.0 / rubyTextureSize

#define mod_factor tex.x * rubyTextureSize.x * rubyOutputSize.x / rubyInputSize.x

#ifdef LINEAR_PROCESSING
	#define TEX2D(c) pow(tex2D(ReShade::BackBuffer, (c)), Gamma)
#else
	#define TEX2D(c) tex2D(ReShade::BackBuffer, (c))
#endif

float intersect(float2 xy)
{
	const float A = dot(xy,xy) + (ViewerDistance * ViewerDistance);
	const float B = 2.0 * (CurvatureRadius * (dot(xy, sinangle) - ViewerDistance * cosangle.x * cosangle.y) - ViewerDistance * ViewerDistance);
	const float C = ViewerDistance * ViewerDistance + 2.0 * CurvatureRadius * ViewerDistance * cosangle.x * cosangle.y; //all constants
	return (-B - sqrt(B * B -4.0 * A * C)) / (2.0 * A);
}

float2 bkwtrans(float2 xy)
{
	const float c = intersect(xy);
	float2 _point = float2(c, c) * xy;
	_point -= float2(-CurvatureRadius, -CurvatureRadius) * sinangle;
	_point /= float2(CurvatureRadius, CurvatureRadius);
	const float2 tang = sinangle / cosangle;
	const float2 poc = _point / cosangle;
	const float A = dot(tang, tang) + 1.0;
	const float B = -2.0 * dot(poc, tang);
	const float C = dot(poc, poc) - 1.0;
	const float a = (-B + sqrt(B * B -4.0 * A * C)) / (2.0 * A);
	const float2 uv = (_point - a * sinangle) / cosangle;
	const float r = CurvatureRadius * acos(a);
	return uv * r / sin(r / CurvatureRadius);
}
float2 fwtrans(float2 uv)
{
	const float r = FIX(sqrt(dot(uv, uv)));
	uv *= sin(r / CurvatureRadius) / r;
	const float x = 1.0 - cos(r / CurvatureRadius);
	const float D = ViewerDistance / CurvatureRadius + x * cosangle.x * cosangle.y + dot(uv, sinangle);
	return ViewerDistance * (uv * cosangle - x * sinangle) / D;
}

float3 maxscale()
{
	const float2 c = bkwtrans(-CurvatureRadius * sinangle / (1.0 + CurvatureRadius / ViewerDistance * cosangle.x * cosangle.y));
	const float2 a = float2(0.5, 0.5) * CeeJay_aspect;
	const float2 lo = float2(fwtrans(float2(-a.x, c.y)).x, fwtrans(float2(c.x,-a.y)).y) / CeeJay_aspect;
	const float2 hi = float2(fwtrans(float2(+a.x, c.y)).x, fwtrans(float2(c.x, +a.y)).y) / CeeJay_aspect;
	return float3((hi + lo) * CeeJay_aspect * 0.5, max(hi.x - lo.x, hi.y - lo.y));
}

float2 transform(float2 coord, float2 textureSize, float2 inputSize)
{
	coord *= textureSize / inputSize;
	coord = (coord - 0.5) * CeeJay_aspect * stretch.z + stretch.xy;
	return (bkwtrans(coord) / float2(Overscan, Overscan) / CeeJay_aspect + 0.5) * inputSize / textureSize;
}

float corner(float2 coord, float2 textureSize, float2 inputSize)
{
	coord *= textureSize / inputSize;
	coord = (coord - 0.5) * float2(Overscan, Overscan) + 0.5;
	coord = min(coord, 1.0 - coord) * CeeJay_aspect;
	const float2 cdist = float2(CornerSize, CornerSize);
	coord = (cdist - min(coord, cdist));
	const float dist = sqrt(dot(coord, coord));
	return clamp((cdist.x-dist) * 1000.0, 0.0, 1.0);
}

// Calculate the influence of a scanline on the current pixel.
//
// 'distance' is the distance in texture coordinates from the current
// pixel to the scanline in question.
// 'color' is the colour of the scanline at the horizontal location of
// the current pixel.
float4 scanlineWeights(float distance, float4 color)
{
	// "wid" controls the width of the scanline beam, for each RGB channel
	// The "weights" lines basically specify the formula that gives
	// you the profile of the beam, i.e. the intensity as
	// a function of distance from the vertical center of the
	// scanline. In this case, it is gaussian if width=2, and
	// becomes nongaussian for larger widths. Ideally this should
	// be normalized so that the integral across the beam is
	// independent of its width. That is, for a narrower beam
	// "weights" should have a higher peak at the center of the
	// scanline than for a wider beam.
	if (!ScanlineGaussian)
	{
		const float4 wid = 0.3 + 0.1 * (color * color * color);
		const float4 weights = float4(distance / wid);
		return 0.4 * exp(-weights * weights) / wid;
	}
	else
	{
		const float4 wid = 2.0 * pow(abs(color), 4.0) + 2.0;
		const float4 weights = (distance / 0.3).xxxx;
		return 1.4 * exp(-pow(abs(weights * rsqrt(0.5 * wid)), abs(wid))) / (0.2 * wid + 0.6);
	}
}

float3 AdvancedCRTPass(float4 position : SV_Position, float2 tex : TEXCOORD) : SV_Target
{
	// Here's a helpful diagram to keep in mind while trying to
	// understand the code:
	//
	//  |      |      |      |      |
	// -------------------------------
	//  |      |      |      |      |
	//  |  01  |  11  |  21  |  31  | <-- current scanline
	//  |      | @    |      |      |
	// -------------------------------
	//  |      |      |      |      |
	//  |  02  |  12  |  22  |  32  | <-- next scanline
	//  |      |      |      |      |
	// -------------------------------
	//  |      |      |      |      |
	//
	// Each character-cell represents a pixel on the output
	// surface, "@" represents the current pixel (always somewhere
	// in the bottom half of the current scan-line, or the top-half
	// of the next scanline). The grid of lines represents the
	// edges of the texels of the underlying texture.

	const float  Input_ratio = ceil(256 * Resolution);
	const float2 Resolution = float2(Input_ratio, Input_ratio);
	const float2 rubyTextureSize = Resolution;
	const float2 rubyInputSize = Resolution;
	const float2 rubyOutputSize = BUFFER_SCREEN_SIZE;

	float2 orig_xy;
	if (Curvature)
		orig_xy = transform(tex, rubyTextureSize, rubyInputSize);
	else
		orig_xy = tex;
	const float cval = corner(orig_xy, rubyTextureSize, rubyInputSize);

	// Of all the pixels that are mapped onto the texel we are
	// currently rendering, which pixel are we currently rendering?
	const float2 ratio_scale = orig_xy * rubyTextureSize - 0.5;

	const float filter = fwidth(ratio_scale.y);
	float2 uv_ratio = frac(ratio_scale);

	// Snap to the center of the underlying texel.
	const float2 xy = (floor(ratio_scale) + 0.5) / rubyTextureSize;

	// Calculate Lanczos scaling coefficients describing the effect
	// of various neighbour texels in a scanline on the current
	// pixel.
	float4 coeffs = PI * float4(1.0 + uv_ratio.x, uv_ratio.x, 1.0 - uv_ratio.x, 2.0 - uv_ratio.x);

	// Prevent division by zero.
	coeffs = FIX(coeffs);

	// Lanczos2 kernel.
	coeffs = 2.0 * sin(coeffs) * sin(coeffs / 2.0) / (coeffs * coeffs);

	// Normalize.
	coeffs /= dot(coeffs, 1.0);

	// Calculate the effective colour of the current and next
	// scanlines at the horizontal location of the current pixel,
	// using the Lanczos coefficients above.
	float4 col  = clamp(mul(coeffs, float4x4(
		TEX2D(xy + float2(-coone.x, 0.0)),
		TEX2D(xy),
		TEX2D(xy + float2(coone.x, 0.0)),
		TEX2D(xy + float2(2.0 * coone.x, 0.0)))),
		0.0, 1.0);
	float4 col2 = clamp(mul(coeffs, float4x4(
		TEX2D(xy + float2(-coone.x, coone.y)),
		TEX2D(xy + float2(0.0, coone.y)),
		TEX2D(xy + coone),
		TEX2D(xy + float2(2.0 * coone.x, coone.y)))),
		0.0, 1.0);

#ifndef LINEAR_PROCESSING
	col  = pow(abs(col) , Gamma);
	col2 = pow(abs(col2), Gamma);
#endif

	// Calculate the influence of the current and next scanlines on
	// the current pixel.
	float4 weights  = scanlineWeights(uv_ratio.y, col);
	float4 weights2 = scanlineWeights(1.0 - uv_ratio.y, col2);

#if __RENDERER__ < 0xa000 && !__RESHADE_PERFORMANCE_MODE__
	[flatten]
#endif
	if (Oversample)
	{
		uv_ratio.y = uv_ratio.y + 1.0 / 3.0 * filter;
		weights = (weights + scanlineWeights(uv_ratio.y, col)) / 3.0;
		weights2 = (weights2 + scanlineWeights(abs(1.0 - uv_ratio.y), col2)) / 3.0;
		uv_ratio.y = uv_ratio.y - 2.0 / 3.0 * filter;
		weights = weights + scanlineWeights(abs(uv_ratio.y), col) / 3.0;
		weights2 = weights2 + scanlineWeights(abs(1.0 - uv_ratio.y), col2) / 3.0;
	}

	float3 mul_res = (col * weights + col2 * weights2).rgb * cval.xxx;

	// dot-mask emulation:
	// Output pixels are alternately tinted green and magenta.
	const float3 dotMaskWeights = lerp(float3(1.0, 0.7, 1.0), float3(0.7, 1.0, 0.7), floor(mod_factor % ScanlineIntensity));
	mul_res *= dotMaskWeights * float3(0.83, 0.83, 1.0) * Brightness;

	// Convert the image gamma for display on our output device.
	mul_res = pow(abs(mul_res), 1.0 / MonitorGamma);

	const float3 color = TEX2D(orig_xy).rgb * cval.xxx;

#if GSHADE_DITHER
	const float3 outcolor = saturate(lerp(color, mul_res, Amount));
	return outcolor + TriDither(outcolor, tex, BUFFER_COLOR_BIT_DEPTH);
#else
	return saturate(lerp(color, mul_res, Amount));
#endif
}

technique AdvancedCRT <ui_label="高级阴极射线管(老式显示器)";>
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = AdvancedCRTPass;
	}
}
