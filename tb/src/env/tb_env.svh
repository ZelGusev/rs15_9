/*************************************************************************************************************
--    Система        : 
--    Разработчик    : 
--    Автор          : Гусев Игорь
--
--    Назначение     : Класс верхнего уровня тестового окружения (Environment).
-—                     Содержит объявление и соединение используемых верификационных компонентов.
--------------------------------------------------------------------------------------------------------------
--    Примечание     : 
*************************************************************************************************************/
`ifndef _GUARD_TB_ENV_
    `define _GUARD_TB_ENV_

    import rs_pkg::*;
    `include "tb_scoreboard.svh"

class Rs_env extends uvm_env; 

    Rs_agent          m_agent;
    Rs_scoreboard     m_scoreboard;

    // UVM Factory registration macros
   
    `uvm_component_utils(Rs_env)
   
    //----------------------------------------------------------------------//
    // Create                                                               //
    //----------------------------------------------------------------------//
    function new(string name, uvm_component parent); 
        super.new(name, parent); 
    endfunction : new
   
    //----------------------------------------------------------------------//
    // Build Phase                                                          //
    //----------------------------------------------------------------------//
    function void build_phase(uvm_phase phase); 
        uvm_report_info(get_full_name(),"Build...", UVM_LOW); 

        m_agent = Rs_agent::type_id::create("m_agent",this);

        uvm_config_db #(int) ::set(this, "m_agent", "is_active", UVM_ACTIVE);
        m_scoreboard = Rs_scoreboard ::type_id::create("m_scoreboard",this);
        
        uvm_report_info(get_full_name(),"Build completed", UVM_LOW); 
    endfunction : build_phase

    //----------------------------------------------------------------------//
    // Connect Phase                                                        //
    //----------------------------------------------------------------------//
    function void connect_phase(uvm_phase phase); 
        uvm_report_info(get_full_name(),"Connect...", UVM_LOW);
        // Connect agent monitor port to analysis export of Scoreboard
        m_agent.wr_rs_data.connect(m_scoreboard.sb_rs_wr_export);
        m_agent.rd_rs_data.connect(m_scoreboard.sb_rs_rd_export);
        uvm_report_info(get_full_name(),"Connect completed", UVM_LOW);
    endfunction : connect_phase

endclass : Rs_env

`endif
