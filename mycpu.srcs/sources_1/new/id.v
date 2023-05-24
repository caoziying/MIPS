`include "defines.vh"
//��ָ��������룬���������������������͡���������Ҫ��Դ����������Ҫд���Ŀ�ļĴ����ĵ�ַ��
module id(
	input wire					rst,		 // ��λ�ź�
	input wire[`InstAddrBus]	pc_i, 		 // ����׶ε�ָ���Ӧ��ַ
	input wire[`InstBus]        inst_i,      // ����׶ε�ָ��
    input wire[`AluOpBus]		ex_aluop_i,  // �����������ж�

	//���մ���ִ�н׶ε�ָ����������������������ԣ�
	input wire					ex_wreg_i,  // �Ƿ���Ҫд��Ŀ�ļĴ���
	input wire[`RegBus]			ex_wdata_i, // Ŀ�ļĴ���������
	input wire[`RegAddrBus]     ex_wd_i,   // Ŀ�ļĴ�����ַ
	
	//���մ��ڷô�׶ε�ָ��������
	input wire					mem_wreg_i, // �Ƿ���Ҫд��Ŀ�ļĴ���
	input wire[`RegBus]			mem_wdata_i,// Ŀ�ļĴ���������
	input wire[`RegAddrBus]     mem_wd_i,  // Ŀ�ļĴ�����ַ
	
	//����ִ�н׶ε�Դ������
	input wire[`RegBus]           reg1_data_i,//��regfile����ĵ�һ�����Ĵ����˿ڵ�����
	input wire[`RegBus]           reg2_data_i,//��regfile����ĵڶ������Ĵ����˿ڵ�����

	
	input wire                    is_in_delayslot_i,

	//�����regfile�Ķ˿�ʹ���ź�
	output reg                    reg1_read_o,// regfileģ���һ�����Ĵ����Ķ�ʹ���ź�
	output reg                    reg2_read_o,// regfileģ��ڶ������Ĵ����Ķ�ʹ���ź�   
	output reg[`RegAddrBus]       reg1_addr_o,// regfileģ���һ�����Ĵ����Ķ���ַ�ź�
	output reg[`RegAddrBus]       reg2_addr_o,// regfileģ��ڶ������Ĵ����Ķ���ַ�ź� 	      
	
	//�͵�ִ�н׶ε���Ϣ
	output reg[`AluOpBus]         aluop_o, // ����׶�ָ��Ҫ���е������������
	output reg[`AluSelBus]        alusel_o,// ����׶�ָ��Ҫ���е����������
	output reg[`RegBus]           reg1_o,  // ����׶�ָ��Ҫ���е������Դ������1
	output reg[`RegBus]           reg2_o,  // ����׶�ָ��Ҫ���е������Դ������2
	output reg[`RegAddrBus]       wd_o,    // ����׶�ָ��Ҫд���Ŀ�ļĴ�����ַ
	output reg                    wreg_o,  // ����׶�ָ���Ƿ���Ҫд���Ŀ�ļĴ���
	output wire[`RegBus]          inst_o,  // ���ָ�� ����if_id   inst_o = inst_i

	output reg                    next_inst_in_delayslot_o,
	
	output reg                    branch_flag_o,
	output reg[`RegBus]           branch_target_address_o,       
	output reg[`RegBus]           link_addr_o,
	output reg                    is_in_delayslot_o,
	
	output wire                   stallreq	
);

	//ȡ��ָ���ָ���룬������
	//oriָ��ֻ��Ҫͨ���ж�ǰ��λ����
	wire[5:0] op = inst_i[31:26];
	wire[4:0] op2 = inst_i[10:6];
	wire[5:0] op3 = inst_i[5:0];
	wire[4:0] op4 = inst_i[20:16];

	//����ָ��ִ����Ҫ��������
	reg[`RegBus]	imm;
	//ָ���Ƿ���Ч
	reg instvalid;

	wire[`RegBus] pc_plus_8;
	wire[`RegBus] pc_plus_4;
	wire[`RegBus] imm_sll2_signedext;  

	reg stallreq_for_reg1_loadrelate;
	reg stallreq_for_reg2_loadrelate;
	wire pre_inst_is_load;
  
	assign pc_plus_8 = pc_i + 8;
	assign pc_plus_4 = pc_i +4;
	assign imm_sll2_signedext = {{14{inst_i[15]}}, inst_i[15:0], 2'b00 };  
	assign stallreq = stallreq_for_reg1_loadrelate | stallreq_for_reg2_loadrelate;
	assign pre_inst_is_load = ((ex_aluop_i == `EXE_LB_OP) || 
                                                    (ex_aluop_i == `EXE_LBU_OP)||
                                                    (ex_aluop_i == `EXE_LH_OP) ||
                                                    (ex_aluop_i == `EXE_LHU_OP)||
                                                    (ex_aluop_i == `EXE_LW_OP) ||
                                                    (ex_aluop_i == `EXE_LWR_OP)||
                                                    (ex_aluop_i == `EXE_LWL_OP)||
                                                    (ex_aluop_i == `EXE_LL_OP) ||
                                                    (ex_aluop_i == `EXE_SC_OP)) ? 1'b1 : 1'b0;

	assign inst_o = inst_i;
	/********************************************************************************************
	//��ָ���������(������Ҫ�Զ˿ڽ��г�ʼ������)
	********************************************************************************************/
	always @ (*) begin	
		if (rst == `RstEnable) begin
			aluop_o <= `EXE_NOP_OP;		//	��ʼ������������
			alusel_o <= `EXE_RES_NOP;	//��ʼ������
			wd_o <= `NOPRegAddr; 		//��ʼ��ָ��д���Ŀ�ĵ�ַ
			wreg_o <= `WriteDisable; 	//д��Ч
			instvalid <= `InstValid; 	
			reg1_read_o <= 1'b0;
			reg2_read_o <= 1'b0;
			reg1_addr_o <= `NOPRegAddr;
			reg2_addr_o <= `NOPRegAddr;
			imm <= 32'h0;	
			link_addr_o <= `ZeroWord;
			branch_target_address_o <= `ZeroWord;
			branch_flag_o <= `NotBranch;
			next_inst_in_delayslot_o <= `NotInDelaySlot;					
	  end else begin
			aluop_o <= `EXE_NOP_OP;
			alusel_o <= `EXE_RES_NOP;
			wd_o <= inst_i[15:11];
			wreg_o <= `WriteDisable;
			instvalid <= `InstInvalid;	   
			reg1_read_o <= 1'b0;
			reg2_read_o <= 1'b0;
			reg1_addr_o <= inst_i[25:21];
			reg2_addr_o <= inst_i[20:16];		
			imm <= `ZeroWord;
			link_addr_o <= `ZeroWord;
			branch_target_address_o <= `ZeroWord;
			branch_flag_o <= `NotBranch;	
			next_inst_in_delayslot_o <= `NotInDelaySlot;
		  //���� op��ֵ�ж��Ƿ���oriָ��			
		  case (op)		
		  //ָ������SPECIAL(���仰˵����R��ָ��)
		    `EXE_SPECIAL_INST:		begin
		    	case (op2)
		    		5'b00000:			begin
		    			case (op3)
		    				`EXE_OR:	
		    					begin
			    					//oriָ����Ҫ�����д��Ŀ�ļĴ���������wreg_oΪдʹ��
			    					wreg_o <= `WriteEnable;
			    					//��������������߼�'��'����		
			    					aluop_o <= `EXE_OR_OP;
			    					//�����������߼�����
			  						alusel_o <= `EXE_RES_LOGIC;
			  						//��Ҫͨ��regfile�Ķ��˿�1��ȡ�Ĵ��� 	
			  						reg1_read_o <= 1'b1;	
			  						//����Ҫͨ��regfile�Ķ��˿�2��ȡ�Ĵ��� 
			  						reg2_read_o <= 1'b1;
			  						//oriָ������Ч��
			  						instvalid <= `InstValid;	
								end  
		    				`EXE_AND:	begin
			    					wreg_o <= `WriteEnable;		aluop_o <= `EXE_AND_OP;
			  						alusel_o <= `EXE_RES_LOGIC;	  reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;	
			  						instvalid <= `InstValid;	
								end  	
		    				`EXE_XOR:	begin
			    					wreg_o <= `WriteEnable;		aluop_o <= `EXE_XOR_OP;
			  						alusel_o <= `EXE_RES_LOGIC;		reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;	
			  						instvalid <= `InstValid;	
								end  				
		    				`EXE_NOR:	begin
			    					wreg_o <= `WriteEnable;		aluop_o <= `EXE_NOR_OP;
			  						alusel_o <= `EXE_RES_LOGIC;		reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;	
			  						instvalid <= `InstValid;	
								end 
							`EXE_SLLV: begin
									wreg_o <= `WriteEnable;		aluop_o <= `EXE_SLL_OP;
			  						alusel_o <= `EXE_RES_SHIFT;		reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;
			  						instvalid <= `InstValid;	
								end 
							`EXE_SRLV: begin
									wreg_o <= `WriteEnable;		aluop_o <= `EXE_SRL_OP;
			  						alusel_o <= `EXE_RES_SHIFT;		reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;
			  						instvalid <= `InstValid;	
								end 					
							`EXE_SRAV: begin
									wreg_o <= `WriteEnable;		aluop_o <= `EXE_SRA_OP;
			  						alusel_o <= `EXE_RES_SHIFT;		reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;
			  						instvalid <= `InstValid;			
		  						end
							`EXE_MFHI: begin
									wreg_o <= `WriteEnable;		aluop_o <= `EXE_MFHI_OP;
			  						alusel_o <= `EXE_RES_MOVE;   reg1_read_o <= 1'b0;	
			  						reg2_read_o <= 1'b0;
			  						instvalid <= `InstValid;	
								end
							`EXE_MFLO: begin
									wreg_o <= `WriteEnable;		aluop_o <= `EXE_MFLO_OP;
			  						alusel_o <= `EXE_RES_MOVE;   reg1_read_o <= 1'b0;	
			  						reg2_read_o <= 1'b0;	instvalid <= `InstValid;	
								end
								`EXE_MTHI: begin
									wreg_o <= `WriteDisable;		aluop_o <= `EXE_MTHI_OP;
		  						reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0; instvalid <= `InstValid;	
								end
							`EXE_MTLO: begin
									wreg_o <= `WriteDisable;		aluop_o <= `EXE_MTLO_OP;
		  							reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0; instvalid <= `InstValid;	
								end
							`EXE_MOVN: begin
									aluop_o <= `EXE_MOVN_OP;
			  						alusel_o <= `EXE_RES_MOVE;   reg1_read_o <= 1'b1;	
			  						reg2_read_o <= 1'b1;
			  						instvalid <= `InstValid;
									 	if(reg2_o != `ZeroWord) begin
		 									wreg_o <= `WriteEnable;
		 								end else begin
		 									wreg_o <= `WriteDisable;
		 								end
								end
							`EXE_MOVZ: begin
									aluop_o <= `EXE_MOVZ_OP;
			  						alusel_o <= `EXE_RES_MOVE;   reg1_read_o <= 1'b1;	
			  						reg2_read_o <= 1'b1;
			  						instvalid <= `InstValid;
								 	if(reg2_o == `ZeroWord) begin
	 									wreg_o <= `WriteEnable;
	 								end else begin
	 									wreg_o <= `WriteDisable;
	 								end		  							
								end
							`EXE_SLT: begin
									wreg_o <= `WriteEnable;		aluop_o <= `EXE_SLT_OP;
			  						alusel_o <= `EXE_RES_ARITHMETIC;		reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;
			  						instvalid <= `InstValid;	
								end
							`EXE_SLTU: begin
									wreg_o <= `WriteEnable;		aluop_o <= `EXE_SLTU_OP;
			  						alusel_o <= `EXE_RES_ARITHMETIC;		reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;
			  						instvalid <= `InstValid;	
								end
							`EXE_SYNC: begin
									wreg_o <= `WriteDisable;		aluop_o <= `EXE_NOP_OP;
			  						alusel_o <= `EXE_RES_NOP;		reg1_read_o <= 1'b0;	reg2_read_o <= 1'b1;
			  						instvalid <= `InstValid;	
								end								
							`EXE_ADD: begin
									wreg_o <= `WriteEnable;		aluop_o <= `EXE_ADD_OP;
			  						alusel_o <= `EXE_RES_ARITHMETIC;		reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;
			  						instvalid <= `InstValid;	
								end
							`EXE_ADDU: begin
									wreg_o <= `WriteEnable;		aluop_o <= `EXE_ADDU_OP;
			  						alusel_o <= `EXE_RES_ARITHMETIC;		reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;
			  						instvalid <= `InstValid;	
								end
							`EXE_SUB: begin
									wreg_o <= `WriteEnable;		aluop_o <= `EXE_SUB_OP;
			  						alusel_o <= `EXE_RES_ARITHMETIC;		reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;
			  						instvalid <= `InstValid;	
								end
							`EXE_SUBU: begin
									wreg_o <= `WriteEnable;		aluop_o <= `EXE_SUBU_OP;
			  						alusel_o <= `EXE_RES_ARITHMETIC;		reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;
			  						instvalid <= `InstValid;	
								end
							`EXE_MULT: begin
									wreg_o <= `WriteDisable;		aluop_o <= `EXE_MULT_OP;
		  							reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1; instvalid <= `InstValid;	
								end
							`EXE_MULTU: begin
									wreg_o <= `WriteDisable;		aluop_o <= `EXE_MULTU_OP;
		  							reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1; instvalid <= `InstValid;	
								end
							`EXE_DIV: begin
									wreg_o <= `WriteDisable;		aluop_o <= `EXE_DIV_OP;
		  							reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1; instvalid <= `InstValid;	
								end
							`EXE_DIVU: begin
									wreg_o <= `WriteDisable;		aluop_o <= `EXE_DIVU_OP;
		  							reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1; instvalid <= `InstValid;	
								end			
							`EXE_JR: begin
									wreg_o <= `WriteDisable;		aluop_o <= `EXE_JR_OP;
		  							alusel_o <= `EXE_RES_JUMP_BRANCH;   reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;
		  							link_addr_o <= `ZeroWord;
		  						
					            	branch_target_address_o <= reg1_o;
					            	branch_flag_o <= `Branch;
			           
						            next_inst_in_delayslot_o <= `InDelaySlot;
						            instvalid <= `InstValid;	
								end
							`EXE_JALR: begin
									wreg_o <= `WriteEnable;		aluop_o <= `EXE_JALR_OP;
			  						alusel_o <= `EXE_RES_JUMP_BRANCH;   reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;
			  						wd_o <= inst_i[15:11];
			  						link_addr_o <= pc_plus_8;
		  						
					            	branch_target_address_o <= reg1_o;
					            	branch_flag_o <= `Branch;
			           
						            next_inst_in_delayslot_o <= `InDelaySlot;
						            instvalid <= `InstValid;	
								end													 											  											
						    default:	begin
						    end
						  endcase
						 end
						default: begin
						end
					endcase	
				end									  
		  	`EXE_ORI:			
			  	begin                       
			  		wreg_o <= `WriteEnable;		aluop_o <= `EXE_OR_OP;
			  		alusel_o <= `EXE_RES_LOGIC; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;	  	
						imm <= {16'h0, inst_i[15:0]};		wd_o <= inst_i[20:16];
						instvalid <= `InstValid;	
			  	end
		  	`EXE_ANDI:			
		  		begin
			  		wreg_o <= `WriteEnable;		aluop_o <= `EXE_AND_OP;
			  		alusel_o <= `EXE_RES_LOGIC;	reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;	  	
						imm <= {16'h0, inst_i[15:0]};		wd_o <= inst_i[20:16];		  	
						instvalid <= `InstValid;	
				end	 	
		  	`EXE_XORI:			
		  		begin
			  		wreg_o <= `WriteEnable;		aluop_o <= `EXE_XOR_OP;
			  		alusel_o <= `EXE_RES_LOGIC;	reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;	  	
						//��ȡ������
						imm <= {16'h0, inst_i[15:0]};		
						//ָ��ִ��Ҫд��Ŀ�ļĴ�����ַ	
						wd_o <= inst_i[20:16];		  	
						instvalid <= `InstValid;	
				end	 		
		  	`EXE_LUI:			
		  		begin
			  		wreg_o <= `WriteEnable;		aluop_o <= `EXE_OR_OP;
			  		alusel_o <= `EXE_RES_LOGIC; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;	  	
						imm <= {inst_i[15:0], 16'h0};		wd_o <= inst_i[20:16];		  	
						instvalid <= `InstValid;	
				end			
			`EXE_SLTI:			
				begin
			  		wreg_o <= `WriteEnable;		aluop_o <= `EXE_SLT_OP;
			  		alusel_o <= `EXE_RES_ARITHMETIC; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;	  	
						imm <= {{16{inst_i[15]}}, inst_i[15:0]};		wd_o <= inst_i[20:16];		  	
						instvalid <= `InstValid;	
				end
			`EXE_SLTIU:			
				begin
			  		wreg_o <= `WriteEnable;		aluop_o <= `EXE_SLTU_OP;
			  		alusel_o <= `EXE_RES_ARITHMETIC; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;	  	
						imm <= {{16{inst_i[15]}}, inst_i[15:0]};		wd_o <= inst_i[20:16];		  	
						instvalid <= `InstValid;	
				end
			`EXE_PREF:			
				begin
			  		wreg_o <= `WriteDisable;		aluop_o <= `EXE_NOP_OP;
			  		alusel_o <= `EXE_RES_NOP; reg1_read_o <= 1'b0;	reg2_read_o <= 1'b0;	  	  	
						instvalid <= `InstValid;	
				end						
			`EXE_ADDI:			
				begin
			  		wreg_o <= `WriteEnable;		aluop_o <= `EXE_ADDI_OP;
			  		alusel_o <= `EXE_RES_ARITHMETIC; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;	  	
						imm <= {{16{inst_i[15]}}, inst_i[15:0]};		wd_o <= inst_i[20:16];		  	
						instvalid <= `InstValid;	
				end
			`EXE_ADDIU:			
				begin
			  		wreg_o <= `WriteEnable;		aluop_o <= `EXE_ADDIU_OP;
			  		alusel_o <= `EXE_RES_ARITHMETIC; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;	  	
						imm <= {{16{inst_i[15]}}, inst_i[15:0]};		wd_o <= inst_i[20:16];		  	
						instvalid <= `InstValid;	
				end
			`EXE_J:			
				begin
			  		wreg_o <= `WriteDisable;		aluop_o <= `EXE_J_OP;
			  		alusel_o <= `EXE_RES_JUMP_BRANCH; reg1_read_o <= 1'b0;	reg2_read_o <= 1'b0;
			  		link_addr_o <= `ZeroWord;
				    branch_target_address_o <= {pc_plus_4[31:28], inst_i[25:0], 2'b00};
				    branch_flag_o <= `Branch;
				    next_inst_in_delayslot_o <= `InDelaySlot;		  	
				    instvalid <= `InstValid;	
				end
				`EXE_JAL:	begin
			  		wreg_o <= `WriteEnable;		aluop_o <= `EXE_JAL_OP;
			  		alusel_o <= `EXE_RES_JUMP_BRANCH; reg1_read_o <= 1'b0;	reg2_read_o <= 1'b0;
			  		wd_o <= 5'b11111;	
			  		link_addr_o <= pc_plus_8 ;
				    branch_target_address_o <= {pc_plus_4[31:28], inst_i[25:0], 2'b00};
				    branch_flag_o <= `Branch;
				    next_inst_in_delayslot_o <= `InDelaySlot;		  	
				    instvalid <= `InstValid;	
				end
				`EXE_BEQ:			begin
			  		wreg_o <= `WriteDisable;		aluop_o <= `EXE_BEQ_OP;
			  		alusel_o <= `EXE_RES_JUMP_BRANCH; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;
			  		instvalid <= `InstValid;	
			  		if(reg1_o == reg2_o) begin
				    	branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
				    	branch_flag_o <= `Branch;
				    	next_inst_in_delayslot_o <= `InDelaySlot;		  	
			    	end
				end
				`EXE_BGTZ:			begin
			  		wreg_o <= `WriteDisable;		aluop_o <= `EXE_BGTZ_OP;
			  		alusel_o <= `EXE_RES_JUMP_BRANCH; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;
			  		instvalid <= `InstValid;	
			  		if((reg1_o[31] == 1'b0) && (reg1_o != `ZeroWord)) begin
				    	branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
				    	branch_flag_o <= `Branch;
				    	next_inst_in_delayslot_o <= `InDelaySlot;		  	
				    end
				end
				`EXE_BLEZ:			begin
			  		wreg_o <= `WriteDisable;		aluop_o <= `EXE_BLEZ_OP;
			  		alusel_o <= `EXE_RES_JUMP_BRANCH; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;
			  		instvalid <= `InstValid;	
			  		if((reg1_o[31] == 1'b1) || (reg1_o == `ZeroWord)) begin
				    	branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
				    	branch_flag_o <= `Branch;
				    	next_inst_in_delayslot_o <= `InDelaySlot;		  	
				    end
				end
					`EXE_BNE:			begin
			  		wreg_o <= `WriteDisable;		aluop_o <= `EXE_BLEZ_OP;
			  		alusel_o <= `EXE_RES_JUMP_BRANCH; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;
			  		instvalid <= `InstValid;	
			  		if(reg1_o != reg2_o) begin
				    	branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
				    	branch_flag_o <= `Branch;
				    	next_inst_in_delayslot_o <= `InDelaySlot;		  	
				    end
				end
				`EXE_LB:			begin
			  		wreg_o <= `WriteEnable;		aluop_o <= `EXE_LB_OP;
			  		alusel_o <= `EXE_RES_LOAD_STORE; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;	  	
						wd_o <= inst_i[20:16]; instvalid <= `InstValid;	
				end
				`EXE_LBU:			begin
			  		wreg_o <= `WriteEnable;		aluop_o <= `EXE_LBU_OP;
			  		alusel_o <= `EXE_RES_LOAD_STORE; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;	  	
						wd_o <= inst_i[20:16]; instvalid <= `InstValid;	
				end
				`EXE_LH:			begin
			  		wreg_o <= `WriteEnable;		aluop_o <= `EXE_LH_OP;
			  		alusel_o <= `EXE_RES_LOAD_STORE; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;	  	
						wd_o <= inst_i[20:16]; instvalid <= `InstValid;	
				end
				`EXE_LHU:			begin
			  		wreg_o <= `WriteEnable;		aluop_o <= `EXE_LHU_OP;
			  		alusel_o <= `EXE_RES_LOAD_STORE; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;	  	
						wd_o <= inst_i[20:16]; instvalid <= `InstValid;	
				end
				`EXE_LW:			begin
			  		wreg_o <= `WriteEnable;		aluop_o <= `EXE_LW_OP;
			  		alusel_o <= `EXE_RES_LOAD_STORE; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;	  	
						wd_o <= inst_i[20:16]; instvalid <= `InstValid;	
				end
				`EXE_LL:			begin
			  		wreg_o <= `WriteEnable;		aluop_o <= `EXE_LL_OP;
			  		alusel_o <= `EXE_RES_LOAD_STORE; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;	  	
						wd_o <= inst_i[20:16]; instvalid <= `InstValid;	
				end
				`EXE_LWL:			begin
			  		wreg_o <= `WriteEnable;		aluop_o <= `EXE_LWL_OP;
			  		alusel_o <= `EXE_RES_LOAD_STORE; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;	  	
						wd_o <= inst_i[20:16]; instvalid <= `InstValid;	
				end
				`EXE_LWR:			begin
			  		wreg_o <= `WriteEnable;		aluop_o <= `EXE_LWR_OP;
			  		alusel_o <= `EXE_RES_LOAD_STORE; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;	  	
						wd_o <= inst_i[20:16]; instvalid <= `InstValid;	
				end
				`EXE_SB:			begin
			  		wreg_o <= `WriteDisable;		aluop_o <= `EXE_SB_OP;
			  		reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1; instvalid <= `InstValid;	
			  		alusel_o <= `EXE_RES_LOAD_STORE; 
				end
				`EXE_SH:			begin
			  		wreg_o <= `WriteDisable;		aluop_o <= `EXE_SH_OP;
			  		reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1; instvalid <= `InstValid;	
			  		alusel_o <= `EXE_RES_LOAD_STORE; 
				end
				`EXE_SW:			begin
			  		wreg_o <= `WriteDisable;		aluop_o <= `EXE_SW_OP;
			  		reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1; instvalid <= `InstValid;	
			  		alusel_o <= `EXE_RES_LOAD_STORE; 
				end
				`EXE_SWL:			begin
			  		wreg_o <= `WriteDisable;		aluop_o <= `EXE_SWL_OP;
			  		reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1; instvalid <= `InstValid;	
			  		alusel_o <= `EXE_RES_LOAD_STORE; 
				end
				`EXE_SWR:			begin
			  		wreg_o <= `WriteDisable;		aluop_o <= `EXE_SWR_OP;
			  		reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1; instvalid <= `InstValid;	
			  		alusel_o <= `EXE_RES_LOAD_STORE; 
				end
				`EXE_SC:			begin
			  		wreg_o <= `WriteEnable;		aluop_o <= `EXE_SC_OP;
			  		alusel_o <= `EXE_RES_LOAD_STORE; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;	  	
					wd_o <= inst_i[20:16]; instvalid <= `InstValid;	
					alusel_o <= `EXE_RES_LOAD_STORE; 
				end				
				`EXE_REGIMM_INST:		begin
					case (op4)
						`EXE_BGEZ:	begin
							wreg_o <= `WriteDisable;		aluop_o <= `EXE_BGEZ_OP;
			  				alusel_o <= `EXE_RES_JUMP_BRANCH; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;
			  				instvalid <= `InstValid;	
			  				if(reg1_o[31] == 1'b0) begin
				    			branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
				    			branch_flag_o <= `Branch;
				    			next_inst_in_delayslot_o <= `InDelaySlot;		  	
				   			end
						end
						`EXE_BGEZAL:		begin
							wreg_o <= `WriteEnable;		aluop_o <= `EXE_BGEZAL_OP;
			  				alusel_o <= `EXE_RES_JUMP_BRANCH; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;
			  				link_addr_o <= pc_plus_8; 
			  				wd_o <= 5'b11111;  	instvalid <= `InstValid;
			  				if(reg1_o[31] == 1'b0) begin
				    			branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
				    			branch_flag_o <= `Branch;
				    			next_inst_in_delayslot_o <= `InDelaySlot;
				   			end
						end
						`EXE_BLTZ:		begin
						  	wreg_o <= `WriteDisable;		aluop_o <= `EXE_BGEZAL_OP;
			  				alusel_o <= `EXE_RES_JUMP_BRANCH; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;
			  				instvalid <= `InstValid;	
			  				if(reg1_o[31] == 1'b1) begin
				    			branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
				    			branch_flag_o <= `Branch;
				    			next_inst_in_delayslot_o <= `InDelaySlot;		  	
				   			end
						end
						`EXE_BLTZAL:		begin
							wreg_o <= `WriteEnable;		aluop_o <= `EXE_BGEZAL_OP;
			  				alusel_o <= `EXE_RES_JUMP_BRANCH; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;
			  				link_addr_o <= pc_plus_8;	
			  				wd_o <= 5'b11111; instvalid <= `InstValid;
			  				if(reg1_o[31] == 1'b1) begin
				    			branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
				    			branch_flag_o <= `Branch;
				    			next_inst_in_delayslot_o <= `InDelaySlot;
				   			end
						end
						default:	begin
						end
					endcase
				end								
				`EXE_SPECIAL2_INST:		begin
					case ( op3 )
						`EXE_CLZ:		begin
							wreg_o <= `WriteEnable;		aluop_o <= `EXE_CLZ_OP;
		  					alusel_o <= `EXE_RES_ARITHMETIC; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;	  	
							instvalid <= `InstValid;	
						end
						`EXE_CLO:		begin
							wreg_o <= `WriteEnable;		aluop_o <= `EXE_CLO_OP;
		  					alusel_o <= `EXE_RES_ARITHMETIC; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;	  	
							instvalid <= `InstValid;	
						end
						`EXE_MUL:		begin
							wreg_o <= `WriteEnable;		aluop_o <= `EXE_MUL_OP;
			  				alusel_o <= `EXE_RES_MUL; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;	
			  				instvalid <= `InstValid;	  			
						end
						`EXE_MADD:		begin
							wreg_o <= `WriteDisable;		aluop_o <= `EXE_MADD_OP;
		  					alusel_o <= `EXE_RES_MUL; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;	  			
		  					instvalid <= `InstValid;	
						end
						`EXE_MADDU:		begin
							wreg_o <= `WriteDisable;		aluop_o <= `EXE_MADDU_OP;
		  					alusel_o <= `EXE_RES_MUL; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;	  			
		  					instvalid <= `InstValid;	
						end
						`EXE_MSUB:		begin
							wreg_o <= `WriteDisable;		aluop_o <= `EXE_MSUB_OP;
		  					alusel_o <= `EXE_RES_MUL; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;	  			
		  					instvalid <= `InstValid;	
						end
						`EXE_MSUBU:		begin
							wreg_o <= `WriteDisable;		aluop_o <= `EXE_MSUBU_OP;
		  					alusel_o <= `EXE_RES_MUL; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;	  			
		  					instvalid <= `InstValid;	
						end						
						default:	begin
						end
					endcase      //EXE_SPECIAL_INST2 case
				end																		  	
		    default:			begin
		    end
		  endcase		  //case op
		  
		  if (inst_i[31:21] == 11'b00000000000) begin
		  	if (op3 == `EXE_SLL) begin
			  		wreg_o <= `WriteEnable;		aluop_o <= `EXE_SLL_OP;
			  		alusel_o <= `EXE_RES_SHIFT; reg1_read_o <= 1'b0;	reg2_read_o <= 1'b1;	  	
						imm[4:0] <= inst_i[10:6];		wd_o <= inst_i[15:11];
						instvalid <= `InstValid;	
				end else if ( op3 == `EXE_SRL ) begin
			  		wreg_o <= `WriteEnable;		aluop_o <= `EXE_SRL_OP;
			  		alusel_o <= `EXE_RES_SHIFT; reg1_read_o <= 1'b0;	reg2_read_o <= 1'b1;	  	
						imm[4:0] <= inst_i[10:6];		wd_o <= inst_i[15:11];
						instvalid <= `InstValid;	
				end else if ( op3 == `EXE_SRA ) begin
			  		wreg_o <= `WriteEnable;		aluop_o <= `EXE_SRA_OP;
			  		alusel_o <= `EXE_RES_SHIFT; reg1_read_o <= 1'b0;	reg2_read_o <= 1'b1;	  	
						imm[4:0] <= inst_i[10:6];		wd_o <= inst_i[15:11];
						instvalid <= `InstValid;	
				end
			end		  
		  
		end       //if
	end         //always
/*************************************************************************************
							//ȷ����������Ĳ�����
**************************************************************************************/
	//����reg1_o��ֵ�Ĺ������������������
	//	1�����Regfileģ����˿�1Ҫ��ȡ�ļĴ������Ǵ���ִ�н׶�Ҫд��Ŀ�ļĴ���
	//		��ôֱ�Ӱ�ִ�н׶εĽ��ex_wdata_i��Ϊreg1_o��ֵ
	//  2�����Regfileģ����˿�1Ҫ��ȡ�ļĴ������Ǵ��ڷô�׶�Ҫд��Ŀ�ļĴ���
	//		��ôֱ�Ӱ�ִ�н׶εĽ��mem_wdata_i��Ϊreg1_o��ֵ

	always @ (*) begin
			stallreq_for_reg1_loadrelate <= `NoStop;	
		if(rst == `RstEnable) begin
			reg1_o <= `ZeroWord;	
		end else if(pre_inst_is_load == 1'b1 && ex_wd_i == reg1_addr_o 
								&& reg1_read_o == 1'b1 ) begin
		  stallreq_for_reg1_loadrelate <= `Stop;							
		end else if((reg1_read_o == 1'b1) && (ex_wreg_i == 1'b1) 
								&& (ex_wd_i == reg1_addr_o)) begin
			reg1_o <= ex_wdata_i; 
		end else if((reg1_read_o == 1'b1) && (mem_wreg_i == 1'b1) 
								&& (mem_wd_i == reg1_addr_o)) begin
			reg1_o <= mem_wdata_i; 			
	  end else if(reg1_read_o == 1'b1) begin
	  	reg1_o <= reg1_data_i;
	  end else if(reg1_read_o == 1'b0) begin
	  	reg1_o <= imm;
	  end else begin
	    reg1_o <= `ZeroWord;
	  end
	end

	//����reg2_o��ֵ�Ĺ������������������
	//	1�����Regfileģ����˿�2Ҫ��ȡ�ļĴ������Ǵ���ִ�н׶�Ҫд��Ŀ�ļĴ���
	//		��ôֱ�Ӱ�ִ�н׶εĽ��ex_wdata_i��Ϊreg2_o��ֵ
	//  2�����Regfileģ����˿�2Ҫ��ȡ�ļĴ������Ǵ��ڷô�׶�Ҫд��Ŀ�ļĴ���
	//		��ôֱ�Ӱ�ִ�н׶εĽ��mem_wdata_i��Ϊreg2_o��ֵ	
	always @ (*) begin
			stallreq_for_reg2_loadrelate <= `NoStop;
		if(rst == `RstEnable) begin
			reg2_o <= `ZeroWord;
		end else if(pre_inst_is_load == 1'b1 && ex_wd_i == reg2_addr_o 
								&& reg2_read_o == 1'b1 ) begin
		  stallreq_for_reg2_loadrelate <= `Stop;			
		end else if((reg2_read_o == 1'b1) && (ex_wreg_i == 1'b1) 
								&& (ex_wd_i == reg2_addr_o)) begin
			reg2_o <= ex_wdata_i; 
		end else if((reg2_read_o == 1'b1) && (mem_wreg_i == 1'b1) 
								&& (mem_wd_i == reg2_addr_o)) begin
			reg2_o <= mem_wdata_i;			
	  end else if(reg2_read_o == 1'b1) begin
	  	reg2_o <= reg2_data_i;
	  end else if(reg2_read_o == 1'b0) begin
	  	reg2_o <= imm;
	  end else begin
	    reg2_o <= `ZeroWord;
	  end
	end

	always @ (*) begin
		if(rst == `RstEnable) begin
			is_in_delayslot_o <= `NotInDelaySlot;
		end else begin
		  is_in_delayslot_o <= is_in_delayslot_i;		
	  end
	end

endmodule