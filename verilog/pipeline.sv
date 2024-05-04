/////////////////////////////////////////////////////////////////////////
//                                                                     //
//   Modulename :  pipeline.sv                                         //
//                                                                     //
//  Description :  Top-level module of the verisimple pipeline;        //
//                 This instantiates and connects the 5 stages of the  //
//                 Verisimple pipeline together.                       //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

`include "verilog/sys_defs.svh"

module pipeline (
    input        clock,             // System clock
    input        reset,             // System reset
    input [3:0]  mem2proc_response, // Tag from memory about current request
    input [63:0] mem2proc_data,     // Data coming back from memory
    input [3:0]  mem2proc_tag,      // Tag from memory about current reply

    output logic [1:0]       proc2mem_command, // Command sent to memory
    output logic [`XLEN-1:0] proc2mem_addr,    // Address sent to memory
    output logic [63:0]      proc2mem_data,    // Data sent to memory
`ifndef CACHE_MODE // no longer sending size to memory
    output MEM_SIZE          proc2mem_size,    // Data size sent to memory
`endif

    // Note: these are assigned at the very bottom of the module
    output logic [3:0]       pipeline_completed_insts,
    output EXCEPTION_CODE    pipeline_error_status,
    output logic [4:0]       pipeline_commit_wr_idx,
    output logic [`XLEN-1:0] pipeline_commit_wr_data,
    output logic             pipeline_commit_wr_en,
    output logic [`XLEN-1:0] pipeline_commit_NPC,

    // Debug outputs: these signals are solely used for debugging in testbenches
    output logic [`XLEN-1:0] if_NPC_dbg,
    output logic [31:0]      if_inst_dbg,
    output logic             if_valid_dbg,

    output logic [`XLEN-1:0] id_NPC_dbg,
    output logic [31:0]      id_inst_dbg,
    output logic             id_valid_dbg,

    output logic [`XLEN-1:0] is_NPC_dbg,
    output logic [31:0]      is_inst_dbg,
    output logic             is_valid_dbg,

    output logic [`XLEN-1:0] ex_NPC_dbg,
    output logic [31:0]      ex_inst_dbg,
    output logic             ex_valid_dbg,

    output logic [`XLEN-1:0] ic_NPC_dbg,
    output logic [31:0]      ic_inst_dbg,
    output logic             ic_valid_dbg,
    
    output logic [`XLEN-1:0] ir_NPC_dbg,
    output logic [31:0]      ir_inst_dbg,
    output logic             ir_valid_dbg,

    output logic             fl_free_dbg,
    output logic             rob_free_dbg,
    output logic             rs_free_dbg,

    output TAG               id_tag1_dbg,
    output TAG               id_tag2_dbg,

    
    output [`XLEN-1:0] opa_mux_out_dbg,
    output [`XLEN-1:0] opb_mux_out_dbg,
    output ALU_FUNC alu_func_dbg,

	output logic [`PHYS_REG_SZ-1:0] phys_reg_free_dbg,
	output logic [`PHYS_REG_SZ-1:0] phys_reg_arch_free_dbg,

    output logic             ir_b_dbg,
    output logic [`XLEN-1:0] ir_baddr_dbg,


    output logic             is_ex_cond_branch,
    output logic             is_ex_uncond_branch,
    output logic [`XLEN-1:0] is_ex_rs1,
    output logic [`XLEN-1:0] is_ex_rs2,
    output logic [`XLEN-1:0] is_ex_npc,

    output logic             ex_ic_take_branch,
    output logic [`XLEN-1:0] ex_ic_branch_target,
    output logic             ex_ic_npc
);
    //////////////////////////////////////////////////
    //                                              //
    //                Pipeline Wires                //
    //                                              //
    //////////////////////////////////////////////////

    // Pipeline register enables
    logic if_id_enable, is_ex_enable, ex_ic_enable;

    // Outputs from IF-Stage and IF/ID Pipeline Register
    logic [`XLEN-1:0] proc2Imem_addr;
    IF_ID_PACKET if_id_packet, if_id_reg;

    // Outputs from IS stage
    IS_EX_PACKET is_ex_packet, is_ex_reg;

    // Outputs from EX-Stage
    EX_IC_PACKET ex_ic_packet, ex_ic_reg;

    // Outputs from IR-Stage
    IR_PIPELINE_PACKET pipe_packet;

    // Outputs from MEM-Stage to memory
    logic [`XLEN-1:0] proc2Dmem_addr;
    logic [`XLEN-1:0] proc2Dmem_data;
    logic [1:0]       proc2Dmem_command;
    MEM_SIZE          proc2Dmem_size;

    
    //////////////////////////////////////////////////
    //                                              //
    //                R10K Components               //
    //                                              //
    //////////////////////////////////////////////////
    
    //cdb
    TAG cdb;
    logic cdb_en;

    //interrupt
    logic interrupt;
    
    //Map Table
    ID_MT_PACKET id_mt_packet;
    IR_MT_PACKET ir_mt_packet;

    MT_ID_PACKET mt_id_packet;
    
    map_table map_table (
        .clock (clock),
        .reset (reset),
        
        .cdb(cdb),
        .cdb_en(cdb_en),
        .interrupt(interrupt),
        
        .id_mt_packet(id_mt_packet),
        .ir_mt_packet(ir_mt_packet),

        .mt_id_packet(mt_id_packet)
    );
    
    //Reservation Station
    logic is_stall;

    ID_RS_PACKET id_rs_packet;
    EX_RS_PACKET ex_rs_packet;

    RS_ID_PACKET rs_id_packet;
    RS_IS_PACKET rs_is_packet;
    
    rs rs (
        .clock (clock),
        .reset (reset),
        
        .cdb(cdb),
        .cdb_en(cdb_en),
        .interrupt(interrupt),
        
        .is_stall(is_stall),
        
        .id_rs_packet(id_rs_packet),
        .ex_rs_packet(ex_rs_packet),

        .rs_id_packet(rs_id_packet),
        .rs_is_packet(rs_is_packet)
    );
    
    //Reorder Buffer
    logic ir_stall;

    ID_ROB_PACKET id_rob_packet;
    IC_ROB_PACKET ic_rob_packet;

    ROB_ID_PACKET rob_id_packet;
	ROB_IR_PACKET rob_ir_packet;
	
	rob rob (
	    .clock (clock),
	    .reset (reset),

        .interrupt(interrupt),

        .ir_stall(ir_stall),
	    
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

        .interrupt(interrupt),
	    
	    .id_fl_packet(id_fl_packet),
	    .ir_fl_packet(ir_fl_packet),
	    .fl_id_packet(fl_id_packet),
        .phys_reg_free_dbg(phys_reg_free_dbg),
        .phys_reg_arch_free_dbg(phys_reg_arch_free_dbg)
	);
	
	//PRF
	IS_PRF_PACKET is_prf_packet;
	EX_PRF_PACKET ex_prf_packet;
    IR_PRF_PACKET ir_prf_packet;

	PRF_IS_PACKET prf_is_packet;
    PRF_IR_PACKET prf_ir_packet;
	
	prf prf (
	    .clock (clock),
        .reset (reset),

	    .is_prf_packet(is_prf_packet),
	    .ex_prf_packet(ex_prf_packet),
        .ir_prf_packet(ir_prf_packet),

	    .prf_is_packet(prf_is_packet),
        .prf_ir_packet(prf_ir_packet)
	);

    //////////////////////////////////////////////////
    //                                              //
    //                  IF-Stage                    //
    //                                              //
    //////////////////////////////////////////////////

    logic [`XLEN-1:0] branch_target;
    logic id_stall;
    logic next_if_valid;

    stage_if stage_if_0 (
        // Inputs
        .clock (clock),
        .reset (reset),
        .if_valid       (next_if_valid),
        .take_branch    (interrupt),
        .branch_target  (branch_target),
        .Imem2proc_data (mem2proc_data),

        // Outputs
        .if_id_packet   (if_id_packet),
        .proc2Imem_addr (proc2Imem_addr)
    );

    //////////////////////////////////////////////////
    //                                              //
    //            IF/ID Pipeline Register           //
    //                                              //
    //////////////////////////////////////////////////

    always_ff @(posedge clock) begin
        if (reset || interrupt) begin
            if_id_reg.inst  <= `NOP;
            if_id_reg.valid <= `FALSE;
            if_id_reg.NPC   <= 0;
            if_id_reg.PC    <= 0;
        end else if (id_stall) begin
            if_id_reg <= if_id_packet;
        end
    end
    
    //////////////////////////////////////////////////
    //                                              //
    //                  ID-Stage                    //
    //                                              //
    //////////////////////////////////////////////////

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
        .id_fl_packet   (id_fl_packet),
        .id_stall       (id_stall)
    );

    //////////////////////////////////////////////////
    //                                              //
    //              RS/IS Controller                //
    //                                              //
    //////////////////////////////////////////////////

    
    //////////////////////////////////////////////////
    //                                              //
    //                  IS-Stage                    //
    //                                              //
    //////////////////////////////////////////////////

    stage_is stage_is_0 (
        // Inputs
        .rs_is_packet   (rs_is_packet),
        .prf_is_packet  (prf_is_packet),

        // Outputs
        .is_prf_packet  (is_prf_packet),
        .is_ex_packet   (is_ex_packet)
    );

    
    //////////////////////////////////////////////////
    //                                              //
    //            IS/EX Pipeline Register           //
    //                                              //
    //////////////////////////////////////////////////

    always_ff @(posedge clock) begin
        if (reset || interrupt) begin
            is_ex_reg.inst <= `NOP;
            is_ex_reg.valid <= 0;
            is_ex_reg.NPC <= 0;
        end if (!is_stall) begin
            is_ex_reg <= is_ex_packet;
        end
    end

    //////////////////////////////////////////////////
    //                                              //
    //                  EX-Stage                    //
    //                                              //
    //////////////////////////////////////////////////

    logic [1:0]       load2Dmem_command;
    MEM_SIZE          load2Dmem_size;
    logic [`XLEN-1:0] load2Dmem_addr;
    logic [`XLEN-1:0] load2Dmem_data;

    stage_ex stage_ex_0 (
        .is_ex_reg      (is_ex_reg),

        .ex_ic_packet	(ex_ic_packet),
        .ex_rs_packet	(ex_rs_packet),
        .ex_prf_packet	(ex_prf_packet),

        .Dmem2load_data (mem2proc_data[`XLEN-1:0]),

        .load2Dmem_command  (load2Dmem_command),
        .load2Dmem_size     (load2Dmem_size),
        .load2Dmem_addr     (load2Dmem_addr),
        .load2Dmem_data     (load2Dmem_data),
        .opa_mux_out_dbg    (opa_mux_out_dbg),
        .opb_mux_out_dbg    (opb_mux_out_dbg),
        .alu_func_dbg       (alu_func_dbg)
    );

    //////////////////////////////////////////////////
    //                                              //
    //            EX/IC Pipeline Register           //
    //                                              //
    //////////////////////////////////////////////////

    always_ff @(posedge clock) begin
        if (reset || is_stall || interrupt) begin
            ex_ic_reg.inst <= `NOP;
            ex_ic_reg.valid <= 0;
            ex_ic_reg.NPC <= 0;
        end else begin
            ex_ic_reg <= ex_ic_packet;
        end
    end
    
    //////////////////////////////////////////////////
    //                                              //
    //                  IC-Stage                    //
    //                                              //
    //////////////////////////////////////////////////

    stage_ic stage_ic_0 (
        .ex_ic_reg      (ex_ic_reg),

        .cdb            (cdb),
        .cdb_en         (cdb_en),
        
        .ic_rob_packet  (ic_rob_packet)
    );

    //////////////////////////////////////////////////
    //                                              //
    //              ROB/IR Controller               //
    //                                              //
    //////////////////////////////////////////////////

    assign ir_stall = 0;
    
    //////////////////////////////////////////////////
    //                                              //
    //                   IR-Stage                   //
    //                                              //
    //////////////////////////////////////////////////
    logic [1:0]       store2Dmem_command;
    MEM_SIZE          store2Dmem_size;
    logic [`XLEN-1:0] store2Dmem_addr;
    logic [`XLEN-1:0] store2Dmem_data;

    stage_ir stage_ir_0 (
        .rob_ir_packet      (rob_ir_packet),

        .ir_fl_packet   (ir_fl_packet),
        .ir_mt_packet   (ir_mt_packet),
        .ir_prf_packet  (ir_prf_packet),

        .prf_ir_packet  (prf_ir_packet),
        .pipe_packet    (pipe_packet),

        .interrupt      (interrupt),
        .branch_target  (branch_target),

        .store2Dmem_command  (store2Dmem_command),
        .store2Dmem_size     (store2Dmem_size),
        .store2Dmem_addr     (store2Dmem_addr),
        .store2Dmem_data     (store2Dmem_data)
    );
    
    //////////////////////////////////////////////////
    //                                              //
    //                Memory Outputs                //
    //                                              //
    //////////////////////////////////////////////////

    // these signals go to and from the processor and memory
    // we give precedence to the mem stage over instruction fetch
    // note that there is no latency in project 3
    // but there will be a 100ns latency in project 4

    //     always_comb begin
    //         if (proc2Dmem_command != BUS_NONE) begin // read or write DATA from memory
    //             proc2mem_command = proc2Dmem_command;
    //             proc2mem_addr    = proc2Dmem_addr;
    // `ifndef CACHE_MODE
    //             proc2mem_size    = proc2Dmem_size;  // size is never DOUBLE in project 3
    // `endif
    //         end else begin                          // read an INSTRUCTION from memory
    //             proc2mem_command = BUS_LOAD;
    //             proc2mem_addr    = proc2Imem_addr;
    // `ifndef CACHE_MODE
    //             proc2mem_size    = DOUBLE;          // instructions load a full memory line (64 bits)
    // `endif
    //         end
    //         proc2mem_data = {32'b0, proc2Dmem_data};
    //     end
    
    always_comb begin
        next_if_valid = id_stall;
        is_stall = 0;
        if (store2Dmem_command != BUS_NONE) begin
            proc2mem_command    = store2Dmem_command;
            proc2mem_addr       = store2Dmem_addr;
            proc2mem_size       = store2Dmem_size;
            proc2mem_data       = {32'b0, store2Dmem_data};

            if (load2Dmem_command != BUS_NONE) begin
                is_stall        = 1;
            end

            next_if_valid       = 0;
        end else if (load2Dmem_command != BUS_NONE) begin
            proc2mem_command    = load2Dmem_command;
            proc2mem_addr       = load2Dmem_addr;
            proc2mem_size       = load2Dmem_size;
            proc2mem_data       = {32'b0, load2Dmem_data};

            next_if_valid       = 0;
        end else begin
            proc2mem_command = BUS_LOAD;
            proc2mem_addr    = proc2Imem_addr;
            proc2mem_size    = DOUBLE;
        end
        
    end

    //////////////////////////////////////////////////
    //                                              //
    //               Pipeline Outputs               //
    //                                              //
    //////////////////////////////////////////////////

    assign pipeline_completed_insts = pipe_packet.completed_insts;
    assign pipeline_error_status = pipe_packet.error_status;

    assign pipeline_commit_wr_en   = pipe_packet.wr_en;
    assign pipeline_commit_wr_idx  = pipe_packet.wr_idx;
    assign pipeline_commit_wr_data = pipe_packet.wr_data;
    assign pipeline_commit_NPC     = pipe_packet.NPC;

    assign if_NPC_dbg   = if_id_packet.NPC;
    assign if_inst_dbg  = if_id_packet.inst;
    assign if_valid_dbg = if_id_packet.valid;

    assign id_NPC_dbg   = if_id_reg.NPC;
    assign id_inst_dbg  = if_id_reg.inst;
    assign id_valid_dbg = if_id_reg.valid;

    assign is_NPC_dbg   = rs_is_packet.decoder_packet.NPC;
    assign is_inst_dbg  = rs_is_packet.decoder_packet.inst;
    assign is_valid_dbg = rs_is_packet.issue_en;

    assign ex_NPC_dbg   = is_ex_reg.NPC;
    assign ex_inst_dbg  = is_ex_reg.inst;
    assign ex_valid_dbg = is_ex_reg.valid;

    assign ic_NPC_dbg   = ex_ic_reg.NPC;
    assign ic_inst_dbg  = ex_ic_reg.inst;
    assign ic_valid_dbg = ex_ic_reg.valid;

    assign ir_NPC_dbg   = rob_ir_packet.NPC;
    assign ir_inst_dbg  = rob_ir_packet.inst;
    assign ir_valid_dbg = rob_ir_packet.retire_en;

    assign ir_b_dbg     = interrupt;
    assign ir_baddr_dbg = branch_target;

    
    assign is_ex_cond_branch    =is_ex_packet.cond_branch;
    assign is_ex_uncond_branch  =is_ex_packet.uncond_branch;
    assign is_ex_rs1            =rs_is_packet.decoder_packet.t1;
    assign is_ex_rs2            =rs_is_packet.decoder_packet.t2;
    assign is_ex_npc            =is_ex_packet.NPC;

    assign ex_ic_take_branch    = ex_ic_packet.take_branch;
    assign ex_ic_branch_target  = ex_ic_packet.result;
    assign ex_ic_npc            = ex_ic_packet.NPC;

    assign fl_free_dbg          = fl_id_packet.free;
    assign rs_free_dbg          = rs_id_packet.free;
    assign rob_free_dbg         = rob_id_packet.free;

    assign id_tag1_dbg          = fl_id_packet.free_tag;
    assign id_tag2_dbg          = mt_id_packet.read_out_2;

endmodule // pipeline
