`include "verilog/sys_defs.svh"
`include "verilog/ISA.svh"
module stage_ic(
    input EX_IC_PACKET ex_ic_reg,
    
    output TAG cdb,
    output cdb_en,

    output IC_ROB_PACKET ic_rob_packet
    
);

    assign cdb = ex_ic_reg.dest_tag;
    assign cdb_en = ex_ic_reg.valid;

    assign ic_rob_packet.complete_en = ex_ic_reg.valid;
    assign ic_rob_packet.complete_idx = ex_ic_reg.rob_idx;
    
    assign ic_rob_packet.take_branch = ex_ic_reg.take_branch;
    assign ic_rob_packet.result = ex_ic_reg.result;
    assign ic_rob_packet.rs2_value = ex_ic_reg.rs2_value;

endmodule
