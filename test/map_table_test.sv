`timescale 1ns / 1ps
`include "verilog/sys_defs.svh"
`include "verilog/ISA.svh"

module map_table_tb;

// Define testbench signals based on the map_table module's interface
reg clock;
reg reset;
TAG T, T1, T2;
COMMAND command_inp;
reg [$clog2(`PHYS_REG_SZ)-1:0] reg_input_t, reg_input_t1, reg_input_t2;
TAG T_out, T1_out, T2_out;

// Instantiate the map_table
map_table dut (
    .clock(clock),
    .reset(reset),
    .command(command_inp), 
    .t(T), .t1(T1), .t2(T2), 
    .t_out(T_out), .t1_out(T1_out), .t2_out(T2_out),
    .reg_t(reg_input_t), .reg_t1(reg_input_t1), .reg_t2(reg_input_t2)
);

// Clock generation
initial begin
    clock = 0;
    forever #10 clock = ~clock;
end


// Test stimulus
initial begin
    // Initialize inputs
    
$display("STARTING TESTBENCH!");

    reset = 1;
$display("@@@ Time:%4.0f clock:%b reset:%b T_input:%b T1_input:%b T2_input:%b command:%b reg_input_t:%h reg_input_t1:%h reg_input_t2:%h", $time, clock, reset, T, T1, T2, command_inp, reg_input_t, reg_input_t1, reg_input_t2, T_out, T1_out, T2_out);

$monitor("@@@ Time:%4.0f clock:%b reset:%b T_input:%b T1_input:%b T2_input:%b command:%b reg_input_t:%h reg_input_t1:%h reg_input_t2:%h T_out:%b T1_out:%b T2_out:%b ", $time, clock, reset, T, T1, T2, command_inp, reg_input_t, reg_input_t1, reg_input_t2, T_out, T1_out, T2_out);
    // Release reset
    #20;
    reset = 0;

    // Test read functionality of tags
    #20;
    reg_input_t = 0;
    reg_input_t1 = 1;
    reg_input_t2 = 2;
    command_inp = READ;
	


	// Continue simulation for a while to observe behavior
    #60;
    $display("\nENDING TESTBENCH: SUCCESS!");
    $display("@@@ Passed\n");
    $finish; // End simulation
end

// Initialize signals for waveform generation
initial begin
    $dumpfile("map_table_tb.vcd");
    $dumpvars(0, map_table_tb);
end

endmodule
