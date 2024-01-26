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
module berlekamp_poly(
    clk,            // синхросигнал
    rst_n,          // сброс
    en,             // готовность входных данных
    syndrom,         // шина синдрома
    rdy,            // готовность выходной шины
    data_o,         // шина полином ошибки
    data_n,         // шина полином ошибки
    );
    //----------------------------------------------------------------------//
    // external parameters                                                  //
    //----------------------------------------------------------------------//
    parameter DATA_WIDTH            = 24;
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
    output reg  [WORD_WIDTH - 1 : 0]    data_o [NUM_NK];         // шина полином ошибки
    output reg  [WORD_WIDTH - 1 : 0]    data_n [NUM_NK];         // шина полином ошибки
    //----------------------------------------------------------------------//
    // registers                                                            //
    //----------------------------------------------------------------------//
    localparam FSM_SIZE = 4; //размер регистра состояний
      
    localparam [FSM_SIZE - 1 : 0]  
                IDLE          = 0,     // установка регистра индекса 
                SET           = 1,     // установка адреса регистра статуса текущего буфера 
                RUN           = 2,     // установка значения регистра
                STOP          = 3;     // обновить статус текущей области при возникновении ошибки 

    reg [FSM_SIZE - 1 : 0] state  =  4'd0;

    integer                     u_last;
    integer                     h_last;
    reg [WORD_WIDTH - 1 : 0]    d_last;
    reg [WORD_WIDTH - 1 : 0]    err_last [NUM_NK];

    integer                     h_reg;
    reg [WORD_WIDTH - 1 : 0]    d_reg;
    reg [WORD_WIDTH - 1 : 0]    err_rom [NUM_NK];
    reg [WORD_WIDTH - 1 : 0]    shift_syn_rom [NUM_NK];
    
    integer                     cnt;
    reg                         en_reg;     // фронт сигнала
    //----------------------------------------------------------------------//
    // wires                                                                //
    //----------------------------------------------------------------------//
    wire [WORD_WIDTH - 1 : 0]    d_last_inv;
    wire [WORD_WIDTH - 1 : 0]    coeff;

    wire [WORD_WIDTH - 1 : 0]   result_mult_err_last_to_add [NUM_NK];

    wire [WORD_WIDTH - 1 : 0]   mult_syn_coeff [NUM_NK];

    wire [WORD_WIDTH - 1 : 0]   mult_err_last [NUM_NK];
    
    wire [WORD_WIDTH - 1 : 0]   mult_dudp;

    wire [WORD_WIDTH - 1 : 0]   sum_er_rom [NUM_NK];

    wire mult_en;
    wire sense [NUM_NK];
    genvar ii;
    //----------------------------------------------------------------------//
    // assigns                                                              //
    //----------------------------------------------------------------------//
    assign mult_en = (d_reg == 4'd0 && state == 2)? 1'b0 : 1'b1;
    assign coeff = (state == 2)? d_reg : syndrom[0];
    assign result_mult_err_last_to_add[0] = (~mult_en)? 4'b0000 : ((cnt - u_last) == 0)? mult_err_last[0] : 4'b0000;
    assign result_mult_err_last_to_add[1] = (~mult_en)? 4'b0000 : ((cnt - u_last) == 0)? mult_err_last[1] : ((cnt - u_last) == 1)? mult_err_last[0] : 4'b0000;
    assign result_mult_err_last_to_add[2] = (~mult_en)? 4'b0000 : ((cnt - u_last) == 0)? mult_err_last[2] : ((cnt - u_last) == 1)? mult_err_last[1] : ((cnt - u_last) == 2)? mult_err_last[0] : 4'b0000;
    assign result_mult_err_last_to_add[3] = (~mult_en)? 4'b0000 : ((cnt - u_last) == 0)? mult_err_last[3] : ((cnt - u_last) == 1)? mult_err_last[2] : ((cnt - u_last) == 2)? mult_err_last[1] : ((cnt - u_last) == 3)? mult_err_last[0] : 4'b0000;
    assign result_mult_err_last_to_add[4] = (~mult_en)? 4'b0000 : ((cnt - u_last) == 0)? mult_err_last[4] : ((cnt - u_last) == 1)? mult_err_last[3] : ((cnt - u_last) == 2)? mult_err_last[2] : ((cnt - u_last) == 3)? mult_err_last[1] : ((cnt - u_last) == 4)? mult_err_last[0] : 4'b0000;
    assign result_mult_err_last_to_add[5] = (~mult_en)? 4'b0000 : ((cnt - u_last) == 0)? mult_err_last[5] : ((cnt - u_last) == 1)? mult_err_last[4] : ((cnt - u_last) == 2)? mult_err_last[3] : ((cnt - u_last) == 3)? mult_err_last[2] : ((cnt - u_last) == 4)? mult_err_last[1] : ((cnt - u_last) == 5)? mult_err_last[0] : 4'b0000;
    
    // assign sense[0] = |err_rom[0];
    // assign sense[1] = |err_rom[1];
    // assign sense[2] = |err_rom[2];
    // assign sense[3] = |err_rom[3];
    // assign sense[4] = |err_rom[4];
    // assign sense[5] = |err_rom[5];
    generate
        for (ii = 0; ii < NUM_NK; ii++)
            begin
                assign sense[ii] = |err_rom[ii];
            end
    endgenerate
    //----------------------------------------------------------------------//
    // component                                                            //
    //----------------------------------------------------------------------//
    gf2_3_inv
    gf2_3_inv_d_last
    (
        .data_i     (d_last),         // шина данных
        .data_out   (d_last_inv)        // шина результирующих данных
    );
    // множитель нулевой степени
    gf2_3mult
    gf2_3mult_dudp
    (
        .data_a     (d_last),
        .data_b     (coeff),
        .data_out   (mult_dudp)
    );
    ////////////////////////////////////////////////////////////// множитель полинома ошибки степени перед сумматором
    generate
        for (ii = 0; ii < NUM_NK - 1; ii++)
            begin
                gf2_3mult
                gf2_3mult_err_last_ii
                (
                    .data_a     (err_last[ii]),
                    .data_b     (mult_dudp),
                    .data_out   (mult_err_last[ii])
                );
            end
        ////////////////////////////////////////////////////////////// сумматор полинома ошибки 
        for (ii = 0; ii < NUM_NK; ii++)
            begin
                gf2_add
                gf2_add_poly0
                (
                    .data_a     (err_rom[ii]),         // шина данных
                    .data_b     (result_mult_err_last_to_add[ii]),         // шина данных
                    .data_out   (sum_er_rom[ii])        // шина результирующих данных
                );
            end

        for (ii = 1; ii < NUM_NK; ii++)
            begin
                gf2_3mult
                gf2_3mult_coeff1
                (
                    .data_a     (sum_er_rom[ii]),
                    .data_b     (shift_syn_rom[ii]),
                    .data_out   (mult_syn_coeff[ii-1])
                );
            end
    endgenerate

    //----------------------------------------------------------------------//
    // logic                                                                //
    //----------------------------------------------------------------------//
    always @(*)
        begin
            data_o = err_rom;
            if (~sense[5] && ~sense[4] && ~sense[3] && ~sense[2] && ~sense[1] && ~sense[0])
                begin
                    data_n [0] = err_rom[0];
                    data_n [1] = err_rom[1];
                    data_n [2] = err_rom[2];
                    data_n [3] = err_rom[3];
                    data_n [4] = err_rom[4];
                    data_n [5] = err_rom[5];
                end
            else if (~sense[5] && ~sense[4] && ~sense[3] && ~sense[2] && ~sense[1])
                begin
                    data_n [0] = err_rom[0];
                    data_n [1] = err_rom[1];
                    data_n [2] = err_rom[2];
                    data_n [3] = err_rom[3];
                    data_n [4] = err_rom[4];
                    data_n [5] = err_rom[5];
                end
            else if (~sense[5] && ~sense[4] && ~sense[3] && ~sense[2])
                begin
                    data_n [0] = err_rom[1];
                    data_n [1] = err_rom[0];
                    data_n [2] = err_rom[2];
                    data_n [3] = err_rom[3];
                    data_n [4] = err_rom[4];
                    data_n [5] = err_rom[5];
                end
            else if (~sense[5] && ~sense[4] && ~sense[3])
                begin
                    data_n [0] = err_rom[2];
                    data_n [1] = err_rom[1];
                    data_n [2] = err_rom[0];
                    data_n [3] = err_rom[3];
                    data_n [4] = err_rom[4];
                    data_n [5] = err_rom[5];
                end
            else if (~sense[5] && ~sense[4])
                begin
                    data_n [0] = err_rom[3];
                    data_n [1] = err_rom[2];
                    data_n [2] = err_rom[1];
                    data_n [3] = err_rom[0];
                    data_n [4] = err_rom[4];
                    data_n [5] = err_rom[5];
                end
            else if (~sense[5])
                begin
                    data_n [0] = err_rom[4];
                    data_n [1] = err_rom[3];
                    data_n [2] = err_rom[2];
                    data_n [3] = err_rom[1];
                    data_n [4] = err_rom[0];
                    data_n [5] = err_rom[5];
                end
            else
                begin
                    data_n [0] = err_rom[5];
                    data_n [1] = err_rom[4];
                    data_n [2] = err_rom[3];
                    data_n [3] = err_rom[2];
                    data_n [4] = err_rom[1];
                    data_n [5] = err_rom[0];
                end
        end
    always @(posedge clk)
        begin
            if (~rst_n)
                begin
                    rdy             <= 1'b0;
                    en_reg          <= 1'b0;
                    state           <= IDLE;
                    u_last          <= -1;
                    h_last          <= 0;
                    h_reg           <= 0;
                    d_last          <= 4'b0001;
                    d_reg           <= 4'b0000;
                    for (int i = 0; i < NUM_NK; i++)
                        begin
                            if (i==0)
                                begin
                                    err_last[0]     <= 4'b0001;
                                    err_rom[0]      <= 4'b0001;
                                end
                            else
                                begin
                                    err_last[i]     <= {WORD_WIDTH{1'b0}};
                                    err_rom[i]      <= {WORD_WIDTH{1'b0}};
                                    data_o[i]       <= {WORD_WIDTH{1'b0}};
                                    data_n[i]       <= {WORD_WIDTH{1'b0}};
                                end
                            shift_syn_rom[i]  <= {WORD_WIDTH{1'b0}};
                        end
                    cnt             <= 0;
                end
            else
                begin
                    en_reg <= en;
                    case (state)
                        IDLE:
                            begin
                                if (~en_reg && en)
                                    begin
                                        state           <= SET;
                                        rdy             <= 1'b0;
                                        shift_syn_rom [0]   <= syndrom[2];
                                        shift_syn_rom [1]   <= syndrom[1];
                                        shift_syn_rom [2]   <= syndrom[0];
                                    end
                            end
                        SET:
                            begin
                                state   <= RUN;
                                cnt     <= cnt + 1;
                                d_reg   <= syndrom[cnt+1] ^ mult_syn_coeff[0];
                                if (syndrom[cnt] != 0)
                                    begin
                                        err_rom[0]  <= sum_er_rom[0];
                                        err_rom[1]  <= sum_er_rom[1];
                                        err_rom[2]  <= sum_er_rom[2];
                                        err_rom[3]  <= sum_er_rom[3];
                                        err_rom[4]  <= sum_er_rom[4];
                                        err_rom[5]  <= sum_er_rom[5];
                                        err_last[0] <= err_rom[0];
                                        err_last[1] <= err_rom[1];
                                        err_last[2] <= err_rom[2];
                                        err_last[3] <= err_rom[3];
                                        err_last[4] <= err_rom[4];
                                        err_last[5] <= err_rom[5];
                                        h_reg       <= 1;
                                        u_last      <= cnt;
                                        h_last      <= h_reg;
                                        d_last      <= syndrom[cnt];
                                    end
                            end
                        RUN:
                            begin
                                if (cnt <= 4)
                                    begin
                                        cnt     <= cnt + 1;
                                        shift_syn_rom [1]   <= shift_syn_rom[0];
                                        shift_syn_rom [2]   <= shift_syn_rom[1];
                                        shift_syn_rom [3]   <= shift_syn_rom[2];
                                        shift_syn_rom [4]   <= shift_syn_rom[3];
                                        shift_syn_rom [5]   <= shift_syn_rom[4];
                                        d_reg   <= shift_syn_rom [0] ^ mult_syn_coeff[0] ^ mult_syn_coeff[1] ^ mult_syn_coeff[2] ^ mult_syn_coeff[3] ^ mult_syn_coeff[4];
                                        case(cnt)
                                            1: shift_syn_rom [0]   <= syndrom[3];
                                            2: shift_syn_rom [0]   <= syndrom[4];
                                            3: shift_syn_rom [0]   <= syndrom[5];
                                            4: shift_syn_rom [0]   <= 4'b0000;
                                            default:;
                                        endcase
                                        if (d_reg != 0)
                                            begin
                                                err_rom[0]  <= sum_er_rom[0];
                                                err_rom[1]  <= sum_er_rom[1];
                                                err_rom[2]  <= sum_er_rom[2];
                                                err_rom[3]  <= sum_er_rom[3];
                                                err_rom[4]  <= sum_er_rom[4];
                                                err_rom[5]  <= sum_er_rom[5];
                                                if (h_reg > h_last + cnt - u_last)
                                                    h_reg   <= h_reg;
                                                else
                                                    h_reg   <= h_last + cnt - u_last;
                                                if (cnt - h_reg >= u_last - h_last)
                                                    begin
                                                        err_last[0] <= err_rom[0];
                                                        err_last[1] <= err_rom[1];
                                                        err_last[2] <= err_rom[2];
                                                        err_last[3] <= err_rom[3];
                                                        err_last[4] <= err_rom[4];
                                                        err_last[5] <= err_rom[5];
                                                        u_last      <= cnt;
                                                        h_last      <= h_reg;
                                                        if (cnt < 7)
                                                            d_last      <= syndrom[cnt];
                                                    end
                                            end
                                    end
                                else
                                    begin
                                        rdy     <= 1'b1;
                                        state   <= IDLE;
                                    end
                            end
                        default:;
                    endcase
                end
        end
endmodule