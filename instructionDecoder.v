

//Instruction Decoder
module InstructionDecoder(iRegToiDec,//Inputs to the Decoder
                            nsel,

                            opcode,//To FSM
                            op,

                            ALUop,//To datapath
                            sximm5,
                            sximm8,
                            shift,
                            readnum,
                            writenum);


  // Inputs/outputs to the module
  input [15:0] iRegToiDec;//Inputs to the Decoder
  input [2:0] nsel; //NOTE: Use the 1-HOT select for Rn | Rd | Rm

  output [2:0] opcode;//To FSM
  output [1:0] op;

  output [1:0] ALUop;//To datapath
  output [15:0] sximm5;
  output [15:0] sximm8;
  output [1:0] shift;
  output [2:0] readnum;
  output [2:0] writenum;

//------------------------------------------------------------------------------

  //Wires
  wire [2:0] Rn, Rd, Rm;
  wire [2:0] muxOutNsel;

  //------------------------------------------------------------------------------

  //Module instantiating

  //outouts readnum and writenum
  Mux3H #(3) MuxToReadnumWritenum(Rn, Rd, Rm, nsel, muxOutNsel);

  //------------------------------------------------------------------------------

  //Assignments

  //input to the ALUop
  assign ALUop = iRegToiDec[12:11];
  //Sign extends bit 4
  assign sximm5 = (iRegToiDec[4])?
                  {{11{1'b1}},iRegToiDec[4:0]}:{{11{1'b0}},iRegToiDec[4:0]};
  //Sign extends bit 7;
  assign sximm8 = (iRegToiDec[7])?
                  {{8{1'b1}},iRegToiDec[7:0]}:{{8{1'b0}},iRegToiDec[7:0]};

  assign Rm = iRegToiDec[2:0];

  assign {opcode, op, //15:13, 12:11
          Rn, Rd,   //10:8, 7:5
           shift  //4:3
           } = iRegToiDec[15:3];

  //outputs of the MUX
  assign readnum = muxOutNsel;
  assign writenum = muxOutNsel;

endmodule

//******************************************************************************

//3-Input-1-HOT-Select-MUX
module Mux3H(a2, a1, a0, s, b);

  parameter k = 16;
  input [k-1:0] a2, a1, a0; //inputs
  input [2:0] s; //1-HOT Select
  output [k-1:0] b;
  reg [k-1:0] b;

  always @ ( * ) begin
    case (s)
      3'b001: b= a0;
      3'b010: b= a1;
      3'b100: b= a2;
      default: b= 16'bx; // catches errors
    endcase
  end

endmodule
