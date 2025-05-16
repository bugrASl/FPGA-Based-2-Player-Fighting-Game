//=== time_counter.v ===
// File: 		time_counter.v
// Description: Counts real time in seconds once the fight state is active.
//              Uses a tick counter that rolls over every CLK_FREQ_HZ ticks to increment seconds.
// Author: 		bugrASl
// Date:   		15.05.2025
// Usage:   	Instantiate in top-level: connect clk_logic_i, rst_i, fight_enable.

`timescale 1ns/1ps

module time_counter #(
    parameter integer CLK_FREQ_HZ = 60_000_000  // System clock frequency in Hz
)(
    input  wire        clk_i,        // System clock input
    input  wire        rst_i,        // Synchronous reset (active high)
    input  wire        enable_i,     // Enable counting when fight is active
    output reg [7:0]   seconds_o     // Elapsed seconds (0–99)
);

// Calculate number of bits needed for tick counter
localparam integer TICK_CNT_WIDTH = $clog2(CLK_FREQ_HZ);
// Number of clock cycles per second
localparam integer TICKS_PER_SEC = CLK_FREQ_HZ - 1;

// Tick counter (counts sysclk cycles)
reg [TICK_CNT_WIDTH-1:0] tick_count_r;

always @(posedge clk_i or posedge rst_i) begin
    if (rst_i) begin
        tick_count_r <= '0;
        seconds_o    <= '0;
    end else if (!enable_i) begin
        // Reset when not enabled
        tick_count_r <= '0;
        seconds_o    <= '0;
    end else begin
        if (tick_count_r == TICKS_PER_SEC) begin
            tick_count_r <= '0;
            // Roll over seconds at 99
            if (seconds_o == 8'd99)
                seconds_o <= '0;
            else
                seconds_o <= seconds_o + 1'b1;
        end else begin
            tick_count_r <= tick_count_r + 1'b1;
        end
    end
end

endmodule
