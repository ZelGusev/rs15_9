/*************************************************************************************************************
--    Система        : 
--    Разработчик    : 
--    Автор          : Гусев Игорь
--
--    Назначение     : Класс базовой транзакции (item) записи интерфейса Rs
--
--------------------------------------------------------------------------------------------------------------
--    Примечание     : 
*************************************************************************************************************/
`ifndef _GUARD_RS_ITEM_
    `define _GUARD_RS_ITEM_
   import parameter_pkg::*;
class Rs_seq_item extends uvm_sequence_item;

    rand state_enum                 option;
    bit                             rst_n;

    bit                             en;
    bit [DATA_WIDTH - 1 : 0]        data;
    bit [DATA_WIDTH - 1 : 0]        databkm;
    
    bit                             busy;
    bit                             rdy;
    bit [CODE_WIDTH - 1 : 0]        data_o;

    integer     num_err_bit;

    // UVM automation macros
    `uvm_object_utils_begin(Rs_seq_item)
    //`uvm_field_int  (data     , UVM_ALL_ON)      
    `uvm_object_utils_end
         
    //----------------------------------------------------------------------------//
    // Constraints                                                                //
    //----------------------------------------------------------------------------//

    //----------------------------------------------------------------------------//
    // Methods                                                                    //
    //----------------------------------------------------------------------------//   
    //Constructor
    function new(string name = "Rs_seq_item");
        super.new(name);
    endfunction : new
    


endclass : Rs_seq_item

`endif
