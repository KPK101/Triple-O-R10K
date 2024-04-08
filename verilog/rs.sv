`include "verilog/sys_defs.svh"
`include "verilog/ISA.svh"

typedef struct packed{
	logic busy;
	logic issued;
	ID_IS_PACKET is_packet;
}RS_ENTRY;

module rs(
	input clock,
	input reset,
	
	//bus input
	input TAG cdb,
	
	//is_packet with info loaded from decoder with t,t1,t2 assigned from free_list and map_table
	input ID_IS_PACKET is_packet_in,
	input in_en,
	
	//When instruction is finished execuring, it will use this to clear rs entry
	input logic [$clog2(`RS_SZ)-1:0] remove_idx,
	input remove_en,
	
	//is_packet that is ready to be issued
	output ID_IS_PACKET is_packet_out,
	output logic issue_en,
	
	//available idx in the rs_table that current input can go into. Only valid when free is true.
	output logic [$clog2(`RS_SZ)-1:0] free_idx,
	output logic free
);
	
	RS_ENTRY [`RS_SZ - 1:0] rs_table;

	//logic to allocate free idx in the rs_table
	logic is_mult;
	assign is_mult =	is_packet_in.alu_func == ALU_MUL ||
							is_packet_in.alu_func == ALU_MULH ||
							is_packet_in.alu_func == ALU_MULHSU ||
							is_packet_in.alu_func == ALU_MULHU;
	
	assign free_idx   =		is_packet_in.wr_mem	? 2 :
							is_packet_in.rd_mem	? 1 :
							!is_mult			? 0 :
							rs_table[3].busy	? 3 : 4;
	
	//the rs is free if the allocated free idx is actually free
	assign free = !rs_table[free_idx].busy;

	//Assign rs_entry to be issued
	always_comb begin
		issue_en = 0;
		foreach (rs_table[i]) begin
			//Check if it has not been issued and tags are either invalid (in case of empty) or ready
			if((!rs_table[i].issued) &&
			   (!rs_table[i].is_packet.t1.valid || rs_table[i].is_packet.t1.ready) && 
			   (!rs_table[i].is_packet.t2.valid || rs_table[i].is_packet.t2.ready)) begin
				is_packet_out = rs_table[i].is_packet;
				issue_en = 1;
			end
		end
	end

	always_ff @(posedge clock) begin
		//when reset, set all entry to be not busy
		if (reset) begin
			foreach (rs_table[i]) begin
				rs_table[i].busy = 0;
			end
		end else begin
			//When there is valid cdb, ready all tags that have same pr
			if (cdb.valid) begin
				foreach (rs_table[i]) begin
					if (rs_table[i].is_packet.t1.valid && 
					    rs_table[i].is_packet.t1.phys_reg == cdb.phys_reg) begin
						rs_table[i].is_packet.t1.ready <= 1;
					end
					if (rs_table[i].is_packet.t2.valid && 
					    rs_table[i].is_packet.t2.phys_reg == cdb.phys_reg) begin
						rs_table[i].is_packet.t2.ready <= 1;
					end
				end
			end
			
			//add new entry to rs when in is enabled and there is free space
			if (free && in_en) begin
				rs_table[free_idx].busy   <= 1'b1;
				rs_table[free_idx].is_packet    <= is_packet_in;
			end
			
			//remove rs entry
			if (remove_en) begin
				rs_table[remove_idx].busy <= 0;
			end
		end
	end

endmodule
	
