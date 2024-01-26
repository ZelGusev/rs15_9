/*************************************************************************************************************
--    Система        : 
--    Разработчик    : 
--    Автор          : Гусев Игорь
--
--    Назначение     : Класс верхнего уровня тестового окружения (Scoreboard).
-—                     Содержит объявление и соединение используемых верификационных компонентов.
--------------------------------------------------------------------------------------------------------------
--    Примечание     : 
*************************************************************************************************************/

`ifndef _GUARD_SCOREBOARD_
    `define _GUARD_SCOREBOARD_

    import parameter_pkg::*;
    import rs_pkg::*;

class Rs_scoreboard extends uvm_scoreboard;

    // UVM Factory registration macros
    `uvm_component_utils(Rs_scoreboard)
    // Declaring TLM analysis port
    uvm_analysis_export #(Rs_seq_item)     sb_rs_wr_export;
    uvm_analysis_export #(Rs_seq_item)     sb_rs_rd_export;
    
    // fifo
    uvm_tlm_analysis_fifo #(Rs_seq_item)   rs_wr_fifo;
    uvm_tlm_analysis_fifo #(Rs_seq_item)   rs_rd_fifo;
    
    // item
    Rs_seq_item        rs_tr;

    //----------------------------------------------------------------------//
    // Create                                                               //
    //----------------------------------------------------------------------//
    function new (string name, uvm_component parent);
        super.new(name, parent);
        rs_tr      = new("rs_tr");
    endfunction:new 

    //----------------------------------------------------------------------//
    // Build Phase                                                          //
    //----------------------------------------------------------------------//
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        //creating port
        sb_rs_wr_export    = new("sb_rs_wr_export", this);
        sb_rs_rd_export    = new("sb_rs_rd_export", this);
        //FIFO
        rs_wr_fifo         = new("rs_wr_fifo",     this);
        rs_rd_fifo         = new("rs_rd_fifo",     this);
    endfunction: build_phase

    //----------------------------------------------------------------------//
    // Coonect Phase                                                        //
    //----------------------------------------------------------------------//
    function void connect_phase(uvm_phase phase);
    sb_rs_wr_export.connect      (rs_wr_fifo.analysis_export);
    sb_rs_rd_export.connect      (rs_rd_fifo.analysis_export);
	endfunction: connect_phase

    //----------------------------------------------------------------------//
    // Run Phase                                                            //
    //----------------------------------------------------------------------//                                          
    integer                                     num_bit_err = 0;
    task run_phase(uvm_phase phase);
        fork
            //------------>///////////////////////////ECC DATA////////////////////////////////////////////
            forever begin
                rs_wr_fifo.get(rs_tr);
            end
            forever begin
                rs_rd_fifo.get(rs_tr);
            end
            /////////////////////////////////////////////////////////////////////////////////////<------------
        join
    endtask : run_phase
    
    // virtual function viod code_word()
    // endfunction


endclass : Rs_scoreboard

`endif