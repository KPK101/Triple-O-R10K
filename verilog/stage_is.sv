`include "verilog/sys_defs.svh"
module stage_is(
    input RS_IS_PACKET rs_is_packet,
    input PRF_IS_PACKET prf_is_packet,
    
    output IS_PRF_PACKET is_prf_packet,
    output IS_EX_PACKET is_ex_packet
);

    //is -> prf inputs
    assign is_prf_packet.read_tag_1 = rs_is_packet.decoder_packet.t1;
    assign is_prf_packet.read_tag_2 = rs_is_packet.decoder_packet.t2;

    //rs -> is -> ex
    assign is_ex_packet.inst = rs_is_packet.decoder_packet.inst;
    assign is_ex_packet.PC = rs_is_packet.decoder_packet.PC;
    assign is_ex_packet.NPC = rs_is_packet.decoder_packet.NPC;

    assign is_ex_packet.rs1_value = prf_is_packet.read_out_1;
    assign is_ex_packet.rs2_value = prf_is_packet.read_out_2;
    
    always_comb begin
        case (rs_is_packet.decoder_packet.opa_select)
            OPA_IS_RS1:  is_ex_packet.opa = prf_is_packet.read_out_1;
            OPA_IS_NPC:  is_ex_packet.opa = rs_is_packet.decoder_packet.NPC;
            OPA_IS_PC:   is_ex_packet.opa = rs_is_packet.decoder_packet.PC;
            OPA_IS_ZERO: is_ex_packet.opa = 0;
            default:     is_ex_packet.opa = `XLEN'hdeadface; // dead face
        endcase
        
        case (rs_is_packet.decoder_packet.opb_select)
            OPB_IS_RS2:   is_ex_packet.opb = prf_is_packet.read_out_2;
            OPB_IS_I_IMM: is_ex_packet.opb = `RV32_signext_Iimm(rs_is_packet.decoder_packet.inst);
            OPB_IS_S_IMM: is_ex_packet.opb = `RV32_signext_Simm(rs_is_packet.decoder_packet.inst);
            OPB_IS_B_IMM: is_ex_packet.opb = `RV32_signext_Bimm(rs_is_packet.decoder_packet.inst);
            OPB_IS_U_IMM: is_ex_packet.opb = `RV32_signext_Uimm(rs_is_packet.decoder_packet.inst);
            OPB_IS_J_IMM: is_ex_packet.opb = `RV32_signext_Jimm(rs_is_packet.decoder_packet.inst);
            default:      is_ex_packet.opb = `XLEN'hfacefeed; // face feed
        endcase
    end

    assign is_ex_packet.dest_tag = rs_is_packet.decoder_packet.t;
    assign is_ex_packet.alu_func = rs_is_packet.decoder_packet.alu_func;
    assign is_ex_packet.rd_mem = rs_is_packet.decoder_packet.rd_mem;
    assign is_ex_packet.wr_mem = rs_is_packet.decoder_packet.wr_mem;

    assign is_ex_packet.cond_branch = rs_is_packet.decoder_packet.cond_branch;
    assign is_ex_packet.uncond_branch = rs_is_packet.decoder_packet.uncond_branch;

    assign is_ex_packet.halt = rs_is_packet.decoder_packet.halt;
    assign is_ex_packet.illegal = rs_is_packet.decoder_packet.illegal;
    assign is_ex_packet.csr_op = rs_is_packet.decoder_packet.csr_op;

    assign is_ex_packet.rs_idx = rs_is_packet.decoder_packet.rs_idx;
    assign is_ex_packet.rob_idx = rs_is_packet.decoder_packet.rob_idx;

    assign is_ex_packet.valid = rs_is_packet.decoder_packet.valid && rs_is_packet.issue_en;
    assign is_ex_packet.pred_take = rs_is_packet.decoder_packet.pred_take;
endmodule
    
