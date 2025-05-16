//=== footsies_top.v ===
// File: 		footsies_top.v
// Description: Top-level module connecting all submodules for the Footsies FPGA game.
//              Instantiates Input Manager, Game FSM, Character FSMs, Hit Engine,
//              VGA Driver, Renderer, Seven-Segment Driver, and LED Controller.
//              Uses active-low reset buttons for FPGA.
// Author: 		bugrASl
// Date:   		15.05.2025
// Usage:   	Synthesize or simulate; ensure utils/ path is set correctly.

`timescale 1ns/1ps

module footsies_top #(
    parameter integer CLK_FREQ_HZ = 50000000,
    parameter integer GAME_HZ     = 60
)(
    input  wire         clk_50mhz_i,    // Onboard FPGA clock
    input  wire         rst_n_i,        // Active-low reset (button is active_low)
    input  wire [1:0]   SW_i,           // SW[0]=game mode, SW[1]=logic clock select
    input  wire [2:0]   buttons_p1_i,   // P1 inputs: {left, right, attack}
    input  wire [2:0]   buttons_p2_i,   // P2 inputs or ignored in 1P mode
    output wire         hsync_o,        // VGA HSYNC
    output wire         vsync_o,        // VGA VSYNC
    output wire [7:0]   red_o,          // VGA Red channel
    output wire [7:0]   green_o,        // VGA Green channel
    output wire [7:0]   blue_o,         // VGA Blue channel
    output wire [6:0]   seven_seg_o,    // 7-segment display output
    output wire [7:0]   leds_o          // Health LEDs
);

//-------------------------------------------------------------------------
// Reset Handling
//-------------------------------------------------------------------------
// Convert active-low reset input to internal active-high reset signal
wire rst_i = ~rst_n_i;

//-------------------------------------------------------------------------
// Clock Generation & Selection
//-------------------------------------------------------------------------
// Derive 60Hz clock from 50MHz input using a generic divider
wire clk_60hz_w;

// Clock Divider: Derive 60Hz clock from 50MHz input
clk_divider #(
    .IN_FREQ_HZ (CLK_FREQ_HZ),
    .OUT_FREQ_HZ(GAME_HZ)
) u_clk_divider (
    .clk_in_i   (clk_50mhz_i),
    .rst_i      (rst_i),
    .clk_out_o  (clk_60hz_w)
);

// Manual step clock (for debug) could be from an active-low button
wire manual_step_w = ~buttons_p1_i[0]; // example mapping, invert if needed

// Select between 60Hz automatic and manual step based on SW_i[1]
wire logic_clk_w = (SW_i[1]) ? manual_step_w : clk_60hz_w;

//-------------------------------------------------------------------------
// Input Manager
//-------------------------------------------------------------------------
// Debounces raw buttons, scans keypad for P2, and generates bot inputs in 1P mode
wire [2:0] btns_p1_w, btns_p2_w, bot_btns_w;
input_manager u_input_mgr (
    .clk_i        (logic_clk_w),
    .rst_i        (rst_i),
    .buttons_p1_i (buttons_p1_i),
    .buttons_p2_i (buttons_p2_i),
    .mode_i       (SW_i[0]),       // 0=2P, 1=1P vs bot
    .btns_p1_o    (btns_p1_w),
    .btns_p2_o    (btns_p2_w),
    .bot_btns_o   (bot_btns_w)
);

//-------------------------------------------------------------------------
// Game FSM
//-------------------------------------------------------------------------
// Controls menu, countdown, fight, and game-over sequencing
wire [1:0] game_state_w;
wire       countdown_en_w, fight_en_w, gameover_en_w;
wire       start_btn_w = btns_p1_w[2]; // e.g. attack button to confirm
wire       health_zero_p1_w, health_zero_p2_w;

game_fsm u_game_fsm (
    .clk_i           (logic_clk_w),
    .rst_i           (rst_i),
    .start_i         (start_btn_w),
    .p1_zero_i       (health_zero_p1_w),
    .p2_zero_i       (health_zero_p2_w),
    .state_o         (game_state_w),
    .countdown_en_o  (countdown_en_w),
    .fight_en_o      (fight_en_w),
    .gameover_en_o   (gameover_en_w)
);

//-------------------------------------------------------------------------
// Character FSM Instances
//-------------------------------------------------------------------------
// Player 1
wire [2:0] char_state_p1_w;
wire [9:0] xpos_p1_w;
wire [1:0] health_p1_w, block_p1_w;
character_fsm u_char_p1 (
    .clk_i        (logic_clk_w),
    .rst_i        (rst_i),
    .btns_i       (btns_p1_w),
    .opponent_x_i (xpos_p2_w),
    .enable_i     (fight_en_w),
    .char_state_o (char_state_p1_w),
    .xpos_o       (xpos_p1_w),
    .health_o     (health_p1_w),
    .block_o      (block_p1_w)
);

// Player 2 or Bot
wire [2:0] char_state_p2_w;
wire [9:0] xpos_p2_w;
wire [1:0] health_p2_w, block_p2_w;
character_fsm u_char_p2 (
    .clk_i        (logic_clk_w),
    .rst_i        (rst_i),
    .btns_i       ((SW_i[0]) ? bot_btns_w : btns_p2_w),
    .opponent_x_i (xpos_p1_w),
    .enable_i     (fight_en_w),
    .char_state_o (char_state_p2_w),
    .xpos_o       (xpos_p2_w),
    .health_o     (health_p2_w),
    .block_o      (block_p2_w)
);

// Health-zero flags
assign health_zero_p1_w = (health_p1_w == 2'd0);
assign health_zero_p2_w = (health_p2_w == 2'd0);

//-------------------------------------------------------------------------
// Hit-Detection Engine
//-------------------------------------------------------------------------
// Determines hits and blockstun events
wire hit_p1_w, hit_p2_w, blockstun_p1_w, blockstun_p2_w;
hit_engine u_hit_engine (
    .clk_i        (logic_clk_w),
    .rst_i        (rst_i),
    .state_p1_i   (char_state_p1_w),
    .state_p2_i   (char_state_p2_w),
    .xpos_p1_i    (xpos_p1_w),
    .xpos_p2_i    (xpos_p2_w),
    .hit_p1_o     (hit_p1_w),
    .hit_p2_o     (hit_p2_w),
    .block_p1_o   (blockstun_p1_w),
    .block_p2_o   (blockstun_p2_w)
);

//-------------------------------------------------------------------------
// VGA Driver & Renderer
//-------------------------------------------------------------------------
// VGA sync & color output
wire       blank_w;
wire [9:0] vga_x_w, vga_y_w;
wire [7:0] pixel_color_w;

vga_driver u_vga (
    .clk_i    (clk_25mhz_i),
    .rst_i    (rst_i),
    .color_i  (pixel_color_w),
    .hsync_o  (hsync_o),
    .vsync_o  (vsync_o),
    .red_o    (red_o),
    .green_o  (green_o),
    .blue_o   (blue_o),
    .blank_o  (blank_w),
    .x_o      (vga_x_w),
    .y_o      (vga_y_w)
);

// Maps game state, positions & health to pixel colors
renderer u_renderer (
    .clk_i         (clk_25mhz_i),
    .rst_i         (rst_i),
    .x_i           (vga_x_w),
    .y_i           (vga_y_w),
    .game_state_i  (game_state_w),
    .c0_state_i    (char_state_p1_w),
    .c1_state_i    (char_state_p2_w),
    .x0_i          (xpos_p1_w),
    .x1_i          (xpos_p2_w),
    .h0_i          (health_p1_w),
    .h1_i          (health_p2_w),
    .b0_i          (block_p1_w),
    .b1_i          (block_p2_w),
    .pixel_color_o (pixel_color_w)
);

//-------------------------------------------------------------------------
// Seven-Segment Display Driver
//-------------------------------------------------------------------------
// Shows "MENU", "FIGHt", "P1-XX-", etc.
// TODO: feed timer count into driver
seven_seg_driver u_sevseg (
    .clk_i         (clk_25mhz_i),
    .rst_i         (rst_i),
    .mode_i        (game_state_w),
    .time_i        (timer_count_w),
    .seg_o         (seven_seg_o)
);

//-------------------------------------------------------------------------
// LED Controller
//-------------------------------------------------------------------------
// Health LEDs: left 3 = P1, right 3 = P2
led_controller u_led (
    .clk_i      (clk_25mhz_i),
    .rst_i      (rst_i),
    .h0_i       (health_p1_w),
    .h1_i       (health_p2_w),
    .leds_o     (leds_o)
);

endmodule
