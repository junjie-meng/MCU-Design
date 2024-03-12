module ARM_SyngleCycle_Controller
	(input logic		i_CLK, i_RESET,

	//	Datapath Control
	input logic[3:0]	i_ALU_Flags,
	output logic[1:0]	o_Reg_Src, o_Imm_Src,
	output logic		o_PC_Src, o_ALU_Src,
	output logic		o_Mem_ToReg,
	output logic		o_Reg_Write, o_Mem_Write,
	output logic[2:0]	o_ALU_Control,

	//	Instruction Memory inputs
	input logic[15:0]	i_Instr);

	//	Conditional logic Control
	logic[3:0]			s_Cond;
	
	logic[1:0]			s_Flag_Write;
	logic				s_PC_Src;
	logic				s_Reg_Write, s_Mem_Write;
	logic				s_No_Write;

	//	Decoder Control
	logic[1:0]			s_Op;
	logic[5:0]			s_Funct;
	logic[3:0]			s_Rd;


	assign s_Cond	= i_Instr[15:12];
	assign s_Op		= i_Instr[11:10];
	assign s_Funct	= i_Instr[9:4];
	assign s_Rd		= i_Instr[3:0];


	ARM_SyngleCycle_Decoder				Decoder
		(s_Op,
		s_Funct,
		s_Rd,
		
		s_Flag_Write,
		s_PC_Src,
		s_Reg_Write, s_Mem_Write,
		s_No_Write,
		
		o_Mem_ToReg,
		o_ALU_Src,
		o_Reg_Src, o_Imm_Src,
		o_ALU_Control);

	ARM_SyngleCycle_ConditionalLogic	ConditionalLogic
		(i_CLK, i_RESET,
		
		s_Cond,
		i_ALU_Flags,
		
		s_Flag_Write,
		s_PC_Src,
		s_Reg_Write, s_Mem_Write,
		s_No_Write,
		
		o_PC_Src,
		o_Reg_Write, o_Mem_Write);

endmodule




module	ARM_SyngleCycle_Decoder
	(input logic[1:0]	i_Op,
	input logic[5:0]	i_Funct,
	input logic[3:0]	i_Rd,

	output logic[1:0]	o_Flag_Write,
	output logic		o_PC_Src,
	output logic		o_Reg_Write, o_Mem_Write,
	output logic		o_No_Write,

	output logic		o_Mem_ToReg,
	output logic		o_ALU_Src,
	output logic[1:0]	o_Reg_Src, o_Imm_Src,
	output logic[2:0]	o_ALU_Control);

	logic				s_ALU_Operation;
	logic				s_Branch;


	ARM_SyngleCycle_ALU_Decoder		ALU_Decoder
		(i_Funct[4:0],
		s_ALU_Operation,
		o_ALU_Control, o_Flag_Write,
		o_No_Write);

	ARM_SyngleCycle_Main_Decoder	Main_Decoder
		(i_Op, {i_Funct[5], i_Funct[0]},
		o_Reg_Src, o_Imm_Src,
		o_ALU_Src,
		o_Reg_Write, o_Mem_Write,
		o_Mem_ToReg,

		s_ALU_Operation,
		s_Branch);

	ARM_SyngleCycle_PC_Logic		PC_Logic
		(i_Rd,
		s_Branch, o_Reg_Write,
		o_PC_Src);

endmodule

