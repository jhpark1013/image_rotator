module sample_generator_testbench
  (
   // Declare some signals so we can see how I/O works
   input         clk,
   input         ResetN,
   input         En,

   output wire M_AXIS_tvalid,
   output wire M_AXIS_tready,
   output wire M_AXIS_tlast,
   output wire M_AXIS_tdata
   );


   reg counterR;
   assign M_AXIS_tdata = counterR;
   always_ff @(posedge Clk)
     if(!ResetN)
       counterR <= 0;
   	else begin
       if(M_AXIS_tvalid && M_AXIS_tready)
         if(M_AXIS_tlast)
           counterR <= 0;
       	else
           counterR<=counterR + 1;
     end

   reg sampleGeneratorEnableR;
   reg afterResetCycleCounterR;
   always_ff @(posedge Clk)
     if(!ResetN)begin
       afterResetCycleCounterR <= 0;
       sampleGeneratorEnableR <= 0;
     end
   	else begin
       afterResetCycleCounterR <= afterResetCycleCounterR+1;
       if(afterResetCycleCounterR == C_M_START_COUNT)
         sampleGeneratorEnableR <= 1;
     end

   reg tvalidR;
   assign M_AXIS_tvalid = tvalidR;
   always_ff @(posedge Clk)
     if(!ResetN)
       tvalidR <=0;
   	else begin
       if (!En)
         tvalidR<=0;
       else if(sampleGeneratorEnableR)
         tvalidR<=1;
     end

   reg [7:0] packetCounter;
   reg framesize_test;
   always_ff @(posedge Clk)
     if(!ResetN) begin
       packetCounter <= 8'hff;
       framesize_test <= 0;
     end
   	else begin
       if (M_AXIS_tlast) begin
         packetCounter <= 8'hff;
         framesize_test <= 0;
       end
       else begin
         packetCounter <= packetCounter + 1;
         framesize_test <= framesize_test+1;
       end
     end
       assign M_AXIS_tlast = (framesize_test == 6) ? 1 : 0;

   // Print some stuff as an example
   initial begin
      if ($test$plusargs("trace") != 0) begin
         $display("[%0t] Tracing to logs/vlt_dump.vcd...\n", $time);
         $dumpfile("logs/vlt_dump.vcd");
         $dumpvars();
      end
      $display("[%0t] Model running...\n", $time);
   end

endmodule
