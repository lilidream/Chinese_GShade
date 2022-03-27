 ////-------------//
 ///**NLM_Sharp**///
 //-------------////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Depth Based Unsharp Mask Non Local Means Contrast Adaptive Sharpening                                     																										
// For Reshade 3.0+																																					
// --------------------------																																			
// Have fun,																																								
// Jose Negrete AKA BlueSkyDefender																																		
// 																																											
// https://github.com/BlueSkyDefender/Depth3D																	
//  ---------------------------------
//	https://web.stanford.edu/class/cs448f/lectures/2.1/Sharpening.pdf
//																																	                                                                                                        																	
// 								Non-Local Means Made by panda1234lee ported over to Reshade by BSD													
//								Link for sorce info listed below																
// 								https://creativecommons.org/licenses/by-sa/4.0/ CC Thank You.
//
//								Non-Local Means sharpening figures out what
//								makes me different from other similar things
//								in the image, and exaggerates that
//                                                     
// LICENSE
// =======
// Copyright (c) 2017-2019 Advanced Micro Devices, Inc. All rights reserved.
// -------
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,
// modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:
// -------
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the
// Software.
// -------
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
// WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
// ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Translation of the UI into Chinese by Lilidream.

// This is the practical limit for the algorithm's scaling ability. Example resolutions;
//  1280x720  -> 1080p = 2.25x area
//  1536x864  -> 1080p = 1.56x area
//  1792x1008 -> 1440p = 2.04x area
//  1920x1080 -> 1440p = 1.78x area
//  1920x1080 ->    4K =  4.0x area
//  2048x1152 -> 1440p = 1.56x area
//  2560x1440 ->    4K = 2.25x area
//  3072x1728 ->    4K = 1.56x area

// It is best to run Smart Sharp after tonemapping.

uniform int Depth_Map <
	ui_type = "combo";
	ui_items = "正常\0反转\0";
	ui_label = "选择深度映射";
	ui_tooltip = "选择你的深度映射";
	ui_category = "深度缓存";
> = 0;

uniform float Depth_Map_Adjust <
	ui_type = "slider";
	ui_min = 1.0; ui_max = 1000.0; ui_step = 0.125;
	ui_label = "深度映射调整";
	ui_tooltip = "调整深度映射与锐化距离";
	ui_category = "深度缓存";
> = 250.0;

uniform bool Depth_Map_Flip <
	ui_label = "深度映射翻转";
	ui_tooltip = "如果深度映射上下颠倒，则翻转它";
	ui_category = "深度缓存";
> = false;

uniform bool No_Depth_Map <
	ui_label = "无深度映射";
	ui_tooltip = "如果你没有深度缓存，则打开它";
	ui_category = "深度缓存";
> = false;

uniform float Sharpness <
	ui_type = "slider";
    ui_label = "锐化强度";
    ui_min = 0.0; ui_max = 1.0;
    ui_tooltip = "从0到1来调整画面锐化的强度。\n"
				 "0=无锐化，1=完全锐化，超过1=超级易碎(?)。"
				 "默认为0.625";
	ui_category = "非局部平均对比度适应锐化";
> = 0.625;

uniform bool CAM_IOB <
	ui_label = "对比度适应遮罩忽略过亮";
	ui_tooltip = "与其在遮罩中允许过亮，不如允许对这个区域进行锐化。我认为打开这个更准确。";
	ui_category = "非局部平均对比度适应锐化";
> = false;

uniform bool CA_Mask_Boost <
	ui_label = "对比度适应遮罩增强";
	ui_tooltip = "此增大着色器的对比度适应遮罩部分的强度。";
	ui_category = "非局部平均对比度适应锐化";
> = false;

uniform bool CA_Removal <
	ui_label = "对比度适应遮罩移除";
	ui_tooltip = "此移除着色器的对比度适应遮罩部分。\n"
				 "给那些喜欢原生的非局部平均锐化的人用的。";
	ui_category = "非局部平均对比度适应锐化";
> = false;


uniform int NLM_Grounding <
	ui_type = "combo";
	ui_items = "精细\0中等\0粗糙\0";
	ui_label = "底色类型";
	ui_tooltip = "像咖啡一样选择你想让这个着色器变得多粗糙。给予非局部平均锐化的更多控制。";
	ui_category = "非局部平均过滤";
