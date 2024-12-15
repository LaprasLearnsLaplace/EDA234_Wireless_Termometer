vlib work
vlib activehdl

vlib activehdl/xil_defaultlib

vmap xil_defaultlib activehdl/xil_defaultlib

vlog -work xil_defaultlib  -v2k5 "+incdir+../../../../THERMO.srcs/sources_1/ip/temp_vi/hdl/verilog" "+incdir+../../../../THERMO.srcs/sources_1/ip/temp_vi/hdl" \
"../../../../THERMO.srcs/sources_1/ip/temp_vi/sim/temp_vi.v" \


vlog -work xil_defaultlib \
"glbl.v"

