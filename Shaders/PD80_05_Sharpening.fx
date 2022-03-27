/*
    Description : PD80 05 Sharpening for Reshade https://reshade.me/
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

namespace pd80_lumasharpen
{
    //// UI ELEMENTS ////////////////////////////////////////////////////////////////
    uniform bool enableShowEdges <
        ui_label = "只显示锐化纹理";
        ui_tooltip = "Show only Sharpening Texture";
        ui_category = "锐化";
        > = false;
    uniform float BlurSigma <
        ui_label = "锐化宽度";
        ui_tooltip = "Sharpening Width";
        ui_category = "锐化";
        ui_type = "slider";
        ui_min = 0.3;
        ui_max = 1.2;
        > = 0.45;
    uniform float Sharpening <
        ui_label = "锐化强度";
        ui_tooltip = "Sharpening Strength";
        ui_category = "锐化";
        ui_type = "slider";
        ui_min = 0.0;
        ui_max = 5.0;
        > = 1.7;
    uniform float Threshold <
        ui_label = "锐化阈值";
        ui_tooltip = "Sharpening Threshold";
        ui_category = "锐化";
        ui_type = "slider";
        ui_min = 0.0;
        ui_max = 1.0;
        > = 0.0;
    uniform float limiter <
        ui_label = "锐化高光限制器";
        ui_tooltip = "Sharpening Highlight Limiter";
        ui_category = "锐化";
        ui_type = "slider";
        ui_min = 0.0;
        ui_max = 1.0;
        > = 0.03;
    uniform bool enable_depth <
        ui_label = "开启基于深度调整。\n确保你正确设置了深度缓存。";
        ui_tooltip = "Enable depth based adjustments";
        ui_category = "锐化: 深度";
        > = false;
    uniform bool enable_reverse <
        ui_label = "反转效果（锐化近处，或远处）";
        ui_tooltip = "Reverses the effect";
        ui_category = "锐化: 深度";
        > = false;
    uniform bool display_depth <
        ui_label = "显示深度贴图";
        ui_tooltip = "Show depth texture";
        ui_category = "锐化: 深度";
        > = false;
    uniform float depthStart <
        ui_type = "slider";
        ui_label = "改变深度开始平面";
        ui_tooltip = "Change Depth Start Plane";
        ui_category = "锐化: 深度";
        ui_min = 0.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float depthEnd <
        ui_type = "slider";
        ui_label = "改变深度结束平面";
        ui_tooltip = "Change Depth End Plane";
        ui_category = "锐化: 深度";
        ui_min = 0.0f;
        ui_max = 1.0f;
        > = 0.1;
    uniform float depthCurve <
        ui_label = "深度曲线调整";
        ui_tooltip = "Depth Curve Adjustment";
        ui_category = "锐化: 深度";
        ui_type = "slider";
        ui_min = 0.05;
        ui_max = 8.0;
        > = 1.0;

    //// TEXTURES ///////////////////////////////////////////////////////////////////
    texture texGaussianH { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; }; 
    texture texGaussian { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; };

    //// SAMPLERS ///////////////////////////////////////////////////////////////////
    sampler samplerGaussianH { Texture = texGaussianH; };
    sampler samplerGaussian { Texture = texGaussian; };

    //// DEFINES ////////////////////////////////////////////////////////////////////
    #define PI 3.1415926535897932

    //// FUNCTIONS //////////////////////////////////////////////////////////////////

    float getLuminance( in float3 x )
    {
        return dot( x, float3( 0.212656, 0.715158, 0.072186 ));
    }

    float getAvgColor( float3 col )
    {
        return dot( col.xyz, float3( 0.333333f, 0.333334f, 0.333333f ));
    }

    // nVidia blend modes
    // Source: https://www.khronos.org/registry/OpenGL/extensions/NV/NV_blend_equation_advanced.txt
    float3 ClipColor( float3 color )
    {
        float lum         = getAvgColor( color.xyz );
        float mincol      = min( min( color.x, color.y ), color.z );
        float maxcol      = max( max( color.x, color.y ), color.z );
        color.xyz         = ( mincol < 0.0f ) ? lum + (( color.xyz - lum ) * lum ) / ( lum - mincol ) : color.xyz;
        color.xyz         = ( maxcol > 1.0f ) ? lum + (( color.xyz - lum ) * ( 1.0f - lum )) / ( maxcol - lum ) : color.xyz;
        return color;
    }
    
    // Luminosity: base, blend
    // Color: blend, base
    float3 blendLuma( float3 base, float3 blend )
    {
        float lumbase     = getAvgColor( base.xyz );
        float lumblend    = getAvgColor( blend.xyz );
        float ldiff       = lumblend - lumbase;
        float3 col        = base.xyz + ldiff;
        return ClipColor( col.xyz );
    }

    float3 screen(float3 c, float3 b) { return 1.0f-(1.0f-c)*(1.0f-b);}
    
    //// PIXEL SHADERS //////////////////////////////////////////////////////////////
    float4 PS_GaussianH(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
    {
        float4 color     = tex2D( ReShade::BackBuffer, texcoord );
        float px         = BUFFER_RCP_WIDTH;
        float SigmaSum   = 0.0f;
        float pxlOffset  = 1.0f;
        float loops      = max( BUFFER_WIDTH, BUFFER_HEIGHT ) / 1920.0f * 4.0f;

        //Gaussian Math
        float3 Sigma;
        float bSigma     = BlurSigma * ( max( BUFFER_WIDTH, BUFFER_HEIGHT ) / 1920.0f ); // Scalar
        Sigma.x          = 1.0f / ( sqrt( 2.0f * PI ) * bSigma );
        Sigma.y          = exp( -0.5f / ( bSigma * bSigma ));
        Sigma.z          = Sigma.y * Sigma.y;

        //Center Weight
        color.xyz        *= Sigma.x;
        //Adding to total sum of distributed weights
        SigmaSum         += Sigma.x;
        //Setup next weight
        Sigma.xy         *= Sigma.yz;

        [loop]
        for( int i = 0; i < loops; ++i )
        {
            color        += tex2Dlod( ReShade::BackBuffer, float4( texcoord.xy + float2( pxlOffset*px, 0.0f ), 0.0, 0.0 )) * Sigma.x;
            color        += tex2Dlod( ReShade::BackBuffer, float4( texcoord.xy - float2( pxlOffset*px, 0.0f ), 0.0, 0.0 )) * Sigma.x;
            SigmaSum     += ( 2.0f * Sigma.x );
            pxlOffset    += 1.0f;
            Sigma.xy     *= Sigma.yz;
        }

        color.xyz        /= SigmaSum;
        return float4( color.xyz, 1.0f );
    }

    float4 PS_GaussianV(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
    {
        float4 color     = tex2D( samplerGaussianH, texcoord );
        float py         = BUFFER_RCP_HEIGHT;
        float SigmaSum   = 0.0f;
        float pxlOffset  = 1.0f;
        float loops      = max( BUFFER_WIDTH, BUFFER_HEIGHT ) / 1920.0f * 4.0f;

        //Gaussian Math
        float3 Sigma;
        float bSigma     = BlurSigma * ( max( BUFFER_WIDTH, BUFFER_HEIGHT ) / 1920.0f ); // Scalar
        Sigma.x          = 1.0f / ( sqrt( 2.0f * PI ) * bSigma );
        Sigma.y          = exp( -0.5f / ( bSigma * bSigma ));
        Sigma.z          = Sigma.y * Sigma.y;

        //Center Weight
        color.xyz        *= Sigma.x;
        //Adding to total sum of distributed weights
        SigmaSum         += Sigma.x;
        //Setup next weight
        Sigma.xy         *= Sigma.yz;

        [loop]
        for( int i = 0; i < loops; ++i )
        {
            color        += tex2Dlod( samplerGaussianH, float4( texcoord.xy + float2( 0.0f, pxlOffset*py ), 0.0, 0.0 )) * Sigma.x;
            color        += tex2Dlod( samplerGaussianH, float4( texcoord.xy - float2( 0.0f, pxlOffset*py ), 0.0, 0.0 )) * Sigma.x;
            SigmaSum     += ( 2.0f * Sigma.x );
            pxlOffset    += 1.0f;
            Sigma.xy     *= Sigma.yz;
        }

        color.xyz        /= SigmaSum;
        return float4( color.xyz, 1.0f );
    }

    float4 PS_LumaSharpen(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
    {
        float4 orig      = tex2D( ReShade::BackBuffer, texcoord );
        float4 gaussian  = tex2D( samplerGaussian, texcoord );
        
        float depth      = ReShade::GetLinearizedDepth( texcoord ).x;
        depth            = smoothstep( depthStart, depthEnd, depth );
        depth            = pow( depth, depthCurve );
        depth            = enable_reverse ? 1.0f - depth : depth;
        
        float3 edges     = max( saturate( orig.xyz - gaussian.xyz ) - Threshold, 0.0f );
        float3 invGauss  = saturate( 1.0f - gaussian.xyz );
        float3 oInvGauss = saturate( orig.xyz + invGauss.xyz );
        float3 invOGauss = max( saturate( 1.0f - oInvGauss.xyz ) - Threshold, 0.0f );
        edges            = max(( saturate( Sharpening * edges.xyz )) - ( saturate( Sharpening * invOGauss.xyz )), 0.0f );
        float3 blend     = screen( orig.xyz, lerp( min( edges.xyz, limiter ), 0.0f, enable_depth * depth ));
        float3 color     = blendLuma( orig.xyz, blend.xyz );
        color.xyz        = enableShowEdges ? lerp( min( edges.xyz, limiter ), min( edges.xyz, limiter ) * depth, enable_depth ) : color.xyz;
        color.xyz        = display_depth ? depth.xxx : color.xyz;
        return float4( color.xyz, 1.0f );
    }

    //// TECHNIQUES /////////////////////////////////////////////////////////////////
    technique prod80_05_LumaSharpen <ui_label="prod80 05 亮度锐化";>
    {
        pass GaussianH
        {
            VertexShader   = PostProcessVS;
            PixelShader    = PS_GaussianH;
            RenderTarget   = texGaussianH;
        }
        pass GaussianV
        {
            VertexShader   = PostProcessVS;
            PixelShader    = PS_GaussianV;
            RenderTarget   = texGaussian;
        }
        pass LumaSharpen
        {
            VertexShader   = PostProcessVS;
            PixelShader    = PS_LumaSharpen;
        }
    }
}