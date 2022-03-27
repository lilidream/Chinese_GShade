/*-----------------------------------------------------------------------------------------------------*/
/* ZigZag Shader - by Radegast Stravinsky of Ultros.                                               */
/* There are plenty of shaders that make your game look amazing. This isn't one of them.               */
/*-----------------------------------------------------------------------------------------------------*/
// Translation of the UI into Chinese by Lilidream.
#include "ReShade.fxh"
#include "Blending.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

uniform int mode <
    ui_type = "combo";
    ui_label = "模式";
    ui_items = "中心附近\0中心之外\0";
    ui_tooltip = "选择扭曲过程所用的模式";
> = 0;

uniform float radius <
    ui_type = "slider";
    ui_label = "半径";
    ui_min = 0.0; 
    ui_max = 1.0;
> = 0.5;

uniform float angle <
    ui_type = "slider";
    ui_label = "角度";
    ui_tooltip = "作为相位和振幅的乘数。也根据数值是负的还是正的，按相位影响动画的运动。";
    ui_tooltip = "调整波纹角度。正值和负值影响动画的方向。";
    ui_min = -999.0; 
    ui_max = 999.0; 
    ui_step = 1.0;
> = 180.0;

uniform float period <
    ui_type = "slider";
    ui_type = "周期";
    ui_tooltip = "调整扭曲的速度";
    ui_min = 0.1; 
    ui_max = 10.0;
> = 0.25;

uniform float amplitude <
    ui_type = "slider";
    ui_label = "振幅";
    ui_tooltip = "增加图片来回扭动的极端程度。";
    ui_min = -10.0; 
    ui_max = 10.0;
> = 3.0;

uniform float2 coordinates <
    ui_type = "slider";
    ui_label="坐标";
    ui_tooltip="效果中心的XY位置";
    ui_min = 0.0; 
    ui_max = 1.0;
> = float2(0.25, 0.25);

uniform bool use_mouse_point <
    ui_label="使用鼠标坐标";
    ui_tooltip="当启用时，使用鼠标的当前坐标，而不是由坐标滑块定义的坐标。";
> = false;

uniform float aspect_ratio <
    ui_type = "slider";
    ui_label="纵横比"; 
    ui_min = -100.0; 
    ui_max = 100.0;
> = 0;

uniform bool use_offset_coords <
    ui_label = "使用偏移坐标";
    ui_category = "偏移";
    ui_tooltip = "在其原始坐标之外的任何位置显示扭曲。";
> = 0;

uniform float2 offset_coords <
    ui_label = "偏移坐标";
    ui_tooltip = "(开启使用偏移坐标) 确定源坐标在传递到输出坐标时要被扭曲。.";
    ui_type = "slider";
    ui_category = "偏移";
    ui_min = 0.0;
    ui_max = 1.0;
> = float2(0.5, 0.5);

uniform float depth_threshold <
    ui_type = "slider";
    ui_label="深度阈值";
    ui_category = "深度";
    ui_min=0.0;
    ui_max=1.0;
> = 0;

uniform int depth_mode <
    ui_type = "combo";
    ui_label = "深度模式";
    ui_category = "深度";
    ui_items = "最小值\0最大值\0";
    ui_tooltip = "使用场景深度来遮罩效果";
> = 0;

uniform bool set_max_depth_behind <
    ui_label = "设置扭曲在前景之后";
    ui_tooltip = "(仅最大值深度阈值模式) 启用后，将扭曲的区域设置在应在其前面的物体后面。";
    ui_category = "深度";
> = 0;

uniform float tension <
    ui_type = "slider";
    ui_label = "张力";
    ui_tooltip = "调整失真达到最大值的速度";
    ui_min = 0; 
    ui_max = 10;
    ui_step = 0.001;
> = 1.0;

uniform float phase <
    ui_type = "slider";
    ui_label = "相位";
    ui_tooltip = "像素从中心来回扭动的偏移量。";
    ui_min = -5.0; 
    ui_max = 5.0;
> = 0.0;

uniform int animate <
    ui_type = "combo";
    ui_label = "动画";
    ui_items = "无\0振幅\0相位\0";
    ui_tooltip = "启用或禁用该动画。通过相位或振幅对之字形效果进行动画。";
> = 0;

BLENDING_COMBO(
    render_type, 
    "混合模式", 
    "混合效果与前面的图层",
    "混合",
    false,
    0,
    0
);

uniform float blending_amount <
    ui_type = "slider";
    ui_label = "透明度";
    ui_category = "混合";
    ui_tooltip = "调整混合数量";
    ui_min = 0.0;
    ui_max = 1.0;
> = 1.0;

uniform float anim_rate <
    source = "timer";
>;

