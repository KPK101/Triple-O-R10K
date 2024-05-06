`timescale 1ns / 1ps
`include "verilog/sys_defs.svh"
`include "verilog/ISA.svh"

module dcache_tb;

// Define testbench signals based on the map_table module's interface
logic clock;
logic reset;
//input
MEMOP_DCACHE_PACKET memop_dcache_packet;

logic [3:0]  Imem2proc_response; // Should be zero unless there is a response
logic [63:0] Imem2proc_data;
logic [3:0]  Imem2proc_tag;
//output
logic [1:0]       proc2Imem_command;
logic [63:0]      proc2Imem_data;
logic [`XLEN-1:0] proc2Imem_addr;

DCACHE_MEMOP_PACKET dcache_memop_packet;

// Instantiate the map_table
dcache dut (
    .clock(clock),
    .reset(reset),
    .memop_dcache_packet(memop_dcache_packet),
    .Imem2proc_data(Imem2proc_data),
    .Imem2proc_response(Imem2proc_response),
    .Imem2proc_tag(Imem2proc_tag),

    .proc2Imem_addr(proc2Imem_addr),
    .proc2Imem_command(proc2Imem_command),
    .proc2Imem_data(proc2Imem_data),
    .dcache_memop_packet(dcache_memop_packet)
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
\tdcache_cmd_in: %d dcache_addr_in:%d dcache_data_in:%d \n\
\tImem2proc_resp:%d Imem2proc_data:%d Imem2proc_tag:%d \n\
\tOUTPUT -------------------------------------------------------\n\
\tproc2Imem_cmd:%d proc2Imem_addr:%d proc2Imem_data:%d \n\
\tdcache_data_out:%d dcache_valid_out:%d \n\
",      
                  $time, clock, reset,
                  memop_dcache_packet.proc2Dcache_command, memop_dcache_packet.proc2Dcache_addr, memop_dcache_packet.proc2Dcache_data,
		Imem2proc_response, Imem2proc_data, Imem2proc_tag,
                  proc2Imem_command, proc2Imem_addr, proc2Imem_data,
                  dcache_memop_packet.Dcache_data_out, dcache_memop_packet.Dcache_valid_out
                  );
       
    #10;
    // 2'h0 : none | 2'h1 : load | 2'h2 : store
    // Test read functionality of tags
    #10;
    memop_dcache_packet.proc2Dcache_command = 2'h2;
    memop_dcache_packet.proc2Dcache_addr = 32'b1; // change
    memop_dcache_packet.proc2Dcache_data = 64'd4;
    Imem2proc_response = 4'd10;
    Imem2proc_data = 64'd88;
    Imem2proc_tag = 4'd3;

    #10;
    memop_dcache_packet.proc2Dcache_command = 2'h2;
    memop_dcache_packet.proc2Dcache_addr = 32'b1; // change
    memop_dcache_packet.proc2Dcache_data = 64'd4;
    Imem2proc_response = 4'd10;
    Imem2proc_data = 64'd88;
    Imem2proc_tag = 4'd3;
    #10;
    
	// Continue simulation for a while to observe behavior
    #10;
    $display("\nENDING TESTBENCH: SUCCESS!");
    $display("@@@ Passed\n");
    $finish; // End simulation
end

endmodule
