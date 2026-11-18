// UART-controlled educational miner interface, 8-N-1.
// Request: ASCII 'W' (0x57), 80 header bytes, 32 target bytes,
//          4-byte nonce_start, 4-byte nonce_end. Multi-byte values big-endian.
// Response: 1 status byte (01=found, 00=range exhausted), 4-byte nonce,
//           32-byte digest. For no match, nonce and digest are zero.
// Error:    if a packet stalls for RX_TIMEOUT_CLKS clocks between bytes, it is
//           discarded and a single 0xEE byte is returned; the next 'W' starts
//           a fresh packet. The RESET button and UART_RX are synchronized.
module uart_miner #(parameter integer CLKS_PER_BIT=868,
                    parameter integer RX_TIMEOUT_CLKS=10000000)(
 input wire CLK100MHZ, input wire RESET, input wire UART_RX,
 output wire UART_TX, output reg LED_BUSY, output reg LED_FOUND
);
// Two-flop synchronizers: RESET is an asynchronous push button and UART_RX is
// asynchronous to the 100 MHz clock. rst asserts and releases on a clock edge.
reg [1:0] rst_sync=2'b11, rx_sync=2'b11;
always @(posedge CLK100MHZ) begin rst_sync<={rst_sync[0],RESET}; rx_sync<={rx_sync[0],UART_RX}; end
wire rst=rst_sync[1]; wire rx_in=rx_sync[1];
wire [7:0] rx_byte; wire rx_valid;
reg [7:0] tx_byte; reg tx_start;
wire tx_busy,tx_ready;
uart_rx #(.CLKS_PER_BIT(CLKS_PER_BIT)) receiver(.clk(CLK100MHZ),.reset(rst),.serial_in(rx_in),.data_out(rx_byte),.data_valid(rx_valid));
uart_tx #(.CLKS_PER_BIT(CLKS_PER_BIT)) transmitter(.clk(CLK100MHZ),.reset(rst),.start(tx_start),.data_in(tx_byte),.serial_out(UART_TX),.busy(tx_busy),.ready(tx_ready));
reg [639:0] work_header; reg [255:0] work_target; reg [31:0] nonce_start,nonce_end;
reg [6:0] payload_index; reg packet_active, miner_start;
wire miner_busy,miner_done,miner_found; wire [31:0] nonce_found; wire [255:0] digest_found;
mining_core miner(.clk(CLK100MHZ),.reset(rst),.start(miner_start),.header(work_header),.target(work_target),.nonce_start(nonce_start),.nonce_end(nonce_end),.busy(miner_busy),.done(miner_done),.found(miner_found),.nonce_found(nonce_found),.digest_found(digest_found));
reg [31:0] reply_nonce; reg [255:0] reply_digest; reg reply_status;
reg reply_active, tx_waiting, reply_error; reg [5:0] tx_index; reg [31:0] rx_idle;
always @* begin
  case(tx_index)
    0: tx_byte=reply_error ? 8'hEE : (reply_status ? 8'h01 : 8'h00);
    1: tx_byte=reply_nonce[31:24]; 2: tx_byte=reply_nonce[23:16]; 3: tx_byte=reply_nonce[15:8]; 4: tx_byte=reply_nonce[7:0];
    default: tx_byte=reply_digest[255-(tx_index-5)*8 -: 8];
  endcase
end
always @(posedge CLK100MHZ) begin
 if(rst) begin reply_error<=0;rx_idle<=0;work_header<=0;work_target<=0;nonce_start<=0;nonce_end<=0;payload_index<=0;packet_active<=0;miner_start<=0;tx_start<=0;reply_active<=0;tx_waiting<=0;tx_index<=0;reply_nonce<=0;reply_digest<=0;reply_status<=0;LED_BUSY<=0;LED_FOUND<=0;end
 else begin
  miner_start<=0;tx_start<=0;LED_BUSY<=miner_busy;
  // Abandon a stalled packet and report the error instead of waiting forever.
  if(!packet_active || rx_valid) rx_idle<=0;
  else if(rx_idle==RX_TIMEOUT_CLKS-1) begin
    packet_active<=0;rx_idle<=0;
    reply_active<=1;tx_waiting<=0;tx_index<=0;reply_error<=1;
  end else rx_idle<=rx_idle+1'b1;
  if(rx_valid) begin
    if(!packet_active) begin
      if(rx_byte==8'h57 && !miner_busy && !reply_active) begin packet_active<=1;payload_index<=0;end
    end else begin
      if(payload_index<80) work_header<={work_header[631:0],rx_byte};
      else if(payload_index<112) work_target<={work_target[247:0],rx_byte};
      else if(payload_index<116) nonce_start<={nonce_start[23:0],rx_byte};
      else nonce_end<={nonce_end[23:0],rx_byte};
      if(payload_index==119) begin packet_active<=0;miner_start<=1;LED_FOUND<=0;end
      else payload_index<=payload_index+1'b1;
    end
  end
  if(miner_done) begin
    reply_active<=1;tx_waiting<=0;tx_index<=0;reply_error<=0;reply_status<=miner_found;
    if(miner_found) begin reply_nonce<=nonce_found;reply_digest<=digest_found;end
    else begin reply_nonce<=0;reply_digest<=0;end
    LED_FOUND<=miner_found;
  end
  if(reply_active) begin
    if(!tx_waiting && tx_ready) begin tx_start<=1;tx_waiting<=1;end
    else if(tx_waiting && tx_ready) begin
      tx_waiting<=0;
      if(reply_error || tx_index==36) reply_active<=0;
      else tx_index<=tx_index+1'b1;
    end
  end
 end
end
endmodule
