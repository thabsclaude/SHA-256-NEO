`timescale 1ns/1ps
module sha256d_header_tb;
    reg clk = 0;
    reg reset = 1;
    reg start = 0;
    reg [639:0] header;
    reg [31:0] nonce = 32'h1a2b3c4d;
    wire busy, done;
    wire [255:0] digest;
    localparam [255:0] EXPECTED = 256'h1b66432a604a4e02b273ebf91734407740e08a4e70a4548da2baad31b51b2c38;

    sha256d_header dut(.clk(clk), .reset(reset), .start(start),
                       .header(header), .nonce(nonce), .busy(busy),
                       .done(done), .digest(digest));
    always #5 clk = ~clk;

    initial begin
        // Header bytes 0..75 are 00..4b. The final four header bytes are
        // replaced by nonce=1a2b3c4d in big-endian SHA input byte order.
        header = 640'h000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132333435363738393a3b3c3d3e3f404142434445464748494a4b00000000;
        repeat (2) @(posedge clk);
        @(negedge clk); reset = 0;
        @(negedge clk); start = 1;
        @(negedge clk); start = 0;
        wait(done);
        #1;
        if (digest !== EXPECTED)
            $fatal(1, "SHA256d mismatch: expected %064h got %064h", EXPECTED, digest);
        $display("PASS SHA256d 80-byte header and nonce vector: %064h", digest);
        $finish;
    end

    initial begin
        #10000;
        $fatal(1, "Timeout waiting for SHA256d completion");
    end
endmodule

