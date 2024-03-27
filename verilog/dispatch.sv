module dispatch(
	input clock,
	input reset,
	input IF_ID_PACKET if_id_pkt,
	
);

logic INST instr;
logic busy_rs_out;
logic TAG T, T1, T2;
logic REG op_a, op_b, op_out;


rs res_sta_0(
	.clock(clock),
	.reset(reset),
	.instr(instr),
	.busy(busy_rs_out)
);	

map_table map_table_0(
	.op_a(op_a),
	.op_b(op_b),
	.op_out(op_out),
	.t1(T1),
	.t2(T2),
	.t(T)
);

assign op_a = instr.////continue from here

always_ff @posedge(clock){
	if(reset) begin
		instr <= `NOP;
	end

	else begin
		instr <= if_id_pkt.instr;
				
	end		
}

endmodule
