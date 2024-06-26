module free_list (
	input clock,
	input reset,
	
	input interrupt,
	
	input ID_FL_PACKET id_fl_packet,
	
	input IR_FL_PACKET ir_fl_packet,
	
	output FL_ID_PACKET fl_id_packet
);

	//Array that keeps track if reg is free
	logic [`PHYS_REG_SZ-1:0] phys_reg_free;
	logic [`PHYS_REG_SZ-1:0] phys_reg_arch_free;
	
	always_comb begin
		//Default output
		fl_id_packet.free_tag.ready = 0;
		fl_id_packet.free = 0;
		
		//TODO:implement free forwarding
		//Look for free tag
		foreach (phys_reg_free[i]) begin
			if (phys_reg_free[i] && i != 0) begin
				fl_id_packet.free_tag.phys_reg = i;
				fl_id_packet.free = 1;
			end
		end
		
	end
	
	always_ff @(posedge clock) begin
		//Reset assigns all first 32 register to be not free. (used in map table as default)
		if (reset) begin
			foreach (phys_reg_free[i]) begin
				phys_reg_free[i] <= i > 31;
			end
			foreach (phys_reg_arch_free[i]) begin
				phys_reg_arch_free[i] <= i > 31;
			end
		end else if (interrupt) begin
		    foreach (phys_reg_free[i]) begin
				if (ir_fl_packet.retire_en && i != 0 && ir_fl_packet.retire_t_old.phys_reg == i) begin
					phys_reg_free[i] <= 1'b1;
					phys_reg_arch_free[i] <= 1'b1;
				end else if (ir_fl_packet.retire_en && i != 0 && ir_fl_packet.retire_t.phys_reg == i) begin
					phys_reg_free[i] <= 1'b0;
					phys_reg_arch_free[i] <= 1'b0;
				end else begin
					phys_reg_free[i] <= phys_reg_arch_free[i];
				end
			end
		end else begin
			//When pop is enabled, set current free tag to be not free
			if (id_fl_packet.pop_en) begin
				phys_reg_free[fl_id_packet.free_tag.phys_reg] <= 1'b0;
			end
			//When retire is enabled, free t_old tag
			if (ir_fl_packet.retire_en && ir_fl_packet.retire_t_old.phys_reg != 0) begin
				phys_reg_free[ir_fl_packet.retire_t_old.phys_reg] <= 1'b1;
				phys_reg_arch_free[ir_fl_packet.retire_t_old.phys_reg] <= 1'b1;
				phys_reg_arch_free[ir_fl_packet.retire_t.phys_reg] <= 1'b0;
			end
		end
	end
endmodule
