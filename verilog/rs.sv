`include "verilog/sys_defs.svh"
`include "verilog/ISA.svh"

typedef struct packed{
	logic busy;
	logic issued;
	DECODER_PACKET decoder_packet;
}RS_ENTRY;

module rs(
	input clock,
	input reset,
	
	//bus input
	input TAG cdb,
	input logic cdb_en,
	input interrupt,

	input is_stall,
	
	input ID_RS_PACKET id_rs_packet,
	
	input EX_RS_PACKET ex_rs_packet,
	
	output RS_ID_PACKET rs_id_packet,
	
	output RS_IS_PACKET rs_is_packet
);
	
	RS_ENTRY [`RS_SZ - 1:0] rs_table;

	//Handle rs -> id logic
	logic is_mult;
	assign is_mult =        id_rs_packet.decoder_packet.alu_func == ALU_MUL ||
							id_rs_packet.decoder_packet.alu_func == ALU_MULH ||
							id_rs_packet.decoder_packet.alu_func == ALU_MULHSU ||
							id_rs_packet.decoder_packet.alu_func == ALU_MULHU;
	
	assign rs_id_packet.free_idx   =	id_rs_packet.decoder_packet.wr_mem	? 2 :
							    id_rs_packet.decoder_packet.rd_mem	? 2 :
							    is_mult			                ? 0 :
							    rs_table[3].busy	                ? 4 : 3;
	assign rs_id_packet.free = !rs_table[rs_id_packet.free_idx].busy;

	//Handle rs -> is issue logic
	always_comb begin
		rs_is_packet.issue_en = 0;
		rs_is_packet.decoder_packet.inst = `NOP;
		rs_is_packet.decoder_packet.valid = 0;
		rs_is_packet.decoder_packet.NPC = 0;
		if (!interrupt) begin
			foreach (rs_table[i]) begin
				if((!rs_table[i].issued) &&
				(rs_table[i].decoder_packet.t1.phys_reg == 0 || rs_table[i].decoder_packet.t1.ready) && 
				(rs_table[i].decoder_packet.t2.phys_reg == 0 || rs_table[i].decoder_packet.t2.ready) &&
				(rs_table[i].busy)) begin
					rs_is_packet.decoder_packet = rs_table[i].decoder_packet;
					rs_is_packet.issue_en = 1;
				end
			end
		end
	end

	always_ff @(posedge clock) begin
		//Handle reset
		if (reset || interrupt) begin
			foreach (rs_table[i]) begin
				rs_table[i].busy <= 0;
				rs_table[i].issued <= 0;
			end
		end else begin
			//Handle CDB
			if (cdb_en) begin
				foreach (rs_table[i]) begin
					if (rs_table[i].decoder_packet.t1.phys_reg == cdb.phys_reg) begin
						rs_table[i].decoder_packet.t1.ready <= 1;
					end
					if (rs_table[i].decoder_packet.t2.phys_reg == cdb.phys_reg) begin
						rs_table[i].decoder_packet.t2.ready <= 1;
					end
				end
			end
			
			//Handle issue marking
			if (rs_is_packet.issue_en && !is_stall) begin
			    rs_table[rs_is_packet.decoder_packet.rs_idx].issued <= 1;
			end
			
			//Handle rs -> id writes
			if (rs_id_packet.free && id_rs_packet.write_en) begin
				rs_table[rs_id_packet.free_idx].busy   <= 1'b1;
				rs_table[rs_id_packet.free_idx].issued   <= 1'b0;
				rs_table[rs_id_packet.free_idx].decoder_packet    <= id_rs_packet.decoder_packet;
			end
			
			//Handle ex -> id removes
			if (ex_rs_packet.remove_en && !is_stall) begin
				rs_table[ex_rs_packet.remove_idx].busy <= 0;
				rs_table[ex_rs_packet.remove_idx].issued   <= 0;
			end
		end
	end

endmodule
	
