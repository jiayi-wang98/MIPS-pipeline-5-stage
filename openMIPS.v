`include "defines.v"

module openMIPS(input wire clk,rst,
		input wire[`RegBus] rom_data_i,
		input wire [`RegBus] ram_data_o,
		//ram
		output wire [`RegBus] ram_addr_i,
		output wire ram_we,
		output wire ram_ce,
		output wire [3:0] ram_sel,
		output wire [`RegBus] ram_data_i,
		output wire [`RegBus] rom_addr_o,
		output wire rom_ce_o);

	//pc if_id id
	wire[`InstAddrBus] pc;
	wire[`InstAddrBus] id_pc_i;
	wire[`InstBus] id_inst_i;
	wire branch_flag;
	wire [`InstBus]	branch_target_addr;

  	assign rom_addr_o = pc;

	//id id_ex
	wire[`AluOpBus] id_aluop_o;
	wire[`AluSelBus] id_alusel_o;
	wire[`RegBus] id_reg1_o;
	wire[`RegBus] id_reg2_o;
	wire id_wreg_o;
	wire[`RegAddrBus] id_wd_o;
	wire id_is_in_delay_slot_i,id_is_in_delay_slot_o,next_is_in_delay_slot_o;	
	wire[`RegBus] id_link_addr_o;
	wire [`RegBus] id_inst_o;
	//id_ex ex
	wire[`AluOpBus] ex_aluop_i;
	wire[`AluSelBus] ex_alusel_i;
	wire[`RegBus] ex_reg1_i;
	wire[`RegBus] ex_reg2_i;
	wire ex_wreg_i;
	wire[`RegAddrBus] ex_wd_i;
	wire ex_is_in_delay_slot_i;
	wire [`RegBus] ex_link_addr_i;
	wire [`RegBus] ex_inst_i;
	//ex ex_mem
	wire ex_wreg_o;
	wire[`RegAddrBus] ex_wd_o;
	wire[`RegBus] ex_wdata_o;
	wire[`RegBus] ex_hi_o;
	wire[`RegBus] ex_lo_o;
	wire ex_whilo_o;	
	wire[`AluOpBus] ex_aluop_o;
	wire[`RegBus] ex_mem_addr_o;
	wire[`RegBus] ex_reg2_o;
	//ex_mem mem
	wire mem_wreg_i;
	wire[`RegAddrBus] mem_wd_i;
	wire[`RegBus] mem_wdata_i;
	wire[`RegBus] mem_hi_i;
	wire[`RegBus] mem_lo_i;
	wire mem_whilo_i;
	wire[`AluOpBus] mem_aluop_i;
	wire[`RegBus] mem_mem_addr_i;
	wire[`RegBus] mem_reg2_i;
	//mem mem_wb
	wire mem_wreg_o;
	wire[`RegAddrBus] mem_wd_o;
	wire[`RegBus] mem_wdata_o;
	wire[`RegBus] mem_hi_o;
	wire[`RegBus] mem_lo_o;
	wire mem_whilo_o;
	

	
	//mem_wb reg
	wire wb_wreg_i;
	wire[`RegAddrBus] wb_wd_i;
	wire[`RegBus] wb_wdata_i;

	//mem_wb hilo
	wire wb_whilo_i;
	wire[`RegBus] wb_hi_i;
	wire[`RegBus] wb_lo_i;

	//hilo ex
	wire[`RegBus] hilo_hi_o;
	wire[`RegBus] hilo_lo_o;

	//id reg
  	wire reg1_read;
  	wire reg2_read;
  	wire[`RegBus] reg1_data;
  	wire[`RegBus] reg2_data;
  	wire[`RegAddrBus] reg1_addr;
  	wire[`RegAddrBus] reg2_addr;

	//ctrl
	wire [5:0] stall;
	wire stallreq_from_ex;
	wire stallreq_from_id;

	//madd,msub
	wire [1:0] ex_cnt_o,ex_cnt_i;
	wire [`DoubleRegBus] ex_hilo_temp_o,ex_hilo_temp_i;

	pc_reg pc_reg0(
		.clk(clk),
		.rst(rst),
		.stall(stall),
		.branch_flag_i(branch_flag),
		.branch_target_address_i(branch_target_addr),
		.pc(pc),
		.ce(rom_ce_o)	
			
	);
	
	if_id if_id0(.clk(clk),.rst(rst),
		.if_pc(pc),
		.if_inst(rom_data_i),
		.stall(stall),
		.id_pc(id_pc_i),
		.id_inst(id_inst_i)
	);


	id id0(.rst(rst),
		.pc_i(id_pc_i),
		.inst_i(id_inst_i),
		.reg1_data_i(reg1_data),.reg2_data_i(reg2_data),
		.ex_aluop_i(ex_aluop_o),
		.ex_wreg_i(ex_wreg_o),
		.ex_wdata_i(ex_wdata_o),
		.ex_wd_i(ex_wd_o),
		.mem_wreg_i(mem_wreg_o),
		.mem_wdata_i(mem_wdata_o),
		.mem_wd_i(mem_wd_o),
		.is_in_delay_slot_i(id_is_in_delay_slot_i),
		.next_is_in_delay_slot_o(next_is_in_delay_slot_o),

		.branch_flag_o(branch_flag),
		.branch_target_addr_o(branch_target_addr),
		.is_in_delay_slot_o(id_is_in_delay_slot_o),
		.link_addr_o(id_link_addr_o),	
		.inst_o(id_inst_o),
		.reg1_addr_o(reg1_addr),.reg2_addr_o(reg2_addr),
		.reg1_read_o(reg1_read),.reg2_read_o(reg2_read),
		.aluop_o(id_aluop_o),
		.alusel_o(id_alusel_o),
		.reg1_o(id_reg1_o),.reg2_o(id_reg2_o),
		.wd_o(id_wd_o),
		.wreg_o(id_wreg_o),
		.stallreq(stallreq_from_id)
	);

	id_ex id_ex0(.clk(clk),.rst(rst),
		.id_aluop(id_aluop_o),
		.id_alusel(id_alusel_o),
		.id_reg1(id_reg1_o),.id_reg2(id_reg2_o),
		.id_wd(id_wd_o),
		.id_wreg(id_wreg_o),
		.stall(stall),
		.id_inst(id_inst_o),
		.id_is_in_delay_slot(id_is_in_delay_slot_o),.next_inst_in_delay_slot_i(next_is_in_delay_slot_o),
		.id_link_address(id_link_addr_o),
		
		.ex_is_in_delay_slot(ex_is_in_delay_slot_i),.is_in_delay_slot_o(id_is_in_delay_slot_i),
		.ex_link_address(ex_link_addr_i),
		.ex_inst(ex_inst_i),
		.ex_aluop(ex_aluop_i),
		.ex_alusel(ex_alusel_i),
		.ex_reg1(ex_reg1_i),.ex_reg2(ex_reg2_i),
		.ex_wd(ex_wd_i),
		.ex_wreg(ex_wreg_i)
	);
	
	//div
	wire div_ready_i,div_start_o,signed_div_o;
	wire [`DoubleRegBus] div_res_i;
	wire [`RegBus] div_opdata1_o,div_opdata2_o;

	ex ex0(.rst(rst),
		.aluop_i(ex_aluop_i),
		.alusel_i(ex_alusel_i),
		.reg1_i(ex_reg1_i),.reg2_i(ex_reg2_i),
		//hilo
		.hi_i(hilo_hi_o),.lo_i(hilo_lo_o),

		.wb_hi_i(wb_hi_i),.wb_lo_i(wb_lo_i),
		.wb_whilo_i(wb_whilo_i),

		.mem_hi_i(mem_hi_o),.mem_lo_i(mem_lo_o),
		.mem_whilo_i(mem_whilo_o),
		.hilo_temp_i(ex_hilo_temp_i),
		.cnt_i(ex_cnt_i),	
		.inst_i(ex_inst_i),

		.div_ready_i(div_ready_i),
		.div_res_i(div_res_i),
		.is_in_delay_slot(ex_is_in_delay_slot_i),
		.link_address_i(ex_link_addr_i),
		.signed_div_o(signed_div_o),.div_start_o(div_start_o),
		.div_opdata1_o(div_opdata1_o),.div_opdata2_o(div_opdata2_o),

		.hi_o(ex_hi_o),.lo_o(ex_lo_o),
		.whilo_o(ex_whilo_o),

		.wd_i(ex_wd_i),
		.wreg_i(ex_wreg_i),
		.wdata_o(ex_wdata_o),
		.wd_o(ex_wd_o),
		.wreg_o(ex_wreg_o),
		.stallreq(stallreq_from_ex),
		.hilo_temp_o(ex_hilo_temp_o),
		.cnt_o(ex_cnt_o),
		.aluop_o(ex_aluop_o),
		.mem_addr_o(ex_mem_addr_o),
		.reg2_o(ex_reg2_o)
	);

	div div0(.clk(clk),.rst(rst),
		.signed_div_i(signed_div_o),
		.opdata1_i(div_opdata1_o),.opdata2_i(div_opdata2_o),
		.start_i(div_start_o),
		.annul_i(1'b0),
		.result_o(div_res_i),
		.ready_o(div_ready_i));

	ex_mem ex_mem0(.clk(clk),.rst(rst),
		.ex_wdata(ex_wdata_o),
		.ex_wd(ex_wd_o),
		.ex_wreg(ex_wreg_o),

		.ex_whilo(ex_whilo_o),
		.ex_hi(ex_hi_o),.ex_lo(ex_lo_o),
		.stall(stall),
		.cnt_i(ex_cnt_o),
		.hilo_i(ex_hilo_temp_o),
		.ex_aluop_o(ex_aluop_o),
		.ex_mem_addr_o(ex_mem_addr_o),
		.ex_reg2_o(ex_reg2_o),
		.cnt_o(ex_cnt_i),
		.hilo_o(ex_hilo_temp_i),
		.mem_hi(mem_hi_i),.mem_lo(mem_lo_i),
		.mem_whilo(mem_whilo_i),

		.mem_wdata(mem_wdata_i),
		.mem_wd(mem_wd_i),
		.mem_wreg(mem_wreg_i),
		.mem_aluop_i(mem_aluop_i),
		.mem_mem_addr_i(mem_mem_addr_i),
		.mem_reg2_i(mem_reg2_i)
	);

	mem mem0(.rst(rst),
		.wdata_i(mem_wdata_i),
		.wd_i(mem_wd_i),
		.wreg_i(mem_wreg_i),
		//hilo
		.mem_whilo_i(mem_whilo_i),
		.mem_hi_i(mem_hi_i),.mem_lo_i(mem_lo_i),
		.aluop_i(mem_aluop_i),
		.mem_addr_i(mem_mem_addr_i),
		.reg2_i(mem_reg2_i),
		.mem_data_i(ram_data_o),
		.mem_hi_o(mem_hi_o),.mem_lo_o(mem_lo_o),
		.mem_whilo_o(mem_whilo_o),

		.wdata_o(mem_wdata_o),
		.wd_o(mem_wd_o),
		.wreg_o(mem_wreg_o),
		.mem_addr_o(ram_addr_i),
		.mem_we_o(ram_we),
		.mem_ce_o(ram_ce),
		.mem_sel_o(ram_sel),
		.mem_data_o(ram_data_i)
	);



	mem_wb mem_wb0(.clk(clk),.rst(rst),
		.mem_wdata(mem_wdata_o),
		.mem_wd(mem_wd_o),
		.mem_wreg(mem_wreg_o),
		//hilo
		.mem_whilo(mem_whilo_o),
		.mem_hi(mem_hi_o),.mem_lo(mem_lo_o),
		.stall(stall),
		.wb_hi(wb_hi_i),.wb_lo(wb_lo_i),
		.wb_whilo(wb_whilo_i),

		.wb_wdata(wb_wdata_i),
		.wb_wd(wb_wd_i),
		.wb_wreg(wb_wreg_i)
	);

	hilo_reg hilo_reg0(.rst(rst),.clk(clk),
		.we(wb_whilo_i),
		.hi_i(wb_hi_i),
		.lo_i(wb_lo_i),
		.hi_o(hilo_hi_o),.lo_o(hilo_lo_o));


	regfile regfile0(.clk(clk),.rst(rst),
			.we(wb_wreg_i),
			.waddr(wb_wd_i),
			.wdata(wb_wdata_i),
			.re1(reg1_read),
			.raddr1(reg1_addr),
			.rdata1(reg1_data),
			.re2(reg2_read),
			.raddr2(reg2_addr),
			.rdata2(reg2_data)
	);

	ctrl ctrl0(.rst(rst),
		.stallreq_from_id(stallreq_from_id),
		.stallreq_from_ex(stallreq_from_ex),
		.stall(stall));
endmodule