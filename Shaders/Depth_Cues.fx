 ////---------------//
 ///**Depth Cues**///
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
//                                                       Depth Cues
//                                Extra Information for where I got the Idea for Depth Cues.
//                             https://www.uni-konstanz.de/mmsp/pubsys/publishedFiles/LuCoDe06.pdf	
//																
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Translation of the UI into Chinese by Lilidream.

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

//Automatic Blur Adjustment based on Resolutionsup to 8k considered.
#if (BUFFER_HEIGHT <= 720)
	#define Multi 0.5
#elif (BUFFER_HEIGHT <= 1080)
	#define Multi 1.0
#elif (BUFFER_HEIGHT <= 1440)
	#define Multi 1.5
#elif (BUFFER_HEIGHT <= 2160)
	#define Multi 2
#else
	#define Quality 2.5
#endif

// It is best to run Smart Sharp after tonemapping.

uniform int Depth_Map <
	ui_type = "combo";
	ui_items = "正常\0反转\0";
	ui_label = "定制深度映射";
	ui_tooltip = "选择你的深度映射";
	ui_category = "深度缓存";
> = 0;

uniform float Depth_Map_Adjust <
	ui_type = "slider";
	ui_min = 1.0; ui_max = 1000.0; ui_step = 0.125;
	ui_label = "深度映射调整";
	ui_tooltip = "调整深度映射并锐化距离";
	ui_category = "深度缓存";
> = 250.0;

uniform bool Depth_Map_Flip <
	ui_label = "反转深度映射";
	ui_tooltip = "如果深度距离颠倒则反转它";
	ui_category = "深度缓存";
> = false;

uniform bool DEPTH_DEBUG <
	ui_label = "查看深度";
	ui_tooltip = "查看深度，近的物体为黑色，远的物体为白色。";
	ui_category = "深度缓存";	
> = false;

uniform bool No_Depth_Map <
	ui_label = "无深度映射";
	ui_tooltip = "如果你没有深度缓存就打开这个。";
	ui_category = "深度缓存";
> = false;

uniform float Shade_Power <	
	ui_type = "slider";
	ui_min = 0.25; ui_max = 1.0;	
	ui_label = "阴影强度";	
	ui_tooltip = "调整阴影强度来改进游戏中环境光遮蔽、阴影与暗部的区域。\n"	
				 "默认为0.625";
	ui_category = "深度特征";
> = 0.625;

uniform float Blur_Cues <	
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;	
	ui_label = "模糊阴影";	
	ui_tooltip = "使画面中阴影更柔和\n"	
				 "默认值为0.5";
	ui_category = "深度特征";
> = 0.5;

uniform float Spread <
	ui_type = "slider";
	ui_min = 1.0; ui_max = 25.0; ui_step = 0.25;
	ui_label = "阴影填充";
	ui_tooltip = "通过填充阴影来创造假环境光遮蔽效果。\n"
				 "用于间隙填充。\n"
				 "默认为7.5";
	ui_category = "深度特征";
> = 12.5;

uniform bool Debug_View <
	ui_label = "深度特征 Debug";
	ui_tooltip = "深度特征 Debug输出着色器输出";
	ui_category = "深度特征";
> = false;
/*
uniform bool Fake_AO <
	ui_label = "Fake AO";
	ui_tooltip = "Fake AO only works when you Have Depth Buffer Access.";
	ui_category = "Fake AO";
> = false;

uniform float Fake_AO_Adjust <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 0.5;
	ui_label = "Fake AO Adjustment";
	ui_tooltip = "Adjust the depth map so Fake AO can work better.";
	ui_category = "Fake AO";
> = 0.1;
*/
/////////////////////////////////////////////////////D3D Starts Here/////////////////////////////////////////////////////////////////
#define pix float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT)
#define BlurSamples 12 //BlurSamples = # * 2
#define S_Power Spread * Multi
#define M_Power Blur_Cues * Multi

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
			
texture texHB { Width = BUFFER_WIDTH  * 0.5 ; Height = BUFFER_HEIGHT * 0.5 ; Format = R8; MipLevels = 1;};

sampler SamplerHB
	{
			Texture = texHB;
	};
	
