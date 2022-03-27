// Translation of the UI into Chinese by Lilidream.

//#region Includes

#include "FXShadersAPI.fxh"
#include "FXShadersCanvas.fxh"
#include "FXShadersCommon.fxh"
#include "FXShadersConvolution.fxh"
#include "FXShadersMath.fxh"
#include "FXShadersTonemap.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

//#endregion

//#region Preprocessor Directives

#ifndef MAGIC_HDR_BLUR_SAMPLES
#define MAGIC_HDR_BLUR_SAMPLES 13
#endif

#if MAGIC_HDR_BLUR_SAMPLES < 1
	#error "Blur samples cannot be less than 1"
#endif

#ifndef MAGIC_HDR_DOWNSAMPLE
#define MAGIC_HDR_DOWNSAMPLE 4
#endif

#if MAGIC_HDR_DOWNSAMPLE < 1
	#error "Downsample cannot be less than 1x"
#endif

#ifndef MAGIC_HDR_SRGB_INPUT
#define MAGIC_HDR_SRGB_INPUT 1
#endif

#ifndef MAGIC_HDR_SRGB_OUTPUT
#define MAGIC_HDR_SRGB_OUTPUT 1
#endif

#ifndef MAGIC_HDR_ENABLE_ADAPTATION
#define MAGIC_HDR_ENABLE_ADAPTATION 0
#endif

//#endregion

