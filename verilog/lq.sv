typedef struct packed {
	logic addr;
	logic valid;
	logic ROB_num;
} LQ_ENTRY;

module lq (
	input clock,
	input reset,
	
	//ROB index to be marked as complete
	input [$clog2(`LQ_SZ)-1:0] complete_idx,
	input complete_en,

	//ROB index to be marked as execute
	input [$clog2(`LQ_SZ)-1:0] execute_idx, // ROB_num 
	input execute_en,


	input sq_value, // value information from sq

	// from ROB 
	input load_en,
	input free_idx, // free_idx from ROB
	input ROB_addr, // load addr value from ROB 


	//High when rob has free space. When low, next_idx is invalid.
	output logic free,
	//Next slot in the rob
	output logic [$clog2(`LQ_SZ)-1:0] tail_idx,
	
`ifdef DEBUG
	output logic [$clog2(`LQ_SZ)-1:0] head_idx_dbg
`endif
);
	LQ_ENTRY [`LQ_SZ-1:0] lq;
	
	logic [$clog2(`LQ_SZ)-1:0] head_idx;
	logic [$clog2(`LQ_SZ):0] counter;	
	//logic lq_ready;
	
`ifdef DEBUG
	assign head_idx_dbg = head_idx;
`endif
	
	//assign free
	assign free = counter == `LQ_SZ;
	assign next_counter = retire_en && !(free && in_en) ? counter - 1 :
		(free && in_en) && !retire_en ? counter + 1: counter;
	
	always_ff @(posedge clock) begin
		if (reset) begin
			//Reset head and tail index
			head_idx <= 0;
			tail_idx <= 0;
			counter <= 0;
			//Invalidate 0 index entry for insertion
			lq[0].addr <= 0;
			lq[0].valid <= 0;
			lq[0].ROB_num <= 0;
			lq_ready <= 0;
		end else begin
			//Accept new entry
			if (load_en) begin // rob has load instruction 
				rob[tail_idx].ROB_num <= free_idx; // input comes from ROB index
				tail_idx <= tail_idx + 1;
			end
			//Execute entry
			if (execute_en) begin // look through store queue for the same addr
				/*foreach (sq[i]) begin 
					if (sq[i].addr == ROB_addr) begin // compare pos 
						
					end else begin 
						lq_ready <= 1;
					end
				end*/
					lq[tail_idx].addr <= ROB_addr; // addr value from ROB 
					lq[tail_idx].valid <= 1;	
			end
			if (complete_en) begin
				head_idx <= head_idx + 1; 
			end

			counter <= next_counter;
		end
	end
endmodule
			
	
	
