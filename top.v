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
  reg 	[7:0]		axiFSM_writeRequestCounter;

  reg ip2bus_mstrd_req;
  reg ip2bus_mstwr_req;
  reg ip2bus_mst_addr;

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
    end



endmodule
