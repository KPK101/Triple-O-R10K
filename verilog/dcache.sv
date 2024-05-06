/////////////////////////////////////////////////////////////////////////
//                                                                     //
//   Modulename :  icache.sv                                           //
//                                                                     //
//  Description :  The instruction cache module that reroutes memory   //
//                 accesses to decrease misses.                        //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

`include "verilog/sys_defs.svh"

// Internal macros, no other file should need these
`define CACHE_LINES 32
`define CACHE_LINE_BITS $clog2(`CACHE_LINES)

typedef struct packed {
    logic [63:0]                  data;
    // (13 bits) since only need 16 bits to access all memory and 3 are the offset
    logic [12-`CACHE_LINE_BITS:0] tags;
    logic                         valid;
} DCACHE_ENTRY;


module dcache (
    input clock,
    input reset,

    // From memory
    input [3:0]  Imem2proc_response, // Should be zero unless there is a response
    input [63:0] Imem2proc_data,
    input [3:0]  Imem2proc_tag,

    // From execute stage for load
    input MEMOP_DCACHE_PACKET memop_dcache_packet,

    // To memory
    output logic [1:0]       dcache2Imem_command,
    output logic [63:0]      dcache2Imem_data,
    output logic [`XLEN-1:0] dcache2Imem_addr,

    // To execute stage for load
    output DCACHE_MEMOP_PACKET dcache_memop_packet,
    output got_mem_data
   // output current_index, current_tag,
);

    // ---- Cache data ---- //

    DCACHE_ENTRY [`CACHE_LINES-1:0] dcache_data;

    logic       write_successful;
    // ---- Addresses and final outputs ---- //

    // Note: cache tags, not memory tags
    logic [12-`CACHE_LINE_BITS:0] current_tag, last_tag;
    logic [`CACHE_LINE_BITS - 1:0] current_index, last_index;

    assign {current_tag, current_index} = memop_dcache_packet.proc2Dcache_addr[15:3];

    assign dcache_memop_packet.Dcache_data_out = dcache_data[current_index].data;
    assign dcache_memop_packet.Dcache_valid_out = dcache_data[current_index].valid && (dcache_data[current_index].tags == current_tag);
    // ---- Main cache logic ---- //

    logic [3:0] current_mem_tag; // The current memory tag we might be waiting on
    logic       miss_outstanding; // Whether a miss has received its response tag to wait on

    //wire got_mem_data    = (current_mem_tag == Imem2proc_tag) && (current_mem_tag != 0);
    wire got_mem_data    = (current_mem_tag == Imem2proc_tag) && (current_mem_tag != 0);

    wire changed_addr    = (current_index != last_index) || (current_tag != last_tag);

    wire update_mem_tag  = changed_addr || miss_outstanding || got_mem_data;

    wire unanswered_miss = changed_addr ? !dcache_memop_packet.Dcache_valid_out
                                        : miss_outstanding && (Imem2proc_response == 0);
   
    
    //tell memory if it is BUS_LOAD or BUS_STORE
    assign dcache2Imem_command = (miss_outstanding && !changed_addr) ? memop_dcache_packet.proc2Dcache_command : BUS_NONE;

    assign dcache2Imem_addr    = {memop_dcache_packet.proc2Dcache_addr[31:3],3'b0};
    assign proc2Dcache_data  = memop_dcache_packet.proc2Dcache_data;
    // ---- Cache state registers ---- //


    always_ff @(posedge clock) begin
        if (reset) begin
            last_index       <= -1; // These are -1 to get ball rolling when2
            last_tag         <= -1; // reset goes low because addr "changes"
            current_mem_tag  <= 0;
            miss_outstanding <= 0;
            dcache_data      <= 0; // Set all cache data to 0 (including valid bits)
        end else if(memop_dcache_packet.proc2Dcache_command == BUS_STORE) begin
            last_index       <= current_index;
            last_tag         <= current_tag;
            miss_outstanding <= unanswered_miss;
            write_successful <= 1'b0;
            if (update_mem_tag) begin
                current_mem_tag <= Imem2proc_response;
            end
            if (got_mem_data) begin // If data came from memory, meaning tag matches
                write_successful<= 1'b1;
                dcache_data[current_index].data  <= memop_dcache_packet.proc2Dcache_data;
                dcache_data[current_index].tags  <= current_tag;
                dcache_data[current_index].valid <= 1;
            end
        end else if(memop_dcache_packet.proc2Dcache_command == BUS_LOAD) begin
            last_index       <= current_index;
            last_tag         <= current_tag;
            miss_outstanding <= unanswered_miss;
            if (update_mem_tag) begin
                current_mem_tag <= Imem2proc_response;
            end
            if (got_mem_data) begin // If data came from memory, meaning tag matches
                dcache_data[current_index].data  <= Imem2proc_data;
                dcache_data[current_index].tags  <= current_tag;
                dcache_data[current_index].valid <= 1;
            end
        end
    end

endmodule // icache
