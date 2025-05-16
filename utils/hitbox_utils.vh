//=== hitbox_utils.vh ===
// File: 		hitbox_utils.vh
// Description: Functions for hitbox/hurtbox overlap detection and resolution.
// Author: 		bugrASl
// Date:   		15.05.2025
// Usage:   	`include "../utils/hitbox_utils.vh" in hit_engine.v

`ifndef HITBOX_UTILS_VH
`define HITBOX_UTILS_VH

// Rectangle overlap: returns 1 if [x1,x2] overlaps [y1,y2]
function bit rect_overlap;
    input int x1, x2, y1, y2;
    begin
        rect_overlap = (x1 < y2) && (y1 < x2);
    end
endfunction

`endif // HITBOX_UTILS_VH
