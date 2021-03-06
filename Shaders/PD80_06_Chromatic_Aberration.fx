/*
    Description : PD80 06 Chromatic Aberration for Reshade https://reshade.me/
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

namespace pd80_ca
{
    //// UI ELEMENTS ////////////////////////////////////////////////////////////////
    uniform int CA_type <
        ui_label = "色差类型";
        ui_tooltip = "Chromatic Aberration Type";
        ui_category = "色差";
        ui_type = "combo";
        ui_items = "中心权重放射形\0中心权重经向形\0全屏放射形\0全屏经向型\0";
        > = 0;
    uniform int degrees <
        ui_type = "slider";
        ui_label = "色差偏移";
        ui_tooltip = "色差旋转偏移";
        ui_category = "色差";
        ui_min = 0;
        ui_max = 360;
        ui_step = 1;
        > = 135;
    uniform float CA <
        ui_type = "slider";
        ui_label = "色差全局宽度";
        ui_tooltip = "CA Global Width";
        ui_category = "色差";
        ui_min = -150.0f;
        ui_max = 150.0f;
        > = -12.0;
    uniform int sampleSTEPS <
        ui_type = "slider";
        ui_label = "Hue的数量";
        ui_tooltip = "Number of Hues";
        ui_category = "色差";
        ui_min = 8;
        ui_max = 96;
        ui_step = 1;
        > = 24;
    uniform float CA_strength <
        ui_type = "slider";
        ui_label = "色差强度";
        ui_tooltip = "CA Effect Strength";
        ui_category = "色差";
        ui_min = 0.0f;
        ui_max = 1.0f;
        > = 1.0;
    uniform bool show_CA <
        ui_label = "色差显示中心/暗角";
        ui_tooltip = "CA Show Center / Vignette";
        ui_category = "色差: 中心权重";
        > = false;
    uniform float3 vignetteColor <
        ui_type = "color";
        ui_label = "暗角颜色";
        ui_tooltip = "Vignette Color";
        ui_category = "色差: 中心权重";
        > = float3(0.0, 0.0, 0.0);
    uniform float CA_width <
        ui_type = "slider";
        ui_label = "色差宽度";
        ui_tooltip = "CA Width";
        ui_category = "色差: 中心权重";
        ui_min = 0.0f;
        ui_max = 5.0f;
        > = 1.0;
    uniform float CA_curve <
        ui_type = "slider";
        ui_label = "色差曲线";
        ui_tooltip = "CA Curve";
        ui_category = "色差: 中心权重";
        ui_min = 0.1f;
        ui_max = 12.0f;
        > = 1.0;
    uniform float oX <
        ui_type = "slider";
        ui_label = "色差中心(X)";
        ui_tooltip = "CA Center (X)";
        ui_category = "色差: 中心权重";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float oY <
        ui_type = "slider";
        ui_label = "色差中心(Y)";
        ui_tooltip = "CA Center (Y)";
        ui_category = "色差: 中心权重";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float CA_shapeX <
        ui_type = "slider";
        ui_label = "色差形状(X)";
        ui_tooltip = "CA Shape (X)";
        ui_category = "色差: 中心权重";
        ui_min = 0.2f;
        ui_max = 6.0f;
        > = 1.0;
    uniform float CA_shapeY <
        ui_type = "slider";
        ui_label = "色差形状(Y)";
        ui_tooltip = "CA Shape (Y)";
        ui_category = "色差: 中心权重";
        ui_min = 0.2f;
        ui_max = 6.0f;
        > = 1.0;
    uniform bool enable_depth_int <
        ui_label = "强度: 开启基于深度的调整。\n请确保你已经正确地设置了你的深度缓存。";
        ui_tooltip = "Intensity: Enable depth based adjustments";
        ui_category = "最终调整: 深度";
        > = false;
    uniform bool enable_depth_width <
        ui_label = "宽度: 开启基于深度的调整。\n请确保你已经正确地设置了你的深度缓存。";
        ui_tooltip = "Width: Enable depth based adjustments";
        ui_category = "最终调整: 深度";
        > = false;
    uniform bool display_depth <
        ui_label = "显示深度贴图";
        ui_tooltip = "Show depth texture";
        ui_category = "最终调整: 深度";
        > = false;
    uniform float depthStart <
        ui_type = "slider";
        ui_label = "改变深度开始平面";
        ui_tooltip = "Change Depth Start Plane";
        ui_category = "最终调整: 深度";
        ui_min = 0.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float depthEnd <
        ui_type = "slider";
        ui_label = "改变深度结束平面";
        ui_tooltip = "Change Depth End Plane";
        ui_category = "最终调整: 深度";
        ui_min = 0.0f;
        ui_max = 1.0f;
        > = 0.1;
    uniform float depthCurve <
        ui_label = "深度曲线调整";
        ui_tooltip = "Depth Curve Adjustment";
        ui_category = "最终调整: 深度";
        ui_type = "slider";
        ui_min = 0.05;
        ui_max = 8.0;
        > = 1.0;
    //// TEXTURES ///////////////////////////////////////////////////////////////////

    //// SAMPLERS ///////////////////////////////////////////////////////////////////
    
    //// DEFINES ////////////////////////////////////////////////////////////////////

    //// FUNCTIONS //////////////////////////////////////////////////////////////////
    float3 HUEToRGB( float H )
    {
        return saturate( float3( abs( H * 6.0f - 3.0f ) - 1.0f,
                                 2.0f - abs( H * 6.0f - 2.0f ),
                                 2.0f - abs( H * 6.0f - 4.0f )));
    }

    //// PIXEL SHADERS //////////////////////////////////////////////////////////////
    float4 PS_CA(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
    {
        float4 color      = 0.0f;
        float px          = BUFFER_RCP_WIDTH;
        float py          = BUFFER_RCP_HEIGHT;
        float aspect      = float( BUFFER_WIDTH * BUFFER_RCP_HEIGHT );
        float3 orig       = tex2D( ReShade::BackBuffer, texcoord ).xyz;
        float depth       = ReShade::GetLinearizedDepth( texcoord ).x;
        depth             = smoothstep( depthStart, depthEnd, depth );
        depth             = pow( depth, depthCurve );
        float CA_width_n  = CA_width;
        if( enable_depth_width )
            CA_width_n    *= depth;

        //float2 coords     = clamp( texcoord.xy * 2.0f - float2( oX + 1.0f, oY + 1.0f ), -1.0f, 1.0f );
        float2 coords     = texcoord.xy * 2.0f - float2( oX + 1.0f, oY + 1.0f ); // Let it ripp, and not clamp!
        float2 uv         = coords.xy;
        coords.xy         /= float2( CA_shapeX / aspect, CA_shapeY );
        float2 caintensity= length( coords.xy ) * CA_width_n;
        caintensity.y     = caintensity.x * caintensity.x + 1.0f;
        caintensity.x     = 1.0f - ( 1.0f / ( caintensity.y * caintensity.y ));
        caintensity.x     = pow( caintensity.x, CA_curve );

        int degreesY      = degrees;
        float c           = 0.0f;
        float s           = 0.0f;
        switch( CA_type )
        {
            // Radial: Y + 90 w/ multiplying with uv.xy
            case 0:
            {
                degreesY      = degrees + 90 > 360 ? degreesY = degrees + 90 - 360 : degrees + 90;
                c             = cos( radians( degrees )) * uv.x;
                s             = sin( radians( degreesY )) * uv.y;
            }
            break;
            // Longitudinal: X = Y w/o multiplying with uv.xy
            case 1:
            {
                c             = cos( radians( degrees ));
                s             = sin( radians( degreesY ));
            }
            break;
            // Full screen Radial
            case 2:
            {
                degreesY      = degrees + 90 > 360 ? degreesY = degrees + 90 - 360 : degrees + 90;
                caintensity.x = 1.0f;
                c             = cos( radians( degrees )) * uv.x;
                s             = sin( radians( degreesY )) * uv.y;
            }
            break;
            // Full screen Longitudinal
            case 3:
            {
                caintensity.x = 1.0f;
                c             = cos( radians( degrees ));
                s             = sin( radians( degreesY ));
            }
            break;
        }
        
        //Apply based on scene depth
        if( enable_depth_int )
            caintensity.x *= depth;

        float3 huecolor   = 0.0f;
        float3 temp       = 0.0f;
        float o1          = sampleSTEPS - 1.0f;
        float o2          = 0.0f;
        float3 d          = 0.0f;

        // Scale CA (hackjob!)
        float caWidth     = CA * ( max( BUFFER_WIDTH, BUFFER_HEIGHT ) / 1920.0f ); // Scaled for 1920, raising resolution in X or Y should raise scale

        float offsetX     = px * c * caintensity.x;
        float offsetY     = py * s * caintensity.x;

        for( float i = 0; i < sampleSTEPS; i++ )
        {
            huecolor.xyz  = HUEToRGB( i / sampleSTEPS );
            o2            = lerp( -caWidth, caWidth, i / o1 );
            temp.xyz      = tex2Dlod( ReShade::BackBuffer, float4(texcoord.xy + float2( o2 * offsetX, o2 * offsetY ), 0.0, 0.0)).xyz;
            color.xyz     += temp.xyz * huecolor.xyz;
            d.xyz         += huecolor.xyz;
        }
        //color.xyz         /= ( sampleSTEPS / 3.0f * 2.0f ); // Too crude and doesn't work with low sampleSTEPS ( too dim )
        color.xyz           /= dot( d.xyz, 0.333333f ); // seems so-so OK
        color.xyz           = lerp( orig.xyz, color.xyz, CA_strength );
        color.xyz           = lerp( color.xyz, vignetteColor.xyz * caintensity.x + ( 1.0f - caintensity.x ) * color.xyz, show_CA );
        color.xyz           = display_depth ? depth.xxx : color.xyz;
        return float4( color.xyz, 1.0f );
    }

    //// TECHNIQUES /////////////////////////////////////////////////////////////////
    technique prod80_06_ChromaticAberration <ui_label="prod80 06 色差";>
    {
        pass prod80_CA
        {
            VertexShader  = PostProcessVS;
            PixelShader   = PS_CA;
        }
    }
}