suppress_message UID-401
# Define system clock period
set clk_period 3

# Create real clock if clock port is found
if {[sizeof_collection [get_ports clk]] > 0} {
    set clk_name clk
    create_clock -period $clk_period clk
    # If real clock, set infinite drive strength
    set_drive 0 clk
    }

# Create virtual clock if clock port is not found
if {[sizeof_collection [get_ports clk]] == 0} {
    set clk_name vclk
    create_clock -period $clk_period -name vclk
    }

# Apply default drive strengths and typical loads
# for I/O ports
set_load 1.5 [all_outputs]
set_driving_cell -lib_cell IV [all_inputs]

# Apply default timing constraints for modules
set_input_delay 1 [all_inputs] -clock $clk_name
set_output_delay 1 [all_outputs] -clock $clk_name
set_clock_uncertainty -setup 0.2 $clk_name

# Set operating conditions
#set_operating_conditions ZEL

# Turn on auto wire load selection
# (library must support this feature)
set auto_wire_load_selection true