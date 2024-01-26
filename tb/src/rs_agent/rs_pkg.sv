/*************************************************************************************************************
--    Система        : 
--    Разработчик    : 
--    Автор          : Гусев Игорь
--
--    Назначение     : Этот пакет (package) содержит все компоненты относящиеся к агенту ecc
--                     Везде где используется данный интерфейс надо импортировать этот пакет.
-—                     
--------------------------------------------------------------------------------------------------------------
--    Примечание     : 
*************************************************************************************************************/
`ifndef _GUARD_RS_PKG_
   `define _GUARD_RS_PKG_
    `timescale 1ns/1ns
package rs_pkg;
    `include "uvm_macros.svh"    
    import uvm_pkg::*;

    `include "rs_seq_item.svh"
    `include "rs_sequence.svh"
    `include "rs_sequencer.svh"

    `include "rs_driver.svh"
    `include "rs_monitor.svh" 
    `include "rs_agent.svh"
   
endpackage : rs_pkg

`endif