/*
    Simple Bi-Color Backdrop - v1.0
    by Packetdancer
*/
// Translation of the UI into Chinese by Lilidream.

#include "ReShade.fxh"

namespace pkd {

	namespace Backdrop {

		uniform float2 CFG_CHROMAEX_ORIGIN <
			ui_category = "位置";
			ui_label = "原始点";
			ui_type = "slider";
			ui_step = 0.001;
			ui_min = 0.000; ui_max = 1.000;
			ui_tooltip = "分割器所在的原点的X和Y坐标。";
		> = float2(0.5, 0.5);

		uniform float CFG_CHROMAEX_ROTATION <
			ui_category = "位置";
			ui_label = "旋转角度";
			ui_type = "slider";
			ui_step = 1;
			ui_min = 0; ui_max = 360;
			ui_tooltip = "分割器应该围绕原点旋转什么角度？";
		> = 90;

        uniform float CFG_CHROMAEX_FOREGROUND_LIMIT <
            ui_type = "slider";
            ui_tooltip = "\"前景\"应该向后延伸多远？";
            ui_label = "前景深度";
            ui_min = 0; ui_max = 1.0; ui_step = 0.01;
        > = 0.8;

		uniform float3 CFG_CHROMAEX_COLOR1 <
			ui_type = "color";
			ui_label = "颜色 1";
			ui_category = "颜色设置";
		> = float3(0.0, 0.0, 0.0);

		uniform float3 CFG_CHROMAEX_COLOR2 <
			ui_type = "color";
			ui_label = "颜色 2";
			ui_category = "颜色设置";
		> = float3(1.0, 1.0, 1.0);

		uniform bool CFG_CHROMAEX_SMOOTH_DIVIDER <
			ui_label = "抗锯齿分割器";
			ui_category = "颜色设置";
		> = true;

		float4 GetPosValues(float2 pos)
		{
            return float4(tex2D(ReShade::BackBuffer, pos).rgb, ReShade::GetLinearizedDepth(pos));
		}

	    float3 PS_ChromaEx(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target {
			if (ReShade::GetLinearizedDepth(texcoord) < CFG_CHROMAEX_FOREGROUND_LIMIT) {
				return tex2D(ReShade::BackBuffer, texcoord).rgb;
			}

			const float s = sin(radians(CFG_CHROMAEX_ROTATION));
			const float c = cos(radians(CFG_CHROMAEX_ROTATION));

			const float2 tempCoord = texcoord - CFG_CHROMAEX_ORIGIN;
			const float2 rotated = float2(tempCoord.x * c - tempCoord.y * s, tempCoord.x * s + tempCoord.y * c) + CFG_CHROMAEX_ORIGIN;

			if (CFG_CHROMAEX_SMOOTH_DIVIDER) {
				const float2 borderSize = ReShade::PixelSize * 0.5;
				if ((rotated.x >= 0.5 - borderSize.x) && (rotated.x <= 0.5 + borderSize.x)) {
					return lerp(CFG_CHROMAEX_COLOR1, CFG_CHROMAEX_COLOR2, (rotated.x - (0.5 - borderSize.x)) / (borderSize.x * 2));
				}
			}

			if (rotated.x <= 0.5) {
				return CFG_CHROMAEX_COLOR1;
			}
			else {
				return CFG_CHROMAEX_COLOR2;
			}
	    }

	    technique pkd_Backdrop <ui_label="pkd背景";>
	    {
	    	pass Backdrop {
	    		VertexShader = PostProcessVS;
	    		PixelShader = PS_ChromaEx;
	    	}
	    }
	}

}