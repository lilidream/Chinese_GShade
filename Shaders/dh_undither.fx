// Translation of the UI into Chinese by Lilidream.
#include "Reshade.fxh"
#include "DH.fxh"

namespace DH {

//// uniform

	uniform int iPS <
		ui_label = "像素大小";
		ui_type = "slider";
	    ui_min = 1;
	    ui_max = 4;
	    ui_step = 1;
	> = 1;

	uniform int iRadius <
		ui_label = "半径";
		ui_type = "slider";
	    ui_min = 1;
	    ui_max = 10;
	    ui_step = 1;
	> = 3;
	
	uniform bool bKeepHue <
		ui_label = "保持源Hue";
	> = false;
	
	uniform float fHueMaxDistance <
		ui_label = "Hue最大距离";
		ui_type = "slider";
	    ui_min = 0.0;
	    ui_max = 1.0;
	    ui_step = 0.01;
	> = 0.2;

	uniform float fSatMaxDistance <
		ui_label = "饱和度最大距离";
		ui_type = "slider";
	    ui_min = 0.0;
	    ui_max = 1.0;
	    ui_step = 0.01;
	> = 0.35;

	uniform float fLumMaxDistance <
		ui_label = "亮度最大距离";
		ui_type = "slider";
	    ui_min = 0.0;
	    ui_max = 1.0;
	    ui_step = 0.01;
	> = 0.20;



//// textures

//// Functions

	float hueDistance(float3 hsl1, float3 hsl2) {
		float minH;
		float maxH;
		if(hsl1.x == hsl2.x) {
			return 0;
		}
		if(hsl1.x < hsl2.x) {
			minH = hsl1.x;
			maxH = hsl2.x;
		}
		else {
			minH = hsl1.x;
			maxH = hsl2.x;
		}

		return 2 * min(maxH - minH, 1 + minH - maxH);
	}	


//// PS

	void PS_undither(in float4 position : SV_Position, in float2 coords : TEXCOORD, out float4 outPixel : SV_Target)
	{
		const float3 hsl = RGBtoHSL(getTex2D_DH(ReShade::BackBuffer,coords).rgb);

		const float maxDist = iRadius * iRadius;
		const float2 pixelSize = getPixelSize() * iPS;

		const float2 minCoords = saturate(coords - iRadius * pixelSize);
		const float2 maxCoords = saturate(coords + iRadius * pixelSize);

		float2 currentCoords;

		float3 sumRgb;
		float sumWeight;

		for(currentCoords.x = minCoords.x; currentCoords.x <= maxCoords.x; currentCoords.x += pixelSize.x) {
			for(currentCoords.y = minCoords.y; currentCoords.y <= maxCoords.y; currentCoords.y += pixelSize.y) {
				int2 delta = (currentCoords - coords) / pixelSize;
				float posDist = dot(delta, delta);

				if(posDist > maxDist) {
					continue;
				}

				
				float3 currentRgb = getTex2D_DH(ReShade::BackBuffer, currentCoords).xyz;
				float3 currentHsl = RGBtoHSL(currentRgb);

				float satDist = abs(hsl.y - currentHsl.y);
				if(satDist > fSatMaxDistance) {
					continue;
				}
				
				float lumDist = abs(hsl.z - currentHsl.z);
				if(lumDist > fLumMaxDistance) {
					continue;
				}

				float hueDist = hueDistance(hsl, currentHsl);
				if(hueDist > fHueMaxDistance) {
					continue;
				}

				float weight = (1 - hueDist) + (1 - satDist) + (1 - lumDist) + (1 + maxDist - posDist) / (maxDist + 1);
				sumWeight += weight;
				sumRgb += weight * currentRgb;
			}
		}

		float3 resultRgb = sumRgb / sumWeight;
		if(bKeepHue) {
			float3 resultHsl = RGBtoHSL(resultRgb);
			resultHsl.x = hsl.x;
			resultRgb = HSLtoRGB(resultHsl);
		}
		outPixel = float4(resultRgb, 1.0);	
	}


//// Techniques

	technique DH_undither < ui_label="DH去抖动";
	>
	{
		pass
		{
			VertexShader = PostProcessVS;
			PixelShader = PS_undither;
		}

	}

}