`include "verilog/sys_defs.svh"
`include "verilog/ISA.svh"

typedef struct packed{
	logic addr;
	logic valid;
	logic value;
}SQ_ENTRY;

module sq(
	input clock,
	input reset,

	input ID_SQ_PACKET id_sq_packet,
	input RS_SQ_PACKET rs_sq_packet,
	input EX_SQ_PACKET ex_sq_packet,
	input ROB_SQ_PACKET rob_sq_packet,
	
	output SQ_RS_PACKET sq_rs_packet,
	output SQ_ID_PACKET sq_id_packet
);
	
	SQ_ENTRY [`LSQ_SZ - 1:0] sq_table;
	logic [$clog2(`LSQ_SZ)-1:0] head_idx;
	logic [$clog2(`LSQ_SZ)-1:0] tail_idx;

	always_comb begin 
		if (reset) begin
			foreach (sq_table[i]) begin 
				sq_table[i].valid = 0;
				sq_table[i].value = 0;
				sq_table[i].addr = 0;
			end
			head_idx = 0;
			tail_idx = 0;
		end else begin 
			if (id_sq_packet.enable) begin
				sq_id_packet.sq_pos = tail_idx; // needs to be blocking assignment
				tail_idx = tail_idx + 1;
			end
			if (ex_sq_packet.enable) begin 
				sq_table[rs_sq_packet.sq_pos].addr = ex_sq_packet.addr;
				sq_table[rs_sq_packet.sq_pos].valid = 1;
				sq_table[rs_sq_packet.sq_pos].value = ex_sq_packet.value;
			end
			if (rob_sq_packet.retire_en) begin
				cache.value = sq_table[head_idx].value; // commit new value to cache ##handle cache? 
				sq_table[head_idx].valid = 0;
				sq_table[head_idx].addr = 0
				sq_table[head_idx].value = 0;
				head_idx = head_idx + 1;
				
			end
		end


	end



endmodule
	
