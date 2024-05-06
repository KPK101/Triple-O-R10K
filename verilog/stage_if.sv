/////////////////////////////////////////////////////////////////////////
//                                                                     //
//   Modulename :  stage_if.sv                                         //
//                                                                     //
//  Description :  instruction fetch (IF) stage of the pipeline;       //
//                 fetch instruction, compute next PC location, and    //
//                 send them down the pipeline.                        //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

`include "verilog/sys_defs.svh"

module stage_if (
    input             clock,          // system clock
    input             reset,          // system reset
    input             if_valid,       // only go to next PC when true
    input             take_branch,    // taken-branch signal
    input [`XLEN-1:0] branch_target,  // target pc: use if take_branch is TRUE
    input [63:0]      Imem2proc_data, // data coming back from Instruction memory
    input EX_IF_PACKET ex_if_packet,

    output IF_ID_PACKET      if_id_packet,
    output logic [`XLEN-1:0] proc2Imem_addr // address sent to Instruction memory
);

    logic [`XLEN-1:0] PC_reg; // PC we are currently fetching

    logic is_branch;
    logic [`XLEN-1:0] pred_target;

    assign pred_target = `RV32_signext_Bimm(if_id_packet.inst) + if_id_packet.PC;

    always_comb begin
        casez (if_id_packet.inst)
            `RV32_BEQ, `RV32_BNE, `RV32_BLT, `RV32_BGE,
            `RV32_BLTU, `RV32_BGEU: begin
                is_branch = 1;
            end
            default: begin
                is_branch = 0;
            end
        endcase
    end

    bp bp_0 (
        .clock(clock),
        .reset(reset),
        .take(ex_if_packet.cond_take),
        .enable(ex_if_packet.bp_enable),

        .pred_take(if_id_packet.pred_take)
    );



    // synopsys sync_set_reset "reset"
    always_ff @(posedge clock) begin
        if (reset) begin
            PC_reg <= 0;             // initial PC value is 0 (the memory address where our program starts)
        end else if (take_branch) begin
            PC_reg <= branch_target; // update to a taken branch (does not depend on valid bit)
        end else if (if_valid) begin
            if (if_id_packet.pred_take && is_branch) begin
                PC_reg <= pred_target;    // or transition to next PC if valid
            end else begin
                PC_reg <= PC_reg + 4;    // or transition to next PC if valid
            end
        end
    end

    // address of the instruction we're fetching (64 bit memory lines)
    // mem always gives us 8=2^3 bytes, so ignore the last 3 bits
    assign proc2Imem_addr = {PC_reg[`XLEN-1:3], 3'b0};

    // this mux is because the Imem gives us 64 bits not 32 bits
    assign if_id_packet.inst = (~if_valid) ? `NOP :
                            PC_reg[2] ? Imem2proc_data[63:32] : Imem2proc_data[31:0];

    assign if_id_packet.PC  = PC_reg;
    assign if_id_packet.NPC = PC_reg + 4; // pass PC+4 down pipeline w/instruction

    assign if_id_packet.valid = if_valid;

endmodule // stage_if
