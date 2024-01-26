/*************************************************************************************************************
--    Система        : 
--    Разработчик    : 
--    Автор          : Гусев Игорь
--
--    Назначение     : Test Top 
--                     
--------------------------------------------------------------------------------------------------------------
--    Примечание     : 
*************************************************************************************************************/
`ifndef _GUARD_TB_TOP_
    `define _GUARD_TB_TOP_
    `ifndef UVM_TESTNAME
        `define UVM_TESTNAME "Test_base"
    `endif
    `include "uvm_macros.svh"
module top_tb;
    import uvm_pkg::*;
    import tb_test_pkg::*;
    import parameter_pkg::*;

    // ------------- Interface -----------------//
    ifclk  #(  .CLK_MHZ (RS_CLK_MHZ)   )      clk_gen     ();
    ifrs   #(  .DATA_WIDTH (DATA_WIDTH), .CODE_WIDTH (CODE_WIDTH)   )      rs_wr_if    ();
    ifrs   #(  .DATA_WIDTH (DATA_WIDTH), .CODE_WIDTH (CODE_WIDTH)   )      rs_bkm_if   ();
    ifrs   #(  .DATA_WIDTH (CODE_WIDTH), .CODE_WIDTH (CODE_WIDTH)   )      rs_rdbkm_if    ();

    decode_if dec_if();
    // -------- Component instantiations -------//
    rs_encode
    rs_encode_inst
    (
    .clk            (clk_gen.clk),            // синхросигнал
    .rst_n          (clk_gen.rst_n),          // сигнал сброса
    .data_en        (rs_wr_if.en),        // готовность данных на входе
    .datain         (rs_wr_if.datain),         // шина входных данных
    .busy           (rs_wr_if.busy),           // занятость кодера 
    .data_rdy       (rs_wr_if.rdy),       // готовность данных на выходе
    .dataout        (rs_wr_if.dataout)         // шина выходных данных
    );

    rs_encodebkm
    rs_encodebkm_inst
    (
    .clk            (clk_gen.clk),            // синхросигнал
    .rst_n          (clk_gen.rst_n),          // сигнал сброса
    .data_en        (rs_bkm_if.en),        // готовность данных на входе
    .datain         (rs_bkm_if.datain),         // шина входных данных
    .busy           (rs_bkm_if.busy),           // занятость кодера 
    .data_rdy       (rs_bkm_if.rdy),       // готовность данных на выходе
    .dataout        (rs_bkm_if.dataout)         // шина выходных данных
    );

    rs_decodebkm
    rs_decodebkm_inst
    (
    .clk            (clk_gen.clk),            // синхросигнал
    .rst_n          (clk_gen.rst_n),          // сигнал сброса
    .data_en        (rs_rdbkm_if.en),        // готовность данных на входе
    .datain         (rs_rdbkm_if.datain),         // шина входных данных
    .busy           (rs_rdbkm_if.busy),           // занятость кодера 
    .data_rdy       (rs_rdbkm_if.rdy),       // готовность данных на выходе
    .dataout        (rs_rdbkm_if.dataout)         // шина выходных данных
    );


    function [6 * 4 - 1 : 0] to_wire;
        input [4 - 1 : 0] data [6];
        reg [6 * 4 - 1 : 0]    tmp;
            begin
                tmp = 0;
                for (int i = 0; i < 6; i++)
                    begin
                        tmp>>=4;
                        tmp[6 * 4 - 1 : 5 * 4] = data[i];
                    end
                    to_wire = tmp;
            end
    endfunction : to_wire

    function [15 * 4 - 1 : 0] func_revers_input_data;
        input [15 * 4 - 1 : 0]  data;
        bit  [15 * 4 - 1 : 0]   data_o;
            begin
                for (int i = 0; i < 15; i++)
                    begin
                        data_o>>=4;
                        data_o[15*4 - 1 : 14*4] = data[15*4 - 1 : 14*4];
                        data<<=4;
                    end
            end
        func_revers_input_data = data_o;
    endfunction : func_revers_input_data

    assign dec_if.syn_rdy  = rs_decodebkm_inst.syn_rdy;
    assign dec_if.syndrom  = rs_decodebkm_inst.syndrom;

    assign dec_if.bkm_rdy  = rs_decodebkm_inst.bkm_rdy;
    assign dec_if.bkm_poly = rs_decodebkm_inst.bkm_poly;

    assign dec_if.chein_rdy = rs_decodebkm_inst.chein_rdy;
    assign dec_if.locator   = rs_decodebkm_inst.chein_search_inst.locator;

    initial begin

        wait(clk_gen.rst_n);
        #100;
        fork
        join_any
    end

    //---------------------------------------------------------------------------//
    // Main test process                                                         //
    //---------------------------------------------------------------------------//
    bit stop_at_the_end = 0; 
    initial begin : main
        uvm_root    root;
    //-------------------------------------------------------------------//
    // DUT initialization                                                //
    //-------------------------------------------------------------------//
        root = uvm_root::get();
        uvm_config_db #(virtual ifclk   #(  .CLK_MHZ (RS_CLK_MHZ)  )   )   ::set( root, "*", "clk_gen",     clk_gen     );
        uvm_config_db #(virtual ifrs   #(  .DATA_WIDTH (DATA_WIDTH), .CODE_WIDTH (CODE_WIDTH)   )    )   ::set( root, "*", "rs_wr_if",     rs_wr_if     );
        uvm_config_db #(virtual ifrs   #(  .DATA_WIDTH (DATA_WIDTH), .CODE_WIDTH (CODE_WIDTH)   )    )   ::set( root, "*", "rs_bkm_if",     rs_bkm_if     );
        uvm_config_db #(virtual ifrs   #(  .DATA_WIDTH (CODE_WIDTH), .CODE_WIDTH (CODE_WIDTH)   )    )   ::set( root, "*", "rs_rdbkm_if",     rs_rdbkm_if   );
        uvm_config_db #(virtual decode_if)  ::set( root, "*", "dec_if", dec_if);
    //-------------------------------------------------------------------//
    // Retrieve runtime configuration                                    //
    //-------------------------------------------------------------------//
        if ($value$plusargs ("stop_at_the_end=%b", stop_at_the_end)) begin
           `uvm_info("DISP", $psprintf("stop_at_the_end=%b IS SPECIFIED", stop_at_the_end), UVM_LOW)
        end
    //-------------------------------------------------------------------//
    // Configure testbench                                               //
    //-------------------------------------------------------------------//
        // set proper time scale
        uvm_config_db #(real) ::set(root, "*", "time_scale", 1ns);
        // disable $finish
        root.finish_on_completion = 0;
    //-------------------------------------------------------------------//
    // Run test                                                          //
    //-------------------------------------------------------------------//
        //tb::create_log();
        run_test(`UVM_TESTNAME);
        $finish;
    end : main
    
endmodule

`endif