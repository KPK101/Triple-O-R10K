
module map_table (
	input clock,
	input reset,
	
	//cdb for ready bit generator
	input TAG cdb,
	input cdb_en,
	
	input ID_MT_PACKET id_mt_packet,
	
	output MT_ID_PACKET mt_id_packet
);
	TAG [31:0] reg_map;
	
	//Handle mt -> id output
	assign mt_id_packet.read_out_1 = reg_map[id_mt_packet.read_idx_1];
	assign mt_id_packet.read_out_2 = reg_map[id_mt_packet.read_idx_2];
	assign mt_id_packet.write_out = reg_map[id_mt_packet.write_idx];
	
	
	always_ff @(posedge clock) begin
	    //Handle reset
		if (reset) begin
			foreach (reg_map[i]) begin
				reg_map[i].phys_reg <= i;
				reg_map[i].valid <= 1'b1;
				reg_map[i].ready <= 1'b1;
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
			if (id_mt_packet.write_en) begin
				reg_map[id_mt_packet.write_idx] <= id_mt_packet.write_tag;
			end
		end
	end
	
endmodule		
