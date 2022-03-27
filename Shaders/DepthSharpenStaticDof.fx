/**
 * DepthSharpenconstDof v1.11
 * by OVNI
 *
 * Based on :
 * LumaSharpen version 1.5.0
 * by Christian Cann Schuldt Jensen ~ CeeJay.dk
 *
 * It blurs the original pixel with the surrounding pixels and then subtracts this blur to sharpen the image.
 * It does this in luma to avoid color artifacts and allows limiting the maximum sharpning to avoid or lessen halo artifacts.
 * This is similar to using Unsharp Mask in Photoshop.
 *
 * OVNI modifications :
 * - depth test for sharpening so it doesn't generate too much aliasing
 * - reuse blur do implement poor man's const DoF
 * - reuse blur do implement poor man's antialiasing between objects (trees) and sky
 */
 // Lightly optimized by Marot Satil for the GShade project.
 // Translation of the UI into Chinese by Lilidream.

uniform float sharp_strength <
	ui_type = "slider";
	ui_label = "锐化强度";
	ui_min = 0.1; ui_max = 10.0;
	ui_tooltip = "锐化的强度";
> = 3.0;

uniform float sharp_clamp <
	ui_type = "slider";
	ui_label = "锐化限制";
	ui_min = 0.0; ui_max = 1.0; ui_step = 0.005;
	ui_tooltip = "限制一个像素接受到的最大锐化数量。";
> = 0.035;

uniform int pattern <
	ui_type = "combo";
	ui_label = "采样图案";
	ui_items = "Fast\0Normal\0Wider\0Pyramid shaped\0";
	ui_tooltip = "选择采样图案";
> = 2;

uniform float offset_bias <
	ui_type = "slider";
	ui_label = "偏移";
	ui_min = 0.0; ui_max = 6.0;
	ui_tooltip = "偏移调整采样类型的半径。我设计了采样图案为1.0, 但你可以随意尝试其他的值。";
> = 1.0;

uniform bool debug <
	ui_tooltip = "Debug view.";
	ui_tooltip = "Debug视角";
> = false;

uniform float sharpenEndDepth <
	ui_type = "slider";
	ui_label = "锐化结束深度";
	ui_min = 0.0; ui_max = 1.0;
	ui_tooltip = "锐化的最大深度";
> = 0.3;

uniform float sharpenMaxDeltaDepth <
	ui_label = "锐化最大Delta深度";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_tooltip = "应用于滤镜的两个采样的最大深度差值。";
> = 0.0025;

uniform float dofStartDepth <
	ui_label = "景深开始深度";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_tooltip = "景深效果的最小深度";
> = 0.7;

uniform float dofTransitionDepth <
	ui_label = "景深变化深度";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_tooltip = "不模糊与全模糊之间的插值距离。";
> = 0.3;

uniform float contourBlurMinDeltaDepth <
	ui_label = "最小模糊Delta深度";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_tooltip = "应用于模糊效果的两个采样之间的最小差值。";
> = 0.05;

uniform float contourDepthExponent <
	ui_label = "外形深度幂";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 4.0;
	ui_tooltip = "影响外形模糊的分布(高的值会减少近处物体的外形模糊)";
> = 2.0;


//Used to avoid bluring the sky (espetially stars/moon) and some UI parts, This should be as high as possible.
uniform float maxDepth <ui_label="最大深度";ui_tooltip="用于避免模糊天空与一些UI";> = 0.999;


#include "ReShade.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

   /*-----------------------------------------------------------.
  /                      Developer settings                     /
  '-----------------------------------------------------------*/
#define CoefLuma float3(0.2126, 0.7152, 0.0722)      // BT.709 & sRBG luma coefficient (Monitors and HD Television)
//#define CoefLuma float3(0.299, 0.587, 0.114)       // BT.601 luma coefficient (SD Television)
//#define CoefLuma float3(1.0/3.0, 1.0/3.0, 1.0/3.0) // Equal weight coefficient

   /*-----------------------------------------------------------.
  /                          Main code                          /
  '-----------------------------------------------------------*/

