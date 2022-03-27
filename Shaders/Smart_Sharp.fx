 ////---------------//
 ///**Smart Sharp**///
 //---------------////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Depth Based Unsharp Mask Bilateral Contrast Adaptive Sharpening                                     																										
// For Reshade 3.0+																																					
// --------------------------																																			
// Have fun,																																								
// Jose Negrete AKA BlueSkyDefender																																		
// 																																											
// https://github.com/BlueSkyDefender/Depth3D																	
//  ---------------------------------
//	https://web.stanford.edu/class/cs448f/lectures/2.1/Sharpening.pdf
//																																                                                                                                        																	
// 								Bilateral Filter Made by mrharicot ported over to Reshade by BSD													
//								GitHub Link for sorce info github.com/SableRaf/Filters4Processin																
// 								Shadertoy Link https://www.shadertoy.com/view/4dfGDH  Thank You.
//
//                                     Everyone wants to best the bilateral filter.....                        
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
// Lightly optimized by Marot Satil for the GShade project.
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

// Determines the power of the Bilateral Filter and sharpening quality. Lower the setting the more performance you would get along with lower quality.
// 0 = Off
// 1 = Low
// 2 = Default 
// 3 = Medium
// 4 = High 
// Default is off.
#define M_Quality 0 //Manual Quality Shader Defaults to 2 when set to off.

// It is best to run Smart Sharp after tonemapping.
uniform int Depth_Map <
	ui_type = "combo";
	ui_items = "正常\0反转\0";
	ui_label = "自定义深度映射";
	ui_tooltip = "选择你的深度映射";
	ui_category = "深度缓存";
> = 0;

uniform float Depth_Map_Adjust <
	ui_type = "slider";
	ui_min = 1.0; ui_max = 1000.0; ui_step = 0.125;
	ui_label = "深度映射调整";
	ui_tooltip = "调整深度映射和锐化距离";
	ui_category = "深度缓存";
> = 250.0;

uniform bool Depth_Map_Flip <
	ui_label = "深度映射翻转";
	ui_tooltip = "如果深度映射上下颠倒就翻转它";
	ui_category = "深度缓存";
> = false;

uniform bool No_Depth_Map <
	ui_label = "无深度映射";
	ui_tooltip = "如果你没有深度映射就打开它";
	ui_category = "深度缓存";
> = false;

uniform float Sharpness <
	#if Compatibility
	ui_type = "drag";
	#else
	ui_type = "slider";
	#endif
    ui_label = "锐化强度";
    ui_min = 0.0; ui_max = 1.0;
    ui_tooltip = "通过调整这个滑块从0到1来增加图像的清晰度。0=无锐化，1=完全锐化，超过1=特脆。数字0.625是默认的。";
	ui_category = "双边对比度自适应锐化";
> = 0.625;

uniform bool CAM_IOB <
	ui_label = "对比度自适应遮罩忽略过亮";
	ui_tooltip = "与其在蒙版中允许过亮，不如允许对这个区域进行锐化。我认为打开这个更好。";
	ui_category = "双边对比度自适应锐化";
> = false;

uniform bool CA_Mask_Boost <
	ui_label = "对比度自适应遮罩增强";
	ui_tooltip = "此增强着色器的对比度自适应遮罩部分";
	ui_category = "双边对比度自适应锐化";
> = false;

uniform bool CA_Removal <
	ui_label = "对比度自适应遮罩移除";
	ui_tooltip = "它移除了着色器的对比度自适应遮罩部分\n"
				 "这是为那些喜欢双边锐化的原始样子的人准备的。";
	ui_category = "双边对比度自适应锐化";
> = false;

uniform int B_Grounding <
	ui_type = "combo";
	ui_items = "精细\0中等\0粗糙\0";
	ui_label = "基础类型";
	ui_tooltip = "就像咖啡一样，选择你想要这个着色器有多粗糙。给予双边过滤的更多控制。";
	ui_category = "双边过滤";
> = 0;

uniform bool Slow_Mode <
	ui_label = "对比度自适应锐化慢模式";
	ui_tooltip = "这可以使双边锐化的质量得到释放，是图像模糊量的2倍，代价是游戏帧率。\n如果你想在更高的分辨率下使用这个功能，可以在着色器中把预处理器的M_Quality改为低。\n这个切换只是为了精确。";
	ui_category = "双边过滤";
> = false;

uniform int Debug_View <
	ui_type = "combo";
	ui_items = "正常视角\0锐化Debug\0Z-Buffer Debug\0";
	ui_label = "视角模式";
	ui_tooltip = "这是用来选择正常视图输出或调试视图。\n"
	"用来查看着色器在图像中的变化情况。\n"
	"Normal给你这个着色器的正常输出。\n"
	"锐化是智能锐化的完整调试。\n深度信息是阴影输出。\nZ-Buffer仅为深度缓存。\n"
				 "默认为正常视角";
	ui_category = "Debug";
> = 0;

#define Quality 2

#if M_Quality > 0
	#undef Quality
    #define Quality M_Quality
#endif
/////////////////////////////////////////////////////D3D Starts Here/////////////////////////////////////////////////////////////////
#define pix float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT)

#define SIGMA 10
#define BSIGMA 0.25

#if Quality == 1
	#define MSIZE 3
#endif
#if Quality == 2
	#define MSIZE 5
#endif
#if Quality == 3
	#define MSIZE 7
#endif
#if Quality == 4
	#define MSIZE 9
