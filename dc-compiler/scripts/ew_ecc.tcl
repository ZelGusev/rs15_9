# Script file for constraining
set design "ew_ecc"

set check_design_rpt_file "${design}_check_design.rpt"
set check_timing_rpt_file "${design}_check_timing.rpt"
set power_rpt_file "${design}_power.rpt"
set report_area_rpt_file "${design}_report_area.rpt"
set report_design_rpt_file "${design}_report_design.rpt"
set report_cell_rpt_file "${design}_report_cell.rpt"
set report_reference_rpt_file "${design}_report_reference.rpt"
set report_port_rpt_file "${design}_report_port.rpt"
set report_net_rpt_file "${design}_report_net.rpt"
set report_compile_options_rpt_file "report_compile_options.rpt"
set report_constraint_rpt_file "${design}_report_constraint.rpt"
set report_timing_rpt_file "${design}_report_timing.rpt"
set report_qor_rpt_file "${design}_report_qor.rpt"

current_design ${design}
# source "${script_path}defaults.tcl"

# Define design environment
set_load 1.3 [all_outputs]

#set DRIVING_CELL DFCND1BWP35P140
#set DRIVING_CELL_PIN Q

#set_driving_cell -lib_cell $DRIVING_CELL -pin $DRIVING_CELL_PIN [all_inputs]
set_driving_cell -lib_cell $DRIVING_CELL [all_inputs]
set_max_transition 3.1 ${design}

# Define design constraints
set clk_name vclk
set clk_period 3
create_clock -period $clk_period vclk
set_input_delay 1 -clock $clk_name {gen correct_n datain chkin}
set_output_delay 1 -clock $clk_name {err_detect err_multpl dataout chkout}
set_clock_uncertainty -setup 0.2 $clk_name

set_max_area 300
# Turn on auto wire load selection
# (library must support this feature)
set auto_wire_load_selection true


compile

#if { [shell_is_in_xg_mode] == 0 } {
#write -hier -o "${db_path}${design}.db"
#} else {
#write -format ddc -hier -out "${ddc_path}${design}.ddc"}

# write -hierarchy -format verilog -output ./outputs/RegisteredAdd Gate.v
# вывести информацию о регистрах в файл
#write -format verilog -output ${source_path}${design}_gate.v
# формирование отчетов
source "${script_path}report.tcl"