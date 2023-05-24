module inst_rom(
	input wire ce,
	input wire[`InstAddrBus] addr,
	output reg[`InstBus] inst
	
);

	reg[`InstBus]  inst_mem[0:`InstMemNum-1];

//	initial $readmemh ( "inst_rom.mem", inst_mem );
//    inst_mem[0][`InstBus] = 32'h20040014;
    
	always @ (*) begin
		if (ce == `ChipDisable) begin
			inst <= `ZeroWord;
			// add FPGA²âÊÔ´úÂë
			inst_mem[0][`InstBus] = 32'h20040014;
			inst_mem[1][`InstBus] = 32'h20032AC2;
			inst_mem[2][`InstBus] = 32'h20050001;
			inst_mem[3][`InstBus] = 32'h20020000;
			inst_mem[4][`InstBus] = 32'h20010001;
			inst_mem[5][`InstBus] = 32'h10230005;
			inst_mem[6][`InstBus] = 32'h00221020;
			inst_mem[7][`InstBus] = 32'h20450000;
			inst_mem[8][`InstBus] = 32'h00220820;
			inst_mem[9][`InstBus] = 32'h20250000;
			inst_mem[10][`InstBus] = 32'h00800008;
	  end else begin
		  inst <= inst_mem[addr[`InstMemNumLog2+1:2]];
		end
	end

endmodule