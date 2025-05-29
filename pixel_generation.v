module pixel_generation(
    input clk,                              // 50MHz from DE10Lite
    input reset,                            // btnC
    input video_on,                         // from VGA controller
	 input [1:0] menu_sel,
	 input pl1_attack_dir,					// attack directional
	 input [1:0] pl1_attack,				// phases of player 1's attack
	 input pl1_left,						//  basic:         000 none, 001 startup, 010 active, 011 recovery
	 input pl1_right,						//	directional:	100 none, 101 startup, 110 active, 111 recovery
	 input game_over_int,
    input [9:0] x, y,                       // from VGA controller
    output reg [7:0] rgb                    // to DAC, to VGA controller
);
    
    parameter X_MAX = 639;                  // right border of display area
    parameter Y_MAX = 479;                  // bottom border of display area
    parameter PL1_RGB = 8'hFC;              // yellow color for pl1
	parameter PL1_HITBOX_RGB = 8'hEA;       // yellow hurtbox for pl1
	parameter PL1_HURTBOX_RGB = 8'hFF;      // yellow hurtbox for pl1
	parameter PL1_INFOBOX_RGB = 8'h0F;      // yellow hurtbox for pl1
    parameter BG_RGB = 8'h03;               // blue background
	parameter GROUND_RGB = 8'h64; 			// e.g., dark green or brown (choose appropriate value)
	parameter GROUND_HEIGHT = 50;			// height of ground
    parameter PLAYER1_SIZE_X = 64;          // width of PLAYER1 sides in pixels
	parameter PLAYER1_SIZE_Y = 240;         // width of PLAYER1 sides in pixels
    
    // create a 60Hz refresh tick at the start of vsync 
    wire refresh_tick;
    assign refresh_tick = ((y == 481) && (x == 0)) ? 1 : 0;
	 
	 reg game_screen, menu_screen;
    
    // PLAYER1 boundaries and position
    wire [9:0] pl1_x_l, pl1_x_r;              // PLAYER1 left and right boundary
    wire [9:0] pl1_y_t, pl1_y_b;              // PLAYER1 top and bottom boundary
    
    reg signed [10:0] pl1_x_reg, pl1_y_reg;          // regs to track left, top position
    wire [9:0] pl1_x_next, pl1_y_next;        // buffer wires
    
    reg signed [10:0] x_delta_reg, y_delta_reg;       // track PLAYER1 speed
    reg signed [10:0] x_delta_next, y_delta_next;     // buffer regs    
    
    always @(posedge clk) begin:SEQ
        if(reset | menu_screen) begin				 // reset input or menu window clears the position(s)
            pl1_x_reg <= X_MAX/2 - PLAYER1_SIZE_X/2 -1;
            pl1_y_reg <= Y_MAX - GROUND_HEIGHT - PLAYER1_SIZE_Y + 1;
            x_delta_reg <= 10'h000; // zero speed
			   y_delta_reg <= 10'h000; // zero speed
				// clear also the stats of the player(s) in the future
        end
        else begin
				if(game_screen) begin				  // only update the values if the game screen is on
					pl1_x_reg <= pl1_x_next;
					pl1_y_reg <= Y_MAX - GROUND_HEIGHT - PLAYER1_SIZE_Y + 1;
					x_delta_reg <= x_delta_next;
					y_delta_reg <= y_delta_next;
					// record also the stats of the player(s) in the future
				end
        end
	 end
	 
	 // Ground boundaries
	 wire [9:0] ground_y_t, ground_y_b;
	 assign ground_y_b = Y_MAX;
	 assign ground_y_t = Y_MAX - GROUND_HEIGHT + 1;

	 // inside ground boundaries signal
	 wire ground_on;
	 assign ground_on = (y >= ground_y_t) && (y <= ground_y_b);
	 
	 // Top bar boundaries
	 wire [9:0] topbar_y_t, topbar_y_b;
	 assign topbar_y_t = 0;  // topmost Y
	 assign topbar_y_b = GROUND_HEIGHT - 1;  // same height with ground of game screen
	 
	 // inside top bar boundaries signal
	 wire topbar_on;
	 assign topbar_on = (y >= topbar_y_t) && (y <= topbar_y_b);
	 
    // PLAYER1 boundaries (hurtbox)
    assign pl1_x_l = pl1_x_reg;                      // left boundary
    assign pl1_y_t = pl1_y_reg;                      // top boundary
    assign pl1_x_r = pl1_x_l + PLAYER1_SIZE_X - 1;   // right boundary
    assign pl1_y_b = pl1_y_t + PLAYER1_SIZE_Y - 1;   // bottom boundary
    
    // inside PLAYER1 boundaries signal (hurtbox)
    wire pl1_on;
	 assign pl1_on = (
		 (pl1_x_l <= x && x <= pl1_x_r) &&
		 (pl1_y_t <= y && y <= pl1_y_b) &&
		 (
			  (x == pl1_x_l) || (x == pl1_x_r) ||     // vertical edges
			  (y == pl1_y_t) || (y == pl1_y_b)        // horizontal edges
		 )
	 );
	 
	 /*
	 // PLAYER1 basic attack start hitbox boundaries
	 wire [9:0] atk_1bs_x_l, atk_1bs_x_r;
	 wire [9:0] atk_1bs_y_t, atk_1bs_y_b;
	 assign atk_1bs_x_l = pl1_x_r + 1;
	 assign atk_1bs_x_r = atk_1bs_x_l + 88 - 1;
	 assign atk_1bs_y_t = pl1_y_t + 35 - 1;
	 assign atk_1bs_y_b = atk_1bs_y_t + 10 - 1;
    wire atk_1bs_on; // hitbox on signal
	 assign atk_1bs_on = 
		 (atk_1bs_x_l <= x && x <= atk_1bs_x_r) &&
		 (atk_1bs_y_t <= y && y <= atk_1bs_y_b) &&
		 (
			  (x == atk_1bs_x_l) || (x == atk_1bs_x_r) || 
			  (y == atk_1bs_y_t) || (y == atk_1bs_y_b)
    );
	 wire atk_1bs_inside; // hitbox on signal
	 assign atk_1bs_inside = 
		 (atk_1bs_x_l <= x && x <= atk_1bs_x_r) &&
		 (atk_1bs_y_t <= y && y <= atk_1bs_y_b);
*/
	// -----------------------------------------------------------------------------
	// PLAYER1 basic attack hitbox with extended border margin
	// -----------------------------------------------------------------------------
