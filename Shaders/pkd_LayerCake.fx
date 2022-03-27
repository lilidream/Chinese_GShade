/*
    LayerCake - v1.5
    by Packetdancer

    This shader allows you to slice apart an image and save it into separate texture buffers
    to be restored later. In practical terms, this lets you apply different shader combinations
    to different layers of the image all in a single preset.
*/
// Translation of the UI into Chinese by Lilidream.


#include "ReShade.fxh"
#include "Blending.fxh"
#include "pkd_Color.fxh"

#define LAYERCAKE_LAYER_CONFIG(label, textureName, sampleName, enableDepthVar, depthVar, blendVar, opacityVar, shouldMaskVar, colorMaskVar, colorMaskBlendVar, colorMaskInvertVar, alphaBlendVar, alphaBlendDepthVar) \
		uniform int blendVar < \
			ui_type = "combo"; \
			ui_category = label; \
			ui_label = "粘贴的混合操作"; \
			ui_items = "顶上\0变暗\0相乘\0颜色加深\0线性加深\0变亮\0滤色\0颜色减淡\0线性减淡\0相加\0反射\0发光\0覆盖\0柔光\0硬光\0亮光\0线性光\0点状光\0硬混合\0差值\0排除\0相减\0相除\0相除(备用)\0相除(Photoshop)\0颗粒融合\0颗粒提取\0Hue\0饱和度\0颜色混合\0光度\0"; \
		> = 0; \
\
		uniform bool enableDepthVar < \
			ui_category = label; \
			ui_label = "开启深度感知"; \
		> = true; \
\
		uniform float2 depthVar < \
			ui_type = "slider"; \
			ui_category = label; \
			ui_label = "深度范围"; \
			ui_min = 0.0; ui_max = 1.0; ui_step = 0.001; \
		> = float2(0.0, 1.0); \
\
		uniform float opacityVar < \
			ui_type = "slider"; \
			ui_category = label; \
			ui_label = "透明度"; \
			ui_min = 0.0; ui_max = 1.0; ui_step = 0.001; \
		> = 1.0; \
\
		uniform bool shouldMaskVar < \
			ui_category = label; \
			ui_label = "把一个颜色当作透明的？"; \
		> = false; \
\
		uniform float3 colorMaskVar < \
			ui_type = "color"; \
			ui_category = label; \
			ui_label = "遮罩颜色"; \
		> = float3(0.0, 0.0, 0.0); \
\
		uniform float colorMaskBlendVar < \
			ui_type = "slider"; \
			ui_category = label; \
			ui_label = "遮罩颜色容忍范围"; \
			ui_tooltip = "颜色与指定的差异有多大，仍然可以被掩盖？以CIE DeltaE指定。"; \
			ui_min = 0.0; ui_max = 160.0; ui_step = 0.1; \
		> = 1.0; \
\
		uniform bool colorMaskInvertVar < \
			ui_category = label; \
			ui_label = "反转颜色遮罩"; \
			ui_tooltip = "我们应该把每一种颜色都屏蔽掉吗，*除了选定的颜色？"; \
		> = false; \
\
		uniform bool alphaBlendVar < \
			ui_category = label; \
			ui_label = "半透明混合图层边缘"; \
			ui_tooltip = "图层的边缘应该是Alpha混合的，而不是一个尖锐的衰减？"; \
		> = false; \
\
		uniform float2 alphaBlendDepthVar < \
			ui_type = "slider"; \
			ui_category = label; \
			ui_label = "半透明混合深度范围"; \
			ui_tooltip = "在遮罩的深度范围内，标记完全不透明度的相对起点和终点；超出这个范围的东西将被平滑地淡化为完全透明。注意，这是相对的深度；1.0意味着 \"该层的最远点\"，而不是整个截图的最远点。"; \
			ui_min = 0.0; ui_max = 1.0; ui_step = 0.001; \
		> = float2(0.05, 0.95); \
\
		texture textureName { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; }; \
		sampler sampleName { Texture = textureName; };	 

