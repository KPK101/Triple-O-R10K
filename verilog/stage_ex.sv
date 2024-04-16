//TODO:ADD LOGIC


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
            ALU_SRA:    result = signed_opa >>> opb[4:0];
            default:    result = `XLEN'hfacebeec;  // here to prevent latches
        endcase
	end
    end
endmodule

module stage_ex(
    input IS_EX_PACKET is_ex_reg,
    
    output EX_IC_PACKET ic_packet
);

 alu alu_0(
	
);
endmodule
