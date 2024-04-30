//TODO:ADD LOGIC

module alu (
    input [`XLEN-1:0] opa,
    input [`XLEN-1:0] opb,
    ALU_FUNC          func,

    output logic [`XLEN-1:0] result
);

    logic signed [`XLEN-1:0]   signed_opa, signed_opb;

    assign signed_opa   = opa;
    assign signed_opb   = opb;

    always_comb begin
	//if(enable) begin // enable signal? 
        case (func)
            ALU_ADD:    result = opa + opb;
            ALU_SUB:    result = opa - opb;
            ALU_AND:    result = opa & opb;
            ALU_SLT:    result = signed_opa < signed_opb;
            ALU_SLTU:   result = opa < opb;
            ALU_OR:     result = opa | opb;
            ALU_XOR:    result = opa ^ opb;
            ALU_SRL:    result = opa >> opb[4:0];
            ALU_SLL:    result = opa << opb[4:0];
            ALU_SRA:    result = signed_opa >>> opb[4:0];
            default:    result = `XLEN'hfacebeec;  // here to prevent latches
        endcase
	//end
     end
endmodule


module mult (
    input [`XLEN-1:0] opa,
    input [`XLEN-1:0] opb,
    ALU_FUNC          func,

    output logic [`XLEN-1:0] result
);
    logic signed [`XLEN-1:0]   signed_opa, signed_opb;

    assign signed_opa   = opa;
    assign signed_opb   = opb;
    logic signed [2*`XLEN-1:0] signed_mul, mixed_mul;
    logic        [2*`XLEN-1:0] unsigned_mul;


    assign signed_mul   = signed_opa * signed_opb;
    assign unsigned_mul = opa * opb;
    assign mixed_mul    = signed_opa * opb;

    always_comb begin
        case (func)
            ALU_MUL:    result = signed_mul[`XLEN-1:0];
            ALU_MULH:   result = signed_mul[2*`XLEN-1:`XLEN];
            ALU_MULHSU: result = mixed_mul[2*`XLEN-1:`XLEN];
            ALU_MULHU:  result = unsigned_mul[2*`XLEN-1:`XLEN];

            default:    result = `XLEN'hfacebeec;  // here to prevent latches
        endcase
    end

endmodule

module load (
    input IS_EX_PACKET is_ex_reg,
    input [`XLEN-1:0] opa,
    input [`XLEN-1:0] opb,
    input [`XLEN-1:0] Dmem2load_data,
    input [`XLEN-1:0] Dmem2proc_data,
    
    output [1:0]       load2Dmem_command,
    output MEM_SIZE    load2Dmem_size,
    output [`XLEN-1:0] load2Dmem_addr,
    output [`XLEN-1:0] load2Dmem_data,
    output logic [`XLEN-1:0] result
);
    logic rd_unsigned;
    
    assign load2Dmem_addr = opa + opb;
    assign load2Dmem_data = 0;
    assign load2Dmem_command = (is_ex_reg.valid && is_ex_reg.rd_mem) ? BUS_LOAD : BUS_NONE;
    assign load2Dmem_size = MEM_SIZE'(is_ex_reg.inst.r.funct3[1:0]);
    assign rd_unsigned = is_ex_reg.inst.r.funct3[2];
 
    
    always_comb begin
        //result = Dmem2proc_data;
        if (rd_unsigned) begin
            // unsigned: zero-extend the data
            if (load2Dmem_size == BYTE) begin
                result[`XLEN-1:8] = 0;
            end else if (load2Dmem_size == HALF) begin
                result[`XLEN-1:16] = 0;
            end
        end else begin
            // signed: sign-extend the data
            if (load2Dmem_size[1:0] == BYTE) begin
                result[`XLEN-1:8] = {(`XLEN-8){Dmem2proc_data[7]}};
            end else if (load2Dmem_size == HALF) begin
                result[`XLEN-1:16] = {(`XLEN-16){Dmem2proc_data[15]}};
            end
        end
    end
endmodule


