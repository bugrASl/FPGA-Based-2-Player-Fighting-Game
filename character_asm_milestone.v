module character_asm_milestone(
	input 	clk, nRst,
	input 	i_forward, i_backward, i_attack,
	output[4:0]	o_count,
	output[2:0] o_state
);

	localparam[2:0]	IDLE 		= 3'b000, 
					BACKWARD 	= 3'b001, 
					FORWARD 	= 3'b010, 
					ATTACK 		= 3'b011, 
					DIR_ATTACK 	= 3'b100;
				
	localparam[4:0] ATTACK_COUNT_MAX 		= 5'd23,
					DIR_ATTACK_COUNT_MAX 	= 5'd22;
	
	reg[2:0]	c_state_reg,
				n_state_reg;
	
	wire 		movement_flag, 
				attack_flag, 
				backward_flag,
				cnt_enable_w,
				cnt_done_w,
				cnt_stop_w;
				
	wire [4:0]	cnt_limit_w;
	
	dyn_duration_counter #(
		.WIDTH(5)
	) state_timer_i (
		.clk    (clk),
		.nRst   (nRst),
		.i_enable (cnt_enable_w),
		.i_stop   (cnt_stop_w),
		.i_limit  (cnt_limit_w),
		.o_done   (cnt_done_w),
		.o_count  (o_count));

	always @(posedge clk or negedge nRst)
	begin
		if(~nRst)
			c_state_reg <= 0;
		else
			c_state_reg	<= n_state_reg;
	end
	
	always @(*)
	begin
		n_state_reg = c_state_reg;
		case(c_state_reg)
			IDLE:
			begin
				if(movement_flag) begin
					if(attack_flag)
						n_state_reg = DIR_ATTACK;
					else begin
						if(backward_flag)
							n_state_reg = BACKWARD;
						else
							n_state_reg	= FORWARD;
					end	
				end else begin
					if(attack_flag)
						n_state_reg = ATTACK;
					else
						n_state_reg = IDLE;
				end
			end
			BACKWARD:
			begin
				if(i_backward)
					n_state_reg = BACKWARD;
				else
					n_state_reg = IDLE;
			end
			FORWARD:
			begin
				if(i_forward)
					n_state_reg = FORWARD;
				else
					n_state_reg = IDLE;
			end
			ATTACK:
			begin
				if(cnt_done_w)
					n_state_reg = IDLE;
				else
					n_state_reg = ATTACK;				
			end
			DIR_ATTACK:
			begin
				if(cnt_done_w)
					n_state_reg = IDLE;
				else
					n_state_reg = DIR_ATTACK;		
			end
			default:	n_state_reg = IDLE;
		endcase	
	end	
	
	assign movement_flag	= i_forward | i_backward;
	assign backward_flag	= i_backward;
	assign attack_flag		= i_attack;
	assign o_state			= c_state_reg;
	assign cnt_enable_w 	= (c_state_reg == ATTACK)     ||
							  (c_state_reg == DIR_ATTACK);
	assign cnt_limit_w =	(c_state_reg == ATTACK)     ? ATTACK_COUNT_MAX   :
							(c_state_reg == DIR_ATTACK) ? DIR_ATTACK_COUNT_MAX : 0;				
endmodule