/*
	Light Depth of Field by luluco250
	
	Poisson disk blur by spite ported from: https://github.com/spite/Wagner/blob/master/fragment-shaders/poisson-disc-blur-fs.glsl
	
	Modified by Marot for ReShade 4.0 compatibility.
	
	Why "light"?
	Because I wanted a DoF shader that didn't tank my GPU and didn't take rocket science to configure.
	Also with delayed auto focus like in ENB.
	
	License: https://creativecommons.org/licenses/by-sa/4.0/
	CC BY-SA 4.0
	
	You are free to:

	Share — copy and redistribute the material in any medium or format
		
	Adapt — remix, transform, and build upon the material
	for any purpose, even commercially.

	The licensor cannot revoke these freedoms as long as you follow the license terms.
		
	Under the following terms:

	Attribution — You must give appropriate credit, provide a link to the license, and indicate if changes were made. 
	You may do so in any reasonable manner, but not in any way that suggests the licensor endorses you or your use.

	ShareAlike — If you remix, transform, or build upon the material, 
	you must distribute your contributions under the same license as the original.

	No additional restrictions — You may not apply legal terms or technological measures 
	that legally restrict others from doing anything the license permits.
*/
// Lightly optimized by Marot Satil for the GShade project.
// Translation of the UI into Chinese by Lilidream.

#include "ReShade.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

//user variables//////////////////////////////////////////////////////////////////////////////////

uniform float fLightDoF_Width <
	ui_label = "散景宽度[轻量景深]";
	ui_type = "slider";
	ui_min = 1.0;
	ui_max = 25.0;
> = 5.0;

uniform float fLightDoF_Amount <
	ui_label = "景深数量[轻量景深]";
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 10.0;
> = 10.0;

uniform bool bLightDoF_UseCA <
	ui_label = "使用色差[轻量景深]";
	ui_tooltip = "使用颜色通道偏移";
> = false;

uniform float2 f2LightDoF_CA <
	ui_label = "色差[轻量景深]";
	ui_tooltip = "偏移颜色通道。\n第一个值控制远色差，第二个值控制近色差。";
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 1.0;
> = float2(0.0, 1.0);

uniform bool bLightDoF_AutoFocus <
	ui_label = "使用自动对焦[轻量景深]";
> = true;

uniform float fLightDoF_AutoFocusSpeed <
	ui_label = "自动对焦速度[轻量景深]";
	ui_type = "slider";
	ui_min = 0.001;
	ui_max = 1.0;
> = 0.1;

uniform bool bLightDoF_UseMouseFocus <
	ui_label = "使用鼠标作为自动对焦中心[轻量景深]";
	ui_tooltip = "使用鼠标位置作为自动对焦中心";
> = false;

uniform float2 f2Bokeh_AutoFocusCenter <
	ui_label = "自动对焦中心[轻量景深]";
	ui_tooltip = "自动对焦的目标。第一个值是水平位置，第二个值是垂直位置。";
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 1.0;
> = float2(0.5, 0.5);

uniform float fLightDoF_ManualFocus <
	ui_label = "手动对焦[轻量景深]";
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 1.0;
> = 0.0;

//system variables////////////////////////////////////////////////////////////////////////////////

//internal variable that holds the current mouse position
uniform float2 f2LightDoF_MouseCoord <source="mousepoint";>;

//textures////////////////////////////////////////////////////////////////////////////////////////

/*
	For those curious...
	
	Two textures are needed in order to delay focus.
	I just lerp between them by a speed.
*/

//texture for saving the current frame's focus
texture tFocus { Format = R16F; };
//texture for saving the last frame's focus
texture tLastFocus { Format = R16F; };

//samplers////////////////////////////////////////////////////////////////////////////////////////

//sampler for the current frame's focus
sampler sFocus { Texture=tFocus; };
//sampler for the last frame's focus
sampler sLastFocus { Texture=tLastFocus; };

//functions///////////////////////////////////////////////////////////////////////////////////////

//interpret the focus textures and separate far/near focuses
float getFocus(float2 coord, bool farOrNear) {
	float depth = ReShade::GetLinearizedDepth(coord);

	if (bLightDoF_AutoFocus)
		depth -= tex2D(sFocus, 0).x;
	else
		depth -= fLightDoF_ManualFocus;
	
	if (farOrNear) {
		depth = saturate(-depth * fLightDoF_Amount);
	}
	else {
		depth = saturate(depth * fLightDoF_Amount);
	}
	
	return depth;
}

//helper function for poisson-disk blur
float2 rot2D(float2 pos, float angle) {
	const float2 source = float2(sin(angle), cos(angle));
	return float2(dot(pos, float2(source.y, -source.x)), dot(pos, source));
}