namespace FXShaders
{

//#region Constants

static const int2 DownsampleAmount = MAGIC_HDR_DOWNSAMPLE;

static const int BlurSamples = MAGIC_HDR_BLUR_SAMPLES;

static const float2 AdaptFocusPointDebugSize = 10.0;

static const int
	InvTonemap_Reinhard = 0,
	InvTonemap_Lottes = 1,
	InvTonemap_Unreal3 = 2,
	InvTonemap_NarkowiczACES = 3,
	InvTonemap_Uncharted2Filmic = 4,
	InvTonemap_BakingLabACES = 5;

static const int
	Tonemap_Reinhard = 0,
	Tonemap_Lottes = 1,
	Tonemap_Unreal3 = 2,
	Tonemap_NarkowiczACES = 3,
	Tonemap_Uncharted2Filmic = 4,
	Tonemap_BakingLabACES = 5;

//#endregion

//#region Uniforms

FXSHADERS_WIP_WARNING();

FXSHADERS_CREDITS();

FXSHADERS_HELP(
	"这个效果允许你同时添加泛光和色调映射，极大地改变了图像的气氛。\n请注意选择一个适当的反色调映射器，它可以准确地从原始图像中提取HDR信息。\nHDR10用户还应该注意选择一个色调贴图器，它与HDR显示器从游戏的LDR输出所期望的内容相兼容，而LDR输出也是色调贴图。"
	"\n"
	"可用的预处理指令:\n"
	"\n"
	"MAGIC_HDR_BLUR_SAMPLES:\n"
	"  决定在每个模糊过程中对多少个像素进行采样，以达到泛光效果。\n"
	"  这个值直接影响到模糊尺寸，所以样本越多，模糊尺寸就越大。\n 设置MAGIC_HDR_DOWNSAMPLE超过1x，也会增加模糊大小以补偿较低的分辨率。\n不过，这种效果可能是理想的。\n"
	"\n"
	"MAGIC_HDR_DOWNSAMPLE:\n"
	"  用来划分用于处理泛光效果的纹理的分辨率。\n留在1倍处以获得最大的细节，2倍或4倍应该还是可以的。\n太高的值可能会引入闪烁。\n"
);

uniform float InputExposure
<
	ui_category = "色调映射";
	ui_label = "输入曝光";
	ui_tooltip =
		"接近原始画面的曝光\n"
		"这个值在f-stops里被测量\n"
		"\n默认: 1.0";
	ui_type = "slider";
	ui_min = -3.0;
	ui_max = 3.0;
> = 0.0;

uniform float Exposure
<
	ui_category = "色调映射";
	ui_label = "输出曝光";
	ui_tooltip =
		"应用于最终效果的曝光\n"
		"这个值在f-stops里被测量\n"
		"\n默认: 1.0";
	ui_type = "slider";
	ui_min = -3.0;
	ui_max = 3.0;
> = 0.0;

uniform int InvTonemap
<
	ui_category = "色调映射";
	ui_label = "反转色调映射";
	ui_tooltip =
		"反转色调映射操作用于保留HDR信息\n"
		"\n默认: Reinhard";
	ui_type = "combo";
	ui_items =
		"Reinhard\0Lottes\0Unreal 3\0Narkowicz ACES\0Uncharted 2 Filmic\0Baking Lab ACES\0";
> = InvTonemap_Reinhard;

uniform int Tonemap
<
	ui_category = "色调映射";
	ui_label = "输出色调映射";
	ui_tooltip =
		"应用于最终效果的的色调映射\n"
		"\n默认: Baking Lab ACES";
	ui_type = "combo";
	ui_items =
		"Reinhard\0Lottes\0Unreal 3\0Narkowicz ACES\0Uncharted 2 Filmic\0Baking Lab ACES\0";
> = Tonemap_BakingLabACES;

uniform float BloomAmount
<
	ui_category = "泛光";
	ui_category_closed = true;
	ui_label = "数量";
	ui_tooltip =
		"应用到画面的泛光数量"
		"\nDefault: 0.3";
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 1.0;
> = 0.3;

uniform float BloomBrightness
<
	ui_category = "泛光";
	ui_label = "亮度";
	ui_tooltip =
		"此值是泛光贴图亮度的相乘倍\n"
		"这与它直接影响泛光亮度数量不同，而不是作为HDR颜色和泛光颜色之间的混合百分比来作用。\n"
		"\nDefault: 3.0";
	ui_type = "slider";
	ui_min = 1.0;
	ui_max = 5.0;
> = 3.0;

uniform float BloomSaturation
<
	ui_category = "泛光";
	ui_label = "饱和度";
	ui_tooltip =
		"决定了泛光的饱和度\n"
		"\n默认: 1.0";
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 2.0;
> = 1.0;

uniform float BlurSize
<
	ui_category = "高级泛光";
	ui_category_closed = true;
	ui_label = "模糊大小";
	ui_tooltip =
		"应用于创建泛光效果的高斯模糊大小。\n"
		"这个值由MAGIC_HDR_BLUR_SAMPLES与MAGIC_HDR_DOWNSAMPLE直接影响。"
		"\n"
		"\n默认: 0.5";
	ui_type = "slider";
	ui_min = 0.01;
	ui_max = 1.0;
> = 0.5;

uniform float BlendingAmount
<
	ui_category = "高级泛光";
	ui_label = "混合数量";
	ui_tooltip =
		"内部各样泛光贴图的混合程度。\n"
		"减少这个值会使泛光更单一，缺少变化。"
		"\n默认: 0.5";
	ui_type = "slider";
	ui_min = 0.1;
	ui_max = 1.0;
> = 0.5;

uniform float BlendingBase
<
	ui_category = "高级泛光";
	ui_label = "混合基础";
	ui_tooltip =
		"决定了混合时基础泛光的大小。\n"
		"低混合数量时更有效。"
		"\nDefault: 0.8";
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 1.0;
> = 0.8;

#if MAGIC_HDR_ENABLE_ADAPTATION

uniform float AdaptTime
<
	ui_category = "自适应";
	ui_category_closed = true;
	ui_label = "延迟";
	ui_tooltip =
		"前一个值到后一个值的自适应转换时间（秒）\n"
		"\n默认: 1.0";
	ui_type = "drag";
	ui_min = 0.0;
	ui_max = 10.0;
	ui_step = 0.001;
> = 1.0;

uniform float2 AdaptMinMax
<
	ui_category = "自适应";
	ui_label = "范围";
	ui_tooltip =
		"分别决定了自适应的最小与最大值。\n"
		"增加最小值会降低图像的亮度。\n"
		"降低最大限度将减少图像的暗程度。\n"
		"\n默认: 0.0 1.0";
	ui_type = "drag";
	ui_min = 0.0;
	ui_max = 3.0;
	ui_step = 0.001;
> = float2(0.0, 1.0);

uniform float AdaptSensitivity
<
	ui_category = "高级自适应";
	ui_category_closed = true;
	ui_label = "敏感度";
	ui_tooltip =
		"决定了自适应对亮物体的敏感程度\n"
		"\n默认: 1.0";
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 2.0;
> = 1.0;

uniform float AdaptPrecision
<
	ui_category = "高级自适应";
	ui_label = "准确度";
	ui_tooltip =
		"决定了哪一部分的画面影响自适应更多。\n"
		"为0.0时，自适应受整个画面的平均影响。\n"
		"为1.0时，自适应受焦点物体影响。"
		"点比剩余场景更多\n"
		"\n默认: 0.0";
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 1.0;
> = 0.0;

uniform float2 AdaptPoint
<
	ui_category = "高级自适应";
	ui_label = "焦点";
	ui_tooltip =
		"决定用于屏幕上用于测量自适应的点。\n"
		"第一个值决定水平位置，从左到右;\n"
		"第二个值决定垂直位置，从上到下。\n"
		"(0.5,0.5)为屏幕中心"
		"\n默认: 0.5 0.5";
	ui_type = "drag";
	ui_min = 0.0;
	ui_max = 1.0;
	ui_step = 0.001;
> = 0.5;

uniform float FrameTime <source = "frametime";>;

#endif

uniform bool ShowBloom
<
	ui_category = "Debug";
	ui_category_closed = true;
	ui_label = "显示泛光";
	ui_tooltip =
		"显示泛光贴图"
		"\n默认: 关";
> = false;

#if MAGIC_HDR_ENABLE_ADAPTATION

uniform bool ShowAdapt
<
	ui_category = "Debug";
	ui_label = "显示自适应";
	ui_tooltip =
		"显示用于自适应的贴图与对焦点。"
		"\n默认: 关";
> = false;

#endif

//#endregion

//#region Textures

texture ColorTex : COLOR;

sampler Color
{
	Texture = ColorTex;

	#if MAGIC_HDR_SRGB_INPUT
		SRGBTexture = true;
	#endif
};

#define DEF_DOWNSAMPLED_TEX(name, downscale, maxMip) \
texture name##Tex <pooled = true;> \
{ \
	Width = BUFFER_WIDTH / DownsampleAmount.x / downscale; \
	Height = BUFFER_HEIGHT / DownsampleAmount.y / downscale; \
	Format = RGBA16F; \
	MipLevels = maxMip; \
}; \
\
sampler name \
{ \
	Texture = name##Tex; \
}

// This texture is used as a sort of "HDR backbuffer".
DEF_DOWNSAMPLED_TEX(Temp, 1, 1);

// These are the textures in which the many bloom LODs are stored.
DEF_DOWNSAMPLED_TEX(Bloom0, 1, 1);
DEF_DOWNSAMPLED_TEX(Bloom1, 2, 1);
DEF_DOWNSAMPLED_TEX(Bloom2, 4, 1);
DEF_DOWNSAMPLED_TEX(Bloom3, 8, 1);
DEF_DOWNSAMPLED_TEX(Bloom4, 16, 1);
DEF_DOWNSAMPLED_TEX(Bloom5, 32, 1);

#if MAGIC_HDR_ENABLE_ADAPTATION
	#if FXSHADERS_API_IS(FXSHADERS_API_OPENGL)
		#define MAGIC_HDR_ADAPT_TEXTURE_RESOLUTION \
			FXSHADERS_NPOT(FXSHADERS_MAX(BUFFER_WIDTH, BUFFER_HEIGHT) / 64)

