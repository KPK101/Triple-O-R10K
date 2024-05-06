/////////////////////////////////////////////////////////////////////////
//                                                                     //
//   Modulename :  stage_id.sv                                         //
//                                                                     //
//  Description :  instruction decode (ID) stage of the pipeline;      //
//                 decode the instruction fetch register operands, and //
//                 compute immediate operand (if applicable)           //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

`include "verilog/sys_defs.svh"
`include "verilog/ISA.svh"


module stage_id (
    input IF_ID_PACKET if_id_reg,
    input MT_ID_PACKET mt_id_packet,
    input RS_ID_PACKET rs_id_packet,
    input ROB_ID_PACKET rob_id_packet,
    input FL_ID_PACKET fl_id_packet,
    
    output ID_MT_PACKET id_mt_packet,
    output ID_RS_PACKET id_rs_packet,
    output ID_ROB_PACKET id_rob_packet,
    output ID_FL_PACKET id_fl_packet,
    output logic id_stall
);

    //Create decoder_packet for rs
    logic has_dest;
    logic has_dest_reg;
    DECODER_PACKET decoder_packet;
    
    //Decoder Passthrough
    assign decoder_packet.inst = if_id_reg.inst;
    assign decoder_packet.PC = if_id_reg.PC;
    assign decoder_packet.NPC = if_id_reg.NPC;
    assign decoder_packet.valid = if_id_reg.valid & ~decoder_packet.illegal;
    assign decoder_packet.pred_take = if_id_reg.pred_take;

    decoder decoder_0 (
        // Inputs
        .inst  (if_id_reg.inst),
        .valid (if_id_reg.valid),

        // Outputs
        .opa_select    (decoder_packet.opa_select),
        .opb_select    (decoder_packet.opb_select),
        .alu_func      (decoder_packet.alu_func),
        .has_dest      (has_dest),
        .rd_mem        (decoder_packet.rd_mem),
        .wr_mem        (decoder_packet.wr_mem),
        .cond_branch   (decoder_packet.cond_branch),
        .uncond_branch (decoder_packet.uncond_branch),
        .csr_op        (decoder_packet.csr_op),
        .halt          (decoder_packet.halt),
        .illegal       (decoder_packet.illegal)
    );
    assign has_dest_reg = has_dest && if_id_reg.inst.r.rd != `ZERO_REG;

    //Helpers
    logic write;
    assign write = (if_id_reg.inst != `NOP) && rs_id_packet.free && rob_id_packet.free && fl_id_packet.free && decoder_packet.valid;
    
    assign id_stall = (if_id_reg.inst == `NOP) || (rs_id_packet.free && rob_id_packet.free && fl_id_packet.free);

    logic need_rs1;
    logic need_rs2;
    assign need_rs1 = (decoder_packet.opa_select == OPA_IS_RS1) || (decoder_packet.cond_branch);    
    assign need_rs2 = (decoder_packet.opb_select == OPB_IS_RS2      || 
                       decoder_packet.opb_select == OPB_IS_B_IMM    || 
                       decoder_packet.opb_select == OPB_IS_S_IMM);
    
    //Assign Map Table Output
    assign id_mt_packet.read_idx_1 = need_rs1 ? decoder_packet.inst.r.rs1 : `ZERO_REG;
    assign id_mt_packet.read_idx_2 = need_rs2 ? decoder_packet.inst.r.rs2 : `ZERO_REG;
    assign id_mt_packet.write_idx = has_dest_reg ? if_id_reg.inst.r.rd : `ZERO_REG;
    assign id_mt_packet.write_tag = fl_id_packet.free_tag;
    assign id_mt_packet.write_en = write && has_dest_reg;
    
    //Assign Map Table Input
    assign decoder_packet.t = has_dest_reg ? fl_id_packet.free_tag : 0;
    assign decoder_packet.t1 = mt_id_packet.read_out_1;
    assign decoder_packet.t2 = mt_id_packet.read_out_2;
    
    //Assign Reservation Station Output
    assign id_rs_packet.decoder_packet = decoder_packet;
    assign id_rs_packet.write_en = write;
    
    //Assign Reservation Station Input
    assign decoder_packet.rs_idx = rs_id_packet.free_idx;
    
    //Assign Reorder Buffer Output
    assign id_rob_packet.write_en = write;
    
    assign id_rob_packet.t_in = fl_id_packet.free_tag;
    assign id_rob_packet.t_old_in = mt_id_packet.write_out;
    
    assign id_rob_packet.inst = if_id_reg.inst;
    assign id_rob_packet.halt = decoder_packet.halt;
    assign id_rob_packet.wr_mem = decoder_packet.wr_mem;
    assign id_rob_packet.has_dest_reg = has_dest_reg;
    assign id_rob_packet.NPC = if_id_reg.NPC;
    
    
    //Assign Reorder buffer Input
    assign decoder_packet.rob_idx = rob_id_packet.free_idx;
    
    //Assign Free List Output
    assign id_fl_packet.pop_en = write && has_dest_reg;
    
endmodule // stage_id
