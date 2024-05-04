`include "verilog/sys_defs.svh"
`include "verilog/ISA.svh"
module stage_ir(
    input ROB_IR_PACKET rob_ir_packet,
    input PRF_IR_PACKET prf_ir_packet,
    
    output IR_FL_PACKET ir_fl_packet,
    output IR_MT_PACKET ir_mt_packet,
    output IR_PRF_PACKET ir_prf_packet,
    output IR_PIPELINE_PACKET pipe_packet,
    
    output interrupt,
    output [`XLEN-1:0] branch_target,
    
    output [1:0]       store2Dmem_command,
    output MEM_SIZE    store2Dmem_size,
    output [`XLEN-1:0] store2Dmem_addr,
    output [`XLEN-1:0] store2Dmem_data
);
    assign ir_fl_packet.retire_t = rob_ir_packet.retire_t;
    assign ir_fl_packet.retire_t_old = rob_ir_packet.retire_t_old;
    assign ir_fl_packet.retire_en = rob_ir_packet.dest_reg_idx != `ZERO_REG && rob_ir_packet.retire_en;
    
    assign ir_mt_packet.retire_t = rob_ir_packet.retire_t;
    assign ir_mt_packet.retire_t_old = rob_ir_packet.retire_t_old;
    assign ir_mt_packet.retire_en = rob_ir_packet.dest_reg_idx != `ZERO_REG && rob_ir_packet.retire_en;
    assign ir_prf_packet.read_tag = rob_ir_packet.retire_t;
    
    assign pipe_packet.completed_insts = {3'b0, rob_ir_packet.retire_en};
    assign pipe_packet.error_status = rob_ir_packet.halt ? HALTED_ON_WFI : NO_ERROR;
    assign pipe_packet.wr_en = rob_ir_packet.dest_reg_idx != `ZERO_REG && rob_ir_packet.retire_en;
    assign pipe_packet.wr_idx = rob_ir_packet.dest_reg_idx;
    assign pipe_packet.wr_data = prf_ir_packet.read_out;
    assign pipe_packet.NPC = rob_ir_packet.NPC;

    assign interrupt = rob_ir_packet.retire_en && rob_ir_packet.take_branch;
    assign branch_target = rob_ir_packet.result;
    
    assign store2Dmem_command = (rob_ir_packet.retire_en && rob_ir_packet.wr_mem) ? BUS_STORE : BUS_NONE;
    assign store2Dmem_size = MEM_SIZE'(rob_ir_packet.inst.r.funct3[1:0]);
    assign store2Dmem_addr = rob_ir_packet.result;
    assign store2Dmem_data = rob_ir_packet.rs2_value;
    
endmodule
