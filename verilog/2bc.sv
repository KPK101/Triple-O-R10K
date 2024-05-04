typedef enum{
   SN = 2'b00, // 0
   WN = 2'b01, // 0
   WT = 2'b10, // 1
   ST = 2'b11 // 1
} ts_state;

module 2bc(
	input clock,
	input reset,
	input take, // rob_ir_packet.take_branch 
	input enable,
	output logic outcome
);

  ts_state next_state, curr_state;

  assign outcome = curr_state[1]; // 0 -> not take | 1 -> take
   
   always_comb begin
	next_state = curr_state;
	case (curr_state)
	   SN: next_state = take ? WN : SN;
	   WN: next_state = take ? WT : SN;
	   WT: next_state = take ? ST : WN;
	   ST: next_state = take ? ST : WT;
	endcase
   end

   always_ff @(posedge clock) begin
	if (reset) curr_state <= SN;
	else if (enable) curr_state <= next_state;
   end


endmodule
