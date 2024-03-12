module ARM_SingleCycle_CPU
	#(parameter	BusWidth	= 32)
	(input logic		i_CLK, i_RESET,

	//	Memory Control
	input logic[(BusWidth - 1):0]	i_Instr,
	output logic[(BusWidth - 1):0]	o_PC,
	output logic[(BusWidth - 1):0]	o_Data_Address,
	output logic					o_Mem_Write,

	//	Memory Process
	output logic[(BusWidth - 1):0]	o_Write_Data,
	input logic[(BusWidth - 1):0]	i_Read_Data,
	output logic[(BusWidth - 1):0]    s_Reg1_Data, s_Reg2_Data);

	logic[3:0]			s_ALU_Flags;

    logic[1:0]          s_Reg_Src;
	logic[1:0]			s_Imm_Src;
	logic				s_PC_Src, s_ALU_Src;
	logic[2:0]			s_ALU_Control;
	logic				s_Mem_ToReg;
	logic				s_Reg_Write;//, Mem_Write;

	//logic		PC;
	//logic		Instr;
	//logic		ALU_Result;

	//logic		Write_Data, Read_Data;


	ARM_SingleCycle_DataPath	Datapath
		(i_CLK, i_RESET,
		
		s_Reg_Src, s_Imm_Src,
		s_PC_Src, s_ALU_Src,
		s_Mem_ToReg,
		s_Reg_Write,
		s_ALU_Control,
		s_ALU_Flags,
		
		i_Instr[31:0],
		o_PC, o_Data_Address,
		
		o_Write_Data,
		i_Read_Data,
		s_Reg1_Data, s_Reg2_Data);

	ARM_SyngleCycle_Controller	Controller
		(i_CLK, i_RESET,
		
		s_ALU_Flags,
		s_Reg_Src, s_Imm_Src,
		s_PC_Src, s_ALU_Src,
		s_Mem_ToReg,
		s_Reg_Write, o_Mem_Write,
		s_ALU_Control,

		{i_Instr[31:20], i_Instr[15:12]});

endmodule
