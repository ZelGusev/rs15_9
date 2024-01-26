/*************************************************************************************************************
--    Система        : 
--    Разработчик    : 
--    Автор          : Гусев Игорь
--
--    Назначение     : Chien search
--                     Поиск локаторов
--------------------------------------------------------------------------------------------------------------
--    Примечание     : 
*************************************************************************************************************/
module chein_search(
    clk,            // синхросигнал
    rst_n,          // сигнал сброса
    data_en,        // готовность данных на входе
    datain,         // шина входных данных
    busy,           // занятость кодера 
    data_rdy,       // готовность данных на выходе
    mult_err,
    pos_err,
    num_err,
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

    // localparam [WORD_WIDTH - 1 : 0] A_DEGREE[N_NUM] = {
    //     4'b0001, 4'b0010, 4'b0100, 4'b1000, 4'b0011, 4'b0110, 4'b1100, 4'b1011,
    //     4'b0101, 4'b1010, 4'b0111, 4'b1110, 4'b1111, 4'b1101, 4'b1001};
    localparam [WORD_WIDTH - 1 : 0] A_DEGREE[N_NUM] = {
        4'b0010, 4'b0100, 4'b1000, 4'b0011, 4'b0110, 4'b1100, 4'b1011,
        4'b0101, 4'b1010, 4'b0111, 4'b1110, 4'b1111, 4'b1101, 4'b1001, 4'b0001};
    function void func_err;
        input [WORD_WIDTH - 1 : 0]  locator [N_NUM];
        output [WORD_WIDTH - 1 : 0]          num_err;
        output [WORD_WIDTH - 1 : 0]   pos_err [T_NUM];
        reg [WORD_WIDTH - 1 : 0]        num;
        reg [WORD_WIDTH - 1 : 0]  pos [T_NUM];
        begin
            num = 0;
            for (int i = 0; i < T_NUM; i ++)
                pos[i] = {WORD_WIDTH{1'b0}};
            for (int i = 0; i < N_NUM; i ++)
                begin
                    if (~|locator[i])
                        begin
                            pos[num] = i + 1;
                            num = num + 1;
                        end
                end
            num_err = num;
            pos_err = pos;
        end
    endfunction

    function [WORD_WIDTH*T_NUM - 1 : 0]  err_location;
        input [WORD_WIDTH - 1 : 0]  locator [N_NUM];
        input [WORD_WIDTH - 1 : 0]  arr_degree [N_NUM];
        integer count;
        reg [WORD_WIDTH*T_NUM - 1 : 0]  err_r;
        begin
            count = 0;
            err_r = {WORD_WIDTH*T_NUM{1'b0}};
            for (integer i = 0; i < N_NUM; i++)
                begin
                    if ((~|locator[i]) && (count < T_NUM))
                        begin
                            // err_r <<= WORD_WIDTH;
                            err_r [WORD_WIDTH - 1 : 0] = arr_degree[i];
                            err_r = {err_r[WORD_WIDTH - 1 : 0] , err_r [WORD_WIDTH*T_NUM - 1 : WORD_WIDTH]};
                            count = count + 1;
                        end
                end
            // if (count < T_NUM)
            //     begin
            //         for (integer i = count; i < T_NUM; i++)
            //             begin
            //                 err_r = {err_r[WORD_WIDTH - 1 : 0] , err_r [WORD_WIDTH*T_NUM - 1 : WORD_WIDTH]};
            //             end
            //     end
            err_location = err_r;
        end
    endfunction
    //----------------------------------------------------------------------//
    // external signals                                                     //
    //----------------------------------------------------------------------//
    input                           clk;            // синхросигнал
    input                           rst_n;          // синхросигнал
    input                           data_en;        // готовность данных на входе
    input    [WORD_WIDTH - 1 : 0]   datain [T2_NUM];         // шина входных данных
    output reg                      busy;           // занятость кодера 
    output reg                      data_rdy;       // готовность данных на выходе
    output reg                      mult_err;
    output reg [WORD_WIDTH - 1 : 0] pos_err [T_NUM];
    output reg [WORD_WIDTH - 1 : 0] num_err;
    output [WORD_WIDTH - 1 : 0]     dataout [T_NUM];        // шина выходных данных
    //----------------------------------------------------------------------//
    // registers                                                            //
    //----------------------------------------------------------------------//
    reg [ERR_WIDTH - 1 : 0]         root_value;       // полином ошибки
    reg [WORD_WIDTH - 1 : 0]        err_poly [T2_NUM];       // полином ошибки
    reg [WORD_WIDTH - 1 : 0]        cnt_nword;      // счетчик количества информационных слов
    reg                             data_en_reg;    // регистр фронта
    reg [WORD_WIDTH - 1 : 0]        locator [N_NUM];
    localparam FSM_SIZE = 4; //размер регистра состояний
    localparam [FSM_SIZE - 1 : 0]  
                   IDLE     = 0,     // установка регистра индекса 
                   RUN      = 1;     // обновить статус текущей области при возникновении ошибки 
    reg [FSM_SIZE - 1 : 0] state;
    //----------------------------------------------------------------------//
    // wires                                                                //
    //----------------------------------------------------------------------//
    
    wire [WORD_WIDTH - 1 : 0]       mult_root   [N_NUM];
    wire [WORD_WIDTH - 1 : 0]       sum_root    [N_NUM];
    wire [WORD_WIDTH - 1 : 0]       arr_degree  [N_NUM];
    //----------------------------------------------------------------------//
    // assigns                                                              //
    //----------------------------------------------------------------------//
    genvar ii;
    generate
        for (ii = 0; ii < T_NUM; ii++)
            begin
                assign dataout[ii] = root_value>>WORD_WIDTH*ii;
            end
        for (ii = 0; ii < N_NUM; ii++)
            begin
                assign arr_degree [ii] = A_DEGREE[ii];
            end
    //----------------------------------------------------------------------//
    // component                                                            //
    //----------------------------------------------------------------------//
        for (ii = 0; ii < N_NUM; ii++)
            begin
                // множитель корня
                gf2_3mult
                gf2_3mult_root_ii
                (
                    .data_a     (A_DEGREE[ii]),
                    .data_b     (locator[ii]),
                    .data_out   (mult_root[ii])
                );
                // сумматор корня
                gf2_add
                gf2_add_root1
                (
                    .data_a     (err_poly[5]),         // шина данных
                    .data_b     (mult_root[ii]),         // шина данных
                    .data_out   (sum_root[ii])        // шина результирующих данных
                );
            end
    endgenerate
    //----------------------------------------------------------------------//
    // logic                                                                //
    //----------------------------------------------------------------------//
    always @(posedge clk)
        begin
            if (~rst_n)
                begin
                    cnt_nword   <= {CNT_WIDTH{1'b0}};
                    mult_err    <= 1'b0;
                    num_err     <= {WORD_WIDTH{1'b0}};
                    data_en_reg <= 1'b0;
                    busy        <= 1'b0;
                    data_rdy    <= 1'b0;
                    state       <= IDLE;
                    for (int i = 0; i < T_NUM; i ++)
                        pos_err[i]  <= {WORD_WIDTH{1'b0}};
                    for (int i = 0; i < T2_NUM; i ++)
                        begin
                            err_poly[i] <= {SHIFT_WIDTH{1'b0}};
                        end
                    for (int i = 0; i < N_NUM; i ++)
                        begin
                            locator[i] <= {SHIFT_WIDTH{1'b0}};
                        end
                    root_value     <= {ERR_WIDTH{1'b0}};
                end
            else
                begin
                    data_en_reg <= data_en;
                    case (state)
                        IDLE:
                            begin
                                if (~data_en_reg && data_en)
                                    begin
                                        err_poly    <= datain;
                                        cnt_nword   <= N_NUM - K_NUM;
                                        data_rdy    <= 1'b0;
                                        state       <= RUN;
                                        busy        <= 1'b1;
                                        mult_err    <= 1'b0;
                                        for (int i = 0; i < T_NUM; i ++)
                                            pos_err[i]  <= {WORD_WIDTH{1'b0}};
                                    end
                            end
                        RUN:
                            begin
                                if (cnt_nword != 0)
                                    begin
                                        cnt_nword   <= cnt_nword - 1'b1;
                                        locator     <= sum_root;
                                        err_poly[0] <= err_poly[5];
                                        for (int i = 0; i < T2_NUM - 1; i ++)
                                            begin
                                                err_poly[i+1] <= err_poly[i];
                                            end
                                    end
                                else
                                    begin
                                        busy        <= 1'b0;
                                        data_rdy    <= 1'b1;
                                        state       <= IDLE;
                                        root_value     <= err_location(locator, arr_degree);
                                        func_err(locator, num_err, pos_err);
                                        if (num_err > 3)
                                            mult_err <= 1'b1;
                                        else
                                            mult_err <= 1'b0;
                                    end
                            end
                        default:;
                    endcase
                end
        end
endmodule