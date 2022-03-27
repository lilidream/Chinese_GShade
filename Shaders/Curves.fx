/**
 * Curves
 * by Christian Cann Schuldt Jensen ~ CeeJay.dk
 *
 * Curves, uses S-curves to increase contrast, without clipping highlights and shadows.
 */
 // Lightly optimized by Marot Satil for the GShade project.
// Translation of the UI into Chinese by Lilidream.

uniform int Mode <
	ui_text = "在不丢失高光和阴影的同时，使用S型曲线增加对比度";
	ui_label = "模式";
	ui_type = "combo";
	ui_items = "亮度\0色度\0亮度与色度\0";
	ui_tooltip = "选择应用对比度的模式";
> = 0;
uniform int Formula <
	ui_label = "公式";
	ui_type = "combo";
	ui_items = "正弦\0绝对值分隔\0平滑阶梯\0指数公式\0简化Catmull-Rom曲线(0,0,1,1)\0Perlins平滑阶梯\0绝对值相加\0Techicolor Cinestyle\0抛物线\0半圆\0多项式分割\0";
	ui_tooltip = "你想用的对比度S曲线。请注意，Technicolor Cinestyle几乎与正弦相同，但运行速度较慢。事实上，我认为这种差异可能只是由于四舍五入的错误造成的。我自己更喜欢2，但3也不错，效果更多一点（但对高光和阴影更苛刻），而且它是最快的公式。";
> = 4;

uniform float Contrast <
	ui_label = "对比度";
	ui_type = "slider";
	ui_min = -1.0; ui_max = 1.0;
	ui_tooltip = "你想要的对比度数量";
> = 0.65;

#include "ReShade.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

