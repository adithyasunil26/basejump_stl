`define WIDTH_P    4
`define OVERFLOW_P (2**(`WIDTH_P)-1)

`include "bsg_defines.v"

/**************************** TEST RATIONALE *******************************
1. STATE SPACE
  This test module tests the outputs of DUT for a complete count-cycle i.e., 
  from 0 to OVERFLOW_P and 0 (restarts after overflow). Since the number of 
  unique counts becomes very large as WIDTH_P increases ( 2**(WIDTH_P) 
  possible counts), the test input, OVERFLOW_P, is defined as a macro which can 
  be varied in the Makefile. If the OVERFLOW_P is more than 2**WIDTH_P the 
  simulation simply finishes doing nothing.
2. PARAMETERIZATION
  Since the DUT implements an algorithm that simply increments or decrements 
  the count an arbitrary set of tests that include that include the edge cases 
  would do the job. So a minimum set of tests might be WIDTH_P=1,2,3,4,8 and 
  OVERFLOW_P=1,2,3,4,8. Time taken to complete a test grows exponentially with 
  WIDTH_P, simulation with large WIDTH_P value takes long to finish.  
  
***************************************************************************/

module testbench 
#(parameter width_p=`WIDTH_P,
  parameter cycle_time_p=20,
  parameter overflow_p=`OVERFLOW_P
  );
  
  wire clk;
  wire reset;
  
  `ifdef VERILATOR
    bsg_nonsynth_dpi_clock_gen
  `else
    bsg_nonsynth_clock_gen
  `endif
   #(.cycle_time_p(cycle_time_p))
   clock_gen
    (.o(clk));
    
  bsg_nonsynth_reset_gen #(  .num_clocks_p     (1)
                           , .reset_cycles_lo_p(1)
                           , .reset_cycles_hi_p(5)
                          )  reset_gen
                          (  .clk_i        (clk)
                           , .async_reset_o(reset)
                          );

  initial
  begin
    $display(  "\n\n\n"
             , "============================================================\n"
             , "testing with ...\n"
             , "WIDTH_P   : %d\n", width_p
             , "OVERFLOW_P: %d\n", overflow_p
            );
    
    assert(overflow_p < 2**width_p)
      else
        begin
          $display("skipping the test due to incompatible parameters\n");
          $display("=========================================================\n");
          $finish;
        end
  end
                                        
  logic [width_p-1:0] test_input, test_output, prev_count, count;
  logic [`BSG_SAFE_CLOG2(overflow_p+1)-1:0] circular_ptr;
  logic finish_r;
  
  assign test_input = overflow_p;
  
  bsg_circular_ptr #(  .slots_p     (overflow_p+1)
                     , .max_add_p   (1)
                     , .ptr_width_lp()
                    )  c_ptr
                    (  .clk    (clk)
                     , .reset_i(reset)
                     , .add_i  (1'b1)
                     , .o      (circular_ptr)
                    );
                                     
  assign count = width_p ' (circular_ptr);
                                     
  always_ff @(posedge clk)
  begin
    prev_count <= count;

    //$display("count: %d, test_output: %d\n", count, test_output); ///////////////////////////
    if(!reset)
      assert (count == test_output)
        else $error("error on count %x", count);
    
    if(~(|count) & (prev_count == overflow_p))
      finish_r <= 1;
    if(finish_r)
      begin
        $display("==============================================================\n");
        $finish;
      end
  end
                                        
  bsg_counter_dynamic_limit #(  .width_p(width_p)
                      )  DUT
                      (  .clk_i       (clk)
                       , .reset_i     (reset)
                       , .limit_i(test_input)
                       , .counter_o (test_output)
                      );
                                                 
  /*bsg_nonsynth_ascii_writer #(  .width_p      (width_p)
                              , .values_p     (3)
                              , .filename_p   ("output.log")
                              , .fopen_param_p("a+")
                              , .format_p     ("%b")
                             )  ascii_writer
                             (  .clk    (clk)
                              , .reset_i(reset)
                              , .valid_i(1'b1)
                              , .data_i ({test_output,
                                          count,
                                          test_input}
                                        )
                             );*/

endmodule
