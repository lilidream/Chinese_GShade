 ////-------------//
 ///**NFAA Fast**///
 //-------------////

 //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
 //* Normal Filter Anti Aliasing.                                     																										        *//
 //* For Reshade 3.0+																																								*//
 //* --------------------------																																						*//
 //* This work is licensed under a Creative Commons Attribution 3.0 Unported License.																								*//
 //* So you are free to share, modify and adapt it for your needs, and even use it for commercial use.																				*//
 //* I would also love to hear about a project you are using it with.																												*//
 //* https://creativecommons.org/licenses/by/3.0/us/																																*//
 //*																																												*//
 //* Have fun,																																										*//
 //* Jose Negrete AKA BlueSkyDefender																																				*//
 //* Based on port by b34r                       																																	*//
 //* https://www.gamedev.net/forums/topic/580517-nfaa---a-post-process-anti-aliasing-filter-results-implementation-details/?page=2													*//	
 //* ---------------------------------																																				*//
 //*                                                                            																									*//
 //* 																																												*//
 //* Lightly optimized by Marot Satil for the GShade project.
 //*
 //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Translation of the UI into Chinese by Lilidream.

uniform int AA_Adjust <
	ui_type = "slider";
	ui_min = 1; ui_max = 32;
	ui_label = "抗锯齿强度";
	ui_tooltip = "调整抗锯齿强度。\n默认为 16";
	ui_category = "法线过滤抗锯齿(NFAA)";
> = 16;

uniform int View_Mode <
	ui_type = "combo";
	ui_items = "法线过滤抗锯齿(NFAA)\0遮罩视角\0法线\0DLSS\0";
	ui_label = "视角模式";
	ui_tooltip = "这是用来选择正常视图输出或Debug视图。\n"
	"NFAA遮罩给你一个应用了法线抗锯齿的更清晰的图像。\n遮罩视角给你一个边缘检测的视角。\n法线给你一个已创建的法线的视图。\nDLSS是NV_AI_DLSS的模仿试验。\n默认是NFAA。";
	ui_category = "法线过滤抗锯齿(NFAA)";
> = 0;

uniform float Mask_Adjust <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 2.0;
	ui_label = "遮罩调整";
	ui_tooltip = "使用此调整遮罩。默认为1.00";
	ui_category = "法线过滤抗锯齿(NFAA)";
> = 1.00;

/////////////////////////////////////////////////////D3D Starts Here/////////////////////////////////////////////////////////////////
#define pix float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT)

texture BackBufferTex : COLOR;

sampler BackBuffer 
	{ 
		Texture = BackBufferTex;
	};
	
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Luminosity Intensity
float LI(in float3 value)
{	
	return dot(value.rgb,float3(0.333, 0.333, 0.333));
}

float4 GetBB(float2 texcoord : TEXCOORD)
{
	return tex2D(BackBuffer, texcoord);
}

float4 Out(float4 position : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float4 NFAA; // The Edge Seeking code can be adjusted to look for longer edges.
	float2 UV = texcoord.xy, SW = pix, n; // But, I don't think it's really needed.
	float t, l, r, d;
	// Find Edges
	t = LI(GetBB( float2( UV.x , UV.y - SW.y ) ).rgb);
	d = LI(GetBB( float2( UV.x , UV.y + SW.y ) ).rgb);
	l = LI(GetBB( float2( UV.x - SW.x , UV.y ) ).rgb);
	r = LI(GetBB( float2( UV.x + SW.x , UV.y ) ).rgb);
	n = float2(t - d,-(r - l));
	// I should have made rep adjustable. But, I didn't see the need.
	// Since my goal was to make this AA fast cheap and simple.	
    float   nl = length(n), Rep = rcp(AA_Adjust);
 
	if(View_Mode == 3)
		Rep = rcp(128);  
	// Seek aliasing and apply AA. Think of this as basicly blur control.
    if (nl < Rep)
    {
		NFAA = GetBB(UV);
	}
    else
    {
		n *= pix / (nl * 0.5);
 	
	const float4   o = GetBB( UV ),
			t0 = GetBB( UV + float2(n.x, -n.y)  * 0.5) * 0.9,
			t1 = GetBB( UV - float2(n.x, -n.y)  * 0.5) * 0.9,
			t2 = GetBB( UV + n * 0.9) * 0.75,
			t3 = GetBB( UV - n * 0.9) * 0.75;
 
		NFAA = (o + t0 + t1 + t2 + t3) / 4.3;
	}
	// Lets make that mask for a sharper image.
	float Mask = nl*(2.5 * Mask_Adjust);
	
	if (Mask > 0.025)
		Mask = 1-Mask;
	else
		Mask = 1;
	// Super Evil Magic Number.
	Mask = saturate(lerp(Mask,1,-1));
	
	// Final color
	if(View_Mode == 0)
	{
		NFAA = lerp(NFAA,GetBB( texcoord.xy ), Mask );
	}
	else if(View_Mode == 1)
	{
		NFAA = Mask;
	}
	else if (View_Mode == 2)
	{
		NFAA = float3(-float2(-(r - l),-(t - d)) * 0.5 + 0.5,1);
	}
	
return NFAA;
}

///////////////////////////////////////////////////////////ReShade.fxh/////////////////////////////////////////////////////////////

// Vertex shader generating a triangle covering the entire screen
void PostProcessVS(in uint id : SV_VertexID, out float4 position : SV_Position, out float2 texcoord : TEXCOORD)
{
	if (id == 2)
		texcoord.x = 2.0;
	else
		texcoord.x = 0.0;

	if (id == 1)
		texcoord.y = 2.0;
	else
		texcoord.y = 0.0;

	position = float4(texcoord * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
}

//*Rendering passes*//
technique Normal_Filter_Anti_Aliasing <ui_label="法线过滤抗锯齿(NFAA)";>
{
			pass NFAA_Fast
		{
			VertexShader = PostProcessVS;
			PixelShader = Out;	
		}
}
