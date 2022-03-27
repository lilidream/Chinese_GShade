// -------------------------------------
// Clipboard (c) seri14
// -------------------------------------
// Translation of the UI into Chinese by Lilidream.

// -------------------------------------
// Includes
// -------------------------------------

#include "ReShade.fxh"

// -------------------------------------
// Textures
// -------------------------------------

texture Clipboard_Texture
{
	Width = BUFFER_WIDTH;
	Height = BUFFER_HEIGHT;
	Format = RGBA8;
};

// -------------------------------------
// Samplers
// -------------------------------------

sampler Sampler
{
	Texture = Clipboard_Texture;
};

// -------------------------------------
// Variables
// -------------------------------------

uniform int _help
<
	ui_text ="启用'复制'着色器然后关闭，就会记录下关闭时的画面。打开'粘贴'就能显示该画面。";
	ui_category = "帮助";
	ui_category_closed = false;
	ui_label = " ";
	ui_type = "radio";
>;

uniform float BlendIntensity <
	ui_label = "透明混合等级";
	ui_type = "drag";
	ui_min = 0.001; ui_max = 1000.0;
	ui_step = 0.001;
> = 1.0;

// -------------------------------------
// Entrypoints
// -------------------------------------

void PS_Copy(float4 pos : SV_Position, float2 texCoord : TEXCOORD, out float4 frontColor : SV_Target)
{
	frontColor = tex2D(ReShade::BackBuffer, texCoord);
}

void PS_Paste(float4 pos : SV_Position, float2 texCoord : TEXCOORD, out float4 frontColor : SV_Target)
{
	const float4 backColor = tex2D(ReShade::BackBuffer, texCoord);

	frontColor = tex2D(Sampler, texCoord);
	frontColor = lerp(backColor, frontColor, min(1.0, frontColor.a * BlendIntensity));
}

// -------------------------------------
// Techniques
// -------------------------------------

technique Copy <ui_label="复制";>
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_Copy;
		RenderTarget = Clipboard_Texture;
	}
}

technique Paste <ui_label="粘贴";>
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_Paste;
	}
}
