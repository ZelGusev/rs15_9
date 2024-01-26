`ifndef _GUARD_CLK_INTF_
    `define _GUARD_CLK_INTF_
   
interface ifclk#(parameter integer CLK_MHZ = 500);
    timeunit 1ns;
	timeprecision 1ns;
    //----------------------------------------------------------------------------//
    // internal parameter                                                         //
    //----------------------------------------------------------------------------//
    localparam PERIOD_CLK       = 1_000_000_000/(CLK_MHZ * 1_000_000);  // перевод в ns период одного колебания
    //----------------------------------------------------------------------------//
    // Declare Interface Signals                                                  //
    //----------------------------------------------------------------------------//
    bit clk;
    bit rst_n;
    //----------------------------------------------------------------------------//
    // Modports                                                                   //
    //----------------------------------------------------------------------------// 
    modport clk_mod(
        output  clk,
                rst_n
        );
    initial begin
        clk     = 1'b0;
        rst_n   = 1'b0;
    end
     
    always #(PERIOD_CLK/2) clk = ~clk;
endinterface : ifclk

`endif
