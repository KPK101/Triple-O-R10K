`include "verilog/sys_defs.svh"
`include "verilog/ISA.svh"

module testbench;

// Define testbench signals based on the map_table module's interface
    TAG cdb;
    logic cdb_en, clock, reset;
    IF_ID_PACKET if_id_reg;
    //Map Table
    ID_MT_PACKET id_mt_packet;
    MT_ID_PACKET mt_id_packet;
    
    map_table map_table (
        .clock (clock),
        .reset (reset),
        
        .cdb(cdb),
        .cdb_en(cdb_en),
        
        .id_mt_packet(id_mt_packet),
        .mt_id_packet(mt_id_packet)
    );
    
    //Reservation Station
    ID_RS_PACKET id_rs_packet;
    EX_RS_PACKET ex_rs_packet;
    RS_ID_PACKET rs_id_packet;
    RS_IS_PACKET rs_is_packet;
    
    rs rs (
        .clock (clock),
        .reset (reset),
        
        .cdb(cdb),
        .cdb_en(cdb_en),
        
        .id_rs_packet(id_rs_packet),
        .ex_rs_packet(ex_rs_packet),
        .rs_id_packet(rs_id_packet),
        .rs_is_packet(rs_is_packet)
    );
    
    //Reorder Buffer
    ID_ROB_PACKET id_rob_packet;
    IC_ROB_PACKET ic_rob_packet;
    ROB_ID_PACKET rob_id_packet;
	ROB_IR_PACKET rob_ir_packet;
	
	rob rob (
	    .clock (clock),
	    .reset (reset),
	    
	    .id_rob_packet(id_rob_packet),
	    .ic_rob_packet(ic_rob_packet),
	    .rob_id_packet(rob_id_packet),
	    .rob_ir_packet(rob_ir_packet)
	);
	
	//Free List
	ID_FL_PACKET id_fl_packet;
	IR_FL_PACKET ir_fl_packet;
	FL_ID_PACKET fl_id_packet;
	
	free_list free_list (
	    .clock (clock),
	    .reset (reset),
	    
	    .id_fl_packet(id_fl_packet),
	    .ir_fl_packet(ir_fl_packet),
	    .fl_id_packet(fl_id_packet)
	);

    stage_id stage_id_0 (
        // inputs
        .if_id_reg      (if_id_reg),
        .mt_id_packet   (mt_id_packet),
        .rs_id_packet   (rs_id_packet),
        .rob_id_packet  (rob_id_packet),
        .fl_id_packet   (fl_id_packet),

        // Outputs
        .id_mt_packet   (id_mt_packet),
        .id_rs_packet   (id_rs_packet),
        .id_rob_packet  (id_rob_packet),
        .id_fl_packet   (id_fl_packet)
    );

       stage_ex stage_is_0 (
        // Inputs
        .is_ex_reg      (is_ex_reg),

	// Outputs
	.ic_packet	(ic_packet),
	.rs_packet	(rs_packet),
	.prf_packet	(prf_packet)
	
    );


    always begin
        #(`CLOCK_PERIOD/2.0);
        clock = ~clock;
    end


// Test stimulus
    initial begin
        // Initialize inputs
        $monitor(
"@@@\tTime:%4.0f clock:%b reset:%b \n\
\tcdb:%b cdb_en:%b \n\
\trs_wr_en:%b rs_wr_t1:%b rs_wr_t2:%b rs_wr_idx:%b\n\
\trs_is_en:%b rs_is_t1:%b rs_is_t2:%b rs_is_idx:%b\n\
",      
                  $time, clock, reset,
                  cdb, cdb_en,
                  id_rs_packet.write_en, id_rs_packet.decoder_packet.t1, id_rs_packet.decoder_packet.t2, id_rs_packet.decoder_packet.rs_idx,
                  rs_is_packet.issue_en, rs_is_packet.decoder_packet.t1, rs_is_packet.decoder_packet.t2, rs_is_packet.decoder_packet.rs_idx
                  );
       
        $display("STARTING TESTBENCH!");

        reset = 1;
        clock = 1;
        cdb_en = 0;
        cdb.valid = 0;
        cdb.phys_reg = 0;
        cdb.ready = 0;
        
        // Release reset
        @(negedge clock);
        reset = 0;
        if_id_reg.inst = 32'b000000000101_00110_000_00110_0010011;
        if_id_reg.PC = 0;
        if_id_reg.NPC = 4;
        if_id_reg.valid = 1;
        @(negedge clock);//addi r7 <-r7+1
        reset = 0;
        if_id_reg.inst = 32'b000000000101_00111_000_00111_0010011;
        if_id_reg.PC = 0;
        if_id_reg.NPC = 4;
        if_id_reg.valid = 1;
        @(negedge clock);//mult r7 <-r7+1
        reset = 0;
        if_id_reg.inst = 32'b0000001_00110_00111_000_01111_0110011;
        if_id_reg.PC = 0;
        if_id_reg.NPC = 4;
        if_id_reg.valid = 1;
        cdb_en = 1;
        cdb.valid = 1;
        cdb.phys_reg = 33;
        cdb.ready = 1;
        @(negedge clock);
        cdb_en = 1;
        cdb.valid = 1;
        cdb.phys_reg = 32;
        cdb.ready = 1;
        @(negedge clock);
        $display("\nENDING TESTBENCH: SUCCESS!");
        $display("@@@ Passed\n");
        $finish; // End simulation
    end

endmodule