#endif

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
		
	const float zBuffer = tex2D(DepthBuffer, texcoord).x; //Depth Buffer
	
	//Conversions to linear space.....
	//Near & Far Adjustment
	const float Far = 1.0, Near = 0.125/Depth_Map_Adjust; //Division Depth Map Adjust - Near
	
	const float2 Z = float2( zBuffer, 1-zBuffer );
	
	if (Depth_Map == 0) //DM0. Normal
		return saturate(Far * Near / (Far + Z.x * (Near - Far)));		
	else //DM1. Reverse
		return saturate(Far * Near / (Far + Z.y * (Near - Far)));
}	

float Min3(float x, float y, float z)
{
    return min(x, min(y, z));
}

float Max3(float x, float y, float z)
{
    return max(x, max(y, z));
}

float normpdf3(in float3 v, in float sigma)
{
	return 0.39894*exp(-0.5*dot(v,v)/(sigma*sigma))/sigma;
}

float3 BB(in float2 texcoord, float2 AD)
{
	return tex2Dlod(BackBuffer, float4(texcoord + AD,0,0)).rgb;
}

float LI(float3 RGB)
{
	return dot(RGB,float3(0.2126, 0.7152, 0.0722));
}

float GT()
{
if (B_Grounding == 2)
	return 1.5;
else if(B_Grounding == 1)
	return 1.25;
else
	return 1.0;
}

float4 CAS(float2 texcoord)
{
	// fetch a Cross neighborhood around the pixel 'C',
	//         Up
	//
	//  Left(Center)Right
	//
	//        Down  
    const float Up = LI(BB(texcoord, float2( 0,-pix.y)));
    const float Left = LI(BB(texcoord, float2(-pix.x, 0)));
    const float Center = LI(BB(texcoord, 0));
    const float Right = LI(BB(texcoord, float2( pix.x, 0)));
    const float Down = LI(BB(texcoord, float2( 0, pix.y)));

    const float mnRGB = Min3( Min3(Left, Center, Right), Up, Down);
    const float mxRGB = Max3( Max3(Left, Center, Right), Up, Down);
       
    // Smooth minimum distance to signal limit divided by smooth max.
    const float rcpMRGB = rcp(mxRGB);
	float RGB_D = saturate(min(mnRGB, 1.0 - mxRGB) * rcpMRGB);

	if( CAM_IOB )
		RGB_D = saturate(min(mnRGB, 2.0 - mxRGB) * rcpMRGB);
          
	//Bilateral Filter//                                                Q1         Q2       Q3        Q4                                                                                          
	const int kSize = MSIZE * 0.5; // Default M-size is Quality 2 so [MSIZE 3] [MSIZE 5] [MSIZE 7] [MSIZE 9] / 2.
														
//													1			2			3			4				5			6			7			8				7			6			5				4			3			2			1
//Full Kernal Size would be 15 as shown here (0.031225216, 0.03332227	1, 0.035206333, 0.036826804, 0.038138565, 0.039104044, 0.039695028, 0.039894000, 0.039695028, 0.039104044, 0.038138565, 0.036826804, 0.035206333, 0.033322271, 0.031225216)
/*#if Quality == 1
	const float weight[MSIZE] = {0.031225216, 0.039894000, 0.031225216}; // by 3
#endif
#if Quality == 2
	const float weight[MSIZE] = {0.031225216, 0.036826804, 0.039894000, 0.036826804, 0.031225216};  // by 5
#endif	
#if Quality == 3
	const float weight[MSIZE] = {0.031225216, 0.035206333, 0.039104044, 0.039894000, 0.039104044, 0.035206333, 0.031225216};   // by 7
#endif
#if Quality == 4
	const float weight[MSIZE] = {0.031225216, 0.035206333, 0.038138565, 0.039695028, 0.039894000, 0.039695028, 0.038138565, 0.035206333, 0.031225216};  // by 9
#endif*/
	
	float3 final_colour, c = BB(texcoord.xy,0), cc;
	const float2 RPC_WS = pix * GT();
	float Z, factor;
	
	[loop]
	for (int i=-kSize; i <= kSize; ++i)
	{	
	if(Slow_Mode)
		{
			for (int j=-kSize; j <= kSize; ++j)
			{
				cc = BB(texcoord.xy, float2(i,j) * RPC_WS * rcp(kSize) );
				factor = normpdf3(cc-c, BSIGMA);
				Z += factor;
				final_colour += factor * cc;
			}
		}
		else
		{		
			cc = BB(texcoord.xy, float2( i, 1 - (i * i) * 0.5 ) * RPC_WS * rcp(kSize) );
			factor = normpdf3(cc-c, BSIGMA);
			Z += factor;
			final_colour += factor * cc;
		}
	}
	
	//// Shaping amount of sharpening masked	
	float CAS_Mask = RGB_D;

	if(CA_Mask_Boost)
		CAS_Mask = lerp(CAS_Mask,CAS_Mask * CAS_Mask,saturate(Sharpness * 0.5));
		
	if(CA_Removal)
		CAS_Mask = 1;
		
return saturate(float4(final_colour/Z,CAS_Mask));
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
	{			
		return lerp(Sharpen, BB, DB);
	}
	else if (Debug_View == 1)
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
	else
		return Depth(texcoord);
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
technique Smart_Sharp
< ui_tooltip = "建议:你可以在ReShade主界面的下方启用\"性能模式\"。当然，一旦你设置了你的智能锐化设置，就可以这样做。";ui_label="智能锐化"; >
{		
			pass UnsharpMask
		{
			VertexShader = PostProcessVS;
			PixelShader = Out;	
		}
}