// Translation of the UI into Chinese by Lilidream.
//#region Includes

#include "ReShade.fxh"
#include "ColorLab.fxh"
#include "FXShadersBlending.fxh"
#include "FXShadersCommon.fxh"
#include "FXShadersConvolution.fxh"
#include "FXShadersDithering.fxh"
#include "FXShadersTonemap.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

//#endregion

//#region Macros

#ifndef NEO_BLOOM_TEXTURE_SIZE
#define NEO_BLOOM_TEXTURE_SIZE 1024
#endif

// Should be ((int)log2(NEO_BLOOM_TEXTURE_SIZE) + 1)
#ifndef NEO_BLOOM_TEXTURE_MIP_LEVELS
#define NEO_BLOOM_TEXTURE_MIP_LEVELS 11
#endif

#ifndef NEO_BLOOM_BLUR_SAMPLES
#define NEO_BLOOM_BLUR_SAMPLES 27
#endif

#ifndef NEO_BLOOM_DOWN_SCALE
#define NEO_BLOOM_DOWN_SCALE 2
#endif

#ifndef NEO_BLOOM_ADAPT
#define NEO_BLOOM_ADAPT 1
#endif

#ifndef NEO_BLOOM_DEBUG
#define NEO_BLOOM_DEBUG 0
#endif

#ifndef NEO_BLOOM_LENS_DIRT
#define NEO_BLOOM_LENS_DIRT 1
#endif

#ifndef NEO_BLOOM_LENS_DIRT_TEXTURE_NAME
#define NEO_BLOOM_LENS_DIRT_TEXTURE_NAME "SharedBloom_Dirt.png"
#endif

#ifndef NEO_BLOOM_LENS_DIRT_TEXTURE_WIDTH
#define NEO_BLOOM_LENS_DIRT_TEXTURE_WIDTH 1280
#endif

#ifndef NEO_BLOOM_LENS_DIRT_TEXTURE_HEIGHT
#define NEO_BLOOM_LENS_DIRT_TEXTURE_HEIGHT 720
#endif

#ifndef NEO_BLOOM_LENS_DIRT_ASPECT_RATIO_CORRECTION
#define NEO_BLOOM_LENS_DIRT_ASPECT_RATIO_CORRECTION 1
#endif

#ifndef NEO_BLOOM_GHOSTING
#define NEO_BLOOM_GHOSTING 1
#endif

#ifndef NEO_BLOOM_GHOSTING_DOWN_SCALE
#define NEO_BLOOM_GHOSTING_DOWN_SCALE (NEO_BLOOM_DOWN_SCALE / 4.0)
#endif

#ifndef NEO_BLOOM_DEPTH
#define NEO_BLOOM_DEPTH 1
#endif

#ifndef NEO_BLOOM_DEPTH_ANTI_FLICKER
#define NEO_BLOOM_DEPTH_ANTI_FLICKER 0
#endif

#define NEO_BLOOM_NEEDS_LAST (NEO_BLOOM_GHOSTING || NEO_BLOOM_DEPTH && NEO_BLOOM_DEPTH_ANTI_FLICKER)

#ifndef NEO_BLOOM_DITHERING
#define NEO_BLOOM_DITHERING 0
#endif

//#endregion

namespace FXShaders
{

//#region Data Types

struct BlendPassParams
{
	float4 p : SV_POSITION;
	float2 uv : TEXCOORD0;

