//including for reference
/*typedef struct packed{
        logic valid;
	logic [$clog2(`PHYS_REG_SZ)-1:0] tag;
	logic ready;
} TAG;*/
`include "verilog/sys_defs.svh"
`include "verilog/ISA.svh"

typedef struct packed{
	logic [$clog2(`PHYS_REG_SZ)-1:0] phy_reg;	
	TAG tag;
}MAP_TABLE_ENTRY;

module map_table(
	input clock,
	input reset,
	input CDB_enable,
	input TAG t,t1,t2, CDB,//(implement CDB)
	input COMMAND command,
	input [$clog2(`PHYS_REG_SZ)-1:0] reg_t, reg_t1, reg_t2,
	output TAG t_out,
	output TAG t1_out,
	output TAG t2_out
);
MAP_TABLE_ENTRY [$clog2(`PHYS_REG_SZ)-1: 0] map_table_entry; 
always_ff @(posedge clock) begin
	if(reset) begin
		//upon reset, making all tags available. tags start from t0 for regs r0. is reg 0 reserved??
		for(int i = 0; i < $clog2(`PHYS_REG_SZ); i++)begin
			map_table_entry[i].phy_reg <= i;
			map_table_entry[i].tag.valid <=1;
			map_table_entry[i].tag.tag <= i;
			map_table_entry[i].tag.ready <= 1;
		end
	end
	//if read command from dispatch, read out tag corresponding to the input physical register operand from the dispatch phase
	else if(command == READ)begin
		for(int i = 0; i < $clog2(`PHYS_REG_SZ); i++)begin
			if(map_table_entry[i].phy_reg == reg_t)begin
				t_out <= map_table_entry[i].tag;
			end
			
			if(map_table_entry[i].phy_reg == reg_t1)begin
				t1_out <= map_table_entry[i].tag;
			end

			if(map_table_entry[i].phy_reg == reg_t2)begin
				t2_out <= map_table_entry[i].tag;
			end
		end
	end
	//if write command, check tag numbers within the TAG struct of each map entry, and if same as input, update it
	else if(command == WRITE)begin
		for(int i = 0; i < $clog2(`PHYS_REG_SZ); i++)begin
			if(map_table_entry[i].tag.tag == reg_t)begin
				map_table_entry[i].tag <= t;
			end
			
			if(map_table_entry[i].tag.tag == reg_t1)begin
				map_table_entry[i].tag <= t1;
			end

			if(map_table_entry[i].tag.tag == reg_t2)begin
				map_table_entry[i].tag <= t2;
			end
		end
	end

	else if(CDB_enable)begin
		for(int i = 0; i < $clog2(`PHYS_REG_SZ); i++)begin
			if(map_table_entry[i].tag.tag == CDB.tag)begin
				map_table_entry[i].tag <= CDB;
			end
		end
	end
end

endmodule