// Original box bounds (unchanged)
wire [9:0] atk_1bs_x_l = pl1_x_r + 1;
wire [9:0] atk_1bs_x_r = atk_1bs_x_l + 88 - 1;
wire [9:0] atk_1bs_y_t = pl1_y_t   + 35 - 1;
wire [9:0] atk_1bs_y_b = atk_1bs_y_t + 10 - 1;

// Inside‐fill exactly as before
wire atk_1bs_inside = 
    (atk_1bs_x_l <= x && x <= atk_1bs_x_r) &&
    (atk_1bs_y_t <= y && y <= atk_1bs_y_b);

// Vertical margin amount only
localparam integer V_MARGIN = 8;

// Extended Y‐bounds only
wire [9:0] ext_y_t = (atk_1bs_y_t > V_MARGIN) ? atk_1bs_y_t - V_MARGIN : 10'd0;
wire [9:0] ext_y_b = atk_1bs_y_b + V_MARGIN;

// Border now only on the top/bottom edges of the extended box,
// and still on the original left/right edges
wire atk_1bs_on = 
    // must be within the original X span
    (atk_1bs_x_l <= x && x <= atk_1bs_x_r) &&
    // but within the vertically-extended region
    (ext_y_t    <= y && y <= ext_y_b) &&
    // and exactly on one of the four border lines:
    (
      // left & right sides (original box)
      (x == atk_1bs_x_l) || (x == atk_1bs_x_r) ||
      // top & bottom of the extended region
      (y == ext_y_t)    || (y == ext_y_b)
    );

// Final signals for your renderer
wire hitbox_fill   = atk_1bs_inside;
wire hitbox_border = atk_1bs_on;

