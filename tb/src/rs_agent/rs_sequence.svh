   /*************************************************************************************************************
--    Система        : 
--    Разработчик    :
--    Автор          : Гусев Игорь
--
--    Назначение     : Класс формирования тестовых последовательностей (sequence) 
-—                     
--------------------------------------------------------------------------------------------------------------
--    Примечание     : 
*************************************************************************************************************/
`ifndef _GUARD_RS_SEQ_
    `define _GUARD_RS_SEQ_
   
    import parameter_pkg::*;
    //----------------------------------------------------------------------------//
    // Генератор последовательности для тестов                                    //
    //----------------------------------------------------------------------------//
class Rs_sequence extends uvm_sequence #(Rs_seq_item);
     
    // UVM automation macros
    `uvm_object_utils(Rs_sequence)

    Rs_seq_item req = new();

    // Constructor
    function new(string name = "Rs_sequence");
        super.new(name);
    endfunction


    //  Body `uvm_do(item) - чисто рандом без псевдо в моем случае было бы `uvm_do(Rs_seq_item) 
    virtual task body();
        //req = Rs_seq_item::type_id::create("req");
        start_item(req);
        finish_item(req);
    endtask : body

    function Rs_sequence set_rst(bit rst);
        this.req.rst_n      = rst;
        this.req.option     = RESET_S;
        return this;
    endfunction: set_rst

    function Rs_sequence wr_data(bit [DATA_WIDTH - 1 : 0] data, bit [DATA_WIDTH - 1 : 0] data_bkm);
        this.req.data       = data;
        this.req.databkm    = data_bkm;
        this.req.option     = WRITE_S;
        return this;
    endfunction: wr_data

    function Rs_sequence rd_data(int num_err_bit);
        this.req.num_err_bit    = num_err_bit;
        this.req.option         = READ_S;
        return this;
    endfunction: rd_data
   
endclass : Rs_sequence

`endif