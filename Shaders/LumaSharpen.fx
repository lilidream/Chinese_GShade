/**
   LumaSharpen version 1.5.0
   by Christian Cann Schuldt Jensen ~ CeeJay.dk
  
   It blurs the original pixel with the surrounding pixels and then subtracts this blur to sharpen the image.
   It does this in luma to avoid color artifacts and allows limiting the maximum sharpning to avoid or lessen halo artifacts.
   This is similar to using Unsharp Mask in Photoshop.

   Version 1.5.1
  - UI improvements for Reshade 3.x
 */
 // Lightly optimized by Marot Satil for the GShade project.
 // Translation of the UI into Chinese by Lilidream.

uniform float sharp_strength <
	ui_type = "slider";
	ui_min = 0.1; ui_max = 3.0;
	ui_label = "锐化强度";
	ui_tooltip = "锐化的强度";

> = 0.65;
uniform float sharp_clamp <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0; ui_step = 0.005;
	ui_label = "锐化限制";
	ui_tooltip = "限制每个像素接收到的最大锐化数量\n这有助于避免出现\"光晕\"伪影，否则，当你把强度提高得太多时，就会出现光晕现象。";
> = 0.035;
uniform int pattern <
	ui_type = "combo";
	ui_items =	"快速" "\0"
				"正常" "\0"
				"宽幅"	"\0"
				"金字塔形" "\0";
	ui_label = "采样图案";
	ui_tooltip = "选择采样图案\n"
	"快速是更快，但质量稍差。\n正常是正常的。\n宽幅对噪声不那么敏感，但也对精细的细节敏感。\n金字塔有一个略微更激进的外观。";
> = 1;
uniform float offset_bias <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 6.0;
	ui_label = "偏移偏离";
	ui_tooltip = "偏移偏置调整了采样模式的半径。我设计的模式的偏移偏差为1.0，但可以自由地进行试验。";
> = 1.0;
uniform bool show_sharpen <
	ui_label = "显示锐化图案";
	ui_tooltip = "显示锐化的强度。\n有助于看到那些区域被锐化得最强。";
> = false;

#include "ReShade.fxh"

   /*-----------------------------------------------------------.
  /                      Developer settings                     /
  '-----------------------------------------------------------*/
#define CoefLuma float3(0.2126, 0.7152, 0.0722)      // BT.709 & sRBG luma coefficient (Monitors and HD Television)
//#define CoefLuma float3(0.299, 0.587, 0.114)       // BT.601 luma coefficient (SD Television)
//#define CoefLuma float3(1.0/3.0, 1.0/3.0, 1.0/3.0) // Equal weight coefficient

   /*-----------------------------------------------------------.
  /                          Main code                          /
  '-----------------------------------------------------------*/

