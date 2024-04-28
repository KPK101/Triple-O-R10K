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
	TAG cdb; // valid, phys_reg, ready

	RS_ID_PACKET rs_id; // free_idx, free
	RS_IS_PACKET rs_is; // decoder_packet, issue_en

	rs rs_dut (
		.clock(clock), 
		.reset(reset),
		.cdb(cdb),
		.cdb_en(cdb_en),
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
        $monitor("time: %3.0d reset : %b id_write_en: %b id_decoder.rd_mem: %b ex.remove_idx: %b ex.remove_en: %b rs_id.free_idx: %b rs_id.free: %b rs_is.decoder_packet %d rs_is.issue_en: %b \n",
                 $time, reset, id_rs.write_en, id_rs.decoder_packet.rd_mem, ex_rs.remove_idx, ex_rs.remove_en, rs_id.free_idx, rs_id.free, rs_is.decoder_packet, rs_is.issue_en);

        clock = 1'b0;
        reset = 1'b1;
	@(negedge clock)
	reset = 1'b0;

	/*first index*/
	id_rs.write_en = 1'b1;
	id_rs.decoder_packet.rd_mem = 1; // write decoder packet 
	ex_rs.remove_idx = 0;
	ex_rs.remove_en =0;
	
	//second index
	#10
	ex_rs.remove_idx = 0;

	/*//third index
	#10

	//fourth index
	#10

	//fifth index
	#10


	//sixth index
	#10


	#10 

	#10*/


	    #20;
    $display("\nENDING TESTBENCH: SUCCESS!");
    $display("@@@ Passed\n");
    $finish; // End simulation
   end
endmodule
			
	
	
