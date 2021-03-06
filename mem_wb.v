`include "defines.v"

module mem_wb(input clk,rst,
	input wire[`RegBus]mem_wdata,
	input wire[`RegAddrBus]mem_wd,
	input wire mem_wreg,

	//hilo
	input wire mem_whilo,
	input wire [`RegBus] mem_hi,mem_lo,

	input wire[5:0] stall,
	output reg[`RegBus]wb_hi,wb_lo,
	output reg wb_whilo,

	output reg [`RegBus]wb_wdata,
	output reg [`RegAddrBus]wb_wd,
	output reg wb_wreg);

always @ (posedge clk) begin
	if (rst==`RstEnable) begin
		wb_wdata=`ZeroWord;
		wb_wd<=`NOPRegAddr;
		wb_wreg<=`WriteDisable;
		wb_hi<=`ZeroWord;
		wb_lo<=`ZeroWord;
		wb_whilo<=`WriteDisable;
	end else if (stall[4]==`Stop && stall[5]==`NoStop)begin
		wb_wdata=`ZeroWord;
		wb_wd<=`NOPRegAddr;
		wb_wreg<=`WriteDisable;
		wb_hi<=`ZeroWord;
		wb_lo<=`ZeroWord;
		wb_whilo<=`WriteDisable;
	end else if (stall[4]==`NoStop) begin
		wb_wdata<=mem_wdata;
		wb_wd<=mem_wd;
		wb_wreg<=mem_wreg;
		wb_hi<=mem_hi;
		wb_lo<=mem_lo;
		wb_whilo<=mem_whilo;
	end 
end
endmodule
