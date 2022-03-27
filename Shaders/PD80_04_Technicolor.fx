/*
    Description : PD80 04 Technicolor for Reshade https://reshade.me/
    Author      : prod80 (Bas Veth)
    License     : MIT, Copyright (c) 2020 prod80

    Additional credits
    - Using Hue Shift algorythm from Vibhore Tanwer (stockexchange)
      No particular reason, just found it interesting

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

namespace pd80_technicolor
{

    //// UI ELEMENTS ////////////////////////////////////////////////////////////////
    uniform float3 Red2strip <
        ui_type = "color";
        ui_label = "红色染色颜色";
        ui_tooltip = "用于创建青色的红色(同时代的)";
        ui_category = "彩色印片2 条纹";
        > = float3(1.0, 0.098, 0.0);
    uniform float3 Cyan2strip <
        ui_type = "color";
        ui_label = "青色染色颜色";
        ui_tooltip = "用于创建红色的青色(同时代的)";
        ui_category = "彩色印片 2 条纹";
        > = float3(0.0, 0.988, 1.0);
    uniform float3 colorKey <
        ui_type = "color";
        ui_label = "时髦颜色调整";
        ui_tooltip = "第三层的乐趣，较低的数值会增加对比度";
        ui_category = "彩色印片 2 条纹";
        > = float3(1.0, 1.0, 1.0);
    uniform float Saturation2 < 
        ui_min = 1.0;
        ui_max = 2.0;
        ui_type = "slider";
        ui_label = "饱和度调整";
        ui_tooltip = "额外的饱和度控制，因为2条纹过程本身的饱和度不高";
        ui_category = "彩色印片 2 条纹";
        > = 1.5;
    uniform bool enable3strip <
        ui_label = "开启彩色印片 3 条纹";
        ui_tooltip = "开启彩色印片 3 条纹";
        ui_category = "彩色印片 3 条纹";
        > = false;
    uniform float3 ColorStrength <
        ui_label = "颜色强度";
        ui_type = "color";
        ui_tooltip = "越高意味着颜色越深、越浓.";
        ui_category = "彩色印片 3 条纹";
        > = float3(0.2, 0.2, 0.2);
    uniform float Brightness < 
        ui_type = "slider";
        ui_label = "亮度调整";
        ui_min = 0.5;
        ui_max = 1.5;
        ui_tooltip = "越高意味着图像越亮";
        ui_category = "彩色印片 3 条纹";
        > = 1.0;
    uniform float Saturation <
        ui_type = "slider";
        ui_label = "饱和度调整";
        ui_min = 0.0;
        ui_max = 1.5;
        ui_tooltip = "额外的饱和度控制，由于效果常趋于形成过饱和。";
        ui_category = "彩色印片 3 条纹";
        > = 1.0;
    uniform float Strength <
        ui_type = "slider";
        ui_label = "效果强度";
        ui_min = 0.0;
        ui_max = 1.0;
        ui_tooltip = "调整效果的强度";
        ui_category = "彩色印片 3 条纹";
        > = 1.0;

    //// TEXTURES ///////////////////////////////////////////////////////////////////
    
    //// SAMPLERS ///////////////////////////////////////////////////////////////////

    //// DEFINES ////////////////////////////////////////////////////////////////////

    //// FUNCTIONS //////////////////////////////////////////////////////////////////
    float getLuminance( in float3 x )
    {
        return dot( x, float3( 0.212656f, 0.715158f, 0.072186f ));
    }

    // Code from Vibhore Tanwer
    float3x3 QuaternionToMatrix( float4 quat )
    {
        float3 cross = quat.yzx * quat.zxy;
        float3 square= quat.xyz * quat.xyz;
        float3 wimag = quat.w * quat.xyz;

        square = square.xyz + square.yzx;

        float3 diag = 0.5f - square;
        float3 a = (cross + wimag);
        float3 b = (cross - wimag);

        return float3x3(
        2.0f * float3(diag.x, b.z, a.y),
        2.0f * float3(a.z, diag.y, b.x),
        2.0f * float3(b.y, a.x, diag.z));
    }

    //// PIXEL SHADERS //////////////////////////////////////////////////////////////
    float4 PS_Technicolor(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
    {
        float4 color      = tex2D( ReShade::BackBuffer, texcoord );
        color.xyz         = saturate( color.xyz );
        float3 root3      = 0.57735f;
        float3 keyC       = 0.0f;
        float half_angle  = 0.0f;
        float4 rot_quat   = 0.0f;
        float3x3 rot_Mat;
        float HueAdj      = 0.52f; //0.5 is too strong in reds and doesn't work well with skin color
        float3 orig       = color.xyz;
        float negR        = 1.0f - color.x;
        float negG        = 1.0f - color.y;
        float3 newR       = 1.0f - negR * Cyan2strip;
        float3 newC       = 1.0f - negG * Red2strip;
        half_angle        = 0.5f * radians( 180.0f ); // Hue is radians of 0 to 360 degrees
        rot_quat          = float4(( root3 * sin( half_angle )), cos( half_angle ));
        rot_Mat           = QuaternionToMatrix( rot_quat );     
        float3 key        = colorKey.xyz;  
        key.xyz           = mul( rot_Mat, key.xyz );   
        key.xyz           = max( color.yyy, key.xyz );
        color.xyz         = newR.xyz * newC.xyz * key.xyz; // 2 strip image
        // Fix hue
        half_angle        = 0.5f * radians( HueAdj * 360.0f ); // Hue is radians of 0 to 360 degrees
        rot_quat          = float4(( root3 * sin( half_angle )), cos( half_angle ));
        rot_Mat           = QuaternionToMatrix( rot_quat );     
        color.xyz         = mul( rot_Mat, color.xyz );  
        // Add saturation to taste
        color.xyz         = lerp( getLuminance( color.xyz ), color.xyz, Saturation2 );

        if( enable3strip ) {
            float3 temp    = 1.0 - orig.xyz;
            float3 target  = temp.grg;
            float3 target2 = temp.bbr;
            float3 temp2   = orig.xyz * target.xyz;
            temp2.xyz      *= target2.xyz;
            temp.xyz       = temp2.xyz * ColorStrength;
            temp2.xyz      *= Brightness;
            target.xyz     = temp.yxy;
            target2.xyz    = temp.zzx;
            temp.xyz       = orig.xyz - target.xyz;
            temp.xyz       += temp2.xyz;
            temp2.xyz      = temp.xyz - target2.xyz;
            color.xyz      = lerp( orig.xyz, temp2.xyz, Strength );
            color.xyz      = lerp( getLuminance( color.xyz ), color.xyz, Saturation);
        }

        return float4( color.xyz, 1.0f );
    }

    //// TECHNIQUES /////////////////////////////////////////////////////////////////
    technique prod80_04_Technicolor <ui_label="prod80 04 彩色印片";>
    {
        pass prod80_TC
        {
            VertexShader   = PostProcessVS;
            PixelShader    = PS_Technicolor;
        }
    }
}


