module	ARM_SingleCycle_DataPath
	#(parameter	BusWidth = 32)
	(input logic	i_CLK, i_RESET,

	//	Control inputs
	input logic[1:0]                i_Reg_Src,
	input logic[1:0]				i_Imm_Src,
	input logic						i_PC_Src, i_ALU_Src, 
	input logic						i_Mem_ToReg,
	input logic						i_Reg_Write,
	input logic[2:0]				i_ALU_Control,
	//	Control outputs
	output logic[3:0]				o_ALU_Flags,

	//	Memory Control
	input logic[31:0]				i_Instr,
	output logic[(BusWidth - 1):0]	o_PC, o_ALU_Result,

	//	Data WD and RD
	output logic[(BusWidth - 1):0]	o_Write_Data,
	input logic[(BusWidth - 1):0]	i_Read_Data,
	output logic [(BusWidth - 1):0]		s_Reg1_Data, s_Reg2_Data);

	logic[(BusWidth - 1):0]			s_PC_in;
	logic[(BusWidth - 1):0]			s_PC;
	
	//logic[(BusWidth - 1):0]			s_Instr;
	//logic[(BusWidth - 1):0]			s_Instruction_Step;
	logic[(BusWidth - 1):0]			s_PC_Plus4, s_PC_Plus8;
	
	logic[3:0]						s_Reg1_Address, s_Reg2_Address;
	//logic[3:0]						s_Reg_ToWrite_Address;
	//logic[(BusWidth - 1):0]			s_Reg1_Data, s_Reg2_Data;

	logic[(BusWidth - 1):0]			s_ExtendedData;

	logic[6:0]						s_Shamt;
	logic[(BusWidth - 1):0]			s_Shifted_Data;

	logic[(BusWidth - 1):0]			s_ALU_Src2;

	logic[(BusWidth - 1):0]			s_ALU_Result;

	logic[(BusWidth - 1):0]			s_Result;


	//assign s_Instruction_Step = 32'd4;

	ARM_Mux2				PC_Source
		(s_PC_Plus4, s_Result,
		i_Instr[31:0],
		i_ALU_Control[2:0],
		i_PC_Src,
		s_PC_in);

	ARM_ProgramCounter		ProgramCounter
		(i_CLK, i_RESET,
		s_PC_in,
		s_PC);

	assign o_PC = s_PC;
/*
	ARM_InstructionMemory	InstructionMemory
		(s_PC,
		s_Instr);
*/
	ARM_Adder				NextInstruction_Adder
		(s_PC, /*s_Instruction_Step*/32'd4,
		s_PC_Plus4);

	ARM_Adder				PC_Plus8_Adder
		(/*s_Instruction_Step*/32'd4, s_PC_Plus4,
		s_PC_Plus8);

	ARM_Mux2	Reg1_Source
		(i_Instr[19:16], 4'd15,
		i_Instr[31:0],
		i_ALU_Control[2:0],
		i_Reg_Src[0],
		s_Reg1_Address[3:0]);

	ARM_Mux2	Reg2_Source
		(i_Instr[3:0], i_Instr[15:12],
		i_Instr[31:0],
		i_ALU_Control[2:0],
		i_Reg_Src[1],
		s_Reg2_Address[3:0]);
		
//	ARM_Mux3	Reg3_Source
//		(i_Instr[19:16],  4'd15,
//		i_Instr[31:0],
//		i_Reg_Src[2],
//		s_Reg2_Address[3:0]);

	//assign s_Reg_ToWrite_Address = i_Instr[15:12];

	ARM_RegisterFile		RegisterFile
		(i_CLK, i_RESET,
		i_Reg_Write,
		s_Reg1_Address, s_Reg2_Address,
		/*s_Reg_ToWrite_Address*/i_Instr[15:12],
		s_PC_Plus8,
		s_Result,
		s_Reg1_Data, s_Reg2_Data);

	ARM_ExtensionUnit		ExtensionUnit
		(i_Instr[23:0],
		i_Imm_Src,
		s_ExtendedData,
		i_Instr[31:0]);
/*
	assign s_Shamt = i_Instr[11:5];

	ARM_Shift				Shift
		(s_Reg2_Data,
		s_Shamt,
		s_Shifted_Data);
*/
	ARM_Mux2				ALU_Src2_Mux
		(s_Reg2_Data, s_ExtendedData,
		i_Instr[31:0],
		i_ALU_Control[2:0],
		i_ALU_Src,
		s_ALU_Src2);

	ARM_ALU					ALU
		(s_Reg1_Data, s_ALU_Src2,
		i_Instr[31:0],
		i_ALU_Control,
		s_ALU_Result,
		o_ALU_Flags);

	assign o_ALU_Result = s_ALU_Result;
	assign o_Write_Data = s_Reg2_Data;