uniform float2 mouse_coordinates < 
source= "mousepoint";
>;

texture texColorBuffer : COLOR;
texture texDepthBuffer : DEPTH;

sampler samplerColor
{
    Texture = texColorBuffer;

    AddressU = MIRROR;
    AddressV = MIRROR;
    AddressW = MIRROR;

};

float2x2 swirlTransform(float theta) {
    const float c = cos(theta);
    const float s = sin(theta);

    const float m1 = c;
    const float m2 = -s;
    const float m3 = s;
    const float m4 = c;

    return float2x2(
        m1, m2,
        m3, m4
    );
}

float2x2 zigzagTransform(float dist) {
    const float c = cos(dist);
    return float2x2(
        c, 0,
        0, c
    );
}

// Vertex Shader
void FullScreenVS(uint id : SV_VertexID, out float4 position : SV_Position, out float2 texcoord : TEXCOORD0)
{
    if (id == 2)
        texcoord.x = 2.0;
    else
        texcoord.x = 0.0;

    if (id == 1)
        texcoord.y  = 2.0;
    else
        texcoord.y = 0.0;

    position = float4( texcoord * float2(2, -2) + float2(-1, 1), 0, 1);
}

// Pixel Shaders (in order of appearance in the technique)
float4 ZigZag(float4 pos : SV_Position, float2 texcoord : TEXCOORD0) : SV_TARGET
{
    const float ar_raw = 1.0 * (float)BUFFER_HEIGHT / (float)BUFFER_WIDTH;
    const float depth = ReShade::GetLinearizedDepth(texcoord).r;
    float4 color;
    const float4 base = tex2D(samplerColor, texcoord);
    float ar = lerp(ar_raw, 1, aspect_ratio * 0.01);
    
    float2 center = coordinates / 2.0;
    float2 offset_center = offset_coords / 2.0;

    if (use_mouse_point) 
        center = float2(mouse_coordinates.x * BUFFER_RCP_WIDTH / 2.0, mouse_coordinates.y * BUFFER_RCP_HEIGHT / 2.0);

    float2 tc = texcoord - center;

    center.x /= ar;
    offset_center.x /= ar;
    tc.x /= ar;


    const float dist = distance(tc, center);
    const float tension_radius = lerp(radius-dist, radius, tension);
    const float percent = max(radius-dist, 0) / tension_radius;
    const float percentSquared = percent * percent;
    const float theta = percentSquared * (animate == 1 ? amplitude * sin(anim_rate * 0.0005) : amplitude) * sin(percentSquared / period * radians(angle) + (phase + (animate == 2 ? 0.00075 * anim_rate : 0)));

    if(!mode) 
    {
        tc = mul(swirlTransform(theta), tc-center);
    }
    else
    {
        tc = mul(zigzagTransform(theta), tc-center);
    }


    if(use_offset_coords)
        tc += (2 * offset_center);
    else 
        tc += (2 * center);

    tc.x *= ar;

    float out_depth;
    bool inDepthBounds;
    if (depth_mode == 0) {
        out_depth =  ReShade::GetLinearizedDepth(texcoord).r;
        inDepthBounds = out_depth >= depth_threshold;
    }
    else{
        out_depth = ReShade::GetLinearizedDepth(tc).r;
        inDepthBounds = out_depth <= depth_threshold;
    }

    float blending_factor;
    if(render_type) 
        blending_factor = lerp(0, percentSquared, blending_amount);
    else
        blending_factor = blending_amount;
    if (inDepthBounds)
    {
        if(use_offset_coords){
            float2 offset_coords_adjust = offset_coords;
            offset_coords_adjust.x *= ar;
            if(dist <= tension_radius)
            {
                color = tex2D(samplerColor, tc);
                color.rgb = ComHeaders::Blending::Blend(render_type, base.rgb, color.rgb, blending_factor);
            }
            else
                color = tex2D(samplerColor, texcoord);
        } else
        {
            color = tex2D(samplerColor, tc);
            color.rgb = ComHeaders::Blending::Blend(render_type, base.rgb, color.rgb, blending_factor);
        }
        
        
    }
    else
    {
        color = base;
    }

    if(set_max_depth_behind) {
        const float mask_front = ReShade::GetLinearizedDepth(texcoord).r;
        if(mask_front < depth_threshold)
            color = tex2D(samplerColor, texcoord);
    }

#if GSHADE_DITHER
	return float4(color.rgb + TriDither(color.rgb, texcoord, BUFFER_COLOR_BIT_DEPTH), color.a);
#else
    return color;
#endif
}

// Technique
technique ZigZag <ui_label="之字形";>
{
    pass p0
    {
        VertexShader = FullScreenVS;
        PixelShader = ZigZag;
    }
};