/*
	 // PLAYER1 basic attack active boundaries
	 wire [9:0] atk_1ba_x_l, atk_1ba_x_r;
	 wire [9:0] atk_1ba_y_t, atk_1ba_y_b;
	 assign atk_1ba_x_l = pl1_x_r + 1;
	 assign atk_1ba_x_r = atk_1ba_x_l + 88 - 1;
	 assign atk_1ba_y_t = pl1_y_t + 35 - 1;
	 assign atk_1ba_y_b = atk_1ba_y_t + 10 - 1;
    wire atk_1ba_on;
    //assign atk_1ba_on = (atk_1ba_x_l <= x) && (x <= atk_1ba_x_r) && (atk_1ba_y_t <= y) && (y <= atk_1ba_y_b);
	 assign atk_1ba_on = 
		 (atk_1ba_x_l <= x && x <= atk_1ba_x_r) &&
		 (atk_1ba_y_t <= y && y <= atk_1ba_y_b) &&
		 (
			  (x == atk_1ba_x_l) || (x == atk_1ba_x_r) || 
			  (y == atk_1ba_y_t) || (y == atk_1ba_y_b)
    );
	 wire atk_1ba_inside;
	 assign atk_1ba_inside = 
     (atk_1ba_x_l < x && x < atk_1ba_x_r) &&
     (atk_1ba_y_t < y && y < atk_1ba_y_b);
*/
//-----------------------------------------------------------------------------
// PLAYER1 basic attack “active” hitbox with vertical‐only margin
//-----------------------------------------------------------------------------

// 1) Original box bounds (unchanged)
wire [9:0] atk_1ba_x_l = pl1_x_r + 1;
wire [9:0] atk_1ba_x_r = atk_1ba_x_l + 88 - 1;
wire [9:0] atk_1ba_y_t = pl1_y_t   + 35 - 1;
wire [9:0] atk_1ba_y_b = atk_1ba_y_t + 10 - 1;

// 2) Unmodified inside‐fill region
	wire atk_1ba_inside = 
		 (atk_1ba_x_l < x && x < atk_1ba_x_r) &&
		 (atk_1ba_y_t < y && y < atk_1ba_y_b);

	// 3) Vertical margin amount (pixels above & below)
	localparam integer V_MARGIN_ACTIVE = 8;

	// 4) Compute extended Y bounds only
	wire [9:0] ext_y_t_ba = (atk_1ba_y_t > V_MARGIN_ACTIVE)
									? atk_1ba_y_t - V_MARGIN_ACTIVE
									: 10'd0;
	wire [9:0] ext_y_b_ba = atk_1ba_y_b + V_MARGIN_ACTIVE;

// 5) Border: within original X span, within extended Y span, and on one of the edges
	wire atk_1ba_on =
    // inside the horizontally‐limited region
    (atk_1ba_x_l <= x && x <= atk_1ba_x_r) &&
    // within the vertically‐extended region
    (ext_y_t_ba    <= y && y <= ext_y_b_ba) &&
    // exactly on a border line:
    (
      // original left/right edges
      (x == atk_1ba_x_l) || (x == atk_1ba_x_r) ||
      // extended top/bottom edges
      (y == ext_y_t_ba)  || (y == ext_y_b_ba)
    );
/*
	 // PLAYER1 basic attack recovery boundaries
	 wire [9:0] atk_1br_x_l, atk_1br_x_r;
	 wire [9:0] atk_1br_y_t, atk_1br_y_b;
	 assign atk_1br_x_l = pl1_x_r + 1;
	 assign atk_1br_x_r = atk_1br_x_l + 44 - 1;
	 assign atk_1br_y_t = pl1_y_t + 35 - 1;
	 assign atk_1br_y_b = atk_1br_y_t + 10 - 1;
    wire atk_1br_on;
	 assign atk_1br_on = 
		 (atk_1br_x_l <= x && x <= atk_1br_x_r) &&
		 (atk_1br_y_t <= y && y <= atk_1br_y_b) &&
		 (
			  (x == atk_1br_x_l) || (x == atk_1br_x_r) || 
			  (y == atk_1br_y_t) || (y == atk_1br_y_b)
    );
	 wire atk_1br_inside;
	 assign atk_1br_inside = 
		 (atk_1br_x_l <= x && x <= atk_1br_x_r) &&
		 (atk_1br_y_t <= y && y <= atk_1br_y_b);
		 */
		 
	//-----------------------------------------------------------------------------
// PLAYER1 basic attack recovery hitbox with vertical‐only margin
//-----------------------------------------------------------------------------

