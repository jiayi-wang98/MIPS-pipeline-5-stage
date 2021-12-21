`include "defines.v"
module id(input wire rst,
		input wire [`InstAddrBus] pc_i,
		input wire [`InstBus]inst_i,
		input wire [`RegBus] reg1_data_i,reg2_data_i,
		input wire [`AluOpBus] ex_aluop_i,
		//bypass from ex
		input wire ex_wreg_i,
		input wire [`RegBus] ex_wdata_i,
		input wire [`RegAddrBus]ex_wd_i,

		//bypass from mem
		input wire mem_wreg_i,
		input wire [`RegBus] mem_wdata_i,
		input wire [`RegAddrBus]mem_wd_i,
		
		//delay slot
		input wire is_in_delay_slot_i,
		output reg next_is_in_delay_slot_o,

		output reg branch_flag_o,
		output reg [`InstAddrBus] branch_target_addr_o,
		output reg is_in_delay_slot_o,
		output reg [`RegBus] link_addr_o,	
		output wire [`RegBus] inst_o,
		output reg [`RegAddrBus] reg1_addr_o,reg2_addr_o,
		output reg reg1_read_o,reg2_read_o,
		output reg [`AluOpBus]aluop_o,
		output reg [`AluSelBus]alusel_o,
		output reg [`RegBus]reg1_o,reg2_o,
		output reg [`RegAddrBus] wd_o,
		output reg wreg_o,
		output reg stallreq
		);

wire [5:0] op =inst_i[31:26];
wire [4:0] op2=inst_i[10:6];
wire [4:0] op4=inst_i[20:16];
wire [5:0] op3=inst_i[5:0];

wire [`InstAddrBus] pc_plus_8,pc_plus_4;
wire [`RegBus] imm_sll2_signed_ext;

//load data hazard
reg stallreq_for_reg1_loadrelate,stallreq_for_reg2_loadrelate;
wire pre_inst_is_load;

assign  pre_inst_is_load=((ex_aluop_i==`EXE_LB_OP)||
			(ex_aluop_i==`EXE_LH_OP)||
			(ex_aluop_i==`EXE_LW_OP)||
			(ex_aluop_i==`EXE_LWL_OP)||
			(ex_aluop_i==`EXE_LWR_OP)||
			(ex_aluop_i==`EXE_LBU_OP)||
			(ex_aluop_i==`EXE_LHU_OP))? 1'b1:1'b0;

