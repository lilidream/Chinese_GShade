///////////////////////////////////////////////////////////////////////////////
//
//ReShade Shader: ColorfulPoster
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
//Modified by Marot Satil for ReShade 4.0 compatibility and lightly optimized for the GShade project.
// Translation of the UI into Chinese by Lilidream.

#include "ReShade.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

#define UI_CATEGORY_POSTERIZATION "色调分离"
#define UI_CATEGORY_COLOR "颜色"
#define UI_CATEGORY_EFFECT "效果"

/******************************************************************************
    Uniforms
******************************************************************************/

////////////////////////// Posterization //////////////////////////
uniform float iUILumaLevels <
    ui_type = "slider";
    ui_category = UI_CATEGORY_POSTERIZATION;
    ui_label = "亮度色调等级分类";
    ui_min = 1.0; ui_max = 20.0;
> = 16.0;

uniform int iUIStepType <
    ui_type = "combo";
    ui_category = UI_CATEGORY_POSTERIZATION;
    ui_label = "曲线类型";
    ui_items = "线性\0平滑阶梯\0对数\0S型曲线\0";
> = 2;

uniform float fUIStepContinuity <
    ui_type = "slider";
    ui_category = UI_CATEGORY_POSTERIZATION;
    ui_label = "连续性";
    ui_tooltip = "断裂 <--> 连接";
    ui_min = 0.0; ui_max = 1.0;
    ui_step = 0.01;
> = 1.0;

uniform float fUISlope <
    ui_type = "slider";
    ui_category = UI_CATEGORY_POSTERIZATION;
    ui_label = "倾斜对数曲线";
    ui_min = 0.0; ui_max = 40.0;
    ui_step = 0.1;
> = 13.0;

uniform bool iUIDebugOverlayPosterizeLevels <
    ui_category = UI_CATEGORY_POSTERIZATION;
    ui_label = "显示色调分离曲线(洋红色)";
> = 0;

////////////////////////// Color //////////////////////////

uniform float fUITint <
    ui_type = "slider";
    ui_category = UI_CATEGORY_COLOR;
    ui_label = "色调强度";
    ui_min = 0.0; ui_max = 1.0;
> = 1.0;

////////////////////////// Effect //////////////////////////

uniform float fUIStrength <
    ui_type = "slider";
    ui_category = UI_CATEGORY_EFFECT;
    ui_label = "强度";
    ui_min = 0.0; ui_max = 1.0;
> = 1.0;

/******************************************************************************
    Functions
******************************************************************************/

#define MAX_VALUE(v) max(v.x, max(v.y, v.z))

float Posterize(float x, int numLevels, float continuity, float slope, int type) {
    const float stepheight = 1.0 / numLevels;
    const float stepnum = floor(x * numLevels);
    const float frc = frac(x * numLevels);
    const float step1 = floor(frc) * stepheight;
    float step2;

    if(type == 1)
        step2 = smoothstep(0.0, 1.0, frc) * stepheight;
    else if(type == 2)
        step2 = (1.0 / (1.0 + exp(-slope*(frc - 0.5)))) * stepheight;
    else if(type == 3)
	{
		if (frc < 0.5)
			step2 = (pow(frc, slope) * pow(2.0, slope) * 0.5) * stepheight;
		else
			step2 = (1.0 - pow(1.0 - frc, slope) * pow(2.0, slope) * 0.5) * stepheight;
	}
    else
        step2 = frc * stepheight;

    return lerp(step1, step2, continuity) + stepheight * stepnum;
}

float4 RGBtoCMYK(float3 color) {
    const float K = 1.0 - max(color.r, max(color.g, color.b));
    const float3 CMY = (1.0 - color - K) / (1.0 - K);
    return float4(CMY, K);
}

float3 CMYKtoRGB(float4 cmyk) {
    return (1.0.xxx - cmyk.xyz) * (1.0 - cmyk.w);
}

float3 DrawDebugCurve(float3 background, float2 texcoord, float value, float3 color, float curveDiv) {
    const float p = exp(-(BUFFER_HEIGHT/curveDiv) * length(texcoord - float2(texcoord.x, 1.0 - value)));
    return lerp(background, color, saturate(p));
}

/******************************************************************************
    Pixel Shader
******************************************************************************/
float3 ColorfulPoster_PS(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target {
    static const float3 LumaCoeff = float3(0.2126, 0.7151, 0.0721);
    /*******************************************************
        Get BackBuffer
    *******************************************************/
    const float3 backbuffer = tex2D(ReShade::BackBuffer, texcoord).rgb;

    /*******************************************************
        Calculate chroma and luma; posterize luma
    *******************************************************/
    const float luma = dot(backbuffer, LumaCoeff);
    const float3 chroma = backbuffer - luma;
    const float3 lumaPoster = Posterize(luma, iUILumaLevels, fUIStepContinuity, fUISlope, iUIStepType).rrr;

    /*******************************************************
        Color
    *******************************************************/
    float3 mask, image, colorLayer;

    //Convert RGB to CMYK, add cyan tint, set K to 0.0
    float4 backbufferCMYK = RGBtoCMYK(backbuffer);
    backbufferCMYK.xyz += float3(0.2, -0.1, -0.2);
    backbufferCMYK.w = 0.0;

    //Convert back to RGB
    const mask = CMYKtoRGB(saturate(backbufferCMYK));
    
    //add luma to chroma
    const image = chroma + lumaPoster;

    //Blend with 'hard light'
    colorLayer = lerp(2*image*mask, 1.0 - 2.0 * (1.0 - image) * (1.0 - mask), step(0.5, luma.r));
    colorLayer = lerp(image, colorLayer, fUITint);

    /*******************************************************
        Create result
    *******************************************************/
    float3 result = lerp(backbuffer, colorLayer, fUIStrength);

    if(iUIDebugOverlayPosterizeLevels == 1) {
        const float value = Posterize(texcoord.x, iUILumaLevels, fUIStepContinuity, fUISlope, iUIStepType);
        result = DrawDebugCurve(result, texcoord, value, float3(1.0, 0.0, 1.0), 1.0);        
    }
        
    /*******************************************************
        Set overall strength and return
    *******************************************************/
#if GSHADE_DITHER
	return result + TriDither(result, texcoord, BUFFER_COLOR_BIT_DEPTH);
#else
	return result;
#endif
}

technique ColorfulPoster <ui_label = "彩色色调分离";>
{
    pass {
        VertexShader = PostProcessVS;
        PixelShader = ColorfulPoster_PS;
    }
}