//poisson-disk blur
float3 poisson(sampler sp, float2 uv, float farOrNear, float CA) {
	float2 poisson[12];
	poisson[0]  = float2(-.326,-.406);
	poisson[1]  = float2(-.840,-.074);
	poisson[2]  = float2(-.696, .457);
	poisson[3]  = float2(-.203, .621);
	poisson[4]  = float2( .962,-.195);
	poisson[5]  = float2( .473,-.480);
	poisson[6]  = float2( .519, .767);
	poisson[7]  = float2( .185,-.893);
	poisson[8]  = float2( .507, .064);
	poisson[9]  = float2( .896, .412);
	poisson[10] = float2(-.322,-.933);
	poisson[11] = float2(-.792,-.598);
	
	float3 col = 0;
	const float random = frac(sin(dot(uv, float2(12.9898, 78.233))) * 43758.5453);
	const float4 basis = float4(rot2D(float2(1, 0), random), rot2D(float2(0, 1), random));
	[loop]
	for (int i = 0; i < 12; ++i) {
		float2 offset = poisson[i];
		offset = float2(dot(offset, basis.xz), dot(offset, basis.yw));
		
		if (bLightDoF_UseCA) {
			float2 rCoord = uv + offset * BUFFER_PIXEL_SIZE * fLightDoF_Width * (1.0 + CA);
			float2 gCoord = uv + offset * BUFFER_PIXEL_SIZE * fLightDoF_Width * (1.0 + CA * 0.5);
			float2 bCoord = uv + offset * BUFFER_PIXEL_SIZE * fLightDoF_Width;
			
			rCoord = lerp(uv, rCoord, getFocus(rCoord, farOrNear));
			gCoord = lerp(uv, gCoord, getFocus(gCoord, farOrNear));
			bCoord = lerp(uv, bCoord, getFocus(bCoord, farOrNear));
			
			col += 	float3(
						tex2Dlod(sp, float4(rCoord, 0, 0)).r,
						tex2Dlod(sp, float4(gCoord, 0, 0)).g,
						tex2Dlod(sp, float4(bCoord, 0, 0)).b
					);
		}
		else {
			float2 coord = uv + offset * BUFFER_PIXEL_SIZE * fLightDoF_Width;
			coord = lerp(uv, coord, getFocus(coord, farOrNear));
			col += tex2Dlod(sp, float4(coord, 0, 0)).rgb;
		}
		
	}
	return col * 0.083;
}

//shaders/////////////////////////////////////////////////////////////////////////////////////////

//far blur shader
float3 Far(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target {
#if GSHADE_DITHER
	const float3 outcolor = poisson(ReShade::BackBuffer, uv, false, f2LightDoF_CA.x);
	return outcolor + TriDither(outcolor, uv, BUFFER_COLOR_BIT_DEPTH);
#else
	return poisson(ReShade::BackBuffer, uv, false, f2LightDoF_CA.x);
#endif
}

//near blur shader
float3 Near(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target {
#if GSHADE_DITHER
	const float3 outcolor = poisson(ReShade::BackBuffer, uv, true, f2LightDoF_CA.y);
	return outcolor + TriDither(outcolor, uv, BUFFER_COLOR_BIT_DEPTH);
#else
	return poisson(ReShade::BackBuffer, uv, true, f2LightDoF_CA.y);
#endif
}

//shader to get the focus, kinda like center of confusion but less complicated
float GetFocus(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target {
	const float2 linearMouse = f2LightDoF_MouseCoord * BUFFER_PIXEL_SIZE; //linearize the mouse position
	float2 focus;
	if (bLightDoF_UseMouseFocus)
		focus = linearMouse;
	else
		focus = f2Bokeh_AutoFocusCenter;
	return lerp(tex2D(sLastFocus, 0).x, ReShade::GetLinearizedDepth(focus), fLightDoF_AutoFocusSpeed);
}

//shader for saving this frame's focus to lerp with the next one's
float SaveFocus(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target {
	return tex2D(sFocus, 0).x;
}


//techniques//////////////////////////////////////////////////////////////////////////////////////

//this technique is dedicated for auto focus, so you don't need it if you're not using auto-focus :)
technique LightDoF_AutoFocus <ui_label="轻量景深-自动对焦";> {
	pass GetFocus {
		VertexShader=PostProcessVS;
		PixelShader=GetFocus;
		RenderTarget=tFocus;
	}
	pass SaveFocus {
		VertexShader=PostProcessVS;
		PixelShader=SaveFocus;
		RenderTarget=tLastFocus;
	}
}

//technique for far blur
technique LightDoF_Far  <ui_label="轻量景深-远模糊";>{
	pass Far {
		VertexShader=PostProcessVS;
		PixelShader=Far;
	}
}

//technique for near blur
technique LightDoF_Near  <ui_label="轻量景深-近模糊";>{
	pass Near {
		VertexShader=PostProcessVS;
		PixelShader=Near;
	}
}

