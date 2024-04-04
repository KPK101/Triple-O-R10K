`timescale 1ns / 1ps
`include "verilog/sys_defs.svh"
`include "verilog/ISA.svh"

module rs_tb;

	logic clock;
	logic reset;

	//Two index for just reading
	logic [4:0] read_idx_1;
	logic [4:0] read_idx_2;
	
	//index and value for new tag from free_list
	logic [4:0] write_idx;
	TAG write_tag;
	logic write_en;
	
	//cdb for ready bit generator
	TAG cdb;
	
	//read outputs
	TAG read_out_1;
	TAG read_out_2;
	
	//return the value in write_idx (before it is written)
	TAG write_out;
	
	map_table dut (
	    .clock(clock),
	    .reset(reset),
	    
	    .read_idx_1(read_idx_1),
	    .read_idx_2(read_idx_2),
	    
	    .write_idx(write_idx),
	    .write_tag(write_tag),
	    .write_en(write_en),
	    
	    .cdb(cdb),
	    
	    .read_out_1(read_out_1),
	    .read_out_2(read_out_2)
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
