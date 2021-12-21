`include "defines.v"

module ex(input rst,
	input wire[`AluOpBus] aluop_i,
	input wire[`AluSelBus] alusel_i,
	input wire[`RegBus] reg1_i,reg2_i,
	input wire[`RegAddrBus]wd_i,
	input wire wreg_i,

	//hilo
	input wire[`RegBus] hi_i,lo_i,wb_hi_i,wb_lo_i,
	input wire wb_whilo_i,

	input wire[`RegBus] mem_hi_i,mem_lo_i,
	input wire mem_whilo_i,
	
	//madd,msub
	input wire[`DoubleRegBus] hilo_temp_i,
	input wire[1:0] cnt_i,	

	//div,divu
	input wire div_ready_i,
	input wire [`DoubleRegBus] div_res_i,

	//branch
	input wire is_in_delay_slot,
	input wire [`RegBus] link_address_i,
	
	input wire [`RegBus] inst_i,
	
	output reg signed_div_o,div_start_o,
	output reg [`RegBus] div_opdata1_o,div_opdata2_o,

	
	output reg[`RegBus] hi_o,lo_o,
	output reg whilo_o,

	output reg[`RegBus]wdata_o,
	output reg[`RegAddrBus]wd_o,
	output reg wreg_o,
	
	output reg stallreq,
	output reg[`DoubleRegBus] hilo_temp_o,
	output reg[1:0] cnt_o,
	
	//mem
	output wire[`AluOpBus] aluop_o,
	output wire[`RegBus] mem_addr_o,
	output wire[`RegBus] reg2_o
	);

reg [`RegBus] logic_out;
reg [`RegBus] shift_out;
reg [`RegBus] move_res;
reg [`RegBus] arithmetic_res;
reg [`RegBus] HI,LO;


wire ov_sum;
wire reg1_eq_reg2;
wire reg1_lt_reg2;
wire [`RegBus] reg2_i_mux; //restore reg2 complement
wire [`RegBus] reg1_i_not; //restore reg1 not
wire [`RegBus] sum_res;
wire [`RegBus] opdata1_mult,opdata2_mult;
wire [`DoubleRegBus] hilo_temp;
reg [`DoubleRegBus] hilo_temp1;
reg stallreq_for_madd_temp;
reg stallreq_for_div;

reg [`DoubleRegBus] mult_res;

always @(*) begin
	stallreq<=stallreq_for_madd_temp||stallreq_for_div;
end

assign reg2_i_mux=((aluop_i==`EXE_SUB_OP) ||
		(aluop_i==`EXE_SUBU_OP)||
		(aluop_i==`EXE_SLT_OP))? ((~reg2_i)+1):reg2_i;

assign sum_res=reg1_i+reg2_i_mux;

//check overload
assign ov_sum=((!reg1_i[31] && !reg2_i_mux[31]) && sum_res[31]) || ((reg1_i[31] && reg2_i_mux[31]) && (!sum_res[31]));

