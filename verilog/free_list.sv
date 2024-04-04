// `include "verilog/sys_defs.svh"
// `include "verilog/ISA.svh"


// module free_list #(parameter STACK_SIZE = `PHYS_REG_SZ)(
//     input logic clk,
//     input logic reset,
//     input `TAG tag_in,
//     input logic push,
//     input logic pop,
//     output `TAG  tag_out,
//     output logic empty,
//     output logic full   
// );

   
//     `TAG stack [STACK_SIZE - 1:0];
//     // `TAG NULL_TAG;
//     logic [$clog2(STACK_SIZE):0] top; // bits to represent up to all physical registers

//     // Initialize top of stack
//     initial begin
//         top = 0;
//     end

//     // Push operation
//     always @(posedge clk or posedge reset) begin
//         if (reset) begin
//             top <= 0;
//         end else if (push && !full) begin
//             stack[top] <= tag_in;
//             top <= top + 1;
//         end
//     end

//     // Pop operation
//     always @(posedge clk or posedge reset) begin
//         if (reset) begin
//             top <= 0;
//         end else if (pop && !empty) begin
//             top <= top - 1;
//         end
//     end

//     // Output data
//     always_comb begin
//         // if (empty) begin
//         //     assign tag_out = NULL_TAG // define NULL_TAG
//         // end
//         // else begin
//         //     assign tag_out = stack[top];
//         // end
//         assign tag_out = stack[top];ss
//         assign empty = (top == 0);
//         assign full = (top == STACK_SIZE);
//     end
    

// endmodule



//Diff version-> Ritwik cause extra ss character 
//The tag_out is now procedurally assigned within an always_ff block, which correctly updates its value based on the current state of the stack. When the stack is not empty, tag_out reflects the last tag that was pushed onto the stack. In case of reset or when the stack is empty, tag_out is set to an undefined state using 'bx.
//Changed tag_out to reg: Since tag_out is now procedurally assigned within an always_ff block, its declaration is changed from output to output reg to allow for such assignments.

`include "verilog/sys_defs.svh"
`include "verilog/ISA.svh"

module free_list #(parameter STACK_SIZE = `PHYS_REG_SZ)(
    input logic clk,
    input logic reset,
    input `TAG tag_in,
    input logic push,
    input logic pop,
    output reg `TAG tag_out, // Changed to reg to allow procedural assignment
    output logic empty,
    output logic full   
);

    `TAG stack [STACK_SIZE - 1:0];
    logic [$clog2(STACK_SIZE):0] top; // Bits to represent up to all physical registers

    // Initialize top of stack
    initial begin
        top = 0;
    end

    // Push operation
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            top <= 0;
        end else if (push && !full) begin
            stack[top] = tag_in; // Using non-blocking assignment is not necessary here, but it's okay to keep it consistent
            top <= top + 1;
        end
    end

    // Pop operation
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            top <= 0;
        end else if (pop && !empty) begin
            top <= top - 1; // Pop operation decrements 'top', actual popping logic to access the tag can be implemented if needed
        end
    end

    // Determine if the stack is empty or full
    assign empty = (top == 0);
    assign full = (top == STACK_SIZE);

    // Correct handling of tag_out output and removing the syntax error 'ss'
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            tag_out <= `TAG'bx; // Resetting tag_out, assuming `TAG'bx is a valid representation for an undefined or reset state
        end else if (!empty) begin
            tag_out <= stack[top - 1]; // Adjusted to access the last pushed element correctly
        end else begin
            tag_out <= `TAG'bx; // Handling the empty case explicitly
        end
    end
endmodule
