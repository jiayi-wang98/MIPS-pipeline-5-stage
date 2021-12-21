`include "defines.v"

module mem(input rst,
	input wire[`RegBus]wdata_i,
	input wire[`RegAddrBus]wd_i,
	input wire wreg_i,
	//hilo
	input wire mem_whilo_i,
	input wire [`RegBus] mem_hi_i,mem_lo_i,
	
	//mem
	input wire[`AluOpBus] aluop_i,
	input wire[`RegBus] mem_addr_i,
	input wire[`RegBus] reg2_i,
	input wire[`RegBus] mem_data_i,

	output reg[`RegBus]mem_hi_o,mem_lo_o,
	output reg mem_whilo_o,

	output reg [`RegBus]wdata_o,
	output reg [`RegAddrBus]wd_o,
	output reg wreg_o,
	output reg[`RegBus] mem_addr_o,
	output wire mem_we_o,
	output reg mem_ce_o,
	output reg[3:0] mem_sel_o,
	output reg[`RegBus] mem_data_o
);

wire [`RegBus] Zero32;
reg mem_we;

assign mem_we_o=mem_we;
assign Zero32=`ZeroWord;

always @ (*) begin
	if (rst==`RstEnable) begin
		wdata_o=`ZeroWord;
		wd_o<=`NOPRegAddr;
		wreg_o<=`WriteDisable;
		mem_hi_o<=`ZeroWord;
		mem_lo_o<=`ZeroWord;
		mem_whilo_o<=`WriteDisable;
		mem_addr_o<=`ZeroWord;
		mem_we<=1'b0;
		mem_ce_o<=1'b0;
		mem_sel_o<=4'b0000;
		mem_data_o<=`ZeroWord;
	end else begin
		wdata_o<=wdata_i;
		wd_o<=wd_i;
		wreg_o<=wreg_i;
		mem_hi_o<=mem_hi_i;
		mem_lo_o<=mem_lo_i;
		mem_whilo_o<=mem_whilo_i;
		mem_addr_o<=`ZeroWord;
		mem_we<=1'b0;
		mem_ce_o<=1'b0;
		mem_sel_o<=4'b1111;
		mem_data_o<=`ZeroWord;
		case (aluop_i)
			`EXE_LB_OP:begin
				mem_addr_o<=mem_addr_i;
				mem_we<=1'b0;
				mem_ce_o<=1'b1;
				case (mem_addr_i[1:0])
					2'b00:begin
						mem_sel_o<=4'b1000;
						wdata_o<={{24{mem_data_i[31]}},mem_data_i[31:24]};
					end
					2'b01:begin
						mem_sel_o<=4'b0100;
						wdata_o<={{24{mem_data_i[23]}},mem_data_i[23:16]};
					end
					2'b10:begin
						mem_sel_o<=4'b0010;
						wdata_o<={{24{mem_data_i[15]}},mem_data_i[15:8]};
					end
					2'b11:begin
						mem_sel_o<=4'b0001;
						wdata_o<={{24{mem_data_i[7]}},mem_data_i[7:0]};
					end
					default:begin
						wdata_o<=`ZeroWord;
					end
				endcase
				end
			`EXE_LBU_OP:begin
				mem_addr_o<=mem_addr_i;
				mem_we<=1'b0;
				mem_ce_o<=1'b1;
				case (mem_addr_i[1:0])
					2'b00:begin
						mem_sel_o<=4'b1000;
						wdata_o<={{24{1'b0}},mem_data_i[31:24]};
					end
					2'b01:begin
						mem_sel_o<=4'b0100;
						wdata_o<={{24{1'b0}},mem_data_i[23:16]};
					end
					2'b10:begin
						mem_sel_o<=4'b0010;
						wdata_o<={{24{1'b0}},mem_data_i[15:8]};
					end
					2'b11:begin
						mem_sel_o<=4'b0001;
						wdata_o<={{24{1'b0}},mem_data_i[7:0]};
					end
					default:begin
						wdata_o<=`ZeroWord;
					end
				endcase
				end	
			`EXE_LH_OP:begin
				mem_addr_o<=mem_addr_i;
				mem_we<=1'b0;
				mem_ce_o<=1'b1;
				case (mem_addr_i[1:0])
					2'b00:begin
						mem_sel_o<=4'b1100;
						wdata_o<={{16{mem_data_i[31]}},mem_data_i[31:16]};
					end
					2'b10:begin
						mem_sel_o<=4'b0011;
						wdata_o<={{16{mem_data_i[15]}},mem_data_i[15:0]};
					end
					default:begin
						wdata_o<=`ZeroWord;
					end
				endcase
				end	
			`EXE_LHU_OP:begin
				mem_addr_o<=mem_addr_i;
				mem_we<=1'b0;
				mem_ce_o<=1'b1;
				case (mem_addr_i[1:0])
					2'b00:begin
						mem_sel_o<=4'b1100;
						wdata_o<={{16{1'b0}},mem_data_i[31:16]};
					end
					2'b10:begin
						mem_sel_o<=4'b0011;
						wdata_o<={{16{1'b0}},mem_data_i[15:0]};
					end
					default:begin
						wdata_o<=`ZeroWord;
					end
				endcase
				end	
			`EXE_LW_OP:begin
				mem_addr_o<=mem_addr_i;
				mem_we<=1'b0;
				mem_ce_o<=1'b1;
				mem_sel_o<=4'b1111;
				wdata_o<=mem_data_i;
				end	
			`EXE_LWL_OP:begin
				mem_addr_o<={mem_addr_i[31:2],2'b00};
				mem_we<=1'b0;
				mem_ce_o<=1'b1;
				mem_sel_o<=4'b1111;
				case (mem_addr_i[1:0])
					2'b00:begin
						wdata_o<=mem_data_i[31:0];
					end
					2'b01:begin
						wdata_o<={mem_data_i[23:0],reg2_i[7:0]};
					end
					2'b10:begin
						wdata_o<={mem_data_i[15:0],reg2_i[15:0]};
					end
					2'b11:begin
						wdata_o<={mem_data_i[7:0],reg2_i[23:0]};
					end
					default:begin
						wdata_o<=`ZeroWord;
					end
				endcase
				end
			`EXE_LWR_OP:begin
				mem_addr_o<={mem_addr_i[31:2],2'b00};
				mem_we<=1'b0;
				mem_ce_o<=1'b1;
				mem_sel_o<=4'b1111;
				case (mem_addr_i[1:0])
					2'b11:begin
						wdata_o<=mem_data_i[31:0];
					end
					2'b10:begin
						wdata_o<={reg2_i[31:24],mem_data_i[31:8]};
					end
					2'b01:begin
						wdata_o<={reg2_i[31:16],mem_data_i[31:16]};
					end
					2'b00:begin
						wdata_o<={reg2_i[31:8],mem_data_i[31:24]};
					end
				endcase
				end
			`EXE_SB_OP:begin
				mem_addr_o<=mem_addr_i;
				mem_data_o<={reg2_i[7:0],reg2_i[7:0],reg2_i[7:0],reg2_i[7:0]};
				mem_we<=1'b1;
				mem_ce_o<=1'b1;
				case (mem_addr_i[1:0])
					2'b00:begin
						mem_sel_o<=4'b1000;
					end
					2'b01:begin
						mem_sel_o<=4'b0100;
					end
					2'b10:begin
						mem_sel_o<=4'b0010;
					end
					2'b11:begin
						mem_sel_o<=4'b0001;
					end
				endcase
				end
			`EXE_SH_OP:begin
				mem_addr_o<=mem_addr_i;
				mem_data_o<={reg2_i[15:0],reg2_i[15:0]};
				mem_we<=1'b1;
				mem_ce_o<=1'b1;
				case (mem_addr_i[1:0])
					2'b00:begin
						mem_sel_o<=4'b1100;
					end
					2'b10:begin
						mem_sel_o<=4'b0011;
					end
				endcase
				end
			`EXE_SW_OP:begin
				mem_addr_o<=mem_addr_i;
				mem_data_o<=reg2_i;
				mem_we<=1'b1;
				mem_ce_o<=1'b1;
				mem_sel_o<=4'b1111;
				end
			`EXE_SWL_OP:begin
				mem_addr_o<={mem_addr_i[31:2],2'b00};
				mem_we<=1'b1;
				mem_ce_o<=1'b1;
				case (mem_addr_i[1:0])
					2'b00:begin
						mem_sel_o<=4'b1111;
						mem_data_o<=reg2_i;
					end
					2'b01:begin
						mem_sel_o<=4'b0111;
						mem_data_o<={Zero32[7:0],reg2_i[31:8]};
					end
					2'b10:begin
						mem_sel_o<=4'b0011;
						mem_data_o<={Zero32[15:0],reg2_i[31:16]};
					end
					2'b11:begin
						mem_sel_o<=4'b0001;
						mem_data_o<={Zero32[23:0],reg2_i[31:24]};
					end
				endcase
				end
			`EXE_SWR_OP:begin
				mem_addr_o<={mem_addr_i[31:2],2'b00};
				mem_we<=1'b1;
				mem_ce_o<=1'b1;
				case (mem_addr_i[1:0])
					2'b00:begin
						mem_sel_o<=4'b1000;
						mem_data_o<={reg2_i[7:0],Zero32[23:0]};
					end
					2'b01:begin
						mem_sel_o<=4'b1100;
						mem_data_o<={reg2_i[15:0],Zero32[15:0]};
					end
					2'b10:begin
						mem_sel_o<=4'b1110;
						mem_data_o<={reg2_i[23:0],Zero32[7:0]};
					end
					2'b11:begin
						mem_sel_o<=4'b1111;
						mem_data_o<=reg2_i;
					end
				endcase
				end
			default:begin
				end
		endcase
	end 
end
endmodule
