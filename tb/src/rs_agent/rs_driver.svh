/*************************************************************************************************************
--    Система        : 
--    Разработчик    : 
--    Автор          : Гусев Игорь
--
--    Назначение     : Класс драйвера (driver) интерфейса
-—                     
--------------------------------------------------------------------------------------------------------------
--    Примечание     : 
*************************************************************************************************************/
`ifndef _GUARD_RS_DRIVER_
    `define _GUARD_RS_DRIVER_

    import parameter_pkg::*;
    
class Rs_driver extends uvm_driver#(Rs_seq_item);
    
    virtual ifclk#( .CLK_MHZ    (RS_CLK_MHZ))  clk_gen;
    virtual ifrs#(  .DATA_WIDTH (DATA_WIDTH), .CODE_WIDTH (CODE_WIDTH)   )      rs_wr_if;
    virtual ifrs#(  .DATA_WIDTH (DATA_WIDTH), .CODE_WIDTH (CODE_WIDTH)   )      rs_bkm_if;
    
    virtual ifrs#(  .DATA_WIDTH (CODE_WIDTH), .CODE_WIDTH (CODE_WIDTH)   )      rs_rdbkm_if;
    

    // UVM Factory registration macros
    `uvm_component_utils( Rs_driver )
    
    Rs_seq_item    rs_seq;

    //----------------------------------------------------------------------//
    // Create                                                               //
    //----------------------------------------------------------------------//
    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction:new 
    //----------------------------------------------------------------------//
    // Build Phase                                                          //
    //----------------------------------------------------------------------//
    function void build_phase(uvm_phase phase); 
        super.build_phase(phase);
        // Configure Interface
        if(!uvm_config_db #(virtual ifclk   #(  .CLK_MHZ    (RS_CLK_MHZ)))::get(this, "*", "clk_gen", clk_gen))
            `uvm_fatal("NOVIF",{"virtual interface must be set for: ",get_full_name(),".clk_gen"});

        if(!uvm_config_db #(virtual ifrs#(  .DATA_WIDTH (DATA_WIDTH), .CODE_WIDTH (CODE_WIDTH)))::get(this, "*", "rs_wr_if", rs_wr_if))
            `uvm_fatal("NOVIF",{"virtual interface must be set for: ",get_full_name(),".rs_wr_if"});
        if(!uvm_config_db #(virtual ifrs#(  .DATA_WIDTH (DATA_WIDTH), .CODE_WIDTH (CODE_WIDTH)))::get(this, "*", "rs_bkm_if", rs_bkm_if))
            `uvm_fatal("NOVIF",{"virtual interface must be set for: ",get_full_name(),".rs_bkm_if"});

        if(!uvm_config_db #(virtual ifrs#(  .DATA_WIDTH (CODE_WIDTH), .CODE_WIDTH (CODE_WIDTH)))::get(this, "*", "rs_rdbkm_if", rs_rdbkm_if))
            `uvm_fatal("NOVIF",{"virtual interface must be set for: ",get_full_name(),".rs_rdbkm_if"});
            
        
        // item
        rs_seq    = Rs_seq_item::type_id::create("rs_seq");
    endfunction : build_phase

    //----------------------------------------------------------------------//
    // Coonect Phase                                                        //
    //----------------------------------------------------------------------//
    function void connect_phase(uvm_phase phase);
    endfunction: connect_phase
    //----------------------------------------------------------------------//
    // Run Phase                                                            //
    //----------------------------------------------------------------------//
    bit [DATA_WIDTH - 1 : 0]        data;
    bit [CNTRL_WIDTH - 1 : 0]       cntrl_bits;
    bit [CODE_WIDTH - 1 : 0]        code;
    bit [CODE_WIDTH - 1 : 0]        err_bit[3];
    localparam POLY_GEN = 24'b0111_1001_0011_1100_1010_1100;
    task run_phase(uvm_phase phase);
        uvm_report_info(get_full_name(),"Driver run phase...", UVM_LOW);
        
        fork
            begin   // rst
                rst_all();
            end
            forever begin
                @(negedge clk_gen.rst_n)
                rst_all();
            end
            forever begin
                seq_item_port.get_next_item(rs_seq);

                case (rs_seq.option)
                    RESET_S:  clk_gen.rst_n = rs_seq.rst_n;
                    WRITE_S:
                        begin
                            //$display(" WRITE TO MEM ");
                            @(posedge clk_gen.clk);
                            rs_wr_if.datain     = rs_seq.data;
                            rs_wr_if.en         = 1'b1;
                            rs_bkm_if.datain    = rs_seq.databkm;
                            rs_bkm_if.en        = 1'b1;
                            data = rs_seq.data;
                            @(posedge clk_gen.clk);
                            rs_wr_if.en         = 1'b0;
                            rs_bkm_if.en        = 1'b0;

                            //$display(" WRITE TO MEM data = %h, checkout = %h, addr = %h", rs_wr_if.dataout, rs_wr_if.chkout, rs_seq.addr);
                            wait(rs_bkm_if.rdy);
                            code = rs_bkm_if.dataout;
                            // code [CODE_WIDTH - 1] = ~code [CODE_WIDTH - 1];
                            // code [CODE_WIDTH - 2] = ~code [CODE_WIDTH - 2];
                            // code [CODE_WIDTH - 3] = ~code [CODE_WIDTH - 3];
                            code [CODE_WIDTH - 2] = ~code [CODE_WIDTH - 2];
                            code [CODE_WIDTH - 16] = ~code [CODE_WIDTH - 16];
                            code [CODE_WIDTH - 41] = ~code [CODE_WIDTH - 41];
                            // for (int i = 0; i < 3; i++)
                            //     begin
                            //         err_bit[i] = $urandom_range(0,CODE_WIDTH-1);
                            //         $display("ERR BIT NUM = %d", err_bit[i]);
                            //     end
                            // for (int i = 0; i < CODE_WIDTH; i++)
                            //     begin
                            //         for (int j = 0; j < 3; j++)
                            //             begin
                            //                 if (i == err_bit[j])
                            //                     begin
                            //                         code[i] = ~code[i];
                            //                         $display ("NUM ERR BIT = %d", i);
                            //                     end
                            //             end
                            //     end
                            // $display("INPUT ERR DATA = %h, = %b", code, code);
                            @(posedge clk_gen.clk);
                            rs_rdbkm_if.datain      = code;
                            rs_rdbkm_if.en          = 1'b1;
                            @(posedge clk_gen.clk);
                            rs_rdbkm_if.en      = 1'b0;
                        end
                    READ_S:
                        begin
                            // $display(" READ FROM MEM ");
                            //cntrl_bits = 24'h57395F;
                            cntrl_bits  = 24'b0101_0111_0011_1001_0101_1111;
                            //$display(" DECODE CONTROL BITS = %h, = %b", cntrl_bits, cntrl_bits);
                            //cntrl_bits  = 0;
                            //cntrl_bits  = 24'b1111_0101_1001_0011_0111_0101;
                            data        = 36'b0000_0000_0000_0000_0000_0000_0000_1110_0000;
                            //                                               0    11        8    10   4    3    8    12
                            code        = 60'b0000_0000_0000_0000_0000_0000_0001_1110_0000_0101_0111_0011_1000_0101_1111;
                            if (rs_seq.num_err_bit == 0)
                                begin
                                    @(posedge clk_gen.clk);
                                    
                                    rs_rdbkm_if.en          = 1'b1;
                                    // ERROR WORD
                                    code                    = 60'b1111_0101_1000_0011_0111_0101_0000_1110_0001_0000_0000_0000_0000_0000_0000;
                                    // TRUE WORD
                                    //code                    = 60'b1111_0101_1001_0011_0111_0101_0000_1110_0000_0000_0000_0000_0000_0000_0000;
                                    
                                    rs_rdbkm_if.datain      = code;
                                    @(posedge clk_gen.clk);
                                    rs_rdbkm_if.en      = 1'b0;
                                    //$display(" MEM DATA = %h, SYN DATA = %h, ADDR READ = %h", mem[rs_seq.addr][RS_DATA_WIDTH + RS_SYN_WIDTH - 1 : RS_SYN_WIDTH], mem[rs_seq.addr][RS_SYN_WIDTH - 1 : 0], rs_seq.addr);
                                end
                            // else
                            //     begin
                            //         if (rs_seq.num_err_bit > (((DATA_WIDTH - CODE_WIDTH)/WORD_WIDTH)/2))
                            //             `uvm_warning(get_type_name (), $sformatf (" Too ManY ErrOrs!!! "));
                            //         shift = {{RS_SYN_WIDTH{1'b0}}, data};
                            //         for (int i = 0; i < rs_seq.num_err_bit; i++)
                            //             err_buf [i] = $urandom_range(0, ((RS_DATA_WIDTH + RS_SYN_WIDTH)/BYTE_WIDTH) - 1);
                            //         for (int i = 0; i < (RS_DATA_WIDTH + RS_SYN_WIDTH)/BYTE_WIDTH; i++)
                            //             begin
                            //                 for (int j = 0; j < rs_seq.num_err_bit; j++)
                            //                     begin
                            //                         //if (err_buf [j] == i)
                            //                         //    data_mem [i] = $urandom;
                            //                         //else
                            //                         //    data_mem [i] = shift[BYTE_WIDTH - 1 : 0];
                            //                         if (err_buf [j] == i)
                            //                             shift[BYTE_WIDTH - 1 : 0] = $urandom;
                            //                     end
                            //                 shift = {shift[BYTE_WIDTH - 1 : 0], shift[RS_DATA_WIDTH + RS_SYN_WIDTH - 1 : BYTE_WIDTH]};
                            //             end
                            //     end

                        end
                    default:;
                endcase
                seq_item_port.item_done();          // завершить последовательность 
            end
        join_any
    endtask : run_phase
   
    //------------------------------------------------------------------------//
    // Driver Task                                                            //
    //------------------------------------------------------------------------//
    virtual task rst_all();
        begin
            rs_wr_if.en         =   1'b0;
            rs_wr_if.datain     =   '0;

            rs_bkm_if.en         =   1'b0;
            rs_bkm_if.datain     =   '0;

            rs_rdbkm_if.en         =   1'b0;
            rs_rdbkm_if.datain     =   '0;
        end
    endtask : rst_all

    // virtual function void poly_gen();
    //     input integer prim_val;
    //     bit [NUM_BIT_VAL - 1 : 0] buff [NUM_SYN_WORD];
    //     begin
    //         for (int i = 1; i <= NUM_SYN_WORD; i++)
    //             begin
    //                 buff[0] = prim_val;
    //                 buff[1] = 1;
    //             end
    //     end
    // endfunction : poly_gen

endclass : Rs_driver

`endif

