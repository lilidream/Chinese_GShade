/*******************************************************
	ReShade Shader: MultiTonePoster
	https://github.com/Daodan317081/reshade-shaders
*******************************************************/
// Translation of the UI into Chinese by Lilidream.

#include "ReShade.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif


#define MTP_PATTERN_ITEMS "Linear\0Vertical Stripes\0Horizontal Stripes\0Squares\0"

uniform float4 Color1 <
	ui_type = "color";
	ui_label = "颜色1";
> = float4(0.0, 0.05, 0.17, 1.0);
uniform int Pattern12 <
	ui_type = "combo";
	ui_label = "图案类型";
	ui_items = MTP_PATTERN_ITEMS;
> = 3;
uniform int Width12 <
	ui_type = "slider";
	ui_label = "宽度";
	ui_min = 1; ui_max = 10;
	ui_step = 1;
> = 1;	
uniform float4 Color2 <
	ui_type = "color";
	ui_label = "颜色2";
> = float4(0.20, 0.16, 0.25, 1.0);
uniform int Pattern23 <
	ui_type = "combo";
	ui_label = "图案类型";
	ui_items = MTP_PATTERN_ITEMS;
> = 3;
uniform int Width23 <
	ui_type = "slider";
	ui_label = "宽度";
	ui_min = 1; ui_max = 10;
	ui_step = 1;
> = 1;
uniform float4 Color3 <
	ui_type = "color";
	ui_label = "颜色3";
> = float4(1.0, 0.16, 0.10, 1.0);
uniform int Pattern34 <
	ui_type = "combo";
	ui_label = "图案类型";
	ui_items = MTP_PATTERN_ITEMS;
> = 2;
uniform int Width34 <
	ui_type = "slider";
	ui_label = "宽度";
	ui_min = 1; ui_max = 10;
	ui_step = 1;
> = 1;
uniform float4 Color4 <
	ui_type = "color";
	ui_label = "颜色4";
> = float4(1.0, 1.0, 1.0, 1.0);
uniform float fUIStrength <
	ui_type = "slider";
	ui_label = "效果强度";
	ui_min = 0.0; ui_max = 1.0;
	ui_step = 0.01;
> = 1.0;

float3 MultiTonePoster_PS(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target {
	const float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;
	float luma = dot(color, float3(0.2126, 0.7151, 0.0721));
	static const int numColors = 7;
	float4 colors[numColors];

	float stripeFactor[12] = {
					0.5,
					step(vpos.x % (Width12*2), Width12),
					step(vpos.y % (Width12*2), Width12),
					0.0,

					0.5,
					step(vpos.x % (Width23*2), Width23),
					step(vpos.y % (Width23*2), Width23),
					0.0,

					0.5,
					step(vpos.x % (Width34*2), Width34),
					step(vpos.y % (Width34*2), Width34),
					0.0
				};

	stripeFactor[3] = step(stripeFactor[1] + stripeFactor[2], 0.0);
	stripeFactor[7] = step(stripeFactor[5] + stripeFactor[6], 0.0);
	stripeFactor[11] = step(stripeFactor[9] + stripeFactor[10], 0.0);

	colors = {
				Color1,
				0.0.rrrr,
				Color2,
				0.0.rrrr,
				Color3,
				0.0.rrrr,
				Color4
			};

	colors[1] = lerp(colors[0], colors[2], stripeFactor[Pattern12]);
	colors[3] = lerp(colors[2], colors[4], stripeFactor[Pattern23 + 4]);
	colors[5] = lerp(colors[4], colors[6], stripeFactor[Pattern34 + 8]);

	colors[0] = lerp(color, colors[0].rgb, colors[0].w);
	colors[1] = lerp(color, colors[1].rgb, (colors[0].w + colors[2].w) / 2.0);
	colors[2] = lerp(color, colors[2].rgb, colors[2].w);
	colors[3] = lerp(color, colors[3].rgb, (colors[2].w + colors[4].w) / 2.0);
	colors[4] = lerp(color, colors[4].rgb, colors[4].w);
	colors[5] = lerp(color, colors[5].rgb, (colors[4].w + colors[6].w) / 2.0);
	colors[6] = lerp(color, colors[6].rgb, colors[6].w);

#if GSHADE_DITHER
	const float3 outcolor = lerp(color, colors[(int)floor(luma * numColors)].rgb, fUIStrength);
	return outcolor + TriDither(outcolor, texcoord, BUFFER_COLOR_BIT_DEPTH);
#else
	return lerp(color, colors[(int)floor(luma * numColors)].rgb, fUIStrength);
#endif
}

technique MultiTonePoster <ui_label="多色调海报";> {
	pass {
		VertexShader = PostProcessVS;
		PixelShader = MultiTonePoster_PS;
		/* RenderTarget = BackBuffer */
	}
}