assign reg1_lt_reg2=(aluop_i==`EXE_SLT_OP)? 
			((reg1_i[31] && !reg2_i[31]) || //A<0,B>0
			((!reg1_i[31] && !reg2_i[31]) && sum_res[31])|| //A>0,B>0,sum_res>0
			((reg1_i[31] && reg2_i[31]) && sum_res[31]) //A<0,B<0,sum_res>0
			)
			:reg1_i<reg2_i;

assign reg1_i_not=~reg1_i;

//mem
assign aluop_o=aluop_i;
assign mem_addr_o=reg1_i+{{16{inst_i[15]}},inst_i[15:0]};
assign reg2_o=reg2_i;


//multi
assign opdata1_mult=(((aluop_i==`EXE_MUL_OP) ||
		(aluop_i==`EXE_MULT_OP)||
		(aluop_i==`EXE_MADD_OP)||
		(aluop_i==`EXE_MSUB_OP))&& reg1_i[31])?
		((~reg1_i)+1):reg1_i; //if signed multiply and opdata1<0, then opdata1=opdata1_complementary

assign opdata2_mult=(((aluop_i==`EXE_MUL_OP) ||
		(aluop_i==`EXE_MULT_OP)||
		(aluop_i==`EXE_MADD_OP)||
		(aluop_i==`EXE_MSUB_OP))&& reg2_i[31])?
		((~reg2_i)+1):reg2_i;

assign hilo_temp=opdata1_mult*opdata2_mult;


//div_res
always @(*) begin
	if (rst==`RstEnable) begin
		stallreq_for_div<=`NoStop;
		div_opdata1_o<=`ZeroWord;
		div_opdata2_o<=`ZeroWord;
		div_start_o<=1'b0;
		signed_div_o<=1'b0;
	end else if (aluop_i==`EXE_DIV_OP)begin
		if (div_ready_i==1'b0) begin
			div_opdata1_o<=reg1_i;
			div_opdata2_o<=reg2_i;
			div_start_o<=1'b1;
			signed_div_o<=1'b1;
			stallreq_for_div<=`Stop;
		end else if (div_ready_i==1'b1) begin
			div_opdata1_o<=reg1_i;
			div_opdata2_o<=reg2_i;
			div_start_o<=1'b0;
			signed_div_o<=1'b1;
			stallreq_for_div<=`NoStop;
		end

	end else if (aluop_i==`EXE_DIVU_OP) begin
		if (div_ready_i==1'b0) begin
			div_opdata1_o<=reg1_i;
			div_opdata2_o<=reg2_i;
			div_start_o<=1'b1;
			signed_div_o<=1'b0;
			stallreq_for_div<=`Stop;
		end else if (div_ready_i==1'b1) begin
			div_opdata1_o<=reg1_i;
			div_opdata2_o<=reg2_i;
			div_start_o<=1'b0;
			signed_div_o<=1'b0;
			stallreq_for_div<=`NoStop;
		end
	end else begin
		stallreq_for_div<=`NoStop;
		div_opdata1_o<=`ZeroWord;
		div_opdata2_o<=`ZeroWord;
		div_start_o<=1'b0;
		signed_div_o<=1'b0;
	end
end

//mult_res
always @(*) begin
	if (rst==`RstEnable) begin
		mult_res<={`ZeroWord,`ZeroWord};
	end else if ((aluop_i==`EXE_MUL_OP) || (aluop_i==`EXE_MULT_OP)||(aluop_i==`EXE_MADD_OP)||(aluop_i==`EXE_MSUB_OP)) begin
		if (reg1_i[31]^reg2_i[31]==1'b1) begin
			mult_res<=~hilo_temp+1;
		end else begin
			mult_res<=hilo_temp;
		end
	end else begin
		mult_res<=hilo_temp;
	end
end

//hilo bypass
always @(*) begin
	if (rst==`RstEnable) begin
		HI<=`ZeroWord;
		LO<=`ZeroWord;
	end else if (mem_whilo_i==`WriteEnable) begin
		HI<=mem_hi_i;
		LO<=mem_lo_i;
	end else if (wb_whilo_i==`WriteEnable) begin
		HI<=wb_hi_i;
		LO<=wb_lo_i;	
	end else begin
		HI<=hi_i;
		LO<=lo_i;
	end
end

//hilo output
always@(*) begin
	if (rst==`RstEnable) begin
		hi_o<=`ZeroWord;
		lo_o<=`ZeroWord;
		whilo_o<=`WriteDisable;
	end else if ((aluop_i==`EXE_MADD_OP)||(aluop_i==`EXE_MADDU_OP)||(aluop_i==`EXE_MSUB_OP)||(aluop_i==`EXE_MSUBU_OP)) begin
		whilo_o<=`WriteEnable;
		hi_o<=hilo_temp1[63:32];
		lo_o<=hilo_temp1[31:0];
	end else if ((aluop_i==`EXE_MULT_OP)||(aluop_i==`EXE_MULTU_OP)) begin
		whilo_o<=`WriteEnable;
		hi_o<=mult_res[63:32];
		lo_o<=mult_res[31:0];
	end else if ((aluop_i==`EXE_DIV_OP)||(aluop_i==`EXE_DIVU_OP)) begin
		whilo_o<=`WriteEnable;
		hi_o<=div_res_i[63:32];
		lo_o<=div_res_i[31:0];
	end else if (aluop_i==`EXE_MTHI_OP) begin
		hi_o<=reg1_i;
		lo_o<=LO;
		whilo_o<=`WriteEnable;
	end else if (aluop_i==`EXE_MTLO_OP) begin
		hi_o<=HI;
		lo_o<=reg1_i;
		whilo_o<=`WriteEnable;
	end else begin
		hi_o<=`ZeroWord;
		lo_o<=`ZeroWord;
		whilo_o<=`WriteDisable;
	end
end

//madd,msub,maddu,msubu
always @ (*) begin
	if (rst==`RstEnable) begin
		cnt_o<=2'b00;
		hilo_temp_o<={`ZeroWord,`ZeroWord};
		stallreq_for_madd_temp=`NoStop;
	end else begin
		case (aluop_i)
			`EXE_MADD_OP,`EXE_MADDU_OP:begin
				if (cnt_i==2'b00) begin
					cnt_o<=2'b01;
					stallreq_for_madd_temp<=`Stop;
					hilo_temp_o<=mult_res;
					hilo_temp1<={`ZeroWord,`ZeroWord};
				end else if (cnt_i==2'b01) begin
					cnt_o<=2'b10;
					stallreq_for_madd_temp<=`NoStop;
					hilo_temp_o<={`ZeroWord,`ZeroWord};
					hilo_temp1<=hilo_temp_i+{HI,LO};
				end
			end
			`EXE_MSUB_OP,`EXE_MSUBU_OP:begin
				if (cnt_i==2'b00) begin
					cnt_o<=2'b01;
					stallreq_for_madd_temp<=`Stop;
					hilo_temp_o<=(~mult_res+1);
					hilo_temp1<={`ZeroWord,`ZeroWord};
				end else if (cnt_i==2'b01) begin
					cnt_o<=2'b10;
					stallreq_for_madd_temp<=`NoStop;
					hilo_temp_o<={`ZeroWord,`ZeroWord};
					hilo_temp1<=hilo_temp_i+{HI,LO};
				end
			end
			default:begin
				cnt_o<=2'b00;
				stallreq_for_madd_temp<=`NoStop;
				hilo_temp_o<={`ZeroWord,`ZeroWord};
				hilo_temp1<={`ZeroWord,`ZeroWord};
			end
		endcase
	end
end

always @ (*) begin
	if (rst==`RstEnable) begin
		wdata_o<=`ZeroWord;
		wreg_o<=`WriteDisable;
		wd_o<=`NOPRegAddr;
	end else begin
		case (aluop_i)
			//Arithmatic
			`EXE_SLT_OP,`EXE_SLTU_OP:begin
				arithmetic_res<=reg1_lt_reg2;
				end
			
			`EXE_ADD_OP,`EXE_ADDU_OP,`EXE_ADDI_OP,`EXE_ADDIU_OP:begin
				arithmetic_res<=sum_res;
				end

			`EXE_SUB_OP,`EXE_SUBU_OP:begin
				arithmetic_res<=sum_res;
				end
			`EXE_CLZ_OP:begin
				arithmetic_res<=(reg1_i[31]? 0:
						reg1_i[30]? 1:
						reg1_i[29]? 2:
						reg1_i[28]? 3:
						reg1_i[27]? 4:
						reg1_i[26]? 5:
						reg1_i[25]? 6:
						reg1_i[24]? 7:
						reg1_i[23]? 8:
						reg1_i[22]? 9:
						reg1_i[21]? 10:
						reg1_i[20]? 11:
						reg1_i[19]? 12:
						reg1_i[18]? 13:
						reg1_i[17]? 14:
						reg1_i[16]? 15:
						reg1_i[15]? 16:
						reg1_i[14]? 17:
						reg1_i[13]? 18:
						reg1_i[12]? 19:
						reg1_i[11]? 20:
						reg1_i[10]? 21:
						reg1_i[9]? 22:
						reg1_i[8]? 23:
						reg1_i[7]? 24:
						reg1_i[6]? 25:
						reg1_i[5]? 26:
						reg1_i[4]? 27:
						reg1_i[3]? 28:
						reg1_i[2]? 29:
						reg1_i[1]? 30:
						reg1_i[0]? 31:32);
				end
			`EXE_CLO_OP:begin
				arithmetic_res<=(reg1_i_not[31]? 0:
						reg1_i_not[30]? 1:
						reg1_i_not[29]? 2:
						reg1_i_not[28]? 3:
						reg1_i_not[27]? 4:
						reg1_i_not[26]? 5:
						reg1_i_not[25]? 6:
						reg1_i_not[24]? 7:
						reg1_i_not[23]? 8:
						reg1_i_not[22]? 9:
						reg1_i_not[21]? 10:
						reg1_i_not[20]? 11:
						reg1_i_not[19]? 12:
						reg1_i_not[18]? 13:
						reg1_i_not[17]? 14:
						reg1_i_not[16]? 15:
						reg1_i_not[15]? 16:
						reg1_i_not[14]? 17:
						reg1_i_not[13]? 18:
						reg1_i_not[12]? 19:
						reg1_i_not[11]? 20:
						reg1_i_not[10]? 21:
						reg1_i_not[9]? 22:
						reg1_i_not[8]? 23:
						reg1_i_not[7]? 24:
						reg1_i_not[6]? 25:
						reg1_i_not[5]? 26:
						reg1_i_not[4]? 27:
						reg1_i_not[3]? 28:
						reg1_i_not[2]? 29:
						reg1_i_not[1]? 30:
						reg1_i_not[0]? 31:32);
				end		
			
			//logic
			`EXE_OR_OP:begin
				logic_out<=reg1_i|reg2_i;
				end
			`EXE_AND_OP:begin
				logic_out<=reg1_i & reg2_i;
				end
			`EXE_XOR_OP:begin
				logic_out<=reg1_i^reg2_i;
				end
			`EXE_NOR_OP:begin
				logic_out<=~(reg1_i|reg2_i);
				end

			//shift
			`EXE_SLL_OP:begin
				shift_out<=reg2_i << reg1_i[4:0];
				end
			`EXE_SRL_OP:begin
				shift_out<=reg2_i >> reg1_i[4:0];
				end
			`EXE_SRA_OP:begin
				shift_out<=({32{reg2_i[31]}} << (6'd32-{1'b0,reg1_i[4:0]}))|reg2_i >> reg1_i[4:0];
				end
			
			//move
			`EXE_MOVZ_OP:begin
				move_res<=reg1_i;
				end
			`EXE_MOVN_OP:begin
				move_res<=reg1_i;
				end
			`EXE_MFHI_OP:begin
				move_res<=HI;
				end
			`EXE_MFLO_OP:begin
				move_res<=LO;
				end
			default: begin
				logic_out<=`ZeroWord;
				shift_out<=`ZeroWord;
				move_res<=`ZeroWord;
				arithmetic_res<=`ZeroWord;
			end
		endcase
		
		case (alusel_i)
			`EXE_RES_JUMP_BRANCH:begin
				wdata_o<=link_address_i;
				end
			`EXE_RES_LOGIC: begin
				wdata_o<=logic_out;
				end
			`EXE_RES_SHIFT:begin
				wdata_o<=shift_out;
				end
			`EXE_RES_MOVE:begin
				wdata_o<=move_res;
				end
			`EXE_RES_ARITHMETIC:begin
				wdata_o<=arithmetic_res;
				end
			`EXE_RES_MUL:begin
				wdata_o<=mult_res[31:0];
				end
			default: begin
				wdata_o<=`ZeroWord;
			end
		endcase
			
		
		wd_o<=wd_i;

		//check overload and disable write
		if (((aluop_i==`EXE_ADD_OP)||(aluop_i==`EXE_ADDI_OP)||(aluop_i==`EXE_SUB_OP))&& ov_sum==1'b1) begin
			wreg_o<=`WriteDisable;
		end else begin
			wreg_o<=wreg_i;
		end
	end
end
endmodule