// Sequential binary-to-BCD converter (double-dabble), 27-bit input
// (up to 134,217,727, enough for eight decimal digits up to 99,999,999).
// Converts continuously; the bcd output refreshes every 29 clocks.
module bin2bcd (
    input  wire        clk,
    input  wire        rst,
    input  wire [26:0] bin,
    output reg  [31:0] bcd
);
    reg [26:0] shift;
    reg [31:0] acc;
    reg [4:0]  cnt;

    // Add 3 to every BCD digit that is 5 or more.
    function [31:0] adjust;
        input [31:0] v;
        integer k;
        begin
            for (k = 0; k < 8; k = k + 1) begin
                adjust[k*4 +: 4] = (v[k*4 +: 4] >= 4'd5) ? v[k*4 +: 4] + 4'd3 : v[k*4 +: 4];
            end
        end
    endfunction

    wire [58:0] next = {adjust(acc), shift} << 1;

    always @(posedge clk) begin
        if (rst) begin
            shift <= 27'd0;
            acc   <= 32'd0;
            cnt   <= 5'd0;
            bcd   <= 32'd0;
        end else if (cnt == 5'd0) begin
            shift <= bin;
            acc   <= 32'd0;
            cnt   <= 5'd1;
        end else if (cnt == 5'd28) begin
            bcd <= acc;
            cnt <= 5'd0;
        end else begin
            acc   <= next[58:27];
            shift <= next[26:0];
            cnt   <= cnt + 1'b1;
        end
    end
endmodule
