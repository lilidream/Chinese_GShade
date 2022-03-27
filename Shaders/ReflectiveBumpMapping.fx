//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// ReShade effect file
// visit facebook.com/MartyMcModding for news/updates
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Reflective Bumpmapping "RBM" 3.0.1 beta by Marty McFly. 
// For ReShade 4.X only!
// Copyright © 2008-2016 Marty McFly
// Modified by Marot for ReShade 4.0 and lightly optimized for the GShade project.
// Translation of the UI into Chinese by Lilidream.
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

uniform float fRBM_BlurWidthPixels <
	ui_label = "模糊宽度像素";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 400.00;
	ui_step = 1;
	ui_tooltip = "控制反射传播的范围。如果你得到重复的伪影，降低这个数值或提高采样次数。";
> = 100.0;

uniform int iRBM_SampleCount <
	ui_label = "采样数";
	ui_type = "slider";
	ui_min = 16; ui_max = 128;
	ui_tooltip = "控制采集多少光泽反射样本。如果你得到重复的伪影，就提高这个值。性能会受到影响。";
> = 32;

uniform float fRBM_ReliefHeight <
	ui_label = "浮雕高度";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 2.00;
	ui_tooltip = "控制表面浮雕的密集程度。0.0意味着像镜子一样的反射。";
> = 0.3;

uniform float fRBM_FresnelReflectance <
	ui_label = "菲涅尔反射";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.00;
	ui_tooltip = "这个值越低，视角与表面的角度就越小，才能得到明显的反射。1.0意味着每个表面都有100%的光泽。";
> = 0.3;

uniform float fRBM_FresnelMult <
	ui_label = "菲涅尔倍数";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.00;
	ui_tooltip = "在物理上完全不准确: 在最低视角-表面角度的反射强度的乘数。";
> = 0.5;

uniform float  fRBM_LowerThreshold <
	ui_label = "低阈值";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.00;
	ui_tooltip = "任何比这更暗的东西不会被反射。反射强度从低阈值到高阈值呈线性增长。 ";
> = 0.1;

uniform float  fRBM_UpperThreshold <
	ui_label = "高阈值";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.00;
	ui_tooltip = "任何比这更亮的东西会被完全反射。反射强度从低阈值到高阈值呈线性增长。 ";
> = 0.2;

uniform float  fRBM_ColorMask_Red <
	ui_label = "颜色遮罩 红色";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.00;
	ui_tooltip = "红色表面的反射倍数。降低这个数值可以消除红色表面的反射。";
> = 1.0;

uniform float  fRBM_ColorMask_Orange <
	ui_label = "颜色遮罩 橙色";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.00;
	ui_tooltip = "橙色表面的反射倍数。降低这个数值可以消除橙色表面的反射。";
> = 1.0;

uniform float  fRBM_ColorMask_Yellow <
	ui_label = "颜色遮罩 黄色";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.00;
	ui_tooltip = "黄色表面的反射倍数。降低这个数值可以消除黄色表面的反射。";
> = 1.0;

uniform float  fRBM_ColorMask_Green <
	ui_label = "颜色遮罩 绿色";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.00;
	ui_tooltip = "绿色表面的反射倍数。降低这个数值可以消除绿色表面的反射。";
> = 1.0;

uniform float  fRBM_ColorMask_Cyan <
	ui_label = "颜色遮罩 青色";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.00;
	ui_tooltip = "青色表面的反射倍数。降低这个数值可以消除青色表面的反射。";
> = 1.0;

uniform float  fRBM_ColorMask_Blue <
	ui_label = "颜色遮罩 蓝色";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.00;
	ui_tooltip = "蓝色表面的反射倍数。降低这个数值可以消除蓝色表面的反射。";
> = 1.0;

uniform float  fRBM_ColorMask_Magenta <
	ui_label = "颜色遮罩 洋红色";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.00;
	ui_tooltip = "洋红色表面的反射倍数。降低这个数值可以消除洋红色表面的反射。";
> = 1.0;

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#include "ReShade.fxh"

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
float GetLinearDepth(float2 coords)
{
	return ReShade::GetLinearizedDepth(coords);
}

