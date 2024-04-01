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

   
    logic [31:0] stack [STACK_SIZE - 1:0];
    logic [`PHYS_REG_SZ-1:0] top; // bits to represent up to 128 elements

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
    assign tag_out = stack[top - 1];
    assign empty = (top == 0);
    assign full = (top == STACK_SIZE);

endmodule
