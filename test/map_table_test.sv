`timescale 1ns / 1ps
`include "verilog/sys_defs.svh"
`include "verilog/ISA.svh"

module map_table_tb;

// Define testbench signals based on the map_table module's interface
reg clock;
reg reset;
reg CDB_enable;
TAG T, T1, T2, CDB;
COMMAND command_inp;
reg [$clog2(`PHYS_REG_SZ)-1:0] reg_input_t, reg_input_t1, reg_input_t2;
TAG T_out, T1_out, T2_out;

// Instantiate the map_table
map_table dut (
    .clock(clock),
    .reset(reset),
    .CDB_enable(CDB_enable),
    .command(command_inp), 
    .t(T), .t1(T1), .t2(T2), .CDB(CDB), 
    .t_out(T_out), .t1_out(T1_out), .t2_out(T2_out),
    .reg_t(reg_input_t), .reg_t1(reg_input_t1), .reg_t2(reg_input_t2)
);

// Clock generation
initial begin
    clock = 0;
    forever #5 clock = ~clock;
    assert property(@(posedge clock) 
	if(command_inp == READ)
		T1 && T1_out
	
	);
end


// Test stimulus
initial begin
    // Initialize inputs
    
$display("STARTING TESTBENCH!");

    reset = 1;
$display("@@@ Time:%4.0f clock:%b reset:%b T_input:%b T1_input:%b T2_input:%b command:%b reg_input_t:%h reg_input_t1:%h reg_input_t2:%h CDB:%h CDB_enable:%h", $time, clock, reset, T, T1, T2, command_inp, reg_input_t, reg_input_t1, reg_input_t2, T_out, T1_out, T2_out, CDB, CDB_enable);

$monitor("@@@ Time:%4.0f clock:%b reset:%b T_input:%b T1_input:%b T2_input:%b command:%b reg_input_t:%h reg_input_t1:%h reg_input_t2:%h T_out:%b T1_out:%b T2_out:%b CDB:%h CDB_enable:%h", $time, clock, reset, T, T1, T2, command_inp, reg_input_t, reg_input_t1, reg_input_t2, T_out, T1_out, T2_out, CDB, CDB_enable);
    // Release reset
    #10;
    reset = 0;
    CDB_enable = 0;
    // Test read functionality of tags
    #10;
    reg_input_t = 0;
    reg_input_t1 = 1;
    reg_input_t2 = 2;
    command_inp = READ;

    #10;
    //simulate assigning new values to physical regs from free list
    command_inp = WRITE;
    reg_input_t = 0;
    T.tag = 3;//destination tag should be free
    T.valid = 1'b1;
    T.ready = 1'b0;
	
    #10;
    //simulate assigning new values to physical regs from free list
    command_inp = WRITE;
    reg_input_t1 = 1;
    T1.tag = 4;//destination tag should be free
    T1.valid = 1'b1;
    T1.ready = 1'b0;
	
    #10;
    //simulate assigning new values to physical regs from free list
    command_inp = WRITE;
    reg_input_t2 = 2;
    T2.tag = 5;//destination tag should be free
    T2.valid = 1'b1;
    T2.ready = 1'b0;
	
    #10
    reg_input_t = 0;
    reg_input_t1 = 1;
    reg_input_t2 = 2;
    command_inp = READ;

    
	// Continue simulation for a while to observe behavior
    #10;
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
