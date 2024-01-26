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

module forney(
    clk,
    rst_n,
    en,
    num_err,
    roots,
    data_g,
    data_l,
    ready,
    err_value
    );

    //----------------------------------------------------------------------//
    // external parameters                                                  //
    //----------------------------------------------------------------------//
    localparam WORD_WIDTH           = 4;
    localparam K_NUM                = 9;
    localparam N_NUM                = 15;
    localparam T_NUM                = (N_NUM - K_NUM)/2;
    localparam T2_NUM               = (N_NUM - K_NUM);
    localparam SHIFT_WIDTH          = T2_NUM * WORD_WIDTH;
    localparam DATA_WIDTH           = K_NUM * WORD_WIDTH;
    localparam ROOT_WIDTH           = T_NUM * WORD_WIDTH;
    localparam CNT_WIDTH            = WORD_WIDTH;

    //----------------------------------------------------------------------//
    // internal parameters                                                  //
    //----------------------------------------------------------------------//
    //----------------------------------------------------------------------//
    // external signals                                                     //
    //----------------------------------------------------------------------//
    input                           clk;
    input                           rst_n;
    input                           en;
    input [WORD_WIDTH - 1 : 0]      num_err;
    input [WORD_WIDTH - 1 : 0]      roots [T_NUM];
    input [WORD_WIDTH - 1 : 0]      data_g[T2_NUM];
    input [WORD_WIDTH - 1 : 0]      data_l[T2_NUM];
    output  reg                     ready;
    output [WORD_WIDTH - 1 : 0]     err_value[T_NUM];
    //----------------------------------------------------------------------//
    // registers                                                            //
    //----------------------------------------------------------------------//
    // вычисление полинома ошибок
    reg [CNT_WIDTH - 1 : 0]         count;
    reg                             en_reg;
    
    reg [WORD_WIDTH - 1 : 0]      sum_lam_r;
    // вычисление полинома синдрома умноженного на полином ошибок
    
    // new
    wire [WORD_WIDTH - 1 : 0]   data_l_w [T2_NUM];

    reg [WORD_WIDTH - 1 : 0]      root_deg[T_NUM][T2_NUM];
    wire [WORD_WIDTH - 1 : 0]     root_n[T_NUM];
    wire [WORD_WIDTH - 1 : 0]     root_deg_w[T_NUM][T2_NUM];
    wire [WORD_WIDTH - 1 : 0]     root_mult_root_n_w[T_NUM][T2_NUM];
    reg [WORD_WIDTH - 1 : 0]      gama_r[T2_NUM];
    wire [WORD_WIDTH - 1 : 0]   mult_g_w[T_NUM][T2_NUM];
    wire [WORD_WIDTH - 1 : 0]   sum_g_w[T_NUM][T2_NUM-1];

    reg [WORD_WIDTH - 1 : 0]      lam_r[T_NUM];
    wire [WORD_WIDTH - 1 : 0]   mult_l_w[T_NUM][T_NUM];
    wire [WORD_WIDTH - 1 : 0]   sum_l_w[T_NUM][T_NUM-1];

    wire [WORD_WIDTH - 1 : 0]   mult_root_w[T_NUM];
    wire [WORD_WIDTH - 1 : 0]   err_value_w[T_NUM];
    wire [WORD_WIDTH - 1 : 0]   lam_n_w[T_NUM];

    localparam FSM_SIZE = 4; //размер регистра состояний
    localparam [FSM_SIZE - 1 : 0]  
                   IDLE         = 0,     //
                   RUN          = 1;     //
    reg [FSM_SIZE - 1 : 0] state;
    //----------------------------------------------------------------------//
    // wire                                                                 //
    //----------------------------------------------------------------------//
    genvar ii;
    genvar nn;
    //----------------------------------------------------------------------//
    // assigns                                                              //
    //----------------------------------------------------------------------//
    assign err_value = err_value_w;
    generate
        for (ii = 0; ii < T2_NUM; ii++)
            begin
                if (ii%2 == 1)
                    assign data_l_w[ii] = {WORD_WIDTH{1'b0}}; 
                else
                    assign data_l_w[ii] = data_l[ii+1];
            end
    endgenerate
    //----------------------------------------------------------------------//
    // Component instantiations                                             //
    //----------------------------------------------------------------------//
    generate
        begin
            // инвентирование корня значение степени локатора 
            for (ii = 0; ii < T_NUM; ii++)
                begin
                    gf2_3_inv
                    gf2_3_inv_root_ii
                    (   // смещение так как в младшем бите всегда единица 
                        .data_i     (roots[ii]),         // шина данных
                        .data_out   (root_n[ii])        // шина результирующих данных
                    );
                end
            // вычисление степеней корней
            for (ii = 0; ii < T_NUM; ii++)
                begin
                    assign root_deg_w[ii][0] = roots[ii];
                    gf2_3mult
                    gf2_3mult_deg_ii_0
                    (
                        .data_a     (root_deg_w[ii][0]),         // шина данных
                        .data_b     (root_deg_w[ii][0]),         // шина данных
                        .data_out   (root_deg_w[ii][1])
                    );
                    for (nn = 0; nn < T2_NUM-2; nn++)
                        begin
                            gf2_3mult
                            gf2_3mult_deg_ii_nn
                            (
                                .data_a     (root_deg_w[ii][0]),         // шина данных
                                .data_b     (root_deg_w[ii][nn+1]),         // шина данных
                                .data_out   (root_deg_w[ii][nn+2])
                            );
                        end
                end
            // умножение числителя на инвентированный корень значение локатора 
            for (ii = 0; ii < T_NUM; ii++)
                begin
                    for (nn = 0; nn < T2_NUM-2; nn++)
                        begin
                            gf2_3mult
                            gf2_3mult_deg_root_n_ii_nn
                            (
                                .data_a     (root_deg_w[ii][nn]),         // шина данных
                                .data_b     (root_n[ii]),         // шина данных
                                .data_out   (root_mult_root_n_w[ii][nn])
                            );
                        end
                end
            for (ii = 0; ii < T2_NUM; ii++)
                begin
                    for (nn = 0; nn < T_NUM; nn++)
                        begin
                            gf2_3mult
                            gf2_3mult_gama_ii_nn
                            (
                                .data_a     (gama_r[ii]),         // шина данных
                                .data_b     (root_mult_root_n_w[nn][ii]),         // шина данных
                                .data_out   (mult_g_w[nn][ii])
                            );
                        end
                end

            for (ii = 0; ii < T_NUM - 1; ii++)
                begin
                    for (nn = 0; nn < T_NUM; nn++)
                        begin
                            assign mult_l_w [nn][ii] = lam_r[ii];
                            gf2_3mult
                            gf2_3mult_lam_ii_nn
                            (
                                .data_a     (lam_r[ii+1]),         // шина данных
                                .data_b     (root_deg_w[nn][ii]),         // шина данных
                                .data_out   (mult_l_w[nn][ii+1])
                            );
                        end
                end

            for (ii = 0; ii < T_NUM; ii++)
                begin
                    gf2_add
                    gf2_add_g_ii_nn
                    (
                        .data_a     (mult_g_w[ii][0]),         // шина данных
                        .data_b     (mult_g_w[ii][1]),         // шина данных
                        .data_out   (sum_g_w[ii][0])        // шина результирующих данных
                    );
                    for (nn = 0; nn < T2_NUM-2; nn++)
                        begin
                            gf2_add
                            gf2_add_g_ii_nn
                            (
                                .data_a     (mult_g_w[ii][nn+2]),         // шина данных
                                .data_b     (sum_g_w[ii][nn]),         // шина данных
                                .data_out   (sum_g_w[ii][nn+1])        // шина результирующих данных
                            );
                        end
                end
            for (ii = 0; ii < T_NUM; ii++)
                begin
                    gf2_add
                    gf2_add_l_ii_nn
                    (
                        .data_a     (mult_l_w[ii][0]),         // шина данных
                        .data_b     (mult_l_w[ii][1]),         // шина данных
                        .data_out   (sum_l_w[ii][0])        // шина результирующих данных
                    );
                    for (nn = 0; nn < T_NUM-2; nn++)
                        begin
                            gf2_add
                            gf2_add_l_ii_nn
                            (
                                .data_a     (mult_l_w[ii][nn+2]),         // шина данных
                                .data_b     (sum_l_w[ii][nn]),         // шина данных
                                .data_out   (sum_l_w[ii][nn+1])        // шина результирующих данных
                            );
                        end
                end
            for (ii = 0; ii < T_NUM; ii++)
                begin
                    // gf2_3mult
                    // gf2_3mult_root_ii
                    // (
                    //     .data_a     (sum_g_w[ii][T2_NUM-2]),         // шина данных
                    //     .data_b     (roots[ii]),         // шина данных
                    //     .data_out   (mult_root_w[ii])
                    // );

                    gf2_3_inv
                    gf2_3_inv_root_ii
                    (   // смещение так как в младшем бите всегда единица 
                        .data_i     (sum_l_w[ii][T_NUM-2]),         // шина данных
                        .data_out   (lam_n_w[ii])        // шина результирующих данных
                    );

                    gf2_3mult
                    gf2_3mult_err_value_ii
                    (
                        .data_a     (sum_g_w[ii][T2_NUM-2]),         // шина данных
                        .data_b     (lam_n_w[ii]),         // шина данных
                        .data_out   (err_value_w[ii])
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
                    state       <= IDLE;
                    ready       <= 1'b0;
                    en_reg      <= 1'b0;
                    count       <= {CNT_WIDTH{1'b0}};
                    sum_lam_r   <= {WORD_WIDTH{1'b0}};
                    for (int i = 0; i < T_NUM; i++)
                        begin
                            lam_r[i] <= {WORD_WIDTH{1'b0}};
                        end
                    for (int i = 0; i < T2_NUM; i++)
                        begin
                            gama_r[i] <= {WORD_WIDTH{1'b0}};
                        end
                    for (int i = 0; i < T_NUM; i++)
                        begin
                            for (int j = 0; j < T2_NUM; j++)
                                begin
                                    root_deg[i][j]  <= {WORD_WIDTH{1'b0}};
                                end
                        end
                    
                end
            else
                begin
                    case (state)
                        IDLE:
                            begin
                                en_reg <= en;
                                if (~en_reg && en)
                                    begin
                                        ready <= 1'b0;
                                        state <= RUN;
                                        gama_r <= data_g;
                                        for (int i = 0; i < T_NUM; i++)
                                            lam_r[i]   <= data_l_w[i];
                                    end
                            end
                        RUN:
                            begin
                                ready <= 1'b1;
                                state <= IDLE;
                                // if (count < N_NUM - 1)
                                //     begin
                                //         count   <= count + 1'b1;
                                //     end
                                // else
                                //     begin
                                //         count <= 0;
                                //         ready <= 1'b1;
                                //         state <= IDLE;
                                //     end
                            end
                        default:;
                    endcase
                end
        end

endmodule
