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
//实现了32个32位通用整数寄存器，可以同时进行两个寄存器的读和一个寄存器的写操作
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
	always @ (posedge clk) begin   // 写
	    regs[0] <=`ZeroWord;   // 0号寄存器置0
		if (rst == `RstDisable) begin // 复位信号无效
			if((we == `WriteEnable) && (waddr != `RegNumLog2'h0)) begin  // 有写入信号 并且要写的寄存器非0号寄存器
				regs[waddr] <= wdata;
			end
		end
	end
	
	always @ (*) begin                 // 读
		if(rst == `RstEnable) begin   // 复位信号有效
			  rdata1 <= `ZeroWord;
	  end else if(raddr1 == `RegNumLog2'h0) begin  // 读地址为0号寄存器
	  		rdata1 <= `ZeroWord;   
	  end else if((raddr1 == waddr) && (we == `WriteEnable) // 读的地址为写入地址并且写入与读出信号均有效
	  	            && (re1 == `ReadEnable)) begin          // 则将写入数据赋给读取数据（因为要写入寄存器的数据还未真正写入寄存器）
	  	  rdata1 <= wdata;  
	  end else if(re1 == `ReadEnable) begin    // 写入信号无效 直接将要读取的寄存器数据赋给rdata1
	      rdata1 <= regs[raddr1];
	  end else begin   // 以上条件都不满足，置0
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
