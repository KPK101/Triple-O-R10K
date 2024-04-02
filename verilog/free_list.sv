`include "verilog/sys_defs.svh"
`include "verilog/ISA.svh"


module free_list #(parameter STACK_SIZE = `PHYS_REG_SZ)(
    input logic clk,
    input logic reset,
    input `TAG tag_in,
    input logic push,
    input logic pop,
    output `TAG  tag_out,
    output logic empty,
    output logic full   
);

   
    `TAG stack [STACK_SIZE - 1:0];
    // `TAG NULL_TAG;
    logic [$clog2(STACK_SIZE):0] top; // bits to represent up to all physical registers

    // Initialize top of stack
    initial begin
        top = 0;
    end

    // Push operation
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            top <= 0;
        end else if (push && !full) begin
            stack[top] <= tag_in;
            top <= top + 1;
        end
    end

    // Pop operation
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            top <= 0;
        end else if (pop && !empty) begin
            top <= top - 1;
        end
    end

    // Output data
    always_comb begin
        // if (empty) begin
        //     assign tag_out = NULL_TAG // define NULL_TAG
        // end
        // else begin
        //     assign tag_out = stack[top];
        // end
        assign tag_out = stack[top];ss
        assign empty = (top == 0);
        assign full = (top == STACK_SIZE);
    end
    

endmodule
