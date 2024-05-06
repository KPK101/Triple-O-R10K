typedef struct packed {
	logic completed;
	//Values for actual retiring
	TAG t;
	TAG t_old;

	//Values from ID stored for retiring
	INST  inst;
	logic halt;
	logic wr_mem;
	logic has_dest_reg;
	logic [`XLEN-1:0] NPC;

	//Values from IC stored for retiring
	logic take_branch;
} ROB_ENTRY;

module rob (
	input clock,
	input reset,
	input interrupt,

	input ir_stall,
	
	input ID_ROB_PACKET id_rob_packet,
	
	input IC_ROB_PACKET ic_rob_packet,
	
	output ROB_ID_PACKET rob_id_packet,
	
	output ROB_IR_PACKET rob_ir_packet


);
	ROB_ENTRY [`ROB_SZ-1:0] rob;
	
	logic [$clog2(`ROB_SZ)-1:0] head_idx;
	logic [$clog2(`ROB_SZ+1):0] counter;
	logic [$clog2(`ROB_SZ+1):0] next_counter;
	
	//Handle rob->id
	assign rob_id_packet.free = counter < `ROB_SZ;
	assign rob_ir_packet.retire_en = rob[head_idx].completed && counter > 0;
	
	//Handle rob->retire output
	always_comb begin 
		if (rob_ir_packet.retire_en) begin
			rob_ir_packet.retire_t = rob[head_idx].t;
			rob_ir_packet.retire_t_old = rob[head_idx].t_old;
		
			rob_ir_packet.inst = rob[head_idx].inst;
			rob_ir_packet.halt = rob[head_idx].halt;
			rob_ir_packet.wr_mem = rob[head_idx].wr_mem;
			rob_ir_packet.has_dest_reg = rob[head_idx].has_dest_reg;
			rob_ir_packet.NPC = rob[head_idx].NPC;
		
			rob_ir_packet.take_branch = rob[head_idx].take_branch;
		end else begin
			rob_ir_packet.retire_t = 0;
			rob_ir_packet.retire_t_old = 0;
		
			rob_ir_packet.inst = `NOP;
			rob_ir_packet.halt = 0;
			rob_ir_packet.wr_mem = 0;
			rob_ir_packet.has_dest_reg = 0;
			rob_ir_packet.NPC = 0;

			rob_ir_packet.take_branch = 0;
		end
	end
	
	//Handle internal counter
	assign next_counter = rob_ir_packet.retire_en && !(rob_id_packet.free && id_rob_packet.write_en) ? counter - 1 :
                          (rob_id_packet.free && id_rob_packet.write_en) && !rob_ir_packet.retire_en ? counter + 1 : counter;
	
	always_ff @(posedge clock) begin
		if (reset || interrupt) begin
			//Reset head and tail index
			head_idx <= 0;
			rob_id_packet.free_idx <= 0;
			counter <= 0;
			foreach (rob[i]) begin
				rob[i].completed <= 0;
			end
		end else begin
			//Handle id->rob
			if (rob_id_packet.free && id_rob_packet.write_en) begin
				rob[rob_id_packet.free_idx].completed <= 0;
				rob[rob_id_packet.free_idx].t <= id_rob_packet.t_in;
				rob[rob_id_packet.free_idx].t_old <= id_rob_packet.t_old_in;
				
				rob[rob_id_packet.free_idx].inst <= id_rob_packet.inst;
				rob[rob_id_packet.free_idx].halt <= id_rob_packet.halt;
				rob[rob_id_packet.free_idx].wr_mem <= id_rob_packet.wr_mem;
				rob[rob_id_packet.free_idx].has_dest_reg <= id_rob_packet.has_dest_reg;
				rob[rob_id_packet.free_idx].NPC <= id_rob_packet.NPC;
				
				rob_id_packet.free_idx <= rob_id_packet.free_idx + 1;
			end
			//Handle ic->rob
			if (ic_rob_packet.complete_en) begin
				rob[ic_rob_packet.complete_idx].completed <= 1;
				rob[ic_rob_packet.complete_idx].take_branch <= ic_rob_packet.take_branch;
			end
			
			//Handle rob->retire update
			if (rob_ir_packet.retire_en && !ir_stall) begin
				head_idx <= head_idx + 1;
			end
			//Update Counter
			counter <= next_counter;
		end
	end
endmodule
