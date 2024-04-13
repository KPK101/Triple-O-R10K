//TODO:ADD LOGIC
module stage_ir(
    input ROB_IR_PACKET rob_ir_packet,
    
    output IR_FL_PACKET ir_fl_packet,
    output IR_AM_PACKET ir_am_packet
);
    assign ir_fl_packet.retire_t_old = rob_ir_packet.retire_t_old;
    assign ir_fl_packet.retire_en = rob_ir_packet.retire_en;
    
    assign ir_am_packet = rob_ir_packet;

endmodule
