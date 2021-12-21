`include "defines.v"

module ex_mem(input clk,rst,
		input wire[`RegBus]ex_wdata,
	input wire[`RegAddrBus]ex_wd,
	input wire ex_wreg,

	//hilo
	input wire ex_whilo,
	input wire [`RegBus] ex_hi,ex_lo,
	input wire[5:0] stall,
	input wire [1:0] cnt_i,
	input wire [`DoubleRegBus] hilo_i,

	input wire[`AluOpBus] ex_aluop_o,
	input wire[`RegBus] ex_mem_addr_o,
	input wire[`RegBus] ex_reg2_o,

	output reg [1:0] cnt_o,
	output reg [`DoubleRegBus] hilo_o,

	output reg[`RegBus]mem_hi,mem_lo,
	output reg mem_whilo,

	output reg[`RegBus]mem_wdata,
	output reg[`RegAddrBus]mem_wd,
	output reg mem_wreg,
	//mem
	output reg[`AluOpBus] mem_aluop_i,
	output reg[`RegBus] mem_mem_addr_i,
	output reg[`RegBus] mem_reg2_i);

always @(posedge clk) begin
	if (rst==`RstEnable) begin
		mem_wdata<=`ZeroWord;
		mem_wd<=`NOPRegAddr;
		mem_wreg<=`WriteDisable;
		mem_hi<=`ZeroWord;
		mem_lo<=`ZeroWord;
		mem_whilo<=`WriteDisable;
		hilo_o<={`ZeroWord,`ZeroWord};
		cnt_o<=2'b00;
		mem_aluop_i<=`EXE_NOP_OP;
		mem_mem_addr_i<=`ZeroWord;
		mem_reg2_i<=`ZeroWord;
	end else if (stall[3]==`Stop && stall[4]==`NoStop) begin
		mem_wdata<=`ZeroWord;
		mem_wd<=`NOPRegAddr;
		mem_wreg<=`WriteDisable;
		mem_hi<=`ZeroWord;
		mem_lo<=`ZeroWord;
		mem_whilo<=`WriteDisable;
		hilo_o<=hilo_i;
		cnt_o<=cnt_i;
	end else if (stall[3]==`NoStop) begin
		mem_wdata<=ex_wdata;
		mem_wd<=ex_wd;
		mem_wreg<=ex_wreg;
		mem_hi<=ex_hi;
		mem_lo<=ex_lo;
		mem_whilo<=ex_whilo;
		hilo_o<={`ZeroWord,`ZeroWord};
		cnt_o<=2'b00;
		mem_aluop_i<=ex_aluop_o;
		mem_mem_addr_i<=ex_mem_addr_o;
		mem_reg2_i<=ex_reg2_o;
	end else begin
		hilo_o<=hilo_i;
		cnt_o<=cnt_i;
	end
end
endmodule