/*
	ARM_DataMemory			RAM
		(i_CLK,
		);
*/
	ARM_Mux2				Result_Source
		(s_ALU_Result, i_Read_Data,
		i_Instr[31:0],
		i_ALU_Control[2:0],
		i_Mem_ToReg,
		s_Result);



endmodule



module	ARM_ProgramCounter
	#(parameter	AddressBusWidth	= 32)
	(input logic							i_CLK, i_RESET,
	input logic[(AddressBusWidth - 1):0]	i_Address,
	output logic[(AddressBusWidth - 1):0]	o_Address);


	always_ff	@(posedge i_CLK, posedge i_RESET)
	begin
		if (i_RESET)		o_Address <= 'd0;
		else if (i_CLK)		o_Address <= i_Address;
	end

endmodule


module	ARM_Adder
	#(parameter BusWidth = 32)
	(input logic[(BusWidth - 1):0]	i_Adder_Src1, i_Adder_Src2,
	output logic[(BusWidth - 1):0]	o_Adder_Result);


	assign o_Adder_Result = i_Adder_Src1 + i_Adder_Src2;

endmodule


module	ARM_RegisterFile
	#(parameter	BusWidth			= 32,
				RegisterFileSize	= 15)
	(input logic					i_CLK, i_RESET,

	//	Write Control
	input logic						i_Write_Enable,

	//	Register Address inputs
	input logic[3:0]				i_Address_ToRead1, i_Address_ToRead2,
	input logic[3:0]				i_Address_ToWrite,

	//	PC Write input
	input logic[(BusWidth - 1):0]	i_R15,

	//	Data Control
	input logic[(BusWidth - 1):0]	i_Write_Data,
	output logic[(BusWidth - 1):0]	o_Read_Data1, o_Read_Data2);


	int								i;
	logic[(BusWidth - 1):0]			RegisterFile[(RegisterFileSize - 1):0];


	always_ff	@(posedge i_CLK, posedge i_RESET)
	begin
		if (i_RESET)
		begin

			for (i = 0; i < 15; i = i + 1)		RegisterFile[i] <= 32'd0;
		end
		else if (i_Write_Enable)				RegisterFile[i_Address_ToWrite] <= i_Write_Data;
	end

	assign o_Read_Data1 = (i_Address_ToRead1 == 4'd15) ?	i_R15 : RegisterFile[i_Address_ToRead1];
	assign o_Read_Data2 = (i_Address_ToRead2 == 4'd15) ?	i_R15 : RegisterFile[i_Address_ToRead2];

endmodule


module	ARM_ExtensionUnit
	#(parameter	BusWidth			= 32,
				ExtendableDataWidth	= 24)
	(input logic[(ExtendableDataWidth - 1):0]	i_Data,
	input logic[1:0]							i_ExtensionControl,
	output logic[(BusWidth - 1):0]				o_Extension,
	input logic [31:0] i_Instr);

	typedef enum logic[1:0] {IMM_DATA_PROCESSING, IMM_MEM, IMM_BRANCH}	ExtensionType;
	
	logic  [4:0]   lsl_num;

	always_comb
	begin
		case (i_ExtensionControl)
			IMM_DATA_PROCESSING:
			begin
			     o_Extension = {24'b0, i_Data[7:0]};
			     lsl_num = ('d32-(i_Instr[11:8]<<1));
			     o_Extension =(lsl_num=='d32) ?          o_Extension : o_Extension << lsl_num;
			     // o_Mux_out = (i_Mux_Src_Select) ?	i_Mux_Src1 : i_Instr[11:8];
			end
				//o_Extension = {24'b0, i_Data[7:0]};
			IMM_MEM:
                begin
                 if(i_Instr[23]==1'b0)   o_Extension = ~{20'b0, i_Data[11:0]}+1'b1;
                 else if(i_Instr[23]==1'b1)  o_Extension = {20'b0, i_Data[11:0]};
                end				
							//o_Extension = ~{20'b0, i_Data[11:0]}+1'b1;
			IMM_BRANCH:				o_Extension = {{6{i_Data[23]}}, i_Data[23:0], 2'b00};
			
			default:	o_Extension = 32'bx;
		endcase
	end

endmodule


module ARM_Shift
	#(parameter	BusWidth	= 32)
	(input logic[(BusWidth - 1):0]	i_Data,
	input logic[6:0]				i_Shamt,
	output logic[(BusWidth - 1):0]	o_Shifted_Data);

	int		l_Shamt;
	typedef enum logic[1:0]	{LSL, LSR, ASR, ROR}	t_ShiftType;
	logic[1:0]						s_ShiftType;
	//logic[(BusWidth - 1):0]	s_LefShiftedPart, s_RightShiftedPart;


	assign s_ShiftType = i_Shamt[1:0];
	//assign s_LeftShiftedPart		= i_Data << (BusWidth - i_Shamt[6:2]);
	//assign s_RightShiftedPart	= i_Data >> i_Shamt[6:2];

	always_comb
	begin
		case (s_ShiftType)
			LSL:	o_Shifted_Data = (i_Data << i_Shamt[6:2]);
			LSR:	o_Shifted_Data = (i_Data >> i_Shamt[6:2]);
			ASR:	o_Shifted_Data = (i_Data >>> i_Shamt[6:2]);
			ROR:
			begin
				case(i_Shamt[6:2])
					4'd0:	o_Shifted_Data = i_Data;
					4'd1:
					begin
						o_Shifted_Data[((BusWidth - 1) - 1):0] = i_Data >> 1;
						o_Shifted_Data[(BusWidth - 1)] = i_Data[0];
					end
					4'd2:
					begin
						o_Shifted_Data[((BusWidth - 1) - 2):0] = i_Data >> 2;
						o_Shifted_Data[(BusWidth - 1):((BusWidth - 1) - 1)] = i_Data[1:0];
					end
					4'd3:
					begin
						o_Shifted_Data[((BusWidth - 1) - 3):0] = i_Data >> 3;
						o_Shifted_Data[(BusWidth - 1):((BusWidth - 1) - 2)] = i_Data[2:0];
					end
					4'd4:
					begin
						o_Shifted_Data[((BusWidth - 1) - 4):0] = i_Data >> 4;
						o_Shifted_Data[(BusWidth - 1):((BusWidth - 1) - 3)] = i_Data[3:0];
					end
					4'd5:
					begin
						o_Shifted_Data[((BusWidth - 1) - 5):0] = i_Data >> 5;
						o_Shifted_Data[(BusWidth - 1):((BusWidth - 1) - 4)] = i_Data[4:0];
					end
					4'd6:
					begin
						o_Shifted_Data[((BusWidth - 1) - 6):0] = i_Data >> 6;
						o_Shifted_Data[(BusWidth - 1):((BusWidth - 1) - 5)] = i_Data[5:0];
					end
					4'd7:
					begin
						o_Shifted_Data[((BusWidth - 1) - 7):0] = i_Data >> 7;
						o_Shifted_Data[(BusWidth - 1):((BusWidth - 1) - 6)] = i_Data[6:0];
					end
					4'd8:
					begin
						o_Shifted_Data[((BusWidth - 1) - 8):0] = i_Data >> 8;
						o_Shifted_Data[(BusWidth - 1):((BusWidth - 1) - 7)] = i_Data[7:0];
					end
					4'd9:
					begin
						o_Shifted_Data[((BusWidth - 1) - 9):0] = i_Data >> 9;
						o_Shifted_Data[(BusWidth - 1):((BusWidth - 1) - 8)] = i_Data[8:0];
					end
					4'd10:
					begin
						o_Shifted_Data[((BusWidth - 1) - 10):0] = i_Data >> 10;
						o_Shifted_Data[(BusWidth - 1):((BusWidth - 1) - 9)] = i_Data[9:0];
					end
					4'd11:
					begin
						o_Shifted_Data[((BusWidth - 1) - 11):0] = i_Data >> 11;
						o_Shifted_Data[(BusWidth - 1):((BusWidth - 1) - 10)] = i_Data[10:0];
					end
					4'd12:
					begin
						o_Shifted_Data[((BusWidth - 1) - 12):0] = i_Data >> 12;
						o_Shifted_Data[(BusWidth - 1):((BusWidth - 1) - 11)] = i_Data[11:0];
					end
					4'd13:
					begin
						o_Shifted_Data[((BusWidth - 1) - 13):0] = i_Data >> 13;
						o_Shifted_Data[(BusWidth - 1):((BusWidth - 1) - 12)] = i_Data[12:0];
					end
					4'd14:
					begin
						o_Shifted_Data[((BusWidth - 1) - 14):0] = i_Data >> 14;
						o_Shifted_Data[(BusWidth - 1):((BusWidth - 1) - 13)] = i_Data[13:0];
					end
					4'd15:
					begin
						o_Shifted_Data[((BusWidth - 1) - 15):0] = i_Data >> 15;
						o_Shifted_Data[(BusWidth - 1):((BusWidth - 1) - 14)] = i_Data[14:0];
					end
				endcase
			end
		endcase
	end

endmodule


module	ARM_ALU
	#(parameter	BusWidth	= 32,
	parameter ADD = 3'b000,
	parameter SUB = 3'b001,
	parameter AND = 3'b010,
	parameter ORR = 3'b011,
	parameter SHF = 3'b100
    )
	(input logic[(BusWidth - 1):0]	i_ALU_Src1, i_ALU_Src2,
	input logic [31:0]  i_Instr,
	input logic[2:0]				i_ALU_Control,
	output logic[(BusWidth - 1):0]	o_ALU_Result,
	output logic[3:0]				o_ALU_Flags);

	logic[(BusWidth - 1):0]			s_ALU_Result;
	logic							s_Flag_Negative, s_Flag_Zero;
	logic							s_Flag_Carry, s_Flag_Overflow;
	


	//	Result logic
	always_comb
	begin

		case (i_ALU_Control[2:0])
			ADD:	s_ALU_Result <= i_ALU_Src1 + i_ALU_Src2;
			SUB:	s_ALU_Result <= i_ALU_Src1 - i_ALU_Src2;
			AND:	s_ALU_Result <= i_ALU_Src1 & i_ALU_Src2;
			ORR:    s_ALU_Result <= i_ALU_Src1 | i_ALU_Src2;
			SHF:	
			begin
			if(i_Instr[6:5]==2'b00)
			begin
                if(i_Instr[4]==1'b0)
                s_ALU_Result <= (i_ALU_Src2 << i_Instr[11:7]);
                else if(i_Instr[4]==1'b1)
                s_ALU_Result <= (i_ALU_Src2 << i_ALU_Src1);
            end
		   else if(i_Instr[6:5]==2'b01)
			begin
			    if(i_Instr[4]==1'b0)
                s_ALU_Result <= (i_ALU_Src2 >> i_Instr[11:7]);
                else if(i_Instr[4]==1'b1)
                s_ALU_Result <= (i_ALU_Src2 >> i_ALU_Src1);
                end
			end
			default:	s_ALU_Result = 32'b0;
		endcase
//	end
	end

	//	Flags logic
	always_comb
	begin
	if(~((i_Instr[27:26]==2'b00)&(i_Instr[24:21]==4'b1101)))
	begin
		s_Flag_Negative = (s_ALU_Result[BusWidth - 1] == 1'b1) ?	1'b1 : 1'b0;
		s_Flag_Zero = (s_ALU_Result == 0) ?							1'b1 : 1'b0;
		case (i_ALU_Control[2:0])
			ADD:
			begin
				s_Flag_Carry = (i_ALU_Src1 >= i_ALU_Src2) ?					1'b1 : 1'b0;
				s_Flag_Overflow =	((~i_ALU_Src1[BusWidth - 1] & ~i_ALU_Src2[BusWidth - 1] & s_ALU_Result[BusWidth - 1]) |
									(i_ALU_Src1[BusWidth - 1] & i_ALU_Src2[BusWidth - 1] & ~s_ALU_Result[BusWidth - 1]));
			end
			SUB:
			begin
				s_Flag_Carry = (i_ALU_Src1 < i_ALU_Src2) ?					1'b1 : 1'b0;
				s_Flag_Overflow =	((i_ALU_Src1[BusWidth - 1] & ~i_ALU_Src2[BusWidth - 1] & s_ALU_Result[BusWidth - 1]) |
									(~i_ALU_Src1[BusWidth - 1] & i_ALU_Src2[BusWidth - 1] & s_ALU_Result[BusWidth - 1]));
			end
			
			default:
			begin
				s_Flag_Carry = 1'bx;
				s_Flag_Overflow = 1'bx;
			end
		endcase
		end
	end

	assign o_ALU_Result =	s_ALU_Result;
	assign o_ALU_Flags =	{s_Flag_Negative, s_Flag_Zero,
							s_Flag_Carry, s_Flag_Overflow};

endmodule


module ARM_Mux2
	#(parameter	BusWidth	= 32)
	(input logic[(BusWidth - 1):0]	i_Mux_Src0, i_Mux_Src1,
	input logic [31:0]       i_Instr,
	input logic [2:0]      i_ALU_Control,
	input logic						i_Mux_Src_Select,
	output logic[(BusWidth - 1):0]	o_Mux_out);
	always_comb
	begin

    logic condition;
    assign condition = (i_Instr[27:26]==2'b00)&&(i_Instr[24:21]==4'b1101)&&(i_Mux_Src1==4'd15);
	   if(condition)
	   begin
	       o_Mux_out = (i_Mux_Src_Select) ?	i_Mux_Src1 : i_Instr[11:8];
	   end
	   else
	       o_Mux_out = (i_Mux_Src_Select) ?	i_Mux_Src1 : i_Mux_Src0;
	end
	

endmodule