		texture Bloom6Tex <pooled = true;>
		{
			Width = MAGIC_HDR_ADAPT_TEXTURE_RESOLUTION;
			Height = MAGIC_HDR_ADAPT_TEXTURE_RESOLUTION;
			Format = RGBA16F;
			MipLevels = FXSHADERS_GET_MAX_MIP(
				MAGIC_HDR_ADAPT_TEXTURE_RESOLUTION,
				MAGIC_HDR_ADAPT_TEXTURE_RESOLUTION);
		};

		sampler Bloom6
		{
			Texture = Bloom6Tex;
		};
	#else
		DEF_DOWNSAMPLED_TEX(
			Bloom6,
			64,
			FXSHADERS_GET_MAX_MIP(BUFFER_WIDTH / 64, BUFFER_HEIGHT / 64));
	#endif
#else
	DEF_DOWNSAMPLED_TEX(Bloom6, 64, 1);
#endif

#if MAGIC_HDR_ENABLE_ADAPTATION

texture AdaptTex <pooled = true;>
{
	Format = R32F;
};

sampler Adapt
{
	Texture = AdaptTex;
};

texture LastAdaptTex
{
	Format = R32F;
};

sampler LastAdapt
{
	Texture = LastAdaptTex;
};

#endif

//#endregion

//#region Functions


float3 ApplyInverseTonemap(float3 color, float2 uv)
{
	switch (InvTonemap)
	{
		default:
			color = Tonemap::Reinhard::Inverse(color);
			break;
		case InvTonemap_Lottes:
			color = Tonemap::Lottes::Inverse(color);
			break;
		case InvTonemap_Unreal3:
			color = Tonemap::Unreal3::Inverse(color);
			break;
		case InvTonemap_NarkowiczACES:
			color = Tonemap::NarkowiczACES::Inverse(color);
			break;
		case InvTonemap_Uncharted2Filmic:
			color = Tonemap::Uncharted2Filmic::Inverse(color);
			break;
		case InvTonemap_BakingLabACES:
			color = Tonemap::BakingLabACES::Inverse(color);
			break;
	}

	color /= exp(InputExposure);

	return color;
}

float3 ApplyTonemap(float3 color, float2 uv)
{
	#if MAGIC_HDR_ENABLE_ADAPTATION
		const float exposure = exp(Exposure) / tex2Dfetch(Adapt, 0).x;
	#else
		const float exposure = exp(Exposure);
	#endif

	switch (Tonemap)
	{
		case Tonemap_Reinhard:
			return Tonemap::Reinhard::Apply(color * exposure);
		case Tonemap_Lottes:
			return Tonemap::Lottes::Apply(color * exposure);
		case Tonemap_Unreal3:
			return Tonemap::Unreal3::Apply(color * exposure);
		case Tonemap_NarkowiczACES:
			return Tonemap::NarkowiczACES::Apply(color * exposure);
		case Tonemap_Uncharted2Filmic:
			return Tonemap::Uncharted2Filmic::Apply(color * exposure);
		default:
			return Tonemap::BakingLabACES::Apply(color * exposure);
	}
}

float4 Blur(sampler sp, float2 uv, float2 dir)
{
	float4 color = GaussianBlur1D(
		sp,
		uv,
		dir * GetPixelSize() * DownsampleAmount,
		sqrt(BlurSamples) * BlurSize,
		BlurSamples);

	return color;
}

#if MAGIC_HDR_ENABLE_ADAPTATION

float GetAdaptSensitivity()
{
	return log10(AdaptSensitivity + 1.0);
}

#endif

//#endregion

//#region Shaders

float4 InverseTonemapPS(
	float4 p : SV_POSITION,
	float2 uv : TEXCOORD) : SV_TARGET
{
	float4 color = tex2D(Color, uv);

	float saturation;
	if (BloomSaturation > 1.0)
		saturation = pow(abs(BloomSaturation), 2.0);
	else
		saturation = BloomSaturation;

	color.rgb = saturate(ApplySaturation(color.rgb, saturation));

	color.rgb = ApplyInverseTonemap(color.rgb, uv);

	// TODO: Saturation and other color filtering options?
	color.rgb *= exp(BloomBrightness);

	return color;
}

#define DEF_BLUR_SHADER(x, y, input, scale) \
float4 Blur##x##PS( \
	float4 p : SV_POSITION, \
	float2 uv : TEXCOORD) : SV_TARGET \
{ \
	return Blur(input, uv, float2(scale, 0.0)); \
} \
\
float4 Blur##y##PS( \
	float4 p : SV_POSITION, \
	float2 uv : TEXCOORD) : SV_TARGET \
{ \
	return Blur(Temp, uv, float2(0.0, scale)); \
}

