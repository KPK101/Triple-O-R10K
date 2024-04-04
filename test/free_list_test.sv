`timescale 1ns / 1ps
`include "verilog/sys_defs.svh"
`include "verilog/ISA.svh"
`define DEBUG 1'b1
module fl_tb;

	// Define testbench signals based on the rs module's interface
	logic clock;
	logic reset;
	
	TAG retire_t_old;
	logic retire_en;
	
	logic pop_en;
	
	TAG free_tag;
	logic free;
	logic [`PHYS_REG_SZ-1:0] phys_reg_free_dbg;
	
	// Instantiate the RS
	free_list dut (
	    .clock(clock),
	    .reset(reset),
	    
	    .retire_t_old(retire_t_old),
	    .retire_en(retire_en),
	    
	    .pop_en(pop_en),
	    
	    .free_tag(free_tag),
	    .free(free),
	    
	    .phys_reg_free_dbg(phys_reg_free_dbg)
	);
	always begin
		#(`CLOCK_PERIOD/2.0);
		clock = ~clock;
	end
	
	initial begin
		$monitor("time: %3.0d retire_pr: %b retire_en: %b pop_en: %b free_pr: %b free: %b \n phys_reg_free_dbg: %b\n",
		             $time, retire_t_old.phys_reg, retire_en, pop_en, free_tag.phys_reg, free, phys_reg_free_dbg);
		clock =1'b0;
		@(negedge clock);
		reset =1'b1;
		@(negedge clock);
		reset =1'b0;
		pop_en = 1;
		for (int i = 0; i < 32; i++) begin
			@(negedge clock);
		end
		@(negedge clock);
		@(negedge clock);
		@(negedge clock);
		pop_en = 0;
		retire_t_old.phys_reg = 6'b100101;
		retire_en = 1;
		@(negedge clock);
		retire_t_old.phys_reg = 6'b000001;
		@(negedge clock);
		retire_t_old.phys_reg = 6'b001001;
		@(negedge clock);
		retire_t_old.phys_reg = 6'b110001;
		@(negedge clock);
		retire_t_old.phys_reg = 6'b111001;
		@(negedge clock);
		reset =1'b1;
		@(negedge clock);
		reset =1'b0;
		
		
		$display("@@@ Passed: SUCCESS! \n ");
		$finish;
		
	end

endmodule
