`timescale 1ns/1ps
module mining_core_tb;
reg clk=0,reset=1,start=0;
reg [639:0] header=640'b0;
reg [255:0] target;
reg [31:0] nonce_start,nonce_end;
wire busy,done,found;
wire [31:0] nonce_found;
wire [255:0] digest_found;
mining_core dut(.clk(clk),.reset(reset),.start(start),.header(header),.target(target),.nonce_start(nonce_start),.nonce_end(nonce_end),.busy(busy),.done(done),.found(found),.nonce_found(nonce_found),.digest_found(digest_found));
always #5 clk=~clk;
initial begin
  nonce_start=32'h0000002a;nonce_end=32'h0000002b;target=256'hffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
  repeat(2) @(posedge clk); @(negedge clk);reset=0;start=1;@(negedge clk);start=0;wait(done);#1;
  if(!found || nonce_found!==32'h0000002a) $fatal(1,"Immediate target match failed: found=%b nonce=%h",found,nonce_found);
  $display("PASS mining controller immediate match nonce=%08h",nonce_found);
  @(negedge clk);nonce_start=0;nonce_end=1;target=0;start=1;@(negedge clk);start=0;wait(done);#1;
  if(found) $fatal(1,"Zero target unexpectedly matched");
  $display("PASS mining controller exhausted nonce range without match");$finish;
end
initial begin #10000;$fatal(1,"Mining controller test timeout");end
endmodule
