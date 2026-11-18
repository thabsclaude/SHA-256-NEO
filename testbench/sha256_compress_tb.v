`timescale 1ns / 1ps

module sha256_compress_tb;
    localparam [255:0] IV = {
        32'h6a09e667, 32'hbb67ae85, 32'h3c6ef372, 32'ha54ff53a,
        32'h510e527f, 32'h9b05688c, 32'h1f83d9ab, 32'h5be0cd19
    };

    reg clk = 1'b0;
    reg reset = 1'b1;
    reg start = 1'b0;
    reg [511:0] block;
    wire busy;
    wire done;
    wire [255:0] state_out;

    sha256_compress dut (
        .clk(clk), .reset(reset), .start(start), .block(block),
        .state_in(IV), .busy(busy), .done(done), .state_out(state_out)
    );

    always #5 clk = ~clk;

    task run_case;
        input [511:0] case_block;
        input [255:0] expected_digest;
        input [8*24-1:0] case_name;
        begin
            @(negedge clk);
            block = case_block;
            start = 1'b1;
            @(negedge clk);
            start = 1'b0;
            wait (done);
            #1;
            if (state_out !== expected_digest) begin
                $fatal(1, "%0s mismatch: expected %064h got %064h",
                       case_name, expected_digest, state_out);
            end
            $display("PASS SHA-256 %0s: %064h", case_name, state_out);
        end
    endtask

    initial begin
        repeat (2) @(posedge clk);
        @(negedge clk);
        reset = 1'b0;

        // SHA-256("")
        run_case(
            512'h80000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000,
            256'he3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855,
            "empty message"
        );

        // SHA-256("abc")
        run_case(
            512'h61626380000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000018,
            256'hba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad,
            "abc"
        );

        $finish;
    end

    initial begin
        #5000;
        $fatal(1, "SHA-256 compression testbench timeout");
    end
endmodule
