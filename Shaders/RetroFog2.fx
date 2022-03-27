/*
    Retro Fog by luluco250

    Copyright (c) 2017 Lucas Melo

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
*/
// Lightly optimized by Marot Satil for the GShade project.
// Translation of the UI into Chinese by Lilidream.

#include "ReShade.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

//Macros//////////////////////////////////////////////////////////////////////////////////

// Used for scaling screen coordinates while keeping them centered.
#define scale(x, scale, center) ((x - center) * scale + center)

// May be faster for loops using offset coordinates
#define _tex2D(sp, uv) tex2Dlod(sp, float4(uv, 0.0, 0.0))

//Uniforms////////////////////////////////////////////////////////////////////////////////

uniform float fOpacityTwo <
    ui_label = "Opacity";
    ui_label = "透明度";
    ui_type  = "slider";
    ui_min   = 0.0;
    ui_max   = 1.0;
    ui_step  = 0.001;
> = 1.0;

uniform float3 f3ColorTwo <
    ui_label   = "雾颜色";
    ui_tooltip = "如果自动颜色开启就会失效";
    ui_type    = "color";
> = float3(0.0, 0.0, 0.0);

uniform bool bDitheringTwo <
    ui_label = "抖动";
    ui_tooltip = "启用复古的抖动模式，使雾气像《毁灭战士》等老游戏中的像素化。";
> = false;

uniform float fQuantizeTwo <
    ui_label   = "量化";
    ui_tooltip = "用于模拟缺乏色彩的情况: 8.0代表8bits，16.0代表16bits等。\n设置为0.0可以禁用量化。只有在同时启用抖动的情况下才启用。";
    ui_type    = "slider";
    ui_min     = 0.0;
    ui_max     = 255.0;
    ui_step    = 1.0;
> = 255.0;

uniform float2 f2CurveTwo <
    ui_label   = "雾曲线";
    ui_tooltip = "控制雾的对比度，使用开始/结束值来确定范围。";
    ui_type    = "slider";
    ui_min     = 0.0;
    ui_max     = 1.0;
    ui_step    = 0.001;
> = float2(0.0, 1.0);

uniform float fStartTwo <
    ui_label   = "雾开始";
    ui_tooltip = "雾中心远离镜头的距离。";
    ui_type    = "slider";
    ui_min     = 0.0;
    ui_max     = 1.0;
    ui_step    = 0.001;
> = 0.0;

uniform bool bCurvedTwo <
    ui_label = "弧形";
    ui_tooltip = "如果启用，雾气将围绕起始位置弯曲，否则它将完全是线性的，并忽略侧面的距离。";
> = true;

//Textures////////////////////////////////////////////////////////////////////////////////

sampler2D sRetroFog_BackBufferTwo {
    Texture = ReShade::BackBufferTex;
    SRGBTexture = true;
};

//Functions///////////////////////////////////////////////////////////////////////////////

float get_fog_two(float2 uv) {
    float depth = ReShade::GetLinearizedDepth(uv);

    if (bCurvedTwo) {
        depth = distance(
            float2(scale(uv.x, depth * 2.0, 0.5), depth),
            float2(0.5, fStartTwo - 0.45)
        );
    } else {
        depth = distance(depth, fStartTwo - 0.45);
    }

    return smoothstep(f2CurveTwo.x, f2CurveTwo.y, depth);
}

// Source: https://en.wikipedia.org/wiki/Ordered_dithering
int get_bayer_two(int2 i) {
    static const int bayer[8 * 8] = {
          0, 48, 12, 60,  3, 51, 15, 63,
         32, 16, 44, 28, 35, 19, 47, 31,
          8, 56,  4, 52, 11, 59,  7, 55,
         40, 24, 36, 20, 43, 27, 39, 23,
          2, 50, 14, 62,  1, 49, 13, 61,
         34, 18, 46, 30, 33, 17, 45, 29,
         10, 58,  6, 54,  9, 57,  5, 53,
         42, 26, 38, 22, 41, 25, 37, 21
    };
    return bayer[i.x + 8 * i.y];
}

// Adapted from: http://devlog-martinsh.blogspot.com.br/2011/03/glsl-dithering.html
float dither_two(float x, float2 uv) {
    x *= fOpacityTwo;

    if (fQuantizeTwo > 0.0)
        x = round(x * fQuantizeTwo) / fQuantizeTwo;
    
    const float2 index = float2(uv * BUFFER_SCREEN_SIZE) % 8;
	float limit;
	if (index.x < 8)
		limit = float(get_bayer_two(index) + 1) / 64.0;
	else
		limit = 0.0;

    if (x < limit)
        return 0.0;
    else
        return 1.0;
}

float3 get_scene_color_two(float2 uv) {
    static const int point_count = 8;
    static const float2 points[point_count] = {
        float2(0.0, 0.0),
        float2(0.0, 0.5),
        float2(0.0, 1.0),        
        float2(0.5, 0.0),
        //float2(0.5, 0.5),
        float2(0.5, 1.0),
        float2(1.0, 0.0),
        float2(1.0, 0.5),
        float2(1.0, 1.0)
    };

    float3 color = _tex2D(sRetroFog_BackBufferTwo, points[0]).rgb;
    [loop]
    for (int i = 1; i < point_count; ++i)
        color += _tex2D(sRetroFog_BackBufferTwo, points[i]).rgb;

    return color / point_count;
}

//Shaders/////////////////////////////////////////////////////////////////////////////////

void PS_RetroFogTwo(
    float4 position  : SV_POSITION,
    float2 uv        : TEXCOORD,
    out float4 color : SV_TARGET
) {
    color = tex2D(sRetroFog_BackBufferTwo, uv);
    float fog = get_fog_two(uv);
    
    if (bDitheringTwo)
        fog = dither_two(fog, uv);
    else
        fog *= fOpacityTwo;

    const float3 fog_color = f3ColorTwo;

    color.rgb = lerp(color.rgb, fog_color, fog);
#if GSHADE_DITHER
	color.rgb += TriDither(color.rgb, uv, BUFFER_COLOR_BIT_DEPTH);
#endif
}

//Technique///////////////////////////////////////////////////////////////////////////////

technique RetroFog2 <ui_label="怀旧雾2";> {
    pass {
        VertexShader = PostProcessVS;
        PixelShader  = PS_RetroFogTwo;
        SRGBWriteEnable = true;
    }
}
