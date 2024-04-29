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

    //PRF
    IS_PRF_PACKET is_prf_packet;
    IC_PRF_PACKET ic_prf_packet;
    PRF_IS_PACKET prf_is_packet;
	
    prf prf (
	.clock (clock),
	.reset(reset),
	.is_prf_packet(is_prf_packet),
	.ic_prf_packet(ic_prf_packet),
	.prf_is_packet(prf_is_packet)
	);
	
    //ISSSUE 
    IS_EX_PACKET is_packet;
    stage_is stage_is_0 (
        // Inputs
        .rs_is_packet    (rs_is_packet),
        .prf_is_packet   (prf_is_packet),

        // Outputs
        .is_prf_packet   (is_prf_packet),
        .is_ex_packet   (is_packet)
    );

    //IS_EX_PACKET is_ex_reg;
    EX_IC_PACKET ex_ic_packet;
    EX_RS_PACKET ex_rs_packet;
    EX_PRF_PACKET ex_prf_packet;

    //EXECUTE
	stage_ex stage_ex_0 (
        // Inputs
        .is_ex_reg      (is_packet),

	// Outputs
	.ex_ic_packet	(ex_ic_packet), 
	.ex_rs_packet	(ex_rs_packet), 
	.ex_prf_packet	(ex_prf_packet)
	
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
\tex_result: %d ex_rs2_value: %d ex_rs_remove: %b \n\
\tex_prf_write: %b ex_prf_data: %d\n\
",      
                  $time, clock, reset,
                  cdb, cdb_en,
                  ex_ic_packet.result, ex_ic_packet.rs2_value, ex_rs_packet.remove_en, ex_prf_packet.write_en, ex_prf_packet.write_data
                  );
       
        $display("STARTING TESTBENCH!");

        reset = 1;
        clock = 1;
        cdb_en = 0;
        cdb.valid = 0;
        cdb.phys_reg = 0;
        cdb.ready = 0;
        
        // Release reset; 
        @(negedge clock);
        reset = 0;
        if_id_reg.inst = 32'b0000000_00011_00101_000_00111_0110011;
        if_id_reg.PC = 0;
        if_id_reg.NPC = 4;
        if_id_reg.valid = 1;
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
        @(posedge clock);
        
        $display("\nENDING TESTBENCH: SUCCESS!");
        $display("@@@ Passed\n");
        $finish; // End simulation
    end

endmodule
