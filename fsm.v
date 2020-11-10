//1. each cycle takes a state + one state for "wait"
//2. NOTE: that in your Verilog you need to set all outputs in every state—
//    including those outputs that are zero or for which you don’t care what the value is
//3. Replace readnum and writenum by nsel for the operation

//Observations:
//1. AND and ADD have the same operation for fsm
//2. MOV Rd,Rm{,<sh_op>} and MVN have the same operation for fsm
//3. MOV Rn,#<im8> will have a unique state

//DEFINING STATES:       a-> States that were defined in lab7

//1a. After turning reset on this is the state we go to->    State: sReset
//2a. the address stored is sent to the instruction memory-> State: sIF1
//3a. Instruction at now available at dout->                 State: sIF2
//4a. Update the PC to the address of the next instruction-> State: sUpdatePC

//1. loading Rm to B is the same for all instructions->  State: sGetB
//2. loading Rn to A is the same for some instructions-> State: sGetA
//3. Computing and saving AND/ADD to reg. C->            State: sAND_ADD
//4. Computing and saving MVN/MOV to reg. C->            State: sMVN_MOV
//5. Getting the status flags:                           State: sGetStatus
//6. Saving result to Rd:                                State: sResultToRd
//7. Moving sximm8 to Rn:                                State: sMovImToRn

// States for LDR/STR:
//For LDR:
//1. sGetA
//2. sAddImm5ToA
//3. sLoadAddr
//4. sLDR_MRead
//5. sLDR_MDataToReg -> We might need to split this instruction



//NOTE: Editing the IOs for lab 7
module control(   //inputs to fsm
              clk,
              reset,
              opcode,
              op,
                  //NOTE: outputs for lab7:
              load_ir,  //enable for instruction register
              load_addr, //enable for Address register
              load_pc,   //enable for program counter
              reset_pc,  //resets the Program counter mux
              addr_sel,  //mux for selecting the addr. source(datapath_out vs PC)
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
              );

                //inputs to fsm
  input clk;
  input reset;
  input [2:0] opcode;
  input [1:0] op;

            //Outouts added for lab 7
  output load_ir;  //enable for instruction register
  output load_addr; //enable for Address register
  output load_pc;   //enable for program counter
  output reset_pc;  //resets the Program counter mux
  output addr_sel;  //mux for selecting the addr. source(datapath_out vs PC)
  output [1:0] mem_cmd;   //1-hot read write: `MREAD: 2'b01, `MWRITE: 2'b10

                  //input to the first multiplexer before regfile
  output [1:0] vsel;
                //input to the REGFILE
  output write;
                //pipeline registers a & b
  output loada;
  output loadb;
                //Select to mux before ALU
  output asel;
  output bsel;
                //pipeline c
  output loadc;
                //status register
  output loads;
                //Use the 1-HOT-select for Rn | Rd | Rm
  output [2:0] nsel;
                //signal for wait state


