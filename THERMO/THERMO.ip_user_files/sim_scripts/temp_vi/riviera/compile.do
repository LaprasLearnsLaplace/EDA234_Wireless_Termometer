vlib work
vlib riviera

vlib riviera/xil_defaultlib

vmap xil_defaultlib riviera/xil_defaultlib

vlog -work xil_defaultlib  -v2k5 "+incdir+../../../../THERMO.srcs/sources_1/ip/temp_vi/hdl/verilog" "+incdir+../../../../THERMO.srcs/sources_1/ip/temp_vi/hdl" \
"../../../../THERMO.srcs/sources_1/ip/temp_vi/sim/temp_vi.v" \


vlog -work xil_defaultlib \
"glbl.v"

