/*
  DisplayDepth by CeeJay.dk (with many updates and additions by the Reshade community)

  Visualizes the depth buffer. The distance of pixels determine their brightness.
  Close objects are dark. Far away objects are bright.
  Use this to configure the depth input preprocessor definitions (RESHADE_DEPTH_INPUT_*).
*/
// Translation of the UI into Chinese by Lilidream.

#include "ReShade.fxh"

uniform int iUIPresentType <
	ui_type = "combo";
	ui_label = "表现类型";
	ui_items = "深度映射\0"
	           "法线映射\0"
	           "同时显示(垂直50/50)\0";
> = 2;

// -- Basic options --
#if __RESHADE__ >= 40500 // If Reshade version is above or equal to 4.5
	#if RESHADE_DEPTH_INPUT_IS_UPSIDE_DOWN
		#define UPSIDE_DOWN_HELP_TEXT "RESHADE_DEPTH_INPUT_IS_UPSIDE_DOWN (Reshade深度输入颠倒)当前设置为1.\n"\
			"如果深度映射显示颠倒请设置为0。"
		#define iUIUpsideDown 1
	#else
		#define UPSIDE_DOWN_HELP_TEXT "RESHADE_DEPTH_INPUT_IS_UPSIDE_DOWN (Reshade深度输入颠倒)当前设置为0。\n"\
			"如果深度映射显示颠倒请设置为1。"
		#define iUIUpsideDown 0
	#endif
	
	#if RESHADE_DEPTH_INPUT_IS_REVERSED
		#define REVERSED_HELP_TEXT "RESHADE_DEPTH_INPUT_IS_REVERSED (Reshade深度输入颠倒)当前设置为1。\n"\
			"如果深度映射中近的物体为黑色远的物体为白色，请设置它为0。\n"\
			"如果你能看到法线，但深度是全黑的，也请设置这个试试。"
		#define iUIReversed 1
	#else
		#define REVERSED_HELP_TEXT "RESHADE_DEPTH_INPUT_IS_REVERSED (Reshade深度输入颠倒)当前设置为0。\n"\
			"如果深度映射中近的物体为白色远的物体为黑色，请设置它为1。\n"\
			"如果你能看到法线，但深度是全黑的，也请设置这个试试。"
		#define iUIReversed 0
	#endif
	
	#if RESHADE_DEPTH_INPUT_IS_LOGARITHMIC
		#define LOGARITHMIC_HELP_TEXT "RESHADE_DEPTH_INPUT_IS_LOGARITHMIC (Reshade深度输入是对数的)当前设置为1。\n"\
			"如果法线映射有带状伪影(额外的条纹)，将它设置为0。"
		#define iUILogarithmic 1
	#else
		#define LOGARITHMIC_HELP_TEXT "RESHADE_DEPTH_INPUT_IS_LOGARITHMIC (Reshade深度输入是对数的)当前设置为0。\n"\
			"如果法线映射有带状伪影(额外的条纹)，将它设置为1。"
		#define iUILogarithmic 0	
	#endif

	uniform int Depth_help <
		ui_type = "radio"; ui_label = " ";
		ui_text =
			"\n正确的设置需要在点击上面的\"编辑全局预处理定义\"按钮后打开的对话框中进行设置。"
		    "\n"
			UPSIDE_DOWN_HELP_TEXT "\n"
		    "\n"
			REVERSED_HELP_TEXT "\n"
		    "\n"
			LOGARITHMIC_HELP_TEXT;
	>;
#else // "ui_text" was introduced in ReShade 4.5, so cannot show instructions in older versions
	uniform bool bUIUseLivePreview <
		ui_label = "显示实时预览";
		ui_tooltip = "启用此功能以显示使用下面的预览设置，而不是保存的预处理设置。";
	> = true;
	
	uniform int iUIUpsideDown <
		ui_type = "combo";
		ui_label = "颠倒(预览)";
		ui_items = "RESHADE_DEPTH_INPUT_IS_UPSIDE_DOWN=0\0"
		           "RESHADE_DEPTH_INPUT_IS_UPSIDE_DOWN=1\0";
	> = RESHADE_DEPTH_INPUT_IS_UPSIDE_DOWN;
	
	uniform int iUIReversed <
		ui_type = "combo";
		ui_label = "反转(预览)";
		ui_items = "RESHADE_DEPTH_INPUT_IS_REVERSED=0\0"
		           "RESHADE_DEPTH_INPUT_IS_REVERSED=1\0";
	> = RESHADE_DEPTH_INPUT_IS_REVERSED;
	
	uniform int iUILogarithmic <
		ui_type = "combo";
		ui_label = "对数性(预览)";
		ui_items = "RESHADE_DEPTH_INPUT_IS_LOGARITHMIC=0\0"
		           "RESHADE_DEPTH_INPUT_IS_LOGARITHMIC=1\0";
		ui_tooltip = "如果物体表面显示的法线有条纹，请改变这个选项。";
	> = RESHADE_DEPTH_INPUT_IS_LOGARITHMIC;