float3 DepthSharpenconstDofPass(float4 position : SV_Position, float2 tex : TEXCOORD) : SV_Target
{
	// -- Get the original pixel --
	const float3 ori = tex2D(ReShade::BackBuffer, tex).rgb;

	/*-----------------------------------------------------------.
	/      Determine if we should sharpen / blur
	'-----------------------------------------------------------*/

	const float depth = ReShade::GetLinearizedDepth(tex).r;

	if( depth > maxDepth )
		return ori;

	const float depthTL = ReShade::GetLinearizedDepth( tex + float2(-BUFFER_PIXEL_SIZE.x, -BUFFER_PIXEL_SIZE.y) ).r;
	const float depthTR = ReShade::GetLinearizedDepth( tex + float2(BUFFER_PIXEL_SIZE.x, -BUFFER_PIXEL_SIZE.y) ).r;
	const float deltaA = abs(depth-depthTL);
	const float deltaB = abs(depth-depthTR);
	float blurPercent = 0;
	bool bluredEdge = false;
	const bool shouldSharpen = depth < sharpenEndDepth && deltaA <= sharpenMaxDeltaDepth && deltaB <= sharpenMaxDeltaDepth;


	if( deltaA >= contourBlurMinDeltaDepth || deltaB >= contourBlurMinDeltaDepth )
	{
		blurPercent = saturate( (deltaA+deltaB)/2.0 * 10 ) * pow(abs(depth), contourDepthExponent);
		bluredEdge = true;
	}
	else 
		blurPercent = (depth - dofStartDepth)/dofTransitionDepth;

	if( blurPercent <= 0 && !shouldSharpen )
		if (debug)
			return float3(0,1,0)*ori;
		else
			return ori;

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

		blur_ori /= 4.0;  //Divide by the number of texture fetches

		sharp_strength_luma *= 0.666; // Adjust strength to aproximate the strength of pattern 2
	}

	/*-----------------------------------------------------------.
	/
	'-----------------------------------------------------------*/

	// Apply blur if needed
	if( blurPercent > 0 )
	{
		blurPercent = saturate(blurPercent);
		if( debug )
			if (bluredEdge)
				return blurPercent * float3(0,0,1);
			else
				return blurPercent * float3(1,0,0);

		return blur_ori*blurPercent + ori*(1.0-blurPercent);
	}

	// Modify sharping Strength depending of depth
	if( sharpenEndDepth < 1.0 )
		sharp_strength_luma *= 1.0 - depth/sharpenEndDepth; // depth reranged in [0,sharpenEndDepth]

	/*-----------------------------------------------------------.
	/                            Sharpen                          /
	'-----------------------------------------------------------*/

	// -- Calculate the sharpening --
	const float3 sharp = ori - blur_ori;  //Subtracting the blurred image from the original image

	// -- Adjust strength of the sharpening and clamp it--
	const float4 sharp_strength_luma_clamp = float4(sharp_strength_luma * (0.5 / sharp_clamp),0.5); //Roll part of the clamp into the dot

	float sharp_luma = saturate(dot(float4(sharp,1.0), sharp_strength_luma_clamp)); //Calculate the luma, adjust the strength, scale up and clamp
	sharp_luma = (sharp_clamp * 2.0) * sharp_luma - sharp_clamp; //scale down

	/*-----------------------------------------------------------.
	/                     Returning the output                    /
	'-----------------------------------------------------------*/

	if (debug)
		return saturate(0.5 + (sharp_luma * 4.0)).rrr;

	// -- Combining the values to get the final sharpened pixel	--
#if GSHADE_DITHER
	const float3 outcolor = ori + sharp_luma;
	return outcolor + TriDither(outcolor, tex, BUFFER_COLOR_BIT_DEPTH);
#else
	return ori + sharp_luma;    // Add the sharpening to the the original.
#endif
}

technique DepthSharpenconstDof <ui_label="深度锐化+静态景深";>
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = DepthSharpenconstDofPass;
	}
}
