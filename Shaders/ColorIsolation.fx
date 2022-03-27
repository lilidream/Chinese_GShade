///////////////////////////////////////////////////////////////////////////////
//
//ReShade Shader: ColorIsolation
//https://github.com/Daodan317081/reshade-shaders
//
//BSD 3-Clause License
//
//Copyright (c) 2018-2019, Alexander Federwisch
//All rights reserved.
//
//Redistribution and use in source and binary forms, with or without
//modification, are permitted provided that the following conditions are met:
//
//* Redistributions of source code must retain the above copyright notice, this
//  list of conditions and the following disclaimer.
//
//* Redistributions in binary form must reproduce the above copyright notice,
//  this list of conditions and the following disclaimer in the documentation
//  and/or other materials provided with the distribution.
//
//* Neither the name of the copyright holder nor the names of its
//  contributors may be used to endorse or promote products derived from
//  this software without specific prior written permission.
//
//THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
//FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
//DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
//SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
//CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
//OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
//OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
///////////////////////////////////////////////////////////////////////////////
//Modified by Marot for ReShade 4.0 compatibility and lightly optimized for the GShade project.
// Translation of the UI into Chinese by Lilidream.

#include "ReShade.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

#define COLORISOLATION_CATEGORY_SETUP "Setup"
#define COLORISOLATION_CATEGORY_DEBUG "Debug"

uniform float fUITargetHue<
    ui_type = "slider";
    ui_category = COLORISOLATION_CATEGORY_SETUP;
    ui_label = "目标Hue";
    ui_tooltip = "设置想要的颜色。\n开启 \"显示Debug图层\"来可视化。";
    ui_min = 0.0; ui_max = 360.0; ui_step = 0.5;
> = 0.0;

uniform int cUIWindowFunction<
    ui_type = "combo";
    ui_category = COLORISOLATION_CATEGORY_SETUP;
    ui_label = "窗口函数";
    ui_items = "高斯\0三角\0";
> = 0;

uniform float fUIOverlap<
    ui_type = "slider";
    ui_category = COLORISOLATION_CATEGORY_SETUP;
    ui_label = "Hue覆盖";
    ui_tooltip = "改变曲线来增加或去掉与目标hue相关的颜色\n";
    ui_min = 0.001; ui_max = 2.0;
    ui_step = 0.001;
> = 0.3;

uniform float fUIWindowHeight<
    ui_type = "slider";
    ui_category = COLORISOLATION_CATEGORY_SETUP;
    ui_label = "曲线陡度";
    ui_min = 0.0; ui_max = 10.0;
    ui_step = 0.01;
> = 1.0;

uniform int iUIType<
    ui_type = "combo";
    ui_category = COLORISOLATION_CATEGORY_SETUP;
    ui_label = "分离/排除 Hue";
    ui_items = "分离\0排除\0";
> = 0;

uniform bool bUIShowDiff <
    ui_category = COLORISOLATION_CATEGORY_DEBUG;
    ui_label = "显示Hue的不同";
> = false;

uniform bool bUIShowDebugOverlay <
    ui_label = "显示Debug覆盖层";
    ui_category = COLORISOLATION_CATEGORY_DEBUG;
> = false;

uniform float2 fUIOverlayPos<
    ui_type = "slider";
    ui_category = COLORISOLATION_CATEGORY_DEBUG;
    ui_label = "覆盖层: 位置";
    ui_min = 0.0; ui_max = 1.0;
    ui_step = 0.01;
> = float2(0.0, 0.0);

uniform int2 iUIOverlaySize <
    ui_type = "slider";
    ui_category = COLORISOLATION_CATEGORY_DEBUG;
    ui_label = "覆盖层: 大小";
    ui_tooltip = "x: 宽度\nz: 高度";
    ui_min = 50; ui_max = BUFFER_WIDTH;
    ui_step = 1;
> = int2(600, 100);

uniform float fUIOverlayOpacity <
    ui_type = "slider";
    ui_category = COLORISOLATION_CATEGORY_DEBUG;
    ui_label = "覆盖层透明度";
    ui_min = 0.0; ui_max = 1.0;
    ui_step = 0.01;
> = 1.0;

