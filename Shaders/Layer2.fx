/*------------------.
| :: Description :: |
'-------------------/

    Layer (version 0.9)

    Authors: CeeJay.dk, seri14, Marot Satil, Uchu Suzume, prod80, originalnicodr
    License: MIT

    About:
    Blends an image with the game.
    The idea is to give users with graphics skills the ability to create effects using a layer just like in an image editor.
    Maybe they could use this to create custom CRT effects, custom vignettes, logos, custom hud elements, toggable help screens and crafting tables or something I haven't thought of.

    History:
    (*) Feature (+) Improvement (x) Bugfix (-) Information (!) Compatibility
    
    Version 0.2 by seri14 & Marot Satil
    * Added the ability to scale and move the layer around on an x, y axis.

    Version 0.3 by seri14
    * Reduced the problem of layer color is blending with border color

    Version 0.4 by seri14 & Marot Satil
    * Added support for the additional seri14 DLL preprocessor options to minimize loaded textures.

    Version 0.5 by Uchu Suzume & Marot Satil
    * Rotation added.

    Version 0.6 by Uchu Suzume & Marot Satil
    * Added multiple blending modes thanks to the work of Uchu Suzume, prod80, and originalnicodr.

    Version 0.7 by Uchu Suzume & Marot Satil
    * Added Addition, Subtract, Divide blending modes.

    Version 0.8 by Uchu Suzume & Marot Satil
    * Sorted blending modes in a more logical fashion, grouping by type.

    Version 0.9 by Uchu Suzume & Marot Satil
    + Implemented new Blending.fxh preprocessor macros.
*/
// Translation of the UI into Chinese by Lilidream.

#include "ReShade.fxh"
#include "Blending.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

#ifndef Layer2Tex
#define Layer2Tex "LayerStage.png" // Add your own image file to \reshade-shaders\Textures\ and provide the new file name in quotes to change the image displayed!
#endif
#ifndef LAYER2_SIZE_X
#define LAYER2_SIZE_X BUFFER_WIDTH
#endif
#ifndef LAYER2_SIZE_Y
#define LAYER2_SIZE_Y BUFFER_HEIGHT
#endif

#if LAYER2_SINGLECHANNEL
#define TEXFORMAT R8
#else
#define TEXFORMAT RGBA8
#endif

BLENDING_COMBO(Layer2_BlendMode, "混合模式", "选择应用到图层的混合模式", "", false, 0, 0)

uniform float Layer2_Blend <
    ui_text = "请在《GShade Visual Guide》查看如何使用此着色器。";
    ui_label = "混合数量";
    ui_tooltip = "应用到图层的混合数量";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.001;
> = 1.0;

uniform float Layer2_Scale <
  ui_type = "slider";
    ui_label = "X与Y缩放";
    ui_min = 0.001; ui_max = 5.0;
    ui_step = 0.001;
> = 1.001;

uniform float Layer2_ScaleX <
  ui_type = "slider";
    ui_label = "X缩放";
    ui_min = 0.001; ui_max = 5.0;
    ui_step = 0.001;
> = 1.0;

uniform float Layer2_ScaleY <
  ui_type = "slider";
    ui_label = "Y缩放";
    ui_min = 0.001; ui_max = 5.0;
    ui_step = 0.001;
> = 1.0;

uniform float Layer2_PosX <
  ui_type = "slider";
    ui_label = "X位置";
    ui_min = -2.0; ui_max = 2.0;
    ui_step = 0.001;
> = 0.5;

uniform float Layer2_PosY <
  ui_type = "slider";
    ui_label = "Y位置";
    ui_min = -2.0; ui_max = 2.0;
    ui_step = 0.001;
> = 0.5;

uniform int Layer2_SnapRotate <
    ui_type = "combo";
    ui_label = "直角选择";
    ui_items = "None\0"
               "90 度\0"
               "-90 度\0"
               "180 度\0"
               "-180 度\0";
    ui_tooltip = "以直角选择图片";
> = false;

uniform float Layer2_Rotate <
    ui_label = "旋转";
    ui_type = "slider";
    ui_min = -180.0;
    ui_max = 180.0;
    ui_step = 0.01;
> = 0;

texture Layer2_Tex <source = Layer2Tex;> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=RGBA8; };
sampler Layer2_Sampler {
    Texture = Layer2_Tex;
    AddressU = CLAMP;
    AddressV = CLAMP;
};

// -------------------------------------
// Entrypoints
// -------------------------------------

void PS_Layer2(in float4 pos : SV_Position, float2 texCoord : TEXCOORD, out float4 passColor : SV_Target) {
    const float3 pivot = float3(0.5, 0.5, 0.0);
    const float AspectX = (1.0 - BUFFER_WIDTH * (1.0 / BUFFER_HEIGHT));
    const float AspectY = (1.0 - BUFFER_HEIGHT * (1.0 / BUFFER_WIDTH));
    const float3 mulUV = float3(texCoord.x, texCoord.y, 1);
    const float2 ScaleSize = (float2(LAYER2_SIZE_X, LAYER2_SIZE_Y) * Layer2_Scale / BUFFER_SCREEN_SIZE);
    const float ScaleX =  ScaleSize.x * AspectX * Layer2_ScaleX;
    const float ScaleY =  ScaleSize.y * AspectY * Layer2_ScaleY;
    float Rotate = Layer2_Rotate * (3.1415926 / 180.0);

    switch(Layer2_SnapRotate)
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
        -Layer2_PosX, -Layer2_PosY, 1
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
    const float4 backColor = tex2D(ReShade::BackBuffer, texCoord);
    passColor = tex2D(Layer2_Sampler, SumUV.rg + pivot.rg) * all(SumUV + pivot == saturate(SumUV + pivot));

    passColor = float4(ComHeaders::Blending::Blend(Layer2_BlendMode, backColor.rgb, passColor.rgb, passColor.a * Layer2_Blend), backColor.a);

#if GSHADE_DITHER
	passColor.rgb += TriDither(passColor.rgb, texCoord, BUFFER_COLOR_BIT_DEPTH);
#endif
}

// -------------------------------------
// Techniques
// -------------------------------------

technique Layer2  <ui_label="图层2";ui_tooltip="在游戏中混合一张图片";>{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader  = PS_Layer2;
    }
}
