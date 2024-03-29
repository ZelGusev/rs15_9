/*************************************************************************************************************
--    Система        : 
--    Разработчик    : 
--    Автор          : Гусев Игорь
--
--    Назначение     : Этот пакет (package) содержит все компоненты необходмые для модуля тестов
-—                     
--------------------------------------------------------------------------------------------------------------
--    Примечание     : 
*************************************************************************************************************/
`ifndef _GUARD_TB_TEST_PKG_
    `define _GUARD_TB_TEST_PKG_
    `timescale 1ns/1ns
package tb_test_pkg;
    `include "uvm_macros.svh"  
    import uvm_pkg::*;

    `include "tb_test_lib.svh"
   
endpackage : tb_test_pkg

`endif // _GUARD_TB_TEST_PKG_