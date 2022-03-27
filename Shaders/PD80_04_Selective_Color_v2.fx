/*
    Description : PD80 04 Selective Color 2 for Reshade https://reshade.me/
    Author      : prod80 (Bas Veth)
    License     : MIT, Copyright (c) 2020 prod80

    Additional credits
    - Based on the mathematical analysis provided here
      http://blog.pkh.me/p/22-understanding-selective-coloring-in-adobe-photoshop.html


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
#include "PD80_00_Color_Spaces.fxh"

namespace pd80_selectivecolorv2
{

    //// UI ELEMENTS ////////////////////////////////////////////////////////////////
    uniform int corr_method <
        ui_label = "校正方法";
        ui_tooltip = "Correction Method";
        ui_category = "颜色校正";
        ui_type = "combo";
        ui_items = "绝对\0相对\0"; //Do not change order; 0=Absolute, 1=Relative
        > = 1;
    // 红色
    uniform float r_adj_cya <
        ui_type = "slider";
        ui_label = "青色";
        ui_tooltip = "颜色校正 红色: 青色";
        ui_category = "颜色校正: 红色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float r_adj_mag <
        ui_type = "slider";
        ui_label = "洋红色";
        ui_tooltip = "颜色校正 红色: 洋红色";
        ui_category = "颜色校正: 红色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float r_adj_yel <
        ui_type = "slider";
        ui_label = "黄色";
        ui_tooltip = "颜色校正 红色: 黄色";
        ui_category = "颜色校正: 红色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float r_adj_bla <
        ui_type = "slider";
        ui_label = "黑色";
        ui_tooltip = "颜色校正 红色: 黑色";
        ui_category = "颜色校正: 红色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float r_adj_sat <
        ui_type = "slider";
        ui_label = "饱和度";
        ui_tooltip = "颜色校正 红色: 饱和度";
        ui_category = "颜色校正: 红色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float r_adj_lig_curve <
        ui_type = "slider";
        ui_label = "亮度曲线";
        ui_tooltip = "颜色校正 红色: 亮度曲线";
        ui_category = "颜色校正: 红色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float r_adj_lig <
        ui_type = "slider";
        ui_label = "亮度";
        ui_tooltip = "颜色校正 红色: 亮度";
        ui_category = "颜色校正: 红色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    
    // 橙色
    uniform float o_adj_cya <
        ui_type = "slider";
        ui_label = "青色";
        ui_tooltip = "颜色校正 橙色: 青色";
        ui_category = "颜色校正: 橙色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float o_adj_mag <
        ui_type = "slider";
        ui_label = "洋红色";
        ui_tooltip = "颜色校正 橙色: 洋红色";
        ui_category = "颜色校正: 橙色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float o_adj_yel <
        ui_type = "slider";
        ui_label = "黄色";
        ui_tooltip = "颜色校正 橙色: 黄色";
        ui_category = "颜色校正: 橙色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float o_adj_bla <
        ui_type = "slider";
        ui_label = "黑色";
        ui_tooltip = "颜色校正 橙色: 黑色";
        ui_category = "颜色校正: 橙色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float o_adj_sat <
        ui_type = "slider";
        ui_label = "饱和度";
        ui_tooltip = "颜色校正 橙色: 饱和度";
        ui_category = "颜色校正: 橙色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float o_adj_lig_curve <
        ui_type = "slider";
        ui_label = "亮度曲线";
        ui_tooltip = "颜色校正 橙色: 亮度曲线";
        ui_category = "颜色校正: 橙色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float o_adj_lig <
        ui_type = "slider";
        ui_label = "亮度";
        ui_tooltip = "颜色校正 橙色: 亮度";
        ui_category = "颜色校正: 橙色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;

    // 黄色
    uniform float y_adj_cya <
        ui_type = "slider";
        ui_label = "青色";
        ui_tooltip = "颜色校正 黄色: 青色";
        ui_category = "颜色校正: 黄色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float y_adj_mag <
        ui_type = "slider";
        ui_label = "洋红色";
        ui_tooltip = "颜色校正 黄色: 洋红色";
        ui_category = "颜色校正: 黄色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float y_adj_yel <
        ui_type = "slider";
        ui_label = "黄色";
        ui_tooltip = "颜色校正 黄色: 黄色";
        ui_category = "颜色校正: 黄色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float y_adj_bla <
        ui_type = "slider";
        ui_label = "黑色";
        ui_tooltip = "颜色校正 黄色: 黑色";
        ui_category = "颜色校正: 黄色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float y_adj_sat <
        ui_type = "slider";
        ui_label = "饱和度";
        ui_tooltip = "颜色校正 黄色: 饱和度";
        ui_category = "颜色校正: 黄色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float y_adj_lig_curve <
        ui_type = "slider";
        ui_label = "亮度曲线";
        ui_tooltip = "颜色校正 黄色: 亮度曲线";
        ui_category = "颜色校正: 黄色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float y_adj_lig <
        ui_type = "slider";
        ui_label = "亮度";
        ui_tooltip = "颜色校正 黄色: 亮度";
        ui_category = "颜色校正: 黄色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;

    // 黄绿色
    uniform float yg_adj_cya <
        ui_type = "slider";
        ui_label = "青色";
        ui_tooltip = "颜色校正 黄绿色: 青色";
        ui_category = "颜色校正: 黄绿色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float yg_adj_mag <
        ui_type = "slider";
        ui_label = "洋红色";
        ui_tooltip = "颜色校正 黄绿色: 洋红色";
        ui_category = "颜色校正: 黄绿色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float yg_adj_yel <
        ui_type = "slider";
        ui_label = "黄色";
        ui_tooltip = "颜色校正 黄绿色: 黄色";
        ui_category = "颜色校正: 黄绿色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float yg_adj_bla <
        ui_type = "slider";
        ui_label = "黑色";
        ui_tooltip = "颜色校正 黄绿色: 黑色";
        ui_category = "颜色校正: 黄绿色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float yg_adj_sat <
        ui_type = "slider";
        ui_label = "饱和度";
        ui_tooltip = "颜色校正 黄绿色: 饱和度";
        ui_category = "颜色校正: 黄绿色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float yg_adj_lig_curve <
        ui_type = "slider";
        ui_label = "亮度曲线";
        ui_tooltip = "颜色校正 黄绿色: 亮度曲线";
        ui_category = "颜色校正: 黄绿色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float yg_adj_lig <
        ui_type = "slider";
        ui_label = "亮度";
        ui_tooltip = "颜色校正 黄绿色: 亮度";
        ui_category = "颜色校正: 黄绿色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;

    // 绿色
    uniform float g_adj_cya <
        ui_type = "slider";
        ui_label = "青色";
        ui_tooltip = "颜色校正 绿色: 青色";
        ui_category = "颜色校正: 绿色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float g_adj_mag <
        ui_type = "slider";
        ui_label = "洋红色";
        ui_tooltip = "颜色校正 绿色: 洋红色";
        ui_category = "颜色校正: 绿色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float g_adj_yel <
        ui_type = "slider";
        ui_label = "黄色";
        ui_tooltip = "颜色校正 绿色: 黄色";
        ui_category = "颜色校正: 绿色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float g_adj_bla <
        ui_type = "slider";
        ui_label = "黑色";
        ui_tooltip = "颜色校正 绿色: 黑色";
        ui_category = "颜色校正: 绿色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float g_adj_sat <
        ui_type = "slider";
        ui_label = "饱和度";
        ui_tooltip = "颜色校正 绿色: 饱和度";
        ui_category = "颜色校正: 绿色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float g_adj_lig_curve <
        ui_type = "slider";
        ui_label = "亮度曲线";
        ui_tooltip = "颜色校正 绿色: 亮度曲线";
        ui_category = "颜色校正: 绿色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float g_adj_lig <
        ui_type = "slider";
        ui_label = "亮度";
        ui_tooltip = "颜色校正 绿色: 亮度";
        ui_category = "颜色校正: 绿色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;

    // 绿色-青色
    uniform float gc_adj_cya <
        ui_type = "slider";
        ui_label = "青色";
        ui_tooltip = "颜色校正 绿色-青色: 青色";
        ui_category = "颜色校正: 绿色-青色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float gc_adj_mag <
        ui_type = "slider";
        ui_label = "洋红色";
        ui_tooltip = "颜色校正 绿色-青色: 洋红色";
        ui_category = "颜色校正: 绿色-青色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float gc_adj_yel <
        ui_type = "slider";
        ui_label = "黄色";
        ui_tooltip = "颜色校正 绿色-青色: 黄色";
        ui_category = "颜色校正: 绿色-青色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float gc_adj_bla <
        ui_type = "slider";
        ui_label = "黑色";
        ui_tooltip = "颜色校正 绿色-青色: 黑色";
        ui_category = "颜色校正: 绿色-青色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float gc_adj_sat <
        ui_type = "slider";
        ui_label = "饱和度";
        ui_tooltip = "颜色校正 绿色-青色: 饱和度";
        ui_category = "颜色校正: 绿色-青色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float gc_adj_lig_curve <
        ui_type = "slider";
        ui_label = "亮度曲线";
        ui_tooltip = "颜色校正 绿色-青色: 亮度曲线";
        ui_category = "颜色校正: 绿色-青色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float gc_adj_lig <
        ui_type = "slider";
        ui_label = "亮度";
        ui_tooltip = "颜色校正 绿色-青色: 亮度";
        ui_category = "颜色校正: 绿色-青色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;

    // 青色
    uniform float c_adj_cya <
        ui_type = "slider";
        ui_label = "青色";
        ui_tooltip = "颜色校正 青色: 青色";
        ui_category = "颜色校正: 青色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float c_adj_mag <
        ui_type = "slider";
        ui_label = "洋红色";
        ui_tooltip = "颜色校正 青色: 洋红色";
        ui_category = "颜色校正: 青色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float c_adj_yel <
        ui_type = "slider";
        ui_label = "黄色";
        ui_tooltip = "颜色校正 青色: 黄色";
        ui_category = "颜色校正: 青色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float c_adj_bla <
        ui_type = "slider";
        ui_label = "黑色";
        ui_tooltip = "颜色校正 青色: 黑色";
        ui_category = "颜色校正: 青色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float c_adj_sat <
        ui_type = "slider";
        ui_label = "饱和度";
        ui_tooltip = "颜色校正 青色: 饱和度";
        ui_category = "颜色校正: 青色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float c_adj_lig_curve <
        ui_type = "slider";
        ui_label = "亮度曲线";
        ui_tooltip = "颜色校正 青色: 亮度曲线";
        ui_category = "颜色校正: 青色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float c_adj_lig <
        ui_type = "slider";
        ui_label = "亮度";
        ui_tooltip = "颜色校正 青色: 亮度";
        ui_category = "颜色校正: 青色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;

    // 青色-蓝色
    uniform float cb_adj_cya <
        ui_type = "slider";
        ui_label = "青色";
        ui_tooltip = "颜色校正 青色-蓝色: Cyan";
        ui_category = "颜色校正: 青色-蓝色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float cb_adj_mag <
        ui_type = "slider";
        ui_label = "洋红色";
        ui_tooltip = "颜色校正 青色-蓝色: 洋红色";
        ui_category = "颜色校正: 青色-蓝色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float cb_adj_yel <
        ui_type = "slider";
        ui_label = "黄色";
        ui_tooltip = "颜色校正 青色-蓝色: 黄色";
        ui_category = "颜色校正: 青色-蓝色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float cb_adj_bla <
        ui_type = "slider";
        ui_label = "黑色";
        ui_tooltip = "颜色校正 青色-蓝色: 黑色";
        ui_category = "颜色校正: 青色-蓝色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float cb_adj_sat <
        ui_type = "slider";
        ui_label = "饱和度";
        ui_tooltip = "颜色校正 青色-蓝色: 饱和度";
        ui_category = "颜色校正: 青色-蓝色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float cb_adj_lig_curve <
        ui_type = "slider";
        ui_label = "亮度曲线";
        ui_tooltip = "颜色校正 青色-蓝色: 亮度曲线";
        ui_category = "颜色校正: 青色-蓝色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float cb_adj_lig <
        ui_type = "slider";
        ui_label = "亮度";
        ui_tooltip = "颜色校正 青色-蓝色: 亮度";
        ui_category = "颜色校正: 青色-蓝色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;

    // 蓝色
    uniform float b_adj_cya <
        ui_type = "slider";
        ui_label = "青色";
        ui_tooltip = "颜色校正 蓝色: 青色";
        ui_category = "颜色校正: 蓝色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float b_adj_mag <
        ui_type = "slider";
        ui_label = "洋红色";
        ui_tooltip = "颜色校正 蓝色: 洋红色";
        ui_category = "颜色校正: 蓝色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float b_adj_yel <
        ui_type = "slider";
        ui_label = "黄色";
        ui_tooltip = "颜色校正 蓝色: 黄色";
        ui_category = "颜色校正: 蓝色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float b_adj_bla <
        ui_type = "slider";
        ui_label = "黑色";
        ui_tooltip = "颜色校正 蓝色: 黑色";
        ui_category = "颜色校正: 蓝色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float b_adj_sat <
        ui_type = "slider";
        ui_label = "饱和度";
        ui_tooltip = "颜色校正 蓝色: 饱和度";
        ui_category = "颜色校正: 蓝色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float b_adj_lig_curve <
        ui_type = "slider";
        ui_label = "亮度曲线";
        ui_tooltip = "颜色校正 蓝色: 亮度曲线";
        ui_category = "颜色校正: 蓝色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float b_adj_lig <
        ui_type = "slider";
        ui_label = "亮度";
        ui_tooltip = "颜色校正 蓝色: 亮度";
        ui_category = "颜色校正: 蓝色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;

    // 蓝色-洋红色
    uniform float bm_adj_cya <
        ui_type = "slider";
        ui_label = "青色";
        ui_tooltip = "颜色校正 蓝色-洋红色: 青色";
        ui_category = "颜色校正: 蓝色-洋红色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float bm_adj_mag <
        ui_type = "slider";
        ui_label = "洋红色";
        ui_tooltip = "颜色校正 蓝色-洋红色: 洋红色";
        ui_category = "颜色校正: 蓝色-洋红色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float bm_adj_yel <
        ui_type = "slider";
        ui_label = "黄色";
        ui_tooltip = "颜色校正 蓝色-洋红色: 黄色";
        ui_category = "颜色校正: 蓝色-洋红色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float bm_adj_bla <
        ui_type = "slider";
        ui_label = "黑色";
        ui_tooltip = "颜色校正 蓝色-洋红色: 黑色";
        ui_category = "颜色校正: 蓝色-洋红色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float bm_adj_sat <
        ui_type = "slider";
        ui_label = "饱和度";
        ui_tooltip = "颜色校正 蓝色-洋红色: 饱和度";
        ui_category = "颜色校正: 蓝色-洋红色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float bm_adj_lig_curve <
        ui_type = "slider";
        ui_label = "亮度曲线";
        ui_tooltip = "颜色校正 蓝色-洋红色: 亮度曲线";
        ui_category = "颜色校正: 蓝色-洋红色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float bm_adj_lig <
        ui_type = "slider";
        ui_label = "亮度";
        ui_tooltip = "颜色校正 蓝色-洋红色: 亮度";
        ui_category = "颜色校正: 蓝色-洋红色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;

    // 洋红色
    uniform float m_adj_cya <
        ui_type = "slider";
        ui_label = "青色";
        ui_tooltip = "颜色校正 洋红色: 青色";
        ui_category = "颜色校正: 洋红色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float m_adj_mag <
        ui_type = "slider";
        ui_label = "洋红色";
        ui_tooltip = "颜色校正 洋红色: 洋红色";
        ui_category = "颜色校正: 洋红色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float m_adj_yel <
        ui_type = "slider";
        ui_label = "黄色";
        ui_tooltip = "颜色校正 洋红色: 黄色";
        ui_category = "颜色校正: 洋红色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float m_adj_bla <
        ui_type = "slider";
        ui_label = "黑色";
        ui_tooltip = "颜色校正 洋红色: 黑色";
        ui_category = "颜色校正: 洋红色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float m_adj_sat <
        ui_type = "slider";
        ui_label = "饱和度";
        ui_tooltip = "颜色校正 洋红色: 饱和度";
        ui_category = "颜色校正: 洋红色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float m_adj_lig_curve <
        ui_type = "slider";
        ui_label = "亮度曲线";
        ui_tooltip = "颜色校正 洋红色: 亮度曲线";
        ui_category = "颜色校正: 洋红色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float m_adj_lig <
        ui_type = "slider";
        ui_label = "亮度";
        ui_tooltip = "颜色校正 洋红色: 亮度";
        ui_category = "颜色校正: 洋红色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;

    // 洋红色-红色
    uniform float mr_adj_cya <
        ui_type = "slider";
        ui_label = "青色";
        ui_tooltip = "颜色校正 洋红色-红色: 青色";
        ui_category = "颜色校正: 洋红色-红色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float mr_adj_mag <
        ui_type = "slider";
        ui_label = "洋红色";
        ui_tooltip = "颜色校正 洋红色-红色: 洋红色";
        ui_category = "颜色校正: 洋红色-红色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float mr_adj_yel <
        ui_type = "slider";
        ui_label = "黄色";
        ui_tooltip = "颜色校正 洋红色-红色: 黄色";
        ui_category = "颜色校正: 洋红色-红色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float mr_adj_bla <
        ui_type = "slider";
        ui_label = "黑色";
        ui_tooltip = "颜色校正 洋红色-红色: 黑色";
        ui_category = "颜色校正: 洋红色-红色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float mr_adj_sat <
        ui_type = "slider";
        ui_label = "饱和度";
        ui_tooltip = "颜色校正 洋红色-红色: 饱和度";
        ui_category = "颜色校正: 洋红色-红色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float mr_adj_lig_curve <
        ui_type = "slider";
        ui_label = "亮度曲线";
        ui_tooltip = "颜色校正 洋红色-红色: 亮度曲线";
        ui_category = "颜色校正: 洋红色-红色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float mr_adj_lig <
        ui_type = "slider";
        ui_label = "亮度";
        ui_tooltip = "颜色校正 洋红色-红色: 亮度";
        ui_category = "颜色校正: 洋红色-红色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;

    // 白色
    uniform float w_adj_cya <
        ui_type = "slider";
        ui_label = "青色";
        ui_tooltip = "颜色校正 白色: 青色";
        ui_category = "颜色校正: 白色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float w_adj_mag <
        ui_type = "slider";
        ui_label = "洋红色";
        ui_tooltip = "颜色校正 白色: 洋红色";
        ui_category = "颜色校正: 白色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float w_adj_yel <
        ui_type = "slider";
        ui_label = "黄色";
        ui_tooltip = "颜色校正 白色: 黄色";
        ui_category = "颜色校正: 白色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float w_adj_bla <
        ui_type = "slider";
        ui_label = "黑色";
        ui_tooltip = "颜色校正 白色: 黑色";
        ui_category = "颜色校正: 白色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float w_adj_sat <
        ui_type = "slider";
        ui_label = "饱和度";
        ui_tooltip = "颜色校正 白色: 饱和度";
        ui_category = "颜色校正: 白色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;

    // 中性
    uniform float n_adj_cya <
        ui_type = "slider";
        ui_label = "青色";
        ui_tooltip = "颜色校正 中性: 青色";
        ui_category = "颜色校正: 中性";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float n_adj_mag <
        ui_type = "slider";
        ui_label = "洋红色";
        ui_tooltip = "颜色校正 中性: 洋红色";
        ui_category = "颜色校正: 中性";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float n_adj_yel <
        ui_type = "slider";
        ui_label = "黄色";
        ui_tooltip = "颜色校正 中性: 黄色";
        ui_category = "颜色校正: 中性";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float n_adj_bla <
        ui_type = "slider";
        ui_label = "黑色";
        ui_tooltip = "颜色校正 中性: 黑色";
        ui_category = "颜色校正: 中性";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float n_adj_sat <
        ui_type = "slider";
        ui_label = "饱和度";
        ui_tooltip = "颜色校正 中性: 饱和度";
        ui_category = "颜色校正: 中性";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;

    // 黑色
    uniform float bk_adj_cya <
        ui_type = "slider";
        ui_label = "青色";
        ui_tooltip = "颜色校正 黑色: 青色";
        ui_category = "颜色校正: 黑色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float bk_adj_mag <
        ui_type = "slider";
        ui_label = "洋红色";
        ui_tooltip = "颜色校正 黑色: 洋红色";
        ui_category = "颜色校正: 黑色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float bk_adj_yel <
        ui_type = "slider";
        ui_label = "黄色";
        ui_tooltip = "颜色校正 黑色: 黄色";
        ui_category = "颜色校正: 黑色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float bk_adj_bla <
        ui_type = "slider";
        ui_label = "黑色";
        ui_tooltip = "颜色校正 黑色: 黑色";
        ui_category = "颜色校正: 黑色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float bk_adj_sat <
        ui_type = "slider";
        ui_label = "饱和度";
        ui_tooltip = "颜色校正 黑色: 饱和度";
        ui_category = "颜色校正: 黑色";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;

    //// TEXTURES ///////////////////////////////////////////////////////////////////
    
    //// SAMPLERS ///////////////////////////////////////////////////////////////////

    //// DEFINES ////////////////////////////////////////////////////////////////////

    //// FUNCTIONS //////////////////////////////////////////////////////////////////
    float mid( float3 c )
    {
        float sum = c.x + c.y + c.z;
        float mn = min( min( c.x, c.y ), c.z );
        float mx = max( max( c.x, c.y ), c.z );
        return sum - mn - mx;
    }

    // Credit to user 'iq' from shadertoy
    // See https://www.shadertoy.com/view/MdBfR1
    float brightness_curve( float x, float k )
    {
        float s = sign( x - 0.5f );
        float o = ( 1.0f + s ) / 2.0f;
        return o - 0.5f * s * pow( max( 2.0f * ( o - s * x ), 0.0f ), k );
    }

    float curve( float x )
    {
        return x * x * ( 3.0 - 2.0 * x );
    }

    float smooth( float x )
    {
        return x * x * x * ( x * ( x * 6.0f - 15.0f ) + 10.0f );
    }

    float adjustcolor( float scale, float colorvalue, float adjust, float bk, int method )
    {
        /* 
        y(value, adjustment) = clamp((( -1 - adjustment ) * bk - adjustment ) * method, -value, 1 - value ) * scale
        absolute: method = 1.0f - colorvalue * 0
        relative: method = 1.0f - colorvalue * 1
        */
        return clamp((( -1.0f - adjust ) * bk - adjust ) * ( 1.0f - colorvalue * method ), -colorvalue, 1.0f - colorvalue) * scale;
    }

    //// PIXEL SHADERS //////////////////////////////////////////////////////////////
    float4 PS_SelectiveColor(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
    {
        float4 color      = tex2D( ReShade::BackBuffer, texcoord );

        // Clamp 0..1
        color.xyz         = saturate( color.xyz );

        // Min Max Mid
        float min_value   = min( min( color.x, color.y ), color.z );
        float max_value   = max( max( color.x, color.y ), color.z );
        float mid_value   = mid( color.xyz );
        float scalar      = max_value - min_value;
        float alt_scalar  = ( mid_value - min_value ) / 2.0f;
        float cmy_scalar  = scalar / 2.0f;
        
        // HSL
        float3 hsl        = RGBToHSL( color.xyz ).x;

        // Weights for Whites, Neutrals, Blacks
        float sWhites     = smooth( min_value );
        float sBlacks     = 1.0f - smooth( max_value );
        float sNeutrals   = 1.0f - smooth( max_value - min_value );

        // Weights
        float sw_r        = curve( max( 1.0f - abs(  hsl.x                   * 6.0f ), 0.0f )) +
                            curve( max( 1.0f - abs(( hsl.x - 1.0f          ) * 6.0f ), 0.0f ));
        float sw_o        = curve( max( 1.0f - abs(( hsl.x - 1.0f  / 12.0f ) * 6.0f ), 0.0f )) +
                            curve( max( 1.0f - abs(( hsl.x - 13.0f / 12.0f ) * 6.0f ), 0.0f ));
        float sw_y        = curve( max( 1.0f - abs(( hsl.x - 2.0f  / 12.0f ) * 6.0f ), 0.0f ));
        float sw_yg       = curve( max( 1.0f - abs(( hsl.x - 3.0f  / 12.0f ) * 6.0f ), 0.0f ));
        float sw_g        = curve( max( 1.0f - abs(( hsl.x - 4.0f  / 12.0f ) * 6.0f ), 0.0f ));
        float sw_gc       = curve( max( 1.0f - abs(( hsl.x - 5.0f  / 12.0f ) * 6.0f ), 0.0f ));
        float sw_c        = curve( max( 1.0f - abs(( hsl.x - 6.0f  / 12.0f ) * 6.0f ), 0.0f ));
        float sw_cb       = curve( max( 1.0f - abs(( hsl.x - 7.0f  / 12.0f ) * 6.0f ), 0.0f ));
        float sw_b        = curve( max( 1.0f - abs(( hsl.x - 8.0f  / 12.0f ) * 6.0f ), 0.0f ));
        float sw_bm       = curve( max( 1.0f - abs(( hsl.x - 9.0f  / 12.0f ) * 6.0f ), 0.0f ));
        float sw_m        = curve( max( 1.0f - abs(( hsl.x - 10.0f / 12.0f ) * 6.0f ), 0.0f ));
        float sw_mr       = curve( max( 1.0f - abs(( hsl.x - 11.0f / 12.0f ) * 6.0f ), 0.0f )) +
                            curve( max( 1.0f - abs(( hsl.x + 1.0f  / 12.0f ) * 6.0f ), 0.0f ));

        float w_r         = sw_r  * scalar;
        float w_o         = sw_o  * alt_scalar;
        float w_y         = sw_y  * cmy_scalar;
        float w_yg        = sw_yg * alt_scalar;
        float w_g         = sw_g  * scalar;
        float w_gc        = sw_gc * alt_scalar;
        float w_c         = sw_c  * cmy_scalar;
        float w_cb        = sw_cb * alt_scalar;
        float w_b         = sw_b  * scalar;
        float w_bm        = sw_bm * alt_scalar;
        float w_m         = sw_m  * cmy_scalar;
        float w_mr        = sw_mr * alt_scalar;

        // Selective Color
        // Reds
        color.x           = color.x + adjustcolor( w_r, color.x, r_adj_cya, r_adj_bla, corr_method );
        color.y           = color.y + adjustcolor( w_r, color.y, r_adj_mag, r_adj_bla, corr_method );
        color.z           = color.z + adjustcolor( w_r, color.z, r_adj_yel, r_adj_bla, corr_method );
        // Oranges
        color.x           = color.x + adjustcolor( w_o, color.x, o_adj_cya, o_adj_bla, corr_method );
        color.y           = color.y + adjustcolor( w_o, color.y, o_adj_mag, o_adj_bla, corr_method );
        color.z           = color.z + adjustcolor( w_o, color.z, o_adj_yel, o_adj_bla, corr_method );
        // Yellows
        color.x           = color.x + adjustcolor( w_y, color.x, y_adj_cya, y_adj_bla, corr_method );
        color.y           = color.y + adjustcolor( w_y, color.y, y_adj_mag, y_adj_bla, corr_method );
        color.z           = color.z + adjustcolor( w_y, color.z, y_adj_yel, y_adj_bla, corr_method );
        // Yellow-Greens
        color.x           = color.x + adjustcolor( w_yg, color.x, yg_adj_cya, yg_adj_bla, corr_method );
        color.y           = color.y + adjustcolor( w_yg, color.y, yg_adj_mag, yg_adj_bla, corr_method );
        color.z           = color.z + adjustcolor( w_yg, color.z, yg_adj_yel, yg_adj_bla, corr_method );
        // Greens
        color.x           = color.x + adjustcolor( w_g, color.x, g_adj_cya, g_adj_bla, corr_method );
        color.y           = color.y + adjustcolor( w_g, color.y, g_adj_mag, g_adj_bla, corr_method );
        color.z           = color.z + adjustcolor( w_g, color.z, g_adj_yel, g_adj_bla, corr_method );
        // Green-Cyans
        color.x           = color.x + adjustcolor( w_gc, color.x, gc_adj_cya, gc_adj_bla, corr_method );
        color.y           = color.y + adjustcolor( w_gc, color.y, gc_adj_mag, gc_adj_bla, corr_method );
        color.z           = color.z + adjustcolor( w_gc, color.z, gc_adj_yel, gc_adj_bla, corr_method );
        // Cyans
        color.x           = color.x + adjustcolor( w_c, color.x, c_adj_cya, c_adj_bla, corr_method );
        color.y           = color.y + adjustcolor( w_c, color.y, c_adj_mag, c_adj_bla, corr_method );
        color.z           = color.z + adjustcolor( w_c, color.z, c_adj_yel, c_adj_bla, corr_method );
        // Cyan-Blues
        color.x           = color.x + adjustcolor( w_cb, color.x, cb_adj_cya, cb_adj_bla, corr_method );
        color.y           = color.y + adjustcolor( w_cb, color.y, cb_adj_mag, cb_adj_bla, corr_method );
        color.z           = color.z + adjustcolor( w_cb, color.z, cb_adj_yel, cb_adj_bla, corr_method );
        // Blues
        color.x           = color.x + adjustcolor( w_b, color.x, b_adj_cya, b_adj_bla, corr_method );
        color.y           = color.y + adjustcolor( w_b, color.y, b_adj_mag, b_adj_bla, corr_method );
        color.z           = color.z + adjustcolor( w_b, color.z, b_adj_yel, b_adj_bla, corr_method );
        // Blue-Magentas
        color.x           = color.x + adjustcolor( w_bm, color.x, bm_adj_cya, bm_adj_bla, corr_method );
        color.y           = color.y + adjustcolor( w_bm, color.y, bm_adj_mag, bm_adj_bla, corr_method );
        color.z           = color.z + adjustcolor( w_bm, color.z, bm_adj_yel, bm_adj_bla, corr_method );
        // Magentas
        color.x           = color.x + adjustcolor( w_m, color.x, m_adj_cya, m_adj_bla, corr_method );
        color.y           = color.y + adjustcolor( w_m, color.y, m_adj_mag, m_adj_bla, corr_method );
        color.z           = color.z + adjustcolor( w_m, color.z, m_adj_yel, m_adj_bla, corr_method );
        // Magenta-Reds
        color.x           = color.x + adjustcolor( w_mr, color.x, mr_adj_cya, mr_adj_bla, corr_method );
        color.y           = color.y + adjustcolor( w_mr, color.y, mr_adj_mag, mr_adj_bla, corr_method );
        color.z           = color.z + adjustcolor( w_mr, color.z, mr_adj_yel, mr_adj_bla, corr_method );
        // Whites
        color.x           = color.x + adjustcolor( sWhites, color.x, w_adj_cya, w_adj_bla, corr_method );
        color.y           = color.y + adjustcolor( sWhites, color.y, w_adj_mag, w_adj_bla, corr_method );
        color.z           = color.z + adjustcolor( sWhites, color.z, w_adj_yel, w_adj_bla, corr_method );
        // Blacks
        color.x           = color.x + adjustcolor( sBlacks, color.x, bk_adj_cya, bk_adj_bla, corr_method );
        color.y           = color.y + adjustcolor( sBlacks, color.y, bk_adj_mag, bk_adj_bla, corr_method );
        color.z           = color.z + adjustcolor( sBlacks, color.z, bk_adj_yel, bk_adj_bla, corr_method );
        // Neutrals
        color.x           = color.x + adjustcolor( sNeutrals, color.x, n_adj_cya, n_adj_bla, corr_method );
        color.y           = color.y + adjustcolor( sNeutrals, color.y, n_adj_mag, n_adj_bla, corr_method );
        color.z           = color.z + adjustcolor( sNeutrals, color.z, n_adj_yel, n_adj_bla, corr_method );

        // Saturation
        // Have to get current saturation in between each adjustment as there are overlaps
        float curr_sat    = 0.0f;
        
        // Reds
        curr_sat          = max( max( color.x, color.y ), color.z ) - min( min( color.x, color.y ), color.z );
        color.xyz         = ( r_adj_sat > 0.0f ) ?  saturate( lerp( dot( color.xyz, 0.333333f ), color.xyz, 1.0f + sw_r * r_adj_sat * ( 1.0f - curr_sat ))) :
                                                    saturate( lerp( dot( color.xyz, 0.333333f ), color.xyz, 1.0f + sw_r * r_adj_sat ));
        // Oranges
        curr_sat          = max( max( color.x, color.y ), color.z ) - min( min( color.x, color.y ), color.z );
        color.xyz         = ( o_adj_sat > 0.0f ) ?  saturate( lerp( dot( color.xyz, 0.333333f ), color.xyz, 1.0f + sw_o * o_adj_sat * ( 1.0f - curr_sat ))) :
                                                    saturate( lerp( dot( color.xyz, 0.333333f ), color.xyz, 1.0f + sw_o * o_adj_sat ));
        // Yellows
        curr_sat          = max( max( color.x, color.y ), color.z ) - min( min( color.x, color.y ), color.z );
        color.xyz         = ( y_adj_sat > 0.0f ) ?  saturate( lerp( dot( color.xyz, 0.333333f ), color.xyz, 1.0f + sw_y * y_adj_sat * ( 1.0f - curr_sat ))) :
                                                    saturate( lerp( dot( color.xyz, 0.333333f ), color.xyz, 1.0f + sw_y * y_adj_sat ));
        // Yellow-Greens
        curr_sat          = max( max( color.x, color.y ), color.z ) - min( min( color.x, color.y ), color.z );
        color.xyz         = ( yg_adj_sat > 0.0f ) ? saturate( lerp( dot( color.xyz, 0.333333f ), color.xyz, 1.0f + sw_yg * yg_adj_sat * ( 1.0f - curr_sat ))) :
                                                    saturate( lerp( dot( color.xyz, 0.333333f ), color.xyz, 1.0f + sw_yg * yg_adj_sat ));
        // Greens
        curr_sat          = max( max( color.x, color.y ), color.z ) - min( min( color.x, color.y ), color.z );
        color.xyz         = ( g_adj_sat > 0.0f ) ?  saturate( lerp( dot( color.xyz, 0.333333f ), color.xyz, 1.0f + sw_g * g_adj_sat * ( 1.0f - curr_sat ))) :
                                                    saturate( lerp( dot( color.xyz, 0.333333f ), color.xyz, 1.0f + sw_g * g_adj_sat ));
        // Green-Cyans
        curr_sat          = max( max( color.x, color.y ), color.z ) - min( min( color.x, color.y ), color.z );
        color.xyz         = ( gc_adj_sat > 0.0f ) ? saturate( lerp( dot( color.xyz, 0.333333f ), color.xyz, 1.0f + sw_gc * gc_adj_sat * ( 1.0f - curr_sat ))) :
                                                    saturate( lerp( dot( color.xyz, 0.333333f ), color.xyz, 1.0f + sw_gc * gc_adj_sat ));
        // Cyans
        curr_sat          = max( max( color.x, color.y ), color.z ) - min( min( color.x, color.y ), color.z );
        color.xyz         = ( c_adj_sat > 0.0f ) ?  saturate( lerp( dot( color.xyz, 0.333333f ), color.xyz, 1.0f + sw_c * c_adj_sat * ( 1.0f - curr_sat ))) :
                                                    saturate( lerp( dot( color.xyz, 0.333333f ), color.xyz, 1.0f + sw_c * c_adj_sat ));
        // Cyan-Blues
        curr_sat          = max( max( color.x, color.y ), color.z ) - min( min( color.x, color.y ), color.z );
        color.xyz         = ( cb_adj_sat > 0.0f ) ? saturate( lerp( dot( color.xyz, 0.333333f ), color.xyz, 1.0f + sw_cb * cb_adj_sat * ( 1.0f - curr_sat ))) :
                                                    saturate( lerp( dot( color.xyz, 0.333333f ), color.xyz, 1.0f + sw_cb * cb_adj_sat ));
        // Blues
        curr_sat          = max( max( color.x, color.y ), color.z ) - min( min( color.x, color.y ), color.z );
        color.xyz         = ( b_adj_sat > 0.0f ) ?  saturate( lerp( dot( color.xyz, 0.333333f ), color.xyz, 1.0f + sw_b * b_adj_sat * ( 1.0f - curr_sat ))) :
                                                    saturate( lerp( dot( color.xyz, 0.333333f ), color.xyz, 1.0f + sw_b * b_adj_sat ));
        // Blue-Magentas
        curr_sat          = max( max( color.x, color.y ), color.z ) - min( min( color.x, color.y ), color.z );
        color.xyz         = ( bm_adj_sat > 0.0f ) ? saturate( lerp( dot( color.xyz, 0.333333f ), color.xyz, 1.0f + sw_bm * bm_adj_sat * ( 1.0f - curr_sat ))) :
                                                    saturate( lerp( dot( color.xyz, 0.333333f ), color.xyz, 1.0f + sw_bm * bm_adj_sat ));
        // Magentas
        curr_sat          = max( max( color.x, color.y ), color.z ) - min( min( color.x, color.y ), color.z );
        color.xyz         = ( m_adj_sat > 0.0f ) ?  saturate( lerp( dot( color.xyz, 0.333333f ), color.xyz, 1.0f + sw_m * m_adj_sat * ( 1.0f - curr_sat ))) :
                                                    saturate( lerp( dot( color.xyz, 0.333333f ), color.xyz, 1.0f + sw_m * m_adj_sat ));
        // Magenta-Reds
        curr_sat          = max( max( color.x, color.y ), color.z ) - min( min( color.x, color.y ), color.z );
        color.xyz         = ( mr_adj_sat > 0.0f ) ? saturate( lerp( dot( color.xyz, 0.333333f ), color.xyz, 1.0f + sw_mr * mr_adj_sat * ( 1.0f - curr_sat ))) :
                                                    saturate( lerp( dot( color.xyz, 0.333333f ), color.xyz, 1.0f + sw_mr * mr_adj_sat ));
        // Whites
        curr_sat          = max( max( color.x, color.y ), color.z ) - min( min( color.x, color.y ), color.z );
        color.xyz         = ( w_adj_sat > 0.0f ) ?  saturate( lerp( dot( color.xyz, 0.333333f ), color.xyz, 1.0f + sWhites * w_adj_sat * ( 1.0f - curr_sat ))) :
                                                    saturate( lerp( dot( color.xyz, 0.333333f ), color.xyz, 1.0f + sWhites * w_adj_sat ));
        // Blacks
        curr_sat          = max( max( color.x, color.y ), color.z ) - min( min( color.x, color.y ), color.z );
        color.xyz         = ( bk_adj_sat > 0.0f ) ? saturate( lerp( dot( color.xyz, 0.333333f ), color.xyz, 1.0f + sBlacks * bk_adj_sat * ( 1.0f - curr_sat ))) :
                                                    saturate( lerp( dot( color.xyz, 0.333333f ), color.xyz, 1.0f + sBlacks * bk_adj_sat ));
        // Neutrals
        curr_sat          = max( max( color.x, color.y ), color.z ) - min( min( color.x, color.y ), color.z );
        color.xyz         = ( n_adj_sat > 0.0f ) ?  saturate( lerp( dot( color.xyz, 0.333333f ), color.xyz, 1.0f + sNeutrals * n_adj_sat * ( 1.0f - curr_sat ))) :
                                                    saturate( lerp( dot( color.xyz, 0.333333f ), color.xyz, 1.0f + sNeutrals * n_adj_sat ));

        // Lightness
        float3 temp       = 0.0f;

        // Reds
        curr_sat          = max( max( color.x, color.y ), color.z ) - min( min( color.x, color.y ), color.z );
        temp.xyz          = RGBToHSL( color.xyz );
        temp.z            = saturate( temp.z * ( 1.0f + r_adj_lig ));
        temp.z            = brightness_curve( temp.z, max( r_adj_lig_curve, 0.001f ) + 1.0f );                                                   
        color.xyz         = lerp( color.xyz, HSLToRGB( temp.xyz ), sw_r * smooth( curr_sat ));
        // Oranges
		curr_sat          = max( max( color.x, color.y ), color.z ) - min( min( color.x, color.y ), color.z );
        temp.xyz          = RGBToHSL( color.xyz );
        temp.z            = saturate( temp.z * ( 1.0f + o_adj_lig ));
        temp.z            = brightness_curve( temp.z, max( o_adj_lig_curve, 0.001f ) + 1.0f );                                                   
        color.xyz         = lerp( color.xyz, HSLToRGB( temp.xyz ), sw_o * smooth( curr_sat ));
        // Yellows
        curr_sat          = max( max( color.x, color.y ), color.z ) - min( min( color.x, color.y ), color.z );
        temp.xyz          = RGBToHSL( color.xyz );
        temp.z            = saturate( temp.z * ( 1.0f + y_adj_lig ));
        temp.z            = brightness_curve( temp.z, max( y_adj_lig_curve, 0.001f ) + 1.0f );                                                   
        color.xyz         = lerp( color.xyz, HSLToRGB( temp.xyz ), sw_y * smooth( curr_sat ));
        // Yellow-Greens
        curr_sat          = max( max( color.x, color.y ), color.z ) - min( min( color.x, color.y ), color.z );
        temp.xyz          = RGBToHSL( color.xyz );
        temp.z            = saturate( temp.z * ( 1.0f + yg_adj_lig ));
        temp.z            = brightness_curve( temp.z, max( yg_adj_lig_curve, 0.001f ) + 1.0f );                                                   
        color.xyz         = lerp( color.xyz, HSLToRGB( temp.xyz ), sw_yg * smooth( curr_sat ));
        // Greens
        curr_sat          = max( max( color.x, color.y ), color.z ) - min( min( color.x, color.y ), color.z );
        temp.xyz          = RGBToHSL( color.xyz );
        temp.z            = saturate( temp.z * ( 1.0f + g_adj_lig ));
        temp.z            = brightness_curve( temp.z, max( g_adj_lig_curve, 0.001f ) + 1.0f );                                                   
        color.xyz         = lerp( color.xyz, HSLToRGB( temp.xyz ), sw_g * smooth( curr_sat ));
        // Green-Cyans
        curr_sat          = max( max( color.x, color.y ), color.z ) - min( min( color.x, color.y ), color.z );
        temp.xyz          = RGBToHSL( color.xyz );
        temp.z            = saturate( temp.z * ( 1.0f + gc_adj_lig ));
        temp.z            = brightness_curve( temp.z, max( gc_adj_lig_curve, 0.001f ) + 1.0f );                                                   
        color.xyz         = lerp( color.xyz, HSLToRGB( temp.xyz ), sw_gc * smooth( curr_sat ));
        // Cyans
        curr_sat          = max( max( color.x, color.y ), color.z ) - min( min( color.x, color.y ), color.z );
        temp.xyz          = RGBToHSL( color.xyz );
        temp.z            = saturate( temp.z * ( 1.0f + c_adj_lig ));
        temp.z            = brightness_curve( temp.z, max( c_adj_lig_curve, 0.001f ) + 1.0f );                                                   
        color.xyz         = lerp( color.xyz, HSLToRGB( temp.xyz ), sw_c * smooth( curr_sat ));
        // Cyan-Blues
        curr_sat          = max( max( color.x, color.y ), color.z ) - min( min( color.x, color.y ), color.z );
        temp.xyz          = RGBToHSL( color.xyz );
        temp.z            = saturate( temp.z * ( 1.0f + cb_adj_lig ));
        temp.z            = brightness_curve( temp.z, max( cb_adj_lig_curve, 0.001f ) + 1.0f );                                                   
        color.xyz         = lerp( color.xyz, HSLToRGB( temp.xyz ), sw_cb * smooth( curr_sat ));
        // Blues
        curr_sat          = max( max( color.x, color.y ), color.z ) - min( min( color.x, color.y ), color.z );
        temp.xyz          = RGBToHSL( color.xyz );
        temp.z            = saturate( temp.z * ( 1.0f + b_adj_lig ));
        temp.z            = brightness_curve( temp.z, max( b_adj_lig_curve, 0.001f ) + 1.0f );                                                   
        color.xyz         = lerp( color.xyz, HSLToRGB( temp.xyz ), sw_b * smooth( curr_sat ));
        // Blue-Magentas
        curr_sat          = max( max( color.x, color.y ), color.z ) - min( min( color.x, color.y ), color.z );
        temp.xyz          = RGBToHSL( color.xyz );
        temp.z            = saturate( temp.z * ( 1.0f + bm_adj_lig ));
        temp.z            = brightness_curve( temp.z, max( bm_adj_lig_curve, 0.001f ) + 1.0f );                                                   
        color.xyz         = lerp( color.xyz, HSLToRGB( temp.xyz ), sw_bm * smooth( curr_sat ));
        // Magentas
        curr_sat          = max( max( color.x, color.y ), color.z ) - min( min( color.x, color.y ), color.z );
        temp.xyz          = RGBToHSL( color.xyz );
        temp.z            = saturate( temp.z * ( 1.0f + m_adj_lig ));
        temp.z            = brightness_curve( temp.z, max( m_adj_lig_curve, 0.001f ) + 1.0f );                                                   
        color.xyz         = lerp( color.xyz, HSLToRGB( temp.xyz ), sw_m * smooth( curr_sat ));
        // Magenta-Reds
        curr_sat          = max( max( color.x, color.y ), color.z ) - min( min( color.x, color.y ), color.z );
        temp.xyz          = RGBToHSL( color.xyz );
        temp.z            = saturate( temp.z * ( 1.0f + mr_adj_lig ));
        temp.z            = brightness_curve( temp.z, max( mr_adj_lig_curve, 0.001f ) + 1.0f );                                                   
        color.xyz         = lerp( color.xyz, HSLToRGB( temp.xyz ), sw_mr * smooth( curr_sat ));

        return float4( color.xyz, 1.0f );
    }

    //// TECHNIQUES /////////////////////////////////////////////////////////////////
    technique prod80_04_SelectiveColor_v2 <ui_label="prod80 04 颜色校正V2";>
    {
        pass prod80_sc
        {
            VertexShader   = PostProcessVS;
            PixelShader    = PS_SelectiveColor;
        }
    }
}
