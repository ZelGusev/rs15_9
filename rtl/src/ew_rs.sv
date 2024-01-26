/*************************************************************************************************************
--    Система        : 
--    Разработчик    : 
--    Автор          : Гусев Игорь
--
--    Назначение     : Код Хэмминга
--                     Исправляет 1 битовую ошибку, обнаруживает 2 бита ошибки
--------------------------------------------------------------------------------------------------------------
--    Примечание     : 
*************************************************************************************************************/
module ew_rs(
    clk,            // синхросигнал
    rst_n,          // сигнал сброса
    gen,            // сигнал управления кодер/декодер
    correct_n,      // сигнал вкл/выкл исправление ошибки
    datain,         // шина входных данных
    chkin,          // шина данных избыточного кода синдрома 
    err_detect,     // сигнал обнаружения ошибки
    err_multpl,     // сигнал обнаружения неисправимых ошибок 
    dataout,        // шина выходных данных
    chkout          // шина избыточности при synd_sel=1 шина синдрома
    );

    //----------------------------------------------------------------------//
    // external parameters                                                  //
    //----------------------------------------------------------------------//
    parameter DATA_WIDTH    = 88;       // ширина шины данных
    parameter SYN_WIDTH     = 32;       // ширина шины данных
    parameter SYN_SEL        = 0;        // определяет что будет выдаваться на chkout избыточность или синдром
    //----------------------------------------------------------------------//
    // internal parameters                                                  //
    //----------------------------------------------------------------------//
    // localparam C_SYN_WIDTH  = calculate_m(DATA_WIDTH);
    localparam C_ONE_WORD_WIDTH     = 4;
    localparam K_WIDTH              = 9;
    localparam N_WIDTH              = 15;
    localparam C_DATA_WIDTH         = K_WIDTH * C_ONE_WORD_WIDTH;
    //----------------------------------------------------------------------//
    // internal function                                                    //
    //----------------------------------------------------------------------//
    
    // function [C_SYN_WIDTH - 1 : 0] syn_out;  // соединение информационных данных с проверочными (0)
    //     input   bit [1 : DATA_WIDTH + C_SYN_WIDTH]    code_w;
    //     integer bit_c;
    //     integer bit_d;
    //     begin
    //         bit_d   = 0;
    //         for(bit_c = 1; bit_c <= DATA_WIDTH + C_SYN_WIDTH; bit_c++)
    //             if(1<<$clog2(bit_c) == bit_c)   // если позиция не степень двойки
    //                 begin
    //                     syn_out[bit_d] = code_w[bit_c];  // заполнение массива информационными данными
    //                     bit_d = bit_d + 1;
    //                 end
    //     end
    // endfunction
    //----------------------------------------------------------------------//
    // external signals                                                     //
    //----------------------------------------------------------------------//
    input                           clk;            // синхросигнал
    input                           rst_n;          // синхросигнал
    input                           gen;            // сигнал управления кодер/декодер
    input                           correct_n;      // сигнал вкл/выкл исправление ошибки
    input    [DATA_WIDTH - 1 : 0]   datain;         // шина входных данных
    input    [SYN_WIDTH - 1 : 0]    chkin;          // шина данных избыточного кода синдрома 
    output                          err_detect;     // сигнал обнаружения ошибки
    output                          err_multpl;     // сигнал обнаружения неисправимых ошибок 
    output   [DATA_WIDTH - 1 : 0]   dataout;        // шина выходных данных
    output   [SYN_WIDTH - 1 : 0]    chkout;         // шина избыточности при synd_sel=1 шина синдрома
    //----------------------------------------------------------------------//
    // registers                                                            //
    //----------------------------------------------------------------------//
    reg     [DATA_WIDTH - 1 : 0]    data_o_r;       // регистровый выход
    reg     [SYN_WIDTH - 1 : 0]     chk_o_r;        // регистровый выход
    reg                             err_detect_r;   // регистровый выход
    reg                             err_multpl_r;   // регистровый выход

    reg [4:0] lrs_1;
    reg [3:0] lrs_0;
    reg [3:0] lrs410;
    reg [7:0] lrs4320;
    
    reg [3:0]   test_shift;
    reg         flag_gen;
    reg         flag_gen_r;

    reg [3:0]   shift_next_gen;

    reg [3:0]   pure_power_shift;
    //GF(2^8) x^8+x^4+x^3+x^2+1
    wire    sum_0;
    wire    sum_1;
    wire    sum410;
    wire    sum4320;
    wire    test_sum;

    wire [3:0] next_gen_sum;
    //----------------------------------------------------------------------//
    // wires                                                                //
    //----------------------------------------------------------------------//
    // wire    [DATA_WIDTH + C_SYN_WIDTH - 1 : 0]  code;
    // wire                                        parity;              
    //----------------------------------------------------------------------//
    // assigns                                                              //
    //----------------------------------------------------------------------//
    assign  dataout         = data_o_r;         //
    assign  chkout          = chk_o_r;          //
    assign  err_detect      = err_detect_r;     //
    assign  err_multpl      = err_multpl_r;     //

    assign sum_0    = lrs_0[3] ^ lrs_0[0];
    assign sum_1    = lrs_1[1] ^ lrs_1[0];
    assign sum410   = lrs410[1] ^ lrs410[0];
    //assign sum4320  = lrs4320[4] ^ lrs4320[3] ^ lrs4320[2] ^ lrs4320[0];
    assign sum4320  = lrs4320[6] ^ lrs4320[5] ^ lrs4320[1] ^ lrs4320[0];

    assign test_sum = 1'b1 ^ test_shift[0];

    assign next_gen_sum [3] = shift_next_gen [2];
    assign next_gen_sum [2] = shift_next_gen [1];
    assign next_gen_sum [1] = shift_next_gen [3] ^ shift_next_gen [0];
    assign next_gen_sum [0] = shift_next_gen [3];
    //----------------------------------------------------------------------//
    // logic                                                                //
    //----------------------------------------------------------------------//
    always @(posedge clk)
        begin
            if (~rst_n)
                begin
                    data_o_r    <= {DATA_WIDTH{1'b0}};
                    chk_o_r     <= {SYN_WIDTH{1'b0}};
                    data_o_r    <= 1'b0;
                    chk_o_r     <= 1'b0;

                    lrs_0       <= {DATA_WIDTH{1'b1}};
                    lrs_1       <= {DATA_WIDTH{1'b1}};
                    lrs410      <= {DATA_WIDTH{1'b1}};
                    lrs4320     <= {DATA_WIDTH{1'b1}};

                    test_shift  <= {DATA_WIDTH{1'b1}};
                    flag_gen    <= 1'b0;
                    flag_gen_r  <= 1'b0;

                    shift_next_gen  <= {DATA_WIDTH{1'b1}};

                    pure_power_shift    <= {DATA_WIDTH{1'b1}};
                end
            else
                begin
                    pure_power_shift[3] <= pure_power_shift[2];
                    pure_power_shift[2] <= pure_power_shift[1];
                    pure_power_shift[1] <= pure_power_shift[3] ^ pure_power_shift[0];
                    pure_power_shift[0] <= pure_power_shift[3];

                    shift_next_gen <= next_gen_sum;

                    flag_gen_r <= flag_gen;
                    if (~flag_gen)
                        begin
                            flag_gen <= 1'b1;
                        end
                    if (~flag_gen_r && ~flag_gen)
                        begin
                            test_shift <= {DATA_WIDTH{1'b0}};
                        end
                    else if (~flag_gen_r && flag_gen)
                        begin
                            test_shift <= {test_shift[2:0], 1'b1};
                        end
                    else
                        begin
                            if (test_shift[3])
                                begin
                                    test_shift <= {test_shift[2:1], {test_sum, 1'b1}};
                                end
                            else
                                begin
                                    test_shift <= {test_shift[2:0], 1'b0};
                                end
                        end

                    lrs4320 <= {lrs4320[6:0],sum4320};

                    // sum_0 <= lrs_0[3] ^ lrs_0[0];
                    lrs_0 <= {lrs_0[2:0],sum_0};

                    // sum_1 <= lrs_1[1] ^ lrs_1[0];
                    lrs_1 <= {lrs_1[3:0],sum_1};
                    
                    lrs410  <= {lrs410[2:0], sum410};

                    if (gen)    // вычисления избыточности
                        begin
                            data_o_r    <= datain;
                            chk_o_r     <= chkin;
                        end
                    else if (~correct_n) // выполнение исправления
                        begin
                        end
                    else    // выдать как есть
                        begin
                            data_o_r    <= datain;
                            chk_o_r     <= chkin;
                        end
                end
        end
endmodule