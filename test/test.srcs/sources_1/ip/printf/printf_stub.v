// Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2019.2 (win64) Build 2708876 Wed Nov  6 21:40:23 MST 2019
// Date        : Fri Dec 20 15:48:48 2024
// Host        : GotohHitori running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               c:/Users/A/Desktop/EDA234/test/test.srcs/sources_1/ip/printf/printf_stub.v
// Design      : printf
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7a100tcsg324-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* X_CORE_INFO = "vio,Vivado 2019.2" *)
module printf(clk, probe_in0)
/* synthesis syn_black_box black_box_pad_pin="clk,probe_in0[7:0]" */;
  input clk;
  input [7:0]probe_in0;
endmodule