texture texDC { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = R8; MipLevels = 3;};

sampler SamplerDC
	{
			Texture = texDC;
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

float3 BB(in float2 texcoord, float2 AD)
{
	/*
	if(Fake_AO)
		return 1-(1 - Fake_AO_Adjust/Depth(texcoord + AD).xxx);
	else
	*/
		return tex2Dlod(BackBuffer, float4(texcoord + AD,0,0)).rgb;
}

float H_Blur(float4 position : SV_Position, float2 texcoord : TEXCOORD) : SV_Target                                                                          
{
	const float S = S_Power * 0.125;
	
	float3 sum = BB(texcoord,0).rgb * BlurSamples;
    
    float total = BlurSamples;
    
    for ( int j = -BlurSamples; j <= BlurSamples; ++j)
    {
        float W = BlurSamples;
        
		sum += BB(texcoord , + float2(pix.x * S,0) * j ) * W;

        total += W;
    }
	return dot(sum / total, float3(0.2126, 0.7152, 0.0722) ); // Get it  Total sum..... :D				
}

// Spread the blur a bit more. 
float DepthCues(float2 texcoord) 
{	
		float2 S = S_Power * 0.75f * pix;

		const float M_Cues = 1;
		float result = tex2Dlod(SamplerHB,float4(texcoord,0,M_Cues)).x;
		result += tex2Dlod(SamplerHB,float4(texcoord + float2( 1, 0) * S ,0,M_Cues)).x;
		result += tex2Dlod(SamplerHB,float4(texcoord + float2( 0, 1) * S ,0,M_Cues)).x;
		result += tex2Dlod(SamplerHB,float4(texcoord + float2(-1, 0) * S ,0,M_Cues)).x;
		result += tex2Dlod(SamplerHB,float4(texcoord + float2( 0,-1) * S ,0,M_Cues)).x;
		S *= 0.5;
		result += tex2Dlod(SamplerHB,float4(texcoord + float2( 1, 0) * S ,0,M_Cues)).x;
		result += tex2Dlod(SamplerHB,float4(texcoord + float2( 0, 1) * S ,0,M_Cues)).x;
		result += tex2Dlod(SamplerHB,float4(texcoord + float2(-1, 0) * S ,0,M_Cues)).x;
		result += tex2Dlod(SamplerHB,float4(texcoord + float2( 0,-1) * S ,0,M_Cues)).x;
		result *= rcp(9);
	
	// Formula for Image Pop = Original + (Original / Blurred).
	const float DC = (dot(BB(texcoord,0),float3(0.2126, 0.7152, 0.0722)) / result );
return lerp(1.0f,saturate(DC),Shade_Power);
}

float DC(float4 position : SV_Position, float2 texcoord : TEXCOORD) : SV_Target                                                                          
{
	return DepthCues(texcoord); // Get it  Total sum..... :D				
}

float3 Out(float4 position : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{	
	const float DCB = tex2Dlod(SamplerDC,float4(texcoord,0,M_Power)).x;
	const float3 DC = DCB.xxx , BBN = tex2D(BackBuffer,texcoord).rgb;
	float DB = Depth(texcoord).r;
	
	if(No_Depth_Map)
	{
		DB = 0.0;
	}
	
	if (Debug_View)
		return lerp(DC,1., DB);
	
	if (DEPTH_DEBUG)
		return DB;

#if GSHADE_DITHER
	const float3 outcolor = BBN * lerp(DC,1., DB);
	return outcolor + TriDither(outcolor, texcoord, BUFFER_COLOR_BIT_DEPTH);
#else
	return BBN * lerp(DC,1., DB);
#endif
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
technique Monocular_Cues <ui_label="单眼深度特征";ui_tooltip="基于深度的反遮罩锐化 双边对比度自适应锐化";>
{		

			pass Blur
		{
			VertexShader = PostProcessVS;
			PixelShader = H_Blur;
			RenderTarget = texHB;
		}
			pass BlurDC
		{
			VertexShader = PostProcessVS;
			PixelShader = DC;
			RenderTarget = texDC;
		}
			pass UnsharpMask
		{
			VertexShader = PostProcessVS;
			PixelShader = Out;	
		}
}