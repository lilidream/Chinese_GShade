/*
    Description : PD80 06 Luma Fade for Reshade https://reshade.me/
    Author      : prod80 (Bas Veth)
    License     : MIT, Copyright (c) 2020 prod80


    MIT License

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
// Translation of the UI into Chinese by Lilidream.

#include "ReShade.fxh"

namespace pd80_lumafade
{
    //// UI ELEMENTS ////////////////////////////////////////////////////////////////
    uniform float transition_speed <
        ui_type = "slider";
        ui_label = "基于时间的淡化速度";
        ui_tooltip = "Time Based Fade Speed";
        ui_category = "场景亮度自适应";
        ui_min = 0.0f;
        ui_max = 1.0f;
        > = 0.5;
    uniform float minlevel <
        ui_label = "纯暗场景等级";
        ui_tooltip = "Pure Dark Scene Level";
        ui_category = "场景亮度自适应";
        ui_type = "slider";
        ui_min = 0.0;
        ui_max = 1.0;
        > = 0.125;
    uniform float maxlevel <
        ui_label = "纯亮场景等级";
        ui_tooltip = "Pure Light Scene Level";
        ui_category = "场景亮度自适应";
        ui_type = "slider";
        ui_min = 0.0;
        ui_max = 1.0;
        > = 0.3;
    //// TEXTURES ///////////////////////////////////////////////////////////////////
    texture texLuma { Width = 256; Height = 256; Format = R16F; MipLevels = 8; };
    texture texAvgLuma { Format = R16F; };
    texture texPrevAvgLuma { Format = R16F; };
    texture texPrevColor { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };

    //// SAMPLERS ///////////////////////////////////////////////////////////////////
    sampler samplerLuma { Texture = texLuma; };
    sampler samplerAvgLuma { Texture = texAvgLuma; };
    sampler samplerPrevAvgLuma { Texture = texPrevAvgLuma; };
    sampler samplerPrevColor { Texture = texPrevColor; };

    //// DEFINES ////////////////////////////////////////////////////////////////////
    uniform float Frametime < source = "frametime"; >;

    //// FUNCTIONS //////////////////////////////////////////////////////////////////
    float interpolate( float o, float n, float factor, float ft )
    {
        return lerp( o, n, 1.0f - exp( -factor * ft ));
    }

    //// PIXEL SHADERS //////////////////////////////////////////////////////////////
    float PS_WriteLuma(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
    {
        float4 color     = tex2D( ReShade::BackBuffer, texcoord );
        return dot( color.xyz, 0.333333f );
    }

    float PS_AvgLuma(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
    {
        float luma       = tex2Dlod( samplerLuma, float4( 0.5f, 0.5f, 0, 8 )).x;
        float prevluma   = tex2D( samplerPrevAvgLuma, float2( 0.5f, 0.5f )).x;
        float factor     = transition_speed * 4.0f + 1.0f;
        return interpolate( prevluma, luma, factor, Frametime * 0.001f );
    }

    float4 PS_StorePrev(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
    {
        return tex2D( ReShade::BackBuffer, texcoord );
    }

    float PS_PrevAvgLuma(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
    {
        return tex2D( samplerAvgLuma, float2( 0.5f, 0.5f )).x;
    }

    float4 PS_LumaInterpolation(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
    {
        float4 newcol    = tex2D( ReShade::BackBuffer, texcoord );
        float4 oldcol    = tex2D( samplerPrevColor, texcoord );
        float luma       = tex2D( samplerAvgLuma, float2( 0.5f, 0.5f )).x;
        return lerp( oldcol, newcol, smoothstep( minlevel, maxlevel, luma ));
    }

    //// TECHNIQUES /////////////////////////////////////////////////////////////////
    technique prod80_06_LumaFade_Start
    < ui_tooltip = "亮度淡化效果\n\n"
			       "这个着色器允许你根据场景的亮度来淡入和淡出ReShade效果。\n使用方法: 在一个明亮的场景中，把开始着色器放在你想启用的着色器之前，把结束着色器放在这些着色器之后。\n然后使用用户界面设置来操纵渐变。";ui_label="prod80 06 亮度淡化-开始";>
    {
        pass Luma
        {
            VertexShader   = PostProcessVS;
            PixelShader    = PS_WriteLuma;
            RenderTarget   = texLuma;
        }
        pass AvgLuma
        {
            VertexShader   = PostProcessVS;
            PixelShader    = PS_AvgLuma;
            RenderTarget   = texAvgLuma;
        }
        pass StoreColor
        {
            VertexShader   = PostProcessVS;
            PixelShader    = PS_StorePrev;
            RenderTarget   = texPrevColor;
        }
        pass PreviousLuma
        {
            VertexShader   = PostProcessVS;
            PixelShader    = PS_PrevAvgLuma;
            RenderTarget   = texPrevAvgLuma;
        }
    }
    technique prod80_06_LumaFade_End <ui_label="prod80 06 亮度淡化-结束";>
    {
        pass Combine
        {
            VertexShader   = PostProcessVS;
            PixelShader    = PS_LumaInterpolation;
        }
    }
}