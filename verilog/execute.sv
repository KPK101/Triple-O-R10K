/////////////////////////////////////////////////////////////////////////
//                                                                     //
//   Modulename :  stage_ex.sv                                         //
//                                                                     //
//  Description :  instruction execute (EX) stage of the pipeline;     //
//                 given the instruction command code CMD, select the  //
//                 proper input A and B for the ALU, compute the       //
//                 result, and compute the condition for branches, and //
//                 pass all the results down the pipeline.             //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

`include "verilog/sys_defs.svh"
`include "verilog/ISA.svh"

// ALU: computes the result of FUNC applied with operands A and B
// This module is purely combinational
module alu (
    input [`XLEN-1:0] opa,
    input [`XLEN-1:0] opb,
    input             enable,
    ALU_FUNC          func,

    output logic [`XLEN-1:0] result
);

    logic signed [`XLEN-1:0]   signed_opa, signed_opb;
    logic signed [2*`XLEN-1:0] signed_mul, mixed_mul;
    logic        [2*`XLEN-1:0] unsigned_mul;

    assign signed_opa   = opa;
    assign signed_opb   = opb;

    // We let verilog do the full 32-bit multiplication for us.
    // This gives a large clock period.
    // You will replace this with your pipelined multiplier in project 4.
    assign signed_mul   = signed_opa * signed_opb;
    assign unsigned_mul = opa * opb;
    assign mixed_mul    = signed_opa * opb;

    always_comb begin
	if(enable) begin
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
            ALU_SRA:    result = signed_opa >>> opb[4:0]; // arithmetic from logical shift
           /* ALU_MUL:    result = signed_mul[`XLEN-1:0];
            ALU_MULH:   result = signed_mul[2*`XLEN-1:`XLEN];
            ALU_MULHSU: result = mixed_mul[2*`XLEN-1:`XLEN];
            ALU_MULHU:  result = unsigned_mul[2*`XLEN-1:`XLEN];
	   */
            default:    result = `XLEN'hfacebeec;  // here to prevent latches
        endcase
	end
    end

endmodule // alu

module ld (
    input [`XLEN-1:0] opa,
    input [`XLEN-1:0] opb,
    input             enable,
    ALU_FUNC          func,

    output logic [`XLEN-1:0] result
);

    logic signed [`XLEN-1:0]   signed_opa, signed_opb;
    logic signed [2*`XLEN-1:0] signed_mul, mixed_mul;
    logic        [2*`XLEN-1:0] unsigned_mul;

    assign signed_opa   = opa;
    assign signed_opb   = opb;

    // We let verilog do the full 32-bit multiplication for us.
    // This gives a large clock period.
    // You will replace this with your pipelined multiplier in project 4.
    assign signed_mul   = signed_opa * signed_opb;
    assign unsigned_mul = opa * opb;
    assign mixed_mul    = signed_opa * opb;

    always_comb begin
	if(enable) begin
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
            ALU_SRA:    result = signed_opa >>> opb[4:0]; // arithmetic from logical shift
           /* ALU_MUL:    result = signed_mul[`XLEN-1:0];
            ALU_MULH:   result = signed_mul[2*`XLEN-1:`XLEN];
            ALU_MULHSU: result = mixed_mul[2*`XLEN-1:`XLEN];
            ALU_MULHU:  result = unsigned_mul[2*`XLEN-1:`XLEN];
	   */
            default:    result = `XLEN'hfacebeec;  // here to prevent latches
        endcase
	end
    end

endmodule // ld

module st (
    input [`XLEN-1:0] opa,
    input [`XLEN-1:0] opb,
    input             enable,
    ALU_FUNC          func,

    output logic [`XLEN-1:0] result
);

    logic signed [`XLEN-1:0]   signed_opa, signed_opb;
    logic signed [2*`XLEN-1:0] signed_mul, mixed_mul;
    logic        [2*`XLEN-1:0] unsigned_mul;

    assign signed_opa   = opa;
    assign signed_opb   = opb;

    // We let verilog do the full 32-bit multiplication for us.
    // This gives a large clock period.
    // You will replace this with your pipelined multiplier in project 4.
    assign signed_mul   = signed_opa * signed_opb;
    assign unsigned_mul = opa * opb;
    assign mixed_mul    = signed_opa * opb;

    always_comb begin
	if(enable) begin
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
            ALU_SRA:    result = signed_opa >>> opb[4:0]; // arithmetic from logical shift
           /* ALU_MUL:    result = signed_mul[`XLEN-1:0];
            ALU_MULH:   result = signed_mul[2*`XLEN-1:`XLEN];
            ALU_MULHSU: result = mixed_mul[2*`XLEN-1:`XLEN];
            ALU_MULHU:  result = unsigned_mul[2*`XLEN-1:`XLEN];
	   */
            default:    result = `XLEN'hfacebeec;  // here to prevent latches
        endcase
	end
    end

endmodule // st


module stage_ex (
    input ID_IS_PACKET id_is_reg,

    output EX_MEM_PACKET ex_packet
);

    logic [`XLEN-1:0] opa_mux_out, opb_mux_out;
    logic take_conditional;
    logic is_mult;
    assign is_mult =	is_packet_in.alu_func == ALU_MUL ||
							is_packet_in.alu_func == ALU_MULH ||
							is_packet_in.alu_func == ALU_MULHSU ||
							is_packet_in.alu_func == ALU_MULHU;
    logic is_st;
    assign is_st =	is_packet_in.wr_mem;

    logic is_ld;
    assign is_ld =	is_packet_in.rd_mem; 

    logic is_alu;
    assign is_alu =	!(is_mult || is_load || is_store);
    
    // ALU opA mux
    always_comb begin
        case (id_is_reg.opa_select)
            OPA_IS_RS1:  opa_mux_out = id_is_reg.rs1_value;
            OPA_IS_NPC:  opa_mux_out = id_is_reg.NPC;
            OPA_IS_PC:   opa_mux_out = id_is_reg.PC;
            OPA_IS_ZERO: opa_mux_out = 0;
            default:     opa_mux_out = `XLEN'hdeadface; // dead face
        endcase
    end

    // ALU opB mux
    always_comb begin
        case (id_is_reg.opb_select)
            OPB_IS_RS2:   opb_mux_out = id_is_reg.rs2_value;
            OPB_IS_I_IMM: opb_mux_out = `RV32_signext_Iimm(id_is_reg.inst);
            OPB_IS_S_IMM: opb_mux_out = `RV32_signext_Simm(id_is_reg.inst);
            OPB_IS_B_IMM: opb_mux_out = `RV32_signext_Bimm(id_is_reg.inst);
            OPB_IS_U_IMM: opb_mux_out = `RV32_signext_Uimm(id_is_reg.inst);
            OPB_IS_J_IMM: opb_mux_out = `RV32_signext_Jimm(id_is_reg.inst);
            default:      opb_mux_out = `XLEN'hfacefeed; // face feed
        endcase
    end

    // Instantiate the ALU
    alu alu_0 (
        // Inputs
        .opa(opa_mux_out),
        .opb(opb_mux_out),
        .func(id_is_reg.alu_func),
	.enable(is_alu),
        // Output
        .result(ex_packet.result)
    );

   ld ld_0 (
        // Inputs
        .opa(opa_mux_out),
        .opb(opb_mux_out),
        .func(id_is_reg.alu_func),
	.enable(is_ld),
        // Output
        .result(ex_packet.result)
    );

   st st_0 (
        // Inputs
        .opa(opa_mux_out),
        .opb(opb_mux_out),
        .func(id_is_reg.alu_func),
	.enable(is_st),
        // Output
        .result(ex_packet.result)
    );

endmodule // stage_ex
