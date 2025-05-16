//=== input_manager.v ===
// File: 		input_manager.v
// Description: Reads and debounces FPGA switches and scans two
//              4×4 keypads, producing clean game-action and debug signals.
//              Separates gameplay controls (keypad) from FPGA switch controls.
// Author: 		bugrASl
// Date:   		16.05.2025
// Usage:   	Instantiate in top-level; connect clock, reset, GPIO pins.

`timescale 1ns/1ps
`include "../utils/debounce_utils.vh"
`include "../utils/input_utils.vh"

module input_manager(
    input  wire        clk_i,          // System clock (e.g. 50 MHz)
    input  wire        rst_i,          // Active-high reset

    // FPGA switch inputs (active-low): debug & mode selection
    input  wire [4:0]  sw_i,           // {show_hitboxes, show_hurtboxes, restart, mode_select, clk_source_sel}

    // Keypad matrix for Player 1 (active-low rows/cols)
    output reg  [3:0]  p1_row_o,
    input  wire [3:0]  p1_col_i,
    // Keypad matrix for Player 2
    output reg  [3:0]  p2_row_o,
    input  wire [3:0]  p2_col_i,

    // Cleaned gameplay inputs (from keypad only)
    output reg         move_left_p1_o,
    output reg         move_right_p1_o,
    output reg         attack_p1_o,
    output reg	       select_p1_o,
	
    output reg         move_left_p2_o,
    output reg         move_right_p2_o,
    output reg         attack_p2_o,
    output reg	       select_p2_o,

    // Cleaned FPGA switch controls (debug/mode)
    output reg         show_hitboxes_o,
    output reg         show_hurtboxes_o,
    output reg         restart_o,
    output reg         mode_select_o,
    output reg         clk_source_sel_o
);

//---------------------------------------------------------------------------
// 1. Debounce FPGA switches
//---------------------------------------------------------------------------
reg [DEBOUNCE_BITS-1:0] db_shift_sw [4:0];
reg                     clean_sw   [4:0];
integer                 j;
always_ff @(posedge clk_i or posedge rst_i) begin
    if (rst_i) begin
        for (j = 0; j < 5; j = j+1) clean_sw[j] <= 1'b0;
    end else begin
        for (j = 0; j < 5; j = j+1) begin
            debounce_button(~sw_i[j], clean_sw[j], db_shift_sw[j]);
        end
    end
end

always_ff @(posedge clk_i or posedge rst_i) begin
    if (rst_i) begin
        {show_hitboxes_o, show_hurtboxes_o,
         restart_o, mode_select_o, clk_source_sel_o} <= 5'b00000;
    end else begin
        show_hitboxes_o  <= clean_sw[0];
        show_hurtboxes_o <= clean_sw[1];
        restart_o        <= clean_sw[2];
        mode_select_o    <= clean_sw[3];
        clk_source_sel_o <= clean_sw[4];
    end
end

//---------------------------------------------------------------------------
// 2. Scan Keypads using scan_keypad task
//---------------------------------------------------------------------------
reg [31:0] scan_cnt_p1, scan_cnt_p2;
reg  [1:0] scan_row_p1, scan_row_p2;
reg  [3:0] p1_cols_sample, p2_cols_sample;
always_ff @(posedge clk_i or posedge rst_i) begin
    scan_keypad(clk_i, rst_i, scan_cnt_p1, scan_row_p1, p1_row_o, p1_col_i, p1_cols_sample);
    scan_keypad(clk_i, rst_i, scan_cnt_p2, scan_row_p2, p2_row_o, p2_col_i, p2_cols_sample);
end

//---------------------------------------------------------------------------
// 3. Decode Keypad Samples into Gameplay Controls
//---------------------------------------------------------------------------
always_comb begin
    // Defaults: no action
    move_left_p1_o  = 1'b0;
    move_right_p1_o = 1'b0;
    attack_p1_o     = 1'b0;
    move_left_p2_o  = 1'b0;
    move_right_p2_o = 1'b0;
    attack_p2_o     = 1'b0;

    // Decode Player 1 from keypad
    case (decode_keypad_action(scan_row_p1, p1_cols_sample))
        `ACT_LEFT:   move_left_p1_o  = 1'b1;
        `ACT_RIGHT:  move_right_p1_o = 1'b1;
        `ACT_ATTACK: attack_p1_o     = 1'b1;
	`SELECT:     select_p1_o     = 1'b1;
        default: ;
    endcase

    // Decode Player 2 from keypad
    case (decode_keypad_action(scan_row_p2, p2_cols_sample))
        `ACT_LEFT:   move_left_p2_o  = 1'b1;
        `ACT_RIGHT:  move_right_p2_o = 1'b1;
        `ACT_ATTACK: attack_p2_o     = 1'b1;
	`SELECT:     select_p2_o     = 1'b0;
        default: ;
    endcase
end

endmodule
