//=== input_utils.vh ===
// File: 		input_utils.vh
// Description: Keypad decoding utilities and action definitions.
// Author: 		bugrASl
// Date:   		16.05.2025
// Usage:   	`include "../utils/input_utils.vh" in input_manager.v

`ifndef INPUT_UTILS_VH
`define INPUT_UTILS_VH

//------------------------------------------------------------------------------
// Scan timing definitions
//------------------------------------------------------------------------------
`define SCAN_FREQ_HZ 1000                 // Row scan frequency in Hz
`define SYS_FREQ_HZ  50000000             // System clock frequency in Hz
`define SCAN_PERIOD  (`SYS_FREQ_HZ / `SCAN_FREQ_HZ)

//------------------------------------------------------------------------------
// Action codes (3-bit): {move_left, move_right, attack}
//------------------------------------------------------------------------------
`define ACT_NONE    3'b000
`define ACT_LEFT    3'b100
`define ACT_RIGHT   3'b010
`define ACT_ATTACK  3'b001
`define	SELECT		3'b111

//------------------------------------------------------------------------------
// scan_keypad Task
// Scans a 4×4 matrix keypad by driving rows and sampling columns
// Inputs:
//   clk_i       - system clock
//   rst_i       - active-high reset
//   SCAN_PERIOD - number of clk_i cycles per row
// InOut:
//   scan_cnt    - counter up to SCAN_PERIOD
//   scan_row    - current row index (0 to 3)
// Inputs:
//   col_i       - 4-bit raw column inputs (active-low)
// Outputs:
//   row_o       - 4-bit row drive outputs (one row low at a time)
//   cols_sample - 4-bit sampled column states (1 = pressed)
//------------------------------------------------------------------------------
task automatic scan_keypad(
    input  wire             clk_i,
    input  wire             rst_i,
    input  integer          SCAN_PERIOD,
    inout  reg     [31:0]   scan_cnt,
    inout  reg     [1:0]    scan_row,
    output reg     [3:0]    row_o,
    input  wire    [3:0]    col_i,
    output reg     [3:0]    cols_sample
);
begin
    if (rst_i) begin
        scan_cnt    = 32'd0;
        scan_row    = 2'd0;
        row_o       = 4'b1111;
        cols_sample = 4'd0;
    end else if (scan_cnt == SCAN_PERIOD-1) begin
        scan_cnt    = 32'd0;
        scan_row    = scan_row + 2'd1;
        row_o       = ~(4'b0001 << scan_row);
        cols_sample = ~col_i;
    end else begin
        scan_cnt    = scan_cnt + 32'd1;
    end
end
endtask

//------------------------------------------------------------------------------
// decode_keypad_action Function
// Maps (row, columns) to one of the 3 action codes
// Inputs:
//   row         - active row index (0 to 3)
//   cols_sample - 4-bit column sample (1 = pressed)
// Output:
//   3-bit action code
//------------------------------------------------------------------------------
function automatic [2:0] decode_keypad_action(
    input [1:0] row,
    input [3:0] cols_sample
);
begin
    decode_keypad_action = `ACT_NONE;
    case (row)
		2'd0: begin
			if(cols_i[3])		decode_keypad_action = `SELECT;
		end
        2'd1: begin
			if (cols_i[0]) 		decode_keypad_action = `ACT_LEFT;
			else if (cols_i[2]) decode_keypad_action = `ACT_RIGHT;
			else if (cols_i[1]) decode_keypad_action = `ACT_ATK;
			else                decode_keypad_action = `ACT_NONE;
		end
        default: ;
    endcase
end
endfunction

`endif // INPUT_UTILS_VH
