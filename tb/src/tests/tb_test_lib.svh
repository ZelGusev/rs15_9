/*************************************************************************************************************
--    Система        : 
--    Разработчик    : 
--    Автор          : Гусев Игорь
--
--    Назначение     : Библиотека тестов для тестового окружения 
-—                     
--------------------------------------------------------------------------------------------------------------
--    Примечание     : 
*************************************************************************************************************/

`ifndef _GUARD_TB_LIB_
    `define _GUARD_TB_LIB_

    import tb_env_pkg::*;
    import parameter_pkg::*;
    //------------------------------------------------------------------------------------------------//
    // TEST BASE                                                                                      //
    //------------------------------------------------------------------------------------------------//
class Test_base extends uvm_test; 

    string   info_msg_id    = "INFO";
    string   warning_msg_id = "WARNING";
    string   error_msg_id   = "ERROR";
    string   fatal_msg_id   = "FATAL ERROR";

    Rs_env  env;

    parameter integer C_NUM_TX = 5;
    // UVM Factory registration macros
    `uvm_component_utils(Test_base) 

    rs_pkg::Rs_sequence        rs_seq;
    //----------------------------------------------------------------------//
    // Create                                                               //
    //----------------------------------------------------------------------//
    function new(string name, uvm_component parent = null); 
        super.new(name, parent); 
    endfunction 
   
    //----------------------------------------------------------------------//
    // Build Phase                                                          //
    //----------------------------------------------------------------------//
    function void build_phase(uvm_phase phase); 
        super.build_phase(phase);
        // Create the tb
        env = Rs_env::type_id::create("env", this);
    endfunction 
   
    //----------------------------------------------------------------------//
    // End of Elaboration Phase                                             //
    //----------------------------------------------------------------------//
    function void end_of_elaboration_phase(uvm_phase phase);
    endfunction : end_of_elaboration_phase
    //-----------------------------------------------------------------------//
    // Run Test                                                              //
    //-----------------------------------------------------------------------//
    
    function [9 * 4 - 1 : 0] func_revers_data;
        input [9 * 4 - 1 : 0]  data;
        bit  [9 * 4 - 1 : 0]   data_o;
            begin
                for (int i = 0; i < 9; i++)
                    begin
                        data_o>>=4;
                        data_o[9*4 - 1 : 8*4] = data[9*4 - 1 : 8*4];
                        data<<=4;
                    end
            end
        func_revers_data = data_o;
    endfunction : func_revers_data

    integer num_tx = C_NUM_TX;
    integer arg;
    bit [DATA_WIDTH - 1 : 0]    data;
    bit [DATA_WIDTH - 1 : 0]    data_rand;
    bit [DATA_WIDTH - 1 : 0]    data_rand_rev;
    bit [DATA_WIDTH - 1 : 0]    databkm;
    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        rs_seq    = rs_pkg::Rs_sequence::type_id::create("rs_seq", this);
        // // Начальные значения сигналов
        fork : timeout_block
            begin
                repeat (1) begin
                    //#G_T_CYCLE;
                    if ($value$plusargs ("NUM_RACE=%0d", arg))
                        begin
                            $display("Set Number of Transaction = %d", arg);
                            num_tx = arg;
                        end
                    else
                        begin
                            $display("Set Default Amount Of Transaction = %d", C_NUM_TX);
                            num_tx = C_NUM_TX;
                        end
                    $display("//---------- start sequence --------------// ");
                    #100;
                    rs_seq.set_rst(1'b1).start(env.m_agent.sequencer);
                    #100;
                    //data = $urandom;
                    // data    = 36'b0000_0000_0000_0000_0000_0000_0000_1110_0000;  // 0000000e0
                    data    = 36'b0000_0000_0000_0000_0000_0000_1110_1110_0000;  // 000000ee0
                    databkm = 36'b0000_1110_0000_0000_0000_0000_0000_0000_0000;
                    data_rand = {$urandom, $urandom};
                    data_rand_rev = func_revers_data(data_rand);

                    // rs_seq.wr_data(data, databkm).start(env.m_agent.sequencer);
                    rs_seq.wr_data(data_rand, data_rand_rev).start(env.m_agent.sequencer);
                    #100;
                    // rs_seq.rd_data(0).start(env.m_agent.sequencer);
                    // for (num_tx = 10; num_tx > 0; num_tx = num_tx - 1'b1)
                    //     begin
                    //         #200;
                    //         data = $urandom;
                    //         rs_seq.wr_data(data).start(env.m_agent.sequencer);
                    //         //rs_seq.rd_data(1).start(env.m_agent.sequencer);
                    //     end
                    #1000;
                    // repeat (num_tx) rs_seq.gen_pckt(NONE).start(env.m_agent.sequencer);
                    $display("//---------- stop sequence ---------------// ");
                    //#1ms;
                end
            end
        join_any
        // disable timeout_block;
        phase.drop_objection(this);    
    endtask : run_phase
    //----------------------------------------------------------------------//
    // Extract Phase                                                        //
    //----------------------------------------------------------------------//
    function void extract_phase(uvm_phase phase);
    $display("");
        if (env.m_scoreboard.num_bit_err != 0)
           begin
               $display ("----------------------------------------------------------------------------------------------");
               $display ("------------------------------- T E S T   F A I L E D ------------- --------------------------");
               $display ("----------------------------------------------------------------------------------------------");
           end
        else
           begin
               $display ("----------------------------------------------------------------------------------------------");
               $display ("------------------------------ T E S T   S U C C E S S E D -----------------------------------");
               $display ("----------------------------------------------------------------------------------------------");
           end
        if (env.m_scoreboard.num_bit_err != 0)
            `uvm_fatal(get_type_name(), $sformatf("TEST FAILED"));
    endfunction : extract_phase
    //----------------------------------------------------------------------//
    // check Phase                                                        //
    //----------------------------------------------------------------------//
    function void check_phase(uvm_phase phase);
    endfunction : check_phase
    //----------------------------------------------------------------------//
    // report Phase                                                        //
    //----------------------------------------------------------------------//
    function void report_phase(uvm_phase phase);
    endfunction : report_phase

endclass : Test_base

`endif // _GUARD_TB_LIB_
