//给出指令地址，其中实现指令指正寄存器PC，该寄存器的值就是指令地址
module pc_reg(
	input wire clk,    //时钟信号
	input wire	rst,   //复位信号

	//来自控制模块的信息
	input wire[5:0]               stall,

	//来自译码阶段ID模块的信息
	input wire                   branch_flag_i,    //转移指令信号
	input wire[`RegBus]          branch_target_address_i,  //转移指令的目标地址
	output reg[`InstAddrBus] pc,   //要读取的指令地址
	output reg  ce  //指令存储器使能信号
	
);

	always @ (posedge clk) begin
		if (ce == `ChipDisable) begin
			pc <= 32'h00000000;
		end else if(stall[0] == `NoStop) begin    // 不暂停
		  	if(branch_flag_i == `Branch) begin     // 分支 转到分支指令地址
					pc <= branch_target_address_i;
				end else begin
		  		pc <= pc + 4'h4;  // 非分支 pc+4
		  	end
		end
	end
	
	always @ (posedge clk) begin       // 每个时钟上升沿检查复位信号
		if (rst == `RstEnable) begin  // 复位信号有效 将指令存储器使能信号置0
			ce <= `ChipDisable;
		end else begin
			ce <= `ChipEnable;
		end
	end

endmodule