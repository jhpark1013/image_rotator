module top
  (
   // Declare some signals so we can see how I/O works
   input         Clk,
   input         ResetN,

   output wire  M_AXIS_tvalid,
   output wire  M_AXIS_tready,
   output wire M_AXIS_tlast,
  output wire [39:0] M_AXIS_tdata,

//  input[1:0] in_small,
  input [39:0] in_quad
   );

   assign M_AXIS_tvalid = 1'd0; //~ResetN ? '0 :  1'b1;
   assign M_AXIS_tready = 1'd1; //~ResetN ? '0 : 1'b1;
   assign M_AXIS_tlast = 1'd0; //~ResetN ? '0 : 0'b1;
   assign M_AXIS_tdata = ~ResetN ? '0 : (in_quad + 40'b1);

   reg [39:0] counterR;
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

   reg sampleGeneratorEnableR = 1'd0;
   reg [7:0] afterResetCycleCounterR = 8'h1;
   reg [7:0] C_M_START_COUNT = 8'h8;
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

   reg tvalidR = 0'd0;
   reg En = 1'd1;
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
  assign M_AXIS_tlast = (packetCounter == 6) ? 1 : 0;

  ///////////////////////////////////////////////////////
  always @(posedge Clk)
  	if ( ! ResetL ) begin
  		pixelBuffer_writeEnable <= 0;
  		pixelBuffer_writeAddress <= 0;
  		pixelBuffer_writeData <= 0;
  	end
  	else begin
  		if ( axiFSM_currentState == `AXI_FSM_IDLE ) begin
  			pixelBuffer_writeEnable <= 0;
  			pixelBuffer_writeAddress <= 0;
  			pixelBuffer_writeData <= 0;
  		end
  		else if ( axiFSM_currentState == `AXI_FSM_SEND_READ_REQUEST1 ) begin
  			pixelBuffer_writeEnable <= 0;
  			case ( RotationType )
  				`ROTATION_CMD_COPY: begin
  					pixelBuffer_writeAddress <= axiFSM_readRequestCounter * `IMAGE_BLOCK_SIZE/4 - 1;
  				end
  				`ROTATION_CMD_HORIZ_FLIP: begin
  					pixelBuffer_writeAddress <= axiFSM_readRequestCounter * `IMAGE_BLOCK_SIZE/4 - 1;
  				end
  				`ROTATION_CMD_VERT_FLIP: begin
  					pixelBuffer_writeAddress <= axiFSM_readRequestCounter * `IMAGE_BLOCK_SIZE/4 - 1;
  				end
  				`ROTATION_CMD_CLOCK_WISE: begin
  					pixelBuffer_writeAddress <= axiFSM_readRequestCounter - `IMAGE_BLOCK_SIZE;
  				end
  				`ROTATION_CMD_COUNTER_CLOCK_WISE: begin
  					pixelBuffer_writeAddress <= axiFSM_readRequestCounter - `IMAGE_BLOCK_SIZE;
  				end
  				endcase
  			pixelBuffer_writeData <= 0;
  		end
  		else if ( axiFSM_currentState == `AXI_FSM_WAIT_FOR_READ_CMPLT1 ) begin
  			if ( ! bus2ip_mstrd_src_rdy_n ) begin
  				pixelBuffer_writeEnable <= 1;

  				case ( RotationType )
  					`ROTATION_CMD_COPY: begin
  						pixelBuffer_writeAddress <= pixelBuffer_writeAddress + 1;
  					end
  					`ROTATION_CMD_HORIZ_FLIP: begin
  						pixelBuffer_writeAddress <= pixelBuffer_writeAddress + 1;
  					end
  					`ROTATION_CMD_VERT_FLIP: begin
  						pixelBuffer_writeAddress <= pixelBuffer_writeAddress + 1;
  					end
  					`ROTATION_CMD_CLOCK_WISE: begin
  						pixelBuffer_writeAddress <= pixelBuffer_writeAddress + `IMAGE_BLOCK_SIZE;
  					end
  					`ROTATION_CMD_COUNTER_CLOCK_WISE: begin
  						pixelBuffer_writeAddress <= pixelBuffer_writeAddress + `IMAGE_BLOCK_SIZE;
  					end
  				endcase

  				pixelBuffer_writeData <= bus2ip_mstrd_d;
  			end
  			else begin
  				pixelBuffer_writeEnable <= 0;
  				pixelBuffer_writeAddress <= pixelBuffer_writeAddress;
  				pixelBuffer_writeData <= 0;
  			end
  		end
  		else begin
  			pixelBuffer_writeEnable <= 0;
  			pixelBuffer_writeAddress <= pixelBuffer_writeAddress;
  			pixelBuffer_writeData <= 0;
  		end
  	end

  //////////////////////////////////////////////////////
  //
  // output data
  //
  //////////////////////////////////////////////////////
  // default block size is 120 x 120 pixels, 14400 pixels
  // generate suitable read address and config signals for reading the data back from the dual port memory.

  always @(posedge Clk)
  	if ( ! ResetL ) begin
  		pixelBuffer_readAddress <= 0;
  		pixelBuffer_readDataSelect <= 0;
  		pixelBuffer_readDataOrder <= 0;
  // 		pixelBuffer_readAddress_subCounter <= 0;
  	end
  	else begin
  		if ( axiFSM_currentState == `AXI_FSM_IDLE ) begin
  			pixelBuffer_readAddress <= 0;
  			pixelBuffer_readDataSelect <= 0;
  			pixelBuffer_readDataOrder <= 0;
  // 			pixelBuffer_readAddress_subCounter <= 0;
  		end
  		else if ( ( axiFSM_prevState == `AXI_FSM_WAIT_FOR_WRITE_ACK1 ) && bus2ip_mst_cmdack) begin
  			case ( RotationType )
  				`ROTATION_CMD_COPY: begin
  					pixelBuffer_readAddress <= axiFSM_writeRequestCounter * ((`IMAGE_BLOCK_SIZE/4)/4) + axiFSM_writeRequestCounter/2;

  // 					if ( axiFSM_writeRequestCounter[0] ) 			// for odd values of axiFSM_writeRequestCounter, pixelBuffer_readAddress_subCounter begins from 2
  // 						pixelBuffer_readAddress_subCounter <= 2;
  // 					else
  // 						pixelBuffer_readAddress_subCounter <= 0; 	// for even values, it begins from zero

  					pixelBuffer_readDataSelect <= 4'hf;
  					pixelBuffer_readDataOrder <= 0;
  				end
  				`ROTATION_CMD_HORIZ_FLIP: begin
  					pixelBuffer_readAddress <= axiFSM_writeRequestCounter * ((`IMAGE_BLOCK_SIZE/4)/4) + axiFSM_writeRequestCounter/2 + ((`IMAGE_BLOCK_SIZE/4)/4);

  // 					if ( axiFSM_writeRequestCounter[0] ) 			// for odd values of axiFSM_writeRequestCounter, pixelBuffer_readAddress_subCounter begins from 2
  // 						pixelBuffer_readAddress_subCounter <= 3;
  // 					else
  // 						pixelBuffer_readAddress_subCounter <= 1; 	// for even values, it begins from zero

  					pixelBuffer_readDataSelect <= 4'hf;
  					pixelBuffer_readDataOrder <= 1;		// put the pixels out in the reverse order
  				end
  				`ROTATION_CMD_VERT_FLIP: begin
  					pixelBuffer_readAddress <= ((`IMAGE_BLOCK_SIZE-1)-axiFSM_writeRequestCounter) * ((`IMAGE_BLOCK_SIZE/4)/4) + ((`IMAGE_BLOCK_SIZE-1)-axiFSM_writeRequestCounter) / 2;

  // 					if ( axiFSM_writeRequestCounter[0] ) 			// for odd values of axiFSM_writeRequestCounter, pixelBuffer_readAddress_subCounter begins from 2
  // 						pixelBuffer_readAddress_subCounter <= 0;
  // 					else
  // 						pixelBuffer_readAddress_subCounter <= 2; 	// for even values, it begins from zero

  					pixelBuffer_readDataSelect <= 4'hf;
  					pixelBuffer_readDataOrder <= 0;		// put the pixels out in the reverse order
  				end
  				`ROTATION_CMD_CLOCK_WISE: begin
  					pixelBuffer_readAddress <= (`IMAGE_BLOCK_SIZE/4) * axiFSM_writeRequestCounter[7:2] + (`IMAGE_BLOCK_SIZE/4-1);

  					if ( axiFSM_writeRequestCounter[1:0] == 0 )
  						pixelBuffer_readDataSelect <= 4'h1;
  					else if ( axiFSM_writeRequestCounter[1:0] == 1 )
  						pixelBuffer_readDataSelect <= 4'h2;
  					else if ( axiFSM_writeRequestCounter[1:0] == 2 )
  						pixelBuffer_readDataSelect <= 4'h4;
  					else
  						pixelBuffer_readDataSelect <= 4'h8;

  					pixelBuffer_readDataOrder <= 1;		// put the pixels out in the reverse order
  // 					pixelBuffer_readAddress_subCounter <= 0;
  				end
  				`ROTATION_CMD_COUNTER_CLOCK_WISE: begin
  					pixelBuffer_readAddress <= (`IMAGE_BLOCK_SIZE/4 - axiFSM_writeRequestCounter[7:2] - 1) * `IMAGE_BLOCK_SIZE/4;

  					if ( axiFSM_writeRequestCounter[1:0] == 0 )
  						pixelBuffer_readDataSelect <= 4'h8;
  					else if ( axiFSM_writeRequestCounter[1:0] == 1 )
  						pixelBuffer_readDataSelect <= 4'h4;
  					else if ( axiFSM_writeRequestCounter[1:0] == 2 )
  						pixelBuffer_readDataSelect <= 4'h2;
  					else
  						pixelBuffer_readDataSelect <= 4'h1;

  					pixelBuffer_readDataOrder <= 0;		// put the pixels out in the reverse order
  // 					pixelBuffer_readAddress_subCounter <= 0;
  				end
  			endcase
  		end
  		else if ( pixelBuffer_readEnable && (! ( ( axiFSM_prevState == `AXI_FSM_WAIT_FOR_WRITE_ACK1 ) && ( axiFSM_currentState == `AXI_FSM_WAIT_FOR_WRITE_CMPLT1 ) ) ) ) begin 	// for the first read enable, dont update the address , it is already updated !
  			case ( RotationType )
  				`ROTATION_CMD_COPY: begin
  					if ( pixelBuffer_readAddress_subCounter == 2 ) begin
  // 						pixelBuffer_readAddress_subCounter <= 0;
  						pixelBuffer_readAddress <= pixelBuffer_readAddress + 1;
  					end
  					else begin
  // 						pixelBuffer_readAddress_subCounter <= pixelBuffer_readAddress_subCounter + 1;
  						pixelBuffer_readAddress <= pixelBuffer_readAddress;
  					end
  					pixelBuffer_readDataSelect <= 4'hf;
  					pixelBuffer_readDataOrder <= 0;
  				end
  				`ROTATION_CMD_HORIZ_FLIP: begin
  					if ( pixelBuffer_readAddress_subCounter == 1 ) begin 			// consider one clock cycle latency of reads from bram
  // 						pixelBuffer_readAddress_subCounter <= 3;
  						pixelBuffer_readAddress <= pixelBuffer_readAddress - 1;
  					end
  					else begin
  // 						pixelBuffer_readAddress_subCounter <= pixelBuffer_readAddress_subCounter - 1;
  						pixelBuffer_readAddress <= pixelBuffer_readAddress;
  					end
  					pixelBuffer_readDataSelect <= 4'hf;
  					pixelBuffer_readDataOrder <= 1;		// put the pixels out in the reverse order
  				end
  				`ROTATION_CMD_VERT_FLIP: begin
  					if ( pixelBuffer_readAddress_subCounter == 2 ) begin
  // 						pixelBuffer_readAddress_subCounter <= 0;
  						pixelBuffer_readAddress <= pixelBuffer_readAddress + 1;
  					end
  					else begin
  // 						pixelBuffer_readAddress_subCounter <= pixelBuffer_readAddress_subCounter + 1;
  						pixelBuffer_readAddress <= pixelBuffer_readAddress;
  					end
  					pixelBuffer_readDataSelect <= 4'hf;
  					pixelBuffer_readDataOrder <= 0;		// put the pixels out in the reverse order
  				end
  				`ROTATION_CMD_CLOCK_WISE: begin
  					pixelBuffer_readAddress <= pixelBuffer_readAddress - 1;
  // 					pixelBuffer_readAddress_subCounter <= 0;

  					if ( axiFSM_writeRequestCounter[1:0] == 0 )
  						pixelBuffer_readDataSelect <= 4'h1;
  					else if ( axiFSM_writeRequestCounter[1:0] == 1 )
  						pixelBuffer_readDataSelect <= 4'h2;
  					else if ( axiFSM_writeRequestCounter[1:0] == 2 )
  						pixelBuffer_readDataSelect <= 4'h4;
  					else
  						pixelBuffer_readDataSelect <= 4'h8;

  					pixelBuffer_readDataOrder <= 1;		// put the pixels out in the reverse order
  				end
  				`ROTATION_CMD_COUNTER_CLOCK_WISE: begin
  					pixelBuffer_readAddress <= pixelBuffer_readAddress + 1;
  // 					pixelBuffer_readAddress_subCounter <= 0;

  					if ( axiFSM_writeRequestCounter[1:0] == 0 )
  						pixelBuffer_readDataSelect <= 4'h8;
  					else if ( axiFSM_writeRequestCounter[1:0] == 1 )
  						pixelBuffer_readDataSelect <= 4'h4;
  					else if ( axiFSM_writeRequestCounter[1:0] == 2 )
  						pixelBuffer_readDataSelect <= 4'h2;
  					else
  						pixelBuffer_readDataSelect <= 4'h1;

  					pixelBuffer_readDataOrder <= 0;		// put the pixels out in the reverse order
  				end
  			endcase
  		end
  		else begin
  			pixelBuffer_readAddress <= pixelBuffer_readAddress;
  // 			pixelBuffer_readAddress_subCounter <= pixelBuffer_readAddress_subCounter;
  			pixelBuffer_readDataSelect <= pixelBuffer_readDataSelect;
  			pixelBuffer_readDataOrder <= pixelBuffer_readDataOrder;
  		end
  	end


  ////////////////////////////////////////////////////////////////////////////////////////////////////////////
  //
  // read address sub counter
  //
  /////////////////////////////////////////////////////////////////////////////////////////////////////////////
  // always block to generate pixelBuffer_readAddress_subCounter

  always @(posedge Clk)
  	if ( ! ResetL ) begin
  		pixelBuffer_readAddress_subCounter <= 0;
  	end
  	else begin
  		if ( axiFSM_currentState == `AXI_FSM_IDLE ) begin
  			pixelBuffer_readAddress_subCounter <= 0;
  		end
  		else if ( ( axiFSM_prevState == `AXI_FSM_WAIT_FOR_WRITE_ACK1 ) && bus2ip_mst_cmdack) begin
  			case ( RotationType )
  				`ROTATION_CMD_COPY: begin
  					if ( axiFSM_writeRequestCounter[0] )
  						pixelBuffer_readAddress_subCounter <= 2;
  					else
  						pixelBuffer_readAddress_subCounter <= 0;
  				end
  				`ROTATION_CMD_HORIZ_FLIP: begin
  					if ( axiFSM_writeRequestCounter[0] )
  						pixelBuffer_readAddress_subCounter <= 3;
  					else
  						pixelBuffer_readAddress_subCounter <= 1;
  				end
  				`ROTATION_CMD_VERT_FLIP: begin
  					if ( axiFSM_writeRequestCounter[0] )
  						pixelBuffer_readAddress_subCounter <= 0;
  					else
  						pixelBuffer_readAddress_subCounter <= 2;
  				end
  				`ROTATION_CMD_CLOCK_WISE: begin
  					pixelBuffer_readAddress_subCounter <= 0;
  				end
  				`ROTATION_CMD_COUNTER_CLOCK_WISE: begin
  					pixelBuffer_readAddress_subCounter <= 0;
  				end
  			endcase
  		end
  		else if ( ( ! ip2bus_mstwr_src_rdy_n ) && ( ! bus2ip_mstwr_dst_rdy_n ) ) begin
  			case ( RotationType )
  				`ROTATION_CMD_COPY: begin
  					if ( pixelBuffer_readAddress_subCounter == 3 ) begin
  						pixelBuffer_readAddress_subCounter <= 0;
  					end
  					else begin
  						pixelBuffer_readAddress_subCounter <= pixelBuffer_readAddress_subCounter + 1;
  					end
  				end
  				`ROTATION_CMD_HORIZ_FLIP: begin
  					if ( pixelBuffer_readAddress_subCounter == 0 ) begin
  						pixelBuffer_readAddress_subCounter <= 3;
  					end
  					else begin
  						pixelBuffer_readAddress_subCounter <= pixelBuffer_readAddress_subCounter - 1;
  					end
  				end
  				`ROTATION_CMD_VERT_FLIP: begin
  					if ( pixelBuffer_readAddress_subCounter == 3 ) begin
  						pixelBuffer_readAddress_subCounter <= 0;
  					end
  					else begin
  						pixelBuffer_readAddress_subCounter <= pixelBuffer_readAddress_subCounter + 1;
  					end
  				end
  				`ROTATION_CMD_CLOCK_WISE: begin
  					pixelBuffer_readAddress_subCounter <= 0;
  				end
  				`ROTATION_CMD_COUNTER_CLOCK_WISE: begin
  					pixelBuffer_readAddress_subCounter <= 0;
  				end
  			endcase
  		end
  		else begin
  			pixelBuffer_readAddress_subCounter <= pixelBuffer_readAddress_subCounter;
  		end
  	end

  // register readEnable, dataselect and data order and subcounter since the block memory has a latency of one clock cycle
  // and then it provided the data for a specific input address
  // you need the above values to put the data out to the axi master plug

  reg 		pixelBuffer_readEnableR;
  reg	[3:0]	pixelBuffer_readDataSelectR;
  reg		pixelBuffer_readDataOrderR;
  reg 	[1:0]	pixelBuffer_readAddress_subCounterR;
  // reg 	[13:0]	dataSendCounterR;

  always @(posedge Clk)
  	if ( ! ResetL ) begin
  		pixelBuffer_readEnableR <= 0;
  		pixelBuffer_readDataSelectR <= 0;
  		pixelBuffer_readDataOrderR <= 0;
  		pixelBuffer_readAddress_subCounterR <= 0;
  // 		dataSendCounterR <= 0;
  	end
  	else begin
  		pixelBuffer_readEnableR <= pixelBuffer_readEnable;
  		pixelBuffer_readDataSelectR <= pixelBuffer_readDataSelect;
  		pixelBuffer_readDataOrderR <= pixelBuffer_readDataOrder;
  		pixelBuffer_readAddress_subCounterR <= pixelBuffer_readAddress_subCounter;
  // 		dataSendCounterR <= dataSendCounter;
  	end

  //////////////////////////////////////////////////////////////////////////////////////////
  //
  // pixel buffer read enable
  //
  //////////////////////////////////////////////////////////////////////////////////////////

  assign pixelBuffer_readEnable = ( ( axiFSM_prevState == `AXI_FSM_WAIT_FOR_WRITE_ACK1 ) && ( axiFSM_currentState == `AXI_FSM_WAIT_FOR_WRITE_CMPLT1 ) ) ? 1'b1 :
  				( ( ! ip2bus_mstwr_src_rdy_n ) && ( ! bus2ip_mstwr_dst_rdy_n ) && (burstCounter < (burstLength-1) ) ) ? 1'b1 : 0;

  //////////////////////////////////////////////////////////////////////////////////////////
  //
  // wirte burst counter
  //
  //////////////////////////////////////////////////////////////////////////////////////////
  // generate signals to axi master block
  wire 	[7:0]	burstLength;
  reg 	[7:0]	burstCounter;

  assign burstLength = ip2bus_mst_length / (PIXEL_WIDTH*4/8);


  always @(posedge Clk)
  	if ( ! ResetL ) begin
  		burstCounter <= 0;
  	end
  	else begin
  		if ( ( axiFSM_prevState == `AXI_FSM_WAIT_FOR_WRITE_ACK1 ) && ( axiFSM_currentState == `AXI_FSM_WAIT_FOR_WRITE_CMPLT1 ) ) begin
  			burstCounter <= 0;
  		end
  		else if ( ( ! ip2bus_mstwr_src_rdy_n ) && ( ! bus2ip_mstwr_dst_rdy_n ) ) begin
  			burstCounter <= burstCounter + 1;
  		end
  		else begin
  			burstCounter <= burstCounter;
  		end
  	end

  //////////////////////////////////////////////////////////////////////////////////////////
  //
  // ip2bus_mstwr_src_rdy_n
  //
  //////////////////////////////////////////////////////////////////////////////////////////
  // source ready signal. goes down in the beginning of data transfer and comes up at its end.

  always @(posedge Clk)
  	if ( ! ResetL ) begin
  		ip2bus_mstwr_src_rdy_n <= 1;
  	end
  	else begin
  		if ( axiFSM_currentState == `AXI_FSM_IDLE ) begin
  			ip2bus_mstwr_src_rdy_n <= 1;
  		end
  		else if ( ( axiFSM_currentState == `AXI_FSM_WAIT_FOR_WRITE_CMPLT1 ) ) begin
  			if ( ( ! ip2bus_mstwr_src_rdy_n ) && ( ! bus2ip_mstwr_dst_rdy_n ) && ( burstCounter == (burstLength-1) ) ) begin
  				ip2bus_mstwr_src_rdy_n <= 1;
  			end
  			else if ( pixelBuffer_readEnableR && (burstCounter == 0) ) begin
  				ip2bus_mstwr_src_rdy_n <= 0;
  			end
  			else begin
  				ip2bus_mstwr_src_rdy_n <= ip2bus_mstwr_src_rdy_n;
  			end
  		end
  	end

  //////////////////////////////////////////////////////////////////////////////////////////
  //
  // write start of frame
  //
  //////////////////////////////////////////////////////////////////////////////////////////

  always @(posedge Clk)
  	if ( ! ResetL ) begin
  		ip2bus_mstwr_sof_n <= 1;
  	end
  	else begin
  		if ( axiFSM_currentState == `AXI_FSM_IDLE ) begin
  			ip2bus_mstwr_sof_n <= 1;
  		end
  		else if ( ( axiFSM_currentState == `AXI_FSM_WAIT_FOR_WRITE_CMPLT1 ) ) begin
  			if ( ( ! ip2bus_mstwr_src_rdy_n ) && ( ! bus2ip_mstwr_dst_rdy_n ) ) begin
  				ip2bus_mstwr_sof_n <= 1;
  			end
  			else if ( pixelBuffer_readEnableR && (burstCounter == 0) ) begin
  				ip2bus_mstwr_sof_n <= 0;
  			end
  			else
  				ip2bus_mstwr_sof_n <= ip2bus_mstwr_sof_n;
  		end
  		else begin
  			ip2bus_mstwr_sof_n <= ip2bus_mstwr_sof_n;
  		end
  	end

  //////////////////////////////////////////////////////////////////////////////////////////
  //
  // write end of frame
  //
  //////////////////////////////////////////////////////////////////////////////////////////

  always @(posedge Clk)
  	if ( ! ResetL ) begin
  		ip2bus_mstwr_eof_n <= 1;
  	end
  	else begin
  		if ( axiFSM_currentState == `AXI_FSM_IDLE ) begin
  			ip2bus_mstwr_eof_n <= 1;
  		end
  		else if ( ( axiFSM_currentState == `AXI_FSM_WAIT_FOR_WRITE_CMPLT1 ) ) begin
  			if ( ( ! ip2bus_mstwr_src_rdy_n ) && ( ! bus2ip_mstwr_dst_rdy_n ) && ( burstCounter == (burstLength-2) ) )
  				ip2bus_mstwr_eof_n <= 0;
  			else if ( ( ! ip2bus_mstwr_src_rdy_n ) && ( ! bus2ip_mstwr_dst_rdy_n ) )
  				ip2bus_mstwr_eof_n <= 1;
  			else
  				ip2bus_mstwr_eof_n <= ip2bus_mstwr_eof_n;
  		end
  		else begin
  			ip2bus_mstwr_eof_n <= ip2bus_mstwr_eof_n;
  		end
  	end

  //////////////////////////////////////////////////////////////////////////////////////////
  //
  // write start of frame and end of frame and data
  //
  //////////////////////////////////////////////////////////////////////////////////////////

  assign ip2bus_mstwr_d = ( ( pixelBuffer_readDataSelect == 4'h1 ) && ( pixelBuffer_readDataOrder == 0 ) ) ? ({ pixelBuffer_readData_0[(PIXEL_WIDTH*4-1):(PIXEL_WIDTH*3)], pixelBuffer_readData_0[(PIXEL_WIDTH*3-1):(PIXEL_WIDTH*2)], pixelBuffer_readData_0[(PIXEL_WIDTH*2-1):PIXEL_WIDTH], pixelBuffer_readData_0[(PIXEL_WIDTH-1):0]  }) :
  			( ( pixelBuffer_readDataSelect == 4'h1 ) && ( pixelBuffer_readDataOrder == 1 ) ) ? ({ pixelBuffer_readData_0[(PIXEL_WIDTH-1):0],  pixelBuffer_readData_0[(PIXEL_WIDTH*2-1):PIXEL_WIDTH], pixelBuffer_readData_0[(PIXEL_WIDTH*3-1):(PIXEL_WIDTH*2)], pixelBuffer_readData_0[(PIXEL_WIDTH*4-1):(PIXEL_WIDTH*3)] }) :
  			( ( pixelBuffer_readDataSelect == 4'h2 ) && ( pixelBuffer_readDataOrder == 0 ) ) ? ({ pixelBuffer_readData_1[(PIXEL_WIDTH*4-1):(PIXEL_WIDTH*3)], pixelBuffer_readData_1[(PIXEL_WIDTH*3-1):(PIXEL_WIDTH*2)], pixelBuffer_readData_1[(PIXEL_WIDTH*2-1):PIXEL_WIDTH], pixelBuffer_readData_1[(PIXEL_WIDTH-1):0]  }) :
  			( ( pixelBuffer_readDataSelect == 4'h2 ) && ( pixelBuffer_readDataOrder == 1 ) ) ? ({ pixelBuffer_readData_1[(PIXEL_WIDTH-1):0],  pixelBuffer_readData_1[(PIXEL_WIDTH*2-1):PIXEL_WIDTH], pixelBuffer_readData_1[(PIXEL_WIDTH*3-1):(PIXEL_WIDTH*2)], pixelBuffer_readData_1[(PIXEL_WIDTH*4-1):(PIXEL_WIDTH*3)] }) :
  			( ( pixelBuffer_readDataSelect == 4'h4 ) && ( pixelBuffer_readDataOrder == 0 ) ) ? ({ pixelBuffer_readData_2[(PIXEL_WIDTH*4-1):(PIXEL_WIDTH*3)], pixelBuffer_readData_2[(PIXEL_WIDTH*3-1):(PIXEL_WIDTH*2)], pixelBuffer_readData_2[(PIXEL_WIDTH*2-1):PIXEL_WIDTH], pixelBuffer_readData_2[(PIXEL_WIDTH-1):0]  }) :
  			( ( pixelBuffer_readDataSelect == 4'h4 ) && ( pixelBuffer_readDataOrder == 1 ) ) ? ({ pixelBuffer_readData_2[(PIXEL_WIDTH-1):0],  pixelBuffer_readData_2[(PIXEL_WIDTH*2-1):PIXEL_WIDTH], pixelBuffer_readData_2[(PIXEL_WIDTH*3-1):(PIXEL_WIDTH*2)], pixelBuffer_readData_2[(PIXEL_WIDTH*4-1):(PIXEL_WIDTH*3)] }) :
  			( ( pixelBuffer_readDataSelect == 4'h8 ) && ( pixelBuffer_readDataOrder == 0 ) ) ? ({ pixelBuffer_readData_3[(PIXEL_WIDTH*4-1):(PIXEL_WIDTH*3)], pixelBuffer_readData_3[(PIXEL_WIDTH*3-1):(PIXEL_WIDTH*2)], pixelBuffer_readData_3[(PIXEL_WIDTH*2-1):PIXEL_WIDTH], pixelBuffer_readData_3[(PIXEL_WIDTH-1):0]  }) :
  			( ( pixelBuffer_readDataSelect == 4'h8 ) && ( pixelBuffer_readDataOrder == 1 ) ) ? ({ pixelBuffer_readData_3[(PIXEL_WIDTH-1):0],  pixelBuffer_readData_3[(PIXEL_WIDTH*2-1):PIXEL_WIDTH], pixelBuffer_readData_3[(PIXEL_WIDTH*3-1):(PIXEL_WIDTH*2)], pixelBuffer_readData_3[(PIXEL_WIDTH*4-1):(PIXEL_WIDTH*3)] }) :

  			( (pixelBuffer_readDataSelect == 4'hf) && (pixelBuffer_readAddress_subCounter == 0) && ( pixelBuffer_readDataOrder == 0 ) ) ? ({ pixelBuffer_readData_3[(PIXEL_WIDTH-1):0],  pixelBuffer_readData_2[(PIXEL_WIDTH-1):0],  pixelBuffer_readData_1[(PIXEL_WIDTH-1):0],  pixelBuffer_readData_0[(PIXEL_WIDTH-1):0]}) :
  			( (pixelBuffer_readDataSelect == 4'hf) && (pixelBuffer_readAddress_subCounter == 0) && ( pixelBuffer_readDataOrder == 1 ) ) ? ({ pixelBuffer_readData_0[(PIXEL_WIDTH-1):0],  pixelBuffer_readData_1[(PIXEL_WIDTH-1):0],  pixelBuffer_readData_2[(PIXEL_WIDTH-1):0],  pixelBuffer_readData_3[(PIXEL_WIDTH-1):0]}) :
  			( (pixelBuffer_readDataSelect == 4'hf) && (pixelBuffer_readAddress_subCounter == 1) && ( pixelBuffer_readDataOrder == 0 ) ) ? ({ pixelBuffer_readData_3[(PIXEL_WIDTH*2-1):PIXEL_WIDTH], pixelBuffer_readData_2[(PIXEL_WIDTH*2-1):PIXEL_WIDTH], pixelBuffer_readData_1[(PIXEL_WIDTH*2-1):PIXEL_WIDTH], pixelBuffer_readData_0[(PIXEL_WIDTH*2-1):PIXEL_WIDTH]}) :
  			( (pixelBuffer_readDataSelect == 4'hf) && (pixelBuffer_readAddress_subCounter == 1) && ( pixelBuffer_readDataOrder == 1 ) ) ? ({ pixelBuffer_readData_0[(PIXEL_WIDTH*2-1):PIXEL_WIDTH], pixelBuffer_readData_1[(PIXEL_WIDTH*2-1):PIXEL_WIDTH], pixelBuffer_readData_2[(PIXEL_WIDTH*2-1):PIXEL_WIDTH], pixelBuffer_readData_3[(PIXEL_WIDTH*2-1):PIXEL_WIDTH]}) :
  			( (pixelBuffer_readDataSelect == 4'hf) && (pixelBuffer_readAddress_subCounter == 2) && ( pixelBuffer_readDataOrder == 0 ) ) ? ({ pixelBuffer_readData_3[(PIXEL_WIDTH*3-1):(PIXEL_WIDTH*2)], pixelBuffer_readData_2[(PIXEL_WIDTH*3-1):(PIXEL_WIDTH*2)], pixelBuffer_readData_1[(PIXEL_WIDTH*3-1):(PIXEL_WIDTH*2)], pixelBuffer_readData_0[(PIXEL_WIDTH*3-1):(PIXEL_WIDTH*2)]}) :
  			( (pixelBuffer_readDataSelect == 4'hf) && (pixelBuffer_readAddress_subCounter == 2) && ( pixelBuffer_readDataOrder == 1 ) ) ? ({ pixelBuffer_readData_0[(PIXEL_WIDTH*3-1):(PIXEL_WIDTH*2)], pixelBuffer_readData_1[(PIXEL_WIDTH*3-1):(PIXEL_WIDTH*2)], pixelBuffer_readData_2[(PIXEL_WIDTH*3-1):(PIXEL_WIDTH*2)], pixelBuffer_readData_3[(PIXEL_WIDTH*3-1):(PIXEL_WIDTH*2)]}) :
  			( (pixelBuffer_readDataSelect == 4'hf) && (pixelBuffer_readAddress_subCounter == 3) && ( pixelBuffer_readDataOrder == 0 ) ) ? ({ pixelBuffer_readData_3[(PIXEL_WIDTH*4-1):(PIXEL_WIDTH*3)], pixelBuffer_readData_2[(PIXEL_WIDTH*4-1):(PIXEL_WIDTH*3)], pixelBuffer_readData_1[(PIXEL_WIDTH*4-1):(PIXEL_WIDTH*3)], pixelBuffer_readData_0[(PIXEL_WIDTH*4-1):(PIXEL_WIDTH*3)]}) :
  			( (pixelBuffer_readDataSelect == 4'hf) && (pixelBuffer_readAddress_subCounter == 3) && ( pixelBuffer_readDataOrder == 1 ) ) ? ({ pixelBuffer_readData_0[(PIXEL_WIDTH*4-1):(PIXEL_WIDTH*3)], pixelBuffer_readData_1[(PIXEL_WIDTH*4-1):(PIXEL_WIDTH*3)], pixelBuffer_readData_2[(PIXEL_WIDTH*4-1):(PIXEL_WIDTH*3)], pixelBuffer_readData_3[(PIXEL_WIDTH*4-1):(PIXEL_WIDTH*3)]}) :
  			0;


endmodule
