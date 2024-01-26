/*************************************************************************************************************
--    Система        : 
--    Разработчик    : 
--    Автор          : Гусев Игорь
--
--    Назначение     : Этот пакет (package) содержит компоненты среды тестового окружения
-—                     
--------------------------------------------------------------------------------------------------------------
--    Примечание     : 
*************************************************************************************************************/
`ifndef _GUARD_PARAM_PKG_
    `define _GUARD_PARAM_PKG_

package parameter_pkg;

    `include "uvm_macros.svh"
    import uvm_pkg::*;

    `include "rs_param.vh"
          
endpackage : parameter_pkg

`endif // _GUARD_PARAM_PKG_