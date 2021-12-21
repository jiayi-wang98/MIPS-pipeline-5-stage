`include "defines.v"
`define DIV_FREE 2'b00
`define DIV_BY_ZERO 2'b01
`define DIV_ON 2'b10
`define DIV_END 2'b11

module div(input wire clk,rst,
		input wire signed_div_i,
		input wire [`RegBus] opdata1_i,opdata2_i,
		input wire start_i,
		input wire annul_i,
		output reg[`DoubleRegBus] result_o,
		output reg ready_o);

wire [32:0] div_temp;
reg [5:0] cnt;
reg [64:0] dividend;
reg [1:0] state;
reg [`RegBus] divisor,temp_op1,temp_op2;

assign div_temp ={1'b0,dividend[63:32]}-{1'b0,divisor};


always @(posedge clk) begin
	if (rst==`RstEnable) begin
		state<=`DIV_FREE;
		ready_o<=1'b0;
		result_o<={`ZeroWord,`ZeroWord};
	end else begin
		case (state)
			`DIV_FREE: begin
				if (start_i==1'b1 && annul_i==1'b0) begin
					if (opdata2_i==`ZeroWord) begin
						state<=`DIV_BY_ZERO;
					end else begin
						state<=`DIV_ON;
						cnt<=6'b000000;
						if (signed_div_i==1'b1 && opdata1_i[31]==1'b1) begin
							temp_op1=~opdata1_i+1;
						end else begin
							temp_op1=opdata1_i;
						end 
						
						if (signed_div_i==1'b1 && opdata2_i[31]==1'b1) begin
							temp_op2=~opdata2_i+1;
						end else begin
							temp_op2=opdata2_i;
						end

						dividend<={`ZeroWord,`ZeroWord};
						dividend[32:1]<=temp_op1;
						divisor<=temp_op2;
					end
				end else begin
					state<=`DIV_FREE;
					ready_o<=1'b0;
					result_o<={`ZeroWord,`ZeroWord};
					end
				end
			`DIV_BY_ZERO:begin
				state<=`DIV_END;
				result_o<={`ZeroWord,`ZeroWord};
				ready_o<=1'b0;
				end
			`DIV_ON:begin
				if (annul_i==1'b0) begin
					if (cnt!=6'b100000) begin
						if (div_temp[32]==1'b1) begin //minuend-n<0
							dividend<={dividend[63:0],1'b0};
						end else begin
							dividend<={div_temp[31:0],dividend[31:0],1'b1};
						end

						cnt<=cnt+1;
					end else begin
						if (signed_div_i==1'b1) begin
							if (opdata1_i[31]^opdata2_i[31]) begin
								dividend[31:0]<=~dividend[31:0]+1;
							end
							if (opdata1_i[31]^dividend[64]) begin
								dividend[64:33]<=~dividend[64:33]+1;
							end
						end 
						state<=`DIV_END;
						cnt=6'b000000;
					end
				end else begin
					state<=`DIV_FREE;
					end
				end
			`DIV_END:begin
				ready_o<=1'b1;
				result_o<={dividend[64:33],dividend[31:0]};
				if (start_i==1'b0) begin
					state<=`DIV_FREE;
					ready_o<=1'b0;
					result_o<={`ZeroWord,`ZeroWord};
					end
				end
			default:begin
				end
		endcase
	end
end
endmodule						
