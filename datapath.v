//In lab6 the changes that are needed to be made to datapath are as follows:
//  1. component9 needs to be altered
//  2. Input to component7 needs to be changed
//  3. Change component10 to include 3-bits instead of 1
//       One bit should represent a “zero flag”, which was what
//        “status” represented in Lab 5. Another bit should represent a
//        “negative flag” and be set to 1’b1 if the most
//            significant bit of the main 16-bit ALU result is 1.
//        The final bit represents an overflow flag.


                      //inputs to datapath MUX
module datapath(mdata,  //mdata is the 16-bit output of a memory block (Lab 7)
                sximm8, //sign ex. lower 8-bits of the instruction register.
                PC,     //“program counter” input lab8

                vsel, //input to the first multiplexer b4 regfile

                writenum,  //inputs to register file
                write,
                readnum,
                clk,

                loada,  //pipeline registers a & b
                loadb,

                shift,  //input to shifter unit

                sximm5, //input for toBin MUX

                asel,   //source opperand multiplexers
                bsel,

                ALUop,  //ALU input

                loadc,  //pipeline c
                loads,  //status register

                Z_out,  //status output
                datapath_out); //datapath output

//-------------------------------------------------------------

  //inputs and outputs

    input [15:0] mdata;  //inputs to datapath (used in lab7, not lab6) assign 0 for lab 6
    input [15:0] sximm8; //this is the actual input to look at in lab6
    input [7:0] PC; //PC is the program counter used in lab8-> assign 0 for lab 6

    input [1:0] vsel; //input to the first multiplexer b4 regfile

    input [2:0] writenum;  //inputs to register file
    input write;
    input [2:0] readnum;
    input clk;

    input loada;  //pipeline registers a & b
    input loadb;

    input [1:0] shift; //input to shifter unit

    input [15:0] sximm5; //input for toBin MUX

    input asel;   //source opperand multiplexers
    input bsel;

    input [1:0] ALUop;  //ALU input

    input loadc;  //pipeline c
    input loads; //status register

    output [2:0] Z_out;  //status output -> Z_out[0] = Zero flag(STATUS)
                                      // -> Z_out[1] =negative flag
                                      // -> Z_out[2] = overflow flag
    output [15:0] datapath_out; //datapath output

//--------------------------------------------------------------

  //Wires

    //into the regfile
    wire [15:0] data_in;
    //out of regfile
    wire [15:0] data_out;

    //wire out of LoadA (3->6)
    wire [15:0] loadaToMux;

    //wire into shifter
    wire [15:0] in;
    //wire out of shifter
    wire [15:0] sout;

    //wires into ALU
    wire[15:0] Ain, Bin;
    //wires out of the ALU
    wire [2:0] Z;
    wire[15:0]out;


//------------------------------------------------------------------

    //instantiating the main datapath Modules (Dont change the instance name)
    regfile REGFILE(data_in,writenum,write,readnum,clk,data_out);

    ALU alu(Ain,Bin,ALUop,out,Z);

    shifter SHIFTER(in,shift,sout);

//------------------------------------------------------------------

  //following is the code for the remaining logical blocks
  //check figure 1 of lab 5 for the numerical codes of the components
  //NOTE: the vDFFE is defined in the regfile.v file

  //Registers
    //Component3: Loada register
    vDFFE #(16) RegLoadA(.clk(clk), .en(loada),
                         .in(data_out), .out(loadaToMux));

   //Component4: Loadb register
   vDFFE #(16) RegLoadB(.clk(clk), .en(loadb),
                        .in(data_out), .out(in));

   //Component5: Loadc register
   vDFFE #(16) RegLoadC(.clk(clk), .en(loadc),
                        .in(out), .out(datapath_out));

   //Component10: Status register
   vDFFE #(3) RegStatus(.clk(clk), .en(loads),
                        .in(Z), .out(Z_out));

  //Multiplexers

  //NOTE: component9 needs to be changed ->done
    //Component9: Multiplexer before the regfile
    Mux4b #(16) BeforeRegfile(.a3(mdata), .a2(sximm8),
                              .a1({8'b0,PC}), .a0(datapath_out),
                              .s(vsel), .b(data_in));

    //Component6: Multiplexer after LoadA
    Mux2a #(16) toAin(.a1(16'b0), .a0(loadaToMux),
                              .s(asel), .b(Ain));

  //NOTE: component7 needs to be changed-> DONE
    //Component7: Multiplexer after LoadB and shifter
    Mux2a #(16) toBin(.a1(sximm5), .a0(sout),
                              .s(bsel), .b(Bin));

//--------------------------------------------------------------

endmodule



//-------------------------------------------------------------------

  //following are the modules made for the datapath


//2-input binary select MUX
  module Mux2a(a1, a0, s, b);
   parameter k = 1 ;
   input [k-1:0] a0, a1;  // inputs
   input s ;
   output[k-1:0] b ;

   assign b = (s) ? a1 : a0;

  endmodule


//Added for lab6
//4-Input-Binary-Select-MUX
  module Mux4b(a3, a2, a1, a0, s, b);

    parameter k = 16;
    input [k-1:0] a3, a2, a1, a0; //inputs
    input [1:0] s; //binary Select
    output [k-1:0] b;
    reg [k-1:0] b;

    always @ ( * ) begin
      case (s)
        2'b00: b= a0;
        2'b01: b= a1;
        2'b10: b= a2;
        2'b11: b= a3;
        default: b= 16'bx; // catches errors
      endcase
    end

  endmodule