#define LAYERCAKE_LAYER_SHADER(copyShader, pasteShader, enableDepth, depthVar, blendVar, opacityVar, maskVar, maskColorVar, maskBlendVar, maskInvertVar, alphaBlendVar, alphaBlendDepthVar, sampleLayer) \
		void copyShader(in float4 position : SV_Position, in float2 texcoord : TEXCOORD, out float4 layerColor : SV_Target) \
        { \
        	layerColor = CopyLayer(texcoord, ReShade::BackBuffer, enableDepth, depthVar, maskVar, maskColorVar, maskBlendVar, maskInvertVar, alphaBlendVar, alphaBlendDepthVar); \
        } \
\
		void pasteShader(in float4 position : SV_Position, in float2 texcoord : TEXCOORD, out float4 screenColor : SV_Target) \
		{ \
			screenColor = PasteLayer(texcoord, sampleLayer, ReShade::BackBuffer, blendVar, opacityVar); \
		}

#define LAYERCAKE_LAYER_TECHNIQUES(copyName, copyShader, pasteName, pasteShader, renderTexture, copylabel, pastelabel) \
		technique copyName <ui_label=copylabel;> \
		{ \
			pass { \
				VertexShader = PostProcessVS; \
				PixelShader = copyShader; \
				RenderTarget = renderTexture; \
			} \
		} \
\
		technique pasteName <ui_label=pastelabel;> \
		{ \
			pass { \
				VertexShader = PostProcessVS; \
				PixelShader = pasteShader; \
			} \
		}

namespace pkd 
{
	namespace LayerCake
	{
		#define LAYERCAKE_BLEND_ATOP 0
		#define LAYERCAKE_BLEND_DARKEN 1
		#define LAYERCAKE_BLEND_MULTIPLY 2
		#define LAYERCAKE_BLEND_COLORBURN 3
		#define LAYERCAKE_BLEND_LINEARBURN 4
		#define LAYERCAKE_BLEND_LIGHTEN 5
		#define LAYERCAKE_BLEND_SCREEN 6
		#define LAYERCAKE_BLEND_COLORDODGE 7
		#define LAYERCAKE_BLEND_LINEARDODGE 8
		#define LAYERCAKE_BLEND_ADDITION 9
		#define LAYERCAKE_BLEND_REFLECT 10
		#define LAYERCAKE_BLEND_GLOW 11
		#define LAYERCAKE_BLEND_OVERLAY 12
		#define LAYERCAKE_BLEND_SOFTLIGHT 13
		#define LAYERCAKE_BLEND_HARDLIGHT 14
		#define LAYERCAKE_BLEND_VIVIDLIGHT 15
		#define LAYERCAKE_BLEND_LINEARLIGHT 16
		#define LAYERCAKE_BLEND_PINLIGHT 17
		#define LAYERCAKE_BLEND_HARDMIX 18
		#define LAYERCAKE_BLEND_DIFFERENCE 19
		#define LAYERCAKE_BLEND_EXCLUSION 20
		#define LAYERCAKE_BLEND_SUBTRACT 21
		#define LAYERCAKE_BLEND_DIVIDE 22
		#define LAYERCAKE_BLEND_DIVIDEALT 23
		#define LAYERCAKE_BLEND_DIVIDEPS 24
		#define LAYERCAKE_BLEND_GRAINMERGE 25
		#define LAYERCAKE_BLEND_GRAINEXTRACT 26
		#define LAYERCAKE_BLEND_HUE 27
		#define LAYERCAKE_BLEND_SATURATION 28
		#define LAYERCAKE_BLEND_COLORBLEND 29
		#define LAYERCAKE_BLEND_LUMINOSITY 30

