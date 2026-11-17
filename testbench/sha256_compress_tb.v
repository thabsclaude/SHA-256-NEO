`timescale 1ns/1ps
module sha256_compress_tb;
reg clk=0,reset=1,start=0;reg[511:0] block;reg[255:0] iv;wire busy,done;wire[255:0] out;
sha256_compress dut(clk,reset,start,block,iv,busy,done,out);always #5 clk=~clk;
always @(negedge clk) begin
    if (dut.busy && dut.round == 0) begin
        $display("TRACE_INPUT block=%h state=%h", dut.block, dut.state_in);
        for (integer wi = 0; wi < 64; wi = wi + 1)
            $display("TRACE_W %0d %08x", wi, dut.w[wi]);
        $display("TRACE_INITIAL a=%08x b=%08x c=%08x d=%08x e=%08x f=%08x g=%08x h=%08x",dut.a,dut.b,dut.c,dut.d,dut.e,dut.f,dut.g,dut.h);
    end else if (dut.busy) begin
        $display("TRACE_AFTER_ROUND %0d t1=%08x t2=%08x a=%08x b=%08x c=%08x d=%08x e=%08x f=%08x g=%08x h=%08x",dut.round-1,dut.t1,dut.t2,dut.a,dut.b,dut.c,dut.d,dut.e,dut.f,dut.g,dut.h);
    end
end
initial begin block=512'h61626380000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000018;iv={32'h6a09e667,32'hbb67ae85,32'h3c6ef372,32'ha54ff53a,32'h510e527f,32'h9b05688c,32'h1f83d9ab,32'h5be0cd19};repeat(2)@(posedge clk);reset<=0;@(posedge clk);start<=1;@(posedge clk);start<=0;wait(done);#1;if(out!==256'hba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad)$fatal(1,"abc mismatch %h",out);$display("PASS abc digest");$finish;end
endmodule