//------------------------------------------------------------------------------

  //inputs to mem_cmd for read/write operation
  `define MREAD       2'b01
  `define MWRITE      2'b10

  // state encoding for control FSM //Modified for lab 7
  `define SW                      5
  `define sReset                  5'b00_000
  `define sIF1                    5'b00_001
  `define sIF2                    5'b00_010
  `define sUpdatePC               5'b00_011
  `define sDecode                 5'b00_100


  `define sGetB                   5'b00_101
  `define sGetA                   5'b00_110
  `define sAND_ADD                5'b00_111
  `define sMVN_MOV                5'b01_000
  `define sGetStatus              5'b01_001
  `define sResultToRd             5'b01_010
  `define sMovImToRn              5'b01_011


  `define sHALT                   5'b01_100 //For STR/LDR
  `define sAddImm5ToA             5'b01_101
  `define sLoadAddr               5'b01_110
  `define sLDR_MRead              5'b01_111
  `define sLDR_MDataToReg         5'b10_000
  `define sSTR_RdToB              5'b10_001
  `define sSTR_BtoDOUT            5'b10_010
  `define sSTR_MWrite             5'b10_011

  //2. sAddImm5ToA
  //3. sLoadAddr
  //4. sLDR_MRead
  //5. sLDR_MDataToReg

//------------------------------------------------------------------------------

//Wires and Regs
  wire [`SW-1:0] present_state, state_next_reset, state_next;
  reg [(`SW+19)-1:0] nextSignals;

//------------------------------------------------------------------------------

// state DFF for control FSM
  vDFF #(`SW) STATE(clk,state_next_reset,present_state);

// Assigns the reset state or next state after checking signal reset
  assign state_next_reset = reset ? `sReset : state_next;

//Output assignments:

              // {state_next, vsel, write,
              // loada, loadb, asel, bsel,
              // loadc, loads, nsel, load_ir,
              // load_addr, load_pc, reset_pc, addr_sel, mem_cmd} = nextSignals;

  always @(*)
    casex ( {present_state, {opcode, op}} )  //NOTE: removed s and replaced sWait for lab7

//------------------------------------------------------------------------------

    //Reset STATE
      {`sReset, 5'bx}: nextSignals = {`sIF1, 2'b00, 1'b0,      // {state_next, vsel, write,
                                         1'b0, 1'b0, 1'b0, 1'b0,   //  loada, loadb, asel, bsel,
                                         1'b0, 1'b0, 3'b000, 1'b0, //    loadc, loads, nsel, load_ir
                                         1'b0, 1'b1, 1'b1, 1'b0, 2'b0 //load_addr, load_pc, reset_pc, addr_sel, mem_cmd} = nextSignals
                                         };



//------------------------------------------------------------------------------

    //IF1 State
    {`sIF1, 5'bx}: nextSignals = {`sIF2, 2'b00, 1'b0,      // {state_next, vsel, write,
                                      1'b0, 1'b0, 1'b0, 1'b0,   //  loada, loadb, asel, bsel,
                                      1'b0, 1'b0, 3'b000, 1'b0, //    loadc, loads, nsel, load_ir
                                      1'b0, 1'b0, 1'b0, 1'b1, `MREAD //load_addr, load_pc, reset_pc, addr_sel, mem_cmd} = nextSignals
                                      };


//------------------------------------------------------------------------------

    //IF2 State
    {`sIF2, 5'bx}: nextSignals = {`sUpdatePC, 2'b00, 1'b0,      // {state_next, vsel, write,
                                        1'b0, 1'b0, 1'b0, 1'b0,   //  loada, loadb, asel, bsel,
                                        1'b0, 1'b0, 3'b000, 1'b1, //    loadc, loads, nsel, load_ir
                                        1'b0, 1'b0, 1'b0, 1'b1, `MREAD //load_addr, load_pc, reset_pc, addr_sel, mem_cmd} = nextSignals
                                        };

//------------------------------------------------------------------------------

    //UpdatePC State
    {`sUpdatePC, 5'bx}: nextSignals = {`sDecode, 2'b00, 1'b0,      // {state_next, vsel, write,
                                          1'b0, 1'b0, 1'b0, 1'b0,   //  loada, loadb, asel, bsel,
                                          1'b0, 1'b0, 3'b000, 1'b0, //    loadc, loads, nsel, load_ir
                                          1'b0, 1'b1, 1'b0, 1'b0, 2'b0 //load_addr, load_pc, reset_pc, addr_sel, mem_cmd} = nextSignals
                                          };