		// Layer1
		LAYERCAKE_LAYER_CONFIG("图层 1", Tex_Layer1, Samp_Layer1, CFG_LAYERCAKE_DEPTHENABLE_Layer1, CFG_LAYERCAKE_DEPTH_Layer1, CFG_LAYERCAKE_BLEND_Layer1, CFG_LAYERCAKE_OPACITY_Layer1, CFG_LAYERCAKE_MASKENABLE_Layer1, CFG_LAYERCAKE_MASKCOLOR_Layer1, CFG_LAYERCAKE_MASKBLEND_Layer1, CFG_LAYERCAKE_MASKINVERT_Layer1, CFG_LAYERCAKE_ALPHABLEND_Layer1, CFG_LAYERCAKE_ALPHABLEND_DEPTH_Layer1)

		// Layer2
		LAYERCAKE_LAYER_CONFIG("图层 2", Tex_Layer2, Samp_Layer2, CFG_LAYERCAKE_DEPTHENABLE_Layer2, CFG_LAYERCAKE_DEPTH_Layer2, CFG_LAYERCAKE_BLEND_Layer2, CFG_LAYERCAKE_OPACITY_Layer2, CFG_LAYERCAKE_MASKENABLE_Layer2, CFG_LAYERCAKE_MASKCOLOR_Layer2, CFG_LAYERCAKE_MASKBLEND_Layer2, CFG_LAYERCAKE_MASKINVERT_Layer2, CFG_LAYERCAKE_ALPHABLEND_Layer2, CFG_LAYERCAKE_ALPHABLEND_DEPTH_Layer2)

		// Layer3
		LAYERCAKE_LAYER_CONFIG("图层 3", Tex_Layer3, Samp_Layer3, CFG_LAYERCAKE_DEPTHENABLE_Layer3, CFG_LAYERCAKE_DEPTH_Layer3, CFG_LAYERCAKE_BLEND_Layer3, CFG_LAYERCAKE_OPACITY_Layer3, CFG_LAYERCAKE_MASKENABLE_Layer3, CFG_LAYERCAKE_MASKCOLOR_Layer3, CFG_LAYERCAKE_MASKBLEND_Layer3, CFG_LAYERCAKE_MASKINVERT_Layer3, CFG_LAYERCAKE_ALPHABLEND_Layer3, CFG_LAYERCAKE_ALPHABLEND_DEPTH_Layer3)

		// Layer4
		LAYERCAKE_LAYER_CONFIG("图层 4", Tex_Layer4, Samp_Layer4, CFG_LAYERCAKE_DEPTHENABLE_Layer4, CFG_LAYERCAKE_DEPTH_Layer4, CFG_LAYERCAKE_BLEND_Layer4, CFG_LAYERCAKE_OPACITY_Layer4, CFG_LAYERCAKE_MASKENABLE_Layer4, CFG_LAYERCAKE_MASKCOLOR_Layer4, CFG_LAYERCAKE_MASKBLEND_Layer4, CFG_LAYERCAKE_MASKINVERT_Layer4, CFG_LAYERCAKE_ALPHABLEND_Layer4, CFG_LAYERCAKE_ALPHABLEND_DEPTH_Layer4)

		float4 CopyLayer(float2 texcoord, sampler sourceSamp, bool enableDepth, float2 depthRange, bool maskEnable, float3 maskColor, float maskTolerance, bool maskInvert, bool alphaBlend, float2 alphaBlendDepth) 
		{
			// Get our base data
			const float depth = ReShade::GetLinearizedDepth(texcoord);
			float4 color = float4(tex2D(ReShade::BackBuffer, texcoord).rgb, 1.0);

			// Handle the color masking logic.
			float smoothDelta;
			if (maskEnable) {
				smoothDelta = smoothstep(0.0, maskTolerance, pkd::Color::DeltaRGB(color.rgb, maskColor));
			}
			else {
				smoothDelta = 1.0;
			}

			float maskAlpha;
			if (alphaBlend) {
				maskAlpha = smoothDelta;
			}
			else {
				maskAlpha = (smoothDelta >= 1.0) ? 1.0 : 0.0;
			}

			maskAlpha *= maskInvert ? -1.0 : 1.0;

			color.a *= maskEnable ? maskAlpha : 1.0;

			// Handle the depth blending logic
			const float relativeDepth = smoothstep(depthRange.x, depthRange.y, depth);
			const float relativeAlpha = (relativeDepth > alphaBlendDepth.y) ? (1.0 - smoothstep(alphaBlendDepth.y, 1.0, relativeDepth)) : smoothstep(0.0, alphaBlendDepth.x, relativeDepth);
			color.a *= alphaBlend ? relativeAlpha : 1.0;

			// Handle removing anything outside of our depth range
			if (enableDepth && (depth < depthRange.x || depth > depthRange.y)) {
				color.a *= 0.0;
			}

			return color;			
		}

