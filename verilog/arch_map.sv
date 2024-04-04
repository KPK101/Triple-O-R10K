module arch_map (
	input clock,
	input reset,
	
	//get signals from ROB to retire a tag
	input TAG retire_t,
	input TAG retire_t_old,
	input retire_en,
	
	//read_idx for assigning Told in rob
	input [4:0] read_idx,
	
	//tag output of a given idx
	output TAG read_out
);
	TAG [31:0] reg_map;
	
	//assign read
	assign read_out = reg_map[read_idx];
	
	always_ff @(posedge clock) begin
		if (reset) begin
			//reset all idx to have the tag equal to their idx
			foreach (reg_map[i]) begin
				reg_map[i].phys_reg <= i;
			end
		end else if (in_en) begin
			//When retire is enabled, replace t_old with t
			foreach (reg_map[i]) begin
				if (reg_map[i].phys_reg == retire_t_old.phys_reg) begin
					reg_map[i] <= retire_t;
				end
			end
		end
	end
	
endmodule
