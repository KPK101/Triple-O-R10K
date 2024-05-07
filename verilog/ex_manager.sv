module ex_manager (
	input clock,
	input reset,

    input interrupt,

    input [$clog2(`RS_SZ)-1:0] done_idx,
    input logic                done_en,
	
	input IS_EX_PACKET is_ex_packet,

    output IS_EX_PACKET [`RS_SZ - 1:0] ex_entries
);
    always_ff @(posedge clock) begin
        if (reset || interrupt) begin
            foreach (ex_entries[i]) begin
                ex_entries[i].inst <= `NOP;
                ex_entries[i].valid <= 0;
                ex_entries[i].NPC <= 0;
            end
        end else begin
            if (is_ex_packet.valid) begin
                ex_entries[is_ex_packet.rs_idx] <= is_ex_packet;
            end
            if (done_en) begin
                ex_entries[done_idx].inst <= `NOP;
                ex_entries[done_idx].valid <= 0;
                ex_entries[done_idx].NPC <= 0;
            end
        end
    end
endmodule

    


