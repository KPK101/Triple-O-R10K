`include "verilog/sys_defs.svh"
`include "verilog/ISA.svh"
module stage_ic(
    input EX_IC_PACKET ex_ic_reg,
    
    output TAG cdb,
    output cdb_en,

    output IC_ROB_PACKET ic_rob_packet,
    output IC_IR_PACKET ic_ir_packet
    
);

    assign cdb.phys_reg = ex_ic_reg.dest_tag.phys_reg;
    assign cdb.ready = ex_ic_reg.valid;
    assign cdb_en = ex_ic_reg.valid;

    assign ic_rob_packet.complete_en = ex_ic_reg.valid;
    assign ic_rob_packet.complete_idx = ex_ic_reg.rob_idx;
    
    assign ic_rob_packet.take_branch = ex_ic_reg.take_branch;

    assign ic_ir_packet.take_branch = ex_ic_reg.take_branch;
    assign ic_ir_packet.branch_result = ex_ic_reg.result;

    assign ic_ir_packet.wr_mem = ex_ic_reg.wr_mem;
    assign ic_ir_packet.wr_addr = ex_ic_reg.result;
    assign ic_ir_packet.wr_data = ex_ic_reg.rs2_value;

    assign ic_ir_packet.rs_idx = ex_ic_reg.rs_idx;

    assign ic_ir_packet.valid = ex_ic_reg.valid;

endmodule
