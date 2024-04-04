`timescale 1ns / 1ps
`include "verilog/sys_defs.svh"
`include "verilog/ISA.svh"

module rs_tb;

	// Define testbench signals based on the rs module's interface
	logic clock;
	logic reset;

	ID_EX_PACKET input_pkt;
	TAG cdb;

	logic rs_busy_alu, rs_busy_fp1, rs_busy_fp2, rs_busy_ld, rs_busy_st;
	logic issue;
	ID_EX_PACKET issue_pkt;

	// Instantiate the RS
	rs dut (
	    .clock(clock),
	    .reset(reset),
	    .input_pkt(input_pkt),
	    .cdb(cdb),
	    .rs_busy_alu(rs_busy_alu),
	    .rs_busy_fp1(rs_busy_fp1),
	    .rs_busy_fp2(rs_busy_fp2),
	    .rs_busy_ld(rs_busy_ld),
	    .rs_busy_st(rs_busy_st),
	    .issue_pkt(issue_pkt),
	    .issue(issue)
	);
	always begin
		#(`CLOCK_PERIOD/2.0);
		clock = ~clock;
	end
	
	initial begin
		$monitor("time: %3.0d clk: %b input_pkt.wr_mem: %b input_pkt.rd_mem: %b input_pkt.T1: %b input_pkt.T2: %b \ncdb: %b rs_busy_alu: %b rs_busy_fp1: %b rs_busy_fp2: %b rs_busy_ld: %b rs_busy_st: %b issue: \n %b issue_pkt: %b\n",
		             $time, clock, input_pkt.wr_mem, input_pkt.rd_mem, input_pkt.T1, input_pkt.T2, cdb, rs_busy_alu, rs_busy_fp1, rs_busy_fp2, rs_busy_ld, rs_busy_st, issue, issue_pkt);
		clock		= 1'b0;
		reset		= 1'b0;
		cdb.tag		= 32'b1;
		cdb.ready	= 0;
		cdb.valid 	= 1;
		input_pkt	= 0;
		
		
        reset = 1'b1;
        @(negedge clock);
        reset = 1'b0;
        
        // ADD
        input_pkt.alu_func	= ALU_ADD;
        input_pkt.T1.tag	= 1;
        input_pkt.T2.tag	= 2;
        input_pkt.T1.ready	= 0;
        input_pkt.T2.ready	= 0;
        input_pkt.T1.valid	= 1;
        input_pkt.T2.valid	= 1;
        input_pkt.wr_mem	= 0;
        input_pkt.rd_mem	= 0;
        input_pkt.valid		= 1;
        input_pkt.illegal	= 0;
        @(negedge clock);
        // LD
        input_pkt.alu_func	= ALU_ADD;
        input_pkt.T1.tag	= 3;
        input_pkt.T2.tag	= 4;
        input_pkt.T1.ready	= 0;
        input_pkt.T2.ready	= 0;
        input_pkt.T1.valid	= 1;
        input_pkt.T2.valid	= 1;
        input_pkt.wr_mem	= 0;
        input_pkt.rd_mem	= 1;
        input_pkt.valid		= 1;
        input_pkt.illegal	= 0;
        @(negedge clock);
        // ST
        input_pkt.alu_func	= ALU_ADD;
        input_pkt.T1.tag	= 5;
        input_pkt.T2.tag	= 6;
        input_pkt.T1.ready	= 0;
        input_pkt.T2.ready	= 0;
        input_pkt.T1.valid	= 1;
        input_pkt.T2.valid	= 1;
        input_pkt.wr_mem	= 1;
        input_pkt.rd_mem	= 0;
        input_pkt.valid		= 1;
        input_pkt.illegal	= 0;
        @(negedge clock);
        // MULT
        input_pkt.alu_func	= ALU_MUL;
        input_pkt.T1.tag	= 5;
        input_pkt.T2.tag	= 6;
        input_pkt.T1.ready	= 0;
        input_pkt.T2.ready	= 0;
        input_pkt.T1.valid	= 1;
        input_pkt.T2.valid	= 1;
        input_pkt.wr_mem	= 0;
        input_pkt.rd_mem	= 0;
        input_pkt.valid		= 1;
        input_pkt.illegal	= 0;
        @(negedge clock);
        
        
        // RDY ADD
		cdb.tag		= 1;
		cdb.ready	= 1;
		cdb.valid 	= 1;
        input_pkt.alu_func	= ALU_MUL;
        input_pkt.T1.tag	= 5;
        input_pkt.T2.tag	= 6;
        input_pkt.T1.ready	= 0;
        input_pkt.T2.ready	= 0;
        input_pkt.T1.valid	= 1;
        input_pkt.T2.valid	= 1;
        input_pkt.wr_mem	= 0;
        input_pkt.rd_mem	= 0;
        input_pkt.valid		= 1;
        input_pkt.illegal	= 0;
        @(negedge clock);
        // MULT
		cdb.tag		= 2;
		cdb.ready	= 1;
		cdb.valid 	= 1;
        input_pkt.alu_func	= ALU_MUL;
        input_pkt.T1.tag	= 5;
        input_pkt.T2.tag	= 6;
        input_pkt.T1.ready	= 0;
        input_pkt.T2.ready	= 0;
        input_pkt.T1.valid	= 1;
        input_pkt.T2.valid	= 1;
        input_pkt.wr_mem	= 0;
        input_pkt.rd_mem	= 0;
        input_pkt.valid		= 1;
        input_pkt.illegal	= 0;
        @(negedge clock);
        // MULT
        input_pkt.alu_func	= ALU_MUL;
        input_pkt.T1.tag	= 5;
        input_pkt.T2.tag	= 6;
        input_pkt.T1.ready	= 0;
        input_pkt.T2.ready	= 0;
        input_pkt.T1.valid	= 1;
        input_pkt.T2.valid	= 1;
        input_pkt.wr_mem	= 0;
        input_pkt.rd_mem	= 0;
        input_pkt.valid		= 1;
        input_pkt.illegal	= 0;
        @(negedge clock);
        
        
		
		$display("@@@ Passed: SUCCESS! \n ");
		$finish;
		
		
	end

endmodule
