//=== vga_utils.vh ===
// File: 		vga_utils.vh
// Description: Centralized VGA timing localparams for controller & renderer.
// Author: 		bugrASl
// Date:   		15.05.2025
// Usage:   	`include "../utils/vga_utils.vh" in vga_driver.v or renderer.v

`ifndef VGA_UTILS_VH
`define VGA_UTILS_VH

localparam H_ACTIVE = 640;
localparam H_FRONT  = 16;
localparam H_SYNC   = 96;
localparam H_BACK   = 48;
localparam H_TOTAL  = H_ACTIVE + H_FRONT + H_SYNC + H_BACK;

localparam V_ACTIVE = 480;
localparam V_FRONT  = 10;
localparam V_SYNC   = 2;
localparam V_BACK   = 33;
localparam V_TOTAL  = V_ACTIVE + V_FRONT + V_SYNC + V_BACK;

`endif // VGA_UTILS_VH