//------------------------------------------------------------------------------

    //Decode State
      //for instruction MOV Rn,#<im8>
      {`sDecode, 5'b110_10}: nextSignals = {`sMovImToRn, 19'b0}; // sDecode->sMovImToRn
      //for other instructions
      {`sDecode, 5'b110_00}: nextSignals = {`sGetB, 19'b0}; // sDecode->sGetB
      {`sDecode, 5'b101_xx}: nextSignals = {`sGetB, 19'b0};
      //for LDR:
      {`sDecode, 5'b011_00}: nextSignals = {`sGetA, 19'b0}; //sDecode-> sGetA
      //for STR:
      {`sDecode, 5'b100_00}: nextSignals = {`sGetA, 19'b0}; //sDecode-> sGetA
      //For HALT:
      {`sDecode, 5'b111_xx}: nextSignals = {`sHALT, 19'b0}; //sDecode->sHALT

//------------------------------------------------------------------------------

    //HALT State
      {`sHALT, 5'bx}: nextSignals = {`sHALT, 2'b00, 1'b0,      // {state_next, vsel, write,
                                            1'b0, 1'b0, 1'b0, 1'b0,   //  loada, loadb, asel, bsel,
                                            1'b0, 1'b0, 3'b000, 1'b0, //    loadc, loads, nsel, load_ir
                                            1'b0, 1'b0, 1'b0, 1'b0, 2'b0 //load_addr, load_pc, reset_pc, addr_sel, mem_cmd} = nextSignals
                                            }; // sHALT->sHALT

//------------------------------------------------------------------------------
    //MovImToRn State
      {`sMovImToRn, 5'bx}: nextSignals = {`sIF1, 2'b10, 1'b1,      // {state_next, vsel, write,
                                                1'b0, 1'b0, 1'b0, 1'b0,   //  loada, loadb, asel, bsel,
                                                1'b0, 1'b0, 3'b100, 1'b0, //    loadc, loads, nsel, load_ir
                                                1'b0, 1'b0, 1'b0, 1'b0, 2'b0 //load_addr, load_pc, reset_pc, addr_sel, mem_cmd} = nextSignals
                                                }; // sDecode->sGetB

//------------------------------------------------------------------------------

    //GetB State
      //for MOV Rd, Rm
      {`sGetB, 5'b110_00}: nextSignals = {`sMVN_MOV, 2'b00, 1'b0,      // {state_next, vsel, write,
                                                1'b0, 1'b1, 1'b0, 1'b0,   //  loada, loadb, asel, bsel,
                                                1'b0, 1'b0, 3'b001, 1'b0, //    loadc, loads, nsel, load_ir
                                                1'b0, 1'b0, 1'b0, 1'b0, 2'b0 //load_addr, load_pc, reset_pc, addr_sel, mem_cmd} = nextSignals
                                                };
      //for MVN Rd, Rm
      {`sGetB, 5'b101_11}: nextSignals = {`sMVN_MOV, 2'b00, 1'b0,      // {state_next, vsel, write,
                                                1'b0, 1'b1, 1'b0, 1'b0,   //  loada, loadb, asel, bsel,
                                                1'b0, 1'b0, 3'b001, 1'b0, //    loadc, loads, nsel, load_ir
                                                1'b0, 1'b0, 1'b0, 1'b0, 2'b0 //load_addr, load_pc, reset_pc, addr_sel, mem_cmd} = nextSignals
                                                };

      //for ADD Rd,Rn Rm and for AND Rd,Rn Rm (Check the x in op)
      {`sGetB, 5'b101_x0}: nextSignals = {`sGetA, 2'b00, 1'b0,      // {state_next, vsel, write,
                                                1'b0, 1'b1, 1'b0, 1'b0,   //  loada, loadb, asel, bsel,
                                                1'b0, 1'b0, 3'b001, 1'b0, //    loadc, loads, nsel, load_ir
                                                1'b0, 1'b0, 1'b0, 1'b0, 2'b0 //load_addr, load_pc, reset_pc, addr_sel, mem_cmd} = nextSignals
                                                };
      //for CMP Rn, Rm
      {`sGetB, 5'b101_01}: nextSignals = {`sGetA, 2'b00, 1'b0,      // {state_next, vsel, write,
                                                1'b0, 1'b1, 1'b0, 1'b0,   //  loada, loadb, asel, bsel,
                                                1'b0, 1'b0, 3'b001, 1'b0, //    loadc, loads, nsel, load_ir
                                                1'b0, 1'b0, 1'b0, 1'b0, 2'b0 //load_addr, load_pc, reset_pc, addr_sel, mem_cmd} = nextSignals
                                                };

//------------------------------------------------------------------------------

    //GetA State
     //for ADD Rd,Rn Rm and for AND Rd,Rn Rm (Check the x in op)
     {`sGetA, 5'b101_x0}: nextSignals = {`sAND_ADD, 2'b00, 1'b0,      // {state_next, vsel, write,
                                               1'b1, 1'b0, 1'b0, 1'b0,   //  loada, loadb, asel, bsel,
                                               1'b0, 1'b0, 3'b100, 1'b0, //    loadc, loads, nsel, load_ir
                                               1'b0, 1'b0, 1'b0, 1'b0, 2'b0 //load_addr, load_pc, reset_pc, addr_sel, mem_cmd} = nextSignals
                                               };
     //for CMP Rn, Rm
     {`sGetA, 5'b101_01}: nextSignals = {`sGetStatus, 2'b00, 1'b0,      // {state_next, vsel, write,
                                               1'b1, 1'b0, 1'b0, 1'b0,   //  loada, loadb, asel, bsel,
                                               1'b0, 1'b0, 3'b100, 1'b0, //    loadc, loads, nsel, load_ir
                                               1'b0, 1'b0, 1'b0, 1'b0, 2'b0 //load_addr, load_pc, reset_pc, addr_sel, mem_cmd} = nextSignals
                                               };

     //for LDR
     {`sGetA, 5'b011_00}: nextSignals = {`sAddImm5ToA, 2'b00, 1'b0,      // {state_next, vsel, write,
                                              1'b1, 1'b0, 1'b0, 1'b0,   //  loada, loadb, asel, bsel,
                                              1'b0, 1'b0, 3'b100, 1'b0, //    loadc, loads, nsel, load_ir
                                              1'b0, 1'b0, 1'b0, 1'b0, 2'b0 //load_addr, load_pc, reset_pc, addr_sel, mem_cmd} = nextSignals
                                              };

    //for STR
    {`sGetA, 5'b100_00}: nextSignals = {`sAddImm5ToA, 2'b00, 1'b0,      // {state_next, vsel, write,
                                             1'b1, 1'b0, 1'b0, 1'b0,   //  loada, loadb, asel, bsel,
                                             1'b0, 1'b0, 3'b100, 1'b0, //    loadc, loads, nsel, load_ir
                                             1'b0, 1'b0, 1'b0, 1'b0, 2'b0 //load_addr, load_pc, reset_pc, addr_sel, mem_cmd} = nextSignals
                                             };

//------------------------------------------------------------------------------

    //MVN_MOV State (Cycle 2)
     //for MOV Rd, Rm and for MVN Rd, Rm
     {`sMVN_MOV, 5'bx}: nextSignals = {`sResultToRd, 2'b00, 1'b0,      // {state_next, vsel, write,
                                                 1'b0, 1'b0, 1'b1, 1'b0,   //  loada, loadb, asel, bsel,
                                                 1'b1, 1'b0, 3'b000, 1'b0, //    loadc, loads, nsel, load_ir
                                                 1'b0, 1'b0, 1'b0, 1'b0, 2'b0 //load_addr, load_pc, reset_pc, addr_sel, mem_cmd} = nextSignals
                                                 };

//------------------------------------------------------------------------------

    //AND_ADD State
    //for ADD Rd,Rn Rm and for AND Rd,Rn Rm (Check the x in op)
    {`sAND_ADD, 5'bx}: nextSignals = {`sResultToRd, 2'b00, 1'b0,      // {state_next, vsel, write,
                                              1'b0, 1'b0, 1'b0, 1'b0,   //  loada, loadb, asel, bsel,
                                              1'b1, 1'b0, 3'b000, 1'b0, //    loadc, loads, nsel, load_ir
                                              1'b0, 1'b0, 1'b0, 1'b0, 2'b0 //load_addr, load_pc, reset_pc, addr_sel, mem_cmd} = nextSignals
                                              };

//------------------------------------------------------------------------------

  //GetStatus State
    //for CMP Rn, Rm
    {`sGetStatus, 5'b101_01}: nextSignals = {`sIF1, 2'b00, 1'b0,// {state_next, vsel, write,
                                              1'b0, 1'b0, 1'b0, 1'b0,   //  loada, loadb, asel, bsel,
                                              1'b0, 1'b1, 3'b000, 1'b0, //    loadc, loads, nsel, load_ir
                                              1'b0, 1'b0, 1'b0, 1'b0, 2'b0 //load_addr, load_pc, reset_pc, addr_sel, mem_cmd} = nextSignals
                                              };

//------------------------------------------------------------------------------

  //ResultToRd State
    //all in this state
    {`sResultToRd, 5'bx}: nextSignals = {`sIF1, 2'b00, 1'b1,// {state_next, vsel, write,
                                              1'b0, 1'b0, 1'b0, 1'b0,   //  loada, loadb, asel, bsel,
                                              1'b0, 1'b0, 3'b010, 1'b0, //    loadc, loads, nsel, load_ir
                                              1'b0, 1'b0, 1'b0, 1'b0, 2'b0 //load_addr, load_pc, reset_pc, addr_sel, mem_cmd} = nextSignals
                                              };

//*****----------------------Additions for LDR/STR Instructions-----------******
//------------------------------------------------------------------------------
//sAddImm5ToA State for LDR/STR (Cycle 2)

  //for LDR
  {`sAddImm5ToA, 5'b011_00}: nextSignals = {`sLoadAddr, 2'b00, 1'b0,      // {state_next, vsel, write,
                                          1'b0, 1'b0, 1'b0, 1'b1,   //  loada, loadb, asel, bsel,
                                          1'b1, 1'b0, 3'b000, 1'b0, //    loadc, loads, nsel, load_ir
                                          1'b0, 1'b0, 1'b0, 1'b0, 2'b0 //load_addr, load_pc, reset_pc, addr_sel, mem_cmd} = nextSignals
                                          };  //sAddImm5ToA->sLoadAddr

  //for STR
  {`sAddImm5ToA, 5'b100_00}: nextSignals = {`sLoadAddr, 2'b00, 1'b0,      // {state_next, vsel, write,
                                          1'b0, 1'b0, 1'b0, 1'b1,   //  loada, loadb, asel, bsel,
                                          1'b1, 1'b0, 3'b000, 1'b0, //    loadc, loads, nsel, load_ir
                                          1'b0, 1'b0, 1'b0, 1'b0, 2'b0 //load_addr, load_pc, reset_pc, addr_sel, mem_cmd} = nextSignals
                                          };  //sAddImm5ToA->sLoadAddr

//------------------------------------------------------------------------------
//sLoadAddr STATE for LDR/STR (Cycle 3)

  //for LDR
  {`sLoadAddr, 5'b011_00}: nextSignals = {`sLDR_MRead, 2'b00, 1'b0,      // {state_next, vsel, write,
                                          1'b0, 1'b0, 1'b0, 1'b0,   //  loada, loadb, asel, bsel,
                                          1'b0, 1'b0, 3'b000, 1'b0, //    loadc, loads, nsel, load_ir
                                          1'b1, 1'b0, 1'b0, 1'b0, 2'b0 //load_addr, load_pc, reset_pc, addr_sel, mem_cmd} = nextSignals
                                          };  //sLoadAddr->sLDR_MRead

  //for STR
  {`sLoadAddr, 5'b100_00}: nextSignals = {`sSTR_RdToB, 2'b00, 1'b0,      // {state_next, vsel, write,
                                          1'b0, 1'b0, 1'b0, 1'b0,   //  loada, loadb, asel, bsel,
                                          1'b0, 1'b0, 3'b000, 1'b0, //    loadc, loads, nsel, load_ir
                                          1'b1, 1'b0, 1'b0, 1'b0, 2'b0 //load_addr, load_pc, reset_pc, addr_sel, mem_cmd} = nextSignals
                                          };  //sLoadAddr->sSTR_RdToB

//------------------------------------------------------------------------------

//sLDR_MRead STATE for LDR (Cycle 4)

  //for LDR
  {`sLDR_MRead, 5'bx}: nextSignals = {`sLDR_MDataToReg, 2'b00, 1'b0,      // {state_next, vsel, write,
                                          1'b0, 1'b0, 1'b0, 1'b0,   //  loada, loadb, asel, bsel,
                                          1'b0, 1'b0, 3'b000, 1'b0, //    loadc, loads, nsel, load_ir
                                          1'b0, 1'b0, 1'b0, 1'b0, `MREAD //load_addr, load_pc, reset_pc, addr_sel, mem_cmd} = nextSignals
                                          };  //sLDR_MRead->sLDR_MDataToReg

//------------------------------------------------------------------------------

//sLDR_MDataToReg STATE for LDR (Cycle 5)

  //for LDR
  {`sLDR_MDataToReg, 5'bx}: nextSignals = {`sIF1, 2'b11, 1'b1,      // {state_next, vsel, write,
                                            1'b0, 1'b0, 1'b0, 1'b0,   //  loada, loadb, asel, bsel,
                                          1'b0, 1'b0, 3'b010, 1'b0, //    loadc, loads, nsel, load_ir
                                          1'b0, 1'b0, 1'b0, 1'b0, `MREAD //load_addr, load_pc, reset_pc, addr_sel, mem_cmd} = nextSignals
                                          };  //sLDR_MDataToReg->sIF1

//------------------------------------------------------------------------------

//sSTR_RdToB STATE for STR instruction (cycle 4)

  //for STR
  {`sSTR_RdToB, 5'bx}: nextSignals = {`sSTR_BtoDOUT, 2'b00, 1'b0,      // {state_next, vsel, write,
                                          1'b0, 1'b1, 1'b0, 1'b0,   //  loada, loadb, asel, bsel,
                                          1'b0, 1'b0, 3'b010, 1'b0, //    loadc, loads, nsel, load_ir
                                          1'b0, 1'b0, 1'b0, 1'b0, 2'b0 //load_addr, load_pc, reset_pc, addr_sel, mem_cmd} = nextSignals
                                          };  //sSTR_RdToB->sSTR_BtoDOUT

//------------------------------------------------------------------------------

//sSTR_BtoDOUT STATE for STR instruction (cycle 5)

  //for STR
  {`sSTR_BtoDOUT, 5'bx}: nextSignals = {`sSTR_MWrite, 2'b00, 1'b0,      // {state_next, vsel, write,
                                          1'b0, 1'b0, 1'b1, 1'b0,   //  loada, loadb, asel, bsel,
                                          1'b1, 1'b0, 3'b000, 1'b0, //    loadc, loads, nsel, load_ir
                                          1'b0, 1'b0, 1'b0, 1'b0, 2'b0 //load_addr, load_pc, reset_pc, addr_sel, mem_cmd} = nextSignals
                                          };  //sSTR_BtoDOUT->sSTR_MWrite

//------------------------------------------------------------------------------

//sSTR_MWrite STATE for STR instruction (cycle 6)

  //for STR
  {`sSTR_MWrite, 5'bx}: nextSignals = {`sIF1, 2'b00, 1'b0,      // {state_next, vsel, write,
                                          1'b0, 1'b0, 1'b0, 1'b0,   //  loada, loadb, asel, bsel,
                                          1'b0, 1'b0, 3'b000, 1'b0, //    loadc, loads, nsel, load_ir
                                          1'b0, 1'b0, 1'b0, 1'b0, `MWRITE //load_addr, load_pc, reset_pc, addr_sel, mem_cmd} = nextSignals
                                          };  //sSTR_BtoDOUT->sSTR_MWrite

//------------------------------------------------------------------------------

      default:     nextSignals = {{`SW{1'bx}},{19{1'bx}}}; // only get here if present_state, s, or zero are x’s
    endcase

  // copy to module outputs
  assign {state_next, vsel, write,
          loada, loadb, asel, bsel,
          loadc, loads, nsel, load_ir,
    load_addr, load_pc, reset_pc, addr_sel, mem_cmd} = nextSignals;



endmodule


//------------------------------------------------------------------------------
//helper modules

module vDFF(clk,D,Q);
  parameter n=1;
  input clk;
  input [n-1:0] D;
  output [n-1:0] Q;
  reg [n-1:0] Q;
  always @(posedge clk)
    Q <= D;
endmodule