		float3 PasteLayer(float2 texcoord, sampler sourceSamp, sampler destSamp, int operation, float opacity)
		{
			const float4 source = tex2D(sourceSamp, texcoord);
			const float4 destination = tex2D(destSamp, texcoord);
			if (source.a == 0.0) {
				return destination.rgb;
			}

			float3 result = destination.rgb;

			switch (operation)
			{
				case LAYERCAKE_BLEND_ATOP:
					result = lerp(destination.rgb, source.rgb, source.a * opacity);
					break;
				case LAYERCAKE_BLEND_DARKEN:
					result = lerp(destination.rgb, ComHeaders::Blending::Darken(destination.rgb, source.rgb), source.a * opacity);
					break;
				case LAYERCAKE_BLEND_MULTIPLY:
					result = lerp(destination.rgb, ComHeaders::Blending::Multiply(destination.rgb, source.rgb), source.a * opacity);
					break;
				case LAYERCAKE_BLEND_COLORBURN:
					result = lerp(destination.rgb, ComHeaders::Blending::ColorBurn(destination.rgb, source.rgb), source.a * opacity);
					break;
				case LAYERCAKE_BLEND_LINEARBURN:
					result = lerp(destination.rgb, ComHeaders::Blending::LinearBurn(destination.rgb, source.rgb), source.a * opacity);
					break;
				case LAYERCAKE_BLEND_LIGHTEN:
					result = lerp(destination.rgb, ComHeaders::Blending::Lighten(destination.rgb, source.rgb), source.a * opacity);
					break;				
				case LAYERCAKE_BLEND_SCREEN:
					result = lerp(destination.rgb, ComHeaders::Blending::Screen(destination.rgb, source.rgb), source.a * opacity);
					break;				
				case LAYERCAKE_BLEND_COLORDODGE:
					result = lerp(destination.rgb, ComHeaders::Blending::ColorDodge(destination.rgb, source.rgb), source.a * opacity);
					break;				
				case LAYERCAKE_BLEND_LINEARDODGE:
					result = lerp(destination.rgb, ComHeaders::Blending::LinearDodge(destination.rgb, source.rgb), source.a * opacity);
					break;				
				case LAYERCAKE_BLEND_ADDITION:
					result = lerp(destination.rgb, ComHeaders::Blending::Addition(destination.rgb, source.rgb), source.a * opacity);
					break;				
				case LAYERCAKE_BLEND_GLOW:
					result = lerp(destination.rgb, ComHeaders::Blending::Glow(destination.rgb, source.rgb), source.a * opacity);
					break;				
				case LAYERCAKE_BLEND_OVERLAY:
					result = lerp(destination.rgb, ComHeaders::Blending::Overlay(destination.rgb, source.rgb), source.a * opacity);
					break;				
				case LAYERCAKE_BLEND_SOFTLIGHT:
					result = lerp(destination.rgb, ComHeaders::Blending::SoftLight(destination.rgb, source.rgb), source.a * opacity);
					break;				
				case LAYERCAKE_BLEND_HARDLIGHT:
					result = lerp(destination.rgb, ComHeaders::Blending::HardLight(destination.rgb, source.rgb), source.a * opacity);
					break;				
				case LAYERCAKE_BLEND_VIVIDLIGHT:
					result = lerp(destination.rgb, ComHeaders::Blending::VividLight(destination.rgb, source.rgb), source.a * opacity);
					break;
				case LAYERCAKE_BLEND_LINEARLIGHT:
					result = lerp(destination.rgb, ComHeaders::Blending::LinearLight(destination.rgb, source.rgb), source.a * opacity);
					break;				
				case LAYERCAKE_BLEND_PINLIGHT:
					result = lerp(destination.rgb, ComHeaders::Blending::PinLight(destination.rgb, source.rgb), source.a * opacity);
					break;				
				case LAYERCAKE_BLEND_HARDMIX:
					result = lerp(destination.rgb, ComHeaders::Blending::HardMix(destination.rgb, source.rgb), source.a * opacity);
					break;				
				case LAYERCAKE_BLEND_DIFFERENCE:
					result = lerp(destination.rgb, ComHeaders::Blending::Difference(destination.rgb, source.rgb), source.a * opacity);
					break;				
				case LAYERCAKE_BLEND_EXCLUSION:
					result = lerp(destination.rgb, ComHeaders::Blending::Exclusion(destination.rgb, source.rgb), source.a * opacity);
					break;				
				case LAYERCAKE_BLEND_SUBTRACT:
					result = lerp(destination.rgb, ComHeaders::Blending::Subtract(destination.rgb, source.rgb), source.a * opacity);
					break;				
				case LAYERCAKE_BLEND_DIVIDE:
					result = lerp(destination.rgb, ComHeaders::Blending::Divide(destination.rgb, source.rgb), source.a * opacity);
					break;				
				case LAYERCAKE_BLEND_DIVIDEALT:
					result = lerp(destination.rgb, ComHeaders::Blending::DivideAlt(destination.rgb, source.rgb), source.a * opacity);
					break;				
				case LAYERCAKE_BLEND_DIVIDEPS:
					result = lerp(destination.rgb, ComHeaders::Blending::DividePS(destination.rgb, source.rgb), source.a * opacity);
					break;				
				case LAYERCAKE_BLEND_REFLECT:
					result = lerp(destination.rgb, ComHeaders::Blending::Reflect(destination.rgb, source.rgb), source.a * opacity);
					break;				
				case LAYERCAKE_BLEND_GRAINMERGE:
					result = lerp(destination.rgb, ComHeaders::Blending::GrainMerge(destination.rgb, source.rgb), source.a * opacity);
					break;				
				case LAYERCAKE_BLEND_GRAINEXTRACT:
					result = lerp(destination.rgb, ComHeaders::Blending::GrainExtract(destination.rgb, source.rgb), source.a * opacity);
					break;				
				case LAYERCAKE_BLEND_HUE:
					result = lerp(destination.rgb, ComHeaders::Blending::Hue(destination.rgb, source.rgb), source.a * opacity);
					break;				
				case LAYERCAKE_BLEND_SATURATION:
					result = lerp(destination.rgb, ComHeaders::Blending::Saturation(destination.rgb, source.rgb), source.a * opacity);
					break;				
				case LAYERCAKE_BLEND_COLORBLEND:
					result = lerp(destination.rgb, ComHeaders::Blending::ColorB(destination.rgb, source.rgb), source.a * opacity);
					break;				
				case LAYERCAKE_BLEND_LUMINOSITY:
					result = lerp(destination.rgb, ComHeaders::Blending::Luminosity(destination.rgb, source.rgb), source.a * opacity);
					break;				
			}

			return result;
		}

