typedef struct packed {
	TAG t;
	TAG t_old;
	logic is_complete;
} ROB_ENTRY;

module rob (
	input clock,
	input reset,
	input ID_ROB_PACKET id_rob_packet, //from dispatch 
	input IC_ROB_PACKET ic_rob_packet, // from complete
	
	output ROB_ID_PACKET rob_id_packet, // to dispatch -> what indexs are ready 
	output ROB_IR_PACKET rob_ir_packet // to retire -> letting know what tags to retire
);

	ROB_ENTRY [`ROB_SZ-1:0] rob; // 3:0 
	
	logic [$clog2(`ROB_SZ)-1:0] head_idx;
	logic [$clog2(`ROB_SZ):0] counter;
	logic rob_full;

	//Handle rob->id
	assign rob_id_packet.full = rob_full;
	assign rob_full = (counter == `ROB_SZ-1); // check if rob has room to take the packet 
	
	//Handle rob->retire output
	assign rob_ir_packet.retire_t = rob[head_idx].t; // tag 
	assign rob_ir_packet.retire_t_old = rob[head_idx].t_old; // old tag
	assign rob_ir_packet.retire_en = rob[head_idx].is_complete; // retire enable 
	
	always_ff @(posedge clock) begin
		if (reset) begin
			//Reset head and tail index
			head_idx <= 0;
			rob_id_packet.free_idx <= 0; // start from the top of the list 
			counter <= 0;
			//Invalidate 0 index entry for insertion
			rob[0].t.valid <= 0;
			rob[0].t_old.valid <= 0;
			rob[0].is_complete <= 0;
		end else begin
			//Handle id->rob
			if (!rob_full && id_rob_packet.write_en) begin // write something
				rob[rob_id_packet.free_idx].t <= id_rob_packet.t_in;
				rob[rob_id_packet.free_idx].t_old <= id_rob_packet.t_old_in;
				rob[rob_id_packet.free_idx].is_complete <= 0;
				counter <= counter + 1;
				rob_id_packet.free_idx <= rob_id_packet.free_idx + 1;
			end
			//Handle ic->rob
			if (ic_rob_packet.complete_en) begin // if something is complete
				rob[ic_rob_packet.complete_idx].is_complete <= 1;
			end
			//Handle rob->retire update
			if (rob_ir_packet.retire_en) begin 
				head_idx <= head_idx + 1;
				counter <= counter - 1;
			end
			if (rob_id_packet.full == 1) rob_id_packet.free_idx = `FALSE;
		end
	end
endmodule
			
	
	
