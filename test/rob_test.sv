`include "verilog/sys_defs.svh"
// test ROB_SZ = 4 
module rob_test;

   // TAG : valid, phys_reg, ready
   // DUT I/O
	logic clock;
	logic reset;
	logic [$clog2(`ROB_SZ):0] counter;
	logic [$clog2(`ROB_SZ)-1:0] head_idx;
	logic [$clog2(`ROB_SZ)-1:0] tail_idx;
	//logic [$clog2(`ROB_SZ):0] next_counter;
	ID_ROB_PACKET id_rob; // t_in, t_old_in, write_en 
	IC_ROB_PACKET ic_rob; // complete_idx, complete_en

	ROB_ID_PACKET rob_id; // free_idx, free
	ROB_IR_PACKET rob_ir; // retire_t, retire_t_old, retire_en

	rob rob_dut (
		.clock(clock), 
		.reset(reset),
		.counter(counter),
		.head_idx(head_idx),
		.tail_idx(tail_idx),
		//.next_counter(next_counter),
		.id_rob_packet(id_rob), 
		.ic_rob_packet(ic_rob), 
		.rob_id_packet(rob_id), 
		.rob_ir_packet(rob_ir)
	);



    // CLOCK_PERIOD is defined on the commandline by the makefile
    always begin 
        #(`CLOCK_PERIOD/2.0);
        clock = ~clock;
    end

   initial begin
        // setup monitor and reset signals
        $monitor("time: %3.0d id_rob_write_en: %b ic_rob_complete_idx: %2.0d ic_rob_complete_en: %b rob_id_free_idx: %2.0d rob_id_free: %b rob_ir_retire_en: %b counter: %d head_idx: %d tail_idx: %d\n",
                 $time, id_rob.write_en, ic_rob.complete_idx, ic_rob.complete_en, rob_id.free_idx, rob_id.free, rob_ir.retire_en, counter, head_idx, tail_idx);

        clock = 1'b0;
	@(posedge clock)
        reset = 1'b1;
	@(posedge clock)
	reset = 1'b0;
	@(posedge clock)
	/*first index*/
	// id_rob 
	id_rob.write_en = 1'b1;
	ic_rob.complete_idx = 2'b00;  
	ic_rob.complete_en = 1'b0;

	/*second index*/
	@(posedge clock)
	id_rob.write_en = 1'b1;
	ic_rob.complete_en = 1'b0;
	

	/*third index*/
	@(posedge clock)
	id_rob.write_en = 1'b1;
	ic_rob.complete_en = 1'b0;

	/*fourth index*/
	@(posedge clock)
	id_rob.write_en = 1'b1;
	ic_rob.complete_en = 1'b0; // full now 

	/*fifth index*/
	@(posedge clock)
	id_rob.write_en = 1'b0;
	ic_rob.complete_en = 1'b0;

	/*sixth index*/
	@(posedge clock)
	id_rob.write_en = 1'b0;
	// ic_rob --> first index is complete
	ic_rob.complete_idx = 2'b00; 
	ic_rob.complete_en = 1'b1;
	@(posedge clock)
	id_rob.write_en = 1'b0;
	ic_rob.complete_en = 1'b0;

	@(posedge clock)
	id_rob.write_en = 1'b1;
	ic_rob.complete_idx = 2'b01;
	ic_rob.complete_en = 1'b1; // write & retire happens at the same time 
	
	@(posedge clock)
	id_rob.write_en = 1'b1;
	ic_rob.complete_idx = 2'b01;
	ic_rob.complete_en = 1'b0;

	@(posedge clock)
	ic_rob.complete_idx = 2'b01; 
	ic_rob.complete_en = 1'b0;
	
	id_rob.write_en = 1'b0;

	@(posedge clock)
	ic_rob.complete_en = 1'b1;
	id_rob.write_en = 1'b1;
	    #60;
    $display("\nENDING TESTBENCH: SUCCESS!");
    $display("@@@ Passed\n");
    $finish; // End simulation
   end
endmodule
			
	
	
