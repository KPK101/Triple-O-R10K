`include "verilog/sys_defs.svh"
`include "verilog/ISA.svh"

typedef struct packed{
	FU func_unit,
	logic busy,
	logic [6:0] opcode,
	TAG T, T1, T2
}RS_ENTRY;

module rs(
	input clock,
	input reset,
	input ID_EX_PACKET op,
	input TAG T, T1, T2, CDB,
	output rs_busy_alu, rs_busy_mul, rs_busy_ld, rs_busy_st);

	logic RS_ENTRY [`RS_SZ -1:0] rs_table;
	int 


assign rs_busy_alu = rs_table[0].busy;
assign rs_busy_mul = rs_table[1].busy;
assign rs_busy_ld  = rs_table[2].busy;
assign rs_busy_st  = rs_table[3].busy;

always_ff @(posedge clock){
	if(reset)begin
		int offset = 0;
		for(int i = 0; i < 'NUM_FU_ALU;i++) begin
			rs_table[i+offset].func_unit = ALU;
		end
		offset += 'NUM_FU_ALU;
		for(int i = 0; i < 'NUM_FU_MULT;i++) begin
			rs_table[i+offset].func_unit = MULT;
		end
		offset += 'NUM_FU_MULT;
		for(int i = 0; i < 'NUM_FU_LOAD;i++) begin
			rs_table[i+offset].func_unit = LD;
		end
		offset += 'NUM_FU_LOAD;
		for(int i = 0; i < 'NUM_FU_STORE;i++) begin
			rs_table[i+offset].func_unit = ST;
		end
	end else begin
		if (op.wr_mem) begin
			int offset = `NUM_FU_ALU + `NUM_FU_MULT + `NUM_FU_LOAD;
			for(int i = offset;i < offset + `NUM_FU_STORE; i++) begin
				if(!rs_table[i].busy) begin
					rs_table[i].busy <= 1'b1;
					rs_table[i].opcode <= op.inst[6:0];
					break;
				end
			end
		end else if (op.rd_mem) begin
			int offset = `NUM_FU_ALU + `NUM_FU_MULT;
			for(int i = offset;i < offset + `NUM_FU_LOAD; i++) begin
				if(!rs_table[i].busy) begin
					rs_table[i].busy <= 1'b1;
					rs_table[i].opcode <= op.inst[6:0];
					break;
				end		
			end
		end else if (op.alu_func == ALU_MUL || op.alu_func == ALU_MULH || op.alu_func == ALU_MULHSU || op.alu_func == ALU_MULHU) begin
			int offset = `NUM_FU_ALU;
			for(int i = offset;i < offset + `NUM_FU_MULT; i++) begin
				if(!rs_table[i].busy) begin
					rs_table[i].busy <= 1'b1;
					rs_table[i].opcode <= op.inst[6:0];
					break;
				end		
			end
		end else begin
			int offset = 0;
			for(int i = offset;i < offset + `NUM_FU_ALU; i++) begin
				if(!rs_table[i].busy) begin
					rs_table[i].busy <= 1'b1;
					rs_table[i].opcode <= op.inst[6:0];
					break;
				end	
			end
		end
	end

	
} 

	
