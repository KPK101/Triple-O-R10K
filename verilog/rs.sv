`include "verilog/sys_defs.svh"
`include "verilog/ISA.svh"

typedef struct packed{
	FU func_unit;
	logic busy;
	logic [6:0] opcode;
	TAG T, T1, T2;
}RS_ENTRY;

module rs(
	input clock,
	input reset,
	input ID_EX_PACKET op,
	input TAG T, T1, T2, CDB,
	output rs_busy_alu, rs_busy_fp1, rs_busy_fp2, rs_busy_ld, rs_busy_st,
	output ID_EX_PACKET issue_pkt,
	output issue
);

	RS_ENTRY [`RS_SZ -1:0] rs_table;
	logic issue_out;
	
assign issue = issue_out;

assign rs_busy_alu = rs_table[0].busy;
assign rs_busy_ld  = rs_table[1].busy;
assign rs_busy_st  = rs_table[2].busy;
assign rs_busy_fp1 = rs_table[3].busy;
assign rs_busy_fp2 = rs_table[4].busy;

always_ff @(posedge clock)begin
	if (reset) begin 
		rs_table[0].func_unit <= ALU;
		rs_table[1].func_unit <= LD;
		rs_table[2].func_unit <= ST;
		rs_table[3].func_unit <= FP1;
		rs_table[4].func_unit <= FP2;
	end
	else begin 
		if (op.wr_mem) begin // stf
			if (!rs_table[2].busy) begin 
				rs_table[2].busy <= 1'b1;
				rs_table[2].opcode <= op.inst[6:0];
				rs_table[2].T <= op.T;
				rs_table[2].T1 <= op.T1;
				rs_table[2].T2 <= op.T2;
			end 
		end
		else if (op.rd_mem) begin // ldf
			if (!rs_table[1].busy) begin 
				rs_table[1].busy <= 1'b1;
				rs_table[1].opcode <= op.inst[6:0];
				rs_table[1].T <= op.T;
				rs_table[1].T1 <= op.T1;
				rs_table[1].T2 <= op.T2;
			end
		end
		else if (op.alu_func == ALU_MUL || op.alu_func == ALU_MULH || op.alu_func == ALU_MULHSU || op.alu_func == ALU_MULHU) begin //mulf
			if (!rs_table[3].busy) begin 
				rs_table[3].busy <= 1'b1;
				rs_table[3].opcode <= op.inst[6:0];
				rs_table[3].T <= op.T;
				rs_table[3].T1 <= op.T1;
				rs_table[3].T2 <= op.T2;
			end else if (rs_table[3].busy && !rs_table[4].busy) begin
				rs_table[4].busy <= 1'b1;
				rs_table[4].opcode <= op.inst[6:0];
				rs_table[4].T <= op.T;
				rs_table[4].T1 <= op.T1;
				rs_table[4].T2 <= op.T2;
			end
		end 
		else begin //addi
			if (!rs_table[0].busy) begin 
				rs_table[0].busy <= 1'b1;
				rs_table[0].opcode <= op.inst[6:0];
				rs_table[0].T <= op.T;
				rs_table[0].T1 <= op.T1;
				rs_table[0].T2 <= op.T2;
			end
		end
		
	end 
		
end

always_ff @(posedge clock)begin
	for(int i = 0; i < `RS_SZ; i++)begin
		if((rs_table[i].T1.tag && rs_table[i].T1.ready) && (rs_table[i].T2.tag && rs_table[i].T2.ready) || (!rs_table[i].T1.tag && rs_table[i].T2.ready) || (!rs_table[i].T2.tag && rs_table[i].T1.ready))begin
			issue_out <= op;
			issue_out<=1'b1;
		end
		
		else begin
			issue_out<=1'b0;
		end
	end
end

endmodule
	
