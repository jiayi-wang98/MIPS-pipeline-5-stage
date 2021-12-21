`include "defines.v"

module openmips_rom_sopc(input wire clk,rst);
	wire[`InstAddrBus] inst_addr;
	wire[`InstBus] inst;
	wire rom_ce;
	wire [`RegBus]ram_data_o,ram_addr_i,ram_data_i;
	wire [3:0] ram_sel;
	wire ram_we,ram_ce;

  	openMIPS openMIPS0(.clk(clk),.rst(rst),
		.rom_data_i(inst),
		.ram_data_o(ram_data_o),
		.ram_addr_i(ram_addr_i),
		.ram_we(ram_we),
		.ram_ce(ram_ce),
		.ram_sel(ram_sel),
		.ram_data_i(ram_data_i),
		.rom_addr_o(inst_addr),
		.rom_ce_o(rom_ce));

	inst_rom inst_rom1(.ce(rom_ce),
		.addr(inst_addr),
		.inst(inst));

	data_ram data_ram0(.clk(clk),.we(ram_we),.ce(ram_ce),
		.addr(ram_addr_i),
		.sel(ram_sel),
		.data_i(ram_data_i),
		.data_o(ram_data_o)
	);
endmodule
