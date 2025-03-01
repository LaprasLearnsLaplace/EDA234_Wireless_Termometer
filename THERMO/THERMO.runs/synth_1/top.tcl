# 
# Synthesis run script generated by Vivado
# 

set TIME_start [clock seconds] 
proc create_report { reportName command } {
  set status "."
  append status $reportName ".fail"
  if { [file exists $status] } {
    eval file delete [glob $status]
  }
  send_msg_id runtcl-4 info "Executing : $command"
  set retval [eval catch { $command } msg]
  if { $retval != 0 } {
    set fp [open $status w]
    close $fp
    send_msg_id runtcl-5 warning "$msg"
  }
}
set_param chipscope.maxJobs 5
set_param xicom.use_bs_reader 1
create_project -in_memory -part xc7a100tcsg324-1

set_param project.singleFileAddWarning.threshold 0
set_param project.compositeFile.enableAutoGeneration 0
set_param synth.vivado.isSynthRun true
set_msg_config -source 4 -id {IP_Flow 19-2162} -severity warning -new_severity info
set_property webtalk.parent_dir C:/Users/A/Desktop/EDA234/THERMO/THERMO.cache/wt [current_project]
set_property parent.project_path C:/Users/A/Desktop/EDA234/THERMO/THERMO.xpr [current_project]
set_property XPM_LIBRARIES XPM_CDC [current_project]
set_property default_lib xil_defaultlib [current_project]
set_property target_language Verilog [current_project]
set_property ip_output_repo c:/Users/A/Desktop/EDA234/THERMO/THERMO.cache/ip [current_project]
set_property ip_cache_permissions {read write} [current_project]
read_vhdl -library xil_defaultlib {
  C:/Users/A/Desktop/EDA234/SDRAM/DDR2.vhdl
  C:/Users/A/Desktop/EDA234/LCD/LCD_ctrl.vhdl
  C:/Users/A/Desktop/EDA234/SDRAM/Ram2Ddr.vhd
  C:/Users/A/Desktop/EDA234/Temp_ADT7420/clk_200KHz.vhd
  C:/Users/A/Desktop/EDA234/FPGA_Internal/find_max_min.vhd
  C:/Users/A/Desktop/EDA234/Temp_ADT7420/i2c_ctrl.vhd
  C:/Users/A/Desktop/EDA234/Keyboard/keyboard.vhdl
  C:/Users/A/Desktop/EDA234/SDRAM/mem_ctrl.vhdl
  C:/Users/A/Desktop/EDA234/Temp_ADT7420/seg7.vhd
  C:/Users/A/Desktop/EDA234/Alarm/speaker.vhd
  C:/Users/A/Desktop/EDA234/FPGA_Internal/temp_comp.vhd
  C:/Users/A/Desktop/EDA234/Temp_ADT7420/temp_top.vhd
  C:/Users/A/Desktop/EDA234/UART/uart_rx.vhdl
  C:/Users/A/Desktop/EDA234/top.vhdl
}
read_ip -quiet C:/Users/A/Desktop/EDA234/THERMO/THERMO.srcs/sources_1/ip/printf/printf.xci
set_property used_in_implementation false [get_files -all c:/Users/A/Desktop/EDA234/THERMO/THERMO.srcs/sources_1/ip/printf/printf.xdc]
set_property used_in_implementation false [get_files -all c:/Users/A/Desktop/EDA234/THERMO/THERMO.srcs/sources_1/ip/printf/printf_ooc.xdc]

read_ip -quiet C:/Users/A/Desktop/EDA234/THERMO/THERMO.srcs/sources_1/ip/clk_wiz/clk_wiz.xci
set_property used_in_implementation false [get_files -all c:/Users/A/Desktop/EDA234/THERMO/THERMO.srcs/sources_1/ip/clk_wiz/clk_wiz_board.xdc]
set_property used_in_implementation false [get_files -all c:/Users/A/Desktop/EDA234/THERMO/THERMO.srcs/sources_1/ip/clk_wiz/clk_wiz.xdc]
set_property used_in_implementation false [get_files -all c:/Users/A/Desktop/EDA234/THERMO/THERMO.srcs/sources_1/ip/clk_wiz/clk_wiz_ooc.xdc]

read_ip -quiet C:/Users/A/Desktop/EDA234/THERMO/THERMO.srcs/sources_1/ip/MIG/MIG.xci
set_property used_in_implementation false [get_files -all c:/Users/A/Desktop/EDA234/THERMO/THERMO.srcs/sources_1/ip/MIG/MIG/user_design/constraints/MIG.xdc]
set_property used_in_implementation false [get_files -all c:/Users/A/Desktop/EDA234/THERMO/THERMO.srcs/sources_1/ip/MIG/MIG/user_design/constraints/MIG_ooc.xdc]

# Mark all dcp files as not used in implementation to prevent them from being
# stitched into the results of this synthesis run. Any black boxes in the
# design are intentionally left as such for best results. Dcp files will be
# stitched into the design at a later time, either when this synthesis run is
# opened, or when it is stitched into a dependent implementation run.
foreach dcp [get_files -quiet -all -filter file_type=="Design\ Checkpoint"] {
  set_property used_in_implementation false $dcp
}
read_xdc C:/Users/A/Desktop/EDA234/CONSTRAINS.xdc
set_property used_in_implementation false [get_files C:/Users/A/Desktop/EDA234/CONSTRAINS.xdc]

read_xdc dont_touch.xdc
set_property used_in_implementation false [get_files dont_touch.xdc]
set_param ips.enableIPCacheLiteLoad 1
close [open __synthesis_is_running__ w]

synth_design -top top -part xc7a100tcsg324-1


# disable binary constraint mode for synth run checkpoints
set_param constraints.enableBinaryConstraints false
write_checkpoint -force -noxdef top.dcp
create_report "synth_1_synth_report_utilization_0" "report_utilization -file top_utilization_synth.rpt -pb top_utilization_synth.pb"
file delete __synthesis_is_running__
close [open __synthesis_is_complete__ w]
