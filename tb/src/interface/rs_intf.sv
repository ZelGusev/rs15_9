`ifndef _GUARD_ST_INTF_
    `define _GUARD_ST_INTF_
   
interface ifrs #(
    parameter integer DATA_WIDTH        = 36,
    parameter integer CODE_WIDTH        = 60
    );
    //----------------------------------------------------------------------------//
    // Declare Interface Signals                                                  //
    //----------------------------------------------------------------------------//
    logic                               en;
    logic [DATA_WIDTH - 1 : 0]          datain;

    logic                               busy;
    logic                               rdy;
    logic [CODE_WIDTH - 1 : 0]          dataout;

    //----------------------------------------------------------------------------//
    // Clocking Blocks                                                            //
    //----------------------------------------------------------------------------//   

    //----------------------------------------------------------------------------//
    // Modports                                                                   //
    //----------------------------------------------------------------------------// 

    modport master
    (
        input   en,
                datain,
        output  busy,
                rdy,
                dataout
    );

endinterface : ifrs

interface decode_if();
    //----------------------------------------------------------------------------//
    // Declare Interface Signals                                                  //
    //----------------------------------------------------------------------------//


    logic                   syn_rdy;
    logic [4 - 1 : 0]       syndrom [6];

    logic                   bkm_rdy;
    logic [4 - 1 : 0]       bkm_poly [6];

    logic                   chein_rdy;
    logic [4 - 1 : 0]       locator [15];
    

endinterface : decode_if


`endif