typedef struct packed {
	logic halt;
	TAG t;
	TAG t_old;
	logic wr_mem;
	logic [4:0] dest_reg_idx;
	logic [`XLEN-1:0] NPC;
	
	logic complete;
	logic [`XLEN-1:0] result;
	logic [`XLEN-1:0] rs2_value;
	logic take_branch;
	
	
} ROB_ENTRY;

module rob (
	input clock,
	input reset,
	
	input ID_ROB_PACKET id_rob_packet,
	
	input IC_ROB_PACKET ic_rob_packet,
	
	output ROB_ID_PACKET rob_id_packet,
	
	output ROB_IR_PACKET rob_ir_packet, 
	output logic [$clog2(`ROB_SZ):0] counter  
	//output logic [$clog2(`ROB_SZ):0] next_counter
);
	ROB_ENTRY [`ROB_SZ-1:0] rob;
	
	logic [$clog2(`ROB_SZ)-1:0] head_idx;
	//logic [$clog2(`ROB_SZ):0] next_counter;
	//logic [$clog2(`ROB_SZ):0] counter;
	logic [$clog2(`ROB_SZ)-1:0] tail_idx;
	
	//Handle rob->id
	assign rob_id_packet.free = (counter != `ROB_SZ);
	assign rob_id_packet.free_idx = tail_idx;
	
	//Handle rob->retire output
	assign rob_ir_packet.retire_en = rob[head_idx].complete;
	assign rob_ir_packet.retire_t = rob[head_idx].t;
	assign rob_ir_packet.retire_t_old = rob[head_idx].t_old;
	
	assign rob_ir_packet.halt = rob[head_idx].halt;
	assign rob_ir_packet.wr_mem = rob[head_idx].wr_mem;
	assign rob_ir_packet.dest_reg_idx = rob[head_idx].dest_reg_idx;
	assign rob_ir_packet.NPC = rob[head_idx].NPC;
	
	assign rob_ir_packet.result = rob[head_idx].result;
	assign rob_ir_packet.rs2_value = rob[head_idx].rs2_value;
	assign rob_ir_packet.take_branch = rob[head_idx].take_branch;
	
	//Handle internal counter
	//assign next_counter = rob_ir_packet.retire_en && !(rob_id_packet.free && id_rob_packet.write_en) ? counter - 1 :
         //                 (rob_id_packet.free && id_rob_packet.write_en) && !rob_ir_packet.retire_en ? counter + 1 : counter;
	//assign next_counter = rob_ir_packet.retire_en ? counter-1 : rob_id_packet.free && id_rob_packet.write_en ? counter + 1:  counter ;
	
	always_ff @(posedge clock) begin
		if (reset) begin
			//Reset head and tail index
			head_idx <= 0;
			//rob_id_packet.free_idx <= 0; // output 
			tail_idx <= 0;
			counter <= 0;
			//Invalidate 0 index entry for insertion
			rob[0].t.valid <= 0;
			rob[0].t_old.valid <= 0;
			rob[0].complete <= 0;
		end else begin
			//Handle id->rob
			if (rob_id_packet.free && id_rob_packet.write_en) begin
				rob[tail_idx].t <= id_rob_packet.t_in;
				rob[tail_idx].t_old <= id_rob_packet.t_old_in;
				rob[tail_idx].complete <= 0;
				
				rob[tail_idx].halt <= id_rob_packet.halt;
				rob[tail_idx].wr_mem <= id_rob_packet.wr_mem;
				rob[tail_idx].dest_reg_idx <= id_rob_packet.dest_reg_idx;
				rob[tail_idx].NPC <= id_rob_packet.NPC;
				tail_idx <= tail_idx + 1;

				if (!rob_ir_packet.retire_en) counter <= counter + 1;
				else if (rob_ir_packet.retire_en) counter <= counter;
			end
			//Handle ic->rob
			if (ic_rob_packet.complete_en) begin
				rob[ic_rob_packet.complete_idx].complete <= 1;
				rob[ic_rob_packet.complete_idx].result <= ic_rob_packet.result;
				rob[ic_rob_packet.complete_idx].rs2_value <= ic_rob_packet.rs2_value;
				rob[ic_rob_packet.complete_idx].take_branch <= ic_rob_packet.take_branch;
				
			end
			
			//Handle rob->retire update
			if (rob_ir_packet.retire_en) begin
				head_idx <= head_idx + 1;
				//counter <= counter - 1;
				counter <= 0; // next cycle
				//if (!(rob_id_packet.free && id_rob_packet.write_en)) counter <= counter - 1;
				//else counter <= counter;
			end
			//Update Counter
			//counter <= next_counter;
		end
	end
endmodule
			
	
	
