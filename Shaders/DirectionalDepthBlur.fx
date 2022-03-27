////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Directional Depth Blur shader for ReShade
// By Frans Bouma, aka Otis / Infuse Project (Otis_Inf)
// https://fransbouma.com 
//
// This shader has been released under the following license:
//
// Copyright (c) 2020 Frans Bouma
// All rights reserved.
// 
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
// 
// * Redistributions of source code must retain the above copyright notice, this
//   list of conditions and the following disclaimer.
// 
// * Redistributions in binary form must reproduce the above copyright notice,
//   this list of conditions and the following disclaimer in the documentation
//   and/or other materials provided with the distribution.
// 
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
////////////////////////////////////////////////////////////////////////////////////////////////////
// 
// Version History
// 18-apr-2020:		v1.2: Added blend factor for blur
// 13-apr-2020:		v1.1: Added highlight control (I know it flips the hue in focus point mode, it's a bug that actually looks great), 
//					      higher precision in buffers, better defaults
// 10-apr-2020:		v1.0: First release
//
////////////////////////////////////////////////////////////////////////////////////////////////////
// Translation of the UI into Chinese by Lilidream.


#include "ReShade.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

namespace DirectionalDepthBlur
{
// Uncomment line below for debug info / code / controls
//	#define CD_DEBUG 1
	
	#define DIRECTIONAL_DEPTH_BLUR_VERSION "v1.2"

	//////////////////////////////////////////////////
	//
	// User interface controls
	//
	//////////////////////////////////////////////////

