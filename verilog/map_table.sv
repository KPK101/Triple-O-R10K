
module map_table (
	input clock,
	input reset,
	
	//Two index for just reading
	input [4:0] read_idx_1,
	input [4:0] read_idx_2,
	
	//index and value for new tag from free_list
	input [4:0] write_idx,
	input TAG write_tag,
	input write_en,
	
	//cdb for ready bit generator
	input TAG cdb,
	input cdb_enable,
	
	//read outputs
	output TAG read_out_1,
	output TAG read_out_2,
	
	//return the value in write_idx (before it is written)
	output TAG write_out
);
	TAG [31:0] reg_map;
	
	//assign output straight from reg_map
	assign read_out_1 = reg_map[read_idx_1];
	assign read_out_2 = reg_map[read_idx_2];
	assign write_out = reg_map[write_idx];
	
	
	always_ff @(posedge clock) begin
		if (reset) begin
			//default takes the phys_reg equal to its index and set as valid
			foreach (reg_map[i]) begin
				reg_map[i].phys_reg <= i;
				reg_map[i].valid <= 1'b1;
				reg_map[i].ready <= 1'b1;
			end
		end else begin
			//if cdb is valid, then ready all tags that has same phys_reg
			if (cdb_enable) begin
				foreach (reg_map[i]) begin
					if (reg_map[i].phys_reg == cdb.phys_reg) begin
						reg_map[i].ready <= 1'b1;
					end
				end
			end
			//write new tag
			if (write_en) begin
				reg_map[write_idx] <= write_tag;
			end
		end
	end
	
endmodule		
