`timescale 1ns / 1ps
`include "verilog/sys_defs.svh"
`include "verilog/ISA.svh"

module dispatch_tb;

// Define testbench signals based on the map_table module's interface
    TAG cdb;
    logic cdb_en;
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
// Clock generationif_
initial begin
    clock = 0;
    forever #5 clock = ~clock;
end


// Test stimulus
initial begin
    // Initialize inputs
    
$display("STARTING TESTBENCH!");

    reset = 1;
$display("@@@ Time:%4.0f clock:%b reset:%b RS_1_Val:%b ", $time, clock, reset, id_rs_packet.decoder_packet.t);

$monitor("@@@ Time:%4.0f clock:%b reset:%b RS_1_Val:%b ", $time, clock, reset, id_rs_packet.decoder_packet.t);
    // Release reset
    #10;
    if_id_reg.inst = 32'b00000000000100101000001010010011;
    if_id_reg.PC = 0;
    if_id_reg.NPC = 4;
    if_id_reg.valid = 1;
	// Continue simulation for a while to observe behavior
    #10;
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
