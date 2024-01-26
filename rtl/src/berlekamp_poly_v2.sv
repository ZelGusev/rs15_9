/*************************************************************************************************************
--    Система        : 
--    Разработчик    : 
--    Автор          : Гусев Игорь
--
--    Назначение     : Алгорит Бекрликампа 
--                     поиск полинома ошибки
--------------------------------------------------------------------------------------------------------------
--    Примечание     : 
*************************************************************************************************************/
module berlekamp_poly_v2(
    clk,            // синхросигнал
    rst_n,          // сброс
    en,             // готовность входных данных
    syndrom,         // шина синдрома
    rdy,            // готовность выходной шины
    poly_err         // шина полином ошибки
    );
    //----------------------------------------------------------------------//
    // external parameters                                                  //
    //----------------------------------------------------------------------//
    parameter WORD_WIDTH            = 4;
    parameter NUM_NK                = 6;
    //----------------------------------------------------------------------//
    // internal parameters                                                  //
    //----------------------------------------------------------------------//
    //----------------------------------------------------------------------//
    // external signals                                                     //
    //----------------------------------------------------------------------//
    input                               clk;            // синхросигнал
    input                               rst_n;          // сброс
    input                               en;             // готовность входных данных
    input       [WORD_WIDTH - 1 : 0]    syndrom [NUM_NK];         // шина синдрома
    output reg                          rdy;            // готовность выходной шины
    output reg  [WORD_WIDTH - 1 : 0]    poly_err [NUM_NK];         // шина полином ошибки
    //----------------------------------------------------------------------//
    // registers                                                            //
    //----------------------------------------------------------------------//
    localparam FSM_SIZE = 4; //размер регистра состояний
      
    localparam [FSM_SIZE - 1 : 0]  
                        IDLE            = 0,     // установка регистра индекса 
                        ALPHA_CAL       = 1,
                        OTHER_CAL       = 2;

    reg [FSM_SIZE - 1 : 0] state  =  4'd0;
    reg                         en_reg;     // фронт сигнала
    // reg [WORD_WIDTH - 1 : 0]    poly_err    [NUM_NK];
    reg [WORD_WIDTH - 1 : 0]    poly_b      [NUM_NK];
    reg [WORD_WIDTH - 1 : 0]    syn_r       [NUM_NK];
    reg [WORD_WIDTH - 1 : 0]    alpha;

    integer                     l_reg;
    integer                     cnt;
    //----------------------------------------------------------------------//
    // wires                                                                //
    //----------------------------------------------------------------------//
    wire [WORD_WIDTH - 1 : 0]    alpha_n;
    wire [WORD_WIDTH - 1 : 0]    mult_b_sum [NUM_NK];
    wire [WORD_WIDTH - 1 : 0]    mult_b_w [NUM_NK];
    wire [WORD_WIDTH - 1 : 0]   mult [NUM_NK];

    genvar ii;
    //----------------------------------------------------------------------//
    // assigns                                                              //
    //----------------------------------------------------------------------//
    //----------------------------------------------------------------------//
    // component                                                            //
    //----------------------------------------------------------------------//
    generate
        for (ii = 0; ii < NUM_NK; ii++)
            begin
                gf2_3mult
                gf2_3mult_alpha_b_ii
                (
                    .data_a     (alpha),
                    .data_b     (poly_b[ii]),
                    .data_out   (mult_b_sum[ii])
                );
                gf2_3mult
                gf2_3mult_b_ii
                (
                    .data_a     (poly_err[ii]),
                    .data_b     (alpha_n),
                    .data_out   (mult_b_w[ii])
                );
                gf2_3mult
                gf2_3mult_s_pol_err
                (
                    .data_a     (poly_err[ii]),
                    .data_b     (syn_r[ii]),
                    .data_out   (mult[ii])
                );
            end
    endgenerate
    gf2_3_inv
    gf2_3_inv_alpha
    (
        .data_i     (alpha),         // шина данных
        .data_out   (alpha_n)        // шина результирующих данных
    );
    //----------------------------------------------------------------------//
    // logic                                                                //
    //----------------------------------------------------------------------//
    always @(posedge clk)
        begin
            if (~rst_n)
                begin
                    rdy             <= 1'b0;
                    en_reg          <= 1'b0;
                    state           <= IDLE;
                    cnt             <= 0;
                    l_reg           <= 0;
                    alpha           <= {WORD_WIDTH{1'b0}};
                    for (int i = 0; i < NUM_NK; i++)
                        begin
                            syn_r[i]        <= {WORD_WIDTH{1'b0}};
                            if (i==0)
                                begin
                                    poly_err[i]        <= 4'b0001;
                                    poly_b[i]          <= 4'b0001;
                                end
                            else
                                begin
                                    poly_err[i]        <= {WORD_WIDTH{1'b0}};
                                    poly_b[i]          <= {WORD_WIDTH{1'b0}};
                                end
                        end
                end
            else
                begin
                    en_reg <= en;
                    case (state)
                        IDLE:
                            begin
                                if (~en_reg && en)
                                    begin
                                        state           <= ALPHA_CAL;
                                        syn_r[0]        <= syndrom[0];
                                        rdy             <= 1'b0;
                                        alpha           <= 0;
                                        cnt             <= 1;
                                        l_reg           <= 0;
                                    end
                            end
                        ALPHA_CAL:
                            begin
                                case (l_reg)
                                    0: alpha <= mult[0];
                                    1: alpha <= mult[0] ^ mult[1];
                                    2: alpha <= mult[0] ^ mult[1] ^ mult[2];
                                    3: alpha <= mult[0] ^ mult[1] ^ mult[2] ^ mult[3];
                                    4: alpha <= mult[0] ^ mult[1] ^ mult[2] ^ mult[3] ^ mult[4];
                                    default:;
                                endcase
                                state           <= OTHER_CAL;
                            end
                        OTHER_CAL:
                            begin
                                if (cnt < NUM_NK)
                                    begin
                                        state           <= ALPHA_CAL;
                                        cnt <= cnt + 1;
                                    end
                                else
                                    begin
                                        rdy <= 1'b1;
                                        cnt <= 0;
                                        state <= IDLE;
                                    end
                                syn_r[0]    <= syndrom[cnt];
                                for (int i = 0; i < NUM_NK - 1; i++)
                                    begin
                                        syn_r[i + 1] <= syn_r[i];
                                    end
                                if (alpha != 0)
                                    begin
                                        for (int i = 0; i < NUM_NK - 1; i++)
                                            begin
                                                poly_err[i+1] <= poly_err[i+1] ^ mult_b_sum[i];
                                            end
                                    end
                                if ((2*l_reg <= cnt - 1))
                                    begin
                                        l_reg   <= cnt - l_reg;
                                        if (alpha != 0)
                                            poly_b  <= mult_b_w;
                                        else
                                            begin
                                                poly_b[0] <= {WORD_WIDTH{1'b0}};
                                                for (int i = 0; i < NUM_NK - 1; i++)
                                                    begin
                                                        poly_b[i+1] <= poly_b[i];
                                                    end
                                            end
                                    end
                                else
                                    begin
                                        poly_b[0] <= {WORD_WIDTH{1'b0}};
                                        for (int i = 0; i < NUM_NK - 1; i++)
                                            begin
                                                poly_b[i+1] <= poly_b[i];
                                            end
                                    end
                            end
                        default:;
                    endcase
                end
        end
endmodule