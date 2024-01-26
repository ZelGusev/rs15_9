/*************************************************************************************************************
--    Система        : 
--    Разработчик    : 
--    Автор          : Гусев Игорь
--
--    Назначение     : Кодер Рида-Соломона 15.9
--                     полином генератор x**6 + a**10x**5 + a**14x**4 + a**4x**3 + a**6x**2 + a**9x**1 + a**6
--------------------------------------------------------------------------------------------------------------
--    Примечание     : 
*************************************************************************************************************/
module rs_decode(
    clk,            // синхросигнал
    rst_n,          // сигнал сброса
    data_en,        // готовность данных на входе
    datain,         // шина входных данных
    busy,           // занятость кодера 
    data_rdy,       // готовность данных на выходе
    dataout         // шина выходных данных
    );
    //----------------------------------------------------------------------//
    // external parameters                                                  //
    //----------------------------------------------------------------------//
    //----------------------------------------------------------------------//
    // internal parameters                                                  //
    //----------------------------------------------------------------------//
    localparam WORD_WIDTH           = 4;
    localparam K_NUM                = 9;
    localparam N_NUM                = 15;
    localparam SHIFT_WIDTH          = (N_NUM - K_NUM) * WORD_WIDTH;
    localparam DATA_WIDTH           = K_NUM * WORD_WIDTH;
    localparam CODE_WIDTH           = N_NUM * WORD_WIDTH;
    localparam CNT_WIDTH            = WORD_WIDTH;
    // степени при порождающем полиноме x**4 + x + 1
    localparam A_10DEGREE           = 4'b0111;
    localparam A_14DEGREE           = 4'b1001;
    localparam A_4DEGREE            = 4'b0011;
    localparam A_6DEGREE            = 4'b1100;
    localparam A_9DEGREE            = 4'b1010;
    //----------------------------------------------------------------------//
    // external signals                                                     //
    //----------------------------------------------------------------------//
    input                           clk;            // синхросигнал
    input                           rst_n;          // синхросигнал
    input                           data_en;        // готовность данных на входе
    input    [CODE_WIDTH - 1 : 0]   datain;         // шина входных данных
    output reg                      busy;           // занятость кодера 
    output reg                      data_rdy;       // готовность данных на выходе
    output   [DATA_WIDTH - 1 : 0]   dataout;        // шина выходных данных
    //----------------------------------------------------------------------//
    // registers                                                            //
    //----------------------------------------------------------------------//
    reg     [SHIFT_WIDTH - 1 : 0]   shift_reg;      // сдвиговый регистр
    reg     [CODE_WIDTH - 1 : 0]    shift_data;     // сдвиговый данных
    reg     [CODE_WIDTH - 1 : 0]    shift_code;     // сдвиговый данных
    reg     [WORD_WIDTH - 1 : 0]    cnt_nword;      // счетчик количества информационных слов
    reg                             data_en_reg;    // регистр фронта
    reg                             busy_reg;       // регистр фронта
    //----------------------------------------------------------------------//
    // wires                                                                //
    //----------------------------------------------------------------------//
    wire    [WORD_WIDTH - 1 : 0]  result_sum;
    wire    [WORD_WIDTH - 1 : 0]  result_5;
    wire    [WORD_WIDTH - 1 : 0]  result_4;
    wire    [WORD_WIDTH - 1 : 0]  result_3;
    wire    [WORD_WIDTH - 1 : 0]  result_2;
    wire    [WORD_WIDTH - 1 : 0]  result_1;
    wire    [WORD_WIDTH - 1 : 0]  result_0;
    wire    [WORD_WIDTH - 1 : 0]  result_01;
    wire    [WORD_WIDTH - 1 : 0]  result_12;
    wire    [WORD_WIDTH - 1 : 0]  result_23;
    wire    [WORD_WIDTH - 1 : 0]  result_34;
    wire    [WORD_WIDTH - 1 : 0]  result_45;
    //----------------------------------------------------------------------//
    // assigns                                                              //
    //----------------------------------------------------------------------//
    
    //----------------------------------------------------------------------//
    // component                                                            //
    //----------------------------------------------------------------------//
    // сумматор данных с свиговым регистром степеней
    gf2_add
    gf2_add_sum
    (
        .data_a     (shift_reg[SHIFT_WIDTH - 1 : SHIFT_WIDTH - WORD_WIDTH]),         // шина данных
        .data_b     (shift_data[CODE_WIDTH - 1 : CODE_WIDTH - WORD_WIDTH]),         // шина данных
        .data_out   (result_sum)        // шина результирующих данных
    );
    // множитель пятой степени
    gf2_3mult
    gf2_3mult_5
    (
        .data_a     (A_10DEGREE),
        .data_b     (result_sum),
        .data_out   (result_5)
    );
    // множитель четвертой степени
    gf2_3mult
    gf2_3mult_4
    (
        .data_a     (A_14DEGREE),
        .data_b     (result_sum),
        .data_out   (result_4)
    );
    // множитель третьей степени
    gf2_3mult
    gf2_3mult_3
    (
        .data_a     (A_4DEGREE),
        .data_b     (result_sum),
        .data_out   (result_3)
    );
    // множитель второй степени
    gf2_3mult
    gf2_3mult_2
    (
        .data_a     (A_6DEGREE),
        .data_b     (result_sum),
        .data_out   (result_2)
    );
    // множитель первой степени
    gf2_3mult
    gf2_3mult_1
    (
        .data_a     (A_9DEGREE),
        .data_b     (result_sum),
        .data_out   (result_1)
    );
    // множитель нулевой степени
    gf2_3mult
    gf2_3mult_0
    (
        .data_a     (A_6DEGREE),
        .data_b     (result_sum),
        .data_out   (result_0)
    );
    // сумматор нулевого слова свигового регистра с результатом умножения первой степени 
    gf2_add
    gf2_add_01
    (
        .data_a     (shift_reg[1*WORD_WIDTH - 1 : WORD_WIDTH*0]),         // шина данных
        .data_b     (result_1),         // шина данных
        .data_out   (result_01)        // шина результирующих данных
    );
    // сумматор первого слова свигового регистра с результатом умножения второй степени 
    gf2_add
    gf2_add_12
    (
        .data_a     (shift_reg[2*WORD_WIDTH - 1 : WORD_WIDTH*1]),         // шина данных
        .data_b     (result_2),         // шина данных
        .data_out   (result_12)        // шина результирующих данных
    );
    // сумматор второго слова свигового регистра с результатом умножения третьей степени 
    gf2_add
    gf2_add_23
    (
        .data_a     (shift_reg[3*WORD_WIDTH - 1 : WORD_WIDTH*2]),         // шина данных
        .data_b     (result_3),         // шина данных
        .data_out   (result_23)        // шина результирующих данных
    );
    // сумматор третьего слова свигового регистра с результатом умножения четвертой степени 
    gf2_add
    gf2_add_34
    (
        .data_a     (shift_reg[4*WORD_WIDTH - 1 : WORD_WIDTH*3]),         // шина данных
        .data_b     (result_4),         // шина данных
        .data_out   (result_34)        // шина результирующих данных
    );
    // сумматор четвертой слова свигового регистра с результатом умножения пятой степени 
    gf2_add
    gf2_add_45
    (
        .data_a     (shift_reg[5*WORD_WIDTH - 1 : WORD_WIDTH*4]),         // шина данных
        .data_b     (result_5),         // шина данных
        .data_out   (result_45)        // шина результирующих данных
    );
    //----------------------------------------------------------------------//
    // logic                                                                //
    //----------------------------------------------------------------------//
    always @(posedge clk)
        begin
            if (~rst_n)
                begin
                    shift_reg   <= {SHIFT_WIDTH{1'b0}};
                    shift_data  <= {CODE_WIDTH{1'b0}};
                    shift_code  <= {CODE_WIDTH{1'b0}};
                    cnt_nword   <= {CNT_WIDTH{1'b0}};
                    data_en_reg <= 1'b0;
                    busy        <= 1'b0;
                    busy_reg    <= 1'b0;
                    data_rdy    <= 1'b0;
                end
            else
                begin
                    data_en_reg <= data_en;
                    busy_reg    <= busy;
                    if (~busy && busy_reg)
                        data_rdy <= 1'b1;
                    if (~data_en_reg && data_en)
                        begin
                            shift_data  <= datain;
                            cnt_nword   <= N_NUM;
                            //busy        <= 1'b1;
                            data_rdy    <= 1'b0;
                        end

                    if (cnt_nword != 0)
                        begin
                            cnt_nword   <= cnt_nword - 1'b1;
                            // if (cnt_nword > N_NUM - K_NUM)
                            //     begin
                            shift_reg[1*WORD_WIDTH - 1 : 0*WORD_WIDTH] <= result_0;
                            shift_reg[2*WORD_WIDTH - 1 : 1*WORD_WIDTH] <= result_01;
                            shift_reg[3*WORD_WIDTH - 1 : 2*WORD_WIDTH] <= result_12;
                            shift_reg[4*WORD_WIDTH - 1 : 3*WORD_WIDTH] <= result_23;
                            shift_reg[5*WORD_WIDTH - 1 : 4*WORD_WIDTH] <= result_34;
                            shift_reg[6*WORD_WIDTH - 1 : 5*WORD_WIDTH] <= result_45;
                            shift_data <= {shift_data[CODE_WIDTH - WORD_WIDTH - 1 : 0] , shift_data[CODE_WIDTH - 1 : CODE_WIDTH - WORD_WIDTH]};
                                // end
                        end
                    else
                        begin
                            busy        <= 1'b0;
                            //shift_reg   <= {SHIFT_WIDTH{1'b0}};
                        end
                end
        end
endmodule