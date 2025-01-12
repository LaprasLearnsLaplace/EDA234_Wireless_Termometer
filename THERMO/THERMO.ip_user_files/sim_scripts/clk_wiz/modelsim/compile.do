vlib modelsim_lib/work
vlib modelsim_lib/msim

vlib modelsim_lib/msim/xil_defaultlib

vmap xil_defaultlib modelsim_lib/msim/xil_defaultlib

vlog -work xil_defaultlib -64 -incr "+incdir+../../../ipstatic" \
"../../../../THERMO.srcs/sources_1/ip/clk_wiz/clk_wiz_clk_wiz.v" \
"../../../../THERMO.srcs/sources_1/ip/clk_wiz/clk_wiz.v" \


vlog -work xil_defaultlib \
"glbl.v"