float3 GetPosition(float2 coords)
{
	float EyeDepth = GetLinearDepth(coords.xy)*RESHADE_DEPTH_LINEARIZATION_FAR_PLANE;
	return float3((coords.xy * 2.0 - 1.0)*EyeDepth,EyeDepth);
}

float3 GetNormalFromDepth(float2 coords) 
{
	const float3 centerPos = GetPosition(coords.xy);
	const float2 offs = BUFFER_PIXEL_SIZE*1.0;
	float3 ddx1 = GetPosition(coords.xy + float2(offs.x, 0)) - centerPos;
	const float3 ddx2 = centerPos - GetPosition(coords.xy + float2(-offs.x, 0));

	float3 ddy1 = GetPosition(coords.xy + float2(0, offs.y)) - centerPos;
	const float3 ddy2 = centerPos - GetPosition(coords.xy + float2(0, -offs.y));

	ddx1 = lerp(ddx1, ddx2, abs(ddx1.z) > abs(ddx2.z));
	ddy1 = lerp(ddy1, ddy2, abs(ddy1.z) > abs(ddy2.z));
	
	return normalize(cross(ddy1, ddx1));
}

float3 GetNormalFromColor(float2 coords, float2 offset, float scale, float sharpness)
{
	const float3 lumCoeff = float3(0.299,0.587,0.114);

    	const float hpx = dot(tex2Dlod(ReShade::BackBuffer, float4(coords + float2(offset.x,0.0),0,0)).xyz,lumCoeff) * scale;
    	const float hmx = dot(tex2Dlod(ReShade::BackBuffer, float4(coords - float2(offset.x,0.0),0,0)).xyz,lumCoeff) * scale;
    	const float hpy = dot(tex2Dlod(ReShade::BackBuffer, float4(coords + float2(0.0,offset.y),0,0)).xyz,lumCoeff) * scale;
    	const float hmy = dot(tex2Dlod(ReShade::BackBuffer, float4(coords - float2(0.0,offset.y),0,0)).xyz,lumCoeff) * scale;

    	const float dpx = GetLinearDepth(coords + float2(offset.x,0.0));
    	const float dmx = GetLinearDepth(coords - float2(offset.x,0.0));
    	const float dpy = GetLinearDepth(coords + float2(0.0,offset.y));
    	const float dmy = GetLinearDepth(coords - float2(0.0,offset.y));

	float2 xymult = float2(abs(dmx - dpx), abs(dmy - dpy)) * sharpness; 
	xymult = saturate(1.0 - xymult);
    	
    	const float ddx = (hmx - hpx) / (2.0 * offset.x) * xymult.x;
    	const float ddy = (hmy - hpy) / (2.0 * offset.y) * xymult.y;
    
    	return normalize(float3(ddx, ddy, 1.0));
}

float3 GetBlendedNormals(float3 n1, float3 n2)
{
	 return normalize(float3(n1.xy*n2.z + n2.xy*n1.z, n1.z*n2.z));
}

float3 RGB2HSV(float3 RGB)
{
    	const float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);

		float4 p;
		if (RGB.g < RGB.b)
			p = float4(RGB.bg, K.wz);
		else
			p = float4(RGB.gb, K.xy);

		float4 q;
		if (RGB.r < p.x)
			q = float4(p.xyw, RGB.r);
		else
			q = float4(RGB.r, p.yzx);

    	const float d = q.x - min(q.w, q.y);
    	const float e = 1.0e-10;
    	return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

float3 HSV2RGB(float3 HSV)
{
    	const float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    	const float3 p = abs(frac(HSV.xxx + K.xyz) * 6.0 - K.www);
    	return HSV.z * lerp(K.xxx, saturate(p - K.xxx), HSV.y); //HDR capable
}

