`timescale 1ns/1ps
module uart_loopback_tb;
localparam integer CLKS_PER_BIT=8;
reg clk=0,reset=1,start=0;reg [7:0] tx_data=0;wire serial_line,tx_busy,tx_ready;wire [7:0] rx_data;wire rx_valid;
integer received=0;
uart_tx #(.CLKS_PER_BIT(CLKS_PER_BIT)) tx(.clk(clk),.reset(reset),.start(start),.data_in(tx_data),.serial_out(serial_line),.busy(tx_busy),.ready(tx_ready));
uart_rx #(.CLKS_PER_BIT(CLKS_PER_BIT)) rx(.clk(clk),.reset(reset),.serial_in(serial_line),.data_out(rx_data),.data_valid(rx_valid));
always #5 clk=~clk;
always @(posedge clk) if(rx_valid) begin received=received+1;if(rx_data!==8'ha5)$fatal(1,"UART byte mismatch expected A5 got %02h",rx_data);$display("PASS UART loopback received %02h",rx_data);end
initial begin repeat(3)@(posedge clk);@(negedge clk);reset=0;tx_data=8'ha5;start=1;@(negedge clk);start=0;wait(received==1);wait(!tx_busy);#1;if(tx_busy)$fatal(1,"TX should be idle after stop bit");$finish;end
initial begin #5000;$fatal(1,"UART loopback timeout");end
endmodule


