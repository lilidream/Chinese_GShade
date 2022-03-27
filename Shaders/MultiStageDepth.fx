// Made by Marot Satil, seri14, & Uchu Suzume for the GShade ReShade package!
// You can follow me via @MarotSatil on Twitter, but I don't use it all that much.
// Follow @GPOSERS_FFXIV on Twitter and join us on Discord (https://discord.gg/39WpvU2)
// for the latest GShade package updates!
//
// This shader was designed in the same vein as GreenScreenDepth.fx, but instead of applying a
// green screen with adjustable distance, it applies a PNG texture with adjustable opacity.
//
// PNG transparency is fully supported, so you could for example add another moon to the sky
// just as readily as create a "green screen" stage like in real life.
//
// Textures provided by Yomigami Okami & Johnni Maestro.
// You can follow Yomi via @Yomigammy on Twitter!
//
// Copyright (c) 2019, Marot Satil
// All rights reserved.
//
// Backglow1.png, Fire1.png, Fire2.png, Lightrays1.png, Shatter1.png, Snow1.png, Snow2.png Copyright (c) 2019, Yomigami Okami
// All rights reserved.
//
// VignetteSharp.png, VignetteSoft.png (c) 2019, Johnni Maestro
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions
// are met:
// 1. Redistributions of source code must retain the above copyright
//    notice, the header above it, this list of conditions, and the following disclaimer
//    in this position and unchanged.
// 2. Redistributions in binary form must reproduce the above copyright
//    notice, the header above it, this list of conditions, and the following disclaimer in the
//    documentation and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE AUTHORS ``AS IS'' AND ANY EXPRESS OR
// IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
// OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
// IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
// NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
// THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
// Translation of the UI into Chinese by Lilidream.


#include "ReShade.fxh"
#include "Blending.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

#define MULTISTAGEDEPTH_TEX_FORMAT RGBA8

uniform int Tex_Select <
    ui_label = "贴图";
    ui_tooltip = "使用的图像";
    ui_type = "combo";
    ui_items = "Fire1.png\0Fire2.png\0Snow1.png\0Snow2.png\0Shatter1.png\0Lightrays1.png\0VignetteSharp.png\0VignetteSoft.png\0Metal1.jpg\0Ice1.jpg\0";
    ui_bind = "MultiStageDepthTexture_Source";
> = 0;

// Set default value(see above) by source code if the preset has not modified yet this variable/definition
#ifndef MultiStageDepthTexture_Source
#define MultiStageDepthTexture_Source 0
#endif

BLENDING_COMBO(Stage_BlendMode, "混合模式", "选择应用于图层的混合模式", "", false, 0, 0)

uniform float Stage_Opacity <
    ui_label = "混合";
    ui_tooltip = "应用于图层的混合数";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.002;
> = 1.0;

uniform float Stage_depth <
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_label = "深度";
> = 0.97;

uniform float Stage_Scale <
  ui_type = "slider";
    ui_label = "缩放 X 与 Y";
    ui_min = 0.001; ui_max = 5.0;
    ui_step = 0.001;
> = 1.001;

uniform float Stage_ScaleX <
  ui_type = "slider";
    ui_label = "缩放 X";
    ui_min = 0.001; ui_max = 5.0;
    ui_step = 0.001;
> = 1.0;

uniform float Stage_ScaleY <
  ui_type = "slider";
    ui_label = "缩放 Y";
    ui_min = 0.001; ui_max = 5.0;
    ui_step = 0.001;
> = 1.0;

uniform float Stage_PosX <
  ui_type = "slider";
    ui_label = "X位置";
    ui_min = -2.0; ui_max = 2.0;
    ui_step = 0.001;
> = 0.5;

uniform float Stage_PosY <
  ui_type = "slider";
    ui_label = "Y位置";
    ui_min = -2.0; ui_max = 2.0;
    ui_step = 0.001;
> = 0.5;

uniform int Stage_SnapRotate <
    ui_type = "combo";
	ui_label = "快速旋转";
    ui_items = "无\0"
               "90 度\0"
               "-90 度\0"
               "180 度\0"
               "-180 度\0";
	ui_tooltip = "快速旋转到特定角度";
> = false;

uniform float Stage_Rotate <
    ui_label = "旋转";
    ui_type = "slider";
    ui_min = -180.0;
    ui_max = 180.0;
    ui_step = 0.01;
> = 0;

uniform bool Stage_InvertDepth <
	ui_label = "反转深度";
	ui_tooltip = "反转深度缓存使贴图应用于前景。";
> = false;

