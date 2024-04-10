`timescale 1ns / 1ps
`include "verilog/sys_defs.svh"
`include "verilog/ISA.svh"

module map_table_tb;

// Define testbench signals based on the map_table module's interface
reg clock;
reg reset;
reg CDB_enable;
TAG T, T1, T2, CDB;
logic write_en;
reg [4:0] reg_1, reg_2, dest_reg;
TAG new_tag, T_old;

// Instantiate the map_table
map_table dut (
    .clock(clock),
    .reset(reset),
    .read_idx_1(reg_1),
    .read_idx_2(reg_2),
    .read_out_1(T1),
    .read_out_2(T2),

    .write_en(write_en),
    .write_idx(dest_reg),
    .write_tag(new_tag),
    .write_out(T_old)
);

// Clock generation
initial begin
    clock = 0;
    forever #5 clock = ~clock;
    /*assert property(@(posedge clock) 
	if(command_inp == READ)
		T1 && T1_out
	
	);*/
end


// Test stimulus
initial begin
    // Initialize inputs
    
$display("STARTING TESTBENCH!");

    reset = 1;
$display("@@@ Time:%4.0f clock:%b reset:%b T1:%b T2:%b reg_1:%b reg_2:%b write_en:%b dest_reg:%b new_tag:%b T_old:%b", $time, clock, reset, T1, T2,reg_1, reg_2, write_en, dest_reg, new_tag, T_old);

$monitor("@@@ Time:%4.0f clock:%b reset:%b T1:%b T2:%b reg_1:%b reg_2:%b write_en:%b dest_reg:%b new_tag:%b T_old:%b", $time, clock, reset, T1, T2,reg_1, reg_2, write_en, dest_reg, new_tag, T_old);
    // Release reset
    #10;
    reset = 0;
    CDB_enable = 0;
    // Test read functionality of tags
    #10;
    reg_1 = 1;
    reg_2 = 2;

    #10;
    reg_1 = 10;
    reg_2 = 12;

    #10;
    write_en = 1;
    dest_reg = 2;
    new_tag.tag = 5;
    new_tag.valid = 1;
    new_tag.valid = 0;
    
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