float4 CurvesPass(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float4 colorInput = tex2D(ReShade::BackBuffer, texcoord);
	const float3 lumCoeff = float3(0.2126, 0.7152, 0.0722);  //Values to calculate luma with
	float Contrast_blend = Contrast; 
	const float PI = 3.1415927;

	/*-----------------------------------------------------------.
	/               Separation of Luma and Chroma                 /
	'-----------------------------------------------------------*/

	// -- Calculate Luma and Chroma if needed --
	//calculate luma (grey)
	const float luma = dot(lumCoeff, colorInput.rgb);
	//calculate chroma
	const float3 chroma = colorInput.rgb - luma;

	// -- Which value to put through the contrast formula? --
	// I name it x because makes it easier to copy-paste to Graphtoy or Wolfram Alpha or another graphing program
	float3 x;
	if (Mode == 0)
		x = luma; //if the curve should be applied to Luma
	else if (Mode == 1)
		x = chroma, //if the curve should be applied to Chroma
		x = x * 0.5 + 0.5; //adjust range of Chroma from -1 -> 1 to 0 -> 1
	else
		x = colorInput.rgb; //if the curve should be applied to both Luma and Chroma

	/*-----------------------------------------------------------.
	/                     Contrast formulas                       /
	'-----------------------------------------------------------*/

	// -- Curve 1 --
	if (Formula == 0)
	{
		x = sin(PI * 0.5 * x); // Sin - 721 amd fps, +vign 536 nv
		x *= x;

		//x = 0.5 - 0.5*cos(PI*x);
		//x = 0.5 * -sin(PI * -x + (PI*0.5)) + 0.5;
	}

	// -- Curve 2 --
	if (Formula == 1)
	{
		x = x - 0.5;
		x = (x / (0.5 + abs(x))) + 0.5;

		//x = ( (x - 0.5) / (0.5 + abs(x-0.5)) ) + 0.5;
	}

	// -- Curve 3 --
	if (Formula == 2)
	{
		//x = smoothstep(0.0,1.0,x); //smoothstep
		x = x*x*(3.0 - 2.0*x); //faster smoothstep alternative - 776 amd fps, +vign 536 nv
		//x = x - 2.0 * (x - 1.0) * x* (x- 0.5);  //2.0 is contrast. Range is 0.0 to 2.0
	}

	// -- Curve 4 --
	if (Formula == 3)
	{
		x = (1.0524 * exp(6.0 * x) - 1.05248) / (exp(6.0 * x) + 20.0855); //exp formula
	}

	// -- Curve 5 --
	if (Formula == 4)
	{
		//x = 0.5 * (x + 3.0 * x * x - 2.0 * x * x * x); //a simplified catmull-rom (0,0,1,1) - btw smoothstep can also be expressed as a simplified catmull-rom using (1,0,1,0)
		//x = (0.5 * x) + (1.5 -x) * x*x; //estrin form - faster version
		x = x * (x * (1.5 - x) + 0.5); //horner form - fastest version

		Contrast_blend = Contrast * 2.0; //I multiply by two to give it a strength closer to the other curves.
	}

	// -- Curve 6 --
	if (Formula == 5)
	{
		x = x*x*x*(x*(x*6.0 - 15.0) + 10.0); //Perlins smootherstep
	}

	// -- Curve 7 --
	if (Formula == 6)
	{
		//x = ((x-0.5) / ((0.5/(4.0/3.0)) + abs((x-0.5)*1.25))) + 0.5;
		x = x - 0.5;
		x = x / ((abs(x)*1.25) + 0.375) + 0.5;
		//x = ( (x-0.5) / ((abs(x-0.5)*1.25) + (0.5/(4.0/3.0))) ) + 0.5;
	}

	// -- Curve 8 --
	if (Formula == 7)
	{
		x = (x * (x * (x * (x * (x * (x * (1.6 * x - 7.2) + 10.8) - 4.2) - 3.6) + 2.7) - 1.8) + 2.7) * x * x; //Techicolor Cinestyle - almost identical to curve 1
	}

	// -- Curve 9 --
	if (Formula == 8)
	{
		x = -0.5 * (x*2.0 - 1.0) * (abs(x*2.0 - 1.0) - 2.0) + 0.5; //parabola
	}

	// -- Curve 10 --
	if (Formula == 9)
	{
		const float3 xstep = step(x, 0.5); //tenary might be faster here
		const float3 xstep_shift = (xstep - 0.5);
		const float3 shifted_x = x + xstep_shift;

		x = abs(xstep - sqrt(-shifted_x * shifted_x + shifted_x)) - xstep_shift;

		//x = abs(step(x,0.5)-sqrt(-(x+step(x,0.5)-0.5)*(x+step(x,0.5)-0.5)+(x+step(x,0.5)-0.5)))-(step(x,0.5)-0.5); //single line version of the above

		//x = 0.5 + (sign(x-0.5)) * sqrt(0.25-(x-trunc(x*2))*(x-trunc(x*2))); //worse

		/* // if/else - even worse
		if (x-0.5)
		x = 0.5-sqrt(0.25-x*x);
		else
		x = 0.5+sqrt(0.25-(x-1)*(x-1));
		*/

		//x = (abs(step(0.5,x)-clamp( 1-sqrt(1-abs(step(0.5,x)- frac(x*2%1)) * abs(step(0.5,x)- frac(x*2%1))),0 ,1))+ step(0.5,x) )*0.5; //worst so far

		//TODO: Check if I could use an abs split instead of step. It might be more efficient

		Contrast_blend = Contrast * 0.5; //I divide by two to give it a strength closer to the other curves.
	}
  
	// -- Curve 11 --
	if (Formula == 10)
	{
		float3 a = float3(0.0, 0.0, 0.0);
		float3 b = float3(0.0, 0.0, 0.0);

		a = x * x * 2.0;
		b = (2.0 * -x + 4.0) * x - 1.0;
		if (x.r < 0.5 || x.g < 0.5 || x.b < 0.5)
			x = a;
		else
			x = b;
	}

	/*-----------------------------------------------------------.
	/                 Joining of Luma and Chroma                  /
	'-----------------------------------------------------------*/

	if (Mode == 0) // Only Luma
	{
		x = lerp(luma, x, Contrast_blend); //Blend by Contrast
		colorInput.rgb = x + chroma; //Luma + Chroma
	}
	else if (Mode == 1) // Only Chroma
	{
		x = x * 2.0 - 1.0; //adjust the Chroma range back to -1 -> 1
		const float3 color = luma + x; //Luma + Chroma
		colorInput.rgb = lerp(colorInput.rgb, color, Contrast_blend); //Blend by Contrast
	}
	else // Both Luma and Chroma
	{
		const float3 color = x;  //if the curve should be applied to both Luma and Chroma
		colorInput.rgb = lerp(colorInput.rgb, color, Contrast_blend); //Blend by Contrast
	}

#if GSHADE_DITHER
	return float4(colorInput.rgb + TriDither(colorInput.rgb, texcoord, BUFFER_COLOR_BIT_DEPTH), colorInput.a);
#else
	return colorInput;
#endif
}

technique Curves <ui_label = "对比度曲线";>
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = CurvesPass;
	}
}
