`timescale 1ns / 1ps
`include "verilog/sys_defs.svh"
`include "verilog/ISA.svh"

module dispatch_tb;

// Define testbench signals based on the map_table module's interface
    TAG cdb;
    DECODER_PACKET tout;
    logic tlog;
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
        .rs_is_packet(rs_is_packet),
        .tout(tout),
        .tlog(tlog)
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

// Clock generationif_
initial begin
    clock = 0;
    forever #10 clock = ~clock;
end


// Test stimulus
initial begin
    // Initialize inputs
    
$display("STARTING TESTBENCH!");

    reset = 1;
$display("@@@ Time:%4.0f clock:%b reset:%b RS_T1_PREG:%d RS_T2_PREG:%d RS_T_PREG:%d FREE_LIST_POPEN:%d FREE_LIST_PREG:%d FREE_LIST_FREE:%d", $time, clock, reset, id_rs_packet.decoder_packet.t1.phys_reg, id_rs_packet.decoder_packet.t2.phys_reg, id_rs_packet.decoder_packet.t.phys_reg, id_fl_packet.pop_en, fl_id_packet.free_tag.phys_reg, fl_id_packet.free, id_rob_packet.write_en);

$monitor("@@@ Time:%4.0f clock:%b reset:%b RS_T1_PREG:%b RS_T2_PREG:%b RS_T_PREG:%d FREE_LIST_POPEN:%d FREE_LIST_PREG:%d FREE_LIST_FREE:%d ID_ROB_WRITE_EN:%d DECODER_PACKET_VALID:%d RS_IS_ISSUE_EN:%d INST:%b tout1:%b tout2:%b tlog:%b\n", $time, clock, reset, id_rs_packet.decoder_packet.t1, id_rs_packet.decoder_packet.t2, id_rs_packet.decoder_packet.t.phys_reg, id_fl_packet.pop_en, fl_id_packet.free_tag.phys_reg, fl_id_packet.free, id_rob_packet.write_en, id_rs_packet.decoder_packet.valid, rs_is_packet.issue_en, rs_is_packet.decoder_packet.inst, tout.t1, tout.t2, tlog);
    // Release reset
    #10;
    /*@(posedge clock)//add r3 <-r2+r1
    reset = 0;
    if_id_reg.inst = 32'b0000000_00010_00001_000_00011_0110011;
    if_id_reg.PC = 0;
    if_id_reg.NPC = 4;
    if_id_reg.valid = 1;*/
    @(posedge clock)//addi r6 <-r6+1
    reset = 0;
    if_id_reg.inst = 32'b000000000101_00110_000_00110_0010011;
    if_id_reg.PC = 0;
    if_id_reg.NPC = 4;
    if_id_reg.valid = 1;
     @(posedge clock)//addi r7 <-r7+1
    reset = 0;
    if_id_reg.inst = 32'b000000000101_00111_000_00111_0010011;
    if_id_reg.PC = 0;
    if_id_reg.NPC = 4;
    if_id_reg.valid = 1;
    /*@(posedge clock)//ld r7 <-r7+1
    reset = 0;
    if_id_reg.inst = 32'b00000000000000111010001100000011;
    if_id_reg.PC = 0;
    if_id_reg.NPC = 4;
    if_id_reg.valid = 1;*/
    @(posedge clock)//mult r7 <-r7+1
    reset = 0;
    if_id_reg.inst = 32'b0000001_00110_00111_000_01111_0110011;
    if_id_reg.PC = 0;
    if_id_reg.NPC = 4;
    if_id_reg.valid = 1;
    @(posedge clock)
   
   // @(posedge clock)
    cdb_en = 1;
    cdb.valid = 1;
    cdb.phys_reg = 33;
    cdb.ready = 1;
    @(posedge clock)
    cdb_en = 1;
    cdb.valid = 1;
    cdb.phys_reg = 32;
    cdb.ready = 1;
    @(posedge clock)
      
    //cdb_en = 0;
	// Continue simulation for a while to observe behavior
  //  #20;
    $display("\nENDING TESTBENCH: SUCCESS!");
    $display("@@@ Passed\n");
    $finish; // End simulation
end

// Initialize signals for waveform generation
initial begin
    $dumpfile("dispatch_tb.vcd");
    $dumpvars(0, dispatch_tb);
end

endmodule
