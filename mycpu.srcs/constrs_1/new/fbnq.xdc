#LED引脚
set_property -dict {PACKAGE_PIN F6 IOSTANDARD LVCMOS33} [get_ports {display[0]}]
set_property -dict {PACKAGE_PIN G4 IOSTANDARD LVCMOS33} [get_ports {display[1]}]
set_property -dict {PACKAGE_PIN G3 IOSTANDARD LVCMOS33} [get_ports {display[2]}]
set_property -dict {PACKAGE_PIN J4 IOSTANDARD LVCMOS33} [get_ports {display[3]}]
set_property -dict {PACKAGE_PIN H4 IOSTANDARD LVCMOS33} [get_ports {display[4]}]
set_property -dict {PACKAGE_PIN J3 IOSTANDARD LVCMOS33} [get_ports {display[5]}]
set_property -dict {PACKAGE_PIN J2 IOSTANDARD LVCMOS33} [get_ports {display[6]}]
set_property -dict {PACKAGE_PIN K2 IOSTANDARD LVCMOS33} [get_ports {display[7]}]
# 时钟约束50MHz
set_property -dict { PACKAGE_PIN P17 IOSTANDARD LVCMOS33 } [get_ports {clk}]; 
create_clock -add -name sys_clk_pin -period 20.00 -waveform {0 10} [get_ports {clk}];

# 时钟引脚
set_property IOSTANDARD LVCMOS33 [get_ports clk]
set_property PACKAGE_PIN P17 [get_ports clk]

set_property PACKAGE_PIN Y29 [get_ports {sss}]