reg[`RegBus] imm;

reg inst_valid;

assign stallreq=stallreq_for_reg1_loadrelate|stallreq_for_reg2_loadrelate;

//jump
assign pc_plus_8=pc_i+8;
assign pc_plus_4=pc_i+4;
assign imm_sll2_signed_ext={{14{inst_i[15]}},inst_i[15:0],2'b00};

assign inst_o=inst_i;

always @ (*) begin
	if (rst==`RstEnable) begin
		aluop_o<=`EXE_NOP_OP;
		alusel_o<=`EXE_RES_NOP;
		wd_o<=`NOPRegAddr;
		wreg_o<=`WriteDisable;
		inst_valid<=`InstValid;
		reg1_addr_o<=`NOPRegAddr;
		reg2_addr_o<=`NOPRegAddr;
		reg1_read_o<=`ReadDisable;
		reg2_read_o<=`ReadDisable;
		link_addr_o<=`ZeroWord;
		branch_target_addr_o<=`ZeroWord;
		branch_flag_o<=1'b0;
		next_is_in_delay_slot_o<=1'b0;
		imm<=`ZeroWord;
	end else begin
		reg1_addr_o<=inst_i[25:21];
		reg2_addr_o<=inst_i[20:16];
		imm<=`ZeroWord;
		wd_o=inst_i[15:11];
		link_addr_o<=`ZeroWord;
		branch_target_addr_o<=`ZeroWord;
		branch_flag_o<=1'b0;
		next_is_in_delay_slot_o<=1'b0;
		case (op)
			`EXE_SPECIAL_INST: begin
				case (op2)
					5'b00000:begin
						case (op3)
							`EXE_JR:begin	
								aluop_o<=`EXE_JR_OP;
								alusel_o<=`EXE_RES_JUMP_BRANCH;
								wreg_o=`WriteDisable;
								inst_valid<=`InstValid;
								reg1_read_o<=`ReadEnable;
								reg2_read_o<=`ReadDisable;
								link_addr_o<=`ZeroWord;
								branch_target_addr_o<=reg1_o;
								branch_flag_o<=1'b1;
								next_is_in_delay_slot_o<=1'b1;
								end	
							`EXE_JALR:begin	
								aluop_o<=`EXE_JALR_OP;
								alusel_o<=`EXE_RES_JUMP_BRANCH;
								wreg_o=`WriteEnable;
								wd_o<=inst_i[15:11];
								inst_valid<=`InstValid;
								reg1_read_o<=`ReadEnable;
								reg2_read_o<=`ReadDisable;
								link_addr_o<=pc_plus_8;
								branch_target_addr_o<=reg1_o;
								branch_flag_o<=1'b1;
								next_is_in_delay_slot_o<=1'b1;
								end	
							`EXE_DIV:begin	
								aluop_o<=`EXE_DIV_OP;
								alusel_o<=`EXE_RES_NOP;
								wreg_o=`WriteDisable;
								inst_valid<=`InstValid;
								reg1_read_o<=`ReadEnable;
								reg2_read_o<=`ReadEnable;
								end	
							`EXE_DIVU:begin	
								aluop_o<=`EXE_DIVU_OP;
								alusel_o<=`EXE_RES_NOP;
								wreg_o=`WriteDisable;
								inst_valid<=`InstValid;
								reg1_read_o<=`ReadEnable;
								reg2_read_o<=`ReadEnable;
								end		
							`EXE_ADD:begin	
								aluop_o<=`EXE_ADD_OP;
								alusel_o<=`EXE_RES_ARITHMETIC;
								wreg_o=`WriteEnable;
								inst_valid<=`InstValid;
								reg1_read_o<=`ReadEnable;
								reg2_read_o<=`ReadEnable;
								end
							`EXE_ADDU:begin	
								aluop_o<=`EXE_ADDU_OP;
								alusel_o<=`EXE_RES_ARITHMETIC;
								wreg_o=`WriteEnable;
								inst_valid<=`InstValid;
								reg1_read_o<=`ReadEnable;
								reg2_read_o<=`ReadEnable;
								end
							`EXE_SUB:begin	
								aluop_o<=`EXE_SUB_OP;
								alusel_o<=`EXE_RES_ARITHMETIC;
								wreg_o=`WriteEnable;
								inst_valid<=`InstValid;
								reg1_read_o<=`ReadEnable;
								reg2_read_o<=`ReadEnable;
								end
							`EXE_SUBU:begin	
								aluop_o<=`EXE_SUBU_OP;
								alusel_o<=`EXE_RES_ARITHMETIC;
								wreg_o=`WriteEnable;
								inst_valid<=`InstValid;
								reg1_read_o<=`ReadEnable;
								reg2_read_o<=`ReadEnable;
								end
							`EXE_SLT:begin	
								aluop_o<=`EXE_SLT_OP;
								alusel_o<=`EXE_RES_ARITHMETIC;
								wreg_o=`WriteEnable;
								inst_valid<=`InstValid;
								reg1_read_o<=`ReadEnable;
								reg2_read_o<=`ReadEnable;
								end
							`EXE_SLTU:begin	
								aluop_o<=`EXE_SLTU_OP;
								alusel_o<=`EXE_RES_ARITHMETIC;
								wreg_o=`WriteEnable;
								inst_valid<=`InstValid;
								reg1_read_o<=`ReadEnable;
								reg2_read_o<=`ReadEnable;
								end

							`EXE_MULT:begin	
								aluop_o<=`EXE_MULT_OP;
								alusel_o<=`EXE_RES_NOP;
								wreg_o=`WriteDisable;
								inst_valid<=`InstValid;
								reg1_read_o<=`ReadEnable;
								reg2_read_o<=`ReadEnable;
								end

							`EXE_MULTU:begin	
								aluop_o<=`EXE_MULTU_OP;
								alusel_o<=`EXE_RES_NOP;
								wreg_o=`WriteDisable;
								inst_valid<=`InstValid;
								reg1_read_o<=`ReadEnable;
								reg2_read_o<=`ReadEnable;
								end

							`EXE_MFHI:begin	
								aluop_o<=`EXE_MFHI_OP;
								alusel_o<=`EXE_RES_MOVE;
								wreg_o=`WriteEnable;
								inst_valid<=`InstValid;
								reg1_read_o<=`ReadDisable;
								reg2_read_o<=`ReadDisable;
								end	
							`EXE_MFLO:begin	
								aluop_o<=`EXE_MFLO_OP;
								alusel_o<=`EXE_RES_MOVE;
								wreg_o=`WriteEnable;
								inst_valid<=`InstValid;
								reg1_read_o<=`ReadDisable;
								reg2_read_o<=`ReadDisable;
								end			
							`EXE_MTHI:begin	
								aluop_o<=`EXE_MTHI_OP;
								alusel_o<=`EXE_RES_NOP;
								wreg_o=`WriteDisable;
								inst_valid<=`InstValid;
								reg1_read_o<=`ReadEnable;
								reg2_read_o<=`ReadDisable;
								end		
							`EXE_MTLO:begin	
								aluop_o<=`EXE_MTLO_OP;
								alusel_o<=`EXE_RES_NOP;
								wreg_o=`WriteDisable;
								inst_valid<=`InstValid;
								reg1_read_o<=`ReadEnable;
								reg2_read_o<=`ReadDisable;
								end		
							`EXE_MOVN:begin	
								aluop_o<=`EXE_MOVN_OP;
								alusel_o<=`EXE_RES_MOVE;
								inst_valid<=`InstValid;
								reg1_read_o<=`ReadEnable;
								reg2_read_o<=`ReadEnable;
								if (reg2_o==`ZeroWord) begin
									wreg_o=`WriteDisable;
								end else begin
									wreg_o=`WriteEnable;
									end		
								end
							`EXE_MOVZ:begin	
								aluop_o<=`EXE_MOVZ_OP;
								alusel_o<=`EXE_RES_MOVE;
								inst_valid<=`InstValid;
								reg1_read_o<=`ReadEnable;
								reg2_read_o<=`ReadEnable;
								if (reg2_o!=`ZeroWord) begin
									wreg_o=`WriteDisable;
								end else begin
									wreg_o=`WriteEnable;
									end		
								end
							`EXE_OR:begin	
								aluop_o<=`EXE_OR_OP;
								alusel_o<=`EXE_RES_LOGIC;
								wreg_o=`WriteEnable;
								inst_valid<=`InstValid;
								reg1_read_o<=`ReadEnable;
								reg2_read_o<=`ReadEnable;
								end
							`EXE_AND:begin	
								aluop_o<=`EXE_AND_OP;
								alusel_o<=`EXE_RES_LOGIC;
								wreg_o=`WriteEnable;
								inst_valid<=`InstValid;
								reg1_read_o<=`ReadEnable;
								reg2_read_o<=`ReadEnable;
								end
							`EXE_XOR:begin	
								aluop_o<=`EXE_XOR_OP;
								alusel_o<=`EXE_RES_LOGIC;
								wreg_o=`WriteEnable;
								inst_valid<=`InstValid;
								reg1_read_o<=`ReadEnable;
								reg2_read_o<=`ReadEnable;
								end		
							`EXE_NOR:begin	
								aluop_o<=`EXE_NOR_OP;
								alusel_o<=`EXE_RES_LOGIC;
								wreg_o=`WriteEnable;
								inst_valid<=`InstValid;
								reg1_read_o<=`ReadEnable;
								reg2_read_o<=`ReadEnable;
								end	
							`EXE_SLLV:begin	
								aluop_o<=`EXE_SLL_OP;
								alusel_o<=`EXE_RES_SHIFT;
								wreg_o=`WriteEnable;
								inst_valid<=`InstValid;
								reg1_read_o<=`ReadEnable;
								reg2_read_o<=`ReadEnable;
								end	
							`EXE_SRLV:begin	
								aluop_o<=`EXE_SRL_OP;
								alusel_o<=`EXE_RES_SHIFT;
								wreg_o=`WriteEnable;
								inst_valid<=`InstValid;
								reg1_read_o<=`ReadEnable;
								reg2_read_o<=`ReadEnable;
								end
							`EXE_SRAV:begin	
								aluop_o<=`EXE_SRA_OP;
								alusel_o<=`EXE_RES_SHIFT;
								wreg_o=`WriteEnable;
								inst_valid<=`InstValid;
								reg1_read_o<=`ReadEnable;
								reg2_read_o<=`ReadEnable;
								end	
							`EXE_SYNC:begin	
								aluop_o<=`EXE_NOP_OP;
								alusel_o<=`EXE_RES_NOP;
								wreg_o=`WriteDisable;
								inst_valid<=`InstValid;
								reg1_read_o<=`ReadDisable;
								reg2_read_o<=`ReadEnable;
								end	
							default: begin
								end
						endcase
					end
					default:begin
						end
				endcase
			end

			`EXE_REGIMM_INST:begin
				case (op4) 
					`EXE_BGEZ:begin
						aluop_o<=`EXE_BGEZ_OP;
						alusel_o<=`EXE_RES_JUMP_BRANCH;
						wreg_o=`WriteDisable;
						inst_valid<=`InstValid;
						reg1_read_o<=`ReadEnable;
						reg2_read_o<=`ReadDisable;
						link_addr_o<=`ZeroWord;
						if (reg1_o[31]==1'b0) begin
							branch_target_addr_o<=pc_plus_4+imm_sll2_signed_ext;
							branch_flag_o<=1'b1;
							next_is_in_delay_slot_o<=1'b1;
							end
						end	
					`EXE_BGEZAL:begin
						aluop_o<=`EXE_BGEZAL_OP;
						alusel_o<=`EXE_RES_JUMP_BRANCH;
						wreg_o=`WriteEnable;
						inst_valid<=`InstValid;
						reg1_read_o<=`ReadEnable;
						reg2_read_o<=`ReadDisable;
						link_addr_o<=pc_plus_8;
						wd_o<=5'b11111;
						if (reg1_o[31]==1'b0) begin
							branch_target_addr_o<=pc_plus_4+imm_sll2_signed_ext;
							branch_flag_o<=1'b1;
							next_is_in_delay_slot_o<=1'b1;
							end
						end	
					`EXE_BLTZ:begin
						aluop_o<=`EXE_BLTZ_OP;
						alusel_o<=`EXE_RES_JUMP_BRANCH;
						wreg_o=`WriteDisable;
						inst_valid<=`InstValid;
						reg1_read_o<=`ReadEnable;
						reg2_read_o<=`ReadDisable;
						link_addr_o<=`ZeroWord;
						if (reg1_o[31]==1'b1) begin
							branch_target_addr_o<=pc_plus_4+imm_sll2_signed_ext;
							branch_flag_o<=1'b1;
							next_is_in_delay_slot_o<=1'b1;
							end
						end	
					`EXE_BLTZAL:begin
						aluop_o<=`EXE_BLTZAL_OP;
						alusel_o<=`EXE_RES_JUMP_BRANCH;
						wreg_o=`WriteEnable;
						inst_valid<=`InstValid;
						reg1_read_o<=`ReadEnable;
						reg2_read_o<=`ReadDisable;
						link_addr_o<=pc_plus_8;
						wd_o<=5'b11111;
						if (reg1_o[31]==1'b1) begin
							branch_target_addr_o<=pc_plus_4+imm_sll2_signed_ext;
							branch_flag_o<=1'b1;
							next_is_in_delay_slot_o<=1'b1;
							end
						end	
					default:begin
						end
				endcase
				end	
			`EXE_SPECIAL2_INST:begin
				case (op3) 
					`EXE_CLZ:begin
						aluop_o<=`EXE_CLZ_OP;
						alusel_o<=`EXE_RES_ARITHMETIC;
						wreg_o=`WriteEnable;
						inst_valid<=`InstValid;
						reg1_read_o<=`ReadEnable;
						reg2_read_o<=`ReadDisable;
						end
					`EXE_CLO:begin
						aluop_o<=`EXE_CLO_OP;
						alusel_o<=`EXE_RES_ARITHMETIC;
						wreg_o=`WriteEnable;
						inst_valid<=`InstValid;
						reg1_read_o<=`ReadEnable;
						reg2_read_o<=`ReadDisable;
						end	
					`EXE_MUL:begin
						aluop_o<=`EXE_MUL_OP;
						alusel_o<=`EXE_RES_MUL;
						wreg_o=`WriteEnable;
						inst_valid<=`InstValid;
						reg1_read_o<=`ReadEnable;
						reg2_read_o<=`ReadEnable;
						end	
					`EXE_MADD:begin
						aluop_o<=`EXE_MADD_OP;
						alusel_o<=`EXE_RES_MUL;
						wreg_o=`WriteDisable;
						inst_valid<=`InstValid;
						reg1_read_o<=`ReadEnable;
						reg2_read_o<=`ReadEnable;
						end	
					`EXE_MADDU:begin
						aluop_o<=`EXE_MADDU_OP;
						alusel_o<=`EXE_RES_MUL;
						wreg_o=`WriteDisable;
						inst_valid<=`InstValid;
						reg1_read_o<=`ReadEnable;
						reg2_read_o<=`ReadEnable;
						end	
					`EXE_MSUB:begin
						aluop_o<=`EXE_MSUB_OP;
						alusel_o<=`EXE_RES_MUL;
						wreg_o=`WriteDisable;
						inst_valid<=`InstValid;
						reg1_read_o<=`ReadEnable;
						reg2_read_o<=`ReadEnable;
						end	
					`EXE_MSUBU:begin
						aluop_o<=`EXE_MSUBU_OP;
						alusel_o<=`EXE_RES_MUL;
						wreg_o=`WriteDisable;
						inst_valid<=`InstValid;
						reg1_read_o<=`ReadEnable;
						reg2_read_o<=`ReadEnable;
						end	
					default:begin
						end
				endcase
				end	

			`EXE_LB:begin
				aluop_o<=`EXE_LB_OP;
				alusel_o<=`EXE_RES_LOAD_STORE;
				wreg_o=`WriteEnable;
				inst_valid<=`InstValid;
				reg1_read_o<=`ReadEnable;
				reg2_read_o<=`ReadDisable;
				wd_o<=inst_i[20:16];
				end	
			`EXE_LBU:begin
				aluop_o<=`EXE_LBU_OP;
				alusel_o<=`EXE_RES_LOAD_STORE;
				wreg_o=`WriteEnable;
				inst_valid<=`InstValid;
				reg1_read_o<=`ReadEnable;
				reg2_read_o<=`ReadDisable;
				wd_o<=inst_i[20:16];
				end	
			`EXE_LH:begin
				aluop_o<=`EXE_LH_OP;
				alusel_o<=`EXE_RES_LOAD_STORE;
				wreg_o=`WriteEnable;
				inst_valid<=`InstValid;
				reg1_read_o<=`ReadEnable;
				reg2_read_o<=`ReadDisable;
				wd_o<=inst_i[20:16];
				end	
			`EXE_LHU:begin
				aluop_o<=`EXE_LHU_OP;
				alusel_o<=`EXE_RES_LOAD_STORE;
				wreg_o=`WriteEnable;
				inst_valid<=`InstValid;
				reg1_read_o<=`ReadEnable;
				reg2_read_o<=`ReadDisable;
				wd_o<=inst_i[20:16];
				end	
			`EXE_LW:begin
				aluop_o<=`EXE_LW_OP;
				alusel_o<=`EXE_RES_LOAD_STORE;
				wreg_o=`WriteEnable;
				inst_valid<=`InstValid;
				reg1_read_o<=`ReadEnable;
				reg2_read_o<=`ReadDisable;
				wd_o<=inst_i[20:16];
				end	
			`EXE_LWL:begin
				aluop_o<=`EXE_LWL_OP;
				alusel_o<=`EXE_RES_LOAD_STORE;
				wreg_o=`WriteEnable;
				inst_valid<=`InstValid;
				reg1_read_o<=`ReadEnable;
				reg2_read_o<=`ReadEnable;
				wd_o<=inst_i[20:16];
				end		
			`EXE_LWR:begin
				aluop_o<=`EXE_LWR_OP;
				alusel_o<=`EXE_RES_LOAD_STORE;
				wreg_o=`WriteEnable;
				inst_valid<=`InstValid;
				reg1_read_o<=`ReadEnable;
				reg2_read_o<=`ReadEnable;
				wd_o<=inst_i[20:16];
				end		
			`EXE_SB:begin
				aluop_o<=`EXE_SB_OP;
				alusel_o<=`EXE_RES_LOAD_STORE;
				wreg_o=`WriteDisable;
				inst_valid<=`InstValid;
				reg1_read_o<=`ReadEnable;
				reg2_read_o<=`ReadEnable;
				wd_o<=inst_i[20:16];
				end		
			`EXE_SH:begin
				aluop_o<=`EXE_SH_OP;
				alusel_o<=`EXE_RES_LOAD_STORE;
				wreg_o=`WriteDisable;
				inst_valid<=`InstValid;
				reg1_read_o<=`ReadEnable;
				reg2_read_o<=`ReadEnable;
				wd_o<=inst_i[20:16];
				end	
			`EXE_SW:begin
				aluop_o<=`EXE_SW_OP;
				alusel_o<=`EXE_RES_LOAD_STORE;
				wreg_o=`WriteDisable;
				inst_valid<=`InstValid;
				reg1_read_o<=`ReadEnable;
				reg2_read_o<=`ReadEnable;
				wd_o<=inst_i[20:16];
				end	
			`EXE_SWL:begin
				aluop_o<=`EXE_SWL_OP;
				alusel_o<=`EXE_RES_LOAD_STORE;
				wreg_o=`WriteDisable;
				inst_valid<=`InstValid;
				reg1_read_o<=`ReadEnable;
				reg2_read_o<=`ReadEnable;
				wd_o<=inst_i[20:16];
				end	
			`EXE_SWR:begin
				aluop_o<=`EXE_SWR_OP;
				alusel_o<=`EXE_RES_LOAD_STORE;
				wreg_o=`WriteDisable;
				inst_valid<=`InstValid;
				reg1_read_o<=`ReadEnable;
				reg2_read_o<=`ReadEnable;
				wd_o<=inst_i[20:16];
				end	
			`EXE_J:begin
				aluop_o<=`EXE_J_OP;
				alusel_o<=`EXE_RES_JUMP_BRANCH;
				wreg_o=`WriteDisable;
				inst_valid<=`InstValid;
				reg1_read_o<=`ReadDisable;
				reg2_read_o<=`ReadDisable;
				link_addr_o<=`ZeroWord;
				branch_target_addr_o<={pc_plus_4[31:28],inst_i[25:0],2'b00};
				branch_flag_o<=1'b1;
				next_is_in_delay_slot_o<=1'b1;
				end	
			`EXE_JAL:begin
				aluop_o<=`EXE_JAL_OP;
				alusel_o<=`EXE_RES_JUMP_BRANCH;
				wreg_o=`WriteEnable;
				wd_o<=5'b11111;
				inst_valid<=`InstValid;
				reg1_read_o<=`ReadDisable;
				reg2_read_o<=`ReadDisable;
				link_addr_o<=pc_plus_8;
				branch_target_addr_o<={pc_plus_4[31:28],inst_i[25:0],2'b00};
				branch_flag_o<=1'b1;
				next_is_in_delay_slot_o<=1'b1;
				end	
			`EXE_BEQ:begin
				aluop_o<=`EXE_BEQ_OP;
				alusel_o<=`EXE_RES_JUMP_BRANCH;
				wreg_o=`WriteDisable;
				inst_valid<=`InstValid;
				reg1_read_o<=`ReadEnable;
				reg2_read_o<=`ReadEnable;
				if (reg1_o==reg2_o) begin
					branch_target_addr_o<=pc_plus_4+imm_sll2_signed_ext;
					branch_flag_o<=1'b1;
					next_is_in_delay_slot_o<=1'b1;
					link_addr_o<=`ZeroWord;
					end
				end	
			`EXE_BGTZ:begin
				aluop_o<=`EXE_BGTZ_OP;
				alusel_o<=`EXE_RES_JUMP_BRANCH;
				wreg_o=`WriteDisable;
				inst_valid<=`InstValid;
				reg1_read_o<=`ReadEnable;
				reg2_read_o<=`ReadDisable;
				if (reg1_o[31]==1'b0 &&reg1_o!=`ZeroWord) begin
					branch_target_addr_o<=pc_plus_4+imm_sll2_signed_ext;
					branch_flag_o<=1'b1;
					next_is_in_delay_slot_o<=1'b1;
					link_addr_o<=`ZeroWord;
					end
				end	
			`EXE_BLEZ:begin
				aluop_o<=`EXE_BLEZ_OP;
				alusel_o<=`EXE_RES_JUMP_BRANCH;
				wreg_o=`WriteDisable;
				inst_valid<=`InstValid;
				reg1_read_o<=`ReadEnable;
				reg2_read_o<=`ReadDisable;
				if (reg1_o[31]==1'b1 ||reg1_o==`ZeroWord) begin
					branch_target_addr_o<=pc_plus_4+imm_sll2_signed_ext;
					branch_flag_o<=1'b1;
					next_is_in_delay_slot_o<=1'b1;
					link_addr_o<=`ZeroWord;
					end
				end	
			`EXE_BNE:begin
				aluop_o<=`EXE_BNE_OP;
				alusel_o<=`EXE_RES_JUMP_BRANCH;
				wreg_o=`WriteDisable;
				inst_valid<=`InstValid;
				reg1_read_o<=`ReadEnable;
				reg2_read_o<=`ReadEnable;
				if (reg1_o==reg2_o) begin
					branch_target_addr_o<=pc_plus_4+imm_sll2_signed_ext;
					branch_flag_o<=1'b1;
					next_is_in_delay_slot_o<=1'b1;
					link_addr_o<=`ZeroWord;
					end
				end	
			`EXE_SLTI:begin
				aluop_o<=`EXE_SLT_OP;
				alusel_o<=`EXE_RES_ARITHMETIC;
				wd_o<=inst_i[20:16];
				wreg_o<=`WriteEnable;
				inst_valid<=`InstInvalid;
				reg1_read_o<=`ReadEnable;
				reg2_read_o<=`ReadDisable;
				imm<={{16{inst_i[15]}},inst_i[15:0]};
				end

			`EXE_SLTIU:begin
				aluop_o<=`EXE_SLTU_OP;
				alusel_o<=`EXE_RES_ARITHMETIC;
				wd_o<=inst_i[20:16];
				wreg_o<=`WriteEnable;
				inst_valid<=`InstInvalid;
				reg1_read_o<=`ReadEnable;
				reg2_read_o<=`ReadDisable;
				imm<={{16{inst_i[15]}},inst_i[15:0]};
				end

			`EXE_ADDI:begin
				aluop_o<=`EXE_ADDI_OP;
				alusel_o<=`EXE_RES_ARITHMETIC;
				wd_o<=inst_i[20:16];
				wreg_o<=`WriteEnable;
				inst_valid<=`InstInvalid;
				reg1_read_o<=`ReadEnable;
				reg2_read_o<=`ReadDisable;
				imm<={{16{inst_i[15]}},inst_i[15:0]};
				end

			`EXE_ADDIU:begin
				aluop_o<=`EXE_ADDIU_OP;
				alusel_o<=`EXE_RES_ARITHMETIC;
				wd_o<=inst_i[20:16];
				wreg_o<=`WriteEnable;
				inst_valid<=`InstInvalid;
				reg1_read_o<=`ReadEnable;
				reg2_read_o<=`ReadDisable;
				imm<={{16{inst_i[15]}},inst_i[15:0]};
				end

			`EXE_ORI:begin
				aluop_o<=`EXE_OR_OP;
				alusel_o<=`EXE_RES_LOGIC;
				wd_o<=inst_i[20:16];
				wreg_o<=`WriteEnable;
				inst_valid<=`InstInvalid;
				reg1_read_o<=`ReadEnable;
				reg2_read_o<=`ReadDisable;
				imm<={16'h0,inst_i[15:0]};
				end
			`EXE_ANDI:begin
				aluop_o<=`EXE_AND_OP;
				alusel_o<=`EXE_RES_LOGIC;
				wd_o<=inst_i[20:16];
				wreg_o<=`WriteEnable;
				inst_valid<=`InstInvalid;
				reg1_read_o<=`ReadEnable;
				reg2_read_o<=`ReadDisable;
				imm<={16'h0,inst_i[15:0]};
				end
			`EXE_XORI:begin
				aluop_o<=`EXE_XOR_OP;
				alusel_o<=`EXE_RES_LOGIC;
				wd_o<=inst_i[20:16];
				wreg_o<=`WriteEnable;
				inst_valid<=`InstInvalid;
				reg1_read_o<=`ReadEnable;
				reg2_read_o<=`ReadDisable;
				imm<={16'h0,inst_i[15:0]};
				end
			`EXE_LUI:begin
				aluop_o<=`EXE_OR_OP;
				alusel_o<=`EXE_RES_LOGIC;
				wd_o<=inst_i[20:16];
				wreg_o<=`WriteEnable;
				inst_valid<=`InstInvalid;
				reg1_read_o<=`ReadEnable;
				reg2_read_o<=`ReadDisable;
				imm<={inst_i[15:0],16'h0};
				end
			`EXE_PREF:begin
				aluop_o<=`EXE_NOP_OP;
				alusel_o<=`EXE_RES_NOP;
				wd_o<=inst_i[20:16];
				wreg_o<=`WriteDisable;
				inst_valid<=`InstValid;
				reg1_read_o<=`ReadDisable;
				reg2_read_o<=`ReadDisable;
				imm<={16'h0,inst_i[15:0]};
				end
			default:begin
				aluop_o<=`EXE_NOP_OP;
				alusel_o<=`EXE_RES_NOP;
				wd_o<=`NOPRegAddr;
				wreg_o<=`WriteDisable;
				inst_valid<=`InstInvalid;
				reg1_read_o<=`ReadDisable;
				reg2_read_o<=`ReadDisable;
				imm<=`ZeroWord;
				branch_target_addr_o<=`ZeroWord;
				branch_flag_o<=1'b0;
				next_is_in_delay_slot_o<=1'b0;
				link_addr_o<=`ZeroWord;
				end
		endcase

		if (inst_i[31:21]==11'b00000000000)begin
			case (op3)
				`EXE_SLL:begin
					aluop_o<=`EXE_SLL_OP;
					alusel_o<=`EXE_RES_SHIFT;
					wd_o<=inst_i[15:11];
					wreg_o<=`WriteEnable;
					inst_valid<=`InstValid;
					reg1_read_o<=`ReadDisable;
					reg2_read_o<=`ReadEnable;
					imm[4:0]<=inst_i[10:6];
					end
				`EXE_SRL:begin
					aluop_o<=`EXE_SRL_OP;
					alusel_o<=`EXE_RES_SHIFT;
					wd_o<=inst_i[15:11];
					wreg_o<=`WriteEnable;
					inst_valid<=`InstValid;
					reg1_read_o<=`ReadDisable;
					reg2_read_o<=`ReadEnable;
					imm[4:0]<=inst_i[10:6];
					end
				`EXE_SRA:begin
					aluop_o<=`EXE_SRA_OP;
					alusel_o<=`EXE_RES_SHIFT;
					wd_o<=inst_i[15:11];
					wreg_o<=`WriteEnable;
					inst_valid<=`InstValid;
					reg1_read_o<=`ReadDisable;
					reg2_read_o<=`ReadEnable;
					imm[4:0]<=inst_i[10:6];
					end
				default:begin
					end
			endcase
		end
	end
end

always @ (*) begin
	stallreq_for_reg1_loadrelate<=`NoStop;
	if (rst==`RstEnable) begin
		reg1_o<=`ZeroWord;
	end else if (reg1_read_o==`ReadEnable) begin
		if (pre_inst_is_load && reg1_addr_o==ex_wd_i) begin
			stallreq_for_reg1_loadrelate<=`Stop;
		end else if (reg1_addr_o==ex_wd_i && ex_wreg_i==`WriteEnable) begin //bypass from mem
			reg1_o<=ex_wdata_i;
		end else if (reg1_addr_o==mem_wd_i && mem_wreg_i==`WriteEnable) begin //bypass from ex
			reg1_o<=mem_wdata_i;
		end else begin
			reg1_o<=reg1_data_i;
		end

	end else if (reg1_read_o==`ReadDisable) begin
		reg1_o<=imm;
	end else begin
		reg1_o<=`ZeroWord;
	end
end

always @ (*) begin
	if (rst==`RstEnable) begin
		is_in_delay_slot_o<=1'b0;
	end else begin
		is_in_delay_slot_o<=is_in_delay_slot_i;
	end
end

always @ (*) begin
	stallreq_for_reg2_loadrelate<=`NoStop;
	if (rst==`RstEnable) begin
		reg2_o<=`ZeroWord;
	end else if (reg2_read_o==`ReadEnable) begin
		if (pre_inst_is_load && reg2_addr_o==ex_wd_i) begin
			stallreq_for_reg2_loadrelate<=`Stop;
		end else if (reg2_addr_o==ex_wd_i && ex_wreg_i==`WriteEnable) begin //bypass from mem
			reg2_o<=ex_wdata_i;
		end else if (reg2_addr_o==mem_wd_i && mem_wreg_i==`WriteEnable) begin //bypass from ex
			reg2_o<=mem_wdata_i;
		end else begin
			reg2_o<=reg2_data_i;
		end

	end else if (reg2_read_o==`ReadDisable) begin
		reg2_o<=imm;
	end else begin
		reg2_o<=`ZeroWord;
	end
end
endmodule














