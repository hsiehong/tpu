//============================================================================//
// AIC2021 Project1 - TPU Design                                              //
// file: top_tb.v                                                             //
// description: testbench for tpu top module                                  //
// authors: kaikai (deekai9139@gmail.com)                                     //
//          suhan  (jjs93126@gmail.com)                                       //
//============================================================================//

`timescale 1ns/10ps
`include "define.v"
`include "top.v"

module top_tb;

  reg clk;
  reg rst;
  reg start;
  wire done;
  reg [3:0] row_a, col_b, k;
  integer err, i, row_offset;

  reg [`GBUFF_ADDR_SIZE-1:0] GOLDEN [`WORD_SIZE-1:0];
  always #(`CYCLE/2) clk = ~clk;

  top TOP(.clk(clk),
          .rst(rst),
          .start(start),
          .m(row_a),
          .k(k),
          .n(col_b),
          .done(done));

  initial begin
    $fsdbDumpfile("top.fsdb");
    $fsdbDumpvars("+struct", "+mda", TOP);
    $fsdbDumpMDA;
//----------------------------------------------------------------------------//
// Global Buffers Initialization                                              //
//----------------------------------------------------------------------------//
    clk = 0;  rst = 1; start = 0;
    #(`CYCLE) rst = 0; start = 1;
    row_a = `MATRIX_A_ROW; col_b = `MATRIX_B_COL; k = `MATRIX_A_COL;
    `ifdef test1
      $readmemb("build/input1/matrix_a.bin", TOP.GBUFF_A.gbuff);
      $readmemb("build/input1/matrix_b.bin", TOP.GBUFF_B.gbuff);
      $readmemb("build/input1/golden.bin", GOLDEN); 

    `elsif test2
      $readmemb("build/input2/matrix_a.bin", TOP.GBUFF_A.gbuff);
      $readmemb("build/input2/matrix_b.bin", TOP.GBUFF_B.gbuff);
      $readmemb("build/input2/golden.bin", GOLDEN);

    `elsif test3
      $readmemb("build/input3/matrix_a.bin", TOP.GBUFF_A.gbuff);
      $readmemb("build/input3/matrix_b.bin", TOP.GBUFF_B.gbuff);
      $readmemb("build/input3/golden.bin", GOLDEN);

    `elsif monster
      $readmemb("build/monster/matrix_a.bin", TOP.GBUFF_A.gbuff);
      $readmemb("build/monster/matrix_b.bin", TOP.GBUFF_B.gbuff);
      $readmemb("build/monster/golden.bin", GOLDEN);

    `else
      $readmemb("build/matrix_a.bin", TOP.GBUFF_A.gbuff);
      $readmemb("build/matrix_b.bin", TOP.GBUFF_B.gbuff);
      $readmemb("build/golden.bin", GOLDEN);  
    `endif
    //for (i = 0; i < `MATRIX_A_ROW*`MATRIX_B_COL/4; i=i+1) begin
    //  $display("%h %h %h %h",
    //    GOLDEN[i][7:0], GOLDEN[i][15:8], GOLDEN[i][23:16], GOLDEN[i][31:24]);
    //end
    row_offset = (`MATRIX_B_COL >= 9)? 3:
                 (`MATRIX_B_COL >= 5 && `MATRIX_B_COL < 9)? 2: 1;

    wait(done == 1);
    $display("\nSimulation Done.\n");


//----------------------------------------------------------------------------//
// Verify output global buffer with golden                                    //
//----------------------------------------------------------------------------//


/*
    err = 0;
    for (i = 0; i < `MATRIX_A_ROW * row_offset; i=i+1) begin
      // [7:0]
      if (GOLDEN[i][31:24] != TOP.GBUFF_OUT.gbuff[i][7:0]) begin
        $display("GBUFF_OUT[%2d][ 7: 0] = %2h, expect = %2h",
          i, TOP.GBUFF_OUT.gbuff[i][7:0], GOLDEN[i][31:24]);
        err = err + 1;
      end
      else begin
        $display("GBUFF_OUT[%2d][ 7: 0] = %2h, pass!",
          i, TOP.GBUFF_OUT.gbuff[i][7:0]);
      end
      // [15:8]
      if (GOLDEN[i][23:16] != TOP.GBUFF_OUT.gbuff[i][15:8]) begin
        $display("GBUFF_OUT[%2d][15: 8] = %2h, expect = %2h",
          i, TOP.GBUFF_OUT.gbuff[i][15:8], GOLDEN[i][23:16]);
        err = err + 1;
      end
      else begin
        $display("GBUFF_OUT[%2d][15: 8] = %2h, pass!",
          i, TOP.GBUFF_OUT.gbuff[i][15:8]);
      end
      // [23:16]
      if (GOLDEN[i][15:8] != TOP.GBUFF_OUT.gbuff[i][23:16]) begin
        $display("GBUFF_OUT[%2d][23:16] = %2h, expect = %2h",
          i, TOP.GBUFF_OUT.gbuff[i][23:16], GOLDEN[i][15:8]);
        err = err + 1;
      end
      else begin
        $display("GBUFF_OUT[%2d][23:16] = %2h, pass!",
          i, TOP.GBUFF_OUT.gbuff[i][23:16]);
      end
      // [31:24]
      if (GOLDEN[i][7:0] != TOP.GBUFF_OUT.gbuff[i][31:24]) begin
        $display("GBUFF_OUT[%2d][31:24] = %2h, expect = %2h",
          i, TOP.GBUFF_OUT.gbuff[i][31:24], GOLDEN[i][7:0]);
        err = err + 1;
      end
      else begin
        $display("GBUFF_OUT[%2d][31:24] = %2h, pass!",
          i, TOP.GBUFF_OUT.gbuff[i][31:24]);
      end

      //$display("%h %h %h %h",
      //  GOLDEN[i][7:0], GOLDEN[i][15:8], GOLDEN[i][23:16], GOLDEN[i][31:24]);
    end

    check_err(err);
    */
  end


