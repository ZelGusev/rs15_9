/*************************************************************************************************************
--    Система        : 
--    Разработчик    : 
--    Автор          : Гусев Игорь
--
--    Назначение     : Класс агента (agent) интерфейса  содержащий : sequencer, driver,
--                     monitor и analysis_port для управления и верификации интерфейса
-—                     
--------------------------------------------------------------------------------------------------------------
--    Примечание     : 
*************************************************************************************************************/
`ifndef _GUARD_RS_AGENT_
    `define _GUARD_RS_AGENT_

class Rs_agent extends uvm_agent;
    //declaring agent components
    Rs_driver         driver;
    Rs_sequencer      sequencer;
    Rs_monitor        monitor;
   
    uvm_analysis_port #(Rs_seq_item)  wr_rs_data;
    uvm_analysis_port #(Rs_seq_item)  rd_rs_data;

    // UVM Factory registration macros
    `uvm_component_utils(Rs_agent)
 
    //-----------------------------------------------------------------------//
    // Create                                                                //
    //-----------------------------------------------------------------------//
    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new
   
    //-----------------------------------------------------------------------//
    // Build Phase                                                           //
    //-----------------------------------------------------------------------//
    function void build_phase(uvm_phase phase); 
        super.build_phase(phase);
        wr_rs_data     = new(.name("wr_rs_data"),    .parent(this));
        rd_rs_data     = new(.name("rd_rs_data"),    .parent(this));
        
        driver          = Rs_driver    ::type_id::create("driver", this);
        sequencer       = Rs_sequencer ::type_id::create("sequencer", this);
        monitor         = Rs_monitor   ::type_id::create("monitor", this);
   endfunction : build_phase
   
    //-----------------------------------------------------------------------//
    // Connect Phase                                                         //
    //-----------------------------------------------------------------------//   
    function void connect_phase(uvm_phase phase);
        driver.seq_item_port.   connect(sequencer.seq_item_export);

        monitor.wr_data_stream.    connect(wr_rs_data);
        monitor.rd_data_stream.    connect(rd_rs_data);
    endfunction : connect_phase
 
endclass : Rs_agent

`endif
