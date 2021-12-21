`include "defines.v"
module pc_reg(input wire rst,clk,
		input wire[5:0] stall,
		input wire branch_flag_i,
		input wire [`InstAddrBus]branch_target_address_i,
		output reg [`InstAddrBus]pc,
		output reg ce
		);

always @ (posedge clk) begin
	if (rst==`RstEnable) begin
		ce<=`ChipDisable;
	end else begin
		ce<=`ChipEnable;
	end
end

always @ (posedge clk) begin
	if (ce<=`ChipDisable) begin
		pc<=32'h00000000;
	end else if (branch_flag_i==1'b0 && stall[0]==`NoStop) begin
		pc<=pc+32'h4;
	end else if (branch_flag_i==1'b1 && stall[0]==`NoStop) begin
		pc<=branch_target_address_i;
	end
end
endmodule