	uniform float FocusPlane <
		ui_category = "对焦";
		ui_label= "对焦平面";
		ui_type = "slider";
		ui_min = 0.001; ui_max = 1.000;
		ui_step = 0.001;
		ui_tooltip = "模糊开始的平面";
	> = 0.010;
	uniform float FocusRange <
		ui_category = "对焦";
		ui_label= "对焦范围";
		ui_type = "slider";
		ui_min = 0.001; ui_max = 1.000;
		ui_step = 0.001;
		ui_tooltip = "调整对焦平面附件模糊或不模糊的范围。\n1.0是对焦平面最大范围";
	> = 0.001;
	uniform float FocusPlaneMaxRange <
		ui_category = "对焦";
		ui_label= "对焦平面最大范围";
		ui_type = "slider";
		ui_min = 10; ui_max = 300;
		ui_step = 1;
		ui_tooltip = "当对焦平面为1.0时的最大对焦范围.\n1000为地平线。";
	> = 150;
	uniform float BlurAngle <
		ui_category = "模糊调整";
		ui_label="模糊角度";
		ui_type = "slider";
		ui_min = 0.01; ui_max = 1.00;
		ui_tooltip = "模糊方向的角度";
		ui_step = 0.01;
	> = 1.0;
	uniform float BlurLength <
		ui_category = "模糊调整";
		ui_label = "模糊长度";
		ui_type = "slider";
		ui_min = 0.000; ui_max = 1.0;
		ui_step = 0.001;
		ui_tooltip = "每像素的模糊长度. 1.0为整个屏幕的长度。";
	> = 0.1;
	uniform float BlurQuality <
		ui_category = "模糊调整";
		ui_label = "模糊质量";
		ui_type = "slider";
		ui_min = 0.01; ui_max = 1.0;
		ui_step = 0.01;
		ui_tooltip = "模糊的质量，1.0表示模糊长度内的所有像素都被读取，0.5则为一半像素。";
	> = 0.5;
	uniform float ScaleFactor <
		ui_category = "模糊调整";
		ui_label = "缩放因子";
		ui_type = "slider";
		ui_min = 0.010; ui_max = 1.000;
		ui_step = 0.001;
		ui_tooltip = "像素模糊的缩放因子。低的值会降低原画面的大小并得到更宽的模糊笔触。";
	> = 1.000;
	uniform int BlurType < 
		ui_category = "模糊调整";
		ui_type = "combo";
		ui_min= 0; ui_max=1;
		ui_items="平行笔触\0对焦目标点笔触\0";
		ui_label = "模糊类型";
		ui_tooltip = "模糊类型，对焦点目标笔触表示每个像素模糊的方向都对着对焦点(放射状)。";
	> = 0;
	uniform float2 FocusPoint <
		ui_category = "模糊调整";
		ui_label = "模糊对焦点";
		ui_type = "slider";
		ui_step = 0.001;
		ui_min = 0.000; ui_max = 1.000;
		ui_tooltip = "对焦目标点笔触的对焦点XY坐标。0，0表示屏幕左上角，0.5,0.5为屏幕中心。";
	> = float2(0.5, 0.5);
	uniform float3 FocusPointBlendColor <
		ui_category = "模糊调整";
		ui_label = "对焦点颜色";
		ui_type= "color";
		ui_tooltip = "点对焦模式的对焦点颜色。距离对焦点越近的像素，就会更容易变成这个颜色。";
	> = float3(0.0,0.0,0.0);
	uniform float FocusPointBlendFactor <
		ui_category = "模糊调整";
		ui_label = "对焦点颜色混合因子";
		ui_type = "slider";
		ui_min = 0.000; ui_max = 1.000;
		ui_step = 0.001;
		ui_tooltip = "最终画面的对焦点颜色混合因子。";
	> = 1.000;
	uniform float HighlightGain <
		ui_category = "模糊调整";
		ui_label="高光增益";
		ui_type = "slider";
		ui_min = 0.00; ui_max = 5.00;
		ui_tooltip = "在笔触平面内增强高光，值越大高光越亮。";
		ui_step = 0.01;
	> = 0.500;	
	uniform float BlendFactor <
		ui_category = "模糊调整";
		ui_label="混合因子";
		ui_type = "drag";
		ui_min = 0.00; ui_max = 1.00;
		ui_tooltip = "效果应用到原画面的混合强度，1代表100%。";
		ui_step = 0.01;
	> = 1.000;	
#if CD_DEBUG
	// ------------- DEBUG
	uniform bool DBVal1 <
		ui_category = "Debugging";
	> = false;
	uniform bool DBVal2 <
		ui_category = "Debugging";
	> = false;
	uniform float DBVal3f <
		ui_category = "Debugging";
		ui_type = "slider";
		ui_min = 0.00; ui_max = 1.00;
		ui_step = 0.01;
	> = 0.0;
	uniform float DBVal4f <
		ui_category = "Debugging";
		ui_type = "slider";
		ui_min = 0.00; ui_max = 10.00;
		ui_step = 0.01;
	> = 1.0;
#endif
	//////////////////////////////////////////////////
	//
	// Defines, constants, samplers, textures, uniforms, structs
	//
	//////////////////////////////////////////////////

#ifndef BUFFER_PIXEL_SIZE
	#define BUFFER_PIXEL_SIZE	ReShade::PixelSize
#endif
#ifndef BUFFER_SCREEN_SIZE
	#define BUFFER_SCREEN_SIZE	ReShade::ScreenSize
#endif

	uniform float2 MouseCoords < source = "mousepoint"; >;
	
	texture texDownsampledBackBuffer { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; };
	texture texBlurDestination { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; }; 
	
	sampler samplerDownsampledBackBuffer { Texture = texDownsampledBackBuffer; AddressU = MIRROR; AddressV = MIRROR; AddressW = MIRROR;};
	sampler samplerBlurDestination { Texture = texBlurDestination; };
	
	struct VSPIXELINFO
	{
		float4 vpos : SV_Position;
		float2 texCoords : TEXCOORD0;
		float2 pixelDelta: TEXCOORD1;
		float blurLengthInPixels: TEXCOORD2;
		float focusPlane: TEXCOORD3;
		float focusRange: TEXCOORD4;
		float4 texCoordsScaled: TEXCOORD5;
	};
	
	//////////////////////////////////////////////////
	//
	// Functions
	//
	//////////////////////////////////////////////////
	
	float2 CalculatePixelDeltas(float2 texCoords)
	{
		float2 mouseCoords = MouseCoords * BUFFER_PIXEL_SIZE;
		
		return (float2(FocusPoint.x - texCoords.x, FocusPoint.y - texCoords.y)) * length(BUFFER_PIXEL_SIZE);
	}
	
