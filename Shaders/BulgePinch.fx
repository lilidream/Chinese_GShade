/*-----------------------------------------------------------------------------------------------------*/
/* PBDistort Shader - by Radegast Stravinsky of Ultros.                                               */
/* There are plenty of shaders that make your game look amazing. This isn't one of them.               */
/*-----------------------------------------------------------------------------------------------------*/
// Translation of the UI into Chinese by Lilidream.
#include "ReShade.fxh"
#include "Blending.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

uniform float radius <
    ui_type = "slider";
    ui_label = "半径";
    ui_tooltip = "扭曲区域半径";
    ui_min = 0.0; 
    ui_max = 1.0;
> = 0.5;

uniform float magnitude <
    ui_type = "slider";
    ui_label = "强度";
    ui_tooltip = "扭曲强度，正值表示凸出，负值表示凹陷。";
    ui_min = -1.0; 
    ui_max = 1.0;
> = -0.5;

uniform float tension <
    ui_type = "slider";
    ui_label = "张力";
    ui_tooltip = "调整画面从变形边缘到中心达到最大扭曲的速度";
    ui_min = 0.; 
    ui_max = 10.; 
    ui_step = 0.001;
> = 1.0;

uniform float2 coordinates <
    ui_type = "slider";
    ui_label="坐标";
    ui_tooltip="效果中心的X和Y坐标";
    ui_min = 0.0; ui_max = 1.0;
> = 0.25;

uniform bool use_mouse_point <
    ui_label="使用鼠标坐标";
    ui_tooltip="若开启，则使用鼠标当前的坐标来作为效果中心";
> = false;

uniform bool use_offset_coords <
    ui_label = "使用偏移坐标";
    ui_category = "偏移";
    ui_tooltip = "在原坐标附近所有的地方显示扭曲";
> = 0;

uniform float2 offset_coords <
    ui_label = "偏移坐标";
    ui_tooltip = "确定在传递到输出坐标时要扭曲的源坐标";
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
    ui_category = "Depth";
    ui_items = "最小\0最大\0";
    ui_tooltip = "通过场景深度来遮罩效果";
> = 0;

uniform bool set_max_depth_behind <
    ui_label = "设置扭曲在前景之后";
    ui_tooltip = "(最大深度阈值模式下) 当开始，将扭曲放在需要的前景后面";
    ui_category = "Depth";
> = 0;

uniform float aspect_ratio <
    ui_type = "slider";
    ui_label = "纵横比"; 
    ui_min = -100.0; 
    ui_max = 100.0;
> = 0;

uniform int animate <
    ui_type = "combo";
    ui_label = "动画";
    ui_items = "关\0开\0";
    ui_tooltip = "使效果动起来";
> = 0;

BLENDING_COMBO(
    render_type, 
    "混合模式", 
    "将前面的图层混合",
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

sampler samplerColor
{
    Texture = texColorBuffer;

    AddressU = MIRROR;
    AddressV = MIRROR;
    AddressW = MIRROR;

    MagFilter = LINEAR;
    MinFilter = LINEAR;
    MipFilter = LINEAR;

    MinLOD = 0.0f;
    MaxLOD = 1000.0f;

    MipLODBias = 0.0f;

    SRGBTexture = false;
};

// Vertex Shader
void FullScreenVS(uint id : SV_VertexID, out float4 position : SV_Position, out float2 texcoord : TEXCOORD0)
{
    texcoord.x = (id == 2) ? 2.0 : 0.0;
    texcoord.y = (id == 1) ? 2.0 : 0.0;
    
    position = float4( texcoord * float2(2, -2) + float2(-1, 1), 0, 1);
    //position /= BUFFER_HEIGHT/BUFFER_WIDTH;

}

// Pixel Shaders (in order of appearance in the technique)
float4 PBDistort(float4 pos : SV_Position, float2 texcoord : TEXCOORD0) : SV_TARGET
{
    const float ar_raw = 1.0 * (float)BUFFER_HEIGHT / (float)BUFFER_WIDTH;
    float ar = lerp(ar_raw, 1, aspect_ratio * 0.01);

    float2 center = coordinates / 2.0;
    float2 offset_center = offset_coords;

    if (use_mouse_point) 
        center = float2(mouse_coordinates.x * BUFFER_RCP_WIDTH / 2.0, mouse_coordinates.y * BUFFER_RCP_HEIGHT / 2.0);

    float2 tc = texcoord - center;

    float4 color;
    const float4 base = tex2D(samplerColor, texcoord);
    const float depth = ReShade::GetLinearizedDepth(texcoord).r;

    center.x /= ar;
    tc.x /= ar;

    float dist = distance(tc, center);
    
    float anim_mag = (animate == 1 ? magnitude * sin(radians(anim_rate * 0.05)) : magnitude);
    float tension_radius = lerp(dist, radius, tension);
    float percent = (dist)/tension_radius;
    if(anim_mag > 0)
        tc = (tc-center) * lerp(1.0, smoothstep(0.0, radius/dist, percent), anim_mag * 0.75);
    else
        tc = (tc-center) * lerp(1.0, pow(abs(percent), 1.0 + anim_mag * 0.75) * radius/dist, 1.0 - percent);

    if(use_offset_coords) {
        tc += (2 * offset_center);
    }
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
        blending_factor = lerp(0, 1 - percent, blending_amount);
    else
        blending_factor = blending_amount;

    if (tension_radius >= dist && inDepthBounds)
    {
        if(use_offset_coords){
            if(dist <= tension_radius)
                color = tex2D(samplerColor, tc);
            else
                color = tex2D(samplerColor, texcoord);
        } else
            color = tex2D(samplerColor, tc);

        color.rgb = ComHeaders::Blending::Blend(render_type, base.rgb, color.rgb, blending_factor);
    }
    else {
        color = tex2D(samplerColor, texcoord);
    }

    if(set_max_depth_behind) {
        const float mask_front = ReShade::GetLinearizedDepth(texcoord).r;
        if(mask_front < depth_threshold)
            color = tex2D(samplerColor, texcoord);
    }
    
    return color;
}

// Technique
technique BulgePinch < ui_label="凹凸效果";>
{
    pass p0
    {
        VertexShader = FullScreenVS;
        PixelShader = PBDistort;
    }
};