module	ARM_SyngleCycle_ALU_Decoder
	(input logic[4:0]	i_Funct,
	input logic			i_ALU_Operation,
	output logic[2:0]  o_ALU_Control,
	output logic[1:0]	o_Flag_Write,
	output logic		o_No_Write);

	typedef enum logic[3:0]	{ADD = 4'b0100,
							SUB = 4'b0010,
							AND = 4'b0000,
							ORR = 4'b1100,
							SHF = 4'b1101,
							CMP = 4'b1010}	InstructionType;


	always_comb
	begin
		if (i_ALU_Operation)
		begin
			o_ALU_Control		= 3'bxxx;
			o_No_Write			= 1'bx;
			o_Flag_Write		= 2'bxx;
			case (i_Funct[4:1])
				ADD:
				begin
					o_ALU_Control		= 3'b000;
					o_No_Write			= 1'b0;
					if (i_Funct[0])		o_Flag_Write	= 2'b11;
				end
				SUB:
				begin
					o_ALU_Control		= 3'b001;
					o_No_Write			= 1'b0;
					if (i_Funct[0])		o_Flag_Write	= 2'b11;
				end
				AND:
				begin
					o_ALU_Control		= 3'b010;
					o_No_Write			= 1'b0;
					if (i_Funct[0])		o_Flag_Write	= 2'b10;
				end
				ORR:
				begin
					o_ALU_Control		= 3'b011;
					o_No_Write			= 1'b0;
					if (i_Funct[0])		o_Flag_Write	= 2'bxx;
				end
				SHF:
				begin
					o_ALU_Control		= 3'b100;
					o_No_Write			= 1'b0;
					if (i_Funct[0])		o_Flag_Write	= 2'bxx;
				end
				CMP:
				begin
					o_ALU_Control		= 3'b001;
					o_No_Write			= 1'b1;
					if (i_Funct[0])		o_Flag_Write	= 2'b11;
				end
				
				default:
				begin
					o_ALU_Control		= 3'bxxx;
					o_No_Write			= 1'bx;
					o_Flag_Write		= 2'bxx;
				end
			endcase
		end
		else
		begin
			o_ALU_Control	= 3'b0;
			o_Flag_Write	= 2'b0;
			o_No_Write		= 1'b0;
		end
	end

endmodule

module	ARM_SyngleCycle_Main_Decoder
	(input logic[1:0]	i_Op, i_Funct,
	
	output logic[1:0]	o_Reg_Src, o_Imm_Src,
	output logic		o_ALU_Src,
	output logic		o_Reg_Write, o_Mem_Write,
	output logic		o_Mem_ToReg,
	
	output logic		o_ALU_Operation,
	output logic		o_Branch);

	typedef enum logic[1:0] {DATA_PROCESSING,
							MEM_CONTROL,
							BRANCH}	InstructionType;


	always_comb
	begin
		case (i_Op)
			DATA_PROCESSING:
			begin
				if (i_Funct[1])
				begin
					o_Branch		= 1'b0;
					o_Mem_ToReg		= 1'b0;
					o_Mem_Write		= 1'b0;
					o_ALU_Src		= 1'b1;
					o_Imm_Src		= 2'b00;
					o_Reg_Write		= 1'b1;
					o_Reg_Src		= 2'bx0;
					o_ALU_Operation	= 1'b1;
				end
				else
				begin
					o_Branch		= 1'b0;
					o_Mem_ToReg		= 1'b0;
					o_Mem_Write		= 1'b0;
					o_ALU_Src		= 1'b0;
					o_Imm_Src		= 2'bxx;
					o_Reg_Write		= 1'b1;
					o_Reg_Src		= 2'b00;
					o_ALU_Operation	= 1'b1;
				end
			end
			MEM_CONTROL:
			begin
				if (i_Funct[0])
				begin
					o_Branch		= 1'b0;
					o_Mem_ToReg		= 1'b1;
					o_Mem_Write		= 1'b0;
					o_ALU_Src		= 1'b1;
					o_Imm_Src		= 2'b01;
					o_Reg_Write		= 1'b1;
					o_Reg_Src		= 2'bx0;
					o_ALU_Operation	= 1'b0;
				end
				else
				begin
					o_Branch		= 1'b0;
					o_Mem_ToReg		= 1'bx;
					o_Mem_Write		= 1'b1;
					o_ALU_Src		= 1'b1;
					o_Imm_Src		= 2'b01;
					o_Reg_Write		= 1'b0;
					o_Reg_Src		= 2'b10;
					o_ALU_Operation	= 1'b0;
				end
			end
			BRANCH:
			begin
				o_Branch		= 1'b1;
				o_Mem_ToReg		= 1'b0;
				o_Mem_Write		= 1'b0;
				o_ALU_Src		= 1'b1;
				o_Imm_Src		= 2'b10;
				o_Reg_Write		= 1'b0;
				o_Reg_Src		= 2'bx1;
				o_ALU_Operation	= 1'b0;
			end
			
			default:
			begin
				o_Branch		= 1'bx;
				o_Mem_ToReg		= 1'bx;
				o_Mem_Write		= 1'bx;
				o_ALU_Src		= 1'bx;
				o_Imm_Src		= 2'bxx;
				o_Reg_Write		= 1'bx;
				o_Reg_Src		= 2'bxx;
				o_ALU_Operation	= 1'bx;
			end
		endcase
	end

endmodule

module	ARM_SyngleCycle_PC_Logic
	(input logic[3:0]	i_Rd,
	input logic			i_Branch, i_Reg_Write,
	output logic		o_PC_Src);


	assign o_PC_Src = (((i_Rd == 4'd15) & i_Reg_Write) | i_Branch) ?	1'b1 : 1'b0;

endmodule



module	ARM_SyngleCycle_ConditionalLogic
	(input logic		i_CLK, i_RESET,
	
	input logic[3:0]	i_Cond,
	input logic[3:0]	i_ALU_Flags,
	
	input logic[1:0]	i_Flag_Write,
	input logic			i_PC_Src,
	input logic			i_Reg_Write, i_Mem_Write,
	input logic			i_No_Write,
	
	output logic		o_PC_Src,
	output logic		o_Reg_Write, o_Mem_Write);

	logic[1:0]			s_Flags_NZ, s_Flags_CV;
	logic				s_Cond_Executed;
	logic[1:0]			s_Flag_Write;


	assign s_Flag_Write = (s_Cond_Executed) ?	i_Flag_Write : 2'b00;

	//	Flags Control
	always_ff	@(posedge i_CLK, posedge i_RESET)
	begin
		if (i_RESET)
		begin
			s_Flags_NZ <= 2'b00;
			s_Flags_CV <= 2'b00;
		end
		else
		begin
			if (s_Flag_Write[1])	s_Flags_NZ <= i_ALU_Flags[3:2];
			if (s_Flag_Write[0])	s_Flags_CV <= i_ALU_Flags[1:0];
		end
	end

	ARM_SyngleCycle_ConditionCheck	ConditionCheck
		(i_Cond,
		s_Flags_NZ,
		s_Flags_CV,
		
		s_Cond_Executed);
	
	always_comb
	begin
		if (s_Cond_Executed)
		begin
			o_PC_Src = i_PC_Src;
			o_Mem_Write = i_Mem_Write;
			if (~i_No_Write)	o_Reg_Write = i_Reg_Write;
			else					o_Reg_Write = 1'b0;
		end
		else
		begin
			o_PC_Src = 1'b0;
			o_Mem_Write = 1'b0;
			o_Reg_Write = 1'b0;
		end
	end

endmodule

module	ARM_SyngleCycle_ConditionCheck
	(input logic[3:0]	i_Cond,
	input logic[1:0]	i_Flags_NZ,
	input logic[1:0]	i_Flags_CV,
	
	output logic		o_Cond_Executed);

	typedef enum logic[3:0]	{EQ, NE, CS, LO,
							MI, PL, VS, VC,
							HI,	LS, GE, LT,
							GT, LE, AL}	ConditionTyoe;


	always_comb
	begin
		case (i_Cond)
			EQ:	if (i_Flags_NZ[0])		o_Cond_Executed = 1'b1;
				else					o_Cond_Executed = 1'b0;
			NE:	if (i_Flags_NZ[0] == 0)	o_Cond_Executed = 1'b1;
				else					o_Cond_Executed = 1'b0;
			CS:	if (i_Flags_CV[1])		o_Cond_Executed = 1'b1;
				else					o_Cond_Executed = 1'b0;
			LO:	if (i_Flags_CV[1] == 0)	o_Cond_Executed = 1'b1;
				else					o_Cond_Executed = 1'b0;
			MI:	if (i_Flags_NZ[1])		o_Cond_Executed = 1'b1;
				else					o_Cond_Executed = 1'b0;
			PL:	if (i_Flags_NZ[1] == 0)	o_Cond_Executed = 1'b1;
				else					o_Cond_Executed = 1'b0;
			VS:	if (i_Flags_CV[0])		o_Cond_Executed = 1'b1;
				else					o_Cond_Executed = 1'b0;
			VC:	if (i_Flags_CV[0] == 0)	o_Cond_Executed = 1'b1;
				else					o_Cond_Executed = 1'b0;
			
			HI:	if ((i_Flags_NZ[0] == 0) & (i_Flags_CV[1]))	o_Cond_Executed = 1'b1;
				else										o_Cond_Executed = 1'b0;
			LS:	if ((i_Flags_NZ[0]) | (i_Flags_CV[1] == 0))	o_Cond_Executed = 1'b1;
				else										o_Cond_Executed = 1'b0;
			GE:	if (~((i_Flags_NZ[1]) ^ (i_Flags_CV[0])))	o_Cond_Executed = 1'b1;
				else										o_Cond_Executed = 1'b0;
			LT:	if (((i_Flags_NZ[1]) ^ (i_Flags_CV[0])))	o_Cond_Executed = 1'b1;
				else										o_Cond_Executed = 1'b0;
			
			GT:	if ((~i_Flags_NZ[0]) & (~((i_Flags_NZ[1]) ^ (i_Flags_CV[0]))))	o_Cond_Executed = 1'b1;
				else															o_Cond_Executed = 1'b0;
			LE:	if ((i_Flags_NZ[0]) | (((i_Flags_NZ[1]) ^ (i_Flags_CV[0]))))	o_Cond_Executed = 1'b1;
				else															o_Cond_Executed = 1'b0;
			
			AL:	o_Cond_Executed = 1'b1;
			
			default:	o_Cond_Executed = 1'bx;
		endcase
	end

endmodule