float GetHueMask(in float H)	
{
	float SMod = 0.0;
	SMod += fRBM_ColorMask_Red * ( 1.0 - min( 1.0, abs( H / 0.08333333 ) ) );
	SMod += fRBM_ColorMask_Orange * ( 1.0 - min( 1.0, abs( ( 0.08333333 - H ) / ( - 0.08333333 ) ) ) );
	SMod += fRBM_ColorMask_Yellow * ( 1.0 - min( 1.0, abs( ( 0.16666667 - H ) / ( - 0.16666667 ) ) ) );
	SMod += fRBM_ColorMask_Green * ( 1.0 - min( 1.0, abs( ( 0.33333333 - H ) / 0.16666667 ) ) );
	SMod += fRBM_ColorMask_Cyan * ( 1.0 - min( 1.0, abs( ( 0.5 - H ) / 0.16666667 ) ) );
	SMod += fRBM_ColorMask_Blue * ( 1.0 - min( 1.0, abs( ( 0.66666667 - H ) / 0.16666667 ) ) );
	SMod += fRBM_ColorMask_Magenta * ( 1.0 - min( 1.0, abs( ( 0.83333333 - H ) / 0.16666667 ) ) );
	SMod += fRBM_ColorMask_Red * ( 1.0 - min( 1.0, abs( ( 1.0 - H ) / 0.16666667 ) ) );
	return SMod;
}

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

void PS_RBM_Gen(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 res : SV_Target0)
{
	const float scenedepth 		= GetLinearDepth(texcoord.xy);
	float3 SurfaceNormals 		= GetNormalFromDepth(texcoord.xy).xyz;
	const float3 TextureNormals 		= GetNormalFromColor(texcoord.xy, 0.01 * BUFFER_PIXEL_SIZE / scenedepth, 0.0002 / scenedepth + 0.1, 1000.0);
	float3 SceneNormals		= GetBlendedNormals(SurfaceNormals, TextureNormals);
	SceneNormals 			= normalize(lerp(SurfaceNormals,SceneNormals,fRBM_ReliefHeight));
	const float3 ScreenSpacePosition 	= GetPosition(texcoord.xy);
	const float3 ViewDirection 		= normalize(ScreenSpacePosition.xyz);

	float4 color = tex2D(ReShade::BackBuffer, texcoord.xy);
	float3 bump = 0.0;

	for(float i=1; i<=iRBM_SampleCount; i++)
	{
		const float2 currentOffset 	= texcoord.xy + SceneNormals.xy * BUFFER_PIXEL_SIZE * i/(float)iRBM_SampleCount * fRBM_BlurWidthPixels;
		const float4 texelSample 	= tex2Dlod(ReShade::BackBuffer, float4(currentOffset,0,0));	
		
		const float depthDiff 	= smoothstep(0.005,0.0,scenedepth-GetLinearDepth(currentOffset));
		const float colorWeight 	= smoothstep(fRBM_LowerThreshold,fRBM_UpperThreshold+0.00001,dot(texelSample.xyz,float3(0.299,0.587,0.114)));
		bump += lerp(color.xyz,texelSample.xyz,depthDiff*colorWeight);
	}

	bump /= iRBM_SampleCount;

	const float cosphi = dot(-ViewDirection, SceneNormals);
	//R0 + (1.0 - R0)*(1.0-cosphi)^5;
	float SchlickReflectance = lerp(pow(1.0-cosphi,5.0), 1.0, fRBM_FresnelReflectance);
	SchlickReflectance = saturate(SchlickReflectance)*fRBM_FresnelMult; // *should* be 0~1 but isn't for some pixels.

	const float3 hsvcol = RGB2HSV(color.xyz);
	float colorMask = GetHueMask(hsvcol.x);
	colorMask = lerp(1.0,colorMask, smoothstep(0.0,0.2,hsvcol.y) * smoothstep(0.0,0.1,hsvcol.z));
	color.xyz = lerp(color.xyz,bump.xyz,SchlickReflectance*colorMask);

	res.xyz = color.xyz;
	res.w = 1.0;

}

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

technique ReflectiveBumpmapping <ui_label="反射性凹凸纹理映射";>
{
	pass P1
	{
		VertexShader = PostProcessVS;
		PixelShader  = PS_RBM_Gen;
	}
}
