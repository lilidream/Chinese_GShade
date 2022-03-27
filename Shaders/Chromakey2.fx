/*
Chromakey PS v1.5.2a (c) 2018 Jacob Maximilian Fober

This work is licensed under the Creative Commons 
Attribution-ShareAlike 4.0 International License. 
To view a copy of this license, visit 
http://creativecommons.org/licenses/by-sa/4.0/.
*/
// Translation of the UI into Chinese by Lilidream.
#include "ReShade.fxh"

	  ////////////
	 /// MENU ///
	////////////

uniform float Threshold2 <
	ui_label = "阈值";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 0.999; ui_step = 0.001;
	ui_category = "调整深度";
> = 0.5;

uniform bool RadialX2 <
	ui_label = "水平放射深度";
	ui_category = "放射距离";
	ui_category_closed = true;
> = false;
uniform bool RadialY2 <
	ui_label = "垂直放射深度";
	ui_category = "放射距离";
> = false;

uniform int FOV2 <
	ui_label = "视场FOV(水平)";
  ui_type = "slider";
	ui_tooltip = "以角度为单位的视场";
	ui_step = .01;
	ui_min = 0; ui_max = 200;
	ui_category = "放射距离";
> = 90;

uniform int CKPass2 <
	ui_label = "键类型";
	ui_type = "combo";
	ui_items = "背景键\0前景键\0";
	ui_category = "方向调整";
> = 0;

uniform bool Floor2 <
	ui_label = "遮罩地板";
	ui_category = "地板遮罩 (实验性)";
	ui_category_closed = true;
> = false;

uniform float FloorAngle2 <
	ui_label = "地板角度";
	ui_type = "slider";
	ui_category = "地板遮罩 (实验性)";
	ui_min = 0.0; ui_max = 1.0;
> = 1.0;

uniform int Precision2 <
	ui_label = "地板精度";
	ui_type = "slider";
	ui_category = "地板遮罩 (实验性)";
	ui_min = 2; ui_max = 9216;
> = 4;

uniform int Color2 <
	ui_label = "键颜色";
	ui_tooltip = "Ultimatte(tm)超级蓝色与绿色是色度键的工业标准";
	ui_type = "combo";
	ui_items = "纯绿 (RGB 0,255,0)\0纯红 (RGB 255,0,255)\0纯蓝 (RGB 0,255,0)\0Ultimatte(tm)超级蓝 (RGB 18,46,184)\0Ultimatte(tm)超级绿 (RGB 74,214,92)\0自定义\0";
	ui_category = "颜色设置";
	ui_category_closed = false;
> = 0;

uniform float3 CustomColor2 <
	ui_type = "color";
	ui_label = "自定义颜色";
	ui_category = "颜色设置";
> = float3(0.0, 1.0, 0.0);

uniform bool AntiAliased2 <
	ui_label = "反锯齿遮罩";
	ui_tooltip = "关闭此选项会减少遮罩间隙";
	ui_category = "额外设置";
	ui_category_closed = true;
> = false;

uniform bool InvertDepth2 <
	ui_label = "反转深度";
	ui_tooltip = "反转深度从而将颜色应用到前景。";
	ui_category = "额外设置";
> = false;


	  /////////////////
	 /// FUNCTIONS ///
	/////////////////

float MaskAA(float2 texcoord)
{
	// Sample depth image
	float Depth;
	if (InvertDepth2)
		Depth = 1 - ReShade::GetLinearizedDepth(texcoord);
	else
		Depth = ReShade::GetLinearizedDepth(texcoord);

	// Convert to radial depth
	float2 Size;
	Size.x = tan(radians(FOV2*0.5));
	Size.y = Size.x / BUFFER_ASPECT_RATIO;
	if(RadialX2) Depth *= length(float2((texcoord.x-0.5)*Size.x, 1.0));
	if(RadialY2) Depth *= length(float2((texcoord.y-0.5)*Size.y, 1.0));

	// Return jagged mask
	if(!AntiAliased2) return step(Threshold2, Depth);

	// Get half-pixel size in depth value
	float hPixel = fwidth(Depth)*0.5;

	return smoothstep(Threshold2-hPixel, Threshold2+hPixel, Depth);
}

float3 GetPosition(float2 texcoord)
{
	// Get view angle for trigonometric functions
	const float theta = radians(FOV2*0.5);

	float3 position = float3( texcoord*2.0-1.0, ReShade::GetLinearizedDepth(texcoord) );
	// Reverse perspective
	position.xy *= position.z;

	return position;
}

// Normal map (OpenGL oriented) generator from DisplayDepth.fx
float3 GetNormal(float2 texcoord)
{
	const float3 offset = float3(BUFFER_PIXEL_SIZE.xy, 0.0);
	const float2 posCenter = texcoord.xy;
	const float2 posNorth  = posCenter - offset.zy;
	const float2 posEast   = posCenter + offset.xz;

	const float3 vertCenter = float3(posCenter - 0.5, 1.0) * ReShade::GetLinearizedDepth(posCenter);
	const float3 vertNorth  = float3(posNorth - 0.5,  1.0) * ReShade::GetLinearizedDepth(posNorth);
	const float3 vertEast   = float3(posEast - 0.5,   1.0) * ReShade::GetLinearizedDepth(posEast);

	return normalize(cross(vertCenter - vertNorth, vertCenter - vertEast)) * 0.5 + 0.5;
}

	  //////////////
	 /// SHADER ///
	//////////////

float3 Chromakey2PS(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	// Define chromakey color, Ultimatte(tm) Super Blue, Ultimatte(tm) Green, or user color
	float3 Screen;
	switch(Color2)
	{
		case 0:{ Screen = float3(0.0, 1.0, 0.0); break; }    // Green
		case 1:{ Screen = float3(1.0, 0.0, 0.0); break; }    // Red
		case 2:{ Screen = float3(0.0, 0.0, 1.0); break; }    // Blue
		case 3:{ Screen = float3(0.07, 0.18, 0.72); break; } // Ultimatte(tm) Super Blue
		case 4:{ Screen = float3(0.29, 0.84, 0.36); break; } // Ultimatte(tm) Green
		case 5:{ Screen = CustomColor2;              break; } // User defined color
	}

	// Generate depth mask
	float DepthMask = MaskAA(texcoord);

	if (Floor2)
	{

		bool FloorMask = (float)round( GetNormal(texcoord).y*Precision2 )/Precision2==(float)round( FloorAngle2*Precision2 )/Precision2;

		if (FloorMask)
			DepthMask = 1.0;
	}

	if(bool(CKPass2)) DepthMask = 1.0-DepthMask;

	return lerp(tex2D(ReShade::BackBuffer, texcoord).rgb, Screen, DepthMask);
}


	  //////////////
	 /// OUTPUT ///
	//////////////

technique Chromakey2 < ui_tooltip = "根据深度生成绿幕墙"; ui_label="色度键2";>
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = Chromakey2PS;
	}
}
