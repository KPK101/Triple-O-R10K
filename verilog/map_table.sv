
module map_table (
	input clock,
	input reset,
	
	//cdb for ready bit generator
	input TAG cdb,
	input cdb_en,
	
	input interrupt,
	
	input ID_MT_PACKET id_mt_packet,
	
	input IR_MT_PACKET ir_mt_packet,
	
	output MT_ID_PACKET mt_id_packet
);
	TAG [31:0] reg_map;
	TAG [31:0] arch_reg_map;
	
	//Handle mt -> id output
	assign mt_id_packet.write_out = reg_map[id_mt_packet.write_idx];
	
	always_comb begin
	    if(cdb_en) begin
	        if(reg_map[id_mt_packet.read_idx_1].phys_reg == cdb.phys_reg) begin
	            mt_id_packet.read_out_1 = cdb;
	        end else begin 
	            mt_id_packet.read_out_1  = reg_map[id_mt_packet.read_idx_1];
	        end
	        
	        if(reg_map[id_mt_packet.read_idx_2].phys_reg == cdb.phys_reg) begin
	            mt_id_packet.read_out_2 = cdb;
	        end else begin 
	            mt_id_packet.read_out_2  = reg_map[id_mt_packet.read_idx_2];
	        end
	    end else begin
	        mt_id_packet.read_out_1 = reg_map[id_mt_packet.read_idx_1];
	        mt_id_packet.read_out_2 = reg_map[id_mt_packet.read_idx_2];
	        
	    end
	end
	
	always_ff @(posedge clock) begin
	    //Handle reset
		if (reset) begin
			foreach (reg_map[i]) begin
				reg_map[i].phys_reg <= i;
				reg_map[i].valid <= 1'b1;
				reg_map[i].ready <= 1'b1;
			end
			foreach (arch_reg_map[i]) begin
                arch_reg_map[i].phys_reg <= i;
                arch_reg_map[i].valid <= 1'b1;
                arch_reg_map[i].ready <= 1'b1;
			end
		end else if (interrupt) begin
		    foreach (reg_map[i]) begin
		        reg_map[i] <= arch_reg_map[i];
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
			if (id_mt_packet.write_en && id_mt_packet.write_idx != 0) begin
				reg_map[id_mt_packet.write_idx] <= id_mt_packet.write_tag;
			end
			//Handle ir -> mt
			if(ir_mt_packet.retire_en) begin
			    foreach (arch_reg_map[i]) begin
				    if (ir_mt_packet.retire_t_old.phys_reg != 0 && arch_reg_map[i].phys_reg == ir_mt_packet.retire_t_old.phys_reg) begin
					    arch_reg_map[i] <= ir_mt_packet.retire_t;
                        arch_reg_map[i].valid <= 1'b1;
                        arch_reg_map[i].ready <= 1'b1;
				    end
			    end
			end
		end
	end
	
endmodule		
