/*************************************************************************************************************
--    Система        : 
--    Разработчик    : 
--    Автор          : Гусев Игорь
--
--    Назначение     : Класс передающий тестовые последовательности от формирователя в драйвер (sequencer)
--                     
-—                     
--------------------------------------------------------------------------------------------------------------
--    Примечание     : 
*************************************************************************************************************/
`ifndef _GUARD_RS_SQER_
    `define _GUARD_RS_SQER_

class Rs_sequencer extends uvm_sequencer #(Rs_seq_item);
    // UVM automation macros
    `uvm_component_utils(Rs_sequencer)
    // Constructor
    function new(string name = "Rs_sequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    function void build_phase (uvm_phase phase);
        super.build_phase(phase);
    endfunction : build_phase
   
endclass : Rs_sequencer

`endif