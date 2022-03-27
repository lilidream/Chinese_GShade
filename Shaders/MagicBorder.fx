////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Magic Border shader
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
// Translation of the UI into Chinese by Lilidream.

#include "ReShade.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

namespace MagicBorder
{
	#define MAGIC_BORDER_VERSION "v1.0.1"

	uniform float LeftTopCornerDepth <
		ui_label = "左上角窗口深度";
		ui_type = "slider";
		ui_min = 0.00; ui_max = 300.00;
		ui_step = 0.01;
		ui_tooltip = "场景中放置窗口的左上角深度。\n0.0为镜头处，1000为无限远";
	> = 1.0;

	uniform float RightTopCornerDepth <
		ui_label = "右上角窗口深度";
		ui_type = "slider";
		ui_min = 0.00; ui_max = 300.00;
		ui_step = 0.01;
		ui_tooltip = "场景中放置窗口的右上角深度。\n0.0为镜头处，1000为无限远";
	> = 1.0;
	
	uniform float RightBottomCornerDepth <
		ui_label = "右下角窗口深度";
		ui_type = "slider";
		ui_min = 0.00; ui_max = 300.00;
		ui_step = 0.01;
		ui_tooltip = "场景中放置窗口的右下角深度。\n0.0为镜头处，1000为无限远";
	> = 1.0;
	
	uniform float LeftBottomCornerDepth <
		ui_label = "左下角窗口深度";
		ui_type = "slider";
		ui_min = 0.00; ui_max = 300.00;
		ui_step = 0.01;
		ui_tooltip = "场景中放置窗口的左下角深度。\n0.0为镜头处，1000为无限远";
	> = 1.0;
	
	uniform bool ShowDepths <
		ui_label = "显示边角深度";
		ui_tooltip = "如果开启将显示每个边角的深度，白色为远，黑色为近。";
	> = false;
	
	uniform float2 PictureFrameLeftTop <
		ui_label = "画像框左上坐标";
		ui_type = "drag";
		ui_tooltip = "画像框左上角坐标";
	> = float2(0.1, 0.1);
	
	uniform float2 PictureFrameRightTop <
		ui_label = "画像框右上坐标";
		ui_type = "drag";
		ui_tooltip = "画像框右上角坐标";
	> = float2(0.9, 0.1);
	
	uniform float2 PictureFrameRightBottom <
		ui_label = "画像框右下坐标";
		ui_type = "drag";
		ui_tooltip = "画像框右下角坐标";
	> = float2(0.9, 0.9);
	
	uniform float2 PictureFrameLeftBottom <
		ui_label = "画像框左下坐标";
		ui_type = "drag";
		ui_tooltip = "画像框左下角坐标";
	> = float2(0.1, 0.9);
	
	uniform float4 BorderColor <
		ui_label = "边框颜色";
		ui_type= "color";
		ui_tooltip = "边框的颜色，使用alpha值来混合";
	> = float4(1.0, 1.0, 1.0, 1.0);
	
	uniform float4 PictureFrameColor <
		ui_label = "画像框颜色";
		ui_type= "color";
		ui_tooltip = "边框内区域的颜色，使用alpha值来混合";
	> = float4(0.7, 0.7, 0.7, 1.0);
	
	
	struct VSBORDERINFO
	{
		float4 vpos : SV_Position;
		float2 Texcoord : TEXCOORD0;
		float2 LeftTop : TEXCOORD1;
		float2 RightTop : TEXCOORD2;
		float2 RightBottom : TEXCOORD3;
		float2 LeftBottom : TEXCOORD4;
	};
	
