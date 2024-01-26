# Define the target logic library, symbol library, link libraries
# default lib is : 

#set symbol_library generic.sdb            
#set target_library lsi_10k.db gtech.db
#set link_library dw_foundation.sldb
#set link_library [concat $target_library "*"]
#set search_path [concat $search_path ./src]
#//////////////////////////////// first libs
#       Load libraries
set snps [getenv SYNOPSYS]
#set LIB_DIR "/usr/corp/fabs/TSMC/TSMC28HPC/TSMC/current/logic/9-track/tcbn28hpcbwp30p140/tcbn28hpcbwp30p140_100b/TSMCHOME/digital"
set LIB_DIR "/usr/corp/fabs/TSMC/TSMC65LP/TSMC/current/logic/hd/tcbn65lp/tcbn65lp_200c/TSMCHOME/digital/"

# Search paths
set search_path [list \
                $snps/libraries/syn/ \
                $snps/dw/sim_ver/ \
                $snps/minpower/syn/ \
                /usr/corp/fabs/Fujitsu/IP_Libs_07092010_UPD/release-synlib-06Sep2010/db/ \
               ./
]

set mw_reference_library [list \
                $LIB_DIR/Back_End/milkyway/tcbn65lp_200a
]

set link_library [list \
                dw_foundation.sldb \
                tcbn65lptc.db \
]

set synthetic_library [list \
                standard.sldb \
                dw_foundation.sldb \
]
#/////////////////////////////////////////////////////
#// входной элемент
set DRIVING_CELL DFD1BWP35P140
#//////////////////////////////////////////second libs
set db_svt /usr/corp/fabs/TSMC/TSMC28HT/TSMC/current/logic/9track/35p/tcbn28hpcplusbwp35p140/tcbn28hpcplusbwp35p140_190a/Front_End/timing_power_noise/CCS/tcbn28hpcplusbwp35p140_180a/tcbn28hpcplusbwp35p140ssg0p81v0c_ccs.db
set db_hvt /usr/corp/fabs/TSMC/TSMC28HT/TSMC/current/logic/9track/35p/tcbn28hpcplusbwp35p140/tcbn28hpcplusbwp35p140hvt_190a/Front_End/timing_power_noise/CCS/tcbn28hpcplusbwp35p140hvt_180a/tcbn28hpcplusbwp35p140hvtssg0p81v0c_ccs.db
#set db_lvt /usr/corp/fabs/TSMC/TSMC28HT/TSMC/current/logic/9track/35p/tcbn28hpcplusbwp35p140/tcbn28hpcplusbwp35p140lvt_190a/Front_End/timing_power_noise/CCS/tcbn28hpcplusbwp35p140lvt_180a/tcbn28hpcplusbwp35p140lvtssg0p81v0c_ccs.db
# Set libraries
# ------------------------------------------------------------------------------
set target_library "$db_svt $db_hvt"
set synthetic_library "$synthetic_library dw_foundation.sldb standard.sldb"
set synthetic_library "$synthetic_library standard.sldb"
set symbol_library "$symbol_library generic.sdb"
set link_library "$target_library $synthetic_library *"

set_attribute    [get_lib_cells [list tcbn28hpcplusbwp35p140ssg0p81v0c_ccs/*   ]] threshold_voltage_group svt_st
set_attribute    [get_lib_cells [list tcbn28hpcplusbwp35p140hvtssg0p81v0c_ccs/*]] threshold_voltage_group hvt_st
#////////////////////////////////////////////////////////////////////

# Common settings
set hdlin_vrlg_std 2005
set hdlin_check_no_latch true
set hdlin_translate_off_skip_text true
set verilogout_write_components true
# Determines the name that will be used for the architecture of the write -f verilog command
set verilogout_architecture_name "structural"
# Turn tri state nets from "tri" to "wire"
set verilogout_no_tri true
# Treat text between translate statements as comments
#set hdlin_translate_off_skip_text true
# List of package commands
set vhdlout_use_packages [list IEEE.std_logic_1164.ALL]
# Write out component declarations for cells mapped to a technology library.
set vhdlout_write_components true
# Determines the name that will be used for the architecture of the write -f vhdl command
set vhdlout_architecture_name "structural"
# Treat text between translate statements as comments
set hdlin_translate_off_skip_text true
# Specify the styel to use in naming an individual port member
set bus_naming_style {%s[%d]}


# Define path directories for file locations
set source_path "./rtl/src/"
set script_path "./dc-compiler/scripts/"
set log_path "./dc-compiler/reports/"
set ddc_path "./dc-compiler/ddc/"
set db_path "./dc-compiler/db/"
set netlist_path "./dc-compiler/netlist/"