// 1) Original recovery‐phase box bounds
wire [9:0] atk_1br_x_l = pl1_x_r + 1;
wire [9:0] atk_1br_x_r = atk_1br_x_l + 44 - 1;
wire [9:0] atk_1br_y_t = pl1_y_t   + 35 - 1;
wire [9:0] atk_1br_y_b = atk_1br_y_t + 10 - 1;

// 2) Unchanged inside‐fill region (solid fill)
wire atk_1br_inside = 
    (atk_1br_x_l <  x && x <  atk_1br_x_r) &&
    (atk_1br_y_t <  y && y <  atk_1br_y_b);

// 3) Vertical margin (pixels to extend above & below)
localparam integer V_MARGIN_REC = 8;

// 4) Compute only the Y‐extent with margin
wire [9:0] ext_y_t_br = (atk_1br_y_t > V_MARGIN_REC)
                        ? atk_1br_y_t - V_MARGIN_REC
                        : 10'd0;
wire [9:0] ext_y_b_br = atk_1br_y_b + V_MARGIN_REC;

// 5) Border signal: 
//    • X must lie on the original left/right edges
//    • Y must lie on the extended top/bottom lines
//    • (and always within the original X span and extended Y span)
wire atk_1br_on =
    (atk_1br_x_l <= x && x <= atk_1br_x_r) &&  // horiz span
    (ext_y_t_br    <= y && y <= ext_y_b_br)    // extended vert span
    &&
    (
      (x == atk_1br_x_l) || (x == atk_1br_x_r) ||  // original vertical edges
      (y == ext_y_t_br)  || (y == ext_y_b_br)      // new top/bottom edges
    );

// 6) Combined “on” if you want both fill & border 
//    (or you can treat them separately)
//wire atk_1br_on = atk_1br_inside || atk_1br_border;

	//player1 sprite
	// Is current pixel within the player hurtbox?
	wire player_hurtbox_on = (x >= pl1_x_l) && (x < pl1_x_r) &&
									  (y >= pl1_y_t) && (y < pl1_y_b);
	wire [7:0] sprite_y = y - pl1_y_t;     // 0–239
	wire [5:0] sprite_x = x - pl1_x_l;     // 0–63

	//Normal (no attack)
	wire [63:0] sprite_row_normal;
	player_mask_rom pl1_mask_rom(
		 .addr(sprite_y),
		 .data(sprite_row_normal)
	);
	wire pl1_sprite_pixel_normal = sprite_row_normal[63 - sprite_x];// Pick one pixel: MSB is leftmost
	// Attacking player
	wire [63:0] sprite_row_attack;
	player_mask_rom_attack pl1_mask_rom_attack(
		 .addr(sprite_y),
		 .data(sprite_row_attack)
	);
	wire pl1_sprite_pixel_attack = sprite_row_attack[63 - sprite_x];// Pick one pixel: MSB is leftmost

    // new PLAYER1 position
	 assign pl1_x_next = (refresh_tick) ? 
								((pl1_x_reg + x_delta_reg < 0) ? 0 : 
								(($unsigned(pl1_x_reg + x_delta_reg) + PLAYER1_SIZE_X > X_MAX) ? 
								X_MAX - PLAYER1_SIZE_X + 1: pl1_x_reg + x_delta_reg)) : pl1_x_reg;
	 // assign pl1_x_next = (refresh_tick) ? 
    //                 ((pl1_x_reg + x_delta_reg < 0) ? 0 : pl1_x_reg + x_delta_reg) :
    //                 pl1_x_reg;
    assign pl1_y_next = (refresh_tick) ? pl1_y_reg + y_delta_reg : pl1_y_reg;
	 
	// SPEED CONTROL
	always @(*) begin:SPEEDCONTROL
		 if(game_screen) begin			  // move only when in the game screen
		   if (~game_over_int) begin    // can move only when game is not over 
			 if (pl1_left && !pl1_right) begin
				  if (pl1_x_reg > 0)
						x_delta_next = -2;  // Move left
				  else
						x_delta_next = 0;   // At left edge, no movement
			 end
			 else if (pl1_right && !pl1_left) begin
				  if ((pl1_x_reg + PLAYER1_SIZE_X) < X_MAX)
						x_delta_next = 3;   // Move right
				  else
						x_delta_next = 0;   // At right edge, no movement
			 end
			 else
				  x_delta_next = 0;       // No movement or both pressed
			end
			else begin
				x_delta_next = 0;
			end
		 end
	 end
	 
	// menu boundaries
	localparam MENU_LEFT   = 256;
	localparam MENU_TOP    = 224;
	localparam MENU_RIGHT  = MENU_LEFT + 128 - 1;
	localparam MENU_BOTTOM = MENU_TOP + 32 - 1;

	// Inside your VGA logic
	wire menu_on;
	assign menu_on = (x >= MENU_LEFT && x <= MENU_RIGHT &&
							  y >= MENU_TOP  && y <= MENU_BOTTOM);
							  
	// Coordinates within the sprite
	wire [6:0] menu_x = x - MENU_LEFT;  // 7 bits for 0–127
	wire [4:0] menu_y = y - MENU_TOP;   // 5 bits for 0–31

	// Combine to form address: (32 rows) * 128 cols
	// If you store 128-bit wide rows (1 line = 128 pixels = 16 bytes),
	// then your ROM is 32 rows × 128 bits (128 pixels per row)
	 
	wire [127:0] menu_row_data;
	menu_rom my_menu_rom (
		 .addr(menu_y),
		 .data(menu_row_data)
	);

	wire menu_pixel_bit = menu_row_data[127 - menu_x];