module conditional_branch (
    input [2:0]       func, // Specifies which condition to check
    input [`XLEN-1:0] rs1,  // Value to check against condition
    input [`XLEN-1:0] rs2,

    output logic take // True/False condition result
);

    logic signed [`XLEN-1:0] signed_rs1, signed_rs2;
    assign signed_rs1 = rs1;
    assign signed_rs2 = rs2;
    always_comb begin
        case (func)
            3'b000:  take = signed_rs1 == signed_rs2; // BEQ
            3'b001:  take = signed_rs1 != signed_rs2; // BNE
            3'b100:  take = signed_rs1 < signed_rs2;  // BLT
            3'b101:  take = signed_rs1 >= signed_rs2; // BGE
            3'b110:  take = rs1 < rs2;                // BLTU
            3'b111:  take = rs1 >= rs2;               // BGEU
            default: take = `FALSE;
        endcase
    end
endmodule // conditional_branch

module stage_ex(
    input IS_EX_PACKET is_ex_reg,
    input [`XLEN-1:0] Dmem2load_data,
    
    output EX_IC_PACKET ex_ic_packet,
    output EX_RS_PACKET ex_rs_packet,
    output EX_PRF_PACKET ex_prf_packet,
    output [1:0]       load2Dmem_command,
    output MEM_SIZE    load2Dmem_size,
    output [`XLEN-1:0] load2Dmem_addr,
    output [`XLEN-1:0] load2Dmem_data
);

    
    logic take_conditional;
    logic [`XLEN-1:0] alu_result, mult_result, load_result;
    logic is_mult;
    logic [`XLEN-1:0] opa_mux_out, opb_mux_out;
    
   /* assign is_mult = is_ex_reg.decoder_packet.alu_func == ALU_MUL ||
		     is_ex_reg.decoder_packet.alu_func == ALU_MULH ||
		     is_ex_reg.decoder_packet.alu_func == ALU_MULHSU ||
		     is_ex_reg.decoder_packet.alu_func == ALU_MULHU;*/

    assign is_mult = is_ex_reg.alu_func == ALU_MUL ||
		     is_ex_reg.alu_func == ALU_MULH ||
		     is_ex_reg.alu_func == ALU_MULHSU ||
		     is_ex_reg.alu_func == ALU_MULHU;


    // Instantiate ALU 
    alu alu_0(
        .opa(opa_mux_out),
        .opb(opb_mux_out),
        .func(is_ex_reg.alu_func),

        .result(alu_result)
    );

    // Instantiate mult
    mult mult_0(
        .opa(opa_mux_out),
        .opb(opb_mux_out),
        .func(is_ex_reg.alu_func),

        .result(mult_result)
    );

    // Instantiate load
    load load_0(
        .is_ex_reg(is_ex_reg),
        .opa(opa_mux_out),
        .opb(opb_mux_out),
        .Dmem2load_data(Dmem2load_data),

        .load2Dmem_command(load2Dmem_command),
        .load2Dmem_size(load2Dmem_size),
        .load2Dmem_addr(load2Dmem_addr),
        .load2Dmem_data(load2Dmem_data),
        .result(load_result)
    );

    // Instantiate the conditional branch module
    conditional_branch cb_0(
        .func(is_ex_reg.inst.b.funct3),
        .rs1(is_ex_reg.rs1_value),
        .rs2(is_ex_reg.rs2_value),

        .take(take_conditional)
    );

    // Pass-throughs
    assign ex_ic_packet.result = is_ex_reg.rd_mem ? load_result : 
					  is_mult ? mult_result : alu_result;
    assign ex_ic_packet.NPC    = is_ex_reg.NPC;
    assign ex_ic_packet.take_branch = is_ex_reg.uncond_branch || (is_ex_reg.cond_branch && take_conditional);
    assign ex_ic_packet.rs2_value = is_ex_reg.rs2_value;
    assign ex_ic_packet.wr_mem = is_ex_reg.wr_mem;
    assign ex_ic_packet.dest_tag = is_ex_reg.dest_tag;
    assign ex_ic_packet.halt = is_ex_reg.halt;
    assign ex_ic_packet.illegal = is_ex_reg.illegal;
    assign ex_ic_packet.csr_op = is_ex_reg.csr_op;
    assign ex_ic_packet.rob_idx = is_ex_reg.rob_idx;
    
    assign ex_rs_packet.remove_idx = is_ex_reg.rs_idx;
    assign ex_rs_packet.remove_en = is_ex_reg.valid && !is_ex_reg.illegal;
    
    assign ex_prf_packet.write_tag = is_ex_reg.dest_tag;
    assign ex_prf_packet.write_data = ex_ic_packet.result;
    assign ex_prf_packet.write_en = (is_ex_reg.valid && !is_ex_reg.illegal) && is_ex_reg.dest_tag.valid && is_ex_reg.dest_tag.phys_reg != 0;

    always_comb begin
        case (is_ex_reg.opa_select)
            OPA_IS_RS1:  opa_mux_out = is_ex_reg.rs1_value;
            OPA_IS_NPC:  opa_mux_out = is_ex_reg.NPC;
            OPA_IS_PC:   opa_mux_out = is_ex_reg.PC;
            OPA_IS_ZERO: opa_mux_out = 0;
            default:     opa_mux_out = `XLEN'hdeadface; // dead face
        endcase
        
        case (is_ex_reg.opb_select)
            OPB_IS_RS2:   opb_mux_out = is_ex_reg.rs2_value;
            OPB_IS_I_IMM: opb_mux_out = `RV32_signext_Iimm(is_ex_reg.inst);
            OPB_IS_S_IMM: opb_mux_out = `RV32_signext_Simm(is_ex_reg.inst);
            OPB_IS_B_IMM: opb_mux_out = `RV32_signext_Bimm(is_ex_reg.inst);
            OPB_IS_U_IMM: opb_mux_out = `RV32_signext_Uimm(is_ex_reg.inst);
            OPB_IS_J_IMM: opb_mux_out = `RV32_signext_Jimm(is_ex_reg.inst);
            default:      opb_mux_out = `XLEN'hfacefeed; // face feed
        endcase
    end

    

    
endmodule
