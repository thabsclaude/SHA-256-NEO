// 8-N-1 UART receiver. CLKS_PER_BIT = clock frequency / baud rate.
module uart_rx #(parameter integer CLKS_PER_BIT=868)(
 input wire clk, reset, serial_in,
 output reg [7:0] data_out, output reg data_valid
);
localparam IDLE=0, START=1, DATA=2, STOP=3;
reg [1:0] state; reg [15:0] count; reg [2:0] bit_index; reg [7:0] shift;
always @(posedge clk) begin
 if(reset) begin state<=IDLE;count<=0;bit_index<=0;shift<=0;data_out<=0;data_valid<=0;end
 else begin
  data_valid<=0;
  case(state)
   IDLE: if(!serial_in) begin count<=0;state<=START;end
   START: if(count==(CLKS_PER_BIT/2)-1) begin if(!serial_in) begin count<=0;bit_index<=0;state<=DATA;end else state<=IDLE;end else count<=count+1'b1;
   DATA: if(count==CLKS_PER_BIT-1) begin count<=0;shift[bit_index]<=serial_in;if(bit_index==7) state<=STOP;else bit_index<=bit_index+1'b1;end else count<=count+1'b1;
   STOP: if(count==CLKS_PER_BIT-1) begin data_out<=shift;data_valid<=1;count<=0;state<=IDLE;end else count<=count+1'b1;
   default: state<=IDLE;
  endcase
 end
end
endmodule
