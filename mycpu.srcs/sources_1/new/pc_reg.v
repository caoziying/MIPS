//����ָ���ַ������ʵ��ָ��ָ���Ĵ���PC���üĴ�����ֵ����ָ���ַ
module pc_reg(
	input wire clk,    //ʱ���ź�
	input wire	rst,   //��λ�ź�

	//���Կ���ģ�����Ϣ
	input wire[5:0]               stall,

	//��������׶�IDģ�����Ϣ
	input wire                   branch_flag_i,    //ת��ָ���ź�
	input wire[`RegBus]          branch_target_address_i,  //ת��ָ���Ŀ���ַ
	output reg[`InstAddrBus] pc,   //Ҫ��ȡ��ָ���ַ
	output reg  ce  //ָ��洢��ʹ���ź�
	
);

	always @ (posedge clk) begin
		if (ce == `ChipDisable) begin
			pc <= 32'h00000000;
		end else if(stall[0] == `NoStop) begin    // ����ͣ
		  	if(branch_flag_i == `Branch) begin     // ��֧ ת����ָ֧���ַ
					pc <= branch_target_address_i;
				end else begin
		  		pc <= pc + 4'h4;  // �Ƿ�֧ pc+4
		  	end
		end
	end
	
	always @ (posedge clk) begin       // ÿ��ʱ�������ؼ�鸴λ�ź�
		if (rst == `RstEnable) begin  // ��λ�ź���Ч ��ָ��洢��ʹ���ź���0
			ce <= `ChipDisable;
		end else begin
			ce <= `ChipEnable;
		end
	end

endmodule