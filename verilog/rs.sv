//`include "verilog/sys_defs.svh"
//`include "verilog/ISA.svh"
//`include "sys_defs.svh"
typedef struct packed{
	logic busy;
	logic issued;
	DECODER_PACKET decoder_packet;
	logic [1:0] lq_pos;
	logic [1:0] sq_pos;
}RS_ENTRY;

module rs(
	input clock,
	input reset,
	
	//bus input
	input interrupt,
	input TAG cdb,
	input cdb_en,
	input ID_RS_PACKET id_rs_packet, // decoder_packet + write_en 
	input EX_RS_PACKET ex_rs_packet, // remove_idx + remove_en
	input logic cdb_en,
	input interrupt,

	input is_stall,

	input LQ_RS_PACKET lq_rs_packet,
	input SQ_RS_PACKET sq_rs_packet,
	
	output [4:0] rs_busy_status, // 5 bit 0 -> 4 for debug purpose
	output logic is_mult,
	output RS_ID_PACKET rs_id_packet, 
	output RS_IS_PACKET rs_is_packet 
);
	
	RS_ENTRY [`RS_SZ - 1:0] rs_table;

	//Handle rs -> id logic
	//logic is_mult;
	assign is_mult = id_rs_packet.decoder_packet.alu_func == ALU_MUL || id_rs_packet.decoder_packet.alu_func == ALU_MULH ||
			 id_rs_packet.decoder_packet.alu_func == ALU_MULHSU || id_rs_packet.decoder_packet.alu_func == ALU_MULHU;

	assign rs_id_packet.free_idx   = id_rs_packet.decoder_packet.wr_mem ? 2 :
					 id_rs_packet.decoder_packet.rd_mem ? 1 :
					 !is_mult			    ? 0 :
					 rs_table[3].busy	            ? 4 : 3; 
	
	// for debugging only 
	assign rs_busy_status[0] = rs_table[0].busy ; 
	assign rs_busy_status[1] = rs_table[1].busy ;
	assign rs_busy_status[2] = rs_table[2].busy ;
	assign rs_busy_status[3] = rs_table[3].busy ;
	assign rs_busy_status[4] = rs_table[4].busy ;
	
	/*
		0: alu (not mult)
		1: load (read_mem) 
		2: store (write_mem) 
		3: fp1 
		4: fp2  	
	*/

	assign rs_id_packet.free = !rs_table[rs_id_packet.free_idx].busy; 
	assign rs_id_packet.free_idx   =	id_rs_packet.decoder_packet.wr_mem	? 1 :
							    id_rs_packet.decoder_packet.rd_mem	? 2 :
							    is_mult			                ? 0 :
							    rs_table[3].busy	                ? 4 : 3;
	assign rs_id_packet.free = !rs_table[rs_id_packet.free_idx].busy;

	//Handle rs -> is issue logic
	always_comb begin
		rs_is_packet.issue_en = 0;

		if (interrupt) begin
			rs_is_packet.decoder_packet.inst = `NOP;
			rs_is_packet.decoder_packet.valid = 0;
			rs_is_packet.decoder_packet.NPC = 0;
		end else begin
			foreach (rs_table[i]) begin
				if((!rs_table[i].issued) &&
				(!rs_table[i].decoder_packet.t1.valid || rs_table[i].decoder_packet.t1.ready) && 
				(!rs_table[i].decoder_packet.t2.valid || rs_table[i].decoder_packet.t2.ready) &&
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
						rs_table[i].decoder_packet.t1.valid <= 1;
					end
					if (rs_table[i].decoder_packet.t2.phys_reg == cdb.phys_reg) begin
						rs_table[i].decoder_packet.t2.ready <= 1;
						rs_table[i].decoder_packet.t2.valid <= 1;
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
				rs_table[rs_id_packet.free_idx].lq_pos    <= id_rs_packet.lq_pos;
				rs_table[rs_id_packet.free_idx].sq_pos    <= id_rs_packet.sq_pos;

			end
			
			//Handle ex -> id removes
			if (ex_rs_packet.remove_en) begin

				rs_table[ex_rs_packet.remove_idx].busy <= 0;
				rs_table[ex_rs_packet.remove_idx].issued   <= 0;

			end
		end
	end

endmodule
	
