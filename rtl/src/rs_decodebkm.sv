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
module rs_decodebkm(
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
    localparam T_NUM                = (N_NUM - K_NUM)/2;
    localparam T2_NUM               = (N_NUM - K_NUM);
    localparam SHIFT_WIDTH          = (N_NUM - K_NUM) * WORD_WIDTH;
    localparam DATA_WIDTH           = K_NUM * WORD_WIDTH;
    localparam CODE_WIDTH           = N_NUM * WORD_WIDTH;
    localparam CNT_WIDTH            = WORD_WIDTH;
    localparam ERR_WIDTH            = WORD_WIDTH*T_NUM;
    // степени при порождающем полиноме x**4 + x + 1
    localparam A_10DEGREE           = 4'b0111;
    localparam A_14DEGREE           = 4'b1001;
    localparam A_4DEGREE            = 4'b0011;
    localparam A_6DEGREE            = 4'b1100;
    localparam A_9DEGREE            = 4'b1010;

    localparam A_1DEGREE            = 4'b0010;
    localparam A_2DEGREE            = 4'b0100;
    localparam A_3DEGREE            = 4'b1000;
    localparam A_5DEGREE            = 4'b0110;
    //----------------------------------------------------------------------//
    // external signals                                                     //
    //----------------------------------------------------------------------//
    input                           clk;            // синхросигнал
    input                           rst_n;          // синхросигнал
    input                           data_en;        // готовность данных на входе
    input    [CODE_WIDTH - 1 : 0]   datain;         // шина входных данных
    output reg                      busy;           // занятость кодера 
    output reg                      data_rdy;       // готовность данных на выходе
    output reg [CODE_WIDTH - 1 : 0] dataout;        // шина выходных данных
    //----------------------------------------------------------------------//
    // registers                                                            //
    //----------------------------------------------------------------------//
    reg     [SHIFT_WIDTH - 1 : 0]   shift_reg;      // сдвиговый регистр
    reg     [CODE_WIDTH - 1 : 0]    shift_data;     // сдвиговый данных
    reg     [CODE_WIDTH - 1 : 0]    shift_code;     // сдвиговый данных
    reg     [WORD_WIDTH - 1 : 0]    cnt_nword;      // счетчик количества информационных слов
    reg                             data_en_reg;    // регистр фронта
    reg                             syn_rdy;       // регистр фронта

    reg     [WORD_WIDTH - 1 : 0]    syndrom [T2_NUM];   //

    localparam FSM_SIZE = 4; //размер регистра состояний
    localparam [FSM_SIZE - 1 : 0]  
                    IDLE       = 0,     // установка регистра индекса 
                    PROC       = 1;     // обновить статус текущей области при возникновении ошибки 
    reg [FSM_SIZE - 1 : 0] state;
    //----------------------------------------------------------------------//
    // wires                                                                //
    //----------------------------------------------------------------------//
    wire [WORD_WIDTH - 1 : 0]       result_sum;
    
    wire [WORD_WIDTH - 1 : 0]       result [T2_NUM];
    wire [WORD_WIDTH - 1 : 0]       result_sec [T2_NUM - 1];
    wire [WORD_WIDTH - 1 : 0]       mult_root [T2_NUM];
    wire [WORD_WIDTH - 1 : 0]       sum_root [T2_NUM];

    wire                            bkm_rdy;
    wire [WORD_WIDTH - 1 : 0]       bkm_poly [T2_NUM];
    wire [WORD_WIDTH - 1 : 0]       bkm_poly_n [T2_NUM];

    wire [WORD_WIDTH - 1 : 0]       chein_o [T_NUM];
    wire                            chein_rdy;
    wire [WORD_WIDTH - 1 : 0]       pos_err[T_NUM];
    wire [WORD_WIDTH - 1 : 0]       num_err;

    wire [WORD_WIDTH - 1 : 0]       mult_poly_o [T2_NUM];
    wire                            mult_poly_en;

    wire                            forney_ready;
    wire [WORD_WIDTH - 1 : 0]       err_value[T_NUM];
    
    //----------------------------------------------------------------------//
    // functions                                                            //
    //----------------------------------------------------------------------//
    function [CODE_WIDTH - 1 : 0] correct_word;
        input bit [WORD_WIDTH - 1 : 0]  num_err;
        input bit [WORD_WIDTH - 1 : 0]  roots[T_NUM];
        input bit [CODE_WIDTH - 1 : 0]  data;
        input bit [WORD_WIDTH - 1 : 0]  err_value[T_NUM];
        bit [CODE_WIDTH - 1 : 0]  data_tmp;
        integer cnt;
            begin
                cnt = 0;
                data_tmp = data;
                // if (num_err != 0)
                //     begin
                        for (int i = 1; i <= N_NUM*WORD_WIDTH; i++)
                            begin
                                if (i == roots[cnt])
                                    begin
                                        // data_tmp    = {data_tmp[CODE_WIDTH - 1 - WORD_WIDTH : 0], data_tmp[CODE_WIDTH - 1 : CODE_WIDTH - WORD_WIDTH]^err_value[cnt]};
                                        data_tmp    = {data_tmp[WORD_WIDTH - 1 : 0]^err_value[cnt], data_tmp[CODE_WIDTH - 1 : WORD_WIDTH]};
                                        cnt         = cnt + 1;
                                    end
                                else
                                    begin
                                        // data_tmp = {data_tmp[CODE_WIDTH - 1 - WORD_WIDTH : 0], data_tmp[CODE_WIDTH - 1 : CODE_WIDTH - WORD_WIDTH]};
                                        data_tmp = {data_tmp[WORD_WIDTH - 1 : 0], data_tmp[CODE_WIDTH - 1 : WORD_WIDTH]};
                                    end
                            end
                    // end
                correct_word = data_tmp;
            end
    endfunction
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
        .data_a     (shift_reg[1*WORD_WIDTH - 1 : 0*WORD_WIDTH]),         // шина данных
        .data_b     (shift_data[WORD_WIDTH - 1 : 0]),         // шина данных
        .data_out   (result_sum)        // шина результирующих данных
    );
    // множитель пятой степени
    gf2_3mult
    gf2_3mult_5
    (
        .data_a     (A_10DEGREE),
        .data_b     (result_sum),
        .data_out   (result[5])
    );
    // множитель четвертой степени
    gf2_3mult
    gf2_3mult_4
    (
        .data_a     (A_14DEGREE),
        .data_b     (result_sum),
        .data_out   (result[4])
    );
    // множитель третьей степени
    gf2_3mult
    gf2_3mult_3
    (
        .data_a     (A_4DEGREE),
        .data_b     (result_sum),
        .data_out   (result[3])
    );
    // множитель второй степени
    gf2_3mult
    gf2_3mult_2
    (
        .data_a     (A_6DEGREE),
        .data_b     (result_sum),
        .data_out   (result[2])
    );
    // множитель первой степени
    gf2_3mult
    gf2_3mult_1
    (
        .data_a     (A_9DEGREE),
        .data_b     (result_sum),
        .data_out   (result[1])
    );
    // множитель нулевой степени
    gf2_3mult
    gf2_3mult_0
    (
        .data_a     (A_6DEGREE),
        .data_b     (result_sum),
        .data_out   (result[0])
    );
    // сумматор нулевого слова свигового регистра с результатом умножения первой степени 
    gf2_add
    gf2_add_01
    (
        .data_a     (shift_reg[6*WORD_WIDTH - 1 : 5*WORD_WIDTH]),         // шина данных
        .data_b     (result[1]),         // шина данных
        .data_out   (result_sec[0])        // шина результирующих данных
    );
    // сумматор первого слова свигового регистра с результатом умножения второй степени 
    gf2_add
    gf2_add_12
    (
        .data_a     (shift_reg[5*WORD_WIDTH - 1 : 4*WORD_WIDTH]),         // шина данных
        .data_b     (result[2]),         // шина данных
        .data_out   (result_sec[1])        // шина результирующих данных
    );
    // сумматор второго слова свигового регистра с результатом умножения третьей степени 
    gf2_add
    gf2_add_23
    (
        .data_a     (shift_reg[4*WORD_WIDTH - 1 : 3*WORD_WIDTH]),         // шина данных
        .data_b     (result[3]),         // шина данных
        .data_out   (result_sec[2])        // шина результирующих данных
    );
    // сумматор третьего слова свигового регистра с результатом умножения четвертой степени 
    gf2_add
    gf2_add_34
    (
        .data_a     (shift_reg[3*WORD_WIDTH - 1 : 2*WORD_WIDTH]),         // шина данных
        .data_b     (result[4]),         // шина данных
        .data_out   (result_sec[3])        // шина результирующих данных
    );
    // сумматор четвертой слова свигового регистра с результатом умножения пятой степени 
    gf2_add
    gf2_add_45
    (
        .data_a     (shift_reg[2*WORD_WIDTH - 1 : 1*WORD_WIDTH]),         // шина данных
        .data_b     (result[5]),         // шина данных
        .data_out   (result_sec[4])        // шина результирующих данных
    );
    // SYNDROM
    // множитель первого корня
    gf2_3mult
    gf2_3mult_root1
    (
        .data_a     (A_1DEGREE),
        .data_b     (syndrom[0]),
        .data_out   (mult_root[0])
    );
    // сумматор первого корня
    gf2_add
    gf2_add_root1
    (
        .data_a     (shift_data[WORD_WIDTH - 1 : 0]),         // шина данных
        .data_b     (mult_root[0]),         // шина данных
        .data_out   (sum_root[0])        // шина результирующих данных
    );
    // множитель второго корня
    gf2_3mult
    gf2_3mult_root2
    (
        .data_a     (A_2DEGREE),
        .data_b     (syndrom[1]),
        .data_out   (mult_root[1])
    );
    // сумматор второго корня
    gf2_add
    gf2_add_root2
    (
        .data_a     (shift_data[WORD_WIDTH - 1 : 0]),         // шина данных
        .data_b     (mult_root[1]),         // шина данных
        .data_out   (sum_root[1])        // шина результирующих данных
    );
    // множитель третьего корня
    gf2_3mult
    gf2_3mult_root3
    (
        .data_a     (A_3DEGREE),
        .data_b     (syndrom[2]),
        .data_out   (mult_root[2])
    );
    // сумматор третьего корня
    gf2_add
    gf2_add_root3
    (
        .data_a     (shift_data[WORD_WIDTH - 1 : 0]),         // шина данных
        .data_b     (mult_root[2]),         // шина данных
        .data_out   (sum_root[2])        // шина результирующих данных
    );
    // множитель четвертого корня
    gf2_3mult
    gf2_3mult_root4
    (
        .data_a     (A_4DEGREE),
        .data_b     (syndrom[3]),
        .data_out   (mult_root[3])
    );
    // сумматор четвертого корня
    gf2_add
    gf2_add_root4
    (
        .data_a     (shift_data[WORD_WIDTH - 1 : 0]),         // шина данных
        .data_b     (mult_root[3]),         // шина данных
        .data_out   (sum_root[3])        // шина результирующих данных
    );
    // множитель пятого корня
    gf2_3mult
    gf2_3mult_root5
    (
        .data_a     (A_5DEGREE),
        .data_b     (syndrom[4]),
        .data_out   (mult_root[4])
    );
    // сумматор пятого корня
    gf2_add
    gf2_add_root5
    (
        .data_a     (shift_data[WORD_WIDTH - 1 : 0]),         // шина данных
        .data_b     (mult_root[4]),         // шина данных
        .data_out   (sum_root[4])        // шина результирующих данных
    );
    // множитель шестого корня
    gf2_3mult
    gf2_3mult_root6
    (
        .data_a     (A_6DEGREE),
        .data_b     (syndrom[5]),
        .data_out   (mult_root[5])
    );
    // сумматор шестого корня
    gf2_add
    gf2_add_root6
    (
        .data_a     (shift_data[WORD_WIDTH - 1 : 0]),         // шина данных
        .data_b     (mult_root[5]),         // шина данных
        .data_out   (sum_root[5])        // шина результирующих данных
    );

    // error poly
    berlekamp_poly_v2
    berlekamp_poly_v2
    (
        .clk            (clk),            // синхросигнал
        .rst_n          (rst_n),          // сброс
        .en             (syn_rdy),             // готовность входных данных
        .syndrom        (syndrom),         // шина синдрома
        .rdy            (bkm_rdy),            // готовность выходной шины
        .poly_err       (bkm_poly)         // шина полином ошибки
    );
    // error location
    chein_search
    chein_search_inst
    (
        .clk            (clk),            // синхросигнал
        .rst_n          (rst_n),          // сигнал сброса
        .data_en        (bkm_rdy),        // готовность данных на входе
        .datain         (bkm_poly),         // шина входных данных
        .busy           (),           // занятость кодера 
        .data_rdy       (chein_rdy),       // готовность данных на выходе
        .mult_err       (),
        .pos_err        (pos_err),
        .num_err        (num_err),
        .dataout        (chein_o)         // шина выходных данных
    );

    mult_poly
    #(
        .WORD_WIDTH (WORD_WIDTH),
        .N_NUM      (T2_NUM)
    )
    mult_poly_inst
    (
        .clk        (clk),
        .rst_n      (rst_n),
        .en         (bkm_rdy),
        .poly_0     (syndrom),
        .poly_1     (bkm_poly),//{{4'd1},{4'd2},{4'd3},{4'd4},{4'd5},{4'd6}}),//bkm_poly),
        .ready      (mult_poly_en),
        .poly_o     (mult_poly_o)
    );

    forney
    forney_inst
    (
        .clk        (clk),
        .rst_n      (rst_n),
        .en         (chein_rdy),
        .num_err    (num_err),
        .roots      (chein_o),
        .data_g     (mult_poly_o),
        .data_l     (bkm_poly),
        .ready      (forney_ready),
        .err_value  (err_value)
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
                    data_rdy    <= 1'b0;
                    syn_rdy     <= 1'b0;
                    state       <= 0;
                    dataout     <= {CODE_WIDTH{1'b0}};
                    for (int i = 0; i < T2_NUM; i++)
                        begin
                            syndrom[i] <= {WORD_WIDTH{1'b0}};
                        end
                end
            else
                begin
                    data_en_reg <= data_en;
                    if (forney_ready)
                        begin
                            dataout <= correct_word(num_err, pos_err, shift_data, err_value);
                            data_rdy    <= 1'b1;
                        end
                    case (state)
                        IDLE:
                            begin
                                if (~data_en_reg && data_en)
                                    begin
                                        shift_data  <= datain;
                                        cnt_nword   <= N_NUM;
                                        data_rdy    <= 1'b0;
                                        syn_rdy     <= 1'b0;
                                        state       <= PROC;
                                        busy        <= 1'b1;
                                    end
                            end
                        PROC:
                            begin
                                if (cnt_nword != 0)
                                    begin
                                        cnt_nword   <= cnt_nword - 1'b1;
                                        shift_reg[6*WORD_WIDTH - 1 : 5*WORD_WIDTH] <= result[0];
                                        shift_reg[5*WORD_WIDTH - 1 : 4*WORD_WIDTH] <= result_sec[0];
                                        shift_reg[4*WORD_WIDTH - 1 : 3*WORD_WIDTH] <= result_sec[1];
                                        shift_reg[3*WORD_WIDTH - 1 : 2*WORD_WIDTH] <= result_sec[2];
                                        shift_reg[2*WORD_WIDTH - 1 : 1*WORD_WIDTH] <= result_sec[3];
                                        shift_reg[1*WORD_WIDTH - 1 : 0*WORD_WIDTH] <= result_sec[4];
                                        shift_data <= {shift_data[WORD_WIDTH - 1 : 0], shift_data[CODE_WIDTH - 1 : WORD_WIDTH]};
                                        // shift_data[CODE_WIDTH - 1 : 0] <= {shift_data[3 : 0],shift_data[CODE_WIDTH - 1 : 4]};
                                        syndrom   <= sum_root;
                                    end
                                else
                                    begin
                                        busy        <= 1'b0;
                                        // data_rdy    <= 1'b1;
                                        syn_rdy     <= 1'b1;
                                        state       <= IDLE;
                                    end
                            end
                        default:;
                    endcase
                end
        end
endmodule