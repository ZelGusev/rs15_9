if {[info exists ::env(TB_TOP_NAME)]} {
    set TB_TOP_NAME $::env(TB_TOP_NAME)
} else {
    set TB_TOP_NAME top_tb
}

if {[info exists ::env(DUMPDB)]} {
    set dumpdb $::env(DUMPDB)
} else {
    set dumpdb 0
}

if {$dumpdb} {
    database -open $TB_TOP_NAME.shm -into $TB_TOP_NAME.shm -event -default -compress
    if {[info exists ::env(UPF_SIM)]} { probe -pwr_mode -shm }
    probe -create -shm $TB_TOP_NAME -all -depth all -memories -all -dynamic -all -function
}

run
