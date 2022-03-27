/*=============================================================================

    ReShade 4 effect file
    github.com/martymcmodding

	Support me:
   		paypal.me/mcflypg
   		patreon.com/mcflypg

    Depth enhanced local contrast sharpen

    by Marty McFly / P.Gilcher
    part of qUINT shader library for ReShade 4

    Copyright (c) Pascal Gilcher / Marty McFly. All rights reserved.

=============================================================================*/
// Translation of the UI into Chinese by Lilidream.

/*=============================================================================
	Preprocessor settings
=============================================================================*/

/*=============================================================================
	UI Uniforms
=============================================================================*/

uniform float SHARP_STRENGTH <
    ui_type = "slider";
    ui_label = "锐化强度";
    ui_min = 0.0;
    ui_max = 1.0;
> = 0.7;

uniform bool DEPTH_MASK_ENABLE <
    ui_label = "使用深度遮罩";
> = true;

uniform bool RMS_MASK_ENABLE <
    ui_label = "使用局部对比度增强";
> = true;

uniform int SHARPEN_MODE <
	ui_type = "radio";
    ui_label = "锐化模式";
    ui_category = "锐化模式";
	ui_items = "色度\0亮度\0";
> = 1;

/*=============================================================================
	Textures, Samplers, Globals
=============================================================================*/

#define RESHADE_QUINT_COMMON_VERSION_REQUIRE    202
#define RESHADE_QUINT_EFFECT_DEPTH_REQUIRE      //effect requires depth access
#include "qUINT_common.fxh"

/*=============================================================================
	Vertex Shader
=============================================================================*/

struct VSOUT
{
	float4                  vpos        : SV_Position;
    float2                  uv          : TEXCOORD0;
};

VSOUT VS_Sharp(in uint id : SV_VertexID)
{
    VSOUT o;

    o.uv.x = (id == 2) ? 2.0 : 0.0;
    o.uv.y = (id == 1) ? 2.0 : 0.0;

    o.vpos = float4(o.uv.xy * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
    return o;
}

/*=============================================================================
	Functions
=============================================================================*/

float color_to_lum(float3 color)
{
    return dot(color, float3(0.3, 0.59, 0.11));
}

float3 blend_overlay(float3 a, float3 b)
{
    float3 c = 1.0 - a;
    float3 d = 1.0 - b;

    return a < 0.5 ? (2.0 * a * b) : (1.0 - 2.0 * c * d);
}

float4 fetch_color_and_depth(float2 uv)
{
    return float4( tex2D(qUINT::sBackBufferTex, uv).rgb, 
                   qUINT::linear_depth(uv));
}

/*=============================================================================
	Pixel Shaders
=============================================================================*/

void PS_Sharp(in VSOUT i, out float3 o : SV_Target0)
{
    //  A B C
    //  D E F           
    //  G H I

    float4 A, B, C, D, E, F, G, H, I;

    float3 offsets = float3(1, 0, -1);
    
    A = fetch_color_and_depth(i.uv + offsets.zz * qUINT::PIXEL_SIZE);
    B = fetch_color_and_depth(i.uv + offsets.yz * qUINT::PIXEL_SIZE);
    C = fetch_color_and_depth(i.uv + offsets.xz * qUINT::PIXEL_SIZE);
    D = fetch_color_and_depth(i.uv + offsets.zy * qUINT::PIXEL_SIZE);
    E = fetch_color_and_depth(i.uv + offsets.yy * qUINT::PIXEL_SIZE);
    F = fetch_color_and_depth(i.uv + offsets.xy * qUINT::PIXEL_SIZE);
    G = fetch_color_and_depth(i.uv + offsets.zx * qUINT::PIXEL_SIZE);
    H = fetch_color_and_depth(i.uv + offsets.yx * qUINT::PIXEL_SIZE);
    I = fetch_color_and_depth(i.uv + offsets.xx * qUINT::PIXEL_SIZE);

    float4 corners = (A + C) + (G + I);
    float4 neighbours = (B + D) + (F + H);
    float4 center = E;

    float4 edge = corners + 2.0 * neighbours - 12.0 * center;
    float3 sharpen = edge.rgb;

    //measures root mean square as local contrast measurement
    //to adjust the intensity of the sharpener at edges with 
    //high local contrast to restrict sharpen to texture detail
    //only while leaving object and detail outlines mostly alone.
    if(RMS_MASK_ENABLE)
    {
        float3 mean = (corners.rgb + neighbours.rgb + center.rgb) / 9.0;
        float3 RMS = (mean - A.rgb) * (mean - A.rgb);
        RMS += (mean - B.rgb) * (mean - B.rgb);
        RMS += (mean - C.rgb) * (mean - C.rgb);
        RMS += (mean - D.rgb) * (mean - D.rgb);
        RMS += (mean - E.rgb) * (mean - E.rgb);
        RMS += (mean - F.rgb) * (mean - F.rgb);
        RMS += (mean - G.rgb) * (mean - G.rgb);
        RMS += (mean - H.rgb) * (mean - H.rgb);
        RMS += (mean - I.rgb) * (mean - I.rgb);

        //sharpen /= RMS * 16.0 + 0.025 * 16.0; //wrapped the div / 9 in here
        sharpen *= rsqrt(RMS + 0.001) * 0.1;
    }

    //Remove sharpen completely from depth edges, as these never look good
    //with any kind of sharpening and always create exaggerated halos that
    //ruin any strong sharpening which would otherwise enhance textures
    sharpen *= DEPTH_MASK_ENABLE ? saturate(1.0 - abs(edge.w) * 4000.0) : 1;

    //grayscale sharpen mask, helps if some color artifacts arise, red-blue
    //is mostly prone to create weirdly colored spots.
    if(SHARPEN_MODE == 1) 
        sharpen = color_to_lum(sharpen);

    sharpen = -sharpen * SHARP_STRENGTH * 0.1;
    //smooth falloff, cheaper than pow() with little error    
    sharpen = sign(sharpen) * log(abs(sharpen) * 10.0 + 1.0)*0.3; 

    o = blend_overlay(center.rgb, (0.5 + sharpen));
}

/*=============================================================================
	Techniques
=============================================================================*/



technique DELC_Sharpen
< ui_tooltip = "       >> qUINT::深度增强局部对比度锐化(DELCS) <<\n\n"
			   "DELCS是一个先进的锐化滤波器，用于增强纹理细节。\n"
               "它提供了一个局部对比度检测方法，并允许抑制深度边缘的过度锐化，\n"
               "以消除常见的锐化伪影。DELCS最好放在在大多数着色器之后，但在胶片颗粒等之前。\n"
               "\DELCS is written by Marty McFly / Pascal Gilcher";ui_label="深度增强局部对比度锐化(DELC)"; >
{
    pass
	{
		VertexShader = VS_Sharp;
		PixelShader  = PS_Sharp;
	}
}