elvsoc build
elvsoc build tb.yaml
elvsoc test-base ARGS="\"-define ECC_DATA_WIDTH=32\""
dc_shell -f dc-compiler/sripts/dc_compile.tcl