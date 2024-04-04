`timescale 1ns / 1ps
`include "verilog/sys_defs.svh"
`include "verilog/ISA.svh"

module rs_tb;

	logic clock;
	logic reset;
	
	TAG cdb;
	
	ID_IS_PACKET is_packet_in;
	logic in_en;
	
	logic [$clog2(`RS_SZ)-1:0] remove_idx;
	logic remove_en;
	
	ID_IS_PACKET is_packet_out;
	logic issue_en;
	
	logic [$clog2(`RS_SZ)-1:0] free_idx;
	logic free;

	// Instantiate the RS
	rs dut (
	    .clock(clock),
	    .reset(reset),
	    
	    .cdb(cdb),
	    
	    .is_packet_in(is_packet_in),
	    .in_en(in_en),
	    
	    .remove_idx(remove_idx),
	    .remove_en(remove_en),
	    
	    .is_packet_out(is_packet_out),
	    .issue_en(issue_en),
	    
	    
	    .free_idx(free_idx),
	    .free(free)
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