		// Layer 1
		LAYERCAKE_LAYER_SHADER(PS_Copy_Layer1, PS_Paste_Layer1, CFG_LAYERCAKE_DEPTHENABLE_Layer1, CFG_LAYERCAKE_DEPTH_Layer1, CFG_LAYERCAKE_BLEND_Layer1, CFG_LAYERCAKE_OPACITY_Layer1, CFG_LAYERCAKE_MASKENABLE_Layer1, CFG_LAYERCAKE_MASKCOLOR_Layer1, CFG_LAYERCAKE_MASKBLEND_Layer1, CFG_LAYERCAKE_MASKINVERT_Layer1, CFG_LAYERCAKE_ALPHABLEND_Layer1, CFG_LAYERCAKE_ALPHABLEND_DEPTH_Layer1, Samp_Layer1)
		LAYERCAKE_LAYER_TECHNIQUES(LayerCake_Layer1_Copy, PS_Copy_Layer1, LayerCake_Layer1_Paste, PS_Paste_Layer1, Tex_Layer1, "千层糕-图层1-复制", "千层糕-图层1-复制")

		// Layer 2
		LAYERCAKE_LAYER_SHADER(PS_Copy_Layer2, PS_Paste_Layer2, CFG_LAYERCAKE_DEPTHENABLE_Layer2, CFG_LAYERCAKE_DEPTH_Layer2, CFG_LAYERCAKE_BLEND_Layer2, CFG_LAYERCAKE_OPACITY_Layer2, CFG_LAYERCAKE_MASKENABLE_Layer2, CFG_LAYERCAKE_MASKCOLOR_Layer2, CFG_LAYERCAKE_MASKBLEND_Layer2, CFG_LAYERCAKE_MASKINVERT_Layer2, CFG_LAYERCAKE_ALPHABLEND_Layer2, CFG_LAYERCAKE_ALPHABLEND_DEPTH_Layer2, Samp_Layer2)
		LAYERCAKE_LAYER_TECHNIQUES(LayerCake_Layer2_Copy, PS_Copy_Layer2, LayerCake_Layer2_Paste, PS_Paste_Layer2, Tex_Layer2, "千层糕-图层2-复制", "千层糕-图层2-复制")

