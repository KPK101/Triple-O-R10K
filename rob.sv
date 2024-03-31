`include "verilog/sys_defs.svh"
`include "verilog/ISA.svh"
`include "verilog/free_list.sv" // check if this works 

typedef struct packed{
	logic [6:0] opcode;
	TAG T, Told, CDB;
	logic full; 
}ROB_ENTRY;

typedef struct packed{
	TAG T, Told;
}ROB_R_PACKET;

module rob(
	input clock,
	input reset,
	input ID_EX_PACKET ????, // NEED INPUT
	input TAG T, Told, CDB,
	input EX_C_PACKET complete, // complete signal from complete stage (add done signal when we make the EX_C_PACKET)

	output ROB_R_PACKET retire_pkt // send to retire stage -> only contains tag information 
);

	ROB_ENTRY [`ROB_SZ -1:0] rob_table; // size of table = 7 
	
	
	logic [`ROB_SZ-1:0] head, tail;
	logic [`ROB_SZ-1:0] next_head, next_tail;
	logic [`ROB_SZ-1:0] rob_retire;

	//assign rob_table.done = EX_C_PACKET.done; 
	assign rob_retire = complete.done; // retire if the head instruction is done EDIT after we make the packet
	
	/* assign tag information */ 
	assign rob_table[tail].T = free_list.pop; // assign a free tag 
	assign rob_table[tail].Told = ;// assign the old tag EDIT

	/* increment head and tail signals */
	assign next_tail = (tail == `ROB_SZ -1) ? 0 : tail + 1; 
	assign next_head = rob_retire ? (head + 1) : head; 

	/* assign retire packet and send tag info to retire stage */
	assign retire_pkt.T = rob_table[head].T; 
	assign retire_pkt.Told = rob_table[head].Told; 

	/* stop sending signals if the table is full -> send to dispatch I guess?*/
	assign rob_table.full = (tail == `ROB_SZ-1) ? 1 :0;
	
	/* update head/tail information every pos edge of the clock */
	always_ff @(posedge clock)begin
		if (reset) begin 
			head <= 0;
			tail <= 0;
		end
		else begin 
			head <= next_head;
			tail <= next_tail;		
		end 
			
	end


endmodule
	
