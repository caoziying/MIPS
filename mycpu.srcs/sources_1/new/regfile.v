`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/12/25 15:25:20
// Design Name: 
// Module Name: regfile
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`include "defines.vh"
//ʵ����32��32λͨ�������Ĵ���������ͬʱ���������Ĵ����Ķ���һ���Ĵ�����д����
module regfile(

	input	wire	clk,
	input   wire	rst,
	
	
	input wire		we,
	input wire[`RegAddrBus]		waddr,
	input wire[`RegBus]			wdata,
	

	input wire					re1,
	input wire[`RegAddrBus]		raddr1,
	output reg[`RegBus]         rdata1,
	

	input wire					re2,
	input wire[`RegAddrBus]		raddr2,
	output reg[`RegBus]         rdata2,
	output wire[`RegBus]       re3
);

	reg[`RegBus]  regs[0:`RegNum-1];
    assign re3 = regs[5];
	always @ (posedge clk) begin   // д
	    regs[0] <=`ZeroWord;   // 0�żĴ�����0
		if (rst == `RstDisable) begin // ��λ�ź���Ч
			if((we == `WriteEnable) && (waddr != `RegNumLog2'h0)) begin  // ��д���ź� ����Ҫд�ļĴ�����0�żĴ���
				regs[waddr] <= wdata;
			end
		end
	end
	
	always @ (*) begin                 // ��
		if(rst == `RstEnable) begin   // ��λ�ź���Ч
			  rdata1 <= `ZeroWord;
	  end else if(raddr1 == `RegNumLog2'h0) begin  // ����ַΪ0�żĴ���
	  		rdata1 <= `ZeroWord;   
	  end else if((raddr1 == waddr) && (we == `WriteEnable) // ���ĵ�ַΪд���ַ����д��������źž���Ч
	  	            && (re1 == `ReadEnable)) begin          // ��д�����ݸ�����ȡ���ݣ���ΪҪд��Ĵ��������ݻ�δ����д��Ĵ�����
	  	  rdata1 <= wdata;  
	  end else if(re1 == `ReadEnable) begin    // д���ź���Ч ֱ�ӽ�Ҫ��ȡ�ļĴ������ݸ���rdata1
	      rdata1 <= regs[raddr1];
	  end else begin   // ���������������㣬��0
	      rdata1 <= `ZeroWord;
	  end
	end

	always @ (*) begin
		if(rst == `RstEnable) begin
			  rdata2 <= `ZeroWord;
	  end else if(raddr2 == `RegNumLog2'h0) begin
	  		rdata2 <= `ZeroWord;
	  end else if((raddr2 == waddr) && (we == `WriteEnable) 
	  	            && (re2 == `ReadEnable)) begin
	  	  rdata2 <= wdata;
	  end else if(re2 == `ReadEnable) begin
	      rdata2 <= regs[raddr2];
	  end else begin
	      rdata2 <= `ZeroWord;
	  end
	end
endmodule
