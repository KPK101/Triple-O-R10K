typedef struct packed {
	logic addr;
	logic valid;
	logic value;	
} SQ_ENTRY;

module sq (
	input clock,
	input reset,
	
	//ROB index to be marked as complete
	input [$clog2(`SQ_SZ)-1:0] complete_idx,
	input complete_en,
	input store_en, // store enable signal from ROB 
	
	input execute_en,
	input execute_value,

	input ROB_addr,
	input lq_addr, // addr information from lq 


	//High when rob has free space. When low, next_idx is invalid.
	output logic free,
	//Next slot in the rob
	output logic [$clog2(`SQ_SZ)-1:0] tail_idx,
	
`ifdef DEBUG
	output logic [$clog2(`SQ_SZ)-1:0] head_idx_dbg
`endif
);
	SQ_ENTRY [`SQ_SZ-1:0] sq;
	
	logic [$clog2(`SQ_SZ)-1:0] head_idx;
	logic [$clog2(`SQ_SZ):0] counter;
	
`ifdef DEBUG
	assign head_idx_dbg = head_idx;
`endif
	
	//assign free
	assign free = counter == `SQ_SZ;
	
	//assign retire
	assign retire_t = rob[head_idx].t;
	assign retire_t_old = rob[head_idx].t_old;
	assign retire_en = rob[head_idx].is_complete;
	assign next_counter = retire_en && !(free && in_en) ? counter - 1 :
		(free && in_en) && !retire_en ? counter + 1: counter;
	
	always_ff @(posedge clock) begin
		if (reset) begin
			//Reset head and tail index
			head_idx <= 0;
			tail_idx <= 0;
			counter <= 0;
			//Invalidate 0 index entry for insertion
			sq[0].addr <= 0;
			sq[0].valid <= 0;
			sq[0].value <= 0;
		end else begin
			//Accept new entry
			if (store_en) begin // rob has store instruction 
				tail_idx <= tail_idx + 1;
			end

			//Execute entry
			if (execute_en) begin
				sq[tail_idx].value <= execute_value;
				sq[tail_idx].valid <= 1;
				sq[tail_idx].addr <= ROB_addr;
			end

			if (complete_en) begin
				head_idx <= head_idx + 1; 
			end

			counter <= next_counter;
		end
	end


endmodule
			
	
	
