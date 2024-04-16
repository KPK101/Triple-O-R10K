/////////////////////////////////////////////////////////////////////////
//                                                                     //
//   Modulename :  sys_defs.svh                                        //
//                                                                     //
//  Description :  This file has the macro-defines for macros used in  //
//                 the pipeline design.                                //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

`ifndef __SYS_DEFS_SVH__
`define __SYS_DEFS_SVH__

// all files should `include "sys_defs.svh" to at least define the timescale
`timescale 1ns/100ps

///////////////////////////////////
// ---- Starting Parameters ---- //
///////////////////////////////////

// some starting parameters that you should set
// this is *your* processor, you decide these values (try analyzing which is best!)

// superscalar width
`define N 1

// sizes
`define ROB_SZ 32
`define RS_SZ 5
`define PHYS_REG_SZ (32 + `ROB_SZ)

// worry about these later
`define BRANCH_PRED_SZ xx
`define LSQ_SZ xx

// functional units (you should decide if you want more or fewer types of FUs)
`define NUM_FU_ALU 1
`define NUM_FU_MULT 1
`define NUM_FU_LOAD 1
`define NUM_FU_STORE 1

// number of mult stages (2, 4, or 8)
`define MULT_STAGES 4

///////////////////////////////
// ---- Basic Constants ---- //
///////////////////////////////

// NOTE: the global CLOCK_PERIOD is defined in the Makefile

// useful boolean single-bit definitions
`define FALSE 1'h0
`define TRUE  1'h1

// data length
`define XLEN 32

// the zero register
// In RISC-V, any read of this register returns zero and any writes are thrown away
`define ZERO_REG 5'd0

// Basic NOP instruction. Allows pipline registers to clearly be reset with
// an instruction that does nothing instead of Zero which is really an ADDI x0, x0, 0
`define NOP 32'h00000013

///////////////////////////////
// ---- R10K Components ---- //
///////////////////////////////

typedef struct packed{
    logic valid;
	logic [$clog2(`PHYS_REG_SZ)-1:0] phys_reg;
	logic ready;
} TAG;

typedef struct packed{
    INST              inst;
    logic [`XLEN-1:0] PC;
    logic [`XLEN-1:0] NPC; // PC + 4

    ALU_OPA_SELECT opa_select; // ALU opa mux select (ALU_OPA_xxx *)
    ALU_OPB_SELECT opb_select; // ALU opb mux select (ALU_OPB_xxx *)

    logic [4:0] dest_reg_idx;  // destination (writeback) register index
    ALU_FUNC    alu_func;      // ALU function select (ALU_xxx *)
    logic       rd_mem;        // Does inst read memory?
    logic       wr_mem;        // Does inst write memory?
    logic       cond_branch;   // Is inst a conditional branch?
    logic       uncond_branch; // Is inst an unconditional branch?
    logic       halt;          // Is this a halt?OPB_IS_I_IMM
    logic       illegal;       // Is this instruction illegal?
    logic       csr_op;        // Is this a CSR operation? (we use this to get return code)
    TAG			t;
    TAG			t1;
    TAG			t2;
    logic [$clog2(`RS_SZ)-1:0] rs_idx;
    logic [$clog2(`ROB_SZ)-1:0] rob_idx;
    
    logic       valid;
} DECODER_PACKET;

/////////////////////////////////
// ---- Map Table Packets ---- //
/////////////////////////////////

//ID -> MT Connections
typedef struct packed{
	//Query param
	logic [4:0] read_idx_1;
	logic [4:0] read_idx_2;
	
	//Write param
	logic [4:0] write_idx;
	TAG write_tag;
	logic write_en;
}ID_MT_PACKET;



//MT -> ID Connections
typedef struct packed{
	//Query results
	TAG read_out_1;
	TAG read_out_2;
	TAG write_out;
}MT_ID_PACKET;

///////////////////////////////////////////
// ---- Reservation Station Packets ---- //
///////////////////////////////////////////


//ID -> RS
typedef struct packed{
	DECODER_PACKET decoder_packet;
	logic write_en;
}ID_RS_PACKET;

//EX -> RS
typedef struct packed{
	logic [$clog2(`RS_SZ)-1:0] remove_idx;
	logic remove_en;
}EX_RS_PACKET;