	float3 AccentuateWhites(float3 fragment)
	{
		return fragment / (1.5 - clamp(fragment, 0, 1.49));	// accentuate 'whites'. 1.5 factor was empirically determined.
	}
	
	float3 CorrectForWhiteAccentuation(float3 fragment)
	{
		return (fragment.rgb * 1.5) / (1.0 + fragment.rgb);		// correct for 'whites' accentuation in taps. 1.5 factor was empirically determined.
	}
	
	float3 PostProcessBlurredFragment(float3 fragment, float maxLuma, float3 averageGained, float normalizationFactor)
	{
		const float3 lumaDotWeight = float3(0.3, 0.59, 0.11);

		averageGained.rgb = CorrectForWhiteAccentuation(averageGained.rgb);
		// increase luma to the max luma found on the gained taps. This over-boosts the luma on the averageGained, which we'll use to blend
		// together with the non-boosted fragment using the normalization factor to smoothly merge the highlights.
		averageGained.rgb *= 1+saturate(maxLuma - dot(fragment, lumaDotWeight));
		fragment = (1-normalizationFactor) * fragment + normalizationFactor * averageGained.rgb;
		return fragment;
	}
	
	//////////////////////////////////////////////////
	//
	// Vertex Shaders
	//
	//////////////////////////////////////////////////
	
