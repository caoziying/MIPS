`include "defines.vh"
module openmips_min_sopc_tb(
    output wire sss
);

reg     CLOCK_50;
reg     rst;

   
initial begin
CLOCK_50 = 1'b0;
forever #10 CLOCK_50 = ~CLOCK_50;   // 10ns
end
  
initial begin
rst = `RstEnable;
#195 rst= `RstDisable;
#1100 $stop;
end
   
openmips_min_sopc openmips_min_sopc0(
    .clk(CLOCK_50),
    .rst(rst)	
);

endmodule