//	wire menu_pixel_on = menu_on && menu_pixel_bit;
	 
    // RGB control, this will be the output process of the fsm when implemented
    always @(*) begin:RGBCONTROL
        if(~video_on)
            rgb = 8'h00;          // black(no value) outside display area
        
		  else begin					 // inside display area
				case(menu_sel)
					2'b00:begin			 // main menu
						//rgb = 8'hFF;
						game_screen = 1'b0;
						menu_screen = 1'b1;
						if(topbar_on) rgb = 8'hFF;
						else if(ground_on) rgb = 8'hFF;
						else if(menu_on) begin
							if(menu_pixel_bit) rgb = 8'hFF;
							else rgb = BG_RGB;
						end
						else rgb = BG_RGB;
					end					 // solo game for now
					2'b01:begin
						game_screen = 1'b1;
						menu_screen = 1'b0;
						if(pl1_on == 1)// yellow PLAYER1 hitbox
							 rgb = PL1_RGB;       		  
						else if(atk_1bs_on == 1 && pl1_attack == 2'b01) //neutral attack start state hitbox
							 rgb = PL1_INFOBOX_RGB;
						else if(atk_1bs_inside == 1 && pl1_attack == 2'b01) //bg filled attack start state hitbox interior
							 rgb = BG_RGB; // this was player color filled
						else if(atk_1ba_on == 1 && pl1_attack == 2'b10) //red attack active state hitbox
							 rgb = PL1_HITBOX_RGB;
						else if(atk_1ba_inside == 1 && pl1_attack == 2'b10) //player color filled attack active state hitbox interior
							 rgb = PL1_RGB;
						else if(atk_1br_on == 1 && pl1_attack == 2'b11) //red attack arecovery state hitbox
							 rgb = PL1_HURTBOX_RGB;
						else if(atk_1br_inside == 1 && pl1_attack == 2'b11) //player color filled attack recovery state hitbox interior
							 rgb = PL1_RGB;
						else if (player_hurtbox_on) begin // inside the hurtbox, draw the sprite
							case(pl1_attack)
							 2'b00: rgb = (pl1_sprite_pixel_normal) ? PL1_RGB : BG_RGB; // for normal behavior
							 2'b01: rgb = (pl1_sprite_pixel_attack) ? PL1_RGB : BG_RGB; // for basic attack start
							 2'b10: rgb = (pl1_sprite_pixel_attack) ? PL1_RGB : BG_RGB; // for basic attack active
							 2'b11: rgb = (pl1_sprite_pixel_attack) ? PL1_RGB : BG_RGB; // for basic attack recovery
							 endcase
						end 
						else if(ground_on)
							 rgb = GROUND_RGB;   // ground
						else
							 rgb = BG_RGB;       // blue background
					end
					default:begin
						rgb = 8'h00;
						game_screen = 1'b0;
						menu_screen = 1'b0;
					end
				endcase
			end
    end
endmodule