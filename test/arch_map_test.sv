`timescale 1ns / 1ps
`include "verilog/sys_defs.svh"
`include "verilog/ISA.svh"

module rs_tb;

	logic clock;
	logic reset;

	TAG retire_t;
	TAG retire_t_old;
	logic retire_en;
	
	logic [4:0] read_idx;
	
	TAG read_out;

	// Instantiate the RS
	arch_map dut (
	    .clock(clock),
	    .reset(reset),
	    
	    .retire_t(retire_t),
	    .retire_t_old(retire_t_old),
	    .retire_en(retire_en),
	    
	    .read_idx(read_idx),
	    .read_out(read_out)
	);
	always begin
		#(`CLOCK_PERIOD/2.0);
		clock = ~clock;
	end
	
	initial begin
		$display("@@@ Passed: SUCCESS! \n ");
		$finish;
		
		
	end

endmodule
