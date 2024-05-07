`include "verilog/sys_defs.svh"
`include "verilog/ISA.svh"
module alu (
    input IS_EX_PACKET is_ex_packet,

    output EX_IF_PACKET ex_if_packet,
    output EX_IC_PACKET ex_ic_packet,
    output EX_RS_PACKET ex_rs_packet,
    output EX_PRF_PACKET ex_prf_packet
);
    logic signed [`XLEN-1:0]   signed_opa, signed_opb;

    assign signed_opa   = is_ex_packet.opa;
    assign signed_opb   = is_ex_packet.opb;
    
    always_comb begin
        case (is_ex_packet.alu_func)
            ALU_ADD:    ex_ic_packet.result = is_ex_packet.opa + is_ex_packet.opb;
            ALU_SUB:    ex_ic_packet.result = is_ex_packet.opa - is_ex_packet.opb;
            ALU_AND:    ex_ic_packet.result = is_ex_packet.opa & is_ex_packet.opb;
            ALU_SLT:    ex_ic_packet.result = signed_opa < signed_opb;
            ALU_SLTU:   ex_ic_packet.result = is_ex_packet.opa < is_ex_packet.opb;
            ALU_OR:     ex_ic_packet.result = is_ex_packet.opa | is_ex_packet.opb;
            ALU_XOR:    ex_ic_packet.result = is_ex_packet.opa ^ is_ex_packet.opb;
            ALU_SRL:    ex_ic_packet.result = is_ex_packet.opa >> is_ex_packet.opb[4:0];
            ALU_SLL:    ex_ic_packet.result = is_ex_packet.opa << is_ex_packet.opb[4:0];
            ALU_SRA:    ex_ic_packet.result = signed_opa >>> is_ex_packet.opb[4:0];
            default:    ex_ic_packet.result = `XLEN'hfacebeec;  // here to prevent latches
        endcase
    end

    assign ex_if_packet.cond_take   = 0;
    assign ex_if_packet.bp_enable   = 0;

    assign ex_ic_packet.inst        = is_ex_packet.valid ? is_ex_packet.inst : `NOP;
    assign ex_ic_packet.NPC         = is_ex_packet.valid ? is_ex_packet.NPC : 0;

    assign ex_ic_packet.take_branch = 0;
    assign ex_ic_packet.rs2_value   = is_ex_packet.rs2_value;
    assign ex_ic_packet.wr_mem      = is_ex_packet.wr_mem;
    assign ex_ic_packet.dest_tag    = is_ex_packet.dest_tag;
    assign ex_ic_packet.halt        = is_ex_packet.halt;
    assign ex_ic_packet.illegal     = is_ex_packet.illegal;
    assign ex_ic_packet.csr_op      = is_ex_packet.csr_op;

    assign ex_ic_packet.rs_idx      = is_ex_packet.rs_idx;
    assign ex_ic_packet.rob_idx     = is_ex_packet.rob_idx;

    assign ex_ic_packet.valid       = is_ex_packet.valid;

    assign ex_rs_packet.remove_en   = ex_ic_packet.valid && !is_ex_packet.illegal;
    assign ex_rs_packet.remove_idx  = is_ex_packet.rs_idx;
    
    assign ex_prf_packet.write_tag  = is_ex_packet.dest_tag;
    assign ex_prf_packet.write_data = ex_ic_packet.result;
    assign ex_prf_packet.write_en   = ex_ic_packet.valid && !is_ex_packet.illegal && (is_ex_packet.dest_tag.phys_reg != 0);
endmodule

module mult_wrapper (
    input clock,
    input reset,
    input IS_EX_PACKET is_ex_packet,

    output EX_IF_PACKET ex_if_packet,
    output EX_IC_PACKET ex_ic_packet,
    output EX_RS_PACKET ex_rs_packet,
    output EX_PRF_PACKET ex_prf_packet
);  
    logic mult_reset, done;
    logic signed [`XLEN-1:0]   signed_opa, signed_opb;
    logic [63:0]   mult_opa, mult_opb, product;
    logic [`XLEN-1:0] upper,lower;

    assign signed_opa   = is_ex_packet.opa;
    assign signed_opb   = is_ex_packet.opb;
    assign mixed_mul    = signed_opa * is_ex_packet.opb;
    assign upper        = product[2*`XLEN-1:`XLEN];
    assign lower        = product[`XLEN-1:0];
    
    always_comb begin
        case (is_ex_packet.alu_func)
            ALU_MUL:    begin
                mult_opa = signed_opa;
                mult_opb = signed_opb;
                ex_ic_packet.result = lower;
            end
            ALU_MULH:   begin
                mult_opa = signed_opa;
                mult_opb = signed_opb;
                ex_ic_packet.result = upper;
            end
            ALU_MULHSU: begin
                mult_opa = signed_opa;
                mult_opb = is_ex_packet.opb;
                ex_ic_packet.result = upper;
            end
            ALU_MULHU:  begin
                mult_opa = is_ex_packet.opa;
                mult_opb = is_ex_packet.opb;
                ex_ic_packet.result = upper;
            end

            default:    begin
                mult_opa = signed_opa;
                mult_opb = signed_opb;
                ex_ic_packet.result = lower;
            end  // here to prevent latches
        endcase
    end

    assign mult_reset = reset || !is_ex_packet.valid;

    mult mult_0(
        .clock      (clock),
        .reset      (mult_reset),
        .mcand      (mult_opa),
        .mplier     (mult_opb),
        .start      (is_ex_packet.valid),
        .product    (product),
        .done       (done)
    );

    assign ex_if_packet.cond_take   = 0;
    assign ex_if_packet.bp_enable   = 0;

    assign ex_ic_packet.inst        = is_ex_packet.valid ? is_ex_packet.inst : `NOP;
    assign ex_ic_packet.NPC         = is_ex_packet.valid ? is_ex_packet.NPC : 0;

    assign ex_ic_packet.take_branch = 0;
    assign ex_ic_packet.rs2_value   = is_ex_packet.rs2_value;
    assign ex_ic_packet.wr_mem      = is_ex_packet.wr_mem;
    assign ex_ic_packet.dest_tag    = is_ex_packet.dest_tag;
    assign ex_ic_packet.halt        = is_ex_packet.halt;
    assign ex_ic_packet.illegal     = is_ex_packet.illegal;
    assign ex_ic_packet.csr_op      = is_ex_packet.csr_op;

    assign ex_ic_packet.rs_idx      = is_ex_packet.rs_idx;
    assign ex_ic_packet.rob_idx     = is_ex_packet.rob_idx;

    assign ex_ic_packet.valid       = is_ex_packet.valid && done;

    assign ex_rs_packet.remove_en   = ex_ic_packet.valid && !is_ex_packet.illegal;
    assign ex_rs_packet.remove_idx  = is_ex_packet.rs_idx;
    
    assign ex_prf_packet.write_tag  = is_ex_packet.dest_tag;
    assign ex_prf_packet.write_data = ex_ic_packet.result;
    assign ex_prf_packet.write_en   = ex_ic_packet.valid && !is_ex_packet.illegal && (is_ex_packet.dest_tag.phys_reg != 0);
endmodule

module mem_wrapper (
    input logic [`XLEN-1:0] Dmem2load_data,

    input IS_EX_PACKET is_ex_packet,

    output logic [1:0]       load2Dmem_command,
    output MEM_SIZE          load2Dmem_size,
    output logic [`XLEN-1:0] load2Dmem_addr,
    output logic [`XLEN-1:0] load2Dmem_data,

    output EX_IF_PACKET ex_if_packet,
    output EX_IC_PACKET ex_ic_packet,
    output EX_RS_PACKET ex_rs_packet,
    output EX_PRF_PACKET ex_prf_packet
);
    logic rd_unsigned;
    logic [`XLEN-1:0] load_result;
    
    assign load2Dmem_addr = is_ex_packet.opa + is_ex_packet.opb;
    assign load2Dmem_data = 0;
    assign load2Dmem_command = (is_ex_packet.valid && is_ex_packet.rd_mem) ? BUS_LOAD : BUS_NONE;
    assign load2Dmem_size = MEM_SIZE'(is_ex_packet.inst.r.funct3[1:0]);
    assign rd_unsigned = is_ex_packet.inst.r.funct3[2];
    always_comb begin
        load_result = Dmem2load_data;
        if (rd_unsigned) begin
            // unsigned: zero-extend the data
            if (load2Dmem_size == BYTE) begin
                load_result[`XLEN-1:8] = 0;
            end else if (load2Dmem_size == HALF) begin
                load_result[`XLEN-1:16] = 0;
            end
        end else begin
            // signed: sign-extend the data
            if (load2Dmem_size[1:0] == BYTE) begin
                load_result[`XLEN-1:8] = {(`XLEN-8){Dmem2load_data[7]}};
            end else if (load2Dmem_size == HALF) begin
                load_result[`XLEN-1:16] = {(`XLEN-16){Dmem2load_data[15]}};
            end
        end
    end

    assign ex_if_packet.cond_take   = 0;
    assign ex_if_packet.bp_enable   = 0;

    assign ex_ic_packet.result      = is_ex_packet.rd_mem ? load_result : is_ex_packet.opa + is_ex_packet.opb;
    assign ex_ic_packet.inst        = is_ex_packet.valid ? is_ex_packet.inst : `NOP;
    assign ex_ic_packet.NPC         = is_ex_packet.valid ? is_ex_packet.NPC : 0;

    assign ex_ic_packet.take_branch = 0;
    assign ex_ic_packet.rs2_value   = is_ex_packet.rs2_value;
    assign ex_ic_packet.wr_mem      = is_ex_packet.wr_mem;
    assign ex_ic_packet.dest_tag    = is_ex_packet.dest_tag;
    assign ex_ic_packet.halt        = is_ex_packet.halt;
    assign ex_ic_packet.illegal     = is_ex_packet.illegal;
    assign ex_ic_packet.csr_op      = is_ex_packet.csr_op;

    assign ex_ic_packet.rs_idx      = is_ex_packet.rs_idx;
    assign ex_ic_packet.rob_idx     = is_ex_packet.rob_idx;

    assign ex_ic_packet.valid       = is_ex_packet.valid;

    assign ex_rs_packet.remove_en   = ex_ic_packet.valid && !is_ex_packet.illegal && is_ex_packet.rd_mem;
    assign ex_rs_packet.remove_idx  = is_ex_packet.rs_idx;
    
    assign ex_prf_packet.write_tag  = is_ex_packet.dest_tag;
    assign ex_prf_packet.write_data = ex_ic_packet.result;
    assign ex_prf_packet.write_en   = ex_ic_packet.valid && !is_ex_packet.illegal && (is_ex_packet.dest_tag.phys_reg != 0);

endmodule

module branch(
    input IS_EX_PACKET is_ex_packet,

    output EX_IF_PACKET ex_if_packet,
    output EX_IC_PACKET ex_ic_packet,
    output EX_RS_PACKET ex_rs_packet,
    output EX_PRF_PACKET ex_prf_packet
);
    logic take_conditional;
    logic signed [`XLEN-1:0] signed_rs1, signed_rs2;
    assign signed_rs1 = is_ex_packet.rs1_value;
    assign signed_rs2 = is_ex_packet.rs2_value;
    always_comb begin
        case (is_ex_packet.inst.b.funct3)
            3'b000:  take_conditional = signed_rs1 == signed_rs2; // BEQ
            3'b001:  take_conditional = signed_rs1 != signed_rs2; // BNE
            3'b100:  take_conditional = signed_rs1 < signed_rs2;  // BLT
            3'b101:  take_conditional = signed_rs1 >= signed_rs2; // BGE
            3'b110:  take_conditional = is_ex_packet.rs1_value < is_ex_packet.rs2_value;                // BLTU
            3'b111:  take_conditional = is_ex_packet.rs1_value >= is_ex_packet.rs2_value;               // BGEU
            default: take_conditional = `FALSE;
        endcase
    end

    assign ex_ic_packet.valid = is_ex_packet.valid;

    assign ex_if_packet.cond_take = ex_ic_packet.valid && !is_ex_packet.illegal && take_conditional;
    assign ex_if_packet.bp_enable = ex_ic_packet.valid && !is_ex_packet.illegal && is_ex_packet.cond_branch;

    assign ex_ic_packet.inst        = is_ex_packet.valid ? is_ex_packet.inst : `NOP;
    assign ex_ic_packet.NPC         = is_ex_packet.valid ? is_ex_packet.NPC : 0;
    assign ex_ic_packet.rs2_value = is_ex_packet.rs2_value;
    assign ex_ic_packet.wr_mem = is_ex_packet.wr_mem;
    assign ex_ic_packet.dest_tag = is_ex_packet.dest_tag;
    assign ex_ic_packet.halt = is_ex_packet.halt;
    assign ex_ic_packet.illegal = is_ex_packet.illegal;
    assign ex_ic_packet.csr_op = is_ex_packet.csr_op;
    assign ex_ic_packet.rob_idx = is_ex_packet.rob_idx;
    assign ex_ic_packet.result = (is_ex_packet.cond_branch && is_ex_packet.pred_take && !take_conditional) ? is_ex_packet.NPC : is_ex_packet.opa + is_ex_packet.opb;
    assign ex_ic_packet.take_branch = is_ex_packet.uncond_branch || (is_ex_packet.cond_branch && (take_conditional ^ is_ex_packet.pred_take));
    assign ex_ic_packet.rs_idx = is_ex_packet.rs_idx;

    assign ex_rs_packet.remove_en = ex_ic_packet.valid && !is_ex_packet.illegal && !ex_ic_packet.take_branch && !is_ex_packet.wr_mem;
    assign ex_rs_packet.remove_idx = is_ex_packet.rs_idx;

    assign ex_prf_packet.write_tag = is_ex_packet.dest_tag;
    assign ex_prf_packet.write_data = (ex_ic_packet.take_branch) ? is_ex_packet.NPC : ex_ic_packet.result;
    assign ex_prf_packet.write_en = ex_ic_packet.valid && !is_ex_packet.illegal && (is_ex_packet.dest_tag.phys_reg != 0);
endmodule

module stage_ex(
    input clock,
    input reset,

    input IS_EX_PACKET [`RS_SZ - 1:0] ex_entries,

    input [`XLEN-1:0] Dmem2load_data,
    
    output EX_IF_PACKET ex_if_packet,
    output EX_IC_PACKET ex_ic_packet,
    output EX_RS_PACKET ex_rs_packet,
    output EX_PRF_PACKET ex_prf_packet,

    output [1:0]       load2Dmem_command,
    output MEM_SIZE    load2Dmem_size,
    output [`XLEN-1:0] load2Dmem_addr,
    output [`XLEN-1:0] load2Dmem_data,

    output logic [$clog2(`RS_SZ)-1:0] done_idx,
    output logic done_en
);
    EX_IF_PACKET [`RS_SZ - 1:0] ex_if_outs;
    EX_IC_PACKET [`RS_SZ - 1:0] ex_ic_outs;
    EX_RS_PACKET [`RS_SZ - 1:0] ex_rs_outs;
    EX_PRF_PACKET [`RS_SZ - 1:0] ex_prf_outs;


    alu alus [`NUM_FU_ALU-1:0] (
        .is_ex_packet(ex_entries[`RS_SZ - 1:`RS_SZ - `NUM_FU_ALU]),

        .ex_if_packet(ex_if_outs[`RS_SZ - 1:`RS_SZ - `NUM_FU_ALU]),
        .ex_ic_packet(ex_ic_outs[`RS_SZ - 1:`RS_SZ - `NUM_FU_ALU]),
        .ex_rs_packet(ex_rs_outs[`RS_SZ - 1:`RS_SZ - `NUM_FU_ALU]),
        .ex_prf_packet(ex_prf_outs[`RS_SZ - 1:`RS_SZ - `NUM_FU_ALU])
    );

    mult_wrapper mults [`NUM_FU_MULT-1:0] (
        .clock(clock),
        .reset(reset),
        .is_ex_packet(ex_entries[`NUM_FU_MULT + 1:2]),

        .ex_if_packet(ex_if_outs[`NUM_FU_MULT + 1:2]),
        .ex_ic_packet(ex_ic_outs[`NUM_FU_MULT + 1:2]),
        .ex_rs_packet(ex_rs_outs[`NUM_FU_MULT + 1:2]),
        .ex_prf_packet(ex_prf_outs[`NUM_FU_MULT + 1:2])
    );

    branch branchs (
        .is_ex_packet(ex_entries[1]),

        .ex_if_packet(ex_if_outs[1]),
        .ex_ic_packet(ex_ic_outs[1]),
        .ex_rs_packet(ex_rs_outs[1]),
        .ex_prf_packet(ex_prf_outs[1])
    );

    mem_wrapper loads (
        .is_ex_packet(ex_entries[0]),

        .ex_if_packet(ex_if_outs[0]),
        .ex_ic_packet(ex_ic_outs[0]),
        .ex_rs_packet(ex_rs_outs[0]),
        .ex_prf_packet(ex_prf_outs[0]),

        .Dmem2load_data(Dmem2load_data),

        .load2Dmem_command(load2Dmem_command),
        .load2Dmem_size(load2Dmem_size),
        .load2Dmem_addr(load2Dmem_addr),
        .load2Dmem_data(load2Dmem_data)
    );

    always_comb begin
        done_en = 0;
        done_idx = 0;
        ex_if_packet.bp_enable = 0;
        ex_ic_packet.valid = 0;
        ex_rs_packet.remove_en = 0;
        ex_prf_packet.write_en = 0;
        for(int i = `RS_SZ - 1; i >= 0; i = i - 1)begin
            if (ex_ic_outs[i].valid) begin
                ex_if_packet    = ex_if_outs[i];
                ex_ic_packet    = ex_ic_outs[i];
                ex_rs_packet    = ex_rs_outs[i];
                ex_prf_packet   = ex_prf_outs[i];
                done_en = 1;
                done_idx = i;
            end
        end
    end



    
    // logic take_conditional;
    // logic [`XLEN-1:0] alu_result, mult_result, load_result;
    // logic is_mult;
    // logic [`XLEN-1:0] opa_mux_out, opb_mux_out;

    
    
    // assign is_mult = is_ex_reg.alu_func == ALU_MUL ||
	// 	     is_ex_reg.alu_func == ALU_MULH ||
	// 	     is_ex_reg.alu_func == ALU_MULHSU ||
	// 	     is_ex_reg.alu_func == ALU_MULHU;


    // // Instantiate ALU 
    // alu alu_0(
    //     .opa(opa_mux_out),
    //     .opb(opb_mux_out),
    //     .func(is_ex_reg.alu_func),

    //     .result(alu_result)
    // );

    // // Instantiate mult
    // hardmult mult_3(
    //     .opa(opa_mux_out),
    //     .opb(opb_mux_out),
    //     .func(is_ex_reg.alu_func),

    //     .result(mult_result)
    // );

    // // Instantiate load
    // load load_0(
    //     .is_ex_reg(is_ex_reg),
    //     .opa(opa_mux_out),
    //     .opb(opb_mux_out),
    //     .Dmem2load_data(Dmem2load_data),

    //     .load2Dmem_command(load2Dmem_command),
    //     .load2Dmem_size(load2Dmem_size),
    //     .load2Dmem_addr(load2Dmem_addr),
    //     .load2Dmem_data(load2Dmem_data),
    //     .result(load_result)
    // );

    // // Instantiate the conditional branch module
    // conditional_branch cb_0(
    //     .func(is_ex_reg.inst.b.funct3),
    //     .rs1(is_ex_reg.rs1_value),
    //     .rs2(is_ex_reg.rs2_value),

    //     .take(take_conditional)
    // );

    // assign ex_ic_packet.valid = is_ex_reg.valid;

    // assign ex_if_packet.cond_take = ex_ic_packet.valid && !is_ex_reg.illegal && take_conditional;
    // assign ex_if_packet.bp_enable = ex_ic_packet.valid && !is_ex_reg.illegal && is_ex_reg.cond_branch;

    // assign ex_ic_packet.inst = is_ex_reg.inst;
    // assign ex_ic_packet.NPC    = is_ex_reg.NPC;
    // assign ex_ic_packet.rs2_value = is_ex_reg.rs2_value;
    // assign ex_ic_packet.wr_mem = is_ex_reg.wr_mem;
    // assign ex_ic_packet.dest_tag = is_ex_reg.dest_tag;
    // assign ex_ic_packet.halt = is_ex_reg.halt;
    // assign ex_ic_packet.illegal = is_ex_reg.illegal;
    // assign ex_ic_packet.csr_op = is_ex_reg.csr_op;
    // assign ex_ic_packet.rob_idx = is_ex_reg.rob_idx;
    // assign ex_ic_packet.result = (is_ex_reg.rd_mem)                                                  ? load_result   : 
	// 				             (is_mult)                                                           ? mult_result   : 
    //                              (is_ex_reg.cond_branch && is_ex_reg.pred_take && !take_conditional) ? is_ex_reg.NPC : alu_result;
    // assign ex_ic_packet.take_branch = is_ex_reg.uncond_branch || (is_ex_reg.cond_branch && (take_conditional ^ is_ex_reg.pred_take));
    // assign ex_ic_packet.rs_idx = is_ex_reg.rs_idx;

    // assign ex_rs_packet.remove_en = ex_ic_packet.valid && !is_ex_reg.illegal && !ex_ic_packet.take_branch && !is_ex_reg.wr_mem;
    // assign ex_rs_packet.remove_idx = is_ex_reg.rs_idx;

    // assign ex_prf_packet.write_tag = is_ex_reg.dest_tag;
    // assign ex_prf_packet.write_data = (ex_ic_packet.take_branch) ? is_ex_reg.NPC : ex_ic_packet.result;
    // assign ex_prf_packet.write_en = ex_ic_packet.valid && !is_ex_reg.illegal && (is_ex_reg.dest_tag.phys_reg != 0);



    

    
endmodule
