`timescale 1ns / 1ps
`include "verilog/sys_defs.svh"
`include "verilog/ISA.svh"
`define CACHE_LINES 32
`define CACHE_LINE_BITS $clog2(`CACHE_LINES)

module icache_tb;

// Define testbench signals based on the map_table module's interface
logic clock;
logic reset;
//input
logic [`XLEN-1:0] proc2Icache_addr;

logic [3:0]  Imem2proc_response; // Should be zero unless there is a response
logic [63:0] Imem2proc_data;
logic [3:0]  Imem2proc_tag;
//output
logic [1:0]       proc2Imem_command;
logic [`XLEN-1:0] proc2Imem_addr;

logic [63:0] Icache_data_out;
logic Icache_valid_out, got_mem_data, unanswered_miss;

logic [12-`CACHE_LINE_BITS:0] current_tag;
logic [`CACHE_LINE_BITS - 1:0] current_index, last_index; 
// Instantiate the map_table
icache dut (
    .clock(clock),
    .reset(reset),
    .proc2Icache_addr(proc2Icache_addr),
    .Imem2proc_data(Imem2proc_data),
    .Imem2proc_response(Imem2proc_response),
    .Imem2proc_tag(Imem2proc_tag),

    .proc2Imem_addr(proc2Imem_addr),
    .proc2Imem_command(proc2Imem_command),
    .got_mem_data(got_mem_data),
    .unanswered_miss(unanswered_miss),
    .Icache_data_out(Icache_data_out),
    .current_index(current_index),
    .last_index(last_index),
    .Icache_valid_out(Icache_valid_out)
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
$monitor(
"@@@\tTime:%4.0f clock:%b reset:%b \n\
\tINPUT --------------------------------------------------------\n\
\proc2Icache_addr: %b  \n\
\tImem2proc_resp:%b Imem2proc_data:%d Imem2proc_tag:%b \n\
\tOUTPUT -------------------------------------------------------\n\
\tproc2Imem_cmd:%b proc2Imem_addr:%d got_mem_data:%d unanswered_miss:%d \n\
\tcurrent_idx:%b last_idx:%b \n\
\ticache_data_out:%d icache_valid_out:%b \n\
",      
                  $time, clock, reset,
                  proc2Icache_addr,
		          Imem2proc_response, Imem2proc_data, Imem2proc_tag,
                  proc2Imem_command, proc2Imem_addr, got_mem_data, unanswered_miss,
                  current_index, last_index,
                  Icache_data_out, Icache_valid_out
                  );
       
    #10
    // 2'h0 : none | 2'h1 : load | 2'h2 : store
    // Test read functionality of tags
    #10
    reset = 0;
                                            //                     |  TAG   | IDX |
    proc2Icache_addr = 32'b0000_0000_0000_0000_0000_0000_0000_1000; // change
    // memop_dcache_packet.proc2Dcache_data = 64'd4;
    #10
    Imem2proc_response = 4'b10;

    #10//30
    Imem2proc_data = 64'd88;
    Imem2proc_tag = 4'b10;


    #10
                                            //                     |  TAG   | IDX |
    proc2Icache_addr = 32'b0000_0000_0000_0000_0000_0000_0001_1000; // change
    Imem2proc_response = 4'b0;
    // memop_dcache_packet.proc2Dcache_data = 64'd4;
    #10
    Imem2proc_response = 4'b11;

    #10
    Imem2proc_data = 64'd128;
    Imem2proc_tag = 4'b11;

    #10
                                            //                     |  TAG   | IDX |
    proc2Icache_addr = 32'b0000_0000_0000_0000_0000_0000_0000_1000; // change

    // memop_dcache_packet.proc2Dcache_command = 2'h2;
    // memop_dcache_packet.proc2Dcache_addr = 32'b1; // change
    // memop_dcache_packet.proc2Dcache_data = 64'd4;
    // Imem2proc_response = 4'd10;
    // Imem2proc_data = 64'd88;
    // Imem2proc_tag = 4'd3;    
	// Continue simulation for a while to observe behavior
    #10;
    $display("\nENDING TESTBENCH: SUCCESS!");
    $display("@@@ Passed\n");
    $finish; // End simulation
end

endmodule
