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
        .if_id_reg      (if_id_reg),
        .mt_id_packet   (mt_id_packet),
        .rs_id_packet   (rs_id_packet),
        .rob_id_packet  (rob_id_packet),
        .fl_id_packet   (fl_id_packet),

        .id_mt_packet   (id_mt_packet),
        .id_rs_packet   (id_rs_packet),
        .id_rob_packet  (id_rob_packet),
        .id_fl_packet   (id_fl_packet)
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
	
    //ISSUE 
    IS_EX_PACKET is_packet;
    stage_is stage_is_0 (
        // Inputs
        .rs_is_packet    (rs_is_packet),
        .prf_is_packet   (prf_is_packet),

        // Outputs
        .is_prf_packet   (is_prf_packet),
        .is_ex_packet   (is_packet)
    );

    //EXECUTE
    IS_EX_PACKET is_ex_reg;
    EX_IC_PACKET ex_packet, ex_ic_reg;
	stage_ex stage_ex_0 (
        // Inputs
        .is_ex_reg      (is_ex_reg),

        // Outputs
        .ex_ic_packet	(ex_packet), 
        .ex_rs_packet	(ex_rs_packet), 
        .ex_prf_packet	(ex_prf_packet)
	
    );
    
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

    always_ff @(posedge clock) begin
        if_id_reg <= if_packet;
        is_ex_reg <= is_packet;
        ex_ic_reg <= ex_packet;
    end
    
    always begin
        #(`CLOCK_PERIOD/2.0);
        clock = ~clock;
    end
    
   
// Test stimulus
    initial begin
        // Initialize inputs
        /*$monitor(
"@@@\tTime:%4.0f clock:%b reset:%b \n\
\tis_packet_dest_reg: %d is_packet_rs1: %d is_packet_rs2: %d is_packet_opb_select: %b \n\
\tex_result: %d ex_rs2_value: %d ex_rs_remove_en: %b ex_rs_remove_idx: %d\n\
\tex_prf_write: %b ex_prf_data: %d\n\
\trs_id_packet.free_idx: %d rs_id_packet.free: %d rs_is_packet.issue: %d\n\
",      
                  $time, clock, reset,
                  is_packet.dest_tag.phys_reg, is_packet.rs1_value, is_packet.rs2_value, is_packet.opb_select, ex_packet.result, ex_packet.rs2_value, ex_rs_packet.remove_en, ex_rs_packet.remove_idx, ex_prf_packet.write_en, ex_prf_packet.write_data, rs_id_packet.free_idx, rs_id_packet.free, rs_is_packet.issue_en
                  );*/
       $monitor ("\
\tpipe_packet.completed_insts: %b pipe_packet.error_status: %b \n\
\tpipe_packet.wr_idx = %d pipe_packet.wr_data = %d pipe_packet.wr_en = %b \n\
\tpipe_packet.NPC = %d",
pipe_packet.completed_insts, pipe_packet.error_status,
pipe_packet.wr_idx, pipe_packet.wr_data, pipe_packet.wr_en,
pipe_packet.NPC
        );
        
        /*$monitor (
"@@@\tTime:%4.0f clock:%b reset:%b \n\
\tic_rob_packet.complete_en: %b ic_rob_packet.complete_idx: %d\
\trob_ir_packet.retire_en: %b rob_ir_packet.retire_t.phys_reg: %d\n", 
$time, clock, reset,
ic_rob_packet.complete_en, ic_rob_packet.complete_idx,
rob_ir_packet.retire_en, rob_ir_packet.retire_t.phys_reg
        );*/
       
        /*$monitor (
"@@@\tTime:%4.0f clock:%b reset:%b \n\
\tex_prf_packet.write_tag: %b ex_prf_packet.write_en: %b ex_prf_packet.write_data: %d \n\
", 
$time, clock, reset,
ex_prf_packet.write_tag, ex_prf_packet.write_en, ex_prf_packet.write_data
        );*/
       
        $display("STARTING TESTBENCH!");

        reset = 1;
        clock = 1;
        
        // Release reset; 
        @(negedge clock);//r3 <- r1 +r2
        reset = 0;
        for(int i = 0; i < 100; i++)begin
            @(negedge clock);//r3 <- r3 + 1
            reset = 0;
            if_packet.inst = 32'b000000000001_00011_000_00011_0010011;
            if_packet.PC = 0;
            if_packet.NPC = i;
            if_packet.valid = 1;
        end
        @(negedge clock);
        $display("\nENDING TESTBENCH: SUCCESS!");
        $display("@@@ Passed\n");
        $finish; // End simulation
    end

endmodule
