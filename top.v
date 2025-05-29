/*
module top(
    input clk_50MHz,       // from Basys 3
    input reset,           // btnC on Basys 3
	 input [1:0] menu_select,
	 input attack_direction_1,
	 input [1:0] player1_attack,
	 input player1_left,
	 input player1_right,
	 input game_over_sig,
    output hsync,          // VGA port on Basys 3
    output vsync,          // VGA port on Basys 3
    output [7:0] rgb       // to DAC, 3 bits to VGA port on Basys 3
    );
    
    wire w_video_on, w_p_tick;
    wire [9:0] w_x, w_y;
    reg [7:0] rgb_reg;
    wire[7:0] rgb_next;
    
    vga_controller vc(.clk_50MHz(clk_50MHz), .reset(reset), .video_on(w_video_on), .hsync(hsync), 
                      .vsync(vsync), .p_tick(w_p_tick), .x(w_x), .y(w_y));
    pixel_generation pg(.clk(clk_50MHz), .reset(reset), .video_on(w_video_on), .menu_sel(menu_select), .pl1_attack_dir(attack_direction_1),
                        .pl1_attack(player1_attack), .pl1_left(player1_left), .pl1_right(player1_right), .game_over_int(game_over_sig), .x(w_x), .y(w_y), .rgb(rgb_next));
    
    always @(posedge clk_50MHz)
        if(w_p_tick)
            rgb_reg <= rgb_next;
            
    assign rgb = rgb_reg;
 
endmodule
*/

module top(
    input clk_50MHz,       // from Basys 3
    input reset,           // btnC on Basys 3
	 input [1:0] menu_select,
	 input attack_direction_1,
	 input [1:0] player1_attack,
	 input player1_left,
	 input player1_right,
	 input game_over_sig,
    output hsync,          // VGA port on Basys 3
    output vsync,          // VGA port on Basys 3
    output [7:0] rgb       // to DAC, 3 bits to VGA port on Basys 3
    );
    
    wire w_video_on, w_p_tick;
    wire [9:0] w_x, w_y;
    reg [7:0] rgb_reg;
    wire[7:0] rgb_next;
	 
	 /*
	 wire clock_in;
	 assign clock_in = (SW[0]) ? KEY[0] : clk;
	 */
	 
	 wire clk60hz;
	 wire b_forward, b_backwards, b_attack, b_dir_attack;
	 wire [4:0] countout;
	 wire [2:0] stateout;
	 
	 clock_divider #(.WIDTH(32), .DIVISION_FACTOR (416_667)) ///25 000 000 for 1Hz logic
	 clock60Hz(
    .clk(clk_50MHz),
    .nRst(1),
    .clk_out(clk60hz));
	 
	 character_asm_milestone gamelogic(
	.clk(clk60hz), 
	.nRst(1),
	.i_forward(player1_right), 
	.i_backward(player1_left), 
	.i_attack(player1_attack[0]),
	.o_count(countout),
	.o_state(stateout)
);
    assign b_backwards = (stateout == 3'b001) ? 1 : 0; 
    assign b_forward = (stateout == 3'b010) ? 1 : 0; 
	assign b_attack = (stateout == 3'b011) ? 1 : 0; 
    assign b_dir_attack = (stateout == 3'b100) ? 1 : 0; 
	 
    vga_controller vc(.clk_50MHz(clk_50MHz), .reset(reset), .video_on(w_video_on), .hsync(hsync), 
                      .vsync(vsync), .p_tick(w_p_tick), .x(w_x), .y(w_y));
    pixel_generation pg(.clk(clk_50MHz), .reset(reset), .video_on(w_video_on), .menu_sel(menu_select), .pl1_attack_dir(b_dir_attack),
                        .pl1_attack({b_attack, 1'b0}), .pl1_left(b_backwards), .pl1_right(b_forward), .game_over_int(game_over_sig), .x(w_x), .y(w_y), .rgb(rgb_next));
    
    always @(posedge clk_50MHz)
        if(w_p_tick)
            rgb_reg <= rgb_next;
            
    assign rgb = rgb_reg;
 
endmodule