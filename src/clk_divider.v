//=== clk_divider.v ===
// File:		clk_divider.v
// Description: Generic clock divider that generates a lower-frequency clock.
//              Parameterized by input clock frequency and desired output frequency.
//              Uses a counter to toggle the output clock.
//
// Author: 		bugrASl
// Date:   		15.05.2025
// Usage:   	Instantiate in top-level: connect clk_i, rst_i, and receive clk_o.

`timescale 1ns/1ps
module clk_divider #(
    parameter integer CLK_FREQ_HZ = 50000000,    // Input clock frequency in Hz
    parameter integer OUT_FREQ_HZ = 60           // Desired output clock frequency in Hz
)(
    input  wire clk_i,                            // System clock input
    input  wire rst_i,                            // Active-high synchronous reset
    output reg  clk_o                             // Divided clock output
);

    // Calculate half period count for toggling clk_o
    localparam integer HALF_PERIOD = CLK_FREQ_HZ / (2 * OUT_FREQ_HZ);
    // Width of counter register
    localparam integer CTR_WIDTH = $clog2(HALF_PERIOD);

    // Counter to track half-period cycles
    reg [CTR_WIDTH-1:0] counter_r;

    // Clock division logic: toggle clk_o every HALF_PERIOD cycles
    always_ff @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            counter_r <= {CTR_WIDTH{1'b0}};
            clk_o     <= 1'b0;
        end else begin
            if (counter_r == HALF_PERIOD - 1) begin
                counter_r <= {CTR_WIDTH{1'b0}};
                clk_o     <= ~clk_o;
            end else begin
                counter_r <= counter_r + 1'b1;
            end
        end
    end

endmodule