float3 LumaSharpenPass(float4 position : SV_Position, float2 tex : TEXCOORD) : SV_Target
{
	// -- Get the original pixel --
	const float3 ori = tex2D(ReShade::BackBuffer, tex).rgb; // ori = original pixel

	// -- Combining the strength and luma multipliers --
	float3 sharp_strength_luma = (CoefLuma * sharp_strength); //I'll be combining even more multipliers with it later on

	/*-----------------------------------------------------------.
	/                       Sampling patterns                     /
	'-----------------------------------------------------------*/
	float3 blur_ori;

	//   [ NW,   , NE ] Each texture lookup (except ori)
	//   [   ,ori,    ] samples 4 pixels
	//   [ SW,   , SE ]

	// -- Pattern 1 -- A (fast) 7 tap gaussian using only 2+1 texture fetches.
	if (pattern == 0)
	{
		// -- Gaussian filter --
		//   [ 1/9, 2/9,    ]     [ 1 , 2 ,   ]
		//   [ 2/9, 8/9, 2/9]  =  [ 2 , 8 , 2 ]
		//   [    , 2/9, 1/9]     [   , 2 , 1 ]

		blur_ori  = tex2D(ReShade::BackBuffer, tex + (BUFFER_PIXEL_SIZE / 3.0) * offset_bias).rgb;  // North West
		blur_ori += tex2D(ReShade::BackBuffer, tex + (-BUFFER_PIXEL_SIZE / 3.0) * offset_bias).rgb; // South East

		//blur_ori += tex2D(ReShade::BackBuffer, tex + (BUFFER_PIXEL_SIZE / 3.0) * offset_bias); // North East
		//blur_ori += tex2D(ReShade::BackBuffer, tex + (-BUFFER_PIXEL_SIZE / 3.0) * offset_bias); // South West

		blur_ori /= 2;  //Divide by the number of texture fetches

		sharp_strength_luma *= 1.5; // Adjust strength to aproximate the strength of pattern 2
	}

	// -- Pattern 2 -- A 9 tap gaussian using 4+1 texture fetches.
	if (pattern == 1)
	{
		// -- Gaussian filter --
		//   [ .25, .50, .25]     [ 1 , 2 , 1 ]
		//   [ .50,   1, .50]  =  [ 2 , 4 , 2 ]
		//   [ .25, .50, .25]     [ 1 , 2 , 1 ]

		blur_ori  = tex2D(ReShade::BackBuffer, tex + float2(BUFFER_PIXEL_SIZE.x, -BUFFER_PIXEL_SIZE.y) * 0.5 * offset_bias).rgb; // South East
		blur_ori += tex2D(ReShade::BackBuffer, tex - BUFFER_PIXEL_SIZE * 0.5 * offset_bias).rgb;  // South West
		blur_ori += tex2D(ReShade::BackBuffer, tex + BUFFER_PIXEL_SIZE * 0.5 * offset_bias).rgb; // North East
		blur_ori += tex2D(ReShade::BackBuffer, tex - float2(BUFFER_PIXEL_SIZE.x, -BUFFER_PIXEL_SIZE.y) * 0.5 * offset_bias).rgb; // North West

		blur_ori *= 0.25;  // ( /= 4) Divide by the number of texture fetches
	}

	// -- Pattern 3 -- An experimental 17 tap gaussian using 4+1 texture fetches.
	if (pattern == 2)
	{
		// -- Gaussian filter --
		//   [   , 4 , 6 ,   ,   ]
		//   [   ,16 ,24 ,16 , 4 ]
		//   [ 6 ,24 ,   ,24 , 6 ]
		//   [ 4 ,16 ,24 ,16 ,   ]
		//   [   ,   , 6 , 4 ,   ]

		blur_ori  = tex2D(ReShade::BackBuffer, tex + BUFFER_PIXEL_SIZE * float2(0.4, -1.2) * offset_bias).rgb;  // South South East
		blur_ori += tex2D(ReShade::BackBuffer, tex - BUFFER_PIXEL_SIZE * float2(1.2, 0.4) * offset_bias).rgb; // West South West
		blur_ori += tex2D(ReShade::BackBuffer, tex + BUFFER_PIXEL_SIZE * float2(1.2, 0.4) * offset_bias).rgb; // East North East
		blur_ori += tex2D(ReShade::BackBuffer, tex - BUFFER_PIXEL_SIZE * float2(0.4, -1.2) * offset_bias).rgb; // North North West

		blur_ori *= 0.25;  // ( /= 4) Divide by the number of texture fetches

		sharp_strength_luma *= 0.51;
	}

	// -- Pattern 4 -- A 9 tap high pass (pyramid filter) using 4+1 texture fetches.
	if (pattern == 3)
	{
		// -- Gaussian filter --
		//   [ .50, .50, .50]     [ 1 , 1 , 1 ]
		//   [ .50,    , .50]  =  [ 1 ,   , 1 ]
		//   [ .50, .50, .50]     [ 1 , 1 , 1 ]

		blur_ori  = tex2D(ReShade::BackBuffer, tex + float2(0.5 * BUFFER_PIXEL_SIZE.x, -BUFFER_PIXEL_SIZE.y * offset_bias)).rgb;  // South South East
		blur_ori += tex2D(ReShade::BackBuffer, tex + float2(offset_bias * -BUFFER_PIXEL_SIZE.x, 0.5 * -BUFFER_PIXEL_SIZE.y)).rgb; // West South West
		blur_ori += tex2D(ReShade::BackBuffer, tex + float2(offset_bias * BUFFER_PIXEL_SIZE.x, 0.5 * BUFFER_PIXEL_SIZE.y)).rgb; // East North East
		blur_ori += tex2D(ReShade::BackBuffer, tex + float2(0.5 * -BUFFER_PIXEL_SIZE.x, BUFFER_PIXEL_SIZE.y * offset_bias)).rgb; // North North West

		//blur_ori += (2 * ori); // Probably not needed. Only serves to lessen the effect.

		blur_ori /= 4.0;  //Divide by the number of texture fetches

		sharp_strength_luma *= 0.666; // Adjust strength to aproximate the strength of pattern 2
	}

	 /*-----------------------------------------------------------.
	/                            Sharpen                          /
	'-----------------------------------------------------------*/

	// -- Calculate the sharpening --
	const float3 sharp = ori - blur_ori;  //Subtracting the blurred image from the original image

#if 0 //older 1.4 code (included here because the new code while faster can be difficult to understand)
	// -- Adjust strength of the sharpening --
	float sharp_luma = dot(sharp, sharp_strength_luma); //Calculate the luma and adjust the strength

	// -- Clamping the maximum amount of sharpening to prevent halo artifacts --
	sharp_luma = clamp(sharp_luma, -sharp_clamp, sharp_clamp);  //TODO Try a curve function instead of a clamp

#else //new code
	// -- Adjust strength of the sharpening and clamp it--
	const float4 sharp_strength_luma_clamp = float4(sharp_strength_luma * (0.5 / sharp_clamp),0.5); //Roll part of the clamp into the dot

	//sharp_luma = saturate((0.5 / sharp_clamp) * sharp_luma + 0.5); //scale up and clamp
	float sharp_luma = saturate(dot(float4(sharp,1.0), sharp_strength_luma_clamp)); //Calculate the luma, adjust the strength, scale up and clamp
	sharp_luma = (sharp_clamp * 2.0) * sharp_luma - sharp_clamp; //scale down
#endif

	// -- Combining the values to get the final sharpened pixel	--
	float3 outputcolor = ori + sharp_luma;    // Add the sharpening to the the original.

	 /*-----------------------------------------------------------.
	/                     Returning the output                    /
	'-----------------------------------------------------------*/

	if (show_sharpen)
	{
		//outputcolor = abs(sharp * 4.0);
		outputcolor = saturate(0.5 + (sharp_luma * 4.0)).rrr;
	}

	return saturate(outputcolor);
}

technique LumaSharpen <ui_label="亮度锐化";>
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = LumaSharpenPass;
	}
}
