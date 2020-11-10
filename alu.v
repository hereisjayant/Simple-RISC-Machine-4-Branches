// The output Z needs to be changed for lab6
// output [2:0] Z_out;  //status output -> Z_out[0] = Zero flag(STATUS)
//                                   // -> Z_out[1] =negative flag
//                                   // -> Z_out[2] = overflow flag


module ALU(Ain,Bin,ALUop,out,Z);
  input [15:0] Ain, Bin;
  input [1:0] ALUop;
  output [15:0] out;
  output [2:0] Z;

  wire sub; // checks if the subtraction operation is being performed
  wire [15:0] s; //output for the helper module
  wire ovf; //checks overflow

  reg [15:0] out;

  always @(*) begin
    case(ALUop)
      2'b00: out = s;//ADDing the input
      2'b01: out = s;//SUBTRACTing the input
      2'b10: out = Ain&Bin;//ANDing the input
      2'b11: out = ~Bin;//INVERSE of the input
      default: out =  {16{1'bx}} ; //to catch errors
    endcase
  end

  assign sub = (ALUop==2'b01) ? 1'b1 : 1'b0;


  AddSub OvFlow(Ain, Bin, sub, s, ovf); //does the math and checks overflow

//ALU output: if out=0 Z=1, otherwise Z=0

  assign Z[0] = (out==16'b0)?1'b1:1'b0; //checks if the output is zero
  assign Z[2] = ovf; //gets the overflow
  assign Z[1] = out[15]; //gets the signed bits

endmodule


//------------------------------------------------------------------------------

//helper modules(taken from lecture notes):

// add a+b or subtract a-b, check for overflow
module AddSub(a,b,sub,s,ovf) ;
  parameter n = 16 ;
  input [n-1:0] a, b ;
  input sub ;           // subtract if sub=1, otherwise add
  output [n-1:0] s ;
  output ovf ;          // 1 if overflow
  wire c1, c2 ;         // carry out of last two bits
  wire ovf = c1 ^ c2 ;  // overflow if signs don't match

  // add non sign bits
  Adder1 #(n-1) ai(a[n-2:0],b[n-2:0]^{n-1{sub}},sub,c1,s[n-2:0]) ;
  // add sign bits
  Adder1 #(1)   as(a[n-1],b[n-1]^sub,c1,c2,s[n-1]) ;
endmodule

// multi-bit adder - behavioral
module Adder1(a,b,cin,cout,s) ;
  parameter n = 8 ;
  input [n-1:0] a, b ;
  input cin ;
  output [n-1:0] s ;
  output cout ;
  wire [n-1:0] s;
  wire cout ;

  assign {cout, s} = a + b + cin ;
endmodule
