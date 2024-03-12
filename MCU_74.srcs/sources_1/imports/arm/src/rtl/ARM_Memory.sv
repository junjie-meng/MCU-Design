module	ARM_InstructionMemory
	#(parameter BusWidth			= 32,
				InstrMemSize		= 8192)
	(input logic[(BusWidth - 1):0]	i_Address,
	output logic[(BusWidth - 1):0]	o_Instr);

	//	Instruction Memory Array
	logic[(BusWidth - 1):0]			InstructionMemory[(InstrMemSize -1):0];

	//	Memory Initialisation
	initial
	begin
		$readmemh("ARM_Program.dat", InstructionMemory);
	end


	assign o_Instr = InstructionMemory[i_Address[31:2]];

endmodule


module	ARM_DataMemory
	#(parameter	BusWidth	= 32,
				DataMemSize	= 8192)
	(input logic					i_CLK,// i_RESET,

	//	Write Control
	input logic						i_Write_Enable,

	input logic[(BusWidth - 1):0]	i_Address,

	//	Data Control
	input logic[(BusWidth - 1):0]	i_Write_Data,
	output logic[(BusWidth - 1):0]	o_Read_Data);

	//	RAM Array
	logic[(BusWidth - 1):0]			RAM[(DataMemSize - 1):0];


	//	Write logic
	always_ff	@(posedge i_CLK)//, posedge i_RESET)
	begin
		/*if (i_RESET)
		begin
			for (i = 0; i < DataMemSize; i = i + 1)	RAM[i] = 32'd0;
		end*/
		if (i_Write_Enable)	RAM[i_Address[(BusWidth - 1):2]] <= i_Write_Data;
	end

	assign o_Read_Data = RAM[i_Address[(BusWidth - 1):2]];

endmodule
