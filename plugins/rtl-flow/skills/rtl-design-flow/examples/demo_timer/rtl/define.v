`timescale 1ns / 1ps
//==============================================================================
// File name   : define.v
// Function    : 全局宏定义：复位极性、仿真延时（rtl-coding-style HW-07）
// Version     : 1.0
// Date        : 2026-10-26
// Doc         : doc/05_rtl_structure.md
//==============================================================================
`define RST_EDGE negedge    // 复位有效沿：低有效（ASM-004）
`define RST_ACT  1'b0       // 复位有效电平，与 RST_EDGE 对应
`define U_DLY    1          // 非阻塞赋值的仿真延时，1 ns，综合时忽略
