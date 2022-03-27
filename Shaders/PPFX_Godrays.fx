// ++++++++++++++++++++++++++++++++++++++++++++++++++++++
// *** PPFX Godrays from the Post-Processing Suite 1.03.29 for ReShade
// *** SHADER AUTHOR: Pascal Matthäus ( Euda )
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Translation of the UI into Chinese by Lilidream.

//+++++++++++++++++++++++++++++
// DEV_NOTES
//+++++++++++++++++++++++++++++
// Updated for compatibility with ReShade 4 and isolated by Marot Satil.

#include "ReShade.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

//+++++++++++++++++++++++++++++
// CUSTOM PARAMETERS
//+++++++++++++++++++++++++++++

// ** GODRAYS **
uniform int pGodraysSampleAmount <
    ui_label = "采样数量";
    ui_tooltip = "实际上就是射线的分辨率。低值可能看起来很粗糙，但会产生更高的帧速率。";
    ui_type = "slider";
    ui_min = 8;
    ui_max = 250;
    ui_step = 1;
> = 64;

uniform float2 pGodraysSource <
    ui_label = "光源";
    ui_tooltip = "圣光在屏幕空间中的消失点。0.500,0.500是你屏幕的中间。";
    ui_type = "slider";
    ui_min = -0.5;
    ui_max = 1.5;
    ui_step = 0.001;
> = float2(0.5, 0.4);

uniform float pGodraysExposure <
    ui_label = "曝光";
    ui_tooltip = "每个单一光斑对最终光线的贡献曝光。一般来说，0.100就足够了。";
    ui_type = "slider";
    ui_min = 0.01;
    ui_max = 1.0;
    ui_step = 0.01;
> = 0.1;

uniform float pGodraysFreq <
    ui_label = "频率";
    ui_tooltip = "更高的值会导致更高的单线密度。'1.000'会导致射线永远覆盖整个屏幕。衰减、采样和这个值之间的平衡。";
    ui_type = "slider";
    ui_min = 1.0;
    ui_max = 10.0;
    ui_step = 0.001;
> = 1.2;

uniform float pGodraysThreshold <
    ui_label = "阈值";
    ui_tooltip = "像素暗于此值将不会产生射线。";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.001;
> = 0.65;

uniform float pGodraysFalloff <
    ui_label = "消散";
    ui_tooltip = "让射线的亮度随着它们与 \"光源\"中指定的光源的距离减弱/消退。";
    ui_type = "slider";
    ui_min = 1.0;
    ui_max = 2.0;
    ui_step = 0.001;
> = 1.06;

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// +++++   TEXTURES   +++++
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

// *** ESSENTIALS ***
texture texColorGRA { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; };
texture texColorGRB < pooled = true; > { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; };
texture texGameDepth : DEPTH;

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// +++++   SAMPLERS   +++++
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

// *** ESSENTIALS ***

sampler SamplerColorGRA
{
	Texture = texColorGRA;
	AddressU = BORDER;
	AddressV = BORDER;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
};

sampler SamplerColorGRB
{
	Texture = texColorGRB;
	AddressU = BORDER;
	AddressV = BORDER;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
};

sampler2D SamplerDepth
{
	Texture = texGameDepth;
};

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// +++++   VARIABLES   +++++
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

static const float3 lumaCoeff = float3(0.2126f,0.7152f,0.0722f);
#define ZNEAR 0.3
#define ZFAR 50.0

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// +++++   STRUCTS   +++++
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

struct VS_OUTPUT_POST
{
	float4 vpos : SV_Position;
	float2 txcoord : TEXCOORD0;
};

struct VS_INPUT_POST
{
	uint id : SV_VertexID;
};

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// +++++   HELPERS   +++++
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

float linearDepth(float2 txCoords)
{
	return (2.0*ZNEAR)/(ZFAR+ZNEAR-tex2D(SamplerDepth,txCoords).x*(ZFAR-ZNEAR));
}

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// +++++   EFFECTS   +++++
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

// *** Godrays ***
	float4 FX_Godrays( float4 pxInput, float2 txCoords )
	{
		const float2	stepSize = (txCoords-pGodraysSource) / (pGodraysSampleAmount*pGodraysFreq);
		float3	rayMask = 0.0;
		float	rayWeight = 1.0;
		float	finalWhitePoint = pxInput.w;
		
		[loop]
		for (int i=1;i<(int)pGodraysSampleAmount;i++)
		{
			rayMask += saturate(saturate(tex2Dlod(SamplerColorGRB, float4(txCoords-stepSize*(float)i, 0.0, 0.0)).xyz) - pGodraysThreshold) * rayWeight * pGodraysExposure;
			finalWhitePoint += rayWeight * pGodraysExposure;
			rayWeight /= pGodraysFalloff;
		}
		
		rayMask.xyz = dot(rayMask.xyz,lumaCoeff.xyz) / (finalWhitePoint-pGodraysThreshold);
		return float4(pxInput.xyz+rayMask.xyz,finalWhitePoint);
	}

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// +++++   VERTEX-SHADERS   +++++
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

VS_OUTPUT_POST VS_PostProcess(VS_INPUT_POST IN)
{
	VS_OUTPUT_POST OUT;

	if (IN.id == 2)
		OUT.txcoord.x = 2.0;
	else
		OUT.txcoord.x = 0.0;

	if (IN.id == 1)
		OUT.txcoord.y = 2.0;
	else
		OUT.txcoord.y = 0.0;

	OUT.vpos = float4(OUT.txcoord * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
	return OUT;
}

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// +++++   PIXEL-SHADERS   +++++
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

// *** Shader Structure ***

// *** Further FX ***
float4 PS_LightFX(VS_OUTPUT_POST IN) : COLOR
{
	const float2 pxCoord = IN.txcoord.xy;
	const float4 res = tex2D(ReShade::BackBuffer,pxCoord);
	
	return FX_Godrays(res,pxCoord.xy);
}

float4 PS_ColorFX(VS_OUTPUT_POST IN) : COLOR
{
	const float2 pxCoord = IN.txcoord.xy;
	const float4 res = tex2D(SamplerColorGRA,pxCoord);

	return float4(res.xyz,1.0);
}

float4 PS_ImageFX(VS_OUTPUT_POST IN) : COLOR
{
	const float2 pxCoord = IN.txcoord.xy;
	const float4 res = tex2D(SamplerColorGRB,pxCoord);
	
#if GSHADE_DITHER
	return float4(res.xyz + TriDither(res.xyz, IN.txcoord, BUFFER_COLOR_BIT_DEPTH), 1.0);
#else
	return float4(res.xyz, 1.0);
#endif
}

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// +++++   TECHNIQUES   +++++
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

technique PPFX_Godrays < ui_label = "PPFX 圣光"; ui_tooltip = "圣光 | 让明亮区域在屏幕上产生射线"; >
{
	pass lightFX
	{
		VertexShader = VS_PostProcess;
		PixelShader = PS_LightFX;
		RenderTarget0 = texColorGRA;
	}
	
	pass colorFX
	{
		VertexShader = VS_PostProcess;
		PixelShader = PS_ColorFX;
		RenderTarget0 = texColorGRB;
	}
	
	pass imageFX
	{
		VertexShader = VS_PostProcess;
		PixelShader = PS_ImageFX;
	}
}