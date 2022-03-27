//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// ReShade effect file
// Eye Adaption by brussell
// v. 2.3_FFXIV - FFXIV Edit
//
// modified by healingbrew to disable adaptation 
// when occluded by UI
//
// Credits:
// luluco250 - luminance get/store code from Magic Bloom
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Translation of the UI into Chinese by Lilidream.

#include "ReShade.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

//effect parameters
uniform float fAdp_Delay <
    ui_label = "自适应延迟";
    ui_tooltip = "画面亮度变化适应速度\n"
                 "0 = 即时适应\n"
                 "2 = 非常慢的适应";
    ui_category = "一般设置";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 2.0;
> = 1.6;

uniform float fAdp_TriggerRadius <
    ui_label = "自适应触发半径";
    ui_tooltip = "触发适应的屏幕区域\n"
                 "1 = 只使用画面中心\n"
                 "7 = 使用整个画面";
    ui_category = "一般设置";
    ui_type = "slider";
    ui_min = 1.0;
    ui_max = 7.0;
    ui_step = 0.1;
> = 6.0;

uniform float fAdp_YAxisFocalPoint <
    ui_label = "Y轴对焦点";
    ui_tooltip = "Y轴上应用于触发半径的焦点\n"
                 "0 = 屏幕顶部\n"
                 "1 = 屏幕底部";
    ui_category = "一般设置";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
> = 0.5;

uniform float fAdp_Equilibrium <
    ui_label = "适应平衡";
    ui_tooltip = "不适用亮度适应的画面亮度\n"
                 "0 = 更迟变亮，更早变暗\n"
                 "1 = 更早变亮，更迟变暗";
    ui_category = "一般设置";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
> = 0.5;

uniform float fAdp_Strength <
    ui_label = "适应强度";
    ui_tooltip = "亮度适应的基本强度";
    ui_category = "一般设置";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 2.0;
> = 1.0;

uniform bool bAdp_IgnoreOccludedByUI <
  ui_label = "忽略被UI遮挡的地方(FFXIV)";
  ui_category = "一般设置";
> = 0;

uniform float fAdp_IgnoreTreshold <
    ui_label = "忽略Alpha阈值";
    ui_tooltip = "透明度如何的UI将被忽略\n"
                 "0 = 任何UI\n"
                 "1 = 只有100%不透明才能不被遮挡";
    ui_category = "一般设置";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
> = 0.2;

uniform float fAdp_BrightenHighlights <
    ui_label = "高光变亮";
    ui_tooltip = "高光的变亮强度";
    ui_category = "变亮";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
> = 0.1;

uniform float fAdp_BrightenMidtones <
    ui_label = "中间调变亮";
    ui_tooltip = "中间调的变亮强度";
    ui_category = "变亮";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
> = 0.2;

uniform float fAdp_BrightenShadows <
    ui_label = "阴影变亮";
    ui_tooltip = "阴影的变亮强度，设置为0来保留纯黑";
    ui_category = "变亮";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
> = 0.1;

uniform float fAdp_DarkenHighlights <
    ui_label = "高光变暗";
    ui_tooltip = "高光变暗强度，设置为0来保留纯白";
    ui_category = "变暗";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
> = 0.1;

uniform float fAdp_DarkenMidtones <
    ui_label = "中间调变暗";
    ui_tooltip = "中间调变暗强度";
    ui_category = "变暗";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
> = 0.2;

uniform float fAdp_DarkenShadows <
    ui_label = "阴影变暗";
    ui_tooltip = "阴影的变暗强度";
    ui_category = "变暗";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
> = 0.1;

//global vars
#define LumCoeff float3(0.212656, 0.715158, 0.072186)
uniform float Frametime < source = "frametime";>;

//textures and samplers
texture2D TexLuma { Width = 256; Height = 256; Format = R8; MipLevels = 7; };
texture2D TexAvgLuma { Format = R16F; };
texture2D TexAvgLumaLast { Format = R16F; };

sampler SamplerLuma { Texture = TexLuma; };
sampler SamplerAvgLuma { Texture = TexAvgLuma; };
sampler SamplerAvgLumaLast { Texture = TexAvgLumaLast; };

//pixel shaders
float PS_Luma(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    const float4 color = tex2Dlod(ReShade::BackBuffer, float4(texcoord, 0, 0));
    return dot(color.xyz, LumCoeff);
}

float PS_AvgLuma(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    const float avgLumaCurrFrame = tex2Dlod(SamplerLuma, float4(fAdp_YAxisFocalPoint.xx, 0, fAdp_TriggerRadius)).x;
    const float avgLumaLastFrame = tex2Dlod(SamplerAvgLumaLast, float4(0.0.xx, 0, 0)).x;
    const float uiVisibility = tex2D(ReShade::BackBuffer, float2(0.5, 0.5)).a;
    if(bAdp_IgnoreOccludedByUI && uiVisibility > fAdp_IgnoreTreshold)
    {
        return avgLumaLastFrame;
    }
    const float delay = sign(fAdp_Delay) * saturate(0.815 + fAdp_Delay / 10.0 - Frametime / 1000.0);
    return lerp(avgLumaCurrFrame, avgLumaLastFrame, delay);
}

float AdaptionDelta(float luma, float strengthMidtones, float strengthShadows, float strengthHighlights)
{
    const float midtones = (4.0 * strengthMidtones - strengthHighlights - strengthShadows) * luma * (1.0 - luma);
    const float shadows = strengthShadows * (1.0 - luma);
    const float highlights = strengthHighlights * luma;
    return midtones + shadows + highlights;
}

float4 PS_Adaption(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    float4 color = tex2Dlod(ReShade::BackBuffer, float4(texcoord, 0, 0));
    const float avgLuma = tex2Dlod(SamplerAvgLuma, float4(0.0.xx, 0, 0)).x;

    color.xyz = pow(abs(color.xyz), 1.0/2.2);
    float luma = dot(color.xyz, LumCoeff);
    const float3 chroma = color.xyz - luma;

    const float avgLumaAdjusted = lerp (avgLuma, 1.4 * avgLuma / (0.4 + avgLuma), fAdp_Equilibrium);
    float delta = 0;

    const float curve = fAdp_Strength * 10.0 * pow(abs(avgLumaAdjusted - 0.5), 4.0);
    if (avgLumaAdjusted < 0.5) {
        delta = AdaptionDelta(luma, fAdp_BrightenMidtones, fAdp_BrightenShadows, fAdp_BrightenHighlights);
    } else {
        delta = -AdaptionDelta(luma, fAdp_DarkenMidtones, fAdp_DarkenShadows, fAdp_DarkenHighlights);
    }
    delta *= curve;

    luma += delta;
    color.xyz = saturate(luma + chroma);
    color.xyz = pow(abs(color.xyz), 2.2);

#if GSHADE_DITHER
    return float4(color.xyz + TriDither(color.xyz, texcoord, BUFFER_COLOR_BIT_DEPTH), color.w);
#else
    return color;
#endif
}

float PS_StoreAvgLuma(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    return tex2Dlod(SamplerAvgLuma, float4(0.0.xx, 0, 0)).x;
}

//techniques
technique EyeAdaption <ui_label="眼部自适应";>{

    pass Luma
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_Luma;
        RenderTarget = TexLuma;
    }

    pass AvgLuma
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_AvgLuma;
        RenderTarget = TexAvgLuma;
    }

    pass Adaption
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_Adaption;
    }

    pass StoreAvgLuma
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_StoreAvgLuma;
        RenderTarget = TexAvgLumaLast;
    }
}