#endif

// -- Advanced options --
#if __RESHADE__ >= 40500
uniform int Advanced_help <
	ui_category = "Advanced settings"; 
	ui_category_closed = true;
	ui_type = "radio"; ui_label = " ";
	ui_text =
		"\nThe following settings also need to be set using \"Edit global preprocessor definitions\" above in order to take effect.\n"
		"You can preview how they will affect the Depth map using the controls below.\n\n"
		"It is rarely necessary to change these though, as their defaults fit almost all games.";
	>;

	uniform bool bUIUseLivePreview <
		ui_category = "Advanced settings";
		ui_label = "Show live preview";
		ui_tooltip = "Enable this to show use the preview settings below rather than the saved preprocessor settings.";
	> = true;
#endif

uniform float2 fUIScale <
	ui_category = "Advanced settings";
	ui_type = "drag";
	ui_label = "Scale (Preview)";
	ui_tooltip = "Best use 'Present type'->'Depth map' and enable 'Offset' in the options below to set the scale.\n"
	             "Use these values for:\nRESHADE_DEPTH_INPUT_X_SCALE=<left value>\nRESHADE_DEPTH_INPUT_Y_SCALE=<right value>\n"
	             "\n"
	             "If you know the right resolution of the games depth buffer then this scale value is simply the ratio\n"
	             "between the correct resolution and the resolution Reshade thinks it is.\n"
	             "For example:\n"
	             "If it thinks the resolution is 1920 x 1080, but it's really 1280 x 720 then the right scale is (1.5 , 1.5)\n"
	             "because 1920 / 1280 is 1.5 and 1080 / 720 is also 1.5, so 1.5 is the right scale for both the x and the y";
	ui_min = 0.0; ui_max = 2.0;
	ui_step = 0.001;
> = float2(RESHADE_DEPTH_INPUT_X_SCALE, RESHADE_DEPTH_INPUT_Y_SCALE);

uniform int2 iUIOffset <
	ui_category = "Advanced settings"; 
	ui_type = "drag";
	ui_label = "Offset (Preview)";
	ui_tooltip = "Best use 'Present type'->'Depth map' and enable 'Offset' in the options below to set the offset in pixels.\n"
	             "Use these values for:\nRESHADE_DEPTH_INPUT_X_PIXEL_OFFSET=<left value>\nRESHADE_DEPTH_INPUT_Y_PIXEL_OFFSET=<right value>";
	ui_step = 1;
> = int2(RESHADE_DEPTH_INPUT_X_PIXEL_OFFSET, RESHADE_DEPTH_INPUT_Y_PIXEL_OFFSET);

uniform bool bUIShowOffset <
	ui_category = "Advanced settings";
	ui_label = "Blend Depth map into the image (to help with finding the right offset)";
> = false;

uniform float fUIFarPlane <
	ui_category = "Advanced settings"; 
	ui_type = "drag";
	ui_label = "Far Plane (Preview)";
	ui_tooltip = "RESHADE_DEPTH_LINEARIZATION_FAR_PLANE=<value>\n"
	             "Changing this value is not necessary in most cases.";
	ui_min = 0.0; ui_max = 1000.0;
	ui_step = 0.1;
> = RESHADE_DEPTH_LINEARIZATION_FAR_PLANE;

uniform float fUIDepthMultiplier <
	ui_category = "Advanced settings"; 
	ui_type = "drag";
	ui_label = "Multiplier (Preview)";
	ui_tooltip = "RESHADE_DEPTH_MULTIPLIER=<value>";
	ui_min = 0.0; ui_max = 1000.0;
	ui_step = 0.001;
> = RESHADE_DEPTH_MULTIPLIER;


