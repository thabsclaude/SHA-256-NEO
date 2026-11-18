// Performance counters for the front-panel display. All values saturate at
// 99,999,999 so they always fit eight decimal digits.
//   rate_hps    hashes completed in the most recent full 1-second window that
//               contained at least one hash (holds its value when idle)
//   hash_count  total hashes completed in the current/last search
//   elapsed_us  microseconds from packet accepted to search finished
module perf_monitor #(
    parameter integer SEC_CLKS = 100000000,  // clocks per rate window
    parameter integer US_CLKS  = 100         // clocks per microsecond
)(
    input  wire        clk,
    input  wire        rst,
    input  wire        search_start,  // one-cycle pulse when a search is launched
    input  wire        search_busy,   // high while the miner is searching
    input  wire        hash_tick,     // one-cycle pulse per completed SHA256d
    output reg  [26:0] rate_hps,
    output reg  [26:0] hash_count,
    output reg  [26:0] elapsed_us
);
    localparam [26:0] MAXV = 27'd99999999;

    reg [31:0] sec_cnt;
    reg [26:0] window;
    reg [6:0]  us_cnt;
    wire [26:0] window_total = window + hash_tick;

    always @(posedge clk) begin
        if (rst) begin
            sec_cnt    <= 32'd0;
            window     <= 27'd0;
            us_cnt     <= 7'd0;
            rate_hps   <= 27'd0;
            hash_count <= 27'd0;
            elapsed_us <= 27'd0;
        end else begin
            // Rate: count hashes per fixed window; keep the last non-empty result.
            if (sec_cnt == SEC_CLKS - 1) begin
                sec_cnt <= 32'd0;
                window  <= 27'd0;
                if (window_total != 27'd0)
                    rate_hps <= (window_total > MAXV) ? MAXV : window_total;
            end else begin
                sec_cnt <= sec_cnt + 1'b1;
                window  <= window_total;
            end

            // Per-search totals.
            if (search_start) begin
                hash_count <= 27'd0;
                elapsed_us <= 27'd0;
                us_cnt     <= 7'd0;
            end else begin
                if (hash_tick && hash_count != MAXV)
                    hash_count <= hash_count + 1'b1;
                if (search_busy) begin
                    if (us_cnt == US_CLKS - 1) begin
                        us_cnt <= 7'd0;
                        if (elapsed_us != MAXV)
                            elapsed_us <= elapsed_us + 1'b1;
                    end else begin
                        us_cnt <= us_cnt + 1'b1;
                    end
                end
            end
        end
    end
endmodule
