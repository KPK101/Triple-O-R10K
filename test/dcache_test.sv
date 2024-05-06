`timescale 1ns / 1ps
`include "verilog/sys_defs.svh"
`include "verilog/ISA.svh"

module dcache_tb;

// Define testbench signals based on the map_table module's interface
logic clock;
logic reset;
MEMOP_DCACHE_PACKET memop_dcache_packet;
logic [3:0]  Imem2proc_response, // Should be zero unless there is a response
logic [63:0] Imem2proc_data,
logic [3:0]  Imem2proc_tag,

logic [1:0]       proc2Imem_command,
logic [63:0]      proc2Imem_data,
logic [`XLEN-1:0] proc2Imem_addr,
DCACHE_MEMOP_PACKET dcache_memop_packet,

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
\tproc2Imem_cmd:%b proc2Imem_addr:%b proc2Imem_data:%b \n\
\tImem2proc_resp:%b Imem2proc_data:%b Imem2proc_tag:%b \n\
\tdcache_data_out:%b dcache_valid_out:%b \n\
",      
                  $time, clock, reset,
                  memop_dcache_packet.proc2Dcache_command, memop_dcache_packet.proc2Dcache_addr, memop_dcache_packet.proc2Dcache_data,
                  proc2Imem_command, proc2Dcache_addr, proc2Dcache_data,
                  Imem2proc_response, Imem2proc_data, Imem2proc_tag,
                  dcache_memop_packet.Dcache_data_out, dcache_memop_packet.Dcache_valid_out
                  );
       
    #10;
    
    // Test read functionality of tags
    #10;
   
    #10;

    #10;
    
	// Continue simulation for a while to observe behavior
    #10;
    $display("\nENDING TESTBENCH: SUCCESS!");
    $display("@@@ Passed\n");
    $finish; // End simulation
end

endmodule
