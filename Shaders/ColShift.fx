// Translation of the UI into Chinese by Lilidream.
#include "ReShade.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

uniform int _help <
    ui_text="此着色器可以将接近红色的一系列颜色的像素替换成黄色或绿色。它的目的是给那些看不清红色的色盲人士（尤其是红色弱）使用，这些颜色在游戏中被用来突出重要的东西，如闪烁的红色低血量条、红色文字、敌人的轮廓、敌人的攻击追踪器，或者表示AOE攻击的圆圈。";
> = 0;

uniform float HardRedCutoff <
    ui_type = "slider";
    ui_min = 0.0; ui_max = 1.0;
    ui_label = "硬红色界限";
> = float(0.85);

uniform float SoftRedCutoff <
    ui_type = "slider";
    ui_min = 0.0; ui_max = 1.0;
    ui_label = "软红色界限";
> = float(0.6);

uniform float HardGreenCutoff <
    ui_type = "slider";
    ui_min = 0.0; ui_max = 1.0;
    ui_label = "硬绿色界限";
> = float(0.6);

uniform float SoftGreenCutoff <
    ui_type = "slider";
    ui_min = 0.0; ui_max = 1.0;
    ui_label = "软绿色界限";
> = float(0.85);

uniform float BlueCutoff <
    ui_type = "slider";
    ui_min = 0.0; ui_max = 1.0;
    ui_label = "蓝色界限";
> = float(0.3);

uniform bool Yellow <
	ui_type = "checkbox";
	ui_label = "使用黄色而不是绿色";
> = false;


float3 ColShiftPass(float4 position: SV_Position, float2 texcoord: TexCoord): SV_Target
{
    const float3 input = tex2D(ReShade::BackBuffer, texcoord).rgb;
    if (input.r >= HardRedCutoff && input.g <= HardGreenCutoff && input.b <= BlueCutoff)
    {
		if (Yellow)
			return input.rrb;
		else
			return input.grb;		
    }

    if (input.r >= SoftRedCutoff && input.g <= SoftGreenCutoff && input.b <= BlueCutoff)
    {
		const float alphaR = (input.r - SoftRedCutoff) / (HardRedCutoff - SoftRedCutoff);
		if (Yellow)
			return lerp(input.rgb, input.rrb, alphaR);
		else
			return lerp(input.rgb, input.grb, alphaR);
    }

#if GSHADE_DITHER
	return input + TriDither(input, texcoord, BUFFER_COLOR_BIT_DEPTH);
#else
	return input;
#endif
}

technique ColShift <ui_label="色盲助手";>
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = ColShiftPass;
    }
}
