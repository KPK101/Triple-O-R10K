`include "verilog/sys_defs.svh"
`include "verilog/ISA.svh"

typedef struct packed{
	logic addr;
	logic valid;
	logic rob_index;
}LQ_ENTRY;

module lq(
	input clock,
	input reset,

	input ID_LQ_PACKET id_lq_packet,
	input ROB_LQ_PACKET rob_lq_packet,
	input EX_LQ_PACKET ex_lq_packet,
	input RS_LQ_PACKET rs_lq_packet,
	
	output LQ_RS_PACKET lq_rs_packet,
	output LQ_ID_PACKET lq_id_packet
);
	
	LQ_ENTRY [`LSQ_SZ - 1:0] lq_table;
	logic [$clog2(`LSQ_SZ)-1:0] head_idx;
	logic [$clog2(`LSQ_SZ)-1:0] tail_idx;

	always_comb begin 
		if (reset) begin
			foreach (lq_table[i]) begin 
				lq_table[i].valid = 0;
				lq_table[i].rob_index = 0;
				lq_table[i].addr = 0;
			end
			head_idx = 0;
			tail_idx = 0;
		end else begin 
			if (id_lq_packet.enable) begin
				lq_id_packet.lq_pos = tail_idx; // needs to be blocking assignment
				lq_table[tail_idx].rob_index = rob_lq_packet.free_idx;
				tail_idx = tail_idx + 1;
			end
			if (ex_lq_packet.enable) begin 
				lq_table[rs_lq_packet.lq_pos].valid = 1;
				lq_table[rs_lq_packet.lq_pos].addr = ex_lq_packet.addr;
			end
			if (rob_lq_packet.retire_en) begin
				lq_table[head_idx].valid = 0;
				lq_table[head_idx].rob_index = 0;
				lq_table[head_idx].addr = 0;
				head_idx = head_idx + 1;
			end
		end


	end
endmodule
	
