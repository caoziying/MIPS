`timescale 1ns / 1ps
//实现取指与译码阶段之间的寄存器，将取指阶段的结果在下一个时钟传递到译码阶段
module if_id(
	input wire clk,
	input wire rst,
	// 流水线暂停信号
	input wire[5:0] stall,	

	input wire[`InstAddrBus] if_pc,    // 取指模块输入的 pc
	input wire[`InstBus] if_inst,      // 取指模块输入的 指令
	output reg[`InstAddrBus] id_pc,    // 输出到译码模块的 pc
	output reg[`InstBus] id_inst       // 输出到译码模块的 指令
);

	always @ (posedge clk) begin
		if (rst == `RstEnable) begin  // 复位
			id_pc <= `ZeroWord;       // id_pc 置全0
			id_inst <= `ZeroWord;    // 指令置空（0）
		end else if(stall[1] == `Stop && stall[2] == `NoStop) begin   // 流水线暂停*
			id_pc <= `ZeroWord;
			id_inst <= `ZeroWord;	
	  end else if(stall[1] == `NoStop) begin   // 流水线正常
		  id_pc <= if_pc;
		  id_inst <= if_inst;
		end
	end

endmodule