> = 0;

uniform bool Debug_View <
	ui_label = "视角模式";
	ui_tooltip = "用于选择正常或Debug输出视角。\n"
				 "用它开看着色器改变了画面的哪些部分。\n"
				 "正常给你正常的效果输出。\n"
				 "锐化是NLM锐化的全Debug。\n"
				 "深度信息是着色后输出。\n"
				 "默认是正常视角。";
	ui_category = "Debug";
> = 0;

/////////////////////////////////////////////////////D3D Starts Here/////////////////////////////////////////////////////////////////
#define pix float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT)

texture DepthBufferTex : DEPTH;

sampler DepthBuffer 
	{ 	
		Texture = DepthBufferTex; 
	};
	
texture BackBufferTex : COLOR;	

sampler BackBuffer 
	{ 
		Texture = BackBufferTex;
	};
				
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
float Depth(in float2 texcoord : TEXCOORD0)
{
	if (Depth_Map_Flip)
		texcoord.y =  1 - texcoord.y;
		
	float zBuffer = tex2D(DepthBuffer, texcoord).x; //Depth Buffer
	
	//Conversions to linear space.....
	//Near & Far Adjustment
	const float Far = 1.0, Near = 0.125/Depth_Map_Adjust; //Division Depth Map Adjust - Near
	
	const float2 Z = float2( zBuffer, 1-zBuffer );
	
	if (Depth_Map == 0)//DM0. Normal
		zBuffer = Far * Near / (Far + Z.x * (Near - Far));		
	else if (Depth_Map == 1)//DM1. Reverse
		zBuffer = Far * Near / (Far + Z.y * (Near - Far));	
		 
	return saturate(zBuffer);	
}	

float Min3(float x, float y, float z)
{
    return min(x, min(y, z));
}

float Max3(float x, float y, float z)
{
    return max(x, max(y, z));
}

float normaL2(float4 RGB) 
{ 
   return pow(RGB.r, 2) + pow(RGB.g, 2) + pow(RGB.b, 2) + pow(RGB.a, 2);
}

float4 BB(in float2 texcoord, float2 AD)
{
	return tex2Dlod(BackBuffer, float4(texcoord + AD,0,0));
}

float LI(float3 RGB)
{
	return dot(RGB,float3(0.2126, 0.7152, 0.0722));
}

float GT()
{
if (NLM_Grounding == 2)
	return 1.5;
else if(NLM_Grounding == 1)
	return 1.25;
else
	return 1.0;
}

#define search_radius 1 //Search window radius D = 1    2   3
#define block_radius 0.5 //Base Window Radius D = 0.5 0.75 1.0

#define search_window 2 * search_radius + 1 //Search window size
#define minus_search_window2_inv -rcp(search_window * search_window) //Refactor Search Window 

#define h 10 //Control the degree of attenuation of the Gaussian function
#define minus_h2_inv -rcp(h * h * 4) //The number of channels is four
#define noise_mult minus_h2_inv * 500 //Used for precision