	VSPIXELINFO VS_PixelInfo(in uint id : SV_VertexID)
	{
		VSPIXELINFO pixelInfo;
		
		if (id == 2)
			pixelInfo.texCoords.x = 2.0;
		else
			pixelInfo.texCoords.x = 0.0;
		if (id == 1)
			pixelInfo.texCoords.y = 2.0;
		else
			pixelInfo.texCoords.y = 0.0;
		pixelInfo.vpos = float4(pixelInfo.texCoords * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
		sincos(6.28318530717958 * BlurAngle, pixelInfo.pixelDelta.y, pixelInfo.pixelDelta.x);
		pixelInfo.pixelDelta *= length(BUFFER_PIXEL_SIZE);
		pixelInfo.blurLengthInPixels = length(BUFFER_SCREEN_SIZE) * BlurLength;
		pixelInfo.focusPlane = (FocusPlane * FocusPlaneMaxRange) / 1000.0; 
		pixelInfo.focusRange = (FocusRange * FocusPlaneMaxRange) / 1000.0;
		pixelInfo.texCoordsScaled = float4(pixelInfo.texCoords * ScaleFactor, pixelInfo.texCoords / ScaleFactor);
		return pixelInfo;
	}

	//////////////////////////////////////////////////
	//
	// Pixel Shaders
	//
	//////////////////////////////////////////////////

	void PS_Blur(VSPIXELINFO pixelInfo, out float4 fragment : SV_Target0)
	{
		const float3 lumaDotWeight = float3(0.3, 0.59, 0.11);
		// pixelInfo.texCoordsScaled.xy is for scaled down UV, pixelInfo.texCoordsScaled.zw is for scaled up UV
		float4 average = float4(tex2Dlod(samplerDownsampledBackBuffer, float4(pixelInfo.texCoordsScaled.xy, 0, 0)).rgb, 1.0);
		float3 averageGained = AccentuateWhites(average.rgb);
		float2 pixelDelta;
		if (BlurType == 0)
			pixelDelta = pixelInfo.pixelDelta;
		else
			pixelDelta = CalculatePixelDeltas(pixelInfo.texCoords);
		float maxLuma = dot(AccentuateWhites(float4(tex2Dlod(samplerDownsampledBackBuffer, float4(pixelInfo.texCoordsScaled.xy, 0, 0)).rgb, 1.0).rgb).rgb, lumaDotWeight);
		for(float tapIndex=0.0;tapIndex<pixelInfo.blurLengthInPixels;tapIndex+=(1/BlurQuality))
		{
			float2 tapCoords = (pixelInfo.texCoords + (pixelDelta * tapIndex));
			float3 tapColor = tex2Dlod(samplerDownsampledBackBuffer, float4(tapCoords * ScaleFactor, 0, 0)).rgb;
			float weight;
			if (ReShade::GetLinearizedDepth(tapCoords) <= pixelInfo.focusPlane)
				weight = 0.0;
			else
				weight = 1-(tapIndex/ pixelInfo.blurLengthInPixels);
			average.rgb+=(tapColor * weight);
			average.a+=weight;
			float3 gainedTap = AccentuateWhites(tapColor.rgb);
			averageGained += gainedTap * weight;
			if (weight > 0)
				maxLuma = max(maxLuma, saturate(dot(gainedTap, lumaDotWeight)));
		}
		fragment.rgb = average.rgb / (average.a + (average.a==0));
		if (BlurType != 0)
			fragment.rgb = lerp(fragment.rgb, lerp(FocusPointBlendColor, fragment.rgb, smoothstep(0, 1, distance(pixelInfo.texCoords, FocusPoint))), FocusPointBlendFactor);
		fragment.rgb = lerp(tex2Dlod(samplerDownsampledBackBuffer, float4(pixelInfo.texCoordsScaled.xy, 0, 0)).rgb, PostProcessBlurredFragment(fragment.rgb, saturate(maxLuma), (averageGained / (average.a + (average.a==0))), HighlightGain), BlendFactor);
		fragment.a = 1.0;
	}


	void PS_Combiner(VSPIXELINFO pixelInfo, out float4 fragment : SV_Target0)
	{
		const float colorDepth = ReShade::GetLinearizedDepth(pixelInfo.texCoords);
		fragment = tex2Dlod(ReShade::BackBuffer, float4(pixelInfo.texCoords, 0, 0));
		if(colorDepth <= pixelInfo.focusPlane || (BlurLength <= 0.0))
			return;
		const float rangeEnd = (pixelInfo.focusPlane+pixelInfo.focusRange);
		float blendFactor = 1.0;
		if (rangeEnd > colorDepth)
			blendFactor = smoothstep(0, 1, 1-((rangeEnd-colorDepth) / pixelInfo.focusRange));
		fragment.rgb = lerp(fragment.rgb, tex2Dlod(samplerBlurDestination, float4(pixelInfo.texCoords, 0, 0)).rgb, blendFactor);
#if GSHADE_DITHER
		fragment.rgb += TriDither(fragment.rgb, pixelInfo.texCoords, BUFFER_COLOR_BIT_DEPTH);
#endif
	}
	
	void PS_DownSample(VSPIXELINFO pixelInfo, out float4 fragment : SV_Target0)
	{
		// pixelInfo.texCoordsScaled.xy is for scaled down UV, pixelInfo.texCoordsScaled.zw is for scaled up UV
		const float2 sourceCoords = pixelInfo.texCoordsScaled.zw;
		if(max(sourceCoords.x, sourceCoords.y) > 1.0001)
		{
			// source pixel is outside the frame
			discard;
		}
		fragment = tex2D(ReShade::BackBuffer, sourceCoords);
	}
	
	//////////////////////////////////////////////////
	//
	// Techniques
	//
	//////////////////////////////////////////////////

	technique DirectionalDepthBlur
	< ui_tooltip = "方向性深度模糊"
			DIRECTIONAL_DEPTH_BLUR_VERSION
			"\n===========================================\n\n"
			"此着色器可添加基于深度的每像素的方向性模糊。\n\n"
			"Directional Depth Blur was written by Frans 'Otis_Inf' Bouma and is part of OtisFX\n"
			"https://fransbouma.com | https://github.com/FransBouma/OtisFX"; ui_label="方向性深度模糊";>
	{
		pass Downsample { VertexShader = VS_PixelInfo ; PixelShader = PS_DownSample; RenderTarget = texDownsampledBackBuffer; }
		pass BlurPass { VertexShader = VS_PixelInfo; PixelShader = PS_Blur; RenderTarget = texBlurDestination; }
		pass Combiner { VertexShader = VS_PixelInfo; PixelShader = PS_Combiner; }
	}
}
