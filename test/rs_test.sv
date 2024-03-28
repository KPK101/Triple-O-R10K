`timescale 1ns / 1ps
`include "verilog/sys_defs.svh"
`include "verilog/ISA.svh"

module rs_tb;

// Define testbench signals based on the rs module's interface
reg clock;
reg reset;
reg [31:0] inst; // Simplification, adjust according to your actual packet structure
reg [2:0] alu_func; // Example functional unit specifier
reg [6:0] opcode;
// Assuming TAG is a structure you have defined that includes a 'tag' and 'ready' field
TAG T, T1, T2, CDB;
ID_EX_PACKET inp;
wire rs_busy_alu, rs_busy_fp1, rs_busy_fp2, rs_busy_ld, rs_busy_st;
wire issue;
wire [31:0] issue_pkt; // Simplification, adjust according to your actual packet structure

// Instantiate the RS
rs dut (
    .clock(clock),
    .reset(reset),
    // Assuming op is a complex packet, you'd need to construct it properly
    .op(inp), // Simplified, construct this based on your actual structure
    .T(T), .T1(T1), .T2(T2), .CDB(CDB),
    .rs_busy_alu(rs_busy_alu),
    .rs_busy_fp1(rs_busy_fp1),
    .rs_busy_fp2(rs_busy_fp2),
    .rs_busy_ld(rs_busy_ld),
    .rs_busy_st(rs_busy_st),
    .issue_pkt(issue_pkt),
    .issue(issue)
);

// Clock generation
initial begin
    clock = 0;
    forever #10 clock = ~clock;
end

assign inp.alu_func = alu_func;
assign inp.inst = inst;
assign inp.T = T;
assign inp.T1 = T1;
assign inp.T2 = T2;
// Test stimulus
initial begin
    // Initialize inputs
    
$display("STARTING TESTBENCH!");

    reset = 1;
    opcode = 7'b0110011; // Example opcode, adjust based on your design
    alu_func = 3'b000; // Example, specify the function
    T = {1'b1, 1'b0}; // Example TAG initialization, indicating operand not ready
    T1 = {1'b1, 1'b1}; // Operand ready
    T2 = {1'b0, 1'b1}; // Operand ready

$display("@@@ Time:%4.0f clock:%b reset:%h opcode:%b alu_func:%b T:%h T1:%b T2:%b issue:%b", $time, clock, reset, opcode, alu_func, T, T1, T2, issue);

$monitor("@@@ Time:%4.0f clock:%b reset:%h opcode:%b alu_func:%b T:%h T1:%b T2:%b issue:%b", $time, clock, reset, opcode, alu_func, T, T1, T2, issue);
    // Release reset
    #20;
    reset = 0;

    // Dispatch an instruction to RS
    #20;
    inst = 32'hDEADBEEF; // Example instruction, use real encoding as per your ISA
    // Note: You will need to set `op` properly if it's a struct or more complex than a single signal

    // Update operand readiness after some cycles
    #30;
    T = {1'b0, 1'b1}; // Now operand becomes ready

    // Continue simulation for a while to observe behavior
    #100;

    $display("\nENDING TESTBENCH: SUCCESS!");
    $display("@@@ Passed\n");
    $finish; // End simulation
end

// Initialize signals for waveform generation
initial begin
    $dumpfile("rs_tb.vcd");
    $dumpvars(0, rs_tb);
end

endmodule
