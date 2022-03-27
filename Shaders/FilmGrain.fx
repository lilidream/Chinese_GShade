/**
 * FilmGrain version 1.0
 * by Christian Cann Schuldt Jensen ~ CeeJay.dk
 *
 * Computes a noise pattern and blends it with the image to create a film grain look.
 */
 // Translation of the UI into Chinese by Lilidream.

uniform float Intensity <
	ui_label = "强度";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_tooltip = "效果的透明度。";
> = 0.50;
uniform float Variance <
	ui_label = "变化";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_tooltip = "控制高斯噪音的变化，较小的值会更柔和";
> = 0.40;
uniform float Mean <
	ui_label = "均值";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_tooltip = "影响噪点亮度";
> = 0.5;

uniform int SignalToNoiseRatio <
	ui_label = "信噪比";
	ui_type = "slider";
	ui_min = 0; ui_max = 16;
	ui_tooltip = "高信噪比使亮的像素得到更少噪点。0则禁用功能。";
> = 6;

uniform float Timer < source = "timer"; >;

#include "ReShade.fxh"

float3 FilmGrainPass(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;

	const float inv_luma = dot(color, float3(-1.0/3.0, -1.0/3.0, -1.0/3.0)) + 1.0; //Calculate the inverted luma so it can be used later to control the variance of the grain
  
	/*---------------------.
	| :: Generate Grain :: |
	'---------------------*/

	const float PI = 3.1415927;
	
	//time counter using requested counter from ReShade
	const float t = Timer * 0.0022337;
	
	//PRNG 2D - create two uniform noise values and save one DP2ADD
	const float seed = dot(texcoord, float2(12.9898, 78.233));// + t;
	const float sine = sin(seed);
	const float cosine = cos(seed);
	float uniform_noise1 = frac(sine * 43758.5453 + t); //I just salt with t because I can
	const float uniform_noise2 = frac(cosine * 53758.5453 - t); // and it doesn't cost any extra ASM

	//Get settings
	float stn;
	if (SignalToNoiseRatio != 0)
		stn = pow(abs(inv_luma), (float)SignalToNoiseRatio);
	else
		stn = 1.0;
	const float variance = (Variance*Variance) * stn;
	const float mean = Mean;

	//Box-Muller transform
	if (uniform_noise1 < 0.0001)
		uniform_noise1 = 0.0001; //fix log(0)
		
	float r = sqrt(-log(uniform_noise1));
	if (uniform_noise1 < 0.0001)
		r = PI; //fix log(0) - PI happened to be the right answer for uniform_noise == ~ 0.0000517.. Close enough and we can reuse a constant.
	const float theta = (2.0 * PI) * uniform_noise2;
	
	const float gauss_noise1 = variance * r * cos(theta) + mean;

	//Calculate how big the shift should be
	const float grain = lerp(1.0 + Intensity,  1.0 - Intensity, gauss_noise1);
  
	//float grain2 = (2.0 * Intensity) * gauss_noise1 + (1.0 - Intensity);
	 
	//Apply grain
	color = color * grain;
  
	//color = (grain-1.0) *2.0 + 0.5;
  
	//color = lerp(color,colorInput.rgb,sqrt(luma));

	/*-------------------------.
	| :: Debugging features :: |
	'-------------------------*/

	//color.rgb = frac(gauss_noise1).xxx; //show the noise
	//color.rgb = (gauss_noise1 > 0.999) ? float3(1.0,1.0,0.0) : 0.0 ; //does it reach 1.0?
	
	return color.rgb;
}

technique FilmGrain <ui_label = "电影颗粒";>
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = FilmGrainPass;
	}
}
