vlib work
vlib riviera

vlib riviera/xpm
vlib riviera/xil_defaultlib

vmap xpm riviera/xpm
vmap xil_defaultlib riviera/xil_defaultlib

vlog -work xpm  -sv2k12 \
"C:/Xilinx/Vivado/2019.2/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \

vcom -work xpm -93 \
"C:/Xilinx/Vivado/2019.2/data/ip/xpm/xpm_VCOMP.vhd" \

vlog -work xil_defaultlib  -v2k5 \
"../../../../THERMO.srcs/sources_1/ip/MIG/MIG/user_design/rtl/clocking/mig_7series_v4_2_clk_ibuf.v" \
"../../../../THERMO.srcs/sources_1/ip/MIG/MIG/user_design/rtl/clocking/mig_7series_v4_2_infrastructure.v" \
"../../../../THERMO.srcs/sources_1/ip/MIG/MIG/user_design/rtl/clocking/mig_7series_v4_2_iodelay_ctrl.v" \
"../../../../THERMO.srcs/sources_1/ip/MIG/MIG/user_design/rtl/clocking/mig_7series_v4_2_tempmon.v" \
"../../../../THERMO.srcs/sources_1/ip/MIG/MIG/user_design/rtl/controller/mig_7series_v4_2_arb_mux.v" \
"../../../../THERMO.srcs/sources_1/ip/MIG/MIG/user_design/rtl/controller/mig_7series_v4_2_arb_row_col.v" \
"../../../../THERMO.srcs/sources_1/ip/MIG/MIG/user_design/rtl/controller/mig_7series_v4_2_arb_select.v" \
"../../../../THERMO.srcs/sources_1/ip/MIG/MIG/user_design/rtl/controller/mig_7series_v4_2_bank_cntrl.v" \
"../../../../THERMO.srcs/sources_1/ip/MIG/MIG/user_design/rtl/controller/mig_7series_v4_2_bank_common.v" \
"../../../../THERMO.srcs/sources_1/ip/MIG/MIG/user_design/rtl/controller/mig_7series_v4_2_bank_compare.v" \
"../../../../THERMO.srcs/sources_1/ip/MIG/MIG/user_design/rtl/controller/mig_7series_v4_2_bank_mach.v" \
"../../../../THERMO.srcs/sources_1/ip/MIG/MIG/user_design/rtl/controller/mig_7series_v4_2_bank_queue.v" \
"../../../../THERMO.srcs/sources_1/ip/MIG/MIG/user_design/rtl/controller/mig_7series_v4_2_bank_state.v" \
"../../../../THERMO.srcs/sources_1/ip/MIG/MIG/user_design/rtl/controller/mig_7series_v4_2_col_mach.v" \
"../../../../THERMO.srcs/sources_1/ip/MIG/MIG/user_design/rtl/controller/mig_7series_v4_2_mc.v" \
"../../../../THERMO.srcs/sources_1/ip/MIG/MIG/user_design/rtl/controller/mig_7series_v4_2_rank_cntrl.v" \
"../../../../THERMO.srcs/sources_1/ip/MIG/MIG/user_design/rtl/controller/mig_7series_v4_2_rank_common.v" \
"../../../../THERMO.srcs/sources_1/ip/MIG/MIG/user_design/rtl/controller/mig_7series_v4_2_rank_mach.v" \
"../../../../THERMO.srcs/sources_1/ip/MIG/MIG/user_design/rtl/controller/mig_7series_v4_2_round_robin_arb.v" \
"../../../../THERMO.srcs/sources_1/ip/MIG/MIG/user_design/rtl/ecc/mig_7series_v4_2_ecc_buf.v" \
"../../../../THERMO.srcs/sources_1/ip/MIG/MIG/user_design/rtl/ecc/mig_7series_v4_2_ecc_dec_fix.v" \
"../../../../THERMO.srcs/sources_1/ip/MIG/MIG/user_design/rtl/ecc/mig_7series_v4_2_ecc_gen.v" \
"../../../../THERMO.srcs/sources_1/ip/MIG/MIG/user_design/rtl/ecc/mig_7series_v4_2_ecc_merge_enc.v" \
"../../../../THERMO.srcs/sources_1/ip/MIG/MIG/user_design/rtl/ecc/mig_7series_v4_2_fi_xor.v" \
"../../../../THERMO.srcs/sources_1/ip/MIG/MIG/user_design/rtl/ip_top/mig_7series_v4_2_memc_ui_top_std.v" \
"../../../../THERMO.srcs/sources_1/ip/MIG/MIG/user_design/rtl/ip_top/mig_7series_v4_2_mem_intfc.v" \
"../../../../THERMO.srcs/sources_1/ip/MIG/MIG/user_design/rtl/phy/mig_7series_v4_2_ddr_byte_group_io.v" \
"../../../../THERMO.srcs/sources_1/ip/MIG/MIG/user_design/rtl/phy/mig_7series_v4_2_ddr_byte_lane.v" \
"../../../../THERMO.srcs/sources_1/ip/MIG/MIG/user_design/rtl/phy/mig_7series_v4_2_ddr_calib_top.v" \
"../../../../THERMO.srcs/sources_1/ip/MIG/MIG/user_design/rtl/phy/mig_7series_v4_2_ddr_if_post_fifo.v" \
"../../../../THERMO.srcs/sources_1/ip/MIG/MIG/user_design/rtl/phy/mig_7series_v4_2_ddr_mc_phy.v" \
"../../../../THERMO.srcs/sources_1/ip/MIG/MIG/user_design/rtl/phy/mig_7series_v4_2_ddr_mc_phy_wrapper.v" \
"../../../../THERMO.srcs/sources_1/ip/MIG/MIG/user_design/rtl/phy/mig_7series_v4_2_ddr_of_pre_fifo.v" \
"../../../../THERMO.srcs/sources_1/ip/MIG/MIG/user_design/rtl/phy/mig_7series_v4_2_ddr_phy_4lanes.v" \
"../../../../THERMO.srcs/sources_1/ip/MIG/MIG/user_design/rtl/phy/mig_7series_v4_2_ddr_phy_ck_addr_cmd_delay.v" \
"../../../../THERMO.srcs/sources_1/ip/MIG/MIG/user_design/rtl/phy/mig_7series_v4_2_ddr_phy_dqs_found_cal.v" \
"../../../../THERMO.srcs/sources_1/ip/MIG/MIG/user_design/rtl/phy/mig_7series_v4_2_ddr_phy_dqs_found_cal_hr.v" \
"../../../../THERMO.srcs/sources_1/ip/MIG/MIG/user_design/rtl/phy/mig_7series_v4_2_ddr_phy_init.v" \
"../../../../THERMO.srcs/sources_1/ip/MIG/MIG/user_design/rtl/phy/mig_7series_v4_2_ddr_phy_ocd_cntlr.v" \
"../../../../THERMO.srcs/sources_1/ip/MIG/MIG/user_design/rtl/phy/mig_7series_v4_2_ddr_phy_ocd_data.v" \
"../../../../THERMO.srcs/sources_1/ip/MIG/MIG/user_design/rtl/phy/mig_7series_v4_2_ddr_phy_ocd_edge.v" \
"../../../../THERMO.srcs/sources_1/ip/MIG/MIG/user_design/rtl/phy/mig_7series_v4_2_ddr_phy_ocd_lim.v" \
"../../../../THERMO.srcs/sources_1/ip/MIG/MIG/user_design/rtl/phy/mig_7series_v4_2_ddr_phy_ocd_mux.v" \
"../../../../THERMO.srcs/sources_1/ip/MIG/MIG/user_design/rtl/phy/mig_7series_v4_2_ddr_phy_ocd_po_cntlr.v" \
"../../../../THERMO.srcs/sources_1/ip/MIG/MIG/user_design/rtl/phy/mig_7series_v4_2_ddr_phy_ocd_samp.v" \
"../../../../THERMO.srcs/sources_1/ip/MIG/MIG/user_design/rtl/phy/mig_7series_v4_2_ddr_phy_oclkdelay_cal.v" \
"../../../../THERMO.srcs/sources_1/ip/MIG/MIG/user_design/rtl/phy/mig_7series_v4_2_ddr_phy_prbs_rdlvl.v" \
"../../../../THERMO.srcs/sources_1/ip/MIG/MIG/user_design/rtl/phy/mig_7series_v4_2_ddr_phy_rdlvl.v" \
"../../../../THERMO.srcs/sources_1/ip/MIG/MIG/user_design/rtl/phy/mig_7series_v4_2_ddr_phy_tempmon.v" \
"../../../../THERMO.srcs/sources_1/ip/MIG/MIG/user_design/rtl/phy/mig_7series_v4_2_ddr_phy_top.v" \
"../../../../THERMO.srcs/sources_1/ip/MIG/MIG/user_design/rtl/phy/mig_7series_v4_2_ddr_phy_wrcal.v" \
"../../../../THERMO.srcs/sources_1/ip/MIG/MIG/user_design/rtl/phy/mig_7series_v4_2_ddr_phy_wrlvl.v" \
"../../../../THERMO.srcs/sources_1/ip/MIG/MIG/user_design/rtl/phy/mig_7series_v4_2_ddr_phy_wrlvl_off_delay.v" \
"../../../../THERMO.srcs/sources_1/ip/MIG/MIG/user_design/rtl/phy/mig_7series_v4_2_ddr_prbs_gen.v" \
"../../../../THERMO.srcs/sources_1/ip/MIG/MIG/user_design/rtl/phy/mig_7series_v4_2_poc_cc.v" \
"../../../../THERMO.srcs/sources_1/ip/MIG/MIG/user_design/rtl/phy/mig_7series_v4_2_poc_edge_store.v" \
"../../../../THERMO.srcs/sources_1/ip/MIG/MIG/user_design/rtl/phy/mig_7series_v4_2_poc_meta.v" \
"../../../../THERMO.srcs/sources_1/ip/MIG/MIG/user_design/rtl/phy/mig_7series_v4_2_poc_pd.v" \
"../../../../THERMO.srcs/sources_1/ip/MIG/MIG/user_design/rtl/phy/mig_7series_v4_2_poc_tap_base.v" \
"../../../../THERMO.srcs/sources_1/ip/MIG/MIG/user_design/rtl/phy/mig_7series_v4_2_poc_top.v" \
"../../../../THERMO.srcs/sources_1/ip/MIG/MIG/user_design/rtl/ui/mig_7series_v4_2_ui_cmd.v" \
"../../../../THERMO.srcs/sources_1/ip/MIG/MIG/user_design/rtl/ui/mig_7series_v4_2_ui_rd_data.v" \
"../../../../THERMO.srcs/sources_1/ip/MIG/MIG/user_design/rtl/ui/mig_7series_v4_2_ui_top.v" \
"../../../../THERMO.srcs/sources_1/ip/MIG/MIG/user_design/rtl/ui/mig_7series_v4_2_ui_wr_data.v" \
"../../../../THERMO.srcs/sources_1/ip/MIG/MIG/user_design/rtl/MIG_mig_sim.v" \
"../../../../THERMO.srcs/sources_1/ip/MIG/MIG/user_design/rtl/MIG.v" \

vlog -work xil_defaultlib \
"glbl.v"

