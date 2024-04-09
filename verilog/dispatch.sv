module dispatch(
	input clock,
	input reset,
	input IF_ID_PACKET if_id_pkt,
	input free_from_rs;
	output ID_IS_PACKET output_pkt;
	output 
	
);

logic INST instr;
logic busy_rs_out;
logic TAG T, T1, T2;
logic REG op_a, op_b, op_out;
logic ID_IS_PACKET id_packet, output_pkt;
logic has_dest_reg;
logic stall;
logic wr_en_rs;
logic wr_en_rob;

assign output_pkt = id_packet;

/*rs res_sta_0(
	.clock(clock),
	.reset(reset),
	.instr(instr),
	.busy(busy_rs_out)
);	
*/
decoder decoder_0 (
        // Inputs
        .inst  (if_id_pkt.inst),
        .valid (if_id_pkt.valid),

        // Outputs
        .opa_select    (id_packet.opa_select),
        .opb_select    (id_packet.opb_select),
        .alu_func      (id_packet.alu_func),
        .has_dest      (has_dest_reg),
        .rd_mem        (id_packet.rd_mem),
        .wr_mem        (id_packet.wr_mem),
        .cond_branch   (id_packet.cond_branch),
        .uncond_branch (id_packet.uncond_branch),
        .csr_op        (id_packet.csr_op),
        .halt          (id_packet.halt),
        .illegal       (id_packet.illegal)
);

logic free;
logic TAG new_tag;
free_list free_list_0(
	.clock(clock),
	.reset(reset),
	.free(free),
	.free_tag(new_tag)
);

logic write_en;
logic [4:0] dest_reg;
assign dest_reg = (has_dest_reg) ? if_id_reg.inst.r.rd : `ZERO_REG;
map_table map_table_0(
	.read_idx_1(id_packet.opa_select),
	.read_idx_2(id_packet.opb_select),
	.read_out_1(id_packet.t1),
	.read_out_2(id_packet.t2),

	.write_en(write_en),
	.write_idx(dest_reg),
	.write_tag(new_tag),
	.write_out(id_packet.t)
);

always_ff @posedge(clock){
	if(reset) begin
		instr <= `NOP;
		write_en <= 0;
	end

	else begin
		if(!write_en)begin//update map_table, proceed to update rs
			write_en <= 1;
			wr_en_rs <=1;
			wr_en_rob <=1;
		end

		if(!free_from_rs)begin//try allocating to RS and ROB. If cannot allocate to RS or ROB, stall the pipeline. 
			stall<=1;
			write_en <=0;
			wr_en_rs <=0;
		end

				
	end		
}

endmodule
