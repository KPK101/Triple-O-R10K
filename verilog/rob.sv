typedef struct packed {
	TAG t;
	TAG t_old;
	logic is_complete;
} ROB_ENTRY;

module rob (
	input clock,
	input reset,
	
	input ID_ROB_PACKET id_rob_packet,
	
	input IC_ROB_PACKET ic_rob_packet,
	
	output ROB_ID_PACKET rob_id_packet,
	
	output ROB_IR_PACKET rob_ir_packet
);
	ROB_ENTRY [`ROB_SZ-1:0] rob;
	
	logic [$clog2(`ROB_SZ)-1:0] head_idx;
	logic [$clog2(`ROB_SZ):0] counter;
	
	//Handle rob->id
	assign rob_id_packet.free = counter == `ROB_SZ;
	
	//Handle rob->retire output
	assign rob_ir_packet.retire_t = rob[head_idx].t;
	assign rob_ir_packet.retire_t_old = rob[head_idx].t_old;
	assign rob_ir_packet.retire_en = rob[head_idx].is_complete;
	assign next_counter = rob_ir_packet.retire_en && !(rob_id_packet.free && id_rob_packet.write_en) ? counter - 1 :
                          (rob_id_packet.free && id_rob_packet.write_en) && !rob_ir_packet.retire_en ? counter + 1 : counter;
	
	always_ff @(posedge clock) begin
		if (reset) begin
			//Reset head and tail index
			head_idx <= 0;
			rob_id_packet.free_idx <= 0;
			counter <= 0;
			//Invalidate 0 index entry for insertion
			rob[0].t.valid <= 0;
			rob[0].t_old.valid <= 0;
			rob[0].is_complete <= 0;
		end else begin
			//Handle id->rob
			if (rob_id_packet.free && id_rob_packet.write_en) begin
				rob[rob_id_packet.free_idx].t <= t_in;
				rob[rob_id_packet.free_idx].t_old <= t_old_in;
				rob[rob_id_packet.free_idx].is_complete <= 0;
				rob_id_packet.free_idx <= rob_id_packet.free_idx + 1;
			end
			//Handle ic->rob
			if (ic_rob_packet.complete_en) begin
				rob[ic_rob_packet.complete_idx].is_complete <= 1;
			end
			
			//Handle rob->retire update
			if (rob_ir_packet.retire_en) begin
				head_idx <= head_idx + 1;
			end
			//Update Counter
			counter <= next_counter;
		end
	end
endmodule
			
	
	
