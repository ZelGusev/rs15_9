/*************************************************************************************************************
--    Система        : 
--    Разработчик    :
--    Автор          : Гусев Игорь
--
--    Назначение     : Класс монитора (monitor) интерфейса rs
-—                     
--------------------------------------------------------------------------------------------------------------
--    Примечание     : 
*************************************************************************************************************/
`ifndef _GUARD_RS_MONITOR_
    `define _GUARD_RS_MONITOR_

    import parameter_pkg::*;
class Rs_monitor extends uvm_monitor;
    localparam POLY_GEN = 28'b0001_0111_1001_0011_1100_1010_1100;
    localparam FIELD_GEN = 4'b0011;
    // Virtual Interface
    virtual ifclk#(     .CLK_MHZ    (RS_CLK_MHZ))      clk_gen;
    virtual ifrs#(  .DATA_WIDTH (DATA_WIDTH), .CODE_WIDTH (CODE_WIDTH)   )      rs_wr_if;
    virtual ifrs#(  .DATA_WIDTH (DATA_WIDTH), .CODE_WIDTH (CODE_WIDTH)   )      rs_bkm_if;
    virtual ifrs#(  .DATA_WIDTH (CODE_WIDTH), .CODE_WIDTH (CODE_WIDTH)   )      rs_rdbkm_if;
   
    virtual decode_if dec_if;
    // UVM Factory registration macros
    uvm_analysis_port #(Rs_seq_item)  wr_data_stream;
    uvm_analysis_port #(Rs_seq_item)  rd_data_stream;
    
    // item
    Rs_seq_item    rs_seq;
    `uvm_component_utils(Rs_monitor)
 
    //----------------------------------------------------------------------//
    // Create                                                               //
    //----------------------------------------------------------------------//
    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new
  
    //----------------------------------------------------------------------//
    // Build Phase                                                          //
    //----------------------------------------------------------------------//
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db #(virtual ifclk   #(  .CLK_MHZ    (RS_CLK_MHZ)))::get(this, "*", "clk_gen", clk_gen))
            `uvm_fatal("NOVIF",{"virtual interface must be set for: ",get_full_name(),".clk_gen"});
        if(!uvm_config_db #(virtual ifrs#(  .DATA_WIDTH (DATA_WIDTH), .CODE_WIDTH (CODE_WIDTH)))::get(this, "*", "rs_wr_if", rs_wr_if))
            `uvm_fatal("NOVIF",{"virtual interface must be set for: ",get_full_name(),".rs_wr_if"});
        if(!uvm_config_db #(virtual ifrs#(  .DATA_WIDTH (DATA_WIDTH), .CODE_WIDTH (CODE_WIDTH)))::get(this, "*", "rs_bkm_if", rs_bkm_if))
            `uvm_fatal("NOVIF",{"virtual interface must be set for: ",get_full_name(),".rs_bkm_if"});
        if(!uvm_config_db #(virtual ifrs#(  .DATA_WIDTH (CODE_WIDTH), .CODE_WIDTH (CODE_WIDTH)))::get(this, "*", "rs_rdbkm_if", rs_rdbkm_if))
            `uvm_fatal("NOVIF",{"virtual interface must be set for: ",get_full_name(),".rs_rdbkm_if"});

        if(!uvm_config_db #(virtual decode_if)::get(this, "*", "dec_if", dec_if))
            `uvm_fatal("NOVIF",{"virtual interface must be set for: ",get_full_name(),".dec_if"});
        // creating port
        // analysis port
        wr_data_stream      = new("wr_data_stream", this);
        rd_data_stream      = new("rd_data_stream", this);
        // item
        rs_seq    = Rs_seq_item::type_id::create("rs_seq");
    endfunction: build_phase
    function void field_gen;
        input [4 - 1 : 0] poly_gen;
        output [4 - 1 : 0] field [15];
        reg  [4 - 1 : 0] tmp [15];
        begin
            for (int i = 0; i < 15; i++)
                tmp[i] = '0;
            for (int i = 0; i < 15; i++)
                begin
                    if (i == 0)
                        tmp[i] = 1;
                    else 
                        begin
                            if (tmp[i-1][3] == 1)
                                begin
                                    tmp[i] = tmp[i-1]<<1;
                                    tmp[i] = tmp[i]^poly_gen;
                                end
                            else
                                begin
                                    tmp[i] = tmp[i-1]<<1;
                                    // $display ("tmp = %b", tmp[i]);
                                end
                        end
                end
            field = tmp;
            // $display ("FIELD = %p", field);
        end
    endfunction : field_gen
    function void wire2arr;
        input [15*4 - 1 : 0] data;
        output [4-1:0] data_out [15];
        reg  [15*4 - 1 : 0] tmp_data;
        begin
            tmp_data = data;
            for (int i = 0; i < 15; i++)
                begin
                    data_out[i] = tmp_data[4-1:0];
                    tmp_data>>=4;
                end
        end
    endfunction : wire2arr
    function void wire2arr_poly;
        input [7*4 - 1 : 0] data;
        output [4-1:0] data_out [7];
        reg  [7*4 - 1 : 0] tmp_data;
        begin
            tmp_data = data;
            for (int i = 0; i < 7; i++)
                begin
                    data_out[i] = tmp_data[4-1:0];
                    tmp_data>>=4;
                end
        end
    endfunction : wire2arr_poly
    function integer index_chk;
        input integer data;
        integer tmp;
        begin
            if (data < 0)
                tmp = data + 15;
            else
                tmp = data;
            index_chk = tmp;
            // $display("index_chk = %d, %d, %d", data, tmp, index_chk);
        end
    endfunction : index_chk
    function integer mult_idex;
        input integer data;
        integer tmp;
        begin
            if (data >= 15)
                tmp = data%15;
            else
                tmp = data;
            mult_idex = tmp;
        end
    endfunction : mult_idex
    function integer find_index_p;
        input [4 - 1 : 0] field [15];
        input [4 - 1 : 0] poly_arr;
        integer tmp;
        begin
            if (poly_arr != 0)
                begin
                    for (int i = 0; i < 15; i++)
                        begin
                            if (poly_arr == field [i])
                                tmp = i;
                        end
                end
            else
                tmp = -1;
            find_index_p = tmp;
        end
    endfunction : find_index_p
    function void encodebkm_rs;
        input [9*4 - 1 : 0] data;
        input [7*4 - 1 : 0] poly;
        output [15*4 - 1 : 0] code;
        output [6*4 - 1 : 0] chk_bits;
        reg [15*4 - 1 : 0] data_code;
        reg [4 - 1 : 0] data_arr [15];
        reg [4 - 1 : 0] poly_arr [7];
        integer index_data_arr [15];
        integer index_poly_arr [7];
        integer tmp_idex_poly_arr [7];
        reg [4 - 1 : 0] field [15];
        integer sum;
        integer index_p;
        integer tmp_index;
        begin
            field_gen(FIELD_GEN, field);
            // $display("INPUT FUNC DATA = %h", data);
            data_code = revers_byte_input_data(data);
            // $display("REVERS FUNC DATA = %h", data_code);
            data_code<<=6*4;
            wire2arr(data_code, data_arr);
            // $display("data_arr = %p", data_arr);
            wire2arr_poly(poly, poly_arr);
            index_p = find_index_p(field, poly_arr[6]);
            for (int i = 0; i < 7; i++)
                begin
                    index_poly_arr[i] = find_index_p(field, poly_arr[i]);
                end
            // $display("index_poly_arr = %p", index_poly_arr);
            for (int i = 0; i < 15; i++)
                begin
                    index_data_arr[i] = find_index_p(field, data_arr[i]);
                end
            // $display("index_data_arr = %p", index_data_arr);
            for (int i = 14; i > 5; i--)
                begin
                    // $display("iteration = %d", i);
                    if (data_arr[i] != 0)
                        begin
                            // $display("data_arr[i] = %h", data_arr[i]);
                            // $display("index_data_arr[i] = %d", index_data_arr[i]);
                            // $display("index_p = %d", index_p);
                            tmp_index = index_chk(index_data_arr[i] - index_p);
                            // $display("tmp_index = %d", tmp_index);
                            for (int j = 0; j < 7; j++)
                                begin
                                    // sum = index_poly_arr + tmp_index;
                                    tmp_idex_poly_arr[j] = mult_idex(index_poly_arr[j] + tmp_index);
                                    // $display("tmp_idex_poly_arr[%d] = %d", j, tmp_idex_poly_arr[j]);
                                end
                            // $display("tmp_idex_poly_arr = %p", tmp_idex_poly_arr);
                            for (int j = 0; j < 7; j++)
                                begin
                                    data_arr[i - 6 + j] = data_arr[i - 6 + j] ^ field[tmp_idex_poly_arr[j]];
                                    // $display("data_arr[%d] = %b", i - 6 + j, data_arr[i - 6 + j]);
                                end
                            for (int i = 0; i < 15; i++)
                                begin
                                    index_data_arr[i] = find_index_p(field, data_arr[i]);
                                end
                        end
                end
            // $display("data_arr = %p", data_arr);
            for (int i = 0; i < 6; i++)
                begin
                    chk_bits>>=4;
                    // if (data_arr[i] != 0)
                        chk_bits[6*4-1:5*4] = data_arr[i];
                    // else
                    //     chk_bits[6*4-1:6*3] = 1;
                    // $display("chk_bits = %h", chk_bits);
                end
            chk_bits = revers_byte_chk(chk_bits);
            code = {chk_bits,data};
            // code = revers_byte_data(code);
            // $display("BKM OUTPUT ENCODER FUNC = %h", code);
        end
    endfunction : encodebkm_rs
    function void encode_rs;
        input [9*4 - 1 : 0] data;
        input [7*4 - 1 : 0] poly;
        output [15*4 - 1 : 0] code;
        output [6*4 - 1 : 0] chk_bits;
        reg [15*4 - 1 : 0] data_code;
        reg [4 - 1 : 0] data_arr [15];
        reg [4 - 1 : 0] poly_arr [7];
        integer index_data_arr [15];
        integer index_poly_arr [7];
        integer tmp_idex_poly_arr [7];
        reg [4 - 1 : 0] field [15];
        integer sum;
        integer index_p;
        integer tmp_index;
        begin
            field_gen(FIELD_GEN, field);
            data_code = data;
            data_code<<=6*4;
            wire2arr(data_code, data_arr);
            // $display("data_arr = %p", data_arr);
            wire2arr_poly(poly, poly_arr);
            index_p = find_index_p(field, poly_arr[6]);
            for (int i = 0; i < 7; i++)
                begin
                    index_poly_arr[i] = find_index_p(field, poly_arr[i]);
                end
            // $display("index_poly_arr = %p", index_poly_arr);
            for (int i = 0; i < 15; i++)
                begin
                    index_data_arr[i] = find_index_p(field, data_arr[i]);
                end
            // $display("index_data_arr = %p", index_data_arr);
            for (int i = 14; i > 5; i--)
                begin
                    // $display("iteration = %d", i);
                    if (data_arr[i] != 0)
                        begin
                            // $display("data_arr[i] = %h", data_arr[i]);
                            // $display("index_data_arr[i] = %d", index_data_arr[i]);
                            // $display("index_p = %d", index_p);
                            tmp_index = index_chk(index_data_arr[i] - index_p);
                            // $display("tmp_index = %d", tmp_index);
                            for (int j = 0; j < 7; j++)
                                begin
                                    // sum = index_poly_arr + tmp_index;
                                    tmp_idex_poly_arr[j] = mult_idex(index_poly_arr[j] + tmp_index);
                                    // $display("tmp_idex_poly_arr[%d] = %d", j, tmp_idex_poly_arr[j]);
                                end
                            // $display("tmp_idex_poly_arr = %p", tmp_idex_poly_arr);
                            for (int j = 0; j < 7; j++)
                                begin
                                    data_arr[i - 6 + j] = data_arr[i - 6 + j] ^ field[tmp_idex_poly_arr[j]];
                                    // $display("data_arr[%d] = %b", i - 6 + j, data_arr[i - 6 + j]);
                                end
                            for (int i = 0; i < 15; i++)
                                begin
                                    index_data_arr[i] = find_index_p(field, data_arr[i]);
                                end
                        end
                end
            // $display("data_arr = %p", data_arr);
            for (int i = 0; i < 6; i++)
                begin
                    chk_bits>>=4;
                    // if (data_arr[i] != 0)
                        chk_bits[6*4-1:5*4] = data_arr[i];
                    // else
                    //     chk_bits[6*4-1:6*3] = 1;
                    // $display("chk_bits = %h", chk_bits);
                end
            code = {data,chk_bits};
        end
    endfunction : encode_rs
    function [15 * 4 - 1 : 0] revers_byte_data;
        input [15 * 4 - 1 : 0]  data;
        bit  [15 * 4 - 1 : 0]   data_o;
            begin
                for (int i = 0; i < 15; i++)
                    begin
                        data_o>>=4;
                        data_o[15*4 - 1 : 14*4] = data[15*4 - 1 : 14*4];
                        data<<=4;
                        // $display("data = %h", data);
                        // $display("data_o = %h", data_o);
                    end
            end
        revers_byte_data = data_o;
    endfunction : revers_byte_data
    function [9 * 4 - 1 : 0] revers_byte_input_data;
        input [9 * 4 - 1 : 0]  data;
        bit  [9 * 4 - 1 : 0]   data_o;
            begin
                for (int i = 0; i < 9; i++)
                    begin
                        data_o>>=4;
                        data_o[9*4 - 1 : 8*4] = data[9*4 - 1 : 8*4];
                        data<<=4;
                        // $display("data = %h", data);
                        // $display("data_o = %h", data_o);
                    end
            end
        revers_byte_input_data = data_o;
    endfunction : revers_byte_data
    function [6 * 4 - 1 : 0] revers_byte_chk;
        input [6 * 4 - 1 : 0]  data;
        bit  [6 * 4 - 1 : 0]   data_o;
            begin
                for (int i = 0; i < 6; i++)
                    begin
                        data_o>>=4;
                        data_o[6*4 - 1 : 5*4] = data[6*4 - 1 : 5*4];
                        data<<=4;
                        // $display("data = %h", data);
                        // $display("data_o = %h", data_o);
                    end
            end
        revers_byte_chk = data_o;
    endfunction : revers_byte_chk
    function void syn_cal;
        input [15*4 - 1 : 0] data;
        output [4-1:0] syndrom[6];
        reg [4 - 1 : 0] data_arr [15];
        integer index_data_arr [15];
        reg [4 - 1 : 0] field [15];
        reg [4-1:0] sum;
        integer idnex;
        begin
            sum = '0;
            wire2arr(data, data_arr);
            // $display("data_arr = %p", data_arr);
            field_gen(FIELD_GEN, field);
            for (int i = 0; i < 15; i++)
                begin
                    index_data_arr[i] = find_index_p(field, data_arr[i]);
                end
            // $display("index_data_arr = %p", index_data_arr);
            for (int i = 0; i < 6; i++)
                begin
                    // $display("----------------- START CALCULATE :: %d :: SYNDROME -----------------", i);
                    for (int j = 0; j < 15; j++)
                        begin
                            if (index_data_arr[j] != -1)
                                begin
                                    sum = sum ^ field[mult_idex((i+1)*j + index_data_arr[j])];
                                    // $display(" :: %d :: sum = %d", j, mult_idex((i+1)*j + index_data_arr[j]));
                                end
                            else
                                sum = sum ^ '0;
                        end
                    syndrom[i] = sum;
                    sum = '0;
                end
        end
    endfunction : syn_cal
    function [4-1:0] mult_gf;
        input [4-1:0] a;
        input [4-1:0] b;
        integer index_a;
        integer index_b;
        integer index_tmp;
        reg [4 - 1 : 0] field [15];
        begin
            if (a==0 || b ==0)
                mult_gf = 0;
            else
                begin
                    field_gen(FIELD_GEN, field);
                    index_a = find_index_p(field,a);
                    index_b = find_index_p(field,b);
                    // index_tmp = mult_idex(index_a+index_b);
                    mult_gf = field[mult_idex(index_a+index_b)];
                end
        end
    endfunction : mult_gf
    function [4-1:0] inv_gf;
        input [4-1:0] data;
        reg [4 - 1 : 0] field [15];
        begin
            field_gen(FIELD_GEN, field);
            if (data == 0)
                inv_gf = 0;
            else if (data == 1)
                inv_gf = field[0];
            else
                inv_gf = field[15 - find_index_p(field,data)];
        end
    endfunction : inv_gf
    function void bkm_cal;
        input [4-1:0] syndrom [6];
        output [4-1:0] bkm_poly [6];
        integer l[6];
        integer r;
        integer j;
        reg [4-1:0] gama [6];
        reg [4-1:0] alpha [6];
        reg [4-1:0] alpha_tmp [6];
        reg [4-1:0] dis;
        reg [4 - 1 : 0] field [15];
        begin
            // $display("syndrom = %p", syndrom);
            field_gen(FIELD_GEN, field);
            // первое заполнение
            r = 0;
            for(int i=0; i<6; i++)
                begin
                    if (i==0)
                        begin
                            gama[i] = 1;
                            alpha[i] = 1;
                            l[i] = 0;
                        end
                    else
                        begin
                            l[i] = 0;
                            gama[i] = 0;
                            alpha[i] = 0;
                        end
                end
            // второе
            //r++;
            for (r=1; r<7; r++)
                begin
                    dis = 0;
                    for(j=0; j<r; j++)
                        begin
                            // $display("alpha[%0d] = %h :: \t\t DEGREE = %0d", j, alpha[j], find_index_p(field,alpha[j]));
                            // $display("syndrom[%0d] = %h :: \t\t DEGREE = %0d", r-1-j, syndrom[r-1-j], find_index_p(field,syndrom[r-1-j]));
                            // $display("alpha[%0d] = %h", j, alpha[j]);
                            // $display("syndrom[%0d] = %h", r-1-j, syndrom[r-1-j]);
                            dis = dis ^ mult_gf(alpha[j],syndrom[r-1-j]);
                        end
                    // $display("index dis = %d :: dis = %0d", find_index_p(field, dis), dis);
                    if (dis != 0)
                        begin
                            for(j=0; j<6; j++)
                                begin
                                    alpha_tmp[j] = alpha[j];
                                    if (j==0)
                                        alpha[j] = alpha[j];
                                    else
                                        alpha[j] = alpha[j] ^ mult_gf(dis,gama[j-1]);
                                    // $display("alpha[%0d] = %d", j, alpha[j]);
                                    // $display("gama[%0d] = %d", j-1, gama[j-1]);
                                end
                            // $display("alpha = %p", alpha);
                            if (2*l[r-1]<=r-1)
                                begin
                                    l[r] = r - l[r-1];
                                    for(j=0; j<6; j++)
                                        begin
                                            // $display("LOOK AT inv_gf(dis) = %0d mult whit alpha_tmp = %0h", inv_gf(dis), alpha_tmp[j]);
                                            gama[j] = mult_gf(inv_gf(dis),alpha_tmp[j]);
                                            // $display("LOOK AT THIS gama[%0d] = %h", j, gama[j]);
                                        end
                                    // $display("gama = %p", gama);
                                end
                            else
                                begin
                                    l[r] = l[r-1];
                                    for(j=6; j>=0; j--)
                                        begin
                                            if (j==0)
                                                gama[j] = '0;
                                            else
                                                gama[j] = gama[j-1];
                                        end
                                    // $display("gama = %p", gama);
                                end
                        end
                    else
                        begin
                            l[r] = l[r-1];
                            for(j=6; j>=0; j--)
                                begin
                                    if (j==0)
                                        gama[j] = '0;
                                    else
                                        gama[j] = gama[j-1];
                                end
                            // $display("gama = %p", gama);
                        end
                end
            bkm_poly = alpha;
        end
    endfunction : bkm_cal
    function void chien_search;
        input [4-1:0] nod [6];
        output [4 - 1 : 0] chien_o [15];
        reg [4 - 1 : 0] field [15];
        reg [4 - 1 : 0] chien_arr [15];
        reg [4-1:0] equation [6];
        reg [4-1:0] root;
        begin
            field_gen(FIELD_GEN, field);
            foreach(chien_arr[i])
                chien_arr[i] = 0;
            equation = nod;
            for(int i = 0; i < 15; i++)
                begin
                    for(int j = 0; j < 6; j++)
                        begin
                            equation[j] = mult_gf(equation[j], field[j]);
                            chien_arr[i] = chien_arr[i] ^ equation[j];
                        end
                    // $display("chien_arr[%d]", i, chien_arr[i]);
                end
            // $display("chien_arr = %p", chien_arr);
            chien_o = chien_arr;
        end
    endfunction : chien_search
    function void mult_poly;
        input [4-1:0] syndrom [6];
        input [4-1:0] nod [6];
        output [4-1:0] mult_res [6];
        reg [4-1:0] mult_arr [12];
        begin
            foreach(mult_arr[i])
                mult_arr[i] = 0;
            for(int i = 0; i < 6; i++)
                begin
                    for(int j = 0; j < 6; j++)
                        begin
                            mult_arr[i+j] = mult_arr[i+j] ^ mult_gf(syndrom[j], nod[i]);
                        end
                end
            for(int i = 0; i < 6; i++)
                mult_res [i] = mult_arr[i];
            // $display("RESULT MULT POLY = %p", mult_res);
        end
    endfunction : mult_poly
    function void derivative_poly;
        input [4-1:0] data [6];
        output [4-1:0] dataout [6];
        reg  [4-1:0] temp [6];
        begin
            temp = data;
            for (int i = 0; i < 6; i++)
                begin
                    if (i%2==0)
                        temp[i] = '0;
                end
            for (int i = 0; i < 5; i++)
                begin
                    temp[i] = temp[i+1];
                end
            temp[5] = 0;
            dataout = temp;
        end
    endfunction : derivative_poly
    function void mult_on_root_poly;
        input [4-1:0] data [6];
        input  [4-1:0] root;
        output [4-1:0] mult[6];
        reg [4-1:0] temp[6];
        reg [4-1:0] degree;
        begin
            degree = root;
            for (int i = 0; i < 6; i++)
                begin
                    temp[i] = mult_gf(data[i], degree);
                    degree = mult_gf(degree, root);
                end
            mult = temp;
        end
    endfunction : mult_on_root_poly
    function void sum_arr_poly;
        input [4-1:0] data [6];
        output [4-1:0] sum;
        reg [4-1:0] sum_temp;
        begin
            sum_temp = 0;
            for (int i = 0; i < 6; i++)
                begin
                    sum_temp = sum_temp ^ data[i];
                end
            sum = sum_temp;
        end
    endfunction : sum_arr_poly
    function void forney_cal;
        input [4-1:0] rx_data [15];
        input [4-1:0] syndrom [6];
        input [4-1:0] nod [6];
        input [4-1:0] locator [15];
        output [4-1:0] fix_data [15];
        reg [4-1:0]     root_val [15];
        reg [4-1:0]     field [15];
        reg [4-1:0] gama[6];
        reg [4-1:0] sum_gama;
        reg [4-1:0] lamda[6];
        reg [4-1:0] sum_lamda;
        reg [4-1:0]     temp_mult_poly [6];
        reg [4-1:0]     derivative [6];
        integer cnt;
        integer num_root;
        begin
            fix_data = rx_data;
            cnt = 0;
            field_gen(FIELD_GEN, field);
            // $display("GF FIELD = %p", field);
            mult_poly(syndrom,nod,temp_mult_poly);
            // $display("GAMA POLY = %p", temp_mult_poly);
            derivative_poly(nod,derivative);
            // $display("DERIVATIVE = %p", derivative);
            // $display("TRUE CODE = %p", tx_data);
            // $display("TX CODE = %p", rx_data);
            foreach(root_val[i])
                root_val[i] = 0;
            for (int i = 0; i < 15; i++)
                begin
                    if (num_root+1>14)
                        num_root = (i + 1)%15;
                    else
                        num_root = i + 1;
                    if (locator[i] == 0)
                        begin
                            // $display("----------ROOT = %d-----------", num_root);
                            // $display("ROOT IS = %b", field[num_root]);
                            mult_on_root_poly(temp_mult_poly, field[num_root], gama);
                            // $display("GAMA POLY = %p", gama);
                            sum_arr_poly(gama, sum_gama);
                            // $display("SUM GAMA POLY = %b", sum_gama);
                            mult_on_root_poly(derivative, field[num_root], lamda);
                            // $display("LAMDA POLY = %p", lamda);
                            sum_arr_poly(lamda, sum_lamda);
                            // $display("SUM LAMDA POLY = %b", sum_lamda);
                            root_val[cnt] = mult_gf(inv_gf(field[num_root]), sum_gama);
                            root_val[cnt] = mult_gf(inv_gf(sum_lamda), sum_gama);
                            // $display("root_val[%0d] = %h", cnt, root_val[cnt]);
                            fix_data[i] = root_val[cnt] ^ fix_data[i];
                            cnt++;
                        end
                end
            // $display("TEST ROOT VALUE = %p", root_val);
        end
    endfunction : forney_cal
    //----------------------------------------------------------------------//
    // Run Phase                                                            //
    //----------------------------------------------------------------------//
    bit sens_wr;

    reg [4 - 1 : 0]         field [15];
    reg [6 * 4 - 1 : 0]     remainder;
    reg [4 - 1 : 0]         syndrom [6];
    reg [4 - 1 : 0]         bkm_poly [6];
    reg [4 - 1 : 0]         locator [15];
    reg [15 * 4 - 1 : 0]    code;
    reg [15 * 4 - 1 : 0]    bkmcode;
    reg [4 - 1 : 0]         code_arr [15];
    reg [15 * 4 - 1 : 0]    input_code;
    reg [4 - 1 : 0]         input_code_arr [15];
    reg [4 - 1 : 0]         fix_code_arr [15];
    reg [15 * 4 - 1 : 0]    temp_code;

    reg [4 - 1 : 0]         res_mult_poly [6];

    virtual task run_phase(uvm_phase phase);
        fork
            // ------------------> //// отслеживание сигналов rtl блока итоговый результат работы модуля
            forever begin
                @(rs_wr_if.en);
                    if (clk_gen.rst_n)
                        begin
                            // #3;
                            //$display(" WRITE TRANSACTION %t", $time);
                            rs_seq.data     = rs_wr_if.datain;
                            wr_data_stream.write(rs_seq);
                            // #3;
                            // rd_data_stream.write(rs_seq);
                        end
            end
            begin
                 field_gen(FIELD_GEN, field);
            end
            begin
                // проверка работы кодера
                wait (rs_wr_if.en);
                encode_rs(rs_wr_if.datain, POLY_GEN, code, remainder);
                // $display ("TEST ENCODE DATA = %h", code);
                // $display ("TEST ENCODE CHEACK BITS = %h", remainder);
                wait (rs_wr_if.rdy);
                // $display ("DATA FROM ENCODER = %h", rs_wr_if.dataout);
                if (code != rs_wr_if.dataout)
                    uvm_report_error(get_full_name(),"ENCODE DATA ERROR \n\n",UVM_LOW);
                else
                    uvm_report_info(get_full_name(),"ENCODE DATA DONE \n\n",UVM_LOW);
                // $display ("REM = %h", remainder);
            end
            begin
                // проверка работы кодера
                wait (rs_bkm_if.en);
                $display ("INPUT ENCODE DATA = %h", rs_bkm_if.datain);
                encodebkm_rs(rs_bkm_if.datain, POLY_GEN, bkmcode, remainder);
                $display ("BKM TEST ENCODE DATA = %h", bkmcode);
                $display ("BKM TEST ENCODE CHEACK BITS = %h", remainder);
                wait (rs_bkm_if.rdy);
                $display ("DATA FROM ENCODER = %h", rs_bkm_if.dataout);
                if (bkmcode != rs_bkm_if.dataout)
                    uvm_report_error(get_full_name(),"BKM ENCODE DATA ERROR \n\n",UVM_LOW);
                else
                    uvm_report_info(get_full_name(),"BKM ENCODE DATA DONE \n\n",UVM_LOW);
                // $display ("REM = %h", remainder);
            end
            
            begin
                // проверка работы вычисления синдрома
                wait (rs_rdbkm_if.en);
                input_code = rs_rdbkm_if.datain;
                // перевод данных в формат unpacked array для удобства работы 
                $display ("TEST ENCODE DATA = %h", bkmcode);
                wire2arr(bkmcode, code_arr);
                $display("TRUE CODE = %p", code_arr);
                $display ("RX INPUT DECODER DATA = %h", input_code);
                wire2arr(input_code, input_code_arr);
                $display("RX CODE = %p", input_code_arr);

                syn_cal(revers_byte_data(rs_rdbkm_if.datain), syndrom);
                $display ("TEST DECODE SYNDROME = %p", syndrom);
                wait (dec_if.syn_rdy);
                if (syndrom != dec_if.syndrom)
                    uvm_report_error(get_full_name(),"SYNDROM CALCULATE ERROR \n\n",UVM_LOW);
                else
                    uvm_report_info(get_full_name(),"SYNDROM CALCULATE DONE \n\n",UVM_LOW);
                bkm_cal(syndrom, bkm_poly);
                wait(dec_if.bkm_rdy);
                $display("RTL BKM POLY = %p", dec_if.bkm_poly);
                $display("TEST BKM POLY = %p", bkm_poly);
                chien_search(bkm_poly, locator);
            end
            begin
                // проверка локатров ошибок
                wait (dec_if.chein_rdy);
                $display("RTL LOCATOR = %p", dec_if.locator);
                $display("TEST LOCATOR = %p", locator);
                if (locator != dec_if.locator)
                    uvm_report_error(get_full_name(),"LOCATOR CALCULATE ERROR \n\n",UVM_LOW);
                else
                    uvm_report_info(get_full_name(),"LOCATOR CALCULATE DONE \n\n",UVM_LOW);
                forney_cal(input_code_arr, syndrom, bkm_poly, locator, fix_code_arr);
                $display("CORAPTED DATA = \t\t %p", input_code_arr);
                $display("FIXED DATA = \t\t\t %p", fix_code_arr);
                $display("TEST OUPUT ENCODE DATA = \t %p", code_arr);
                wait (rs_rdbkm_if.rdy);
                $display ("RTL CORRECT DATA = %h", rs_rdbkm_if.dataout);
                if (bkmcode != rs_rdbkm_if.dataout)
                    uvm_report_error(get_full_name(),"OUTPUT CORRECT DATA ERROR \n\n",UVM_LOW);
                else
                    uvm_report_info(get_full_name(),"OUTPUT CORRECT DATA  DONE \n\n",UVM_LOW);

            end
            //////////////////////////////////////////////////////////////////////////////////// <------------------
        join_any
    endtask : run_phase
    
endclass : 	Rs_monitor

`endif