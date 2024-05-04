`include "verilog/sys_defs.svh"
`include "verilog/ISA.svh"

module testbench;

// Define testbench signals based on the map_table module's interface

    TAG cdb;
    logic cdb_en, clock, reset;
    IF_ID_PACKET if_id_reg, if_packet;

    //Map Table
    ID_MT_PACKET id_mt_packet;
    MT_ID_PACKET mt_id_packet;
    IR_MT_PACKET ir_mt_packet;
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
    logic is_stall;
    rs rs (
        .clock (clock),
        .reset (reset),    
        .cdb(cdb),
        .cdb_en(cdb_en),
        
        .id_rs_packet(id_rs_packet),
        .ex_rs_packet(ex_rs_packet),
        .is_stall(is_stall),

        .rs_id_packet(rs_id_packet),
        .rs_is_packet(rs_is_packet)
    );
    
    //Reorder Buffer
    ID_ROB_PACKET id_rob_packet;
    IC_ROB_PACKET ic_rob_packet;
    ROB_ID_PACKET rob_id_packet;
    ROB_IR_PACKET rob_ir_packet;
    logic ir_stall;
	
    rob rob (
	    .clock (clock),
	    .reset (reset),
	    
	    .id_rob_packet(id_rob_packet),
	    .ic_rob_packet(ic_rob_packet),
        .ir_stall(ir_stall),

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

    //PRF
    IS_PRF_PACKET is_prf_packet;
    EX_PRF_PACKET ex_prf_packet;
    IC_PRF_PACKET ic_prf_packet;
    PRF_IS_PACKET prf_is_packet;
	
    prf prf (
        .clock (clock),
        .reset(reset),

        .is_prf_packet(is_prf_packet),
        .ic_prf_packet(ex_prf_packet),

        .prf_is_packet(prf_is_packet)
	);
    logic next_if_valid;
    
    always_ff @(posedge clock) begin
        if (reset) begin
            if_id_reg.inst  <= `NOP;
            if_id_reg.valid <= `FALSE;
            if_id_reg.NPC   <= 0;
            if_id_reg.PC    <= 0;
        end else begin
            if_id_reg <= if_packet;
        end
    end

    stage_id stage_id_0 (
        .if_id_reg      (if_id_reg),
        .mt_id_packet   (mt_id_packet),
        .rs_id_packet   (rs_id_packet),
        .rob_id_packet  (rob_id_packet),
        .fl_id_packet   (fl_id_packet),

        .id_mt_packet   (id_mt_packet),
        .id_rs_packet   (id_rs_packet),
        .id_rob_packet  (id_rob_packet),
        .id_fl_packet   (id_fl_packet),
        .next_if_valid  (next_if_valid)
    );
	
    //ISSUE 
    IS_EX_PACKET is_ex_reg, is_ex_packet;
    stage_is stage_is_0 (
        // Inputs
        .rs_is_packet    (rs_is_packet),
        .prf_is_packet   (prf_is_packet),

        // Outputs
        .is_prf_packet   (is_prf_packet),
        .is_ex_packet   (is_packet)
    );

    always_ff @(posedge clock) begin
        if (reset || is_stall) begin
            is_ex_reg.inst <= `NOP;
            is_ex_reg.PC <= 0;
            is_ex_reg.NPC <= 0;
            is_ex_reg.valid <= 0;
        end else begin
            is_ex_reg <= is_packet;
        end
    end

    //EXECUTE
    EX_IC_PACKET ex_ic_reg, ex_packet;
	stage_ex stage_ex_0 (
        // Inputs
        .is_ex_reg      (is_ex_reg),

        // Outputs
        .ex_ic_packet	(ex_packet), 
        .ex_rs_packet	(ex_rs_packet), 
        .ex_prf_packet	(ex_prf_packet)
    );

    always_ff @(posedge clock) begin
        ex_ic_reg <= ex_packet;
    end
    
    //COMPLETE
    stage_ic stage_ic_0 (
        .cdb(cdb),
        .cdb_en(cdb_en),
        .ex_ic_reg(ex_ic_reg),

        .ic_rob_packet(ic_rob_packet)
    );

    //RETIRE
    IR_PIPELINE_PACKET pipe_packet;
    stage_ir stage_ir_0 (
        .rob_ir_packet(rob_ir_packet),

        .fl_packet(ir_fl_packet),
        .mt_packet(ir_mt_packet),
        .pipe_packet(pipe_packet)
    );
    
    always begin
        #(`CLOCK_PERIOD/2.0);
        clock = ~clock;
    end
    
   
// Test stimulus
    initial begin

        $monitor (
"\
@@@\tTime:%4.0f clock:%b reset:%b\n\
\tissue_en: %b issue_inst: %b\n\
",
$time, clock, reset,
rs_is_packet.issue_en, rs_is_packet.decoder_packet.inst
        );
       
        $display("STARTING TESTBENCH!");

        reset = 1;
        clock = 1;
        is_stall = 1;
        ir_stall = 0;
        
        @(negedge clock);//r3 <- r3 + 1
        reset = 0;
        if_packet.inst = 32'b000000000001_00011_000_00010_0010011;
        if_packet.PC = 0;
        if_packet.NPC = 0;
        if_packet.valid = 1;
        @(negedge clock);
        reset = 0;
        if_packet.inst = 32'b000000000001_11111_000_11111_0010011;
        if_packet.PC = 0;
        if_packet.NPC = 0;
        if_packet.valid = 0;
        @(negedge clock);
        @(negedge clock);
        @(negedge clock);
        @(negedge clock);
        @(negedge clock);
        @(negedge clock);
        @(negedge clock);
        @(negedge clock);
        @(negedge clock);
        @(negedge clock);
        @(negedge clock);
        @(negedge clock);
        @(negedge clock);
        @(negedge clock);
        @(negedge clock);
        @(negedge clock);
        @(negedge clock);
        @(negedge clock);
        @(negedge clock);
        @(negedge clock);
        $display("\nENDING TESTBENCH: SUCCESS!");
        $display("@@@ Passed\n");
        $finish; // End simulation
    end

endmodule
