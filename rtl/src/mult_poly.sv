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

module mult_poly(
    clk,
    rst_n,
    en,
    poly_0,
    poly_1,
    ready,
    poly_o
    );

    //----------------------------------------------------------------------//
    // external parameters                                                  //
    //----------------------------------------------------------------------//
    parameter WORD_WIDTH           = 4;
    parameter N_NUM                = 6;
    //----------------------------------------------------------------------//
    // internal parameters                                                  //
    //----------------------------------------------------------------------//
    localparam CNT_WIDTH            = WORD_WIDTH;
    //----------------------------------------------------------------------//
    // external signals                                                     //
    //----------------------------------------------------------------------//
    input                           clk;
    input                           rst_n;
    input                           en;
    input [WORD_WIDTH - 1 : 0]      poly_0 [N_NUM];
    input [WORD_WIDTH - 1 : 0]      poly_1 [N_NUM];
    output  reg                     ready;
    output reg [WORD_WIDTH - 1 : 0] poly_o [N_NUM];
    //----------------------------------------------------------------------//
    // registers                                                            //
    //----------------------------------------------------------------------//
    reg                             en_reg;
    reg [WORD_WIDTH - 1 : 0]        shift_r [N_NUM];
    reg [CNT_WIDTH - 1 : 0]         count;
    localparam FSM_SIZE = 4; //размер регистра состояний
    localparam [FSM_SIZE - 1 : 0]  
                   IDLE         = 0,     //
                   RUN          = 1;     //
    reg [FSM_SIZE - 1 : 0] state;
    //----------------------------------------------------------------------//
    // wire                                                                 //
    //----------------------------------------------------------------------//
    wire [WORD_WIDTH - 1 : 0]       mult    [N_NUM];
    wire [WORD_WIDTH - 1 : 0]       sum     [N_NUM - 1];
    genvar ii;
    //----------------------------------------------------------------------//
    // assigns                                                              //
    //----------------------------------------------------------------------//
    //----------------------------------------------------------------------//
    // Component instantiations                                             //
    //----------------------------------------------------------------------//
    gf2_add
    gf2_add_0
    (
        .data_a     (mult[0]),         // шина данных
        .data_b     (mult[1]),         // шина данных
        .data_out   (sum[0])        // шина результирующих данных
    );
    generate
        begin
            for (ii = 0; ii < N_NUM - 2; ii++)
                begin
                    gf2_add
                    gf2_add_ii
                    (
                        .data_a     (sum[ii]),         // шина данных
                        .data_b     (mult[ii + 2]),         // шина данных
                        .data_out   (sum[ii + 1])        // шина результирующих данных
                    );
                end
            for (ii = 0; ii < N_NUM; ii++)
                begin
                    gf2_3mult
                    gf2_3mult_ii
                    (
                        .data_a     (poly_0[ii]),         // шина данных
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
                    state       <= IDLE;
                    ready       <= 1'b0;
                    en_reg      <= 1'b0;
                    count       <= {CNT_WIDTH{1'b0}};
                    for (int i = 0; i < N_NUM; i++)
                        begin
                            poly_o[i]   <= {WORD_WIDTH{1'b0}};
                            shift_r[i]  <= {WORD_WIDTH{1'b0}};
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
                                        state <= RUN;
                                        count   <= N_NUM;
                                        for (int i = 0; i < N_NUM; i++)
                                            begin
                                                poly_o[i]   <= {WORD_WIDTH{1'b0}};
                                                shift_r[i]  <= {WORD_WIDTH{1'b0}};
                                            end
                                    end
                            end
                        RUN:
                    // else if (en_reg)
                            begin
                                if (count != 0)
                                    begin
                                        count       <= count - 1'b1;
                                        shift_r[0]  <= poly_1[N_NUM - count];
                                        poly_o[N_NUM - 1 - count]   <= sum[N_NUM - 2];
                                        for (int i = 0; i < N_NUM; i++)
                                            begin
                                                if (i != N_NUM - 1)
                                                    shift_r[i + 1] <= shift_r[i];
                                                //poly_o[i+1] <= poly_o[i];
                                            end
                                    end
                                else
                                    begin
                                        state <= IDLE;
                                        ready   <= 1'b1;
                                        poly_o[N_NUM - 1]   <= sum[N_NUM - 2];
                                    end
                            end
                        default:;
                    endcase
                end
        end

endmodule