//RS -> ID
typedef struct packed{
	logic [$clog2(`RS_SZ)-1:0] free_idx;
	logic free;
}RS_ID_PACKET;

//RS -> IS
typedef struct packed{
	DECODER_PACKET decoder_packet;
	logic issue_en;
}RS_IS_PACKET;


//////////////////////////////////////
// ---- Reorder Buffer Packets ---- //
//////////////////////////////////////

typedef struct packed{
    TAG t_in;
    TAG t_old_in;
    logic write_en;
}ID_ROB_PACKET;

typedef struct packed{
    logic [$clog2(`ROB_SZ)-1:0] complete_idx;
    logic complete_en;
}IC_ROB_PACKET;

typedef struct packed{
    logic [$clog2(`ROB_SZ)-1:0] free_idx;
    logic free;
}ROB_ID_PACKET;

typedef struct packed{
    TAG retire_t;
    TAG retire_t_old;
    logic retire_en;
}ROB_IR_PACKET;

/////////////////////////////////
// ---- Free List Packets ---- //
/////////////////////////////////
typedef struct packed{
    logic pop_en;
}ID_FL_PACKET;

typedef struct packed{
    TAG retire_t_old;
    logic retire_en;
}IR_FL_PACKET;

typedef struct packed{
    TAG retire_t;
    TAG retire_t_old;
    logic retire_en;
}IR_AM_PACKET;

typedef struct packed{
    TAG free_tag;
    logic free;
}FL_ID_PACKET;

//////////////////////////////////////////////
// ---- Physical Register File Packets ---- //
//////////////////////////////////////////////

//TODO: THIS IC_PRF IS TEMPORARY (WHAT IF YOU NEED TO COMPLETE MORE THAN ONE??)
typedef struct packed{
    TAG write_tag;
    logic [`XLEN-1:0] write_data;
    logic write_en;
}IC_PRF_PACKET;

typedef struct packed{
    TAG read_tag_1;
    TAG read_tag_2;
}IS_PRF_PACKET;

typedef struct packed{
    logic [`XLEN-1:0] read_out_1;
    logic [`XLEN-1:0] read_out_2;
}PRF_IS_PACKET;


////////////////////////////////
// ---- IF -> ID Packets ---- //
////////////////////////////////

typedef struct packed {
    INST              inst;
    logic [`XLEN-1:0] PC;
    logic [`XLEN-1:0] NPC; // PC + 4
    logic             valid;
} IF_ID_PACKET;


////////////////////////////////
// ---- IS -> EX Packets ---- //
////////////////////////////////

//TODO: THIS CODE IS A PLACEHOLDER.
typedef struct packed {
    INST              inst;
    logic [`XLEN-1:0] PC;
    logic [`XLEN-1:0] NPC; // PC + 4

    logic [`XLEN-1:0] rs1_value; // reg A value
    logic [`XLEN-1:0] rs2_value; // reg B value

    ALU_OPA_SELECT opa_select; // ALU opa mux select (ALU_OPA_xxx *)
    ALU_OPB_SELECT opb_select; // ALU opb mux select (ALU_OPB_xxx *)

    logic TAG dest_tag;  // destination tag
    ALU_FUNC    alu_func;      // ALU function select (ALU_xxx *)
    logic       rd_mem;        // Does inst read memory?
    logic       wr_mem;        // Does inst write memory?
    logic       cond_branch;   // Is inst a conditional branch?
    logic       uncond_branch; // Is inst an unconditional branch?
    logic       halt;          // Is this a halt?
    logic       illegal;       // Is this instruction illegal?
    logic       csr_op;        // Is this a CSR operation? (we only used this as a cheap way to get return code)
    logic [$clog2(`RS_SZ)-1:0] rs_idx;
    logic [$clog2(`ROB_SZ)-1:0] rob_idx;

    logic       valid;
} IS_EX_PACKET;


typedef struct packed {
    logic [`XLEN-1:0] result;
    logic [`XLEN-1:0] NPC;

    logic             take_branch; // Is this a taken branch?
    // Pass-through from decode stage
    logic [`XLEN-1:0] rs2_value;
    logic             rd_mem;
    logic             wr_mem;
    logic [4:0]       dest_reg_idx;
    logic             halt;
    logic             illegal;
    logic             csr_op;
    logic             rd_unsigned; // Whether proc2Dmem_data is signed or unsigned
    MEM_SIZE          mem_size;
    logic [$clog2(`RS_SZ)-1:0] rs_idx;
    logic [$clog2(`ROB_SZ)-1:0] rob_idx;
    
    logic             valid;
    //tells the issue logic that the incoming packet has a computation which was just performed by the FU
    logic 	          done;
} EX_IC_PACKET;


//////////////////////////////////
// ---- Memory Definitions ---- //
//////////////////////////////////

// Cache mode removes the byte-level interface from memory, so it always returns
// a double word. The original processor won't work with this defined. Your new
// processor will have to account for this effect on mem.
// Notably, you can no longer write data without first reading.ALU_OPA_SELECT opa_select,
`define CACHE_MODE

// you are not allowed to change this definition for your final processor
// the project 3 processor has a massive boost in performance just from having no mem latency
// see if you can beat it's CPI in project 4 even with a 100ns latency!
// `define MEM_LATENCY_IN_CYCLES  0
`define MEM_LATENCY_IN_CYCLES (100.0/`CLOCK_PERIOD+0.49999)
// the 0.49999 is to force ceiling(100/period). The default behavior for
// float to integer conversion is rounding to nearest

// How many memory requests can be waiting at once
`define NUM_MEM_TAGS 15

`define MEM_SIZE_IN_BYTES (64*1024)
`define MEM_64BIT_LINES   (`MEM_SIZE_IN_BYTES/8)

typedef union packed {
    logic [7:0][7:0]  byte_level;
    logic [3:0][15:0] half_level;
    logic [1:0][31:0] word_level;
} EXAMPLE_CACHE_BLOCK;

typedef enum logic [1:0] {
    BYTE   = 2'h0,
    HALF   = 2'h1,
    WORD   = 2'h2,
    DOUBLE = 2'h3
} MEM_SIZE;

// Memory bus commands
typedef enum logic [1:0] {
    BUS_NONE   = 2'h0,
    BUS_LOAD   = 2'h1,
    BUS_STORE  = 2'h2
} BUS_COMMAND;

///////////////////////////////
// ---- Exception Codes ---- //
///////////////////////////////

/**
 * Exception codes for when something goes wrong in the processor.
 * Note that we use HALTED_ON_WFI to signify the end of computation.
 * It's original meaning is to 'Wait For an Interrupt', but we generally
 * ignore interrupts in 470
 *
 * This mostly follows the RISC-V Privileged spec
 * except a few add-ons for our infrastructure
 * The majority of them won't be used, but it's good to know what they are
 */

typedef enum logic [3:0] {
    INST_ADDR_MISALIGN  = 4'h0,
    INST_ACCESS_FAULT   = 4'h1,
    ILLEGAL_INST        = 4'h2,
    BREAKPOINT          = 4'h3,
    LOAD_ADDR_MISALIGN  = 4'h4,
    LOAD_ACCESS_FAULT   = 4'h5,
    STORE_ADDR_MISALIGN = 4'h6,
    STORE_ACCESS_FAULT  = 4'h7,
    ECALL_U_MODE        = 4'h8,
    ECALL_S_MODE        = 4'h9,
    NO_ERROR            = 4'ha, // a reserved code that we use to signal no errors
    ECALL_M_MODE        = 4'hb,
    INST_PAGE_FAULT     = 4'hc,
    LOAD_PAGE_FAULT     = 4'hd,
    HALTED_ON_WFI       = 4'he, // 'Wait For Interrupt'.1 In 470, signifies the end of computation
    STORE_PAGE_FAULT    = 4'hf
} EXCEPTION_CODE;

///////////////////////////////////
// ---- Instruction Typedef ---- //
///////////////////////////////////

// from the RISC-V ISA specALU_OPA_SELECT opa_select,
typedef union packed {
    logic [31:0] inst;
    struct packed {
        logic [6:0] funct7;
        logic [4:0] rs2; // source register 2
        logic [4:0] rs1; // source register 1
        logic [2:0] funct3;
        logic [4:0] rd; // destination register
        logic [6:0] opcode;
    } r; // register-to-register instructions
    struct packed {
        logic [11:0] imm; // immediate value for calculating address
        logic [4:0]  rs1; // source register 1 (used as address base)
        logic [2:0]  funct3;
        logic [4:0]  rd;  // destination register
        logic [6:0]  opcode;
    } i; // immediate or load instructions1
    struct packed {
        logic [6:0] off; // offset[11:5] for calculating address
        logic [4:0] rs2; // source register 2
        logic [4:0] rs1; // source register 1 (used as address base)
        logic [2:0] funct3;
        logic [4:0] set; // offset[4:0] for calculating address
        logic [6:0] opcode;
    } s; // store instructions
    struct packed {
        logic       of;  // offset[12]
        logic [5:0] s;   // offset[10:5]
        logic [4:0] rs2; // source register 2
        logic [4:0] rs1; // source register 1
        logic [2:0] funct3;
        logic [3:0] et;  // offset[4:1]
        logic       f;   // offset[11]
        logic [6:0] opcode;
    } b; // branch instructions
    struct packed {
        logic [19:0] imm; // immediate value
        logic [4:0]  rd; // destination register
        logic [6:0]  opcode;
    } u; // upper-immediate instructions
    struct packed {
        logic       of; // offset[20]1
        logic [9:0] et; // offset[10:1]
        logic       s;  // offset[11]
        logic [7:0] f;  // offset[19:12]
        logic [4:0] rd; // destination register
        logic [6:0] opcode;
    } j;  // jump instructions

// extensions for other instruction types
`ifdef ATOMIC_EXT
    struct packed {
        logic [4:0] funct5;
        logic       aq;
        logic       rl;
        logic [4:0] rs2;
        logic [4:0] rs1;
        logic [2:0] funct3;
        logic [4:0] rd;
        logic [6:0] opcode;
    } a; // atomic instructions
`endif
`ifdef SYSTEM_EXT
    struct packed {
        logic [11:0] csr;
        logic [4:0]  rs1;
        logic [2:0]  funct3;
        logic [4:0]  rd;
        logic [6:0]  opcode;
    } sys; // system call instructions
`endif

} INST; // instruction typedef, this should cover all ty1pes of instructions

////////////////////////////////////////
// ---- Datapath Control Signals ---- //
////////////////////////////////////////

// ALU opA input mux selects
typedef enum logic [1:0] {
    OPA_IS_RS1  = 2'h0,
    OPA_IS_NPC  = 2'h1,
    OPA_IS_PC   = 2'h2,
    OPA_IS_ZERO = 2'h3
} ALU_OPA_SELECT;

// ALU opB input mux selects
typedef enum logic [3:0] {
    OPB_IS_RS2    = 4'h0,
    OPB_IS_I_IMM  = 4'h1,
    OPB_IS_S_IMM  = 4'h2,
    OPB_IS_B_IMM  = 4'h3,
    OPB_IS_U_IMM  = 4'h4,
    OPB_IS_J_IMM  = 4'h5
} ALU_OPB_SELECT;

// ALU function code input
// probably want to leave these alone
typedef enum logic [4:0] {
    ALU_ADD     = 5'h00,
    ALU_SUB     = 5'h01,
    ALU_SLT     = 5'h02,
    ALU_SLTU    = 5'h03,
    ALU_AND     = 5'h04,
    ALU_OR      = 5'h05,
    ALU_XOR     = 5'h06,
    ALU_SLL     = 5'h07,
    ALU_SRL     = 5'h08,
    ALU_SRA     = 5'h09,
    ALU_MUL     = 5'h0a, // Mult FU
    ALU_MULH    = 5'h0b, // Mult FU
    ALU_MULHSU  = 5'h0c, // Mult FU
    ALU_MULHU   = 5'h0d, // Mult FU
    ALU_DIV     = 5'h0e, // unused
    ALU_DIVU    = 5'h0f, // unused
    ALU_REM     = 5'h10, // unused
    ALU_REMU    = 5'h11  // unused
} ALU_FUNC;

 
`endif // __SYS_DEFS_SVH__
