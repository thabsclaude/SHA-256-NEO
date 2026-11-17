// 8-N-1 UART transmitter. Assert start for one clock when ready is high.
module uart_tx #(parameter integer CLKS_PER_BIT=868)(
 input wire clk, reset, start, input wire [7:0] data_in,
 output reg serial_out, output reg busy, output wire ready
);
localparam IDLE=0, START=1, DATA=2, STOP=3;
reg [1:0] state;reg [15:0] count;reg [2:0] bit_index;reg [7:0] shift;
assign ready=~busy;
always @(posedge clk) begin
 if(reset) begin state<=IDLE;count<=0;bit_index<=0;shift<=0;serial_out<=1;busy<=0;end
 else case(state)
  IDLE: begin serial_out<=1;busy<=0;if(start) begin shift<=data_in;busy<=1;serial_out<=0;count<=0;state<=START;end end
  START: if(count==CLKS_PER_BIT-1) begin count<=0;bit_index<=0;serial_out<=shift[0];state<=DATA;end else count<=count+1'b1;
  DATA: if(count==CLKS_PER_BIT-1) begin count<=0;if(bit_index==7) begin serial_out<=1;state<=STOP;end else begin bit_index<=bit_index+1'b1;serial_out<=shift[bit_index+1'b1];end end else count<=count+1'b1;
  STOP: if(count==CLKS_PER_BIT-1) begin serial_out<=1;busy<=0;count<=0;state<=IDLE;end else count<=count+1'b1;
  default: begin state<=IDLE;serial_out<=1;busy<=0;end
 endcase
end
endmodule
