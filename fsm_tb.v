// state encoding for control FSM
`define SW          5
`define sWait       5'd0
`define sDecode     5'd1
`define sGetB       5'd2
`define sGetA       5'd3
`define sAND_ADD    5'd4
`define sMVN_MOV    5'd5
`define sGetStatus  5'd6
`define sResultToRd 5'd7
`define sMovImToRn  5'd8


module control_tb();

//Regs and Wires
 reg err;
 reg clk;
 reg reset;
 reg s;
 reg [2:0] opcode;
 reg [1:0] op;
               //Outouts added for lab 7
 wire load_ir;  //enable for instruction register
 wire load_addr; //enable for Address register
 wire load_pc;   //enable for program counter
 wire reset_pc;  //resets the Program counter mux
 wire addr_sel;  //mux for selecting the addr. source(datapath_out vs PC)
 wire [1:0] mem_cmd;   //1-hot read write: `MREAD: 2'b01, `MWRITE: 2'b10
               //input to the first multiplexer before regfile
 wire [1:0] vsel;
               //input to the REGFILE
 wire write;
               //pipeline registers a & b
 wire loada;
 wire loadb;
               //Select to mux before ALU
 wire asel;
 wire bsel;
               //pipeline c
 wire loadc;
               //status register
 wire loads;
               //Use the 1-HOT-select for Rn | Rd | Rm
 wire [2:0] nsel;
               //signal for wait state
 wire w;

//------------------------------------------------------------------------------

  //instantiating the dut
  control dut(   //inputs to fsm
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

//------------------------------------------------------------------------------

//clock
  initial begin
   clk = 0; #5; //the clock starts with a 0
   forever begin
     clk = 1; #5;
     clk = 0; #5;
   end
  end

  //------------------------------------------------------------------------------

  //The tests:
    initial begin
    //Setting signal err to 0
      err = 1'b0;
      reset = 1'b0; //resets the FSM to sWait
      s= 1'b0; //stays in state in the begining

//------------------------------------------------------------------------------

    //testing ADD operation
      opcode = 3'b101;
      op = 2'b00;
      #10;

      s= 1'b1;
      #10; //turns on s for 1 Cycle
      s= 1'b0;
      #60;//turns s off for 6 cycles




    if( ~err ) $display("PASSED the test for ADD command");
    else $stop;

//------------------------------------------------------------------------------
   //testing MVN Rd,Rm{,<sh_op>} operation
     opcode = 3'b101;
     op = 2'b11;
     #10;

     s= 1'b1;
     #10; //turns on s for 1 Cycle
     s= 1'b0;
     #50;//turns s off for 5 cycles


     // check whether in expected state


    if( ~err ) $display("PASSED the test for MVN Rd,Rm{,<sh_op>} command");
    else $stop;


//------------------------------------------------------------------------------

   //testing MOV Rn,#<im8> operation
     opcode = 3'b110;
     op = 2'b10;
     #10;
     
     s= 1'b1;
     #10; //turns on s for 1 Cycle
     s= 1'b0;
     #20;//turns s off for 2 cycles


     // check whether in expected state


    if( ~err ) $display("PASSED the test for MOV Rn,#<im8> command");
    else $stop;


//------------------------------------------------------------------------------

  //testing CMP Rn,Rm{,<sh_op>}  operation
    opcode = 3'b101;
    op = 2'b01;
    #10;

    s= 1'b1;
    #10; //turns on s for 1 Cycle
    s= 1'b0;
    #50;//turns s off for 5 cycles


    // check whether in expected state


   if( ~err ) $display("PASSED the test for CMP Rn,Rm{,<sh_op>}  command");
   else $stop;


//------------------------------------------------------------------------------

  //testing MOV Rd,Rm{,<sh_op>}  operation
    opcode = 3'b110;
    op = 2'b00;
    #10;

    s= 1'b1;
    #10; //turns on s for 1 Cycle
    s= 1'b0;
    #50;//turns s off for 5 cycles


    // check whether in expected state


   if( ~err ) $display("PASSED the test for MOV Rd,Rm{,<sh_op>}  command");
   else $stop;


//------------------------------------------------------------------------------

  //testing AND Rd,Rn,Rm{,<sh_op>}  operation
    opcode = 3'b101;
    op = 2'b10;
    #10;

    s= 1'b1;
    #10; //turns on s for 1 Cycle
    s= 1'b0;
    #50;//turns s off for 5 cycles


    // check whether in expected state


   if( ~err ) $display("PASSED the test for AND Rd,Rn,Rm{,<sh_op>}  command");
   else $stop;


//------------------------------------------------------------------------------

    $display("**PASSED ALL TESTS**");
    $stop;
    end

endmodule
