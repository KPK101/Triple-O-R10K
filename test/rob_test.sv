`timescale 1ns / 1ps
`include "verilog/sys_defs.svh"
`include "verilog/ISA.svh"
`define DEBUG 1'b1
module rob_tb;

	logic clock;
	logic reset;
	
	//ROB index to be marked as complete
	logic [$clog2(`ROB_SZ)-1:0] complete_idx;
	logic complete_en;
	
	//New entry that would be placed in the rob[next_idx]
	TAG t_in;
	TAG t_old_in;
	logic in_en;
	
	//High when rob has free space. When low, next_idx is invalid.
	logic free;
	//Next slot in the rob
	logic [$clog2(`ROB_SZ)-1:0] free_idx;
	logic head_idx_dbg;
	
	//These signals will be sent to the Arch map to replace t_old with t
	//t_old is also sent to free_list to push
	TAG retire_t;
	TAG retire_t_old;
	logic retire_en;
	
	// Instantiate the RS
	rob dut (
	    .clock(clock),
	    .reset(reset),
	    
	    .complete_idx(complete_idx),
	    .complete_en(complete_en),
	    
	    .t_in(t_in),
	    .t_old_in(t_old_in),
	    .in_en(in_en),
	    
	    
	    .free(free),
	    .free_idx(free_idx),
	   	.head_idx_dbg(head_idx_dbg),
	    
	    .retire_t(retire_t),
	    .retire_t_old(retire_t_old),
	    .retire_en(retire_en)
	);
	always begin
		#(`CLOCK_PERIOD/2.0);
		clock = ~clock;
	end
	
	initial begin
		$monitor("time: %3.0d complete_idx: %d complete_en: %b t_in_pr: %b t_old_in_pr: %b in_en: %b\n \
				  free: %3.0d free_idx: %d head_idx_dbg:%d retire_t_pr: %b retire_t_old_pr: %b retire_en: %b \n",
		          $time, complete_idx, complete_en, t_in.phys_reg, t_old_in.phys_reg, in_en,
		          free, free_idx, head_idx_dbg, retire_t.phys_reg, retire_t_old.phys_reg, retire_en);
		
		$display("@@@ Passed: SUCCESS! \n ");
		$finish;
		
	end

endmodule
