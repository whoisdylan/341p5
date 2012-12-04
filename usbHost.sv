`default_nettype none

//18-341 P5 Gun Charnmanee (gcharnma) Dylan Koenig (djkoenig)

// Write your usb host here.  Do not modify the port list.
module usbHost
  (input logic clk, rst_L, 
  usbWires wires);
 
  /* Tasks needed to be finished to run testbenches */

  task prelabRequest
  // sends an OUT packet with ADDR=5 and ENDP=4
  // packet should have SYNC and EOP too
  (input bit  [15:0] data);
  
  usbHost.token = 11'b1010000_0010;
  usbHost.data_out =64'hDEADBEEF1987CAFE;
  usbHost.sync = 8'b0000_0001;
  usbHost.mode = 2'b0;
  usbHost.pid = 8'b1000_0111;
  
  /*
  usbHost.mode = 2'd0;
  usbHost.start_send_token <=1'b1;
  wait(usbHost.done_send_token);
  usbHost.start_send_token<= 1'b0;
  */

   usbHost.mode = 2'd1;
  usbHost.start_send_data <=1'b1;
  wait(usbHost.done_send_data);
  usbHost.start_send_data<= 1'b0;
  
  /*
   usbHost.mode = 2'd2;
  usbHost.start_send_hand <=1'b1;
  wait(usbHost.done_send_hand);
  usbHost.start_send_hand<= 1'b0;
  */
  
  endtask: prelabRequest


  task readData
  // host sends memPage to thumb drive and then gets data back from it
  // then returns data and status to the caller
  (input  bit [15:0]  mempage, // Page to write
   output bit [63:0] data, // array of bytes to write
   output bit        success);

  endtask: readData

  task writeData
  // Host sends memPage to thumb drive and then sends data
  // then returns status to the caller
  (input  bit [15:0]  mempage, // Page to write
   input  bit [63:0] data, // array of bytes to write
   output bit        success);

  endtask: writeData

  // usbHost starts here!!
logic nrzi_in, nrzi_out, clear, start, wiresDP, wiresDM;
logic stuffer_in, stuffer_out, pause, crc_in, crc16_in, crc_out, crc16_out, en_crc_L, sync_out, pid_out, sync_pid_out;
logic ld_tok, en_tok, ld_sync, en_sync, ld_pid, en_pid, enable_send, do_eop;
logic sel_1, sel_2, sel_3; //sel_1 for sync or pid, sel_2 for nrzi input, sel_3 for crc16 or crc5
logic [10:0] token;
logic [63:0] data_out;
logic [7:0] sync, pid;
logic clear_sender;
logic done_send_token,start_send_token;
logic clear_stuffer;
logic start_send_data, start_send_hand;
////////////////////////////////////////////////////////////////
logic [1:0] mode; // 0 = SEND_TOKEN, 1 = SEND_DATA, 2 = SEND_HAND
////////////////////////////////////////////////////////////////
////////////////////////////////////////////
logic do_eop_token,en_sync_token,en_crc_L_token, en_pid_token, en_tok_token, clear_token, ld_sync_token, ld_pid_token,
			ld_tok_token, sel_1_token,sel_2_token,enable_send_token,clear_stuffer_token;
logic do_eop_hand,en_sync_hand, en_pid_hand, clear_hand, ld_sync_hand, ld_pid_hand, sel_1_hand,sel_2_hand,enable_send_hand,
		 done_send_hand;
logic  do_eop_data, en_sync_data ,en_crc_L_data, en_pid_data, en_data_data, clear_data, ld_sync_data, ld_pid_data,
		 ld_data_data, sel_1_data,sel_2_data,enable_send_data, clear_stuffer_data,
		done_send_data;

send_token handle_token(clk, rst_L, start_send_token, pause,
							  do_eop_token,en_sync_token,en_crc_L_token, en_pid_token, en_tok_token, clear_token, ld_sync_token, ld_pid_token,
							  ld_tok_token, sel_1_token,sel_2_token,enable_send_token,clear_stuffer_token,
							  done_send_token); // done signal sends to above.
							  
send_data handle_data(clk, rst_L, start_send_data, pause,
							 do_eop_data, en_sync_data ,en_crc_L_data, en_pid_data, en_data_data, clear_data, ld_sync_data, ld_pid_data,
							 ld_data_data, sel_1_data,sel_2_data,enable_send_data, clear_stuffer_data,
							 done_send_data); // done signal sends to above.
							  
							  
send_ack_nak handle_hand( clk, rst_L, start_send_hand, pause,  // ack or nak is determined by the higher FSM
							  do_eop_hand,en_sync_hand, en_pid_hand, clear_hand, ld_sync_hand, ld_pid_hand, sel_1_hand,sel_2_hand,enable_send_hand,
							 done_send_hand); // done signal sends to above.  							  
							  

mux4ways#(1)  mux1(mode, do_eop_token,do_eop_data,do_eop_hand, 1'b0 ,do_eop),
					   mux2(mode, en_sync_token, en_sync_data, en_sync_hand,1'b0, en_sync),
					   mux3(mode, en_crc_L_token, en_crc_L_data, 1'b1, 1'b0, en_crc_L),
					   mux4(mode, en_pid_token, en_pid_data, en_pid_hand, 1'b0, en_pid),
					   mux5(mode, en_tok_token, 1'b0, 1'b0, 1'b0, en_tok),
					   mux6(mode, clear_token, clear_data, clear_hand, 1'b0,clear),
					   mux7(mode,  ld_sync_token, ld_sync_data, ld_sync_hand, 1'b0,ld_sync),
					   mux8(mode, ld_pid_token, ld_pid_data, ld_pid_hand, 1'b0,ld_pid),
					   mux9(mode, ld_tok_token, 1'b0, 1'b0,1'b0, ld_tok),
					   mux10(mode, sel_1_token, sel_1_data, sel_1_hand,1'bz, sel_1),
					   mux11(mode, sel_2_token, sel_2_data, sel_2_hand, 1'bz,sel_2),
					   mux12(mode, enable_send_token, enable_send_data, enable_send_hand,1'bz,enable_send),
					   mux13(mode, clear_stuffer_token, clear_stuffer_data, 1'b1,1'bz,clear_stuffer);
always_comb begin
	case(mode)
		2'd0: sel_3 = 1'b0;
		2'd1: sel_3 = 1'b1;
		2'd2: sel_3 = 1'bz;
		2'd3: sel_3 = 1'bz;
	endcase
end
////////////////////////////////////////////
assign clear_sender = en_crc_L;
//implement enable_send as output of protocol_fsm
assign wires.DP = enable_send ? wiresDP : 1'bz;
assign wires.DM = enable_send ? wiresDM : 1'bz;

///////////////////////////////CRC machines
sender crcSender(crc_in, rst_L, clk, clear_sender ,pause, crc_out);
sender16 crcSender16(crc16_in, rst_L, clk, clear_sender ,pause, crc16_out);
//for now: crcSender's output is tied to bitstuffer's input, but should implement mux with crc16's output later!
assign stuffer_in = sel_3 ? crc16_out : crc_out;

//shift register to hold the token as it's sent to crc
shiftRegister #(11) shiftRegToken(clk, rst_L, ld_tok, en_tok, pause, token, crc_in);

//shift register to hold sync
shiftRegister #(8) shiftRegSync(clk, rst_L, ld_sync, en_sync, 1'd0, sync, sync_out);

//shift register to hold pid
shiftRegister #(8) shiftRegPid(clk, rst_L, ld_pid, en_pid, 1'd0, pid, pid_out);
//shift register to hold DATA
shiftRegister #(64) shiftRegData(clk, rst_L, ld_data_data, en_data_data, pause, data_out, crc16_in);


///////////////////////////////////////////////////////////////
stuffer   bitstuff(stuffer_in, clk, rst_L, clear_stuffer, stuffer_out, pause);  // stuff addr, endp,crc5,crc16, and DATA
///////////////////////////////////////////////////////////////
 //mux in sync, pid 

//mux for selecting between sync or pid
assign sync_pid_out = sel_1 ? sync_out : pid_out;

//mux for NRZI
assign nrzi_in = sel_2 ? stuffer_out : sync_pid_out;
  
////////////////////////////////////////////////////////////////
nrzi    flip(nrzi_in, start, clk, rst_L, clear, nrzi_out);  
////////////////////////////////////////////////////////////////
  // small handler to send out DP and DM. use do_eop to control between NRZI output and EOP.
 logic [2:0] counter_dpdm; 
always_comb begin   // sending DP and DM
	if (do_eop) begin
		if (counter_dpdm == 3'd2) begin
			{wiresDP,wiresDM} = 2'b10;
		end
		else {wiresDP,wiresDM} = 2'b00;
	end
	else {wiresDP,wiresDM} = {nrzi_out,~nrzi_out};                 // go back to output from NRZI
end
always_ff @(posedge clk, negedge rst_L) begin
	if(~rst_L) counter_dpdm <= 3'd0;
	else if(do_eop) counter_dpdm <= counter_dpdm +  3'd1;
	else counter_dpdm <= 3'd0;
end
endmodule: usbHost


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                       modified CRC 5 from hw2                                          //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
module  sender(input logic bit_in, rst_l, clk, clear, pause,  //pause for bit stuffing
						output logic send_bit);
	logic [4:0] Q;
	logic go;
	logic mux;
	logic out_bit;

	assign send_bit = (mux) ?out_bit : bit_in; // mux output between incoming bit and complement
	
	senderFSM sendit(clk,rst_l,clear,pause,mux,go);
	crcCal calcIt(send_bit,clk,rst_l,clear,pause, Q);
	complementMake make(rst_l, go, clk,clear, pause,Q,out_bit);
	
endmodule: sender

module senderFSM( input logic clk, rst_l, clear, pause,
							  output logic mux,go);

	logic [4:0] counter;
	enum logic [2:0]  { FIRST, DATA,COMP, DEAD} cs,ns;

always_comb begin
	go =1'b0;
	mux=1'b0; // mux =1 => shifting out COMP
	case(cs)
		FIRST: begin
			ns = DATA;
			end
		DATA: begin
			if(counter >= 5'd11) begin
				ns = COMP;
				go =1'b1;
				mux =1'b1;
				end
			else
				ns= DATA;
			end
		COMP:begin
		        if(counter>=5'd15) begin
					ns = DEAD;
					mux=1'b1;
					end
				else begin
					mux =1'b1;
					ns =COMP;
				end
			end
		DEAD: ns = DEAD;
	endcase
end

always_ff @(posedge clk, negedge rst_l) begin
		if(~rst_l) begin
			cs <= FIRST;
			counter <= 5'b0;
			end
		else if(clear) begin
			cs<=FIRST;
			counter <= 5'b0;
		end
		else if(pause)begin
			cs <= cs; // stall the process by one clock
			counter<= counter;
		end
		else begin
			cs<= ns;
			counter <= counter + 5'b00001;
			end
	end
endmodule:senderFSM

module  crcCal(input logic bit_in,clk,rst_l, clear, pause, output logic [4:0] Q);

always_ff @(posedge clk, negedge rst_l) begin
		if(~rst_l)
			Q <= 5'b11111;
		else if(clear) Q<= 5'b11111;
		else if(pause) Q <= Q; //stall for one clock.
		else begin
			Q[0] <= bit_in ^ Q[4];
			Q[1] <=	Q[0];
			Q[2] <= (bit_in ^ Q[4] ) ^ Q[1];
			Q[3] <= Q[2];
			Q[4] <= Q[3];
		end
end
endmodule: crcCal

module complementMake(input logic rst_l, go, clk, clear, pause,
									  input logic [4:0] Q,
										output logic oneBit);
		logic [3:0] remainder;
		
		always_comb begin // the first clock just output inverted MSB value of remainder
			if(go) oneBit = ~Q[4];
			else oneBit = remainder[3]; // for subsequent clocks take output from shift register.
		end
		always_ff@(posedge clk, negedge rst_l) begin
			if(~rst_l)
				remainder <= 4'b0;
			else if (clear ) remainder <=4'b0;
			else if(pause) remainder <= remainder; //stall for one clock.
			else if(go)
				remainder <= ~(Q[3:0]); // need to hold 4 bits since the first one is sent out on the clock
			else begin
				remainder[3:1]<= remainder[2:0];
				remainder[0] <= 1'b0;
				end
		end
endmodule: complementMake

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                           CRC16                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module  sender16(input logic bit_in, rst_l, clk, clear, pause,  //pause for bit stuffing
						output logic send_bit);
	logic [15:0] Q;
	logic go;
	logic mux;
	logic out_bit;

	assign send_bit = (mux) ?out_bit : bit_in; // mux output between incoming bit and complement
	
	senderFSM16 sendit(clk,rst_l, clear, pause,mux,go);
	crcCal16 calcIt(send_bit,clk,rst_l, clear, pause,Q);
	complementMake16 make(rst_l,go,clk, clear, pause,Q,out_bit);
	
endmodule: sender16

module senderFSM16( input logic clk, rst_l, clear, pause,
							  output logic mux,go);

	logic [6:0] counter;
	enum logic [2:0]  {FIRST,DATA,COMP,DEAD} cs,ns;

always_comb begin
	go =1'b0;
	mux=1'b0; // mux =1 => shifting out COMP
	case(cs)
		FIRST: begin
			ns = DATA;
			end
		DATA: begin
			if(counter >= 7'd64) begin
				ns = COMP;
				go = 1'b1;
				mux = 1'b1;
			end
			else
				ns= DATA;
			end
		COMP:begin
		        if(counter >= 7'd79) begin
					ns = DEAD;
					mux = 1'b1;
				end
				else begin
					mux = 1'b1;
					ns = COMP;
				end
			end
		DEAD: ns = DEAD;
	endcase
end

always_ff @(posedge clk, negedge rst_l) begin
		if(~rst_l) begin
			cs <= FIRST;
			counter <= 7'd0;
			end
		else if( clear) begin
			cs<= FIRST;
			counter<= 7'd0;
		end
		else if(pause)begin
			cs <= cs; // stall the process by one clock
			counter<= counter;
		end
		else begin
			cs<= ns;
			counter <= counter + 7'd1;
			end
	end
endmodule:senderFSM16

module  crcCal16(input logic bit_in,clk,rst_l, clear, pause, output logic [15:0] Q);

always_ff @(posedge clk, negedge rst_l) begin
		if(~rst_l)
			Q <= 16'b1111_1111_1111_1111;
		else if(clear) Q<= 16'hFFFF;
		else if(pause) Q <= Q; //stall for one clock.
		else begin
			Q[0] <= bit_in^Q[15];
			Q[1] <= Q[0];
			Q[2] <= (bit_in^Q[15])^Q[1];
			Q[3] <= Q[2];
			Q[4] <= Q[3];
			Q[5] <= Q[4];
			Q[6] <= Q[5];
			Q[7] <= Q[6];
			Q[8] <= Q[7];
			Q[9] <= Q[8];
			Q[10] <= Q[9];
			Q[11] <= Q[10];
			Q[12] <= Q[11];
			Q[13] <= Q[12];
			Q[14] <= Q[13];
			Q[15] <= (bit_in^Q[15])^Q[14];
		end
end
endmodule: crcCal16

module complementMake16(input logic rst_l, go, clk, clear, pause,
									  input logic [15:0] Q,
										output logic oneBit);
		logic [14:0] remainder;
		
		always_comb begin // the first clock just output inverted MSB value of remainder
			if(go) oneBit = ~Q[15];
			else oneBit = remainder[14]; // for subsequent clocks take output from shift register.
		end
		always_ff@(posedge clk, negedge rst_l) begin
			if(~rst_l)
				remainder <= 15'd0;
			else if(clear) remainder <=15'd0;
			else if(pause) remainder <= remainder; //stall for one clock.
			else if(go)
				remainder <= ~(Q[14:0]); // need to hold 15 bits since the first one is sent out on the clock
			else begin
				remainder[14:1] <= remainder[13:0];
				remainder[0] <= 1'b0;
				end
		end
endmodule: complementMake16
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                           Bit Stuffing                                                             //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


module stuffer(input logic bit_in, clk, rst_l, clear,
					 output logic bit_out, pause);  // stuff addr, endp,crc5,crc16, and DATA

	logic [2:0] count;
always_comb begin
if(count ==3'd6)begin // found 6 ones, stuff a 0, pause for 1 clock
	pause =1'd1;
	bit_out =1'd0;
end
else begin
	pause =1'd0;
	bit_out = bit_in;
end
end
 
always_ff @(posedge clk, negedge rst_l)begin
	if(~rst_l) count <= 0;   //reset
	else if (clear) count<=0;  // count up to 6 or found a zero. clear
	else if(bit_in) count <= count +3'd1; // keep counting.
	else count <=0;   //  found a 0, clear.
	end
endmodule:stuffer

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                              NRZI                                                                     //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// assume first one is 1;

module nrzi(input logic bit_in, start, clk, rst_L, clear,
				  output logic bit_out);  // everything except EOP
				  
logic past;
always_comb begin

if(bit_in) bit_out = past;  // input is 1, don't invert
else bit_out =~past;      // input is 0 invert.

end
 
always_ff @(posedge clk, negedge rst_L) begin
	if(~rst_L) past <= 1'd1;
	else if(clear) past <= 1'd1;
	else past <= bit_out;
	end				  
endmodule

module shiftRegister
	#(parameter w = 11)
	(input logic clk, rst_L, ld, en, pause,
	 input logic [w-1:0] in,
	 output logic out);

	logic [w-1:0] val;
	assign out = val[w-1];

	always_ff @(posedge clk, negedge rst_L) begin
		if (~rst_L) begin
			val <= 'd0;
		end
		else if (ld) begin
			val <= in;
		end
		else if (en && !pause) begin
			val <= val << 1;
		end
	end
endmodule: shiftRegister

module mux4ways#(parameter w = 1) (input logic [1:0] sel,
														input logic [w-1:0] inA,inB,inC,inD,
														output logic [w-1:0] out);
always_comb begin
	case(sel)
		2'd0:out = inA;
		2'd1:out = inB;
		2'd2:out = inC;
		2'd3:out = inD;
	endcase
end
endmodule:mux4ways

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                            SEND TOKEN FSM                                                     //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
module send_token(input logic clk, rst_l, start, pause,
							 output logic do_eop,en_sync,en_crc_L, en_pid, en_tok, clear, ld_sync, ld_pid,ld_tok, sel_1,sel_2,enable_send, clear_stuffer,
							 output logic done); // done signal sends to above.

	logic [4:0] sync_count, pid_count,token_count, eop_count;
	logic [4:0] sync_add,pid_add, token_add, eop_add;
	enum logic [2:0]  {IDLE, SYNC, PID, TOKE, EOP} cs,ns;
	logic clear_counter;
always_comb begin
	done = 1'b0;
	clear_stuffer = 1'b1;
	sync_add = 5'b0;
	pid_add =5'b0;
	token_add = 5'b0;
	eop_add = 5'b0;
	clear_counter=1'b0;
	do_eop = 1'b0;
	en_sync =1'b0;
	en_crc_L = 1'b1;// has CRC off.
	en_pid = 1'b0;
	en_tok = 1'b0;
	clear = 1'b1;
	ld_sync =1'b0;   //
	ld_pid = 1'b0;    //
	ld_tok = 1'b0;    //
	sel_1 =1'b0;      //
	sel_2 =1'b0;     //
	enable_send = 1'b0;
	case(cs)
		IDLE :begin
				if(start) begin
					ns = SYNC;
					ld_sync <= 1'b1;
					ld_pid <=1'b1;
					ld_tok <= 1'b1;
					sel_1 <=1'b1;
					sel_2<=1'b0;
					end
				else ns = IDLE;    // wait for start signal. 
		end
		SYNC: begin
			clear = 1'b0;
			en_sync = 1'b1;
			sel_1 = 1'b1;
			sel_2 = 1'b0;
			sync_add =1'b1;
			enable_send =1'b1;
			if(sync_count < 5'd7)begin
				ns = SYNC;	
			end
			else ns = PID; 
		end
		PID: begin
			clear = 1'b0;
			en_pid = 1'b1;
			sel_1 = 1'b0;
			sel_2  = 1'b0;
			pid_add = 1'b1;
			enable_send =1'b1;
			if(pid_count<5'd7) begin
				ns = PID;
			end
			else ns = TOKE;
		end
		TOKE:begin
			clear_stuffer = 1'b0;
			clear = 1'b0;
			sel_1 = 1'b0;
			sel_2 = 1'b1;
			en_crc_L = 1'b0;
			token_add =1'b1;
			enable_send =1'b1;
			if(token_count <5'd10) en_tok =1'b1;
			else en_tok = 1'b0;
			if(token_count < 5'd15) begin
			ns = TOKE;
			end
			else ns = EOP;
		end
		EOP: begin
			clear = 1'b0;
			en_crc_L =1'b1;
			do_eop  = 1'b1;
			eop_add =1'b1;
			enable_send =1'b1;
			if(eop_count <5'd2) begin
				ns = EOP;
			end
			else begin
				ns = IDLE;
				done = 1'b1;
				clear_counter =1'b1;
				
			end
		end
	endcase
end

	always_ff @(posedge clk, negedge rst_l) begin
		if(~rst_l) begin
			cs <=IDLE;
			sync_count <= 5'b0;
			pid_count <= 5'b0;
			token_count <= 5'b0;
			eop_count <= 5'b0;
		end
		else if(clear_counter) begin
			cs <=ns;
			sync_count <= 5'b0;
			pid_count <= 5'b0;
			token_count <= 5'b0;
			eop_count <= 5'b0;
		end
		else if(pause) begin
			cs <=cs;
			sync_count <= sync_count;
			pid_count <= pid_count;
			token_count <= token_count;
			eop_count <= eop_count;
		end
		else begin
			cs <=ns;
			sync_count <= sync_count + sync_add;
			pid_count <= pid_count +pid_add;
			token_count <= token_count +token_add;
			eop_count <= eop_count + eop_add;
		end
	end
endmodule: send_token
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                               SEND_HAND                                     //
////////////////////////////////////////////////////////////////////////////////////////////////////////////
module send_ack_nak(input logic clk, rst_l, start, pause,  // ack or nak is determined by the higher FSM
							 output logic do_eop,en_sync, en_pid, clear, ld_sync, ld_pid, sel_1,sel_2,enable_send,
							 output logic done); // done signal sends to above.  

	logic [4:0] sync_count, pid_count,token_count, eop_count;
	logic [4:0] sync_add,pid_add, token_add, eop_add;
	enum logic [2:0]  {IDLE, SYNC, PID, EOP} cs,ns;
	logic clear_counter;
always_comb begin
	done = 1'b0;
	sync_add = 5'b0;
	pid_add =5'b0;
	eop_add = 5'b0;
	clear_counter=1'b0;
	do_eop = 1'b0;
	en_sync =1'b0;
	en_pid = 1'b0;
	clear = 1'b1;
	ld_sync =1'b0;   //
	ld_pid = 1'b0;    //
	sel_1 =1'b0;      //
	sel_2 =1'b0;     //
	enable_send = 1'b0;
	case(cs)
		IDLE :begin
			if(start) begin
				ns = SYNC;
				ld_sync <= 1'b1;
				ld_pid <=1'b1;
				sel_1 <=1'b1;
				sel_2<=1'b0;
				end
			else ns = IDLE;    // wait for start signal. 
		end
		SYNC: begin
			clear = 1'b0;
			en_sync = 1'b1;
			sel_1 = 1'b1;
			sel_2 = 1'b0;
			sync_add =1'b1;
			enable_send =1'b1;
			if(sync_count < 5'd7)begin
				ns = SYNC;	
			end
			else ns = PID; 
		end
		PID: begin
			clear = 1'b0;
			en_pid = 1'b1;
			sel_1 = 1'b0;
			sel_2  = 1'b0;
			pid_add = 1'b1;
			enable_send =1'b1;
			if(pid_count<5'd7) begin
				ns = PID;
			end
			else ns = EOP;
		end
		EOP: begin
			clear = 1'b0;
			do_eop  = 1'b1;
			eop_add =1'b1;
			enable_send =1'b1;
			if(eop_count <5'd2) begin
				ns = EOP;
			end
			else begin
				ns = IDLE;
				done = 1'b1;
				clear_counter =1'b1;
				
			end
		end
	endcase
end

	always_ff @(posedge clk, negedge rst_l) begin
		if(~rst_l) begin
			cs <=IDLE;
			sync_count <= 5'b0;
			pid_count <= 5'b0;
			eop_count <= 5'b0;
		end
		else if(clear_counter) begin
			cs <=ns;
			sync_count <= 5'b0;
			pid_count <= 5'b0;
			eop_count <= 5'b0;
		end
		else if(pause) begin
			cs <=cs;
			sync_count <= sync_count;
			pid_count <= pid_count;
			eop_count <= eop_count;
		end
		else begin
			cs <=ns;
			sync_count <= sync_count + sync_add;
			pid_count <= pid_count +pid_add;
			eop_count <= eop_count + eop_add;
		end
	end
endmodule: send_ack_nak
//////////////////////////////////////////////////////////////////////////////////////////////////////////

module send_data(input logic clk, rst_l, start, pause,
							 output logic do_eop,en_sync,en_crc_L, en_pid, en_data, clear, ld_sync, ld_pid,ld_data, sel_1,sel_2,enable_send, clear_stuffer,
							 output logic done); // done signal sends to above.

	logic [4:0] sync_count, pid_count, eop_count;
	logic [6:0] data_count;
	logic [4:0] sync_add,pid_add, data_add, eop_add;
	enum logic [2:0]  {IDLE, SYNC, PID, DATA, EOP} cs,ns;
	logic clear_counter;
always_comb begin
	done = 1'b0;
	clear_stuffer = 1'b1;
	sync_add = 5'b0;
	pid_add =5'b0;
	data_add = 5'b0;
	eop_add = 5'b0;
	clear_counter=1'b0;
	do_eop = 1'b0;
	en_sync =1'b0;
	en_crc_L = 1'b1;// has CRC off.
	en_pid = 1'b0;
	en_data = 1'b0;
	clear = 1'b1;
	ld_sync =1'b0;   //
	ld_pid = 1'b0;    //
	ld_data = 1'b0;    //
	sel_1 =1'b0;      //
	sel_2 =1'b0;     //
	enable_send = 1'b0;
	case(cs)
		IDLE :begin
				if(start) begin
					ns = SYNC;
					ld_sync <= 1'b1;
					ld_pid <=1'b1;
					ld_data <= 1'b1;
					sel_1 <=1'b1;
					sel_2<=1'b0;
					end
				else ns = IDLE;    // wait for start signal. 
		end
		SYNC: begin
			clear = 1'b0;
			en_sync = 1'b1;
			sel_1 = 1'b1;
			sel_2 = 1'b0;
			sync_add =1'b1;
			enable_send =1'b1;
			if(sync_count < 5'd7)begin
				ns = SYNC;	
			end
			else ns = PID; 
		end
		PID: begin
			clear = 1'b0;
			en_pid = 1'b1;
			sel_1 = 1'b0;
			sel_2  = 1'b0;
			pid_add = 1'b1;
			enable_send =1'b1;
			if(pid_count<5'd7) begin
				ns = PID;
			end
			else ns = DATA;
		end
		DATA:begin
			clear_stuffer = 1'b0;
			clear = 1'b0;
			sel_1 = 1'b0;
			sel_2 = 1'b1;
			en_crc_L = 1'b0;
			data_add =1'b1;
			enable_send =1'b1;
			if(data_count <7'd63) en_data =1'b1;
			else en_data = 1'b0;
			if(data_count < 7'd79) begin
			ns = DATA;
			end
			else ns = EOP;
		end
		EOP: begin
			clear = 1'b0;
			en_crc_L =1'b1;
			do_eop  = 1'b1;
			eop_add =1'b1;
			enable_send =1'b1;
			if(eop_count <5'd2) begin
				ns = EOP;
			end
			else begin
				ns = IDLE;
				done = 1'b1;
				clear_counter =1'b1;
				
			end
		end
	endcase
end

	always_ff @(posedge clk, negedge rst_l) begin
		if(~rst_l) begin
			cs <=IDLE;
			sync_count <= 5'b0;
			pid_count <= 5'b0;
			data_count <= 7'b0;
			eop_count <= 5'b0;
		end
		else if(clear_counter) begin
			cs <=ns;
			sync_count <= 5'b0;
			pid_count <= 5'b0;
			data_count <= 5'b0;
			eop_count <= 7'b0;
		end
		else if(pause) begin
			cs <=cs;
			sync_count <= sync_count;
			pid_count <= pid_count;
			data_count <= data_count;
			eop_count <= eop_count;
		end
		else begin
			cs <=ns;
			sync_count <= sync_count + sync_add;
			pid_count <= pid_count +pid_add;
			data_count <= data_count +data_add;
			eop_count <= eop_count + eop_add;
		end
	end
endmodule: send_data
//////////////////////////////////////////////////////////////////////////////////////////////////////////
