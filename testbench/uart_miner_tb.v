`timescale 1ns/1ps
module uart_miner_tb;
localparam integer CPB=8;
reg clk=0,reset=1,host_tx=1;reg [1:0] sw=2'b11;wire [7:0] an,seg;wire fpga_tx,busy,found;
wire [7:0] rx_byte;wire rx_valid;integer response_count=0;reg [7:0] response[0:36];integer i;
uart_miner #(.CLKS_PER_BIT(CPB),.RX_TIMEOUT_CLKS(2000),.HASH_WINDOW_CLKS(4000),.CLKS_PER_US(10)) dut(.CLK100MHZ(clk),.RESET(reset),.UART_RX(host_tx),.SW(sw),.UART_TX(fpga_tx),.LED_BUSY(busy),.LED_FOUND(found),.AN(an),.SEG(seg));
uart_rx #(.CLKS_PER_BIT(CPB)) host_receiver(.clk(clk),.reset(reset),.serial_in(fpga_tx),.data_out(rx_byte),.data_valid(rx_valid));
always #5 clk=~clk;
always @(posedge clk) if(rx_valid) begin response[response_count]=rx_byte;response_count=response_count+1;end
task send_byte(input [7:0] value);integer bitno;begin
 @(negedge clk);host_tx=0;repeat(CPB)@(negedge clk);
 for(bitno=0;bitno<8;bitno=bitno+1) begin host_tx=value[bitno];repeat(CPB)@(negedge clk);end
 host_tx=1;repeat(CPB)@(negedge clk);
end endtask
task send_work;begin
 send_byte(8'h57); // 'W'
 for(i=0;i<80;i=i+1) send_byte(i[7:0]);
 for(i=0;i<32;i=i+1) send_byte(8'hff); // easiest target: every digest meets target
 send_byte(0);send_byte(0);send_byte(0);send_byte(8'h2a);
 send_byte(0);send_byte(0);send_byte(0);send_byte(8'h2a);
end endtask
initial begin
 repeat(3)@(posedge clk);@(negedge clk);reset=0;
 send_work;
 wait(response_count==37);#1;
 if(response[0]!==8'h01) $fatal(1,"Expected found status 01, got %02h",response[0]);
 if({response[1],response[2],response[3],response[4]}!==32'h0000002a) $fatal(1,"Nonce reply mismatch");
 if({response[5],response[6],response[7],response[8],response[9],response[10],response[11],response[12],response[13],response[14],response[15],response[16],response[17],response[18],response[19],response[20],response[21],response[22],response[23],response[24],response[25],response[26],response[27],response[28],response[29],response[30],response[31],response[32],response[33],response[34],response[35],response[36]}!==256'h86bef4c1c6dd1f3a6c456465f26af381e57fc3a8670c066979a37584306802e1) $fatal(1,"Digest reply mismatch");
 $display("PASS UART mining work packet and 37-byte result response");
 // Display modes: one nonce (0x2a) was hashed once.
 sw=2'b11;repeat(100)@(negedge clk);
 if(dut.show_value!==32'd1) $fatal(1,"hash count display expected 1 got %0d",dut.show_value);
 sw=2'b01;repeat(100)@(negedge clk);
 if(dut.show_value!==32'h0000002a || dut.show_hex!==1'b1) $fatal(1,"nonce display expected 2a got %h",dut.show_value);
 sw=2'b10;repeat(100)@(negedge clk);
 if(dut.show_value===32'd0) $fatal(1,"elapsed time display should be nonzero");
 sw=2'b00;repeat(100)@(negedge clk);
 $display("PASS display modes (hash count 1, nonce 2a, elapsed time nonzero)");
 // UART-001: a truncated packet must time out with a single 0xEE byte.
 repeat(50)@(negedge clk);response_count=0;
 send_byte(8'h57);for(i=0;i<5;i=i+1) send_byte(i[7:0]);
 wait(response_count==1);#1;
 if(response[0]!==8'hEE) $fatal(1,"Expected error byte EE, got %02h",response[0]);
 repeat(3000)@(negedge clk);
 if(response_count!==1) $fatal(1,"Error reply must be exactly one byte, got %0d",response_count);
 $display("PASS truncated packet timed out with error byte EE");
 // Recovery: a complete packet after the error must still succeed.
 response_count=0;send_work;wait(response_count==37);#1;
 if(response[0]!==8'h01 || {response[1],response[2],response[3],response[4]}!==32'h0000002a) $fatal(1,"Recovery packet failed");
 $display("PASS valid packet accepted after timeout recovery");$finish;
end
initial begin #2000000;$fatal(1,"UART mining integration timeout; response bytes=%0d",response_count);end
endmodule
