`include "verilog/sys_defs.svh"
module prf(
    input             clock, // system clock
    input             reset,
    input IS_PRF_PACKET is_prf_packet,
    input EX_PRF_PACKET ic_prf_packet,
    
    output PRF_IS_PACKET prf_is_packet
);
    logic [`PHYS_REG_SZ-1:1] [`XLEN-1:0] registers;
    
    always_comb begin
    
        //Read Port 1
        if (is_prf_packet.read_tag_1.phys_reg == 0) begin
            prf_is_packet.read_out_1 = 0;
        end else if (ic_prf_packet.write_en && (ic_prf_packet.write_tag.phys_reg == is_prf_packet.read_tag_1.phys_reg)) begin
            prf_is_packet.read_out_1 = ic_prf_packet.write_data; // internal forwarding
        end else begin
            prf_is_packet.read_out_1 = registers[is_prf_packet.read_tag_1.phys_reg];
        end
        
        //Read Port 2
        if (is_prf_packet.read_tag_2.phys_reg == 0) begin
            prf_is_packet.read_out_2 = 0;
        end else if (ic_prf_packet.write_en && (ic_prf_packet.write_tag.phys_reg == is_prf_packet.read_tag_2.phys_reg)) begin
            prf_is_packet.read_out_2 = ic_prf_packet.write_data; // internal forwarding
        end else begin
            prf_is_packet.read_out_2 = registers[is_prf_packet.read_tag_2.phys_reg];
        end
    end
    
    //Write port
    always_ff @(posedge clock) begin
        if(reset) begin
            foreach(registers[i])begin
                registers[i]<=i;
            end
        end
        if (ic_prf_packet.write_en && ic_prf_packet.write_tag.phys_reg != 0) begin
            registers[ic_prf_packet.write_tag.phys_reg] <= ic_prf_packet.write_data;
        end
    end
endmodule
    
    