float GetLinearizedDepth(float2 texcoord)
{
	if (!bUIUseLivePreview)
	{
		return ReShade::GetLinearizedDepth(texcoord);
	}
	else
	{
		if (iUIUpsideDown) // RESHADE_DEPTH_INPUT_IS_UPSIDE_DOWN
			texcoord.y = 1.0 - texcoord.y;

		texcoord.x /= fUIScale.x; // RESHADE_DEPTH_INPUT_X_SCALE
		texcoord.y /= fUIScale.y; // RESHADE_DEPTH_INPUT_Y_SCALE
		texcoord.x -= iUIOffset.x * BUFFER_RCP_WIDTH; // RESHADE_DEPTH_INPUT_X_PIXEL_OFFSET
		texcoord.y += iUIOffset.y * BUFFER_RCP_HEIGHT; // RESHADE_DEPTH_INPUT_Y_PIXEL_OFFSET

		float depth = tex2Dlod(ReShade::DepthBuffer, float4(texcoord, 0, 0)).x * fUIDepthMultiplier;

		const float C = 0.01;
		if (iUILogarithmic) // RESHADE_DEPTH_INPUT_IS_LOGARITHMIC
			depth = (exp(depth * log(C + 1.0)) - 1.0) / C;

		if (iUIReversed) // RESHADE_DEPTH_INPUT_IS_REVERSED
			depth = 1.0 - depth;

		const float N = 1.0;
		depth /= fUIFarPlane - depth * (fUIFarPlane - N);

		return depth;
	}
}

float3 GetScreenSpaceNormal(float2 texcoord)
{
	float3 offset = float3(BUFFER_PIXEL_SIZE, 0.0);
	float2 posCenter = texcoord.xy;
	float2 posNorth  = posCenter - offset.zy;
	float2 posEast   = posCenter + offset.xz;

	float3 vertCenter = float3(posCenter - 0.5, 1) * GetLinearizedDepth(posCenter);
	float3 vertNorth  = float3(posNorth - 0.5,  1) * GetLinearizedDepth(posNorth);
	float3 vertEast   = float3(posEast - 0.5,   1) * GetLinearizedDepth(posEast);

	return normalize(cross(vertCenter - vertNorth, vertCenter - vertEast)) * 0.5 + 0.5;
}

void PS_DisplayDepth(in float4 position : SV_Position, in float2 texcoord : TEXCOORD, out float3 color : SV_Target)
{
	float3 depth = GetLinearizedDepth(texcoord).xxx;
	float3 normal = GetScreenSpaceNormal(texcoord);

	// Ordered dithering
#if 1
	const float dither_bit = 8.0; // Number of bits per channel. Should be 8 for most monitors.
	// Calculate grid position
	float grid_position = frac(dot(texcoord, (BUFFER_SCREEN_SIZE * float2(1.0 / 16.0, 10.0 / 36.0)) + 0.25));
	// Calculate how big the shift should be
	float dither_shift = 0.25 * (1.0 / (pow(2, dither_bit) - 1.0));
	// Shift the individual colors differently, thus making it even harder to see the dithering pattern
	float3 dither_shift_RGB = float3(dither_shift, -dither_shift, dither_shift); // Subpixel dithering
	// Modify shift acording to grid position.
	dither_shift_RGB = lerp(2.0 * dither_shift_RGB, -2.0 * dither_shift_RGB, grid_position);
	depth += dither_shift_RGB;
#endif

	color = depth;
	if (iUIPresentType == 1)
		color = normal;
	if (iUIPresentType == 2)
		color = lerp(normal, depth, step(BUFFER_WIDTH * 0.5, position.x));

	if (bUIShowOffset)
	{
		float3 color_orig = tex2D(ReShade::BackBuffer, texcoord).rgb;

		// Blend depth and back buffer color with 'overlay' so the offset is more noticeable
		color = lerp(2 * color * color_orig, 1.0 - 2.0 * (1.0 - color) * (1.0 - color_orig), max(color.r, max(color.g, color.b)) < 0.5 ? 0.0 : 1.0);
	}
}

technique DisplayDepth <
	ui_tooltip = "这个着色器帮助你为深度输入设置正确的预处理器设置。\n"
				"要设置这些设置，请点击'Edit global preprocessor definitions'（编辑全局预处理器定义），\n"
				"并在那里进行设置-而不是在这个着色器中。然后，这些设置将对所有着色器生效，包括这个。\n"
	             "\n"
	             "默认情况下，计算的法线和深度是并排显示的。\n"
				 "法线（在左边）看起来应该是平滑的，当看地平线的时候，地面应该是绿色的。\n"
				 "深度（在右边）应该把近处的物体显示为暗色，物体越远，使用的色调就越亮。";ui_label="显示深度";
>

{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_DisplayDepth;
	}
}
