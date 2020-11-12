
//NOTE: Instance name of your memory is MEM for the auto-grader.

//inputs to mem_cmd for read/write operation
`define MREAD       2'b01
`define MWRITE      2'b10

module lab7_top(KEY,SW,LEDR,HEX0,HEX1,HEX2,HEX3,HEX4,HEX5);
  input [3:0] KEY;
  input [9:0] SW;
  output [9:0] LEDR;
  output [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;

//------------------------------------------------------------------------------

//Wires:

  //from memory
  wire [15:0] dout;

  //CPU
  wire [15:0] read_data; //this goes into the instruction register
  wire [1:0] mem_cmd; //output from FSM
  wire [8:0] mem_addr;  //output from addr_selMux
  wire [15:0] write_data; //datapath_out of the CPU
  wire N, V, Z; //give the value of negative, overflow
                    //and zero status register bits.
                    //w set to 1 if state machine is in the reset state and is waiting for s to be 1

  //Equals Comparators:
  wire equalsMRead;
  wire equalsMWrite;
  wire msel;

  //Memory mapped IO:
  wire switchEnable;
  wire ledEnable;

//------------------------------------------------------------------------------

//Declared modules:

  //CPU
  cpu CPU(.clk        (~KEY[0]),
          .reset      (~KEY[1]),
          .read_data  (read_data),
          .mem_cmd    (mem_cmd),
          .mem_addr   (mem_addr),
          .write_data (write_data),
          .N          (N),
          .V          (V),
          .Z          (Z),
          .current_state(current_state)
          );

//------------------------------------------------------------------------------
  //Comparator for MREAD
  equals #(2) forMREAD(`MREAD, mem_cmd, equalsMRead);

//------------------------------------------------------------------------------
  //Comparator for MWRITE
  equals #(2) forMWRITE(`MWRITE, mem_cmd, equalsMWrite);

//------------------------------------------------------------------------------
  //Comparator for Msel
  equals #(1) forMsel(1'b0, mem_addr[8:8], msel);

//------------------------------------------------------------------------------

  //RAM (memory)
  RAM MEM(.clk             (~KEY[0]),
          .read_address    (mem_addr),
          .write_address   (mem_addr),
          .write           (equalsMWrite && msel),
          .din             (write_data),
          .dout            (dout)    );

//------------------------------------------------------------------------------

  //triStateBuffer:
  triStateBuffer TriSB_for_Dout(dout, equalsMRead && msel, read_data);

//------------------------------------------------------------------------------

  //Enable for switches:
  enableSwitches enaSW(mem_cmd, mem_addr, switchEnable);

  //Enable for LEDs:
  enableLEDs enaLEDs(mem_cmd, mem_addr, ledEnable);

//------------------------------------------------------------------------------

  //triStateBuffer for Memory mapped IOs:

  //for Switches:
  triStateBuffer tsb_for_switches({8'b0,SW[7:0]}, switchEnable, read_data);

//------------------------------------------------------------------------------

  vDFFE #(8) Register_for_LEDS(~KEY[0], ledEnable, write_data[7:0], LEDR[7:0]) ;

//------------------------------------------------------------------------------

  endmodule


//------------------------------------------------------------------------------

//helper modules:


  module equals(ain, bin, out);
    parameter  k = 1;
    input [k-1:0] ain, bin;
    output out;

    assign out = (ain==bin) ? 1'b1:1'b0;

  endmodule

  module enableSwitches(cmd, address, enable);
    input [1:0] cmd;
    input [8:0] address;
    output enable;

    assign enable = (cmd==`MREAD && address==9'h140) ? 1'b1:1'b0;

  endmodule

  module enableLEDs(cmd, address, enable);
    input [1:0] cmd;
    input [8:0] address;
    output enable;

    assign enable = (cmd==`MWRITE && address==9'h100) ? 1'b1:1'b0;

  endmodule


  module triStateBuffer(in, enable, out);
    parameter k = 16;
    input [k-1:0] in;
    input enable;
    output [k-1:0] out;

    assign out = enable ? in : {k{1'bz}};
  endmodule

  module sseg(in,segs);
    input [3:0] in;
    output [6:0] segs;

    reg [6:0] segs;

    //defining the codes for the HEX display

      `define N0 7'b100_0000 //0
      `define N1 7'b100_1111 //1
      `define N2 7'b010_0100 //2
      `define N3 7'b011_0000 //3
      `define N4 7'b001_1001 //4
      `define N5 7'b001_0010 //5
      `define N6 7'b000_0010 //6
      `define N7 7'b111_1000 //7
      `define N8 7'b000_0000 //8
      `define N9 7'b001_0000 //9


    // NOTE: The code for sseg below is not complete: You can use your code from
    // Lab4 to fill this in or code from someone else's Lab4.
    //
    // IMPORTANT:  If you *do* use someone else's Lab4 code for the seven
    // segment display you *need* to state the following three things in
    // a file README.txt that you submit with handin along with this code:
    //
    //   1.  First and last name of student providing code
    //   2.  Student number of student providing code
    //   3.  Date and time that student provided you their code
    //
    // You must also (obviously!) have the other student's permission to use
    // their code.
    //
    // To do otherwise is considered plagiarism.
    //
    // One bit per segment. On the DE1-SoC a HEX segment is illuminated when
    // the input bit is 0. Bits 6543210 correspond to:
    //
    //    0000
    //   5    1
    //   5    1
    //    6666
    //   4    2
    //   4    2
    //    3333
    //
    // Decimal value | Hexadecimal symbol to render on (one) HEX display
    //             0 | 0
    //             1 | 1
    //             2 | 2
    //             3 | 3
    //             4 | 4
    //             5 | 5
    //             6 | 6
    //             7 | 7
    //             8 | 8
    //             9 | 9
    //            10 | A
    //            11 | b
    //            12 | C
    //            13 | d
    //            14 | E
    //            15 | F

    always @ ( * ) begin
      case (in)
        4'd0: segs = `N0;
        4'd1: segs = `N1;
        4'd2: segs = `N2;
        4'd3: segs = `N3;
        4'd4: segs = `N4;
        4'd5: segs = `N5;
        4'd6: segs = `N6;
        4'd7: segs = `N7;
        4'd8: segs = `N8;
        4'd9: segs = `N9;
        default: segs = 4'b1110;  // this will output "F"
      endcase
    end

  endmodule