		// Layer 3
		LAYERCAKE_LAYER_SHADER(PS_Copy_Layer3, PS_Paste_Layer3, CFG_LAYERCAKE_DEPTHENABLE_Layer3, CFG_LAYERCAKE_DEPTH_Layer3, CFG_LAYERCAKE_BLEND_Layer3, CFG_LAYERCAKE_OPACITY_Layer3, CFG_LAYERCAKE_MASKENABLE_Layer3, CFG_LAYERCAKE_MASKCOLOR_Layer3, CFG_LAYERCAKE_MASKBLEND_Layer3, CFG_LAYERCAKE_MASKINVERT_Layer3, CFG_LAYERCAKE_ALPHABLEND_Layer3, CFG_LAYERCAKE_ALPHABLEND_DEPTH_Layer3, Samp_Layer3)
		LAYERCAKE_LAYER_TECHNIQUES(LayerCake_Layer3_Copy, PS_Copy_Layer3, LayerCake_Layer3_Paste, PS_Paste_Layer3, Tex_Layer3, "千层糕-图层3-复制", "千层糕-图层3-复制")

		// Layer 4
		LAYERCAKE_LAYER_SHADER(PS_Copy_Layer4, PS_Paste_Layer4, CFG_LAYERCAKE_DEPTHENABLE_Layer4, CFG_LAYERCAKE_DEPTH_Layer4, CFG_LAYERCAKE_BLEND_Layer4, CFG_LAYERCAKE_OPACITY_Layer4, CFG_LAYERCAKE_MASKENABLE_Layer4, CFG_LAYERCAKE_MASKCOLOR_Layer4, CFG_LAYERCAKE_MASKBLEND_Layer4, CFG_LAYERCAKE_MASKINVERT_Layer4, CFG_LAYERCAKE_ALPHABLEND_Layer4, CFG_LAYERCAKE_ALPHABLEND_DEPTH_Layer4, Samp_Layer4)
		LAYERCAKE_LAYER_TECHNIQUES(LayerCake_Layer4_Copy, PS_Copy_Layer4, LayerCake_Layer4_Paste, PS_Paste_Layer4, Tex_Layer4, "千层糕-图层4-复制", "千层糕-图层4-复制")
	}
}