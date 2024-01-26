clear

BASE='BASE' # command argument for simulate with database, if another or no arg specified - fast sim wo gui
COMP='COMP'

if [ "$1" != "$BASE" ]
then
    BASE='FALSE' # simulation FAST without GUI & DataBase
else
    BASE='TRUE'  # simulation with GUI & Data Base
fi

if [ "$1" != "$COMP" ]
then
    COMP='FALSE' #
else
    COMP='TRUE'  #
fi

export DUMPDB="1"
export TB_TOP_NAME="top_tb"
export SVSEED=$((RANDOM%(100)+1))
export NUM_TX="5"
COMPILE=" -sv -q +access+rwc -64 -uvm -disable_sem2009 -notimingchecks -no_tchk_msg +no_warning -compile "
ELABORATE=" -sv -q +access+rwc -64 -uvm -disable_sem2009 -notimingchecks -no_tchk_msg +no_warning -elaborate "
SIMULATE_GUI=" -sv -q +access+rwc -64 -uvm -disable_sem2009 -notimingchecks -no_tchk_msg +no_warning +gui "
SIMULATE=" +access+rwc -64 -uvm -disable_sem2009 -notimingchecks -no_tchk_msg +no_warning "
INPUTS=" -input ./tb/scripts/simulate.tcl "
TS_PARAM=" 1ns/1ns "
TIMESCALE=" -timescale $TS_PARAM "
TOP_MOD=" -top $TB_TOP_NAME "
NC_ELAB_TYPE=" +fsmdebug "
######## INSTANCE ###################################################
RTL_FILES=" -f ./rtl/rtl.files "
SIM_FILES=" -f ./tb/sim.files "
INCDIR=" +incdir+./rtl/src "
INCDIR_TB=" +incdir+./tb/src "
######################################################################

######## ALL #########################################################
FILES_ALL=" ${RTL_FILES} "
FILES_SIM_F=" ${SIM_FILES} "
INDIR_ALL=" ${INCDIR} ${INCDIR_TB} "
######################################################################

OPTION_COMP=" $COMPILE $FILES_ALL $INDIR_ALL "
if [ "${BASE}" == "TRUE" ]
then
    OPTION_RUN=" $SIMULATE_GUI $INPUTS $TIMESCALE $NC_ELAB_TYPE $FILES_ALL $INDIR_ALL $FILES_SIM_F "
    echo "============================== simulation with DATABASE and GUI selected ===================================="
elif [ "${COMP}" == "TRUE" ]
then
    OPTION_RUN=" $OPTION_COMP $FILES_ALL $INDIR_ALL $FILES_SIM_F "
    echo "======================================== only COMPILE selected =============================================="
else
    OPTION_RUN=" $SIMULATE $INPUTS $TIMESCALE $NC_ELAB_TYPE $FILES_ALL $INDIR_ALL $FILES_SIM_F"
    echo "============================================ FAST simulate selected !!! ====================================="
fi
echo "................................................."

xrun ${OPTION_RUN} +NUM_RACE=$NUM_TX -seed $SVSEED $ARGS +UVM_NO_RELNOTES
