//=== char_utils.vh ===
// File:		char_utils.vh
// Description: Header with Character FSM state encodings, timing constants,
//              combinational decoder, and attack handling task.
// Author: 		bugrASl
// Date:   		15.05.2025
// Usage:  		`include "../utils/char_utils.vh" in character_fsm.v

`ifndef CHAR_UTILS_VH
`define CHAR_UTILS_VH

// Character state encodings (3 bits)
`define C_IDLE        3'd0
`define C_MOVE_FWD    3'd1
`define C_MOVE_BWD    3'd2
`define C_ATK_BASIC   3'd3
`define C_ATK_DIR     3'd4
`define C_HITSTUN     3'd5
`define C_BLOCKSTUN   3'd6

// Attack & stun timings (frames @ 60Hz)
`define T_ATK_STARTUP 4
`define T_ATK_ACTIVE  6
`define T_ATK_RECOV   8
`define T_HITSTUN     10
`define T_BLOCKSTUN   5

// Combinational decoder: maps button vector to next state
function [2:0] decode_char_state;
    input [2:0] btns; // {left, right, attack}
    begin
        if (btns[2])       decode_char_state = `C_ATK_BASIC;
        else if (btns[1])  decode_char_state = `C_MOVE_FWD;
        else if (btns[0])  decode_char_state = `C_MOVE_BWD;
        else               decode_char_state = `C_IDLE;
    end
endfunction

// Procedural attack sequence handler
task handle_attack;
    inout reg [2:0] state_r;
    inout reg [7:0] timer_r;
    begin
        if (timer_r == 0) begin
            state_r = `C_ATK_BASIC;
            timer_r = `T_ATK_STARTUP;
        end else if (timer_r < (`T_ATK_STARTUP + `T_ATK_ACTIVE)) begin
            state_r = `C_ATK_BASIC;
            timer_r = timer_r - 1;
        end else begin
            state_r = `C_IDLE;
            timer_r = 0;
        end
    end
endtask

`endif // CHAR_UTILS_VH