	#if NEO_BLOOM_LENS_DIRT
		float2 lens_uv : TEXCOORD1;
	#endif
};

//#endregion

//#region Constants

// Each bloom means: (x, y, scale, miplevel).
static const int BloomCount = 5;
static const float4 BloomLevels[] =
{
	float4(0.0, 0.5, 0.5, 1),
	float4(0.5, 0.0, 0.25, 2),
	float4(0.75, 0.875, 0.125, 3),
	float4(0.875, 0.0, 0.0625, 5),
	float4(0.0, 0.0, 0.03, 7)
	//float4(0.0, 0.0, 0.03125, 9)
};
static const int MaxBloomLevel = BloomCount - 1;

static const int BlurSamples = NEO_BLOOM_BLUR_SAMPLES;

static const float2 PixelScale = 1.0;

static const float2 DirtResolution = float2(
	NEO_BLOOM_LENS_DIRT_TEXTURE_WIDTH,
	NEO_BLOOM_LENS_DIRT_TEXTURE_HEIGHT);
static const float2 DirtPixelSize = 1.0 / DirtResolution;
static const float DirtAspectRatio = DirtResolution.x * DirtPixelSize.y;
static const float DirtAspectRatioInv = 1.0 / DirtAspectRatio;

static const int DebugOption_None = 0;
static const int DebugOption_OnlyBloom = 1;
static const int DebugOptions_TextureAtlas = 2;
static const int DebugOption_Adaptation = 3;

#if NEO_BLOOM_ADAPT
	static const int DebugOption_DepthRange = 4;
#else
	static const int DebugOption_DepthRange = 3;
#endif

static const int AdaptMode_FinalImage = 0;
static const int AdaptMode_OnlyBloom = 1;

static const int BloomBlendMode_Mix = 0;
static const int BloomBlendMode_Addition = 1;
static const int BloomBlendMode_Screen = 2;

//#endregion

//#region Uniforms

// Bloom

FXSHADERS_HELP(
	"NeoBloom有很多选项，可能很难设置，或者一开始看起来很糟糕，但它的设计非常灵活，可以适应很多不同的情况。\n请务必看一看底部的预处理定义! \n对于更具体的描述，将鼠标光标移到你需要帮助的选项的名称上。\n下面是对这些功能的一般描述。\n  泛光: 用于控制泛光本身的外观的基本选项。\n  自适应: 用于根据场景动态地增加或减少图像的亮度，使之具有HDR的外观。\n看一个明亮的物体，如灯，会导致图像变暗；看一个黑暗的地方，如山洞，会导致图像变亮。\n  混合: 用于控制不同泛光纹理的混合方式，每种纹理代表不同的细节水平。\n  可以用来模拟2000年中期的老式泛光，环境光等。  \n  重影（Ghosting）: 使帧之间的泛光平滑，造成运动模糊或跟踪效果。\n  深度: 用于根据深度增加或减少图像部分的亮度。\n  可用于提高天空亮度等效果。\n有一个可选的防闪烁功能，以帮助解决游戏中的深度闪烁问题，在启用深度功能的情况下，也会导致花屏的闪烁。\n  HDR: 用于控制高动态范围模拟的选项。\n  对于模拟更多的雾状光晕很有用，就像老肥皂剧，高对比度的阳光下的外观等。\n  模糊: 控制用于生成泛光纹理的模糊效果的选项。\n  大多数情况下可以不做任何改动。\n  Debug: 启用测试选项，比如在与图像混合之前，单独查看泛光纹理。"
);

uniform float uIntensity <
	ui_label = "强度";
	ui_tooltip =
		"决定了添加多少泛光到你的画面中。对于HDR游戏，你可能需要让它保持较低，不然看起来会太亮。\n"
		"\n默认: 1.0";
	ui_category = "泛光";
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 3.0;
	ui_step = 0.001;
> = 1.0;

uniform float uSaturation <
	ui_label = "饱和度";
	ui_tooltip =
		"泛光纹理的饱和度\n"
		"\n默认: 1.0";
	ui_category = "泛光";
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 3.0;
> = 1.0;

uniform float3 ColorFilter
<
	ui_label = "颜色过滤";
	ui_tooltip =
		"颜色乘上泛光，使其过滤(泛光颜色)\n"
		"设为全白(255, 255, 255)来关闭它\n"
		"\n默认: 255 255 255";
	ui_category = "泛光";
	ui_type = "color";
> = float3(1.0, 1.0, 1.0);

uniform int BloomBlendMode
<
	ui_label = "混合模式";
	ui_tooltip =
		"决定用于混合泛光与场景颜色的公式。\n"
		"特定的混合模式可能与其他选项结合起来较差。\n"
		"作为后备方案，相加总是有效的。\n"
		"\n默认: Mix";
	ui_category = "泛光";
	ui_type = "combo";
	ui_items = "混合\0相加\0滤色\0";
> = 1;

#if NEO_BLOOM_LENS_DIRT

uniform float uLensDirtAmount <
	ui_text =
		"设置 NEO_BLOOM_DIRT 为0关闭此功能来减少资源消耗";
	ui_label = "数量";
	ui_tooltip =
		"决定添加多少镜头灰尘到泛光纹理中。\n"
		"\n默认: 0.0";
	ui_category = "镜头灰尘";
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 3.0;
> = 0.0;

#endif

#if NEO_BLOOM_ADAPT

// Adaptation

uniform int AdaptMode
<
	ui_text =
		"设置 NEO_BLOOM_ADAPT 为0关闭此功能来减少资源消耗";
	ui_label = "模式";
	ui_tooltip =
		"通过不同模式选择自适应如何被应用。\n"
		"  最终图像:\n"
		"    在画面与泛光混合后再使用自适应。\n"
		"  仅泛光:\n"
		"    在对泛光与图像混合前对泛光使用自适应。\n"
		"\n默认: 最终图像";
	ui_category = "自适应";
	ui_type = "combo";
	ui_items = "最终图像\0仅泛光\0";
> = 0;

uniform float uAdaptAmount <
	ui_label = "数量";
	ui_tooltip =
		"自适应影响画面亮度的程度。"
		"\n默认: 1.0";
	ui_category = "自适应";
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 2.0;
> = 1.0;

uniform float uAdaptSensitivity <
	ui_label = "灵敏度";
	ui_tooltip =
		"自适应对于亮点的敏感程度。"
		"\n默认: 1.0";
	ui_category = "自适应";
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 2.0;
> = 1.0;

uniform float uAdaptExposure <
	ui_label = "曝光";
	ui_tooltip =
		"决定了自适应的目标亮度。（即适应至此亮度）。\n"
		"此值由f数测量，大于0会使画面更亮，小于0会使画面更暗。\n"
		"\n默认: 0.0";
	ui_category = "自适应";
	ui_type = "slider";
	ui_min = -3.0;
	ui_max = 3.0;
> = 0.0;

uniform bool uAdaptUseLimits <
	ui_label = "使用限制";
	ui_tooltip =
		"限制自适应在最大值与最小值之间。"
		"\n默认: 开";
	ui_category = "自适应";
> = true;

uniform float2 uAdaptLimits <
	ui_label = "限制";
	ui_tooltip =
		"自适应可达到的最小值与最大值。\n"
		"增加最小值会降低图像在黑暗场景中的亮度。\n"
		"降低最大值将减少图像在明亮场景中的黑暗程度。\n"
		"\n默认: 0.0 1.0";
	ui_category = "自适应";
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 1.0;
	ui_step = 0.001;
> = float2(0.0, 1.0);

uniform float uAdaptTime <
	ui_label = "时间";
	ui_tooltip =
		"效果适应的时间。\n"
		"\n默认: 1.0";
	ui_category = "自适应";
	ui_type = "slider";
	ui_min = 0.02;
	ui_max = 3.0;
> = 1.0;

uniform float uAdaptPrecision <
	ui_label = "精确度";
	ui_tooltip =
		"自适应对于画面中心的精准程度。\n"
		"这意味着0.0将产生对整体图像亮度的适应，而更高的值将越来越多地集中在中心像素上。\n"
		"\n默认: 0.0";
	ui_category = "自适应";
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = NEO_BLOOM_TEXTURE_MIP_LEVELS;
	ui_step = 1.0;
> = 0.0;

uniform int uAdaptFormula <
	ui_label = "公式";
	ui_tooltip =
		"从颜色中提取亮度信息的公式\n"
		"\n默认: 亮度(Luma(线性))";
	ui_category = "自适应";
	ui_type = "combo";
	ui_items = "平均\0亮度(Luminance)\0亮度(Luma (Gamma))\0亮度(Luma (线性))";
> = 3;

#endif

// Blending

uniform float uMean <
	ui_label = "平均值";
	ui_tooltip =
		"作为所有泛光纹理/尺寸之间的偏差。这意味着小的值会产生更多细节泛光，反之产生大高光。\n"
		"指定的方差越大，这个设置的效果就越差，所以如果你想有非常精细的细节泛光，就减少这两个参数。\n"
		"\n默认: 0.0";
	ui_category = "混合";
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = BloomCount;
	//ui_step = 0.005;
> = 0.0;

uniform float uVariance <
	ui_label = "方差";
	ui_tooltip =
		"决定了泛光纹理/尺寸的 \"多样性\"/\"对比\"。这意味着低方差会产生更多由平均值指定的泛光尺寸；也就是说，低方差和平均值会产生更多精细的绽放。高方差将削弱平均值的效果，因为它将导致所有的泛光纹理更平等地混合。低方差和高平均值会产生类似于 \"环境光\"的效果，有大面积的光线泛光，但细节很少。"
		"\n默认: 1.0";
	ui_category = "混合";
	ui_type = "slider";
	ui_min = 1.0;
	ui_max = BloomCount;
	//ui_step = 0.005;
> = BloomCount;

#if NEO_BLOOM_GHOSTING

// Last

uniform float uGhostingAmount <
	ui_text =
		"设置 NEO_BLOOM_GHOSTING 为0关闭此功能来减少资源消耗";
	ui_label = "数量";
	ui_tooltip =
		"重影应用的数量\n"
		"\n默认: 0.0";
	ui_category = "重影";
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 0.999;
> = 0.0;

#endif

#if NEO_BLOOM_DEPTH

uniform float3 DepthMultiplier
<
	ui_text =
		"设置 NEO_BLOOM_DEPTH 为0关闭此功能来减少资源消耗";
	ui_label = "倍数";
	ui_tooltip =
		"设定应用于各个深度范围的倍数。\n"
		" - 第一个值决定近深度的倍数。\n"
		" - 第二个值决定中深度的倍数。\n"
		" - 第三个值决定远深度的倍数。\n"
		"\n默认: 1.0 1.0 1.0";
	ui_category = "深度";
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 10.0;
	ui_step = 0.01;
> = float3(1.0, 1.0, 1.0);

uniform float2 DepthRange
<
	ui_label = "范围";
	ui_tooltip =
		"设定三个深度倍数的深度范围。\n"
		" - 第一个值定义了中间深度。"
		" - 第二个值定义了中间深度的结束与远深度的开始。"
		"\n默认: 0.0 1.0";
	ui_category = "深度";
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 1.0;
	ui_step = 0.001;
> = float2(0.0, 1.0);

uniform float DepthSmoothness
<
	ui_label = "平滑";
	ui_tooltip =
		"深度范围转变的平滑程度。\n"
		"\n默认: 1.0";
	ui_category = "深度";
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 1.0;
	ui_step = 0.001;
> = 1.0;

#if NEO_BLOOM_DEPTH_ANTI_FLICKER

uniform float DepthAntiFlicker
<
	ui_label = "反闪烁数量";
	ui_tooltip =
		"应用于深度功能的反闪烁数量。\n"
		"当使用高倍数时注意到远泛光闪烁时开启。"
		"\n默认: 0.999";
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 0.999;
> = 0.999;

#endif

#endif

// HDR

uniform float uMaxBrightness <
	ui_label  = "最大亮度";
	ui_tooltip =
		"tl;dr: HDR 对比度.\n"
		" 决定一个像素在被 \"反色调映射\"时能达到的最大亮度，也就是说，当着色器试图从图像中提取HDR信息时。在实践中，100的值和1000的值之间的区别在于一个白色像素可以变得多亮/多泛光/多大，比如太阳或汽车的前灯。较低的数值也可以用于制作更 \"平衡\"的泛光，即没有那么刺眼的高光，整个场景同样是雾蒙蒙的，就像一个老电视节目或肮脏的镜头。"
		"\n默认: 100.0";
	ui_category = "高动态范围(HDR)";
	ui_type = "slider";
	ui_min = 1.0;
	ui_max = 1000.0;
	ui_step = 1.0;
> = 100.0;

uniform bool uNormalizeBrightness <
	ui_label = "亮度标准化";
	ui_tooltip =
		"当混合图像时是否标准化泛光亮度。\n"
		"没有它，泛光可能是非常刺眼的亮点。\n"
		"\n默认: On";
	ui_category = "高动态范围(HDR)";
> = true;

uniform bool MagicMode
<
	ui_label = "魔法模式";
	ui_tooltip =
		"开启时，将模拟魔法泛光(MagicBloom)的效果。\n"
		"这还是一个实验选项，可能与其他选项相冲突。\n"
		"\n默认: 关";
	ui_category = "高动态范围(HDR)";
> = false;

// Blur

uniform float uSigma <
	ui_label = "Sigma";
	ui_tooltip =
		"模糊数量，值太高会使模糊破坏(break)。\n"
		"推荐值在2至4之间。\n"
		"\n默认: 2.0";
	ui_category = "模糊";
	ui_type = "slider";
	ui_min = 1.0;
	ui_max = 10.0;
	ui_step = 0.01;
> = 4.0;

uniform float uPadding <
	ui_label = "边距";
	ui_tooltip =
		"在内部纹理图集中的泛光纹理周围指定额外的边距，在模糊处理过程中使用。\n"
		"这样做的原因是为了减少屏幕边缘的亮度损失，这是由于模糊处理的工作方式造成的。\n"
		"如果需要的话，可以将其设置为零，以有目的地减少边缘的光晕量。在增加模糊Sigma、样本 和/或 模糊缩小比例时，可能有必要增加这个参数。\n"
        "由于它的工作方式，建议将该值保持在必要的低水平，因为它将导致模糊处理在较低的分辨率下工作。\n"
		"如果你对这个参数仍然感到困惑，可以尝试用Debug模式查看纹理图集，观察增加参数后会发生什么。"
		"\n默认: 0.1";
	ui_category = "模糊";
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 10.0;
	ui_step = 0.001;
> = 0.1;

#if NEO_BLOOM_DEBUG

// Debug

uniform int uDebugOptions <
	ui_text =
		"设置 NEO_BLOOM_DEBUG 为0关闭此功能来减少资源消耗";
	ui_label = "Debug选项";
	ui_tooltip =
		"调试选项包含:   - 只显示bloom纹理。可以使用 \"显示泛光纹理 \"参数来确定要显示的泛光纹理。\n  - 显示用于模糊所有泛光纹理的原始内部纹理图集，使所有泛光的比例一次性可视化。\n"
		#if NEO_BLOOM_ADAPT
		"  - 直接显示自适应贴图。\n"
		#endif
		#if NEO_BLOOM_DEPTH
		"  - 显示深度范围纹理，以红色表示近范围，绿色表示中，蓝色表示远。\n"
		#endif
		"\n默认: 无";
	ui_category = "Debug";
	ui_type = "combo";
	ui_items =
		"无\0仅显示泛光\0显示纹理图集\0"
		#if NEO_BLOOM_ADAPT
		"显示自适应\0"
		#endif
		#if NEO_BLOOM_DEPTH
		"显示深度范围\0"
		#endif
		;
> = false;

uniform int uBloomTextureToShow <
	ui_label = "显示泛光纹理";
	ui_tooltip =
		"\"仅显示泛光\"Debug选项中哪一个泛光纹理被显示。\n"
		"设置为-1来显示所有被混合的泛光。\n"
		"\n默认: -1";
	ui_category = "Debug";
	ui_type = "slider";
	ui_min = -1;
	ui_max = MaxBloomLevel;
> = -1;

#endif

#if NEO_BLOOM_DITHERING

uniform float DitherAmount
<
	ui_type = "slider";
	ui_label = "数量";
	ui_tooltip =
		"应用到泛光的抖动数量\n"
		"\n默认: 0.1";
	ui_category = "抖动";
	ui_min = 0.0;
	ui_max = 1.0;
	ui_step = 0.001;
> = 0.1;

#endif

#if NEO_BLOOM_ADAPT

uniform float FrameTime <source = "frametime";>;

#endif

//#endregion

//#region Textures

sampler BackBuffer
{
	Texture = ReShade::BackBufferTex;
	SRGBTexture = true;
};

texture NeoBloom_DownSample <pooled="true";>
{
	Width = NEO_BLOOM_TEXTURE_SIZE;
	Height = NEO_BLOOM_TEXTURE_SIZE;
	Format = RGBA16F;
	MipLevels = NEO_BLOOM_TEXTURE_MIP_LEVELS;
};
sampler DownSample
{
	Texture = NeoBloom_DownSample;
};

texture NeoBloom_AtlasA <pooled="true";>
{
	Width = BUFFER_WIDTH / NEO_BLOOM_DOWN_SCALE;
	Height = BUFFER_HEIGHT / NEO_BLOOM_DOWN_SCALE;
	Format = RGBA16F;
};
sampler AtlasA
{
	Texture = NeoBloom_AtlasA;
	AddressU = BORDER;
	AddressV = BORDER;
};

texture NeoBloom_AtlasB <pooled="true";>
{
	Width = BUFFER_WIDTH / NEO_BLOOM_DOWN_SCALE;
	Height = BUFFER_HEIGHT / NEO_BLOOM_DOWN_SCALE;
	Format = RGBA16F;
};
sampler AtlasB
{
	Texture = NeoBloom_AtlasB;
	AddressU = BORDER;
	AddressV = BORDER;
};

#if NEO_BLOOM_ADAPT

texture NeoBloom_Adapt <pooled="true";>
{
	Format = R16F;
};
sampler Adapt
{
	Texture = NeoBloom_Adapt;
	MinFilter = POINT;
	MagFilter = POINT;
	MipFilter = POINT;
};

texture NeoBloom_LastAdapt
{
	Format = R16F;
};
sampler LastAdapt
{
	Texture = NeoBloom_LastAdapt;
	MinFilter = POINT;
	MagFilter = POINT;
	MipFilter = POINT;
};

#endif

#if NEO_BLOOM_LENS_DIRT

texture NeoBloom_LensDirt
<
	source = NEO_BLOOM_LENS_DIRT_TEXTURE_NAME;
>
{
	Width = NEO_BLOOM_LENS_DIRT_TEXTURE_WIDTH;
	Height = NEO_BLOOM_LENS_DIRT_TEXTURE_HEIGHT;
};
sampler LensDirt
{
	Texture = NeoBloom_LensDirt;
};

#endif

#if NEO_BLOOM_NEEDS_LAST

texture NeoBloom_Last
{
	Width = BUFFER_WIDTH / NEO_BLOOM_GHOSTING_DOWN_SCALE;
	Height = BUFFER_HEIGHT / NEO_BLOOM_GHOSTING_DOWN_SCALE;

	#if NEO_BLOOM_GHOSTING && NEO_BLOOM_DEPTH_ANTI_FLICKER
		Format = RGBA16F;
	#else
		Format = R8;
	#endif
};
sampler Last
{
	Texture = NeoBloom_Last;
};

#if NEO_BLOOM_DEPTH

texture NeoBloom_Depth
{
	Width = BUFFER_WIDTH;
	Height = BUFFER_HEIGHT;
	Format = R8;
};
sampler Depth
{
	Texture = NeoBloom_Depth;
};

#endif

#endif

//#endregion

//#region Functions

float3 blend_bloom(float3 color, float3 bloom)
{
	float w;
	if (uNormalizeBrightness)
		w = uIntensity / uMaxBrightness;
	else
		w = uIntensity;

	switch (BloomBlendMode)
	{
		default:
			return 0.0;
		case BloomBlendMode_Mix:
			return lerp(color, bloom, log2(w + 1.0));
		case BloomBlendMode_Addition:
			return color + bloom * w * 3.0;
		case BloomBlendMode_Screen:
			return BlendScreen(color, bloom, w);
	}
}

float3 inv_tonemap_bloom(float3 color)
{
	if (MagicMode)
		return pow(abs(color), uMaxBrightness * 0.01);

	return Tonemap::Reinhard::InverseOldLum(color, 1.0 / uMaxBrightness);
}

float3 inv_tonemap(float3 color)
{
	if (MagicMode)
		return color;

	return Tonemap::Reinhard::InverseOld(color, 1.0 / uMaxBrightness);
}

float3 tonemap(float3 color)
{
	if (MagicMode)
		return color;

	return Tonemap::Reinhard::Apply(color);
}

//#endregion

//#region Shaders

#if NEO_BLOOM_DEPTH && NEO_BLOOM_DEPTH_ANTI_FLICKER

float GetDepthPS(float4 p : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET
{
	float3 depth = ReShade::GetLinearizedDepth(uv);

	#if NEO_BLOOM_GHOSTING
		float last = tex2D(Last, uv).a;
	#else
		float last = tex2D(Last, uv).r;
	#endif

	depth = lerp(depth, last, DepthAntiFlicker);

	return depth;
}

#endif

float4 DownSamplePS(float4 p : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET
{
	float4 color = tex2D(BackBuffer, uv);
	color.rgb = saturate(ApplySaturation(color.rgb, uSaturation));
	color.rgb *= ColorFilter;
	color.rgb = inv_tonemap_bloom(color.rgb);

	#if NEO_BLOOM_DEPTH
		#if NEO_BLOOM_DEPTH_ANTI_FLICKER
			const float3 depth = tex2D(Depth, uv).x;
		#else
			const float3 depth = ReShade::GetLinearizedDepth(uv);
		#endif

		const float is_near = smoothstep(
			depth.x - DepthSmoothness.x,
			depth.x + DepthSmoothness.x,
			DepthRange.x);

		const float is_far = smoothstep(
			DepthRange.y - DepthSmoothness.x,
			DepthRange.y + DepthSmoothness.x, depth.x);

		const float is_middle = (1.0 - is_near) * (1.0 - is_far);

		color.rgb *= lerp(1.0, DepthMultiplier.x, is_near);
		color.rgb *= lerp(1.0, DepthMultiplier.y, is_middle);
		color.rgb *= lerp(1.0, DepthMultiplier.z, is_far);
	#endif

	return color;
}

float4 SplitPS(float4 p : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET
{
	float4 color = 0.0;

	[unroll]
	for (int i = 0; i < BloomCount; ++i)
	{
		float4 rect = BloomLevels[i];
		float2 rect_uv = ScaleCoord(uv - rect.xy, 1.0 / rect.z, 0.0);
		float inbounds =
			step(0.0, rect_uv.x) * step(rect_uv.x, 1.0) *
			step(0.0, rect_uv.y) * step(rect_uv.y, 1.0);

		rect_uv = ScaleCoord(rect_uv, 1.0 + uPadding * (i + 1), 0.5);

		float4 pixel = tex2Dlod(DownSample, float4(rect_uv, 0, rect.w));
		pixel.rgb *= inbounds;
		pixel.a = inbounds;

		color += pixel;
	}

	return color;
}

float4 BlurXPS(float4 p : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET
{
	return GaussianBlur1D(AtlasA, uv, PixelScale * float2(BUFFER_RCP_WIDTH, 0.0) * NEO_BLOOM_DOWN_SCALE, uSigma, BlurSamples);
}

float4 BlurYPS(float4 p : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET
{
	return GaussianBlur1D(AtlasB, uv, PixelScale * float2(0.0, BUFFER_RCP_HEIGHT) * NEO_BLOOM_DOWN_SCALE, uSigma, BlurSamples);
}

#if NEO_BLOOM_ADAPT

float4 CalcAdaptPS(float4 p : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET
{
	float3 color = tex2Dlod(
		DownSample,
		float4(0.5, 0.5, 0.0, NEO_BLOOM_TEXTURE_MIP_LEVELS - uAdaptPrecision)
	).rgb;
	color = tonemap(color);

	float gs;
	switch (uAdaptFormula)
	{
		case 0:
			gs = dot(color, 0.333);
			break;
		case 1:
			gs = max(color.r, max(color.g, color.b));
			break;
		case 2:
			gs = GetLumaGamma(color);
			break;
		case 3:
			gs = GetLumaLinear(color);
			break;
	}

	gs *= uAdaptSensitivity;

	if (uAdaptUseLimits)
		gs = clamp(gs, uAdaptLimits.x, uAdaptLimits.y);
	gs = lerp(tex2D(LastAdapt, 0.0).r, gs, saturate((FrameTime * 0.001) / max(uAdaptTime, 0.001)));

	return float4(gs, 0.0, 0.0, 1.0);
}

float4 SaveAdaptPS(float4 p : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET
{
	return tex2D(Adapt, 0.0);
}

#endif

float4 JoinBloomsPS(float4 p : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET
{
	float4 bloom = 0.0;
	float accum = 0.0;

	[unroll]
	for (int i = 0; i < BloomCount; ++i)
	{
		float4 rect = BloomLevels[i];
		float2 rect_uv = ScaleCoord(uv, 1.0 / (1.0 + uPadding * (i + 1)), 0.5);
		rect_uv = ScaleCoord(rect_uv + rect.xy / rect.z, rect.z, 0.0);

		float weight = NormalDistribution(i, uMean, uVariance);
		bloom += tex2D(AtlasA, rect_uv) * weight;
		accum += weight;
	}
	bloom /= accum;

	#if NEO_BLOOM_GHOSTING
		bloom.rgb = lerp(bloom.rgb, tex2D(Last, uv).rgb, uGhostingAmount);
	#endif

	return bloom;
}

#if NEO_BLOOM_NEEDS_LAST

float4 SaveLastBloomPS(
	float4 p : SV_POSITION,
	float2 uv : TEXCOORD
) : SV_TARGET
{
	float4 color = float4(0.0, 0.0, 0.0, 1.0);

	#if NEO_BLOOM_DEPTH && NEO_BLOOM_DEPTH_ANTI_FLICKER
		color = tex2D(Depth, uv).x;
	#endif

	#if NEO_BLOOM_GHOSTING
		color.rgb = tex2D(AtlasB, uv).rgb;
	#endif

	return color;
}

#endif

// As a workaround for a bug in the current ReShade DirectX 9 code generator,
// we have to return the parameters instead of using out.
// If we don't do that, the DirectX 9 half pixel offset bug is not automatically
// corrected by the code generator, which leads to a slightly blurry image.
BlendPassParams BlendVS(uint id : SV_VERTEXID)
{
	BlendPassParams p;

	PostProcessVS(id, p.p, p.uv);

	#if NEO_BLOOM_LENS_DIRT && NEO_BLOOM_LENS_DIRT_ASPECT_RATIO_CORRECTION
		float ar = BUFFER_WIDTH * BUFFER_RCP_HEIGHT;
		float ar_inv = BUFFER_HEIGHT * BUFFER_RCP_WIDTH;
		float is_horizontal = step(ar, DirtAspectRatio);
		float ratio = lerp(
			DirtAspectRatio * ar_inv,
			ar * DirtAspectRatioInv,
			is_horizontal);

		p.lens_uv = ScaleCoord(p.uv, float2(1.0, ratio), 0.5);
	#endif

	return p;
}

float4 BlendPS(BlendPassParams p) : SV_TARGET
{
	float2 uv = p.uv;

	float4 color = tex2D(BackBuffer, uv);
	color.rgb = inv_tonemap(color.rgb);

	#if NEO_BLOOM_GHOSTING
		float4 bloom = tex2D(AtlasB, uv);
	#else
		float4 bloom = JoinBloomsPS(p.p, uv);
	#endif

	#if NEO_BLOOM_DITHERING
		bloom.rgb = FXShaders::Dithering::Ordered16::Apply(
			bloom.rgb,
			uv,
			DitherAmount);
	#endif

	#if NEO_BLOOM_LENS_DIRT
	bloom.rgb = mad(tex2D(LensDirt, p.lens_uv).rgb, bloom.rgb * uLensDirtAmount, bloom.rgb);

	#endif

	#if NEO_BLOOM_DEBUG
		switch (DebugOptions)
		{
			case DebugOption_OnlyBloom:
				if (uBloomTextureToShow == -1)
				{
					color.rgb = tonemap(bloom.rgb);
				}
				else
				{
					float4 rect = BloomLevels[uBloomTextureToShow];
					float2 rect_uv = ScaleCoord(
						uv,
						1.0 / (1.0 + Padding * (uBloomTextureToShow + 1)),
						0.5
					);

					rect_uv = ScaleCoord(rect_uv + rect.xy / rect.z, rect.z, 0.0);
					color = tex2D(AtlasA, rect_uv);
					color.rgb = tonemap(color.rgb);
				}

				return color;
			case DebugOptions_TextureAtlas:
				color = tex2D(AtlasA, uv);
				color.rgb = lerp(checkered_pattern(uv), color.rgb, color.a);
				color.a = 1.0;

				return color;

			#if NEO_BLOOM_ADAPT
				case DebugOption_Adaptation:
					color = tex2Dlod(
						DownSample,
						float4(
							uv,
							0.0,
							NEO_BLOOM_TEXTURE_MIP_LEVELS - AdaptPrecision)
					);
					color.rgb = tonemap(color.rgb);
					return color;
			#endif

			#if NEO_BLOOM_DEPTH
				case DebugOption_DepthRange:
					#if NEO_BLOOM_DEPTH_ANTI_FLICKER
						float depth = tex2D(Depth, uv).x;
					#else
						float depth = ReShade::GetLinearizedDepth(uv);
					#endif

					color.r = smoothstep(0.0, DepthRange.x, depth);
					color.g = smoothstep(DepthRange.x, DepthRange.y, depth);
					color.b = smoothstep(DepthRange.y, 1.0, depth);

					color.r *= smoothstep(
						depth - DepthSmoothness,
						depth + DepthSmoothness,
						DepthRange.x);

					color.g *= smoothstep(
						depth - DepthSmoothness,
						depth + DepthSmoothness,
						DepthRange.y);

					return color;
			#endif
		}
	#endif

	#if NEO_BLOOM_ADAPT
		const float exposure = lerp(1.0, exp(uAdaptExposure) / max(tex2D(Adapt, 0.0).r, 0.001), uAdaptAmount);

		if (MagicMode)
		{
			bloom.rgb = Tonemap::Uncharted2Filmic::Apply(
				bloom.rgb * exposure * 0.1);
		}

		switch (AdaptMode)
		{
			case AdaptMode_FinalImage:
				color = blend_bloom(color.rgb, bloom.rgb);
				color.rgb *= exposure;
				break;
			case AdaptMode_OnlyBloom:
				bloom.rgb *= exposure;
				color = blend_bloom(color.rgb, bloom.rgb);
				break;
		}
	#else
		if (MagicMode)
			bloom.rgb = Tonemap::Uncharted2Filmic::Apply(bloom.rgb * 10.0);

		color.rgb = blend_bloom(color.rgb, bloom.rgb);
	#endif

	if (!MagicMode)
		color.rgb = tonemap(color.rgb);

#if GSHADE_DITHER
	return float4(color.rgb + TriDither(color.rgb, p.uv, BUFFER_COLOR_BIT_DEPTH), color.a);
#else
	return color;
#endif
}

//#endregion

//#region Technique

technique NeoBloom <ui_label="霓虹泛光";>
{
	#if NEO_BLOOM_DEPTH && NEO_BLOOM_DEPTH_ANTI_FLICKER
		pass GetDepth
		{
			VertexShader = PostProcessVS;
			PixelShader = GetDepthPS;
			RenderTarget = NeoBloom_Depth;
		}
	#endif

	pass DownSample
	{
		VertexShader = PostProcessVS;
		PixelShader = DownSamplePS;
		RenderTarget = NeoBloom_DownSample;
	}
	pass Split
	{
		VertexShader = PostProcessVS;
		PixelShader = SplitPS;
		RenderTarget = NeoBloom_AtlasA;
	}
	pass BlurX
	{
		VertexShader = PostProcessVS;
		PixelShader = BlurXPS;
		RenderTarget = NeoBloom_AtlasB;
	}
	pass BlurY
	{
		VertexShader = PostProcessVS;
		PixelShader = BlurYPS;
		RenderTarget = NeoBloom_AtlasA;
	}

	#if NEO_BLOOM_ADAPT
		pass CalcAdapt
		{
			VertexShader = PostProcessVS;
			PixelShader = CalcAdaptPS;
			RenderTarget = NeoBloom_Adapt;
		}
		pass SaveAdapt
		{
			VertexShader = PostProcessVS;
			PixelShader = SaveAdaptPS;
			RenderTarget = NeoBloom_LastAdapt;
		}
	#endif

	#if NEO_BLOOM_NEEDS_LAST
		pass JoinBlooms
		{
			VertexShader = PostProcessVS;
			PixelShader = JoinBloomsPS;
			RenderTarget = NeoBloom_AtlasB;
		}
		pass SaveLastBloom
		{
			VertexShader = PostProcessVS;
			PixelShader = SaveLastBloomPS;
			RenderTarget = NeoBloom_Last;
		}
	#endif

	pass Blend
	{
		VertexShader = BlendVS;
		PixelShader = BlendPS;
		SRGBWriteEnable = true;
	}
}

//#endregion

}
