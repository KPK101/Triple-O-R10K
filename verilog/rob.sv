typedef struct packed {
	TAG t;
	TAG t_old;
	logic is_complete;
} ROB_ENTRY;

module rob (
	input clock,
	input reset,
	
	//ROB index to be marked as complete
	input [$clog2(`ROB_SZ)-1:0] complete_idx,
	input complete_en,
	
	//New entry that would be placed in the rob[next_idx]
	input TAG t_in,
	input TAG t_old_in,
	input in_en,
	
	//High when rob has free space. When low, next_idx is invalid.
	output logic free,
	//Next slot in the rob
	output logic [$clog2(`ROB_SZ)-1:0] free_idx,
	
	//These signals will be sent to the Arch map to replace t_old with t
	//t_old is also sent to free_list to push
	output TAG retire_t,
	output TAG retire_t_old,
	output logic retire_en,
`ifdef DEBUG
	output logic [$clog2(`ROB_SZ)-1:0] head_idx_dbg
`endif
);
	ROB_ENTRY [`ROB_SZ-1:0] rob;
	
	logic [$clog2(`ROB_SZ)-1:0] head_idx;
	logic [$clog2(`ROB_SZ):0] counter;
	
`ifdef DEBUG
	assign head_idx_dbg = head_idx;
`endif
	
	//assign free
	assign free = counter == `ROB_SZ;
	
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
			free_idx <= 0;
			counter <= 0;
			//Invalidate 0 index entry for insertion
			rob[0].t.valid <= 0;
			rob[0].t_old.valid <= 0;
			rob[0].is_complete <= 0;
		end else begin
			//retire and remove from rob by moving head
			if (retire_en) begin
				head_idx <= head_idx + 1;
			end
			
			//Accept new entry
			if (free && in_en) begin
				rob[free_idx].t <= t_in;
				rob[free_idx].t_old <= t_old_in;
				rob[free_idx].is_complete <= 0;
				free_idx <= free_idx + 1;
			end
			
			//Complete entry
			if (complete_en) begin
				rob[complete_idx].is_complete <= 1;
			end
			counter <= next_counter;
		end
	end
endmodule
			
	
	
