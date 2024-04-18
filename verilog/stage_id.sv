/////////////////////////////////////////////////////////////////////////
//                                                                     //
//   Modulename :  stage_id.sv                                         //
//                                                                     //
//  Description :  instruction decode (ID) stage of the pipeline;      //
//                 decode the instruction fetch register operands, and //
//                 compute immediate operand (if applicable)           //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

`include "verilog/sys_defs.svh"
`include "verilog/ISA.svh"

// Decode an instruction: generate useful datapath control signals by matching the RISC-V ISA
// This module is purely combinational
module decoder (
    input INST  inst,
    input logic valid, // when low, ignore inst. Output will look like a NOP

    output ALU_OPA_SELECT opa_select,
    output ALU_OPB_SELECT opb_select,
    output logic          has_dest, // if there is a destination register
    output ALU_FUNC       alu_func,
    output logic          rd_mem, wr_mem, cond_branch, uncond_branch,
    output logic          csr_op, // used for CSR operations, we only use this as a cheap way to get the return code out
    output logic          halt,   // non-zero on a halt
    output logic          illegal // non-zero on an illegal instruction
);

    // Note: I recommend using an IDE's code folding feature on this block
    always_comb begin
        // Default control values (looks like a NOP)
        // See sys_defs.svh for the constants used here
        opa_select    = OPA_IS_RS1;
        opb_select    = OPB_IS_RS2;
        alu_func      = ALU_ADD;
        has_dest      = `FALSE;
        csr_op        = `FALSE;
        rd_mem        = `FALSE;
        wr_mem        = `FALSE;
        cond_branch   = `FALSE;
        uncond_branch = `FALSE;
        halt          = `FALSE;
        illegal       = `FALSE;

        if (valid) begin
            casez (inst)
                `RV32_LUI: begin
                    has_dest   = `TRUE;
                    opa_select = OPA_IS_ZERO;
                    opb_select = OPB_IS_U_IMM;
                end
                `RV32_AUIPC: begin
                    has_dest   = `TRUE;
                    opa_select = OPA_IS_PC;
                    opb_select = OPB_IS_U_IMM;
                end
                `RV32_JAL: begin
                    has_dest      = `TRUE;
                    opa_select    = OPA_IS_PC;
                    opb_select    = OPB_IS_J_IMM;
                    uncond_branch = `TRUE;
                end
                `RV32_JALR: begin
                    has_dest      = `TRUE;
                    opa_select    = OPA_IS_RS1;
                    opb_select    = OPB_IS_I_IMM;
                    uncond_branch = `TRUE;
                end
                `RV32_BEQ, `RV32_BNE, `RV32_BLT, `RV32_BGE,
                `RV32_BLTU, `RV32_BGEU: begin
                    opa_select  = OPA_IS_PC;
                    opb_select  = OPB_IS_B_IMM;
                    cond_branch = `TRUE;
                end
                `RV32_LB, `RV32_LH, `RV32_LW,
                `RV32_LBU, `RV32_LHU: begin
                    has_dest   = `TRUE;
                    opb_select = OPB_IS_I_IMM;
                    rd_mem     = `TRUE;
                end
                `RV32_SB, `RV32_SH, `RV32_SW: begin
                    opb_select = OPB_IS_S_IMM;
                    wr_mem     = `TRUE;
                end
                `RV32_ADDI: begin
                    has_dest   = `TRUE;
                    opb_select = OPB_IS_I_IMM;
                end
                `RV32_SLTI: begin
                    has_dest   = `TRUE;
                    opb_select = OPB_IS_I_IMM;
                    alu_func   = ALU_SLT;
                end
                `RV32_SLTIU: begin
                    has_dest   = `TRUE;
                    opb_select = OPB_IS_I_IMM;
                    alu_func   = ALU_SLTU;
                end
                `RV32_ANDI: begin
                    has_dest   = `TRUE;
                    opb_select = OPB_IS_I_IMM;
                    alu_func   = ALU_AND;
                endhas_dest_reg
                `RV32_ORI: begin
                    has_dest   = `TRUE;
                    opb_select = OPB_IS_I_IMM;
                    alu_func   = ALU_OR;
                end
                `RV32_XORI: begin
                    has_dest   = `TRUE;
                    opb_select = OPB_IS_I_IMM;
                    alu_func   = ALU_XOR;
                end
                `RV32_SLLI: begin
                    has_dest   = `TRUE;
                    opb_select = OPB_IS_I_IMM;
                    alu_func   = ALU_SLL;
                end
                `RV32_SRLI: begin
                    has_dest   = `TRUE;has_dest_reg
                    opb_select = OPB_IS_I_IMM;
                    alu_func   = ALU_SRL;
                end
                `RV32_SRAI: begin
                    has_dest   = `TRUE;
                    opb_select = OPB_IS_I_IMM;
                    alu_func   = ALU_SRA;
                end
                `RV32_ADD: begin
                    has_dest   = `TRUE;
                end
                `RV32_SUB: begin
                    has_dest   = `TRUE;
                    alu_func   = ALU_SUB;
                end
                `RV32_SLT: begin
                    has_dest   = `TRUE;
                    alu_func   = ALU_SLT;
                end
                `RV32_SLTU: begin
                    has_dest   = `TRUE;
                    alu_func   = ALU_SLTU;
                end
                `RV32_AND: begin
                    has_dest   = `TRUE;
                    alu_func   = ALU_AND;
                end
                `RV32_OR: begin
                    has_dest   = `TRUE;
                    alu_func   = ALU_OR;
                end
                `RV32_XOR: begin
                    has_dest   = `TRUE;
                    alu_func   = ALU_XOR;
                end
                `RV32_SLL: begin
                    has_dest   = `TRUE;
                    alu_func   = ALU_SLL;
                end
                `RV32_SRL: begin
                    has_dest   = `TRUE;
                    alu_func   = ALU_SRL;
                end
                `RV32_SRA: begin
                    has_dest   = `TRUE;
                    alu_func   = ALU_SRA;
                end
                `RV32_MUL: begin
                    has_dest   = `TRUE;
                    alu_func   = ALU_MUL;
                end
                `RV32_MULH: begin
                    has_dest   = `TRUE;
                    alu_func   = ALU_MULH;
                end
                `RV32_MULHSU: begin
                    has_dest   = `TRUE;
                    alu_func   = ALU_MULHSU;
                end
                `RV32_MULHU: begin
                    has_dest   = `TRUE;
                    alu_func   = ALU_MULHU;
                end
                `RV32_CSRRW, `RV32_CSRRS, `RV32_CSRRC: begin
                    csr_op = `TRUE;
                end
                `WFI: begin
                    halt = `TRUE;
                endhas_dest_reg
                default: begin
                    illegal = `TRUE;
                end
        endcase // casez (inst)
        end // if (valid)
    end // always

endmodule // decoder


module stage_id (
    input              clock,           // system clock
    input              reset,           // system reset
    input IF_ID_PACKET if_id_reg,
    input MT_ID_PACKET mt_id_packet,
    input RS_ID_PACKET rs_id_packet,
    input ROB_ID_PACKET rob_id_packet,
    input FL_ID_PACKET fl_id_packet,
    
    output ID_MT_PACKET id_mt_packet,
    output ID_RS_PACKET id_rs_packet,
    output ID_ROB_PACKET id_rob_packet,
    output ID_FL_PACKET id_fl_packet,
);
    //availability and consumption logic
    logic free;
    assign free = rs_id_packet.free && rob_id_packet.free && fl_id_packet.free;
    
    assign id_rs_packet.write_en = free;
    assign id_rob_packet.write_en = free;
    assign id_fl_packet.pop_en = free;

    //Create decoder_packet for rs
    logic has_dest_reg;
    DECODER_PACKET decoder_packet;
    
    //Decoder Passthrough
    assign decoder_packet.inst = if_id_reg.inst;
    assign decoder_packet.PC = if_id_reg.PC;
    assign decoder_packet.NPC = if_id_reg.NPC;
    assign decoder_packet.valid = if_id_reg.valid & ~decoder_packet.illegal;
    decoder decoder_0 (
        // Inputs
        .inst  (if_id_reg.inst),
        .valid (if_id_reg.valid),

        // Outputs
        .opa_select    (decoder_packet.opa_select),
        .opb_select    (decoder_packet.opb_select),
        .alu_func      (decoder_packet.alu_func),
        .has_dest      (has_dest_reg),
        .rd_mem        (decoder_packet.rd_mem),
        .wr_mem        (decoder_packet.wr_mem),
        .cond_branch   (decoder_packet.cond_branch),
        .uncond_branch (decoder_packet.uncond_branch),
        .csr_op        (decoder_packet.csr_op),
        .halt          (decoder_packet.halt),
        .illegal       (decoder_packet.illegal)
    );
    
    //Assign Map Table Output
    logic need_rs1;
    logic need_rs2;
    assign need_rs1 = (decoder_packet.opa_select == OPA_IS_RS1) || (decoder_packet.cond_branch);
    
    assign need_rs2 = (decoder_packet.opb_select == OPB_IS_RS2      || 
                       decoder_packet.opb_select == OPB_IS_B_IMM    || 
                       decoder_packet.opb_select == OPB_IS_S_IMM);
    
    assign id_mt_packet.read_idx_1 = need_rs1 ? decoder_packet.inst.r.rs1 : 'ZERO_REG;
    assign id_mt_packet.read_idx_2 = need_rs2 ? decoder_packet.inst.r.rs2 : 'ZERO_REG;
    assign id_mt_packet.write_idx = has_dest_reg ? if_id_reg.inst.r.rd : `ZERO_REG;
    assign id_mt_packet.write_tag = fl_id_packet.free_tag;
    assign id_mt_packet.write_en = free && has_dest_reg;
    
    //Assign Map Table Input
    assign decoder_packet.t = fl_id_packet.free_tag;
    assign decoder_packet.t1 = mt_id_packet.read_out_1;
    assign decoder_packet.t2 = mt_id_packet.read_out_2;
    
    //Assign Reservation Station Output
    assign id_rs_packet.decoder_packet = decoder_packet;
    assign id_rs_packet.write_en = free;
    
    //Assign Reservation Station Input
    assign decoder_packet.rs_idx = rs_id_packet.free_idx;
    
    //Assign Reorder Buffer Output
    assign id_rob_packet.t_in = fl_id_packet.free_tag;
    assign id_rob_packet.t_old_in = mt_id_packet.write_out;
    assign id_rob_packet.write_en = free;
    
    //Assign Reorder buffer Input
    assign decoder_packet.rob_idx = rob_id_packet.free_idx;
    
    //Assign Free List Output
    assign id_fl_packet.pop_en = free && has_dest_reg;
    
endmodule // stage_id
