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
// Copyright (c) 2019, Marot Satil
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

#define TEXFORMAT RGBA8

#ifndef StageTex
#define StageTex "LayerStage.png" // Add your own image file to \reshade-shaders\Textures\ and provide the new file name in quotes to change the image displayed!
#endif
#ifndef STAGE_SIZE_X
#define STAGE_SIZE_X BUFFER_WIDTH
#endif
#ifndef STAGE_SIZE_Y
#define STAGE_SIZE_Y BUFFER_HEIGHT
#endif

BLENDING_COMBO(Stage_BlendMode, "混合模式", "选择应用到图层的混合模式", "", false, 0, 0)

uniform float Stage_Opacity <
    ui_label = "混合";
    ui_tooltip = "应用到图像的混合数量";
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
    ui_label = "缩放X与Y";
    ui_min = 0.001; ui_max = 5.0;
    ui_step = 0.001;
> = 1.001;

uniform float Stage_ScaleX <
  ui_type = "slider";
    ui_label = "缩放X";
    ui_min = 0.001; ui_max = 5.0;
    ui_step = 0.001;
> = 1.0;

uniform float Stage_ScaleY <
  ui_type = "slider";
    ui_label = "缩放Y";
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
               "90 角度\0"
               "-90 角度\0"
               "180 角度\0"
               "-180 角度\0";
	ui_tooltip = "快速旋转至特定角度";
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
	ui_tooltip = "反转深度缓存，那么贴图就应用于前景";
> = false;

texture Stage_texture <source=StageTex;> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=TEXFORMAT; };

sampler Stage_sampler { Texture = Stage_texture; };

void PS_StageDepth(in float4 position : SV_Position, in float2 texCoord : TEXCOORD, out float4 passColor : SV_Target)
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
        const float2 ScaleSize = (float2(STAGE_SIZE_X, STAGE_SIZE_Y) * Stage_Scale / BUFFER_SCREEN_SIZE);
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
        passColor = tex2D(Stage_sampler, SumUV.rg + pivot.rg) * all(SumUV + pivot == saturate(SumUV + pivot));

        passColor.rgb = ComHeaders::Blending::Blend(Stage_BlendMode, backColor, passColor.rgb, passColor.a * Stage_Opacity);

#if GSHADE_DITHER
        passColor.rgb += TriDither(passColor.rgb, texCoord, BUFFER_COLOR_BIT_DEPTH);
#endif
    }
}

technique StageDepth <ui_label="深度舞台";ui_tooltip="将你自己的图像文件添加到reshade-shaders/Textures中，\n并在预处理定义的StageTex中使用引号添加你的文件名来改变显示的图像。";>
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_StageDepth;
    }
}