//----------------------------------------------------------------------------//
// Maximum Simulation time                                                    //
//----------------------------------------------------------------------------//
  initial begin

    #(`CYCLE*`MAX)
    err = 0;
    for (i = 0; i < `MATRIX_A_ROW * row_offset; i=i+1) begin
      // [7:0]
      if (GOLDEN[i][31:24] != TOP.GBUFF_OUT.gbuff[i][7:0]) begin
        $display("GBUFF_OUT[%2d][ 7: 0] = %2h, expect = %2h",
          i, TOP.GBUFF_OUT.gbuff[i][7:0], GOLDEN[i][31:24]);
        err = err + 1;
      end
      else begin
        $display("GBUFF_OUT[%2d][ 7: 0] = %2h, pass!",
          i, TOP.GBUFF_OUT.gbuff[i][7:0]);
      end
      // [15:8]
      if (GOLDEN[i][23:16] != TOP.GBUFF_OUT.gbuff[i][15:8]) begin
        $display("GBUFF_OUT[%2d][15: 8] = %2h, expect = %2h",
          i, TOP.GBUFF_OUT.gbuff[i][15:8], GOLDEN[i][23:16]);
        err = err + 1;
      end
      else begin
        $display("GBUFF_OUT[%2d][15: 8] = %2h, pass!",
          i, TOP.GBUFF_OUT.gbuff[i][15:8]);
      end
      // [23:16]
      if (GOLDEN[i][15:8] != TOP.GBUFF_OUT.gbuff[i][23:16]) begin
        $display("GBUFF_OUT[%2d][23:16] = %2h, expect = %2h",
          i, TOP.GBUFF_OUT.gbuff[i][23:16], GOLDEN[i][15:8]);
        err = err + 1;
      end
      else begin
        $display("GBUFF_OUT[%2d][23:16] = %2h, pass!",
          i, TOP.GBUFF_OUT.gbuff[i][23:16]);
      end
      // [31:24]
      if (GOLDEN[i][7:0] != TOP.GBUFF_OUT.gbuff[i][31:24]) begin
        $display("GBUFF_OUT[%2d][31:24] = %2h, expect = %2h",
          i, TOP.GBUFF_OUT.gbuff[i][31:24], GOLDEN[i][7:0]);
        err = err + 1;
      end
      else begin
        $display("GBUFF_OUT[%2d][31:24] = %2h, pass!",
          i, TOP.GBUFF_OUT.gbuff[i][31:24]);
      end

    end
    $display ("\n************************");
    $display ("m=%2d, k=%2d, n=%2d\n", row_a, k, col_b);
    $display ("************************\n");
    check_err(err);
    $finish;
  end





//----------------------------------------------------------------------------//
// Task Declarations                                                          //
//----------------------------------------------------------------------------//
  task check_err;
    input integer err;


    if( err == 0 )
    begin
      $display("\n");
      $display("                                             / \\  //\\                      ");
      $display("                              |\\___/|      /   \\//  \\\\                   ");
      $display("                             /0  0  \\__  /    //  | \\ \\                   ");
      $display("                            /     /  \\/_/    //   |  \\  \\                 ");
      $display("                            @_^_@'/   \\/_   //    |   \\   \\               ");
      $display("                            //_^_/     \\/_ //     |    \\    \\             ");
      $display("                         ( //) |        \\///      |     \\     \\           ");
      $display("                        ( / /) _|_ /   )  //       |      \\     _\\         ");
      $display("                      ( // /) '/,_ _ _/  ( ; -.    |    _ _\\.-~        .-~~~^-.                      ");
      $display(" ********************(( / / )) ,-{        _      `-.|.-~-.            .~         `.                   ");
      $display(" **                   (( // / ))  '/\\      /                 ~-. _ .-~      .-~^-.  \                ");
      $display(" **  Congratulations!  (( /// ))      `.   {            }                    /      \  \              ");
      $display(" **  Simulation Passed!  (( / ))     .----~-.\\        \\-'                .~         \  `. \^-.      ");
      $display(" **                      **           ///.----..>        \\             _ -~             `.  ^-`  ^-_ ");
      $display(" **************************             ///-._ _ _ _ _ _ _}^ - - - -- ~                     ~-- ,.-~  ");
      $display("\n");
    end
    else
    begin
      $display("\n");
      $display(" **************************    __ __   ");
      $display(" **                      **   /--\\/ \\ ");
      $display(" **  Awwwww              **  |   /   | ");
      $display(" **  Simulation Failed!  **  |-    --| ");
      $display(" **                      **   \\__-*_/ ");
      $display(" **************************            ");
      $display(" Total %4d errors\n", err);
    end
  endtask


endmodule
