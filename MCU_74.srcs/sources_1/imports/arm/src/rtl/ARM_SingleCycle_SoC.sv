module ARM_SingleCycle_SoC
	#(parameter	BusWidth	= 32)
	(input logic					i_CLK, i_RESET,
	output logic[(BusWidth - 1):0]	o_Address,
	output logic[(BusWidth - 1):0]	o_Write_Data,
	output logic					o_Mem_Write,
	output logic [(BusWidth - 1):0]      s_Instr,
	output logic [(BusWidth - 1):0]      s_PC,
	output logic [(BusWidth - 1):0]    s_Reg1_Data, s_Reg2_Data,
	output logic [(BusWidth - 1):0]    s_Read_Data);

	//	Memory Control
	//logic[(BusWidth - 1):0]			s_PC;//, s_Address;
	//logic							s_Mem_Write;
	//	Memory Process
	//logic[(BusWidth - 1):0]			/*s_Write_Data, */s_Read_Data;


	//	Instantiation CPU and Memories
	//	CPU
	ARM_SingleCycle_CPU		CPU
		(i_CLK, i_RESET,
		s_Instr,
		s_PC,
		o_Address,
		o_Mem_Write,

		o_Write_Data, s_Read_Data,
		s_Reg1_Data, s_Reg2_Data);
	
//	always_comb
//	begin
//	if((s_Instr[27:26]==2'b00)&(s_Instr[24:21]==4'b1101))
//	begin
//	   if(s_Instr[4]==1'b0)//imm
//	   begin
//	   o_Write_Data <= (o_Write_Data << s_Instr[11:7]);
//	   end
//	   else if(s_Instr[4]==1'b1)//reg
//	   o_Write_Data <= (o_Write_Data << s_Instr[11:8]);
//	end
//	end

		//	Instruction Memory
	ARM_InstructionMemory	InstructionMemory
		(s_PC,
		s_Instr);

	//	RAM
	ARM_DataMemory			RAM
		(i_CLK,
		
		o_Mem_Write,
		
		o_Address,
		o_Write_Data, s_Read_Data);

endmodule
