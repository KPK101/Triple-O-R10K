//TODO:ADD LOGIC
module stage_ir(
    input ROB_IR_PACKET rob_ir_packet,
    
    output IR_FL_PACKET fl_packet,
    output IR_MT_PACKET mt_packet,
    output IR_PIPELINE_PACKET pipe_packet,
    
    output interrupt,
    output ['XLEN-1:0] branch_target,
    
    output [1:0]       store2Dmem_command,
    output MEM_SIZE    store2Dmem_size,
    output [`XLEN-1:0] store2Dmem_addr,
    output [`XLEN-1:0] store2Dmem_data,
);
    assign fl_packet.retire_t = rob_ir_packet.retire_t;
    assign fl_packet.retire_t_old = rob_ir_packet.retire_t_old;
    assign fl_packet.retire_en = rob_ir_packet.retire_en;
    
    assign mt_packet.retire_t = rob_ir_packet.retire_t;
    assign mt_packet.retire_t_old = rob_ir_packet.retire_t_old;
    assign mt_packet.retire_en = rob_ir_packet.retire_en;
    
    assign pipe_packet.completed_insts = rob_ir_packet.retire_en;
    assign pipe_packet.error_status = rob_ir_packet.halt ? HALTED_ON_WFI : NO_ERROR;
    assign pipe_packet.wr_idx = rob_ir_packet.dest_reg_idx;
    assign pipe_packet.wr_data = rob_ir_packet.result;
    assign pipe_packet.wr_en = rob_ir_packet.dest_reg_idx != 'ZERO_REG && rob_ir_packet.retire_en;
    assign pipe_packet.NPC = rob_ir_packet.take_branch ? rob_ir_packet.result : rob_ir_packet.NPC;
    
    assign store2Dmem_command = (rob_ir_packet.retire_en && rob_ir_packet.wr_mem) ? BUS_STORE : BUS_NONE;
    assign store2Dmem_size = (rob_ir_packet.retire_en && rob_ir_packet.wr_mem) ? BUS_STORE : BUS_NONE;
    assign store2Dmem_addr = rob_ir_packet.result;
    assign store2Dmem_data = rob_ir_packet.rs2_value;
    
endmodule
