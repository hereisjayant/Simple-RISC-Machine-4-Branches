//We need have only the following I/Os for lab 7 CPU:
//1. mem_cmd: Output from the FSM
//2. mem_addr: output from the adress selecting MUX
//3. read_data: input to the Instruction register


`define SW                      5


module cpu(clk, reset, read_data, mem_cmd, mem_addr, write_data, N, V, Z, current_state);

//I/Os
  input clk;
  input reset; //input for FSM
  input [15:0] read_data; //this goes into the instruction register

  output [1:0] mem_cmd; //output from FSM
  output [8:0] mem_addr;  //output from addr_selMux
  output [15:0] write_data; //datapath_out of the CPU
  output N, V, Z; //give the value of negative, overflow
                    //and zero status register bits.
                    //w set to 1 if state machine is in the reset state and is waiting for s to be 1
  output[`SW-1:0] current_state;

//------------------------------------------------------------------------------

//Wires

  //To instruction register
  wire load_ir; //from FSM

  //Wires to instruction decoder
  wire [15:0] iRegToiDec;
  wire [2:0] nsel; //fsm to IDec

  //Wires to the state machine
  wire [2:0] opcode;
  wire [1:0] op;

  //To addr_sel MUX:
    wire addr_sel;  //from FSM
    wire [8:0] PC;  //from PC
    wire [8:0] dataAdressToAddrSel; //from DataAdress

  //To PC reset MUX:
    wire reset_pc;
    wire [8:0] PCSelector_to_PCReset;

  //To PC Selector Mux:
    wire[8:0] BLRegOut;
    wire[2:0] pc_select;

  //To BL register:
   wire load_bl;


  //To ProgramCounter
    wire load_pc;  //from FSM
    wire [8:0] next_pc;  //from PCResetMux

  //To DataAdress Register
    wire [8:0] datapath_outToDataAddress;
    wire load_addr;


  //Wires out of datapath:
    wire [15:0] datapath_out;

  //Wires to the datapath

    //from Instruction decoder
    wire [1:0] ALUop;
    wire [15:0] sximm5;
    wire [15:0] sximm8;
    wire [1:0] shift;
    wire [2:0] readnum;
    wire [2:0] writenum;
    wire [2:0] b_cond;

    //from the FSM
    wire [1:0] vsel;    //input to the REGFILE
    wire write;
    wire loada;        //pipeline registers a & b
    wire loadb;
    wire asel;        //Select to mux before ALU
    wire bsel;
    wire loadc;        //pipeline c
    wire loads;        //status register








//------------------------------------------------------------------------------

//Declared modules:


  //Instruction Register:
  vDFFE #(16) InstructionReg(clk, load_ir, read_data, iRegToiDec);

//------------------------------------------------------------------------------

  //NOTE: Lab 8 Addition:
  //PC Selector Mux://NOTE : removed 1'b1 from a1
  Mux3h #(9) PCSelectorMux(.a2(BLRegOut), .a1(PC + sximm8[8:0]), .a0(PC + 1'b1),
                          .s(pc_select), .b(PCSelector_to_PCReset));

  //PC Reset Mux
  Mux2a #(9) PCResetMux(.a1(9'b0), .a0(PCSelector_to_PCReset),
                        .s(reset_pc), .b(next_pc));

//------------------------------------------------------------------------------
  //BL Register:
  vDFFE #(9) BLRegister(clk, load_bl, PC, BLRegOut);


//------------------------------------------------------------------------------

  //program counter
  vDFFE #(9) ProgramCounter(clk, load_pc, next_pc, PC);

//------------------------------------------------------------------------------

  assign datapath_outToDataAddress = datapath_out[8:0];
  //DataAdress Register
  vDFFE #(9) DataAdress(clk, load_addr, datapath_outToDataAddress, dataAdressToAddrSel);

//------------------------------------------------------------------------------

  //Adress Selecting Mux
  Mux2a #(9) addr_selMux( PC, dataAdressToAddrSel, addr_sel, mem_addr);

//------------------------------------------------------------------------------

  //InstructionDecoder
 InstructionDecoder InstrDec(iRegToiDec,//Inputs to the Decoder
                              nsel,

                              opcode,//To FSM
                              op,

                              ALUop,//To datapath
                              sximm5,
                              sximm8,
                              shift,
                              readnum,
                              writenum,
                              b_cond);


//------------------------------------------------------------------------------

  //FSM:
  control FSM(   //inputs to fsm
                clk,
                reset,
                opcode,
                op,
                V,N,Z,
                b_cond, //Added for lab8

                    // outputs for lab7:
                load_ir,  //enable for instruction register
                load_addr, //enable for Address register
                load_pc,   //enable for program counter
                reset_pc,  //resets the Program counter mux
                addr_sel,  //mux for selecting the addr. source(DataAdress vs PC)
                mem_cmd,   //1-hot read write: `MREAD: 2'b01, `MWRITE: 2'b10
                    //input to the first multiplexer b4 regfile
                vsel,
                    //input to the REGFILE
                write,
                    //pipeline registers a & b
                loada,
                loadb,
                    //Select to mux before ALU
                asel,
                bsel,
                    //pipeline c
                loadc,
                    //status register
                loads,
                    //Use the 1-HOT select for Rn | Rd | Rm
                nsel,
                    //Lab8 additions for PC:
                pc_select,
                load_bl,
                current_state
                );


//------------------------------------------------------------------------------

  //NOTE: instantiate Datapath as DP
  //Datapath
  datapath DP     (read_data,  //NOTE: **mdata** is the 16-bit output of a memory block (Lab 7)
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

                  {V,N,Z},  //status output
                  datapath_out); //datapath output


                  //status output ->                          Z_out[0] = Zero flag(STATUS)
                  //                                   // -> Z_out[1] =negative flag
                  //                                   // -> Z_out[2] = overflow flag


    assign write_data = datapath_out;

endmodule

//******************************************************************************
