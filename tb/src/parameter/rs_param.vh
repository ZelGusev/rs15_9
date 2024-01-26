/*************************************************************************************************************
--    Система        : 
--    Разработчик    : 
--    Автор          : Игорь Гусев
--
--    Назначение     : Параметры интерфейса
-—                     
--------------------------------------------------------------------------------------------------------------
--    Примечание     : 
*************************************************************************************************************/
`ifndef _GUARD_RS_PARAM_
    `define _GUARD_RS_PARAM_
    //-- Основные параметры конфигурации модуля -----------------------------------------------------
    localparam WORD_WIDTH           = 4;
    localparam K_NUM                = 9;
    localparam N_NUM                = 15;
    localparam SHIFT_WIDTH          = (N_NUM - K_NUM) * WORD_WIDTH;
    localparam DATA_WIDTH           = K_NUM * WORD_WIDTH;
    localparam CODE_WIDTH           = N_NUM * WORD_WIDTH;
    localparam CNT_WIDTH            = WORD_WIDTH;
    localparam CNTRL_WIDTH          = SHIFT_WIDTH;
    // степени при порождающем полиноме x**4 + x + 1
    localparam A_10DEGREE           = 4'b0111;
    localparam A_14DEGREE           = 4'b1001;
    localparam A_4DEGREE            = 4'b0011;
    localparam A_6DEGREE            = 4'b1100;
    localparam A_9DEGREE            = 4'b1010;
    
    localparam RS_CLK_MHZ       = 100;      // частота MHz
   
    // utility
    localparam TIMEOUT          = 5;
    
    typedef enum {WRITE_S, READ_S, RESET_S} state_enum;

`endif
  