`timescale 1ns / 1ps
//ʵ��ȡָ������׶�֮��ļĴ�������ȡָ�׶εĽ������һ��ʱ�Ӵ��ݵ�����׶�
module if_id(
	input wire clk,
	input wire rst,
	// ��ˮ����ͣ�ź�
	input wire[5:0] stall,	

	input wire[`InstAddrBus] if_pc,    // ȡָģ������� pc
	input wire[`InstBus] if_inst,      // ȡָģ������� ָ��
	output reg[`InstAddrBus] id_pc,    // ���������ģ��� pc
	output reg[`InstBus] id_inst       // ���������ģ��� ָ��
);

	always @ (posedge clk) begin
		if (rst == `RstEnable) begin  // ��λ
			id_pc <= `ZeroWord;       // id_pc ��ȫ0
			id_inst <= `ZeroWord;    // ָ���ÿգ�0��
		end else if(stall[1] == `Stop && stall[2] == `NoStop) begin   // ��ˮ����ͣ*
			id_pc <= `ZeroWord;
			id_inst <= `ZeroWord;	
	  end else if(stall[1] == `NoStop) begin   // ��ˮ������
		  id_pc <= if_pc;
		  id_inst <= if_inst;
		end
	end

endmodule