DEF_BLUR_SHADER(0, 1, Bloom0, 1)
DEF_BLUR_SHADER(2, 3, Bloom0, 2)
DEF_BLUR_SHADER(4, 5, Bloom1, 4)
DEF_BLUR_SHADER(6, 7, Bloom2, 8)
DEF_BLUR_SHADER(8, 9, Bloom3, 16)
DEF_BLUR_SHADER(10, 11, Bloom4, 32)
DEF_BLUR_SHADER(12, 13, Bloom5, 64)

#if MAGIC_HDR_ENABLE_ADAPTATION

float4 CalcAdaptPS(
	float4 p : SV_POSITION,
	float2 uv : TEXCOORD) : SV_TARGET
{
	#if FXSHADERS_API_IS(FXSHADERS_API_OPENGL)
		const float mip = FXSHADERS_GET_MAX_MIP(
			MAGIC_HDR_ADAPT_TEXTURE_RESOLUTION,
			MAGIC_HDR_ADAPT_TEXTURE_RESOLUTION) *
			AdaptPrecision;
	#else
		const float mip = FXSHADERS_GET_MAX_MIP(
			BUFFER_WIDTH / 64,
			BUFFER_HEIGHT / 64) *
			AdaptPrecision;
	#endif

	float adapt = GetLumaLinear(tex2Dlod(Bloom6, float4(AdaptPoint, 0.0, mip)).rgb) * GetAdaptSensitivity();

	float2 minMax = AdaptMinMax;
	if (minMax.x > minMax.y)
		minMax = minMax.yx;

	adapt = clamp(adapt, max(minMax.x, 0.001), minMax.y);

	if (AdaptTime > 0.001)
	{
		adapt = lerp(tex2Dfetch(LastAdapt, 0).x, adapt, saturate((FrameTime * 0.001) / max(AdaptTime, 0.001)));
	}

	return adapt;
}

