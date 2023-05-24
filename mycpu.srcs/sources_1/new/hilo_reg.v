module hilo_reg(
	input wire			    clk,  // 时钟信号
	input wire				rst,  // 复位信号
	input wire				we,   // HI、LO寄存器写使能信号
	input wire[`RegBus]		hi_i, // 要写入HI寄存器的值
	input wire[`RegBus]		lo_i, // 要写入LO寄存器的值
	output reg[`RegBus]     hi_o, // HI寄存器的值
	output reg[`RegBus]     lo_o  // LO寄存器的值

	);

	always @ (posedge clk) begin
		if (rst == `RstEnable) begin
					hi_o <= `ZeroWord;
					lo_o <= `ZeroWord;
		end else if((we == `WriteEnable)) begin
					hi_o <= hi_i;
					lo_o <= lo_i;
		end
	end

	endmodule