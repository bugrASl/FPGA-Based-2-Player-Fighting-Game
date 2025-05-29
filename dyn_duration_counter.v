module dyn_duration_counter #(
  parameter integer WIDTH = 5    // enough bits to hold your largest limit
)(
  input  wire                   clk,
  input  wire                   nRst,      // activeâ€?high reset
  input  wire                   i_enable,  // run the count when high
  input  wire                   i_stop,    // synchronous clear
  input  wire [WIDTH-1:0]       i_limit,   // dynamic max count
  output reg                    o_done,    // pulses high when count reaches limit
  output reg  [WIDTH-1:0]       o_count    // for debug/monitor
);

  always @(posedge clk or negedge nRst) begin
    if (!nRst) begin
      o_count <= 0;
      o_done  <= 0;
    end
    else if (i_stop) begin
      o_count <= 0;
      o_done  <= 0;
    end
    else if (!i_enable) begin
      o_count <= 0;
      o_done  <= 0;
    end
    else begin
      if (!o_done) begin 
        if (o_count == (i_limit - 1)) begin
          o_done  <= 1;
          o_count <= o_count;        
        end else begin
          o_count <= o_count + 1;
        end
      end else begin
		o_count <= 0;
		o_done 	<= 0;
	  end		  
    end
  end

endmodule