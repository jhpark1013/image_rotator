`include "image_rotator_defines.v"
  module top
  (
   input         Clk,
   // input         ILAClk,
   input         ResetL,
   // input reg [31:0] PIXEL_WIDTH,

   // output 	reg 					ip2bus_mstrd_req,
   // output 	reg 					ip2bus_mstwr_req,
   // output 	reg 	[31:0]				ip2bus_mst_addr,
   // output 	wire 	[19:0] 				ip2bus_mst_length,
   // output 	wire 	[((32*4)/8-1):0] 	ip2bus_mst_be,
   // output 	wire 					ip2bus_mst_type,
   // output 	wire 					ip2bus_mst_lock,
   // output 	wire 					ip2bus_mst_reset,
   //
   // input 	 					bus2ip_mst_cmdack,
   // input 	 					bus2ip_mst_cmplt,
   // // input 	wire 					bus2ip_mst_error,
   // // input 	wire 					bus2ip_mst_rearbitrate,
   // // input 	wire 					bus2ip_mst_cmd_timeout,
   // // input 	wire 	[(32*4-1):0]		bus2ip_mstrd_d,
   // input 	wire 	[7:0]				bus2ip_mstrd_rem,
   // // input 	wire 					bus2ip_mstrd_sof_n,
   // // input 	wire 					bus2ip_mstrd_eof_n,
   // input 	wire 					bus2ip_mstrd_src_rdy_n,
   // input 	wire 					bus2ip_mstrd_src_dsc_n,
   //
   // output 	wire 					ip2bus_mstrd_dst_rdy_n,
   // output 	wire 					ip2bus_mstrd_dst_dsc_n,
   // // output 	reg 	[(32*4-1):0]		ip2bus_mstwr_d,
   // output 	wire 	[7:0]				ip2bus_mstwr_rem,
   // // output 	reg 					ip2bus_mstwr_sof_n,
   // // output 	reg 					ip2bus_mstwr_eof_n,
   // // output 	reg 					ip2bus_mstwr_src_rdy_n,
   // output 	wire 					ip2bus_mstwr_src_dsc_n,
   //
   // input 	wire 					bus2ip_mstwr_dst_rdy_n,
   // input 	wire 					bus2ip_mstwr_dst_dsc_n,
   //
   output 	wire 	[31:0]				InputImageAddress,
   output 	wire 	[31:0]				OutputImageAddress,
   output 	wire 					BeginRotation
   // output 	wire 					RotationDone // don't use this as output wire
   // output 	wire  				RotationType,
   // output 	wire	[4:0]				NumberOf120PixelsBlocks_X,
   // output 	wire	[4:0]				NumberOf120PixelsBlocks_Y
   // // input 	wire 	[31:0]				StartPixel_X,
   // // input 	wire 	[31:0]				StartPixel_Y,
   // // input 	wire 	[31:0]				NumberOfPixelsPerLine

   );

// assign PIXEL_WIDTH = 32;

assign BeginRotation = 1;

// assign InputImageAddress = 1;
// assign OutputImageAddress = 0;
// assign BeginRotation = 1;
reg RotationDone = 1;
// assign RotationType = 1;
reg NumberOf120PixelsBlocks_X = 10;
reg NumberOf120PixelsBlocks_Y = 10;
//
// localparam BE_WIDTH = (32*4)/8;

//////////////////////////////////////////////////////
//
// axi master - constant signals
//
//////////////////////////////////////////////////////

// assign ip2bus_mst_length = 120 * 2;		// every read or write transaction has a length of 120 pixels --> 120 * 2 = 240 bytes.
// assign ip2bus_mst_type = 1; 		// we always transfer in bursts.
// assign ip2bus_mst_lock = 0;
// assign ip2bus_mstrd_dst_dsc_n = 1; 	// we do never discountinue a transfer
// assign ip2bus_mstrd_dst_rdy_n = 0; 	// we are always ready to receive the data
// assign ip2bus_mst_be = {BE_WIDTH{1'b1}};			//8'hff; 		// all of the transferred data is always meaningful
// assign ip2bus_mstwr_rem = 0;
// assign ip2bus_mst_reset = 0;
// assign ip2bus_mstwr_src_dsc_n = 1;

//////////////////////////////////////////////////////
//
// main fsm
//
//////////////////////////////////////////////////////

reg 	[3:0]		mainFSM_currentState;
reg	[3:0]		mainFSM_prevState;

reg	[31:0]		inputImageAddressR;
reg	[31:0]		outputImageAddressR;

always_ff @(posedge Clk)
       if ( ! ResetL ) begin
	      mainFSM_currentState <= `FSM_IDLE;
	      mainFSM_prevState <= `FSM_IDLE;

	      inputImageAddressR <= 0;
	      outputImageAddressR <= 0;

	      RotationDone <= 0;
       end
       else begin
	      case ( mainFSM_currentState )

	      `FSM_IDLE: begin
		     if ( BeginRotation ) begin
			    inputImageAddressR <= InputImageAddress;
			    outputImageAddressR <= OutputImageAddress;

			    mainFSM_currentState <= `FSM_RECEIEVE_BLOCK;
			    mainFSM_prevState <= `FSM_IDLE;
		     end
		     else begin
			    inputImageAddressR <= inputImageAddressR;
			    outputImageAddressR <= outputImageAddressR;

			    mainFSM_currentState <= `FSM_IDLE;
			    mainFSM_prevState <= `FSM_IDLE;
		     end

		     RotationDone <= 0;
	      end

	    `FSM_RECEIEVE_BLOCK: begin
    			if ( axiMaster_blockReceived ) begin
    				mainFSM_currentState <= `FSM_SEND_BLOCK;
    				mainFSM_prevState <= `FSM_RECEIEVE_BLOCK;
    			end
    			else begin
    				mainFSM_currentState <= `FSM_RECEIEVE_BLOCK;
    				mainFSM_prevState <= `FSM_RECEIEVE_BLOCK;
    			end
	      end

	    `FSM_SEND_BLOCK: begin
    			if ( axiMaster_blockSent ) begin
    				if ( ( sendBlockCounterX == (NumberOf120PixelsBlocks_X-1) ) && ( sendBlockCounterY == (NumberOf120PixelsBlocks_Y-1) ) ) begin
    					mainFSM_currentState <= `FSM_END_OPERATION;
    					mainFSM_prevState <= `FSM_SEND_BLOCK;
    				end
    				else begin
    					mainFSM_currentState <= `FSM_RECEIEVE_BLOCK;
    					mainFSM_prevState <= `FSM_SEND_BLOCK;
    				end
    			end
    			else begin
    				mainFSM_currentState <= `FSM_SEND_BLOCK;
    				mainFSM_prevState <= `FSM_SEND_BLOCK;
    			end
	      end

	    `FSM_END_OPERATION: begin
    			RotationDone <= 1;

    			mainFSM_currentState <= `FSM_IDLE;
    			mainFSM_prevState <= `FSM_END_OPERATION;
	      end

	      default: begin
    			mainFSM_currentState <= `FSM_IDLE;
    			mainFSM_prevState <= mainFSM_prevState;
	      end

	      endcase
       end