float4 SaveAdaptPS(
	float4 p : SV_POSITION,
	float2 uv : TEXCOORD) : SV_TARGET
{
	return tex2Dfetch(Adapt, 0);
}

#endif

float4 TonemapPS(
	float4 p : SV_POSITION,
	float2 uv : TEXCOORD) : SV_TARGET
{
	#if MAGIC_HDR_ENABLE_ADAPTATION
		if (ShowAdapt)
		{
			const float mip = FXSHADERS_GET_MAX_MIP(
				BUFFER_WIDTH / 64,
				BUFFER_HEIGHT / 64) * AdaptPrecision;

			float4 color = tex2Dlod(Bloom6, float4(uv, 0.0, mip));
			color.rgb *= GetAdaptSensitivity();

			const float2 res = GetResolution();

			float4 pointColor = float4(1.0 - color.rgb, color.a);
			if (abs(pointColor.rgb - color.rgb) < 0.1)
				pointColor.rgb = pointColor.rgb * 1.5;

			FillRect(color, uv * res, ConvertToRect(AdaptPoint * res, AdaptFocusPointDebugSize), pointColor);

			return color;
		}
	#endif

	float4 color = tex2D(Color, uv);
	color.rgb = ApplyInverseTonemap(color.rgb, uv);

	const float mean = BlendingBase * 7;
	const float variance = BlendingAmount * 7;

	const float4 bloom = (
		tex2D(Bloom0, uv) * NormalDistribution(1, mean, variance) +
		tex2D(Bloom1, uv) * NormalDistribution(2, mean, variance) +
		tex2D(Bloom2, uv) * NormalDistribution(3, mean, variance) +
		tex2D(Bloom3, uv) * NormalDistribution(4, mean, variance) +
		tex2D(Bloom4, uv) * NormalDistribution(5, mean, variance) +
		tex2D(Bloom5, uv) * NormalDistribution(6, mean, variance) +
		tex2D(Bloom6, uv) * NormalDistribution(7, mean, variance)
		) / 7;

	if (ShowBloom)
		color.rgb = bloom.rgb;
	else
		color.rgb = lerp(color.rgb, bloom.rgb, log10(BloomAmount + 1.0));

	color.rgb = ApplyTonemap(color.rgb, uv);

#if GSHADE_DITHER
	return float4(color.rgb + TriDither(color.rgb, uv, BUFFER_COLOR_BIT_DEPTH), color.a);
#else
	return color;
#endif
}

//#endregion

//#region Technique

technique MagicHDR <ui_tooltip = "FXShaders - 泛光与色调映射效果。";ui_label="魔法HDR";>
{
	pass InverseTonemap
	{
		VertexShader = ScreenVS;
		PixelShader = InverseTonemapPS;
		RenderTarget = Bloom0Tex;
	}

	#define DEF_BLUR_PASS(index, x, y) \
	pass Blur##x \
	{ \
		VertexShader = ScreenVS; \
		PixelShader = Blur##x##PS; \
		RenderTarget = TempTex; \
	} \
	pass Blur##y \
	{ \
		VertexShader = ScreenVS; \
		PixelShader = Blur##y##PS; \
		RenderTarget = Bloom##index##Tex; \
	}

	DEF_BLUR_PASS(0, 0, 1)
	DEF_BLUR_PASS(1, 2, 3)
	DEF_BLUR_PASS(2, 4, 5)
	DEF_BLUR_PASS(3, 6, 7)
	DEF_BLUR_PASS(4, 8, 9)
	DEF_BLUR_PASS(5, 10, 11)
	DEF_BLUR_PASS(6, 12, 13)

	#if MAGIC_HDR_ENABLE_ADAPTATION
		pass CalcAdapt
		{
			VertexShader = ScreenVS;
			PixelShader = CalcAdaptPS;
			RenderTarget = AdaptTex;
		}
		pass SaveAdapt
		{
			VertexShader = ScreenVS;
			PixelShader = SaveAdaptPS;
			RenderTarget = LastAdaptTex;
		}
	#endif

	pass Tonemap
	{
		VertexShader = ScreenVS;
		PixelShader = TonemapPS;

		#if MAGIC_HDR_SRGB_OUTPUT
			SRGBWriteEnable = true;
		#endif
	}
}

//#endregion

} // Namespace.
