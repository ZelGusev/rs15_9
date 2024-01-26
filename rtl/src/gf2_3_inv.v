/*************************************************************************************************************
--    Система        : 
--    Разработчик    : 
--    Автор          : Гусев Игорь
--
--    Назначение     : Сумматор в поле Галуа
--                     Считает сумму в поле обычный xor
--------------------------------------------------------------------------------------------------------------
--    Примечание     : 
*************************************************************************************************************/
module gf2_3_inv(
    data_i,         // шина данных
    data_out        // шина результирующих данных
    );
    //----------------------------------------------------------------------//
    // external parameters                                                  //
    //----------------------------------------------------------------------//
    parameter DATA_WIDTH            = 4;
    //----------------------------------------------------------------------//
    // internal parameters                                                  //
    //----------------------------------------------------------------------//
    //----------------------------------------------------------------------//
    // external signals                                                     //
    //----------------------------------------------------------------------//
    input       [DATA_WIDTH - 1 : 0]       data_i;         // шина данных
    output reg  [DATA_WIDTH - 1 : 0]       data_out;       // шина результирующих данных
    //----------------------------------------------------------------------//
    // registers                                                            //
    //----------------------------------------------------------------------//
    //----------------------------------------------------------------------//
    // wires                                                                //
    //----------------------------------------------------------------------//
    wire        [DATA_WIDTH - 1 : 0]       data_inv;       // шина результирующих данных
    //----------------------------------------------------------------------//
    // assigns                                                              //
    //----------------------------------------------------------------------//
    //----------------------------------------------------------------------//
    // logic                                                                //
    //----------------------------------------------------------------------//
    always @(data_i)
    begin
        case (data_i)
            4'd  2 : data_out = 4'd  9; 
            4'd  4 : data_out = 4'd 13; 
            4'd  8 : data_out = 4'd 15; 
            4'd  3 : data_out = 4'd 14; 
            4'd  6 : data_out = 4'd  7; 
            4'd 12 : data_out = 4'd 10; 
            4'd 11 : data_out = 4'd  5; 
            4'd  5 : data_out = 4'd 11; 
            4'd 10 : data_out = 4'd 12; 
            4'd  7 : data_out = 4'd  6; 
            4'd 14 : data_out = 4'd  3; 
            4'd 15 : data_out = 4'd  8; 
            4'd 13 : data_out = 4'd  4; 
            4'd  9 : data_out = 4'd  2; 
            4'd  1 : data_out = 4'd  1; 
            default: data_out = 4'd  0;  
        endcase
    end
endmodule