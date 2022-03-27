// Translation of the UI into Chinese by Lilidream.

#include "ReShade.fxh"

uniform int lineDensity <
	ui_label = "亮度线";
	ui_type = "slider";
	ui_min = 1; ui_max = 100;
	ui_tooltip = "如果设置为0游戏会崩溃";
> = 10;

uniform float blackThreshold <
	ui_label = "黑色阈值";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
> = 0.1;

uniform float whiteThreshold <
	ui_label = "白色阈值";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
> = 0.9;

uniform bool blend <
> = false;

float3 lumaLines(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD) : COLOR
{
	int OneBitLuma, OneBitLumaShift, lines;
	float luma = dot(tex2D(ReShade::BackBuffer, texcoord).rgb, 1.0 / 3.0);

	for(float i = 1.0 / lineDensity; i <= 1.0 - (1.0 / lineDensity); i += (1.0 / lineDensity))
	{
		OneBitLuma = ceil(1.0 - step(luma, i));

		OneBitLumaShift = ceil(1.0 - step(dot(tex2D(ReShade::BackBuffer, float2(texcoord.x + BUFFER_RCP_WIDTH, texcoord.y)).rgb, 1.0 / 3.0), i));
		lines += OneBitLumaShift - OneBitLuma;

		OneBitLumaShift = ceil(1.0 - step(dot(tex2D(ReShade::BackBuffer, float2(texcoord.x - BUFFER_RCP_WIDTH, texcoord.y)).rgb, 1.0 / 3.0), i));
		lines += OneBitLumaShift - OneBitLuma;

		OneBitLumaShift = ceil(1.0 - step(dot(tex2D(ReShade::BackBuffer, float2(texcoord.x, texcoord.y + BUFFER_RCP_HEIGHT)).rgb, 1.0 / 3.0), i));
		lines += OneBitLumaShift - OneBitLuma;

		OneBitLumaShift = ceil(1.0 - step(dot(tex2D(ReShade::BackBuffer, float2(texcoord.x, texcoord.y - BUFFER_RCP_HEIGHT)).rgb, 1.0 / 3.0), i));
		lines += OneBitLumaShift - OneBitLuma;
	}

	lines = max(lines, ceil(step(luma, blackThreshold)));
	lines = min(lines, ceil(step(luma, whiteThreshold)));

	if(blend)
	{
		return (1.0 - lines) * tex2D(ReShade::BackBuffer, texcoord).rgb;
	}
	else
	{
		return 1.0 - lines;
	}
}

technique LumaLines <ui_label="亮度线";>
{
	pass pass0
	{
		VertexShader = PostProcessVS;
		PixelShader = lumaLines;
	}
}
