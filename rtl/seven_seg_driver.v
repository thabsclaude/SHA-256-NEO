// Multiplexed driver for the Nexys A7 eight-digit common-anode display.
// digits[31:28] is the leftmost digit (AN7); digits[3:0] is the rightmost (AN0).
// AN and SEG are active low. SEG[0]=CA ... SEG[6]=CG, SEG[7]=DP.
// With blank_leading set, leading zeros are turned off (the last digit never is).
module seven_seg_driver (
    input  wire        clk,
    input  wire        rst,
    input  wire [31:0] digits,
    input  wire        blank_leading,
    output reg  [7:0]  AN,
    output reg  [7:0]  SEG
);
    // About 760 full-display refreshes per second at 100 MHz.
    reg [16:0] refresh;
    wire [2:0] sel = refresh[16:14];

    wire [3:0] nibble = digits[sel*4 +: 4];
    wire       blank  = blank_leading && (sel != 3'd0) && ((digits >> (sel * 4)) == 32'd0);

    reg [6:0] seg_high;  // bit 0 = segment a ... bit 6 = segment g, active high
    always @* begin
        case (nibble)
            4'h0: seg_high = 7'b0111111;
            4'h1: seg_high = 7'b0000110;
            4'h2: seg_high = 7'b1011011;
            4'h3: seg_high = 7'b1001111;
            4'h4: seg_high = 7'b1100110;
            4'h5: seg_high = 7'b1101101;
            4'h6: seg_high = 7'b1111101;
            4'h7: seg_high = 7'b0000111;
            4'h8: seg_high = 7'b1111111;
            4'h9: seg_high = 7'b1101111;
            4'ha: seg_high = 7'b1110111;
            4'hb: seg_high = 7'b1111100;
            4'hc: seg_high = 7'b0111001;
            4'hd: seg_high = 7'b1011110;
            4'he: seg_high = 7'b1111001;
            default: seg_high = 7'b1110001;
        endcase
    end

    always @(posedge clk) begin
        if (rst) begin
            refresh <= 17'd0;
            AN      <= 8'hff;
            SEG     <= 8'hff;
        end else begin
            refresh <= refresh + 1'b1;
            AN      <= ~(8'b00000001 << sel);
            SEG     <= blank ? 8'hff : {1'b1, ~seg_high};
        end
    end
endmodule