#if   MultiStageDepthTexture_Source == 0 // Fire1.png
#define _SOURCE_MULTILUT_FILE "Fire1.png"
#elif MultiStageDepthTexture_Source == 1 // Fire2.png
#define _SOURCE_MULTILUT_FILE "Fire2.png"
#elif MultiStageDepthTexture_Source == 2 // Snow1.png
#define _SOURCE_MULTILUT_FILE "Snow1.png"
#elif MultiStageDepthTexture_Source == 3 // Snow2.png
#define _SOURCE_MULTILUT_FILE "Snow2.png"
#elif MultiStageDepthTexture_Source == 4 // Shatter1.png
#define _SOURCE_MULTILUT_FILE "Shatter1.png"
#elif MultiStageDepthTexture_Source == 5 // Lightrays1.png
#define _SOURCE_MULTILUT_FILE "Lightrays1.png"
#elif MultiStageDepthTexture_Source == 6 // VignetteSharp.png
#define _SOURCE_MULTILUT_FILE "VignetteSharp.png"
#elif MultiStageDepthTexture_Source == 7 // VignetteSoft.png
#define _SOURCE_MULTILUT_FILE "VignetteSoft.png"
#elif MultiStageDepthTexture_Source == 8 // Metal1.jpg
#define _SOURCE_MULTILUT_FILE "Metal1.jpg"
#elif MultiStageDepthTexture_Source == 9 // Ice1.jpg
#define _SOURCE_MULTILUT_FILE "Ice1.jpg"
#endif

texture MultiStage_texture <source = _SOURCE_MULTILUT_FILE;> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format= MULTISTAGEDEPTH_TEX_FORMAT; };
sampler MultiStage_sampler { Texture = MultiStage_texture; };

void PS_MultiStageDepth(in float4 position : SV_Position, in float2 texCoord : TEXCOORD, out float4 passColor : SV_Target)
{
    passColor = tex2D(ReShade::BackBuffer, texCoord);
    const float depth = Stage_InvertDepth ? ReShade::GetLinearizedDepth(texCoord).r : 1 - ReShade::GetLinearizedDepth(texCoord).r;

    if (depth < Stage_depth)
    {
        const float3 backColor = tex2D(ReShade::BackBuffer, texCoord).rgb;
        const float3 pivot = float3(0.5, 0.5, 0.0);
        const float AspectX = (1.0 - BUFFER_WIDTH * (1.0 / BUFFER_HEIGHT));
        const float AspectY = (1.0 - BUFFER_HEIGHT * (1.0 / BUFFER_WIDTH));
        const float3 mulUV = float3(texCoord.x, texCoord.y, 1);
        const float2 ScaleSize = (float2(BUFFER_WIDTH, BUFFER_HEIGHT) * Stage_Scale / BUFFER_SCREEN_SIZE);
        const float ScaleX =  ScaleSize.x * AspectX * Stage_ScaleX;
        const float ScaleY =  ScaleSize.y * AspectY * Stage_ScaleY;
        float Rotate = Stage_Rotate * (3.1415926 / 180.0);

        switch(Stage_SnapRotate)
        {
            default:
                break;
            case 1:
                Rotate = -90.0 * (3.1415926 / 180.0);
                break;
            case 2:
                Rotate = 90.0 * (3.1415926 / 180.0);
                break;
            case 3:
                Rotate = 0.0;
                break;
            case 4:
                Rotate = 180.0 * (3.1415926 / 180.0);
                break;
        }

        const float3x3 positionMatrix = float3x3 (
            1, 0, 0,
            0, 1, 0,
            -Stage_PosX, -Stage_PosY, 1
        );
        const float3x3 scaleMatrix = float3x3 (
            1/ScaleX, 0, 0,
            0,  1/ScaleY, 0,
            0, 0, 1
        );
        const float3x3 rotateMatrix = float3x3 (
            (cos (Rotate) * AspectX), (sin(Rotate) * AspectX), 0,
            (-sin(Rotate) * AspectY), (cos(Rotate) * AspectY), 0,
            0, 0, 1
        );

        const float3 SumUV = mul (mul (mul (mulUV, positionMatrix), rotateMatrix), scaleMatrix);
        passColor = tex2D(MultiStage_sampler, SumUV.rg + pivot.rg) * all(SumUV + pivot == saturate(SumUV + pivot));

        passColor.rgb = ComHeaders::Blending::Blend(Stage_BlendMode, backColor, passColor.rgb, passColor.a * Stage_Opacity);

#if GSHADE_DITHER
        passColor.rgb += TriDither(passColor.rgb, texCoord, BUFFER_COLOR_BIT_DEPTH);
#endif
    }
}

technique MultiStageDepth <ui_label="多级深度(深度贴图)";>
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_MultiStageDepth;
    }
}