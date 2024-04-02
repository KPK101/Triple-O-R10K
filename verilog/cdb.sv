`include "verilog/sys_defs.svh"
`include "verilog/ISA.svh"


module cdb(
    // input clock,
    // input reset,
    input en_rob,
    input TAG rob_in,
    output TAG rs_out
);



always_comb begin
    if(en_rob)begin
        rs_out = rob_in;
    end
end
