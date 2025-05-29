module clock_divider #(parameter WIDTH = 32, parameter DIVISION_FACTOR = 1000000)(
    input clk,
    input nRst,
    output reg clk_out
);
//
//	Fout	=	Fin / (2.DIVISION_FACTOR)
//
reg [WIDTH-1:0] count;

always @(posedge clk or negedge nRst) begin
    if (~nRst) begin
        count <= 0;
        clk_out <= 0;
    end else begin
        if (count == DIVISION_FACTOR - 1) begin
            count <= 0;
            clk_out <= ~clk_out;
        end else
            count <= count + 1;
    end
end

endmodule
