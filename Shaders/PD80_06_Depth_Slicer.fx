/*
    Description : PD80 04 Magical Rectangle for Reshade https://reshade.me/
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
#include "PD80_00_Blend_Modes.fxh"
#include "PD80_00_Color_Spaces.fxh"

namespace pd80_depthslicer
{
    //// PREPROCESSOR DEFINITIONS ///////////////////////////////////////////////////

    //// UI ELEMENTS ////////////////////////////////////////////////////////////////
    uniform float depth_near <
        ui_type = "slider";
        ui_label = "深度近平面";
        ui_tooltip = "Depth Near Plane";
        ui_category = "深度切割器";
        ui_min = 0.0;
        ui_max = 1.0;
        > = 0.0;
    uniform float depthpos <
        ui_type = "slider";
        ui_label = "深度位置";
        ui_tooltip = "Depth Position";
        ui_category = "深度切割器";
        ui_min = 0.0;
        ui_max = 1.0;
        > = 0.015;
    uniform float depth_far <
        ui_type = "slider";
        ui_label = "深度远平面";
        ui_tooltip = "Depth Far Plane";
        ui_category = "深度切割器";
        ui_min = 0.0;
        ui_max = 1.0;
        > = 0.0;
    uniform float depth_smoothing <
        ui_type = "slider";
        ui_label = "深度平滑";
        ui_tooltip = "Depth Smoothing";
        ui_category = "深度切割器";
        ui_min = 0.0;
        ui_max = 1.0;
        > = 0.005;
    uniform float intensity <
        ui_type = "slider";
        ui_label = "亮度";
        ui_tooltip = "Lightness";
        ui_category = "深度切割器";
        ui_min = 0.0;
        ui_max = 1.0;
        > = 0.0;
    uniform float hue <
        ui_type = "slider";
        ui_label = "Hue";
        ui_tooltip = "Hue";
        ui_category = "深度切割器";
        ui_min = 0.0;
        ui_max = 1.0;
        > = 0.083;
    uniform float saturation <
        ui_type = "slider";
        ui_label = "饱和度";
        ui_tooltip = "Saturation";
        ui_category = "深度切割器";
        ui_min = 0.0;
        ui_max = 1.0;
        > = 0.0;
    uniform int blendmode_1 <
        ui_label = "混合模式";
        ui_tooltip = "Blendmode";
        ui_category = "深度切割器";
        ui_type = "combo";
        ui_items = "默认\0变暗\0相乘\0线性加深\0颜色加深\0变亮\0滤色\0颜色减淡\0线性减淡\0重叠\0柔光\0亮光\0线性光\0点光\0硬混合\0反射\0发光\0Hue\0饱和度\0颜色\0光度\0";
        > = 0;
    uniform float opacity <
        ui_type = "slider";
        ui_label = "透明度";
        ui_tooltip = "Opacity";
        ui_category = "深度切割器";
        ui_min = 0.0;
        ui_max = 1.0;
        > = 1.0;
    //// TEXTURES ///////////////////////////////////////////////////////////////////
    
    //// SAMPLERS ///////////////////////////////////////////////////////////////////

    //// DEFINES ////////////////////////////////////////////////////////////////////

    //// FUNCTIONS //////////////////////////////////////////////////////////////////

    //// PIXEL SHADERS //////////////////////////////////////////////////////////////
    float4 PS_DepthSlice(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
    {
        float4 color      = tex2D( ReShade::BackBuffer, texcoord );
        float depth       = ReShade::GetLinearizedDepth( texcoord ).x;

        float depth_np    = depthpos - depth_near;
        float depth_fp    = depthpos + depth_far;

        float dn          = smoothstep( depth_np - depth_smoothing, depth_np, depth );
        float df          = 1.0f - smoothstep( depth_fp, depth_fp + depth_smoothing, depth );
        
        float colorize    = 1.0f - ( dn * df );
        float a           = colorize;
        colorize          *= intensity;
        float3 b          = HSVToRGB( float3( hue, saturation, colorize ));
        color.xyz         = blendmode( color.xyz, b.xyz, blendmode_1, opacity * a );

        return float4( color.xyz, 1.0f );
    }

    //// TECHNIQUES /////////////////////////////////////////////////////////////////
    technique prod80_06_Depth_Slicer <ui_label="prod80 06 深度切割器";>
    {
        pass prod80_pass0
        {
            VertexShader  = PostProcessVS;
            PixelShader   = PS_DepthSlice;
        }
    }
}


