`include "verilog/sys_defs.svh"
`include "verilog/ISA.svh"


module cdb(
    input clock,
    input reset,
    input TAG Tin,
    output TAG Tout,
    output TAG Tout1,
    output TAG Tout2
);

logic TAG T, T1;
logic enable_cdb;

rs rs_sta_1(
    .clock(clock),
    .reset(reset),
    .T(Tout),
    .T1(Tout1),
    .T2(Tout2)
)


rob rob_1(
    .clock(clock),
    .reset(reset),
)

always_ff @(posedge clock) begin
    if (reset) begin    
        Tin <= 0;
    end

end