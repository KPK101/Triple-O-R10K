`include "verilog/sys_defs.svh"
`include "verilog/ISA.svh"

typedef struct packed{
	FU func_unit;
	logic busy;
	ID_EX_PACKET pkt;
}RS_ENTRY;

module rs(
	input clock,
	input reset,
	input ID_EX_PACKET input_pkt,
	input TAG cdb,

	output rs_busy_alu, rs_busy_fp1, rs_busy_fp2, rs_busy_ld, rs_busy_st,
	output ID_EX_PACKET issue_pkt,
	output logic issue
);
	
	RS_ENTRY [`RS_SZ -1:0] rs_table;
	logic [2:0] entry_idx;
	logic is_mult_pkt;

	assign is_mult_pkt =	input_pkt.alu_func == ALU_MUL ||
							input_pkt.alu_func == ALU_MULH ||
							input_pkt.alu_func == ALU_MULHSU ||
							input_pkt.alu_func == ALU_MULHU;
	
	assign entry_idx   =	input_pkt.wr_mem	? 2 :
							input_pkt.rd_mem	? 1 :
							!is_mult_pkt		? 0 :
							!rs_table[3].busy	? 3 : 4;
	
	assign rs_busy_alu = rs_table[0].busy;
	assign rs_busy_ld  = rs_table[1].busy;
	assign rs_busy_st  = rs_table[2].busy;
	assign rs_busy_fp1 = rs_table[3].busy;
	assign rs_busy_fp2 = rs_table[4].busy;

	always_comb begin
		issue_pkt = 32'b0;
		issue = 0;
		foreach (rs_table[i]) begin
			if((!rs_table[i].pkt.T1.valid || rs_table[i].pkt.T1.ready) && 
			   (!rs_table[i].pkt.T2.valid || rs_table[i].pkt.T2.ready)) begin
				issue_pkt = rs_table[i].pkt;
				issue = 1;
			end
		end
	end

	always_ff @(posedge clock) begin
		if (reset) begin 
			rs_table[0].func_unit <= ALU;
			rs_table[1].func_unit <= LD;
			rs_table[2].func_unit <= ST;
			rs_table[3].func_unit <= FP1;
			rs_table[4].func_unit <= FP2;
			rs_table[0].busy <= 1'b0;
			rs_table[1].busy <= 1'b0;
			rs_table[2].busy <= 1'b0;
			rs_table[3].busy <= 1'b0;
			rs_table[4].busy <= 1'b0;
		end else begin
			if (!input_pkt.illegal && input_pkt.valid && !rs_table[entry_idx].busy) begin
				rs_table[entry_idx].busy   <= 1'b1;
				rs_table[entry_idx].pkt    <= input_pkt;
			end

			if (cdb.valid) begin
				foreach (rs_table[i]) begin
					if (rs_table[i].pkt.T1.valid && 
					    rs_table[i].pkt.T1.tag == cdb.tag) begin
						rs_table[i].pkt.T1.ready <= 1;
					end
					if (rs_table[i].pkt.T2.valid && 
					    rs_table[i].pkt.T2.tag == cdb.tag) begin
						rs_table[i].pkt.T2.ready <= 1;
					end
				end
			end
		end
	end

endmodule
	
