/** Aspect Ratio PS, version 1.1.1
by Fubax 2019 for ReShade
Translation of the UI into Chinese by Lilidream.
*/

uniform float A <
	ui_type = "slider";
	ui_label = "比例";
	ui_category = "纵横比";
	ui_min = -1.0; ui_max = 1.0;
> = 0.0;

uniform float Zoom <
	ui_type = "slider";
	ui_label = "缩放画面";
	ui_category = "纵横比";
	ui_min = 1.0; ui_max = 1.5;
> = 1.0;

uniform bool FitScreen <
	ui_label = "缩放画面至填满边缘";
	ui_category = "边框";
> = true;

uniform bool UseBackground <
	ui_label = "使用背景图片";
	ui_category = "边框";
> = true;

uniform float4 Color <
	ui_type = "color";
	ui_label = "背景颜色";
	ui_category = "边框";
> = float4(0.027, 0.027, 0.027, 0.17);

#include "ReShade.fxh"

	  //////////////
	 /// SHADER ///
	//////////////

texture AspectBgTex < source = "AspectRatio.jpg"; > { Width = 1351; Height = 1013; };
sampler AspectBgSampler { Texture = AspectBgTex; };

float3 AspectRatioPS(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	bool Mask = false;

	// Center coordinates
	float2 coord = texcoord-0.5;

	// if (Zoom != 1.0) coord /= Zoom;
	if (Zoom != 1.0) coord /= clamp(Zoom, 1.0, 1.5); // Anti-cheat

	// Squeeze horizontally
	if (A<0)
	{
		coord.x *= abs(A)+1.0; // Apply distortion

		// Scale to borders
		if (FitScreen) coord /= abs(A)+1.0;
		else // Mask image borders
			Mask = abs(coord.x)>0.5;
	}
	// Squeeze vertically
	else if (A>0)
	{
		coord.y *= A+1.0; // Apply distortion

		// Scale to borders
		if (FitScreen) coord /= abs(A)+1.0;
		else // Mask image borders
			Mask = abs(coord.y)>0.5;
	}
	
	// Coordinates back to the corner
	coord += 0.5;

	// Sample display image and return
	if (UseBackground && !FitScreen) // If borders are visible
		if (Mask)
			return lerp( tex2D(AspectBgSampler, texcoord).rgb, Color.rgb, Color.a );
		else
			return tex2D(ReShade::BackBuffer, coord).rgb;
	else
		if (Mask)
			return Color.rgb;
		else
			return tex2D(ReShade::BackBuffer, coord).rgb;
}


	  ///////////////
	 /// DISPLAY ///
	///////////////

technique AspectRatioPS
<
	ui_label = "画面纵横比";
	ui_tooltip = "校正画面纵横比";
>
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = AspectRatioPS;
	}
}
