`timescale 1ns/1ps
// Unit tests for bin2bcd, seven_seg_driver, and perf_monitor.
module display_tb;
    reg clk = 0, rst = 1;
    always #5 clk = ~clk;

    // ---- bin2bcd ----
    reg  [26:0] bin;
    wire [31:0] bcd;
    bin2bcd conv(.clk(clk), .rst(rst), .bin(bin), .bcd(bcd));

    task check_bcd(input [26:0] value, input [31:0] expected);
        begin
            bin = value;
            repeat (70) @(posedge clk);
            if (bcd !== expected) $fatal(1, "bin2bcd %0d: expected %h got %h", value, expected, bcd);
        end
    endtask

    // ---- seven_seg_driver ----
    reg  [31:0] digits;
    reg         blank_leading;
    wire [7:0]  AN, SEG;
    seven_seg_driver drv(.clk(clk), .rst(rst), .digits(digits), .blank_leading(blank_leading), .AN(AN), .SEG(SEG));

    function [7:0] seg_for(input [3:0] n);
        case (n)
            0: seg_for = 8'hC0; 1: seg_for = 8'hF9; 2: seg_for = 8'hA4; 3: seg_for = 8'hB0;
            4: seg_for = 8'h99; 5: seg_for = 8'h92; 6: seg_for = 8'h82; 7: seg_for = 8'hF8;
            8: seg_for = 8'h80; 9: seg_for = 8'h90; 10: seg_for = 8'h88; 11: seg_for = 8'h83;
            12: seg_for = 8'hC6; 13: seg_for = 8'hA1; 14: seg_for = 8'h86; default: seg_for = 8'h8E;
        endcase
    endfunction

    integer seen_mask, d, cycles;
    reg [7:0] expect_seg;
    task scan_display(input [31:0] value, input blank);
        begin
            digits = value; blank_leading = blank; seen_mask = 0;
            repeat (20) @(posedge clk);
            for (cycles = 0; cycles < 140000; cycles = cycles + 1) begin
                @(posedge clk);
                for (d = 0; d < 8; d = d + 1) begin
                    if (AN === ~(8'b1 << d)) begin
                        seen_mask = seen_mask | (1 << d);
                        if (blank && d != 0 && (value >> (4*d)) == 0) expect_seg = 8'hFF;
                        else expect_seg = seg_for(value[d*4 +: 4]);
                        if (SEG !== expect_seg)
                            $fatal(1, "digit %0d of %h: expected seg %h got %h (blank=%b)", d, value, expect_seg, SEG, blank);
                    end
                end
            end
            if (seen_mask !== 255) $fatal(1, "not all eight digits were scanned: %b", seen_mask[7:0]);
        end
    endtask

    // ---- perf_monitor: 1000-clock rate window, 10-clock microsecond ----
    reg start = 0, busy = 0, tick = 0;
    wire [26:0] rate, count, us;
    perf_monitor #(.SEC_CLKS(1000), .US_CLKS(10)) perf(
        .clk(clk), .rst(rst), .search_start(start), .search_busy(busy),
        .hash_tick(tick), .rate_hps(rate), .hash_count(count), .elapsed_us(us));

    integer n;
    initial begin
        repeat (3) @(posedge clk);
        @(negedge clk); rst = 0;

        check_bcd(0, 32'h00000000);
        check_bcd(7, 32'h00000007);
        check_bcd(1234, 32'h00001234);
        check_bcd(493210, 32'h00493210);
        check_bcd(99999999, 32'h99999999);
        check_bcd(12345678, 32'h12345678);
        $display("PASS bin2bcd");

        scan_display(32'h89abcdef, 1'b0);
        scan_display(32'h00012340, 1'b1);
        scan_display(32'h00000000, 1'b1);
        $display("PASS seven_seg_driver");

        // One hash tick every 10 clocks for 5000 clocks while busy.
        @(negedge clk); start = 1; @(negedge clk); start = 0; busy = 1;
        for (n = 0; n < 5000; n = n + 1) begin
            tick = (n % 10) == 0;
            @(negedge clk);
        end
        tick = 0; busy = 0;
        repeat (5) @(negedge clk);
        if (count !== 500) $fatal(1, "hash_count expected 500 got %0d", count);
        if (rate !== 100) $fatal(1, "rate expected 100 hashes/window got %0d", rate);
        if (us < 495 || us > 505) $fatal(1, "elapsed_us expected about 500 got %0d", us);
        // Rate holds its last value while idle.
        repeat (3000) @(negedge clk);
        if (rate !== 100) $fatal(1, "rate must hold while idle, got %0d", rate);
        // A new search clears the per-search counters.
        @(negedge clk); start = 1; @(negedge clk); start = 0;
        @(negedge clk);
        if (count !== 0 || us !== 0) $fatal(1, "search_start must clear counters");
        $display("PASS perf_monitor");
        $finish;
    end

    initial begin #20000000; $fatal(1, "display testbench timeout"); end
endmodule