//These RGB/HSV conversion functions are based on the blogpost from:
//http://lolengine.net/blog/2013/07/27/rgb-to-hsv-in-glsl
float3 RGBtoHSV(float3 c) {
    const float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);

	float4 p;
	if (c.g < c.b)
		p = float4(c.bg, K.wz);
	else
		p = float4(c.gb, K.xy);

	float4 q;
	if (c.r < p.x)
		q = float4(p.xyw, c.r);
	else
		q = float4(c.r, p.yzx);

    const float d = q.x - min(q.w, q.y);
    const float e = 1.0e-10;
    return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

float3 HSVtoRGB(float3 c) {
    const float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    const float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * lerp(K.xxx, saturate(p - K.xxx), c.y);
}

float Map(float value, float2 span_old, float2 span_new) {
	float span_old_diff;
    if (abs(span_old.y - span_old.x) < 1e-6)
		span_old_diff = 1e-6;
	else
		span_old_diff = span_old.y - span_old.x;
    return lerp(span_new.x, span_new.y, (clamp(value, span_old.x, span_old.y)-span_old.x)/(span_old_diff));
}

#define GAUSS(x,height,offset,overlap) (height * exp(-((x - offset) * (x - offset)) / (2 * overlap * overlap)))
#define TRIANGLE(x,height,offset,overlap) saturate(height * ((2 / overlap) * ((overlap / 2) - abs(x - offset))))

float CalculateValue(float x, float height, float offset, float overlap) {
    float retVal;
    //Add three curves together, two of them are moved by 1.0 to the left and to the right respectively
    //in order to account for the borders at 0.0 and 1.0
    if(cUIWindowFunction == 0) {
        //Scale overlap so the gaussian has roughly the same span as the triangle
        overlap /= 5.0;
        retVal = saturate(GAUSS(x-1.0, height, offset, overlap) + GAUSS(x, height, offset, overlap) + GAUSS(x+1.0, height, offset, overlap));
    }
    else {
        retVal = saturate(TRIANGLE(x-1.0, height, offset, overlap) + TRIANGLE(x, height, offset, overlap) + TRIANGLE(x+1.0, height, offset, overlap));
    }
    
    if(iUIType == 1)
        return 1.0 - retVal;
    
    return retVal;
}

float3 DrawDebugOverlay(float3 background, float3 param, float2 pos, int2 size, float opacity, int2 vpos, float2 texcoord) {
    float x, y, value, luma;
    float3 overlay, hsvStrip;

	const float2 overlayPos = pos * (BUFFER_SCREEN_SIZE - size);

    if(all(vpos.xy >= overlayPos) && all(vpos.xy < overlayPos + size))
    {
        x = Map(texcoord.x, float2(overlayPos.x, overlayPos.x + size.x) / BUFFER_WIDTH, float2(0.0, 1.0));
        y = Map(texcoord.y, float2(overlayPos.y, overlayPos.y + size.y) / BUFFER_HEIGHT, float2(0.0, 1.0));
        hsvStrip = HSVtoRGB(float3(x, 1.0, 1.0));
        luma = dot(hsvStrip, float3(0.2126, 0.7151, 0.0721));
        value = CalculateValue(x, param.z, param.x, 1.0 - param.y);
        overlay = lerp(luma.rrr, hsvStrip, value);
        overlay = lerp(overlay, 0.0.rrr, exp(-size.y * length(float2(x, 1.0 - y) - float2(x, value))));
        background = lerp(background, overlay, opacity);
    }

    return background;
}

float3 ColorIsolationPS(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target {
    const float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;
    const float3 luma = dot(color, float3(0.2126, 0.7151, 0.0721)).rrr;
    const float3 param = float3(fUITargetHue / 360.0, fUIOverlap, fUIWindowHeight);
    const float value = CalculateValue(RGBtoHSV(color).x, param.z, param.x, 1.0 - param.y);
    float3 retVal = lerp(luma, color, value);

    if(bUIShowDiff)
        retVal = value.rrr;
    
    if(bUIShowDebugOverlay)
    {
        retVal = DrawDebugOverlay(retVal, param, fUIOverlayPos, iUIOverlaySize, fUIOverlayOpacity, vpos.xy, texcoord);
    }

#if GSHADE_DITHER
	return retVal + TriDither(retVal, texcoord, BUFFER_COLOR_BIT_DEPTH);
#else
    return retVal;
#endif
}

technique ColorIsolation <ui_label="单色";> {
    pass {
        VertexShader = PostProcessVS;
        PixelShader = ColorIsolationPS;
        /* RenderTarget = BackBuffer */
    }
}