	// As we use 4 different depth values, we have to interpolate the depth of the pixel with the passed in coord  based on these
	float CalculateDepthOfFrameAtCoord(VSBORDERINFO info)
	{
		// take the average of the 4 depths, while assigning weights based on how close the coord is to each of them. 
		const float2 coord = info.Texcoord;
		
		// The closer to the corner, the stronger the depth set for that corner has to be taken into account, so the weight is 1-distance_to_corner
		float distanceToCorner = 1-distance(float2(0, 0), coord);
		float2 average = float2((LeftTopCornerDepth/1000.0) * distanceToCorner, distanceToCorner);
		
		distanceToCorner = 1-distance(float2(1, 0), coord);
		average.x += ((RightTopCornerDepth/1000.0) * distanceToCorner);
		average.y += distanceToCorner;
		
		distanceToCorner = 1-distance(float2(1, 1), coord);
		average.x += ((RightBottomCornerDepth/1000.0) * distanceToCorner);
		average.y += distanceToCorner;
		
		distanceToCorner = 1-distance(float2(0, 1), coord);
		average.x += ((LeftBottomCornerDepth/1000.0) * distanceToCorner);
		average.y += distanceToCorner;
		
		return saturate(average.x/average.y);
	}
	
	
	// Tests if the passed in coord in info is inside the area marked with the four vertices. Returns true if that's the case
	// false otherwise (in which case the coord is part of the border). 
	// Simple poly-point hittest algo, borrowed from: http://www.jeffreythompson.org/collision-detection/poly-point.php
	// No need for a bounding box first cull as we just have 4 points.
	bool IsCoordInPictureArea(VSBORDERINFO info)
	{
		bool isInPictureArea = false;
		
		float2 vertices[4];
		vertices[0] = info.LeftTop;
		vertices[1] = info.RightTop;
		vertices[2] = info.RightBottom;
		vertices[3] = info.LeftBottom;
		
		// go through each of the vertices, plus
		// the next vertex in the list
		int next = 0;
		for (int current=0; current<4; current++) 
		{
			// get next vertex in list. if we've hit the end, wrap around to 0
			next = current+1;
			if (next == 4) next = 0;

			// get the vertices at our current position. this makes our if statement a little cleaner
			float2 vc = vertices[current];    // c for "current"
			float2 vn = vertices[next];       // n for "next"

			// compare position, flip 'collision' variable back and forth
			if (((vc.y >= info.Texcoord.y && vn.y < info.Texcoord.y) || (vc.y < info.Texcoord.y && vn.y >= info.Texcoord.y)) &&
				(info.Texcoord.x < (vn.x-vc.x)*(info.Texcoord.y-vc.y) / (vn.y-vc.y)+vc.x)) 
			{
				isInPictureArea = !isInPictureArea;
			}
		}
		
		return isInPictureArea;
	}
	
	
	//////////////////////////////////////////////////
	//
	// Vertex Shaders
	//
	//////////////////////////////////////////////////
	
	VSBORDERINFO VS_CalculateBorderInfo(in uint id : SV_VertexID)
	{
		VSBORDERINFO borderInfo;
		
		borderInfo.Texcoord.x = (id == 2) ? 2.0 : 0.0;
		borderInfo.Texcoord.y = (id == 1) ? 2.0 : 0.0;
		borderInfo.vpos = float4(borderInfo.Texcoord * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
		
		borderInfo.LeftTop = PictureFrameLeftTop;
		borderInfo.RightTop = PictureFrameRightTop;
		borderInfo.LeftBottom = PictureFrameLeftBottom;
		borderInfo.RightBottom = PictureFrameRightBottom;
		return borderInfo;
	}
	
	//////////////////////////////////////////////////
	//
	// Pixel Shaders
	//
	//////////////////////////////////////////////////
	
	void PS_DrawBorder(VSBORDERINFO borderInfo, out float4 fragment : SV_Target0)
	{
		const float4 originalFragment = tex2D(ReShade::BackBuffer, borderInfo.Texcoord);
		const float depthFragment = ReShade::GetLinearizedDepth(borderInfo.Texcoord);
		// check if the current pixel is in the border, we do that by doing a hittest with the polygon made up by the 4 corners. If we're hitting that
		// poly we're not in the border, otherwise we are.
		const bool isInPictureArea = IsCoordInPictureArea(borderInfo);
		float depthOfFrameAtCoord = CalculateDepthOfFrameAtCoord(borderInfo);
		fragment = isInPictureArea ? PictureFrameColor : BorderColor;
		fragment = depthFragment > depthOfFrameAtCoord ? lerp(originalFragment, fragment, fragment.a) : originalFragment;
		fragment = ShowDepths ? float4(depthOfFrameAtCoord, depthOfFrameAtCoord, depthOfFrameAtCoord, 1.0) : fragment;
#if GSHADE_DITHER
		fragment.rgb += TriDither(fragment.rgb, borderInfo.Texcoord, BUFFER_COLOR_BIT_DEPTH);
#endif
	}
	
	//////////////////////////////////////////////////
	//
	// Techniques
	//
	//////////////////////////////////////////////////

	technique MagicBorder
	< ui_tooltip = "魔法边框"
			MAGIC_BORDER_VERSION
			"\n===========================================\n\n"
			"魔术边框可以在镜头中创建一个边框，让你的部分内容在边框前面，就像跳出画面一样。"
			"Magic Border was written by Frans 'Otis_Inf' Bouma and is part of OtisFX\n"
			"https://fransbouma.com | https://github.com/FransBouma/OtisFX"; ui_label="魔法边框";>
	{
		pass DrawBorder { VertexShader = VS_CalculateBorderInfo; PixelShader = PS_DrawBorder;}
	}
}