float4 CAS(float2 texcoord)
{
	// fetch a Cross neighborhood around the pixel 'C',
	//         Up
	//
	//  Left(Center)Right
	//
	//        Down  
    const float Up = LI(BB(texcoord, float2( 0,-pix.y)).rgb);
    const float Left = LI(BB(texcoord, float2(-pix.x, 0)).rgb);
    const float Center = LI(BB(texcoord, 0).rgb);
    const float Right = LI(BB(texcoord, float2( pix.x, 0)).rgb);
    const float Down = LI(BB(texcoord, float2( 0, pix.y)).rgb);

    const float mnRGB = Min3( Min3(Left, Center, Right), Up, Down);
    const float mxRGB = Max3( Max3(Left, Center, Right), Up, Down);
       
    // Smooth minimum distance to signal limit divided by smooth max.
    const float rcpMRGB = rcp(mxRGB);
	float RGB_D = saturate(min(mnRGB, 1.0 - mxRGB) * rcpMRGB);

	if( CAM_IOB )
		RGB_D = saturate(min(mnRGB, 2.0 - mxRGB) * rcpMRGB);
          
	//Non-Local Mean// - https://blog.csdn.net/panda1234lee/article/details/88016834      
   float sum2;
   const float2 RPC_WS = pix * GT();
   float4 sum1;
	//Traverse the search window
   for(float y = -search_radius; y <= search_radius; ++y)
   {
      for(float x = -search_radius; x <= search_radius; ++x)
      { //Count the sum of the L2 norms of the colors in a search window (the colors in all Base windows
          float dist = 0;
 
		  //Traversing the Base window
          for(float ty = -block_radius; ty <= block_radius; ++ty)
          { 
             for(float tx = -block_radius; tx <= block_radius; ++tx)
             {  //clamping to increase performance & Search window neighborhoods
                const float4 bv = saturate(  BB(texcoord, float2(x + tx, y + ty) * RPC_WS) );
                //Current pixel neighborhood
                const float4 av = saturate(  BB(texcoord, float2(tx, ty) * RPC_WS) );
                
                dist += normaL2(av - bv);
             }
          }
		  //Gaussian weights (calculated from the color distance and pixel distance of all base windows) under a search window
          float window = exp(dist * noise_mult + (pow(x, 2) + pow(y, 2)) * minus_search_window2_inv);
 
          sum1 +=  window * saturate( BB(texcoord, float2(x, y) * RPC_WS) ); //Gaussian weight * pixel value         
          sum2 += window; //Accumulate Gaussian weights for all search windows for normalization
      }
   }
   // Shaping amount of sharpening masked
	float CAS_Mask = RGB_D;

	if(CA_Mask_Boost)
		CAS_Mask = lerp(CAS_Mask,CAS_Mask * CAS_Mask,saturate(Sharpness * 0.5));
		
	if(CA_Removal)
		CAS_Mask = 1;
		
return saturate(float4(sum1.rgb / sum2,CAS_Mask));
}

float3 Sharpen_Out(float2 texcoord)                                                                          
{   const float3 Done = tex2D(BackBuffer,texcoord).rgb;	
	return lerp(Done,Done+(Done - CAS(texcoord).rgb)*(Sharpness*3.1), CAS(texcoord).w * saturate(Sharpness)); //Sharpen Out
}


float3 Out(float4 position : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{	
	const float3 Sharpen = Sharpen_Out(texcoord).rgb,BB = tex2D(BackBuffer,texcoord).rgb;
	float DB = Depth(texcoord).r, DBBL = Depth(float2(texcoord.x*2,texcoord.y*2-1)).r;
	const float DBTL = Depth(float2(texcoord.x*2,texcoord.y*2)).r;

	if(No_Depth_Map)
	{
		DB = 0.0;
		DBBL = 0.0;
	}
	
	if (Debug_View == 0)			
		return lerp(Sharpen, BB, DB);
	else
	{
		const float3 Top_Left = lerp(float3(1.,1.,1.),CAS(float2(texcoord.x*2,texcoord.y*2)).www,1-DBTL);
		
		const float3 Top_Right =  Depth(float2(texcoord.x*2-1,texcoord.y*2)).rrr;		
		
		const float3 Bottom_Left = lerp(float3(1., 0., 1.),tex2D(BackBuffer,float2(texcoord.x*2,texcoord.y*2-1)).rgb,DBBL);	

		const float3 Bottom_Right = CAS(float2(texcoord.x*2-1,texcoord.y*2-1)).rgb;	

		float3 VA_Top;
		if (texcoord.x < 0.5)
			VA_Top = Top_Left;
		else
			VA_Top = Top_Right;
		
		float3 VA_Bottom;
		if (texcoord.x < 0.5)
			VA_Bottom = Bottom_Left;
		else
			VA_Bottom = Bottom_Right;
		
		if (texcoord.y < 0.5)
			return VA_Top;
		else
			return VA_Bottom;
	}
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
technique NLM_Sharp
< ui_tooltip = "建议 : 你可以打开GShade主界面下方的\"性能模式\"\n"
			   "      一旦你设置了你的智能锐化设置，就可以这样做。";ui_label="非局部平均锐化(NLM Sharp)" ;>
{		
			pass UnsharpMask
		{
			VertexShader = PostProcessVS;
			PixelShader = Out;	
		}
}