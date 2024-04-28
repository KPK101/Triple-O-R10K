`include "verilog/sys_defs.svh"
// test ROB_SZ = 4 
module rs_test;

   // TAG : valid, phys_reg, ready
   // DUT I/O
	logic clock;
	logic reset;
	ID_RS_PACKET id_rs; // decoder_packet, write_en
	EX_RS_PACKET ex_rs; // remove_idx, remove_en
	logic cdb_en; 
	logic interrupt;
	logic [4:0] rs_busy;
	logic is_mult;
	//TAG cdb; // valid, phys_reg, ready

	RS_ID_PACKET rs_id; // free_idx, free
	RS_IS_PACKET rs_is; // decoder_packet, issue_en

	rs rs_dut (
		.clock(clock), 
		.reset(reset),
		//.cdb(cdb),
		.interrupt(interrupt),
		.cdb_en(cdb_en),
		.rs_busy_status(rs_busy),
		.is_mult(is_mult),
		.id_rs_packet(id_rs), 
		.ex_rs_packet(ex_rs), 
		.rs_id_packet(rs_id), 
		.rs_is_packet(rs_is)
	);


    // CLOCK_PERIOD is defined on the commandline by the makefile
    always begin 
        #(`CLOCK_PERIOD/2.0);
        clock = ~clock;
    end

   initial begin
        // setup monitor and reset signals
        $monitor("time: %3.0d reset : %b id_write_en: %b rd_mem: %b wr_mem: %b ex.remove_idx: %d ex.remove_en: %b rs_id.free_idx: %d rs_id.free: %b rs_is.issue_en: %b rs_busy: %5.0b mult?: %b \n",
                 $time, reset, id_rs.write_en, id_rs.decoder_packet.rd_mem, id_rs.decoder_packet.wr_mem, ex_rs.remove_idx, ex_rs.remove_en, rs_id.free_idx, rs_id.free, rs_is.issue_en, rs_busy, is_mult);

        clock = 1'b0;
	@(posedge clock)
        reset = 1'b1;
	@(posedge clock)
	reset = 1'b0;
	@(posedge clock)

	// first 105 - read
	@(posedge clock)
	interrupt = 1'b0;
	cdb_en = 1'b0;
	id_rs.write_en = 1'b1;
	id_rs.decoder_packet.wr_mem = 0;  
	id_rs.decoder_packet.rd_mem = 1; // free_idx 1
	ex_rs.remove_idx = 0;
	ex_rs.remove_en =0;
	
	// second 135 - write 
	@(posedge clock)
	interrupt = 1'b0;
	cdb_en = 1'b0;
	id_rs.write_en = 1'b1;
	id_rs.decoder_packet.wr_mem = 1; // free_idx 2 
	//id_rs.decoder_packet.alu_func = ALU_MUL; // index 4
	ex_rs.remove_idx = 0;
	ex_rs.remove_en =0;
	
	// third 165 - read (should not be free)
	@(posedge clock)
	interrupt = 1'b0;
	cdb_en = 1'b0;
	id_rs.write_en = 1'b1;
	id_rs.decoder_packet.wr_mem = 0; // free_idx 2 
	id_rs.decoder_packet.rd_mem = 1; // free_idx 1
	ex_rs.remove_idx = 0;
	ex_rs.remove_en =0;

	// fourth 195 - alu mult 
	@(posedge clock)
	interrupt = 1'b0;
	cdb_en = 1'b0;
	id_rs.write_en = 1'b1;
	id_rs.decoder_packet.wr_mem = 0; // free_idx 2 
	id_rs.decoder_packet.rd_mem = 0; // free_idx 1
	id_rs.decoder_packet.alu_func=ALU_MUL; // index 3 
	ex_rs.remove_idx = 0;
	ex_rs.remove_en =0;

	// fifth 225 - read remove
	@(posedge clock)
	interrupt = 1'b0;
	cdb_en = 1'b0;
	id_rs.write_en = 1'b0;
	id_rs.decoder_packet.wr_mem = 0; // free_idx 2 
	id_rs.decoder_packet.rd_mem = 0; // free_idx 1
	ex_rs.remove_idx = 1;
	ex_rs.remove_en =1;
	
	// sixth 255 - non mult alu 
	@(posedge clock)
	interrupt = 1'b0;
	cdb_en = 1'b0;
	id_rs.write_en = 1'b1;
	id_rs.decoder_packet.wr_mem = 0; // free_idx 2 
	id_rs.decoder_packet.rd_mem = 0; // free_idx 1
	id_rs.decoder_packet.alu_func=ALU_ADD; // index 0 
	ex_rs.remove_idx = 0;
	ex_rs.remove_en =0;

	// seventh 285 - alu mult 
	@(posedge clock)
	interrupt = 1'b0;
	cdb_en = 1'b0;
	id_rs.write_en = 1'b1;
	id_rs.decoder_packet.wr_mem = 0; // free_idx 2 
	id_rs.decoder_packet.rd_mem = 0; // free_idx 1
	id_rs.decoder_packet.alu_func=ALU_MUL; // index 4 
	ex_rs.remove_idx = 0;
	ex_rs.remove_en =0;

	// eight 315 - cdb 
	@(posedge clock)
	interrupt = 1'b0;
	cdb_en = 1'b0;
	id_rs.write_en = 1'b1;
	id_rs.decoder_packet.wr_mem = 0; // free_idx 2 
	id_rs.decoder_packet.rd_mem = 0; // free_idx 1
	id_rs.decoder_packet.alu_func=ALU_MUL; // index 4 
	ex_rs.remove_idx = 0;
	ex_rs.remove_en =0;

	@(posedge clock)

	#60	    
    $display("\nENDING TESTBENCH: SUCCESS!");
    $display("@@@ Passed\n");
    $finish; // End simulation
   end
endmodule
			
	
	
