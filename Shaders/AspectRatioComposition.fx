/*******************************************************
	ReShade Shader: AspectRatioComposition
	https://github.com/Daodan317081/reshade-shaders
	
	Translation of the UI into Chinese by Lilidream.
*******************************************************/

#include "ReShade.fxh"

#define GOLDEN_RATIO 1.6180339887

#ifndef ASPECT_RATIO_MAX
	#define ASPECT_RATIO_MAX 25
#endif

/******************************************************************************
	Uniforms
******************************************************************************/

#ifdef ASPECT_RATIO_FLOAT
uniform float fUIAspectRatio <
	ui_type = "slider";
	ui_label = "纵横比";
	ui_tooltip = "如需使用整数控制纵横比\n请从预处理中清除'ASPECT_RATIO_FLOAT'";
	ui_min = 0.0; ui_max = 25.0;
	ui_step = 0.01;
> = 1.0;
#else
uniform int2 iUIAspectRatio <
	ui_type = "slider";
	ui_label = "纵横比";
	ui_tooltip = "如需使用小数控制纵横比\n请在预处理中添加'ASPECT_RATIO_FLOAT'\n备用选项: 'ASPECT_RATIO_MAX=xyz'";
	ui_min = 0; ui_max = ASPECT_RATIO_MAX;
> = int2(16, 9);
#endif

uniform int iUIGridType <
	ui_type = "combo";
	ui_label = "网格类型";
	ui_items = "关闭\0均分\0黄金比例\0";
> = 0;

uniform int iUIGridFractions <
	ui_type = "slider";
	ui_label = "网格均分数";
	ui_tooltip = "需要设置网格类型为均分";
	ui_min = 1; ui_max = 5;
> = 3;

uniform float4 UIGridColor <
	ui_type = "color";
    ui_label = "网格颜色";
> = float4(0.0, 0.0, 0.0, 1.0);

/******************************************************************************
	Functions
******************************************************************************/

float3 DrawGrid(float3 backbuffer, float3 gridColor, float aspectRatio, float fraction, float4 vpos)
{
	float borderSize;
	float fractionWidth;
	
	float3 retVal = backbuffer;

	if(aspectRatio < BUFFER_ASPECT_RATIO)
	{
		borderSize = (BUFFER_WIDTH - BUFFER_HEIGHT * aspectRatio) / 2.0;
		fractionWidth = (BUFFER_WIDTH - 2 * borderSize) / fraction;

		if(vpos.x < borderSize || vpos.x > (BUFFER_WIDTH - borderSize))
			retVal = gridColor;

		if((vpos.y % (BUFFER_HEIGHT / fraction)) < 1)
			retVal = gridColor;

		if(((vpos.x - borderSize) % fractionWidth) < 1)
			retVal = gridColor;	
	}
	else
	{
		borderSize = (BUFFER_HEIGHT - BUFFER_WIDTH / aspectRatio) / 2.0;
		fractionWidth = (BUFFER_HEIGHT - 2 * borderSize) / fraction;

		if(vpos.y < borderSize || vpos.y > (BUFFER_HEIGHT - borderSize))
			retVal = gridColor;

		if((vpos.x % (BUFFER_WIDTH / fraction)) < 1)
			retVal = gridColor;
			
		if(((vpos.y - borderSize) % fractionWidth) < 1)
			retVal = gridColor;

	}

	if(vpos.x <= 1 || vpos.x >= BUFFER_WIDTH-1 || vpos.y <= 1 || vpos.y >= BUFFER_HEIGHT-1)
		retVal = gridColor;
	
	return retVal;
}

/******************************************************************************
	Pixel Shader
******************************************************************************/

float3 AspectRatioComposition_PS(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
    float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;
	float3 retVal = color;

	float userAspectRatio;

#ifdef ASPECT_RATIO_FLOAT
	userAspectRatio = fUIAspectRatio;
#else
	userAspectRatio = (float)iUIAspectRatio.x / (float)iUIAspectRatio.y;
#endif

	if(iUIGridType == 1)
		retVal = DrawGrid(color, UIGridColor.rgb, userAspectRatio, iUIGridFractions, vpos);
	else if(iUIGridType == 2)
	{
		retVal = DrawGrid(color, UIGridColor.rgb, userAspectRatio, GOLDEN_RATIO, vpos);
		retVal = DrawGrid(retVal, UIGridColor.rgb, userAspectRatio, GOLDEN_RATIO, float4(BUFFER_WIDTH, BUFFER_HEIGHT, 0, 0) - vpos);
	}

    return lerp(color, retVal, UIGridColor.w);
}

technique AspectRatioComposition <
	ui_label = "比例构图线";
	ui_tooltip = "添加不同比例的边框与网格";
>
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = AspectRatioComposition_PS;
	}
}