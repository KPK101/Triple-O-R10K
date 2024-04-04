module free_list (
	input clock,
	input reset,
	
	//When old tag gets retired, it is added to free list
	input TAG retire_t_old,
	input retire_en,
	
	//When pop is enabled, then the free_tag gets consumed
	input pop_en,
	
	//Currently free tag. Only valid when free is true
	output TAG free_tag,
	output logic free,
	
`ifdef DEBUG
	output [`PHYS_REG_SZ-1:0] phys_reg_free_dbg
`endif
	
);

	//Array that keeps track if reg is free
	logic [`PHYS_REG_SZ-1:0] phys_reg_free;
`ifdef DEBUG
	assign phys_reg_free_dbg = phys_reg_free;
`endif
	
	always_comb begin
		//Default output
		free_tag.valid = 0;
		free_tag.ready = 0;
		free = 0;
		
		//Look for free tag
		foreach (phys_reg_free[i]) begin
			if (phys_reg_free[i]) begin
				free_tag.valid = 1;
				free_tag.phys_reg = i;
				free = 1;
			end
		end
		
	end
	
	always_ff @(posedge clock) begin
		//Reset assigns all first 32 register to be not free. (used in map table as default)
		if (reset) begin
			foreach (phys_reg_free[i]) begin
				phys_reg_free[i] <= i > 31;
			end
		end else begin
			//When pop is enabled, set current free tag to be not free
			if (pop_en) begin
				phys_reg_free[free_tag.phys_reg] <= 1'b0;
			end
			//When retire is enabled, free t_old tag
			if (retire_en) begin
				phys_reg_free[retire_t_old.phys_reg] <= 1'b1;
			end
		end
	end
endmodule
