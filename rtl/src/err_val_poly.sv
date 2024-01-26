/*************************************************************************************************************
--    Система        :
--    Разработчик    :
--    Автор          : Гусев Игорь
--
--    Назначение     :
--
--------------------------------------------------------------------------------------------------------------
--    Примечание     :
*************************************************************************************************************/

module err_val_poly(
    clk,
    rst_n,
    en,
    data_s,
    data_l,
    ready,
    gama
    );

    //----------------------------------------------------------------------//
    // external parameters                                                  //
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
    //----------------------------------------------------------------------//
    // internal parameters                                                  //
    //----------------------------------------------------------------------//
    //----------------------------------------------------------------------//
    // external signals                                                     //
    //----------------------------------------------------------------------//
    input                           clk;
    input                           rst_n;
    input                           en;
    input [SHIFT_WIDTH - 1 : 0]     data_s;
    input [SHIFT_WIDTH - 1 : 0]     data_l;
    output  reg                     ready;
    //output  [SHIFT_WIDTH - 1 : 0]   data_o;
    output reg [WORD_WIDTH - 1 : 0]        gama    [T2_NUM];
    //----------------------------------------------------------------------//
    // registers                                                            //
    //----------------------------------------------------------------------//
    reg [SHIFT_WIDTH - 1 : 0]       shift_l;
    reg                             en_reg;
    reg [WORD_WIDTH - 1 : 0]        shift_r [T2_NUM];
    reg [CNT_WIDTH - 1 : 0]         count;
    //----------------------------------------------------------------------//
    // wire                                                                 //
    //----------------------------------------------------------------------//
    wire [WORD_WIDTH - 1 : 0]       mult    [T2_NUM];
    wire [WORD_WIDTH - 1 : 0]       sum     [T2_NUM];
    wire [WORD_WIDTH - 1 : 0]       syn2m   [T2_NUM];
    wire [WORD_WIDTH - 1 : 0]       loc2m   [T2_NUM];
    wire [CODE_WIDTH - 1 : 0]       data_shift;
    wire [WORD_WIDTH*N_NUM - 1 : 0] degree;
    genvar ii;
    //----------------------------------------------------------------------//
    // assigns                                                              //
    //----------------------------------------------------------------------//
    generate
        for (ii = 0; ii < T2_NUM; ii++)
            begin
                // assign syn2m[ii] = shift_l[1*WORD_WIDTH - 1 : 0*WORD_WIDTH];
                assign syn2m[T2_NUM - 1 - ii] = data_s >> WORD_WIDTH*ii;
                assign loc2m[T2_NUM - 1 - ii] = data_l >> WORD_WIDTH*ii;
            end
    endgenerate
    //----------------------------------------------------------------------//
    // Component instantiations                                             //
    //----------------------------------------------------------------------//
    generate
        begin
            for (ii = 0; ii < T2_NUM - 1; ii++)
                begin
                    if (ii == T2_NUM - 2)
                        begin
                            gf2_add
                            gf2_add_4
                            (
                                .data_a     (mult[ii + 1]),         // шина данных
                                .data_b     (mult[ii]),         // шина данных
                                .data_out   (sum[ii])        // шина результирующих данных
                            );
                        end
                    else
                        begin
                            gf2_add
                            gf2_add_3
                            (
                                .data_a     (sum[ii + 1]),         // шина данных
                                .data_b     (mult[ii]),         // шина данных
                                .data_out   (sum[ii])        // шина результирующих данных
                            );
                        end
                end
            for (ii = 0; ii < T2_NUM; ii++)
                begin
                    gf2_3mult
                    gf2_3mult_ii
                    (
                        .data_a     (syn2m[ii]),         // шина данных
                        .data_b     (shift_r[ii]),         // шина данных
                        .data_out   (mult[ii])
                    );
                end
        end
    endgenerate
    //----------------------------------------------------------------------//
    // logic                                                                //
    //----------------------------------------------------------------------//
    always @(posedge clk or negedge rst_n)
        begin
            if (~rst_n)
                begin
                    ready       <= 1'b0;
                    shift_l     <= {SHIFT_WIDTH{1'b0}};
                    en_reg      <= 1'b0;
                    count       <= {CNT_WIDTH{1'b0}};
                    for (int i = 0; i < T2_NUM; i++)
                        begin
                            gama[i]     <= {WORD_WIDTH{1'b0}};
                            shift_r[i]  <= {WORD_WIDTH{1'b0}};
                        end
                end
            else
                begin
                    if (~ready)
                        en_reg <= en;
                    if (~en_reg && en)
                        begin
                            shift_l <= data_l;
                            count   <= T2_NUM;
                            for (int i = 0; i < T2_NUM; i++)
                                begin
                                    gama[i]     <= {WORD_WIDTH{1'b0}};
                                    shift_r[i]  <= {WORD_WIDTH{1'b0}};
                                end
                        end
                    else if (en_reg)
                        begin
                            if (count != 0)
                                begin
                                    shift_l <= {shift_l[5*WORD_WIDTH - 1 : 0*WORD_WIDTH], {WORD_WIDTH{1'b0}}};
                                    count   <= count - 1'b1;
                                    shift_r[T2_NUM - 1] <= loc2m[count - 1];
                                    gama[0] <= sum[0];
                                    for (int i = 0; i < T2_NUM; i++)
                                        begin
                                            if (i != 0)
                                                shift_r[T2_NUM - 1 - i] <= shift_r[T2_NUM - i];
                                            gama[i+1] <= gama[i];
                                        end
                                end
                            else
                                ready   <= 1'b1;
                                if (~ready)
                                    begin
                                        gama[0] <= sum[0];
                                        for (int i = 0; i < T2_NUM; i++)
                                            begin
                                                gama[i+1] <= gama[i];
                                            end
                                    end
                        end
                end
        end

endmodule