//////////////////////////////////////////////////////
//
// received and sent block counters
//
//////////////////////////////////////////////////////
//

reg	[4:0]	receiveBlockCounterX, receiveBlockCounterY;
reg	[4:0]	sendBlockCounterX, sendBlockCounterY;

  always_ff @(posedge Clk)
    if(!ResetL) begin
      receiveBlockCounterX <= 0;
      receiveBlockCounterY <= 0;
      sendBlockCounterX <= 0;
      sendBlockCounterY <= 0;
    end
    else begin

    if(mainFSM_currentState == `FSM_IDLE) begin
      receiveBlockCounterX <= 0;
      receiveBlockCounterY <= 0;
      sendBlockCounterX <= 0;
      sendBlockCounterY <= 0;
    end

    else if((mainFSM_currentState == `FSM_SEND_BLOCK) &&
              (mainFSM_prevState == `FSM_RECEIEVE_BLOCK) ) begin
        if(receiveBlockCounterX == (NumberOf120PixelsBlocks_X-1)) begin
            receiveBlockCounterX <= 0;
            if(receiveBlockCounterY == (NumberOf120PixelsBlocks_Y-1)) begin
              receiveBlockCounterY <= 0;
            end
            else begin
              receiveBlockCounterY <= receiveBlockCounterY + 1;
            end
          end
    else begin
      receiveBlockCounterX <= receiveBlockCounterX + 1;
      receiveBlockCounterY <= receiveBlockCounterY + 1;
    end

    sendBlockCounterX <= sendBlockCounterX;
    sendBlockCounterY <= sendBlockCounterY;
    end

    else if((mainFSM_currentState == `FSM_RECEIEVE_BLOCK) &&
              (mainFSM_prevState == `FSM_SEND_BLOCK)) begin
          receiveBlockCounterX <= receiveBlockCounterX;
          receiveBlockCounterY <= receiveBlockCounterY;
       if(sendBlockCounterX == (NumberOf120PixelsBlocks_X-1)) begin
              sendBlockCounterX <= 0;
          if(sendBlockCounterY == (NumberOf120PixelsBlocks_Y-1)) begin
              sendBlockCounterY <= 0;
          end
          else begin
            sendBlockCounterY <= sendBlockCounterY + 1;
          end
        end
        else begin
          sendBlockCounterX <= sendBlockCounterX + 1;
          sendBlockCounterY <= sendBlockCounterY ;
        end
      end

      else begin
        receiveBlockCounterX <= receiveBlockCounterX;
        receiveBlockCounterY <= receiveBlockCounterY;
        sendBlockCounterX <= sendBlockCounterX;
        sendBlockCounterY <= sendBlockCounterY;
      end

    end


  //////////////////////////////////////////////////////
  //
  // axi master fsm
  //
  //////////////////////////////////////////////////////
  // logic to talk to the axi master ipif

  reg 			axiMaster_blockReceived;
  reg 			axiMaster_blockSent;
  reg	[4:0]		axiFSM_currentState;
  reg	[4:0]		axiFSM_prevState;
  reg	[7:0]		axiFSM_readRequestCounter;
  reg [7:0]		axiFSM_writeRequestCounter;

  reg ip2bus_mstrd_req;
  reg ip2bus_mstwr_req;
  reg ip2bus_mst_addr;

  reg bus2ip_mst_cmdack;
  reg bus2ip_mst_cmplt;

  reg axi_readAddress_offset;
  reg axi_readAddress_numberOfPassedLines;
  reg axi_readAddress_numberOfPassedPixelsInCurrentLine;
  reg axi_readAddress_numberOfPassedPixels;

  reg RotationType;

  reg axi_writeAddress_copy_offset;
  reg axi_writeAddress_horiz_offset;
  reg axi_writeAddress_vert_offset;
  // reg axi_writeAddress_clockwise_offset;
  // reg axi_writeAddress_counter_clockwise_offset;

  always_ff @(posedge Clk)
    if(!ResetL) begin
      axiFSM_currentState <= `AXI_FSM_IDLE;
      axiFSM_prevState <= `AXI_FSM_IDLE;
      axiMaster_blockReceived <= 0;
      axiMaster_blockSent <= 0;
      ip2bus_mstrd_req <= 0;
      ip2bus_mstwr_req <= 0;
      ip2bus_mst_addr <= 0;
      axiFSM_readRequestCounter <= 0;
      axiFSM_writeRequestCounter <= 0;

      // generate read address to read the pixels
      assign axi_readAddress_numberOfPassedLines = receiveBlockCounterX * `IMAGE_BLOCK_SIZE
        + axiFSM_readRequestCounter ;
      assign axi_readAddress_numberOfPassedPixelsInCurrentLine = receiveBlockCounterX
        * `IMAGE_BLOCK_SIZE ;
      assign axi_readAddress_numberOfPassedPixels = axi_readAddress_numberOfPassedPixelsInCurrentLine
        + axi_readAddress_numberOfPassedLines;
      assign axi_readAddress_offset = axi_readAddress_numberOfPassedPixels * `IMAGE_NO_BYTES_PER_PIXEL;

      assign bus2ip_mst_cmdack = 1;
      assign bus2ip_mst_cmplt = 1;
      assign RotationType = 0;

      // generate write address when doing only a block copy operation
      assign axi_writeAddress_copy_offset = (RotationType == `ROTATION_CMD_COPY)?1:0;
            // (`IMAGE_BLOCK_SIZE * NumberOf120PixelsBlocks_X) : 0;
      // (RotationType == `ROTATION_CMD_COPY)?
      //   (sendBlockCounterY * `IMAGE_BLOCK_SIZE + axiFSM_writeRequestCounter) : 0 ;
      assign axi_writeAddress_horiz_offset = (RotationType == `ROTATION_CMD_HORIZ_FLIP)?
            (`IMAGE_BLOCK_SIZE * NumberOf120PixelsBlocks_X) : 0;
      // (RotationType == `ROTATION_CMD_HORIZ_FLIP)?
      //   (axi_writeAddress_horiz_numberOfPassedPixels * `IMAGE_NO_BYTES_PER_PIXEL) : 0;
      assign axi_writeAddress_vert_offset = axi_writeAddress_copy_offset;
      // axi_writeAddress_clockwise_offset;
      // axi_writeAddress_counter_clockwise_offset;
    end


    else begin
  		case ( axiFSM_currentState )
  		`AXI_FSM_IDLE : begin
  			if ( (mainFSM_currentState == `FSM_RECEIEVE_BLOCK) && (mainFSM_prevState == `FSM_IDLE) ) begin
  				axiFSM_currentState <= `AXI_FSM_SEND_READ_REQUEST1;
  				axiFSM_prevState <= `AXI_FSM_IDLE;

  				axiFSM_readRequestCounter <= 0;
  			end
  			else if ( (mainFSM_currentState == `FSM_RECEIEVE_BLOCK) && (mainFSM_prevState == `FSM_SEND_BLOCK) ) begin
  				axiFSM_currentState <= `AXI_FSM_SEND_READ_REQUEST1;
  				axiFSM_prevState <= `AXI_FSM_IDLE;

  				axiFSM_readRequestCounter <= 0;
  			end
  			else if ( (mainFSM_currentState == `FSM_SEND_BLOCK) && (mainFSM_prevState == `FSM_RECEIEVE_BLOCK) ) begin
  				axiFSM_currentState <= `AXI_FSM_SEND_WRITE_REQUEST1;
  				axiFSM_prevState <= `AXI_FSM_IDLE;

  				axiFSM_writeRequestCounter <= 0;
  			end
  			else begin
  				axiFSM_currentState <= `AXI_FSM_IDLE;
  				axiFSM_prevState <= `AXI_FSM_IDLE;
  			end

  			axiMaster_blockReceived <= 0;
  			axiMaster_blockSent <= 0;
  		end
  		/////////////////////////////////
  		//
  		// read req.
  		//
  		/////////////////////////////////
  		`AXI_FSM_SEND_READ_REQUEST1: begin
  			ip2bus_mstrd_req <= 1;
  			ip2bus_mst_addr <= inputImageAddressR + axi_readAddress_offset;

  			axiFSM_currentState <= `AXI_FSM_WAIT_FOR_READ_ACK1;
  			axiFSM_prevState <= `AXI_FSM_SEND_READ_REQUEST1;
  		end
  		`AXI_FSM_WAIT_FOR_READ_ACK1: begin
  			if ( bus2ip_mst_cmdack ) begin
  				ip2bus_mstrd_req <= 0;

  				axiFSM_currentState <= `AXI_FSM_WAIT_FOR_READ_CMPLT1;
  				axiFSM_prevState <= `AXI_FSM_WAIT_FOR_READ_ACK1;
  			end
  			else begin
  				ip2bus_mstrd_req <= ip2bus_mstrd_req;

  				axiFSM_currentState <= `AXI_FSM_WAIT_FOR_READ_ACK1;
  				axiFSM_prevState <= `AXI_FSM_WAIT_FOR_READ_ACK1;
  			end
  		end
  		`AXI_FSM_WAIT_FOR_READ_CMPLT1: begin
  			if ( bus2ip_mst_cmplt ) begin

  				if ( axiFSM_readRequestCounter == (`IMAGE_BLOCK_SIZE-1) ) begin
  					axiFSM_currentState <= `AXI_FSM_IDLE;
  					axiFSM_prevState <= `AXI_FSM_WAIT_FOR_READ_CMPLT1;

  					axiMaster_blockReceived <= 1;

  				end
  				else begin
  					axiFSM_currentState <= `AXI_FSM_SEND_READ_REQUEST1;
  					axiFSM_prevState <= `AXI_FSM_WAIT_FOR_READ_CMPLT1;

  					axiMaster_blockReceived <= 0;
  					axiFSM_readRequestCounter <= axiFSM_readRequestCounter + 1;
  				end
  			end
  			else begin
  				axiFSM_currentState <= `AXI_FSM_WAIT_FOR_READ_CMPLT1;
  				axiFSM_prevState <= `AXI_FSM_WAIT_FOR_READ_CMPLT1;
  			end
  		end
  		/////////////////////////////////
  		//
  		// write req. 1
  		//
  		/////////////////////////////////
  		`AXI_FSM_SEND_WRITE_REQUEST1: begin
  			ip2bus_mstwr_req <= 1;

  			case ( RotationType )
  				`ROTATION_CMD_COPY: begin
  					ip2bus_mst_addr <= outputImageAddressR + axi_writeAddress_copy_offset;
  				end
  				`ROTATION_CMD_HORIZ_FLIP: begin
  					ip2bus_mst_addr <= outputImageAddressR + axi_writeAddress_horiz_offset;
  				end
  				`ROTATION_CMD_VERT_FLIP: begin
  					ip2bus_mst_addr <= outputImageAddressR + axi_writeAddress_vert_offset;
  				end
  				// `ROTATION_CMD_CLOCK_WISE: begin
  				// 	ip2bus_mst_addr <= outputImageAddressR + axi_writeAddress_clockwise_offset;
  				// end
  				// `ROTATION_CMD_COUNTER_CLOCK_WISE: begin
  				// 	ip2bus_mst_addr <= outputImageAddressR + axi_writeAddress_counter_clockwise_offset;
  				// end
  			endcase

  			axiFSM_currentState <= `AXI_FSM_WAIT_FOR_WRITE_ACK1;
  			axiFSM_prevState <= `AXI_FSM_SEND_WRITE_REQUEST1;
  		end
  		`AXI_FSM_WAIT_FOR_WRITE_ACK1: begin
  			if ( bus2ip_mst_cmdack ) begin
  				ip2bus_mstwr_req <= 0;

  				axiFSM_currentState <= `AXI_FSM_WAIT_FOR_WRITE_CMPLT1;
  				axiFSM_prevState <= `AXI_FSM_WAIT_FOR_WRITE_ACK1;
  			end
  			else begin
  				ip2bus_mstwr_req <= ip2bus_mstwr_req;

  				axiFSM_currentState <= `AXI_FSM_WAIT_FOR_WRITE_ACK1;
  				axiFSM_prevState <= `AXI_FSM_WAIT_FOR_WRITE_ACK1;
  			end
  		end
  		`AXI_FSM_WAIT_FOR_WRITE_CMPLT1: begin
  			if ( bus2ip_mst_cmplt ) begin
  				if ( axiFSM_writeRequestCounter == (`IMAGE_BLOCK_SIZE-1)) begin
  					axiFSM_currentState <= `AXI_FSM_IDLE;
  					axiFSM_prevState <= `AXI_FSM_WAIT_FOR_READ_CMPLT1;

  					axiMaster_blockSent <= 1;
  				end
  				else begin
  					axiFSM_currentState <= `AXI_FSM_SEND_WRITE_REQUEST1;
  					axiFSM_prevState <= `AXI_FSM_WAIT_FOR_WRITE_CMPLT1;

  					axiFSM_writeRequestCounter <= axiFSM_writeRequestCounter + 1;
  				end
  			end
  			else begin
  				axiFSM_currentState <= `AXI_FSM_WAIT_FOR_WRITE_CMPLT1;
  				axiFSM_prevState <= `AXI_FSM_WAIT_FOR_WRITE_CMPLT1;
  			end
  		end
  		/////////////////////////////////
  		//
  		// default
  		//
  		/////////////////////////////////
  		default : begin
  			axiFSM_currentState <= `AXI_FSM_IDLE;
  			axiFSM_prevState <= `AXI_FSM_IDLE;
  		end
  		endcase
  	end

    // pixel buffer
    reg PIXEL_WIDTH = 32;
    // write registers
    reg                       pixelBuffer_writeEnable;
    reg [11:0]                pixelBuffer_writeAddress;
    reg [(32*4-1):0] pixelBuffer_writeData;
    // read registers
    reg                       pixelBuffer_readEnable;
    reg [9:0]                 pixelBuffer_readAddress;
    reg [(32*4-1):0] pixelBuffer_readData0;
    reg [(32*4-1):0] pixelBuffer_readData1;
    reg [(32*4-1):0] pixelBuffer_readData2;
    reg [(32*4-1):0] pixelBuffer_readData3;

    // indicator for reading one pixel from each block memory. or we reading
    // all pixels from the same block memory.
    reg	[3:0]			pixelBuffer_readDataSelect;
    // indicator for telling if the pixels that we read should be sent out in a
    // straight order or reverse order.
    reg				pixelBuffer_readDataOrder;
    // this is only used when doing horizontal and vertical flips or copy.
    reg 	[1:0]			pixelBuffer_readAddress_subCounter;

    //////////////////////////////////////////
    // input data
    //////////////////////////////////////////

    reg bus2ip_mstrd_src_rdy_n;
    reg bus2ip_mstrd_d = 1;
    reg pixel_Buffer_writeData;

    always_ff @(posedge Clk)
      if(!ResetL) begin
        pixelBuffer_writeEnable <= 0;
        pixelBuffer_writeAddress <= 0;
        pixelBuffer_writeData <= 0;
      end
      else begin

        if(axiFSM_currentState == `AXI_FSM_IDLE) begin
          pixelBuffer_writeEnable <= 0;
          pixelBuffer_writeAddress <= 0;
          pixelBuffer_writeData <= 0;
        end

        else if (axiFSM_currentState == `AXI_FSM_SEND_READ_REQUEST1) begin
          pixelBuffer_writeEnable <= 0;
          case(RotationType)
            `ROTATION_CMD_COPY: begin
              pixelBuffer_writeAddress <=
                axiFSM_readRequestCounter * `IMAGE_BLOCK_SIZE/4 - 1;
              end
          endcase
          pixelBuffer_writeData <= 0;
        end

        else if (axiFSM_currentState == `AXI_FSM_WAIT_FOR_READ_CMPLT1) begin
          if(!bus2ip_mstrd_src_rdy_n) begin
            pixelBuffer_writeEnable <= 1;
            case(RotationType)
              `ROTATION_CMD_COPY: begin
                pixelBuffer_writeAddress <= pixelBuffer_writeAddress + 1;
              end
            endcase
            pixelBuffer_writeData <= bus2ip_mstrd_d;
          end
          else begin
            pixelBuffer_writeEnable <= 0;
            pixelBuffer_writeAddress <= pixelBuffer_writeAddress;
            pixel_Buffer_writeData <= 0;
          end
        end

        else begin
          pixelBuffer_writeEnable <= 0;
          pixelBuffer_writeAddress <= pixelBuffer_writeAddress;
          pixelBuffer_writeData <= 0;
        end
      end

      /////////////////////////////////////
      // output data
      /////////////////////////////////////
      // default block size is 120 x 120 pixels (14400 pixels)
      // generate suitable read address and config signals for reading the data
      // back from the dual port memory.

      always_ff @(posedge Clk)
        if(!ResetL) begin
          pixelBuffer_readAddress <= 0;
          pixelBuffer_readDataSelect <= 0;
          pixelBuffer_readDataOrder <= 0;
        end
        else begin
          if(axiFSM_currentState == `AXI_FSM_IDLE) begin
            pixelBuffer_readAddress <= 0;
            pixelBuffer_readDataSelect <= 0;
            pixelBuffer_readDataOrder <= 0;
          end
          else if ((axiFSM_prevState == `AXI_FSM_WAIT_FOR_READ_ACK1) &&
                  bus2ip_mst_cmdack) begin
              case (RotationType)
                `ROTATION_CMD_COPY: begin
                  pixelBuffer_readAddress <= axiFSM_writeRequestCounter
                    *((`IMAGE_BLOCK_SIZE/4)/4 + axiFSM_writeRequestCounter/2);
                  pixelBuffer_readDataSelect <= 4'hf;
                  pixelBuffer_readDataOrder <= 0;
                end
              endcase
          end

          else if(pixelBuffer_readEnable &&
            (!
              (
              (axiFSM_prevState == `AXI_FSM_WAIT_FOR_WRITE_ACK1) &&
            (axiFSM_currentState == `AXI_FSM_WAIT_FOR_WRITE_CMPLT1)
              )
            )) begin

            case(RotationType)
              `ROTATION_CMD_COPY: begin
              if(pixelBuffer_readAddress_subCounter == 2) begin
                pixelBuffer_readAddress <= pixelBuffer_readAddress + 1;
              end
              else begin
                pixelBuffer_readAddress <= pixelBuffer_readAddress;
              end
              pixelBuffer_readDataSelect <= 4'hf;
              pixelBuffer_readDataOrder <= 0;
              end
            endcase

            end
            else begin
              pixelBuffer_readAddress <= pixelBuffer_readAddress;
              pixelBuffer_readDataSelect <= pixelBuffer_readDataSelect;
              pixelBuffer_readDataOrder <= pixelBuffer_readDataOrder;
              pixelBuffer_readAddress <= 0;
              pixelBuffer_readDataSelect <= 0;
              pixelBuffer_readDataOrder <= 0;
            end
          end

      //////////////////////////////////////////
      // read address
      //////////////////////////////////////////



































endmodule
