// Iterative SHA-256 compression function.
// Accepts one already-padded 512-bit block and an arbitrary chaining state.
// One SHA-256 round executes per clk edge, followed by one finalization edge
// (65 busy cycles per block). The datapath is split into short register-to-
// register stages so it can meet 100 MHz on a Nexys A7-100T (Artix-7, -1):
//   * sr[0..15] is a fixed-tap shift register holding W[r] .. W[r+15] during
//     round r, so the schedule needs no indexed multiplexers.
//   * hkw holds h + K[r] + W[r] for the current round, computed one cycle
//     early from values that are already registered (h_next == g).
//   * The final feed-forward addition occupies its own cycle.
module sha256_compress (
    input  wire         clk,
    input  wire         reset,
    input  wire         start,
    input  wire [511:0] block,
    input  wire [255:0] state_in,
    output reg          busy,
    output reg          done,
    output reg  [255:0] state_out
);

    reg [31:0] sr [0:15];
    reg [31:0] a, b, c, d, e, f, g, h;
    reg [31:0] hkw;
    reg [255:0] initial_state;
    reg [6:0] round;
    integer i;

    reg [31:0] w_new;
    reg [31:0] t1_next;
    reg [31:0] t2_next;

    function [31:0] k_constant;
        input integer index;
        begin
            case (index)
                 0: k_constant = 32'h428a2f98;  1: k_constant = 32'h71374491;
                 2: k_constant = 32'hb5c0fbcf;  3: k_constant = 32'he9b5dba5;
                 4: k_constant = 32'h3956c25b;  5: k_constant = 32'h59f111f1;
                 6: k_constant = 32'h923f82a4;  7: k_constant = 32'hab1c5ed5;
                 8: k_constant = 32'hd807aa98;  9: k_constant = 32'h12835b01;
                10: k_constant = 32'h243185be; 11: k_constant = 32'h550c7dc3;
                12: k_constant = 32'h72be5d74; 13: k_constant = 32'h80deb1fe;
                14: k_constant = 32'h9bdc06a7; 15: k_constant = 32'hc19bf174;
                16: k_constant = 32'he49b69c1; 17: k_constant = 32'hefbe4786;
                18: k_constant = 32'h0fc19dc6; 19: k_constant = 32'h240ca1cc;
                20: k_constant = 32'h2de92c6f; 21: k_constant = 32'h4a7484aa;
                22: k_constant = 32'h5cb0a9dc; 23: k_constant = 32'h76f988da;
                24: k_constant = 32'h983e5152; 25: k_constant = 32'ha831c66d;
                26: k_constant = 32'hb00327c8; 27: k_constant = 32'hbf597fc7;
                28: k_constant = 32'hc6e00bf3; 29: k_constant = 32'hd5a79147;
                30: k_constant = 32'h06ca6351; 31: k_constant = 32'h14292967;
                32: k_constant = 32'h27b70a85; 33: k_constant = 32'h2e1b2138;
                34: k_constant = 32'h4d2c6dfc; 35: k_constant = 32'h53380d13;
                36: k_constant = 32'h650a7354; 37: k_constant = 32'h766a0abb;
                38: k_constant = 32'h81c2c92e; 39: k_constant = 32'h92722c85;
                40: k_constant = 32'ha2bfe8a1; 41: k_constant = 32'ha81a664b;
                42: k_constant = 32'hc24b8b70; 43: k_constant = 32'hc76c51a3;
                44: k_constant = 32'hd192e819; 45: k_constant = 32'hd6990624;
                46: k_constant = 32'hf40e3585; 47: k_constant = 32'h106aa070;
                48: k_constant = 32'h19a4c116; 49: k_constant = 32'h1e376c08;
                50: k_constant = 32'h2748774c; 51: k_constant = 32'h34b0bcb5;
                52: k_constant = 32'h391c0cb3; 53: k_constant = 32'h4ed8aa4a;
                54: k_constant = 32'h5b9cca4f; 55: k_constant = 32'h682e6ff3;
                56: k_constant = 32'h748f82ee; 57: k_constant = 32'h78a5636f;
                58: k_constant = 32'h84c87814; 59: k_constant = 32'h8cc70208;
                60: k_constant = 32'h90befffa; 61: k_constant = 32'ha4506ceb;
                62: k_constant = 32'hbef9a3f7; 63: k_constant = 32'hc67178f2;
                default: k_constant = 32'h00000000;
            endcase
        end
    endfunction

    function [31:0] rotr;
        input [31:0] value;
        input integer amount;
        begin
            rotr = (value >> amount) | (value << (32 - amount));
        end
    endfunction

    // All arithmetic truncates to 32 bits (SHA-256 modulo-2^32 behavior).
    always @* begin
        // W[r+16] = s1(W[r+14]) + W[r+9] + s0(W[r+1]) + W[r]
        w_new = (rotr(sr[14], 17) ^ rotr(sr[14], 19) ^ (sr[14] >> 10)) +
                sr[9] +
                (rotr(sr[1], 7) ^ rotr(sr[1], 18) ^ (sr[1] >> 3)) +
                sr[0];

        t1_next = hkw +
                  (rotr(e, 6) ^ rotr(e, 11) ^ rotr(e, 25)) +
                  ((e & f) ^ (~e & g));
        t2_next = (rotr(a, 2) ^ rotr(a, 13) ^ rotr(a, 22)) +
                  ((a & b) ^ (a & c) ^ (b & c));
    end

    always @(posedge clk) begin
        done <= 1'b0;

        if (reset) begin
            busy      <= 1'b0;
            round     <= 7'd0;
            state_out <= 256'd0;
        end else if (start && !busy) begin
            for (i = 0; i < 16; i = i + 1) begin
                sr[i] <= block[511 - (i * 32) -: 32];
            end
            {a, b, c, d, e, f, g, h} <= state_in;
            initial_state <= state_in;
            hkw   <= state_in[31:0] + k_constant(0) + block[511:480];
            round <= 7'd0;
            busy  <= 1'b1;
        end else if (busy) begin
            if (round == 7'd64) begin
                // Finalization: feed-forward addition of the initial state.
                state_out <= {
                    a + initial_state[255:224],
                    b + initial_state[223:192],
                    c + initial_state[191:160],
                    d + initial_state[159:128],
                    e + initial_state[127:96],
                    f + initial_state[95:64],
                    g + initial_state[63:32],
                    h + initial_state[31:0]
                };
                busy <= 1'b0;
                done <= 1'b1;
            end else begin
                for (i = 0; i < 15; i = i + 1) begin
                    sr[i] <= sr[i + 1];
                end
                sr[15] <= w_new;

                // Next round's h is this round's g; sr[1] is the next W.
                hkw <= g + k_constant(round + 1) + sr[1];

                h <= g;
                g <= f;
                f <= e;
                e <= d + t1_next;
                d <= c;
                c <= b;
                b <= a;
                a <= t1_next + t2_next;
                round <= round + 1'b1;
            end
        end
    end
endmodule
