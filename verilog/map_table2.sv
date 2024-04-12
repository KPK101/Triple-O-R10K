
module map_table (
	input clock,
	input reset,
	
	//cdb for ready bit generator
	input TAG cdb,
	input cdb_en,
	
	input interrupt;
	
	input ID_MT_PACKET id_mt_packet,
	
	input ROB_MT_PACKET rob_mt_packet,
	
	output MT_ID_PACKET mt_id_packet,
	
);
	TAG [31:0] reg_map;
	TAG [31:0] arch_map;
	logic [`PHYS_REG_SZ-1:0] free_list;
	
	//Handle mt -> id output
	assign mt_id_packet.read_out_1 = reg_map[id_mt_packet.read_idx_1];
	assign mt_id_packet.read_out_2 = reg_map[id_mt_packet.read_idx_2];
	assign mt_id_packet.write_t_old = reg_map[id_mt_packet.write_idx];
	always_comb begin
		//Default output
		mt_id_packet.write_t.valid = 0;
		mt_id_packet.write_t.ready = 0;
		mt_id_packet.free = 0;
		
		//Look for free tag
		foreach (free_list[i]) begin
			if (free_list[i]) begin
				mt_id_packet.write_t.valid = 1;
				mt_id_packet.write_t.phys_reg = i;
				mt_id_packet.free = 1;
			end
		end
		
	end
	
	
	always_ff @(posedge clock) begin
	    //Handle reset
		if (reset) begin
		    //reset map table
			foreach (reg_map[i]) begin
				reg_map[i].phys_reg <= i;
				reg_map[i].valid <= 1'b1;
				reg_map[i].ready <= 1'b1;
			end
			//reset arch map
			foreach (reg_map[i]) begin
				reg_map[i].phys_reg <= i;
			end
			//reset free_list
			foreach (phys_reg_free[i]) begin
				phys_reg_free[i] <= i > 31;
			end
		end else begin
			//Handle CDB
			if (cdb_en) begin
				foreach (reg_map[i]) begin
					if (reg_map[i].phys_reg == cdb.phys_reg) begin
						reg_map[i].ready <= 1'b1;
					end
				end
			end
			//Handle id -> mt
			if (id_mt_packet.write_en && mt_id_packet.free) begin
				reg_map[id_mt_packet.write_idx] <= mt_id_packet.write_t.phys_reg;
				free_list[mt_id_packet.write_t.phys_reg] <= 1'b0;
			end
			//Retire Logic
			if (rob_mt_packet.retire_en) begin
				free_list[rob_mt_packet.retire_t_old.phys_reg] <= 1'b1;
			end
			
		end
	end
	
endmodule		
