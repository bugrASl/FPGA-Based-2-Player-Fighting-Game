//=== debounce_utils.vh ===
// File: 		debounce_utils.vh
// Description: Debouncing utility header with a reusable task to filter mechanical switch bounces.
// Author: 		bugrASl
// Date:   		16.05.2025
// Usage:   	`include "../utils/debounce_utils.vh" in input_manager.v

`ifndef DEBOUNCE_UTILS_VH
`define DEBOUNCE_UTILS_VH

// Number of samples required for stable input. Adjust as needed.
`ifndef DEBOUNCE_BITS
`define DEBOUNCE_BITS 8
`endif

// Debounce task: shifts in raw samples, updates clean_o when stable
// Inputs:
//   raw_i     - raw sampled input (1 = pressed, 0 = released)
// InOut:
//   shift_reg - shift register of width DEBOUNCE_BITS
// Output:
//   clean_o   - debounced output (1 = pressed, 0 = released)
task debounce_button(
    input  wire raw_i,
    output reg  clean_o,
    inout  reg  [DEBOUNCE_BITS-1:0] shift_reg
);
begin
    // shift in new sample
    shift_reg = { shift_reg[DEBOUNCE_BITS-2:0], raw_i };
    // if all bits are 1 => stable high
    if (&shift_reg)
        clean_o = 1'b1;
    // if all bits are 0 => stable low
    else if (~|shift_reg)
        clean_o = 1'b0;
    // else clean_o remains previous value
end
endtask


`endif // DEBOUNCE_UTILS_VH
