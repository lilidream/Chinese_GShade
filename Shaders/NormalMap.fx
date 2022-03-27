// Translation of the UI into Chinese by Lilidream.
//#region Includes

#include "FXShadersCommon.fxh"
#include "FXShadersMath.fxh"

//#endregion

//#region Preprocessor Directives

#ifndef NORMAL_MAP_WIDTH
#define NORMAL_MAP_WIDTH 1024
#endif

#ifndef NORMAL_MAP_HEIGHT
#define NORMAL_MAP_HEIGHT 1024
#endif

#ifndef NORMAL_MAP_TEXTURE
#define NORMAL_MAP_TEXTURE "NormalMap.png"
#endif

//#endregion

namespace FXShaders
{

//#region Constants

static const float2 NormalResolution = float2(NORMAL_MAP_WIDTH, NORMAL_MAP_HEIGHT);
static const float2 NormalPixelSize = 1.0 / NormalResolution;
static const float NormalAspectRatio = NormalResolution.x * NormalPixelSize.y;
static const float TranslationScale = 1.0;
static const float RotationScale = 0.2;

static const int AddressMode_Repeat = 0;
static const int AddressMode_Clip = 1;
static const int AddressMode_Stretch = 2;

static const float DistortionAmountScale = 100.0;

//#endregion

//#region Uniforms

FXSHADERS_WIP_WARNING();

uniform float DistortionAmount
<
	ui_label = "扭曲数量";
	ui_tooltip =
		"基于法线映射贴图的画面扭曲数量\n"
		"\n默认: 1.0";
	ui_type = "slider";
	ui_min = -3.0;
	ui_max = 3.0;
> = 1.0;

uniform float TextureScale
<
	ui_label = "贴图缩放";
	ui_tooltip =
		"缩放屏幕上的发现映射贴图。"
		"\n默认: 6.0";
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 10.0;
> = 6.0;

uniform float ZScale
<
	ui_label = "Z缩放";
	ui_tooltip =
		"决定了多少法线贴图的Z轴影响扭曲效果。"
		"\n默认: 1.0";
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 1.0;
> = 1.0;

uniform float2 Translation
<
	ui_label = "转换速度";
	ui_tooltip =
		"法线贴图移动时的速度。"
		"\n默认: 0.0 0.0";
	ui_type = "slider";
	ui_min = -1.0;
	ui_max = 1.0;
> = 0.0;

uniform float Rotation
<
	ui_label = "旋转速度";
	ui_tooltip =
		"法线映射贴图的旋转速度。"
		"\n默认: 0.0";
	ui_type = "slider";
	ui_min = -1.0;
	ui_max = 1.0;
> = 0.0;

uniform int AddressMode
<
	ui_label = "贴图处理模式";
	ui_tooltip =
		"决定了超出坐标范围外的法线映射贴图如何渲染"
		"\n默认: 重复";
	ui_type = "combo";
	ui_items = "重复\0裁剪\0拉伸\0";
> = AddressMode_Repeat;

uniform float Timer <source = "timer";>;

//#endregion

//#region Textures

texture BackBufferTex : COLOR;

sampler BackBuffer
{
	Texture = BackBufferTex;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
};

texture NormalTex <source = NORMAL_MAP_TEXTURE;>
{
	Width = NormalResolution.x;
	Height = NormalResolution.y;
};

sampler NormalRepeat
{
	Texture = NormalTex;
	AddressU = REPEAT;
	AddressV = REPEAT;
};

sampler NormalClip
{
	Texture = NormalTex;
	AddressU = BORDER;
	AddressV = BORDER;
};

sampler NormalStretch
{
	Texture = NormalTex;
};

//#endregion

//#region Functions

float2 CorrectAspect(float2 uv)
{
	// Correct the normal map aspect ratio in case it's not 1:1.
	uv = CorrectAspectRatio(uv, NormalAspectRatio, 1.0);

	// Correct the normal map aspecct ratio to cover the screen's aspect ratio.
	return CorrectAspectRatio(
		uv,
		NormalAspectRatio,
		GetAspectRatio());
}

float2 ApplyScale(float2 uv)
{
	// Apply the normal texture scale.
	return ScaleCoord(uv, TextureScale);
}

float2 ApplyRotation(float2 uv)
{
	// We'll apply the rotation with non-normalized coordinates, otherwise it
	// breaks the aspect ratio.
	uv *= NormalResolution;
	uv = RotatePoint(
		uv,
		Rotation * Timer * RotationScale,
		NormalResolution * 0.5);
	return uv * NormalPixelSize;
}

float2 ApplyTranslation(float2 uv)
{
	return uv + (float2(-Translation.x, Translation.y) * Timer * TranslationScale) * NormalPixelSize;
}

float2 ApplyTransformations(float2 uv)
{
	uv = CorrectAspect(uv);
	uv = ApplyScale(uv);
	uv = ApplyRotation(uv);

	return ApplyTranslation(uv);
}

float2 ReadNormalTexture(float2 uv)
{
	uv = ApplyTransformations(uv);

	// HACK:
	//
	// Using a switch breaks, probably because the SPIR-V code is attempting to
	// optimize the call by changing the sampler dynamically, which HLSL does
	// not support.

	// TODO: Check if apply address modes programmatically is more efficient.

	float4 normal = 0.0;

	if (AddressMode == AddressMode_Repeat)
		normal = tex2D(NormalRepeat, uv);
	else if (AddressMode == AddressMode_Clip)
		normal = tex2D(NormalClip, uv);
	else if (AddressMode == AddressMode_Stretch)
		normal = tex2D(NormalStretch, uv);

	normal.xyz *= normal.a;
	normal = normal * 2.0 - 1.0;
	normal.xy *= lerp(1.0, normal.z, ZScale);

	return normal.xy;
}

//#endregion

//#region Shaders

float4 MainPS(float4 p : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET
{
	const float2 normal = ReadNormalTexture(uv);
	const float amount = DistortionAmount * DistortionAmountScale;
	const float2 ps = GetPixelSize() * amount;
	uv += normal.xy * ps;

	return tex2D(BackBuffer, uv);
}

//#endregion

//#region Techniques

technique NormalMap
<
	ui_tooltip = "FXShaders - 使用法线映射贴图来扭曲画面。";ui_label="法线映射";
>
{
	pass
	{
		VertexShader = ScreenVS;
		PixelShader = MainPS;
	}
}

//#endregion

} // Namespace.
