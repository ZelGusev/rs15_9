# This script file creates reports for all modules
set maxpaths 5

check_design > "${log_path}${check_design_rpt_file}"
check_timing >> "${log_path}${check_timing_rpt_file}"
report_power >> "${log_path}${power_rpt_file}"
report_area >> "${log_path}${report_area_rpt_file}"
report_design >> "${log_path}${report_design_rpt_file}"
report_cell >> "${log_path}${report_cell_rpt_file}"
report_reference >> "${log_path}${report_reference_rpt_file}"
report_port -verbose >> "${log_path}${report_port_rpt_file}"
report_net >> "${log_path}${report_net_rpt_file}"
report_compile_options >> "${log_path}${report_compile_options_rpt_file}"
report_constraint -all_violators -verbose >> "${log_path}${report_constraint_rpt_file}"
report_timing -path end >> "${log_path}${report_timing_rpt_file}"
report_timing -max_path $maxpaths >> "${log_path}${report_timing_rpt_file}"
report_qor >> "${log_path}${report_qor_rpt_file}"