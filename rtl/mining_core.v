// Sequential nonce search using the verified SHA256d header datapath.
// Digest and target are compared as unsigned 256-bit big-endian values.
module mining_core(
    input wire clk, reset, start,
    input wire [639:0] header,
    input wire [255:0] target,
    input wire [31:0] nonce_start, nonce_end,
    output reg busy, done, found,
    output reg [31:0] nonce_found,
    output reg [255:0] digest_found
);
localparam [1:0] IDLE=0, LAUNCH=1, WAIT_HASH=2;
reg [1:0] phase;
reg [31:0] nonce;
reg hash_start;
wire hash_busy, hash_done;
wire [255:0] hash_digest;
sha256d_header hash_engine(.clk(clk),.reset(reset),.start(hash_start),.header(header),.nonce(nonce),.busy(hash_busy),.done(hash_done),.digest(hash_digest));
always @(posedge clk) begin
  if (reset) begin phase<=IDLE;busy<=0;done<=0;found<=0;nonce<=0;nonce_found<=0;digest_found<=0;hash_start<=0;end
  else begin
    done<=0;hash_start<=0;
    case(phase)
      IDLE: if(start) begin
        if(nonce_start<=nonce_end) begin nonce<=nonce_start;found<=0;busy<=1;phase<=LAUNCH;end
        else begin found<=0;busy<=0;done<=1;end
      end
      LAUNCH: begin hash_start<=1;phase<=WAIT_HASH;end
      WAIT_HASH: if(hash_done) begin
        if(hash_digest<=target) begin found<=1;nonce_found<=nonce;digest_found<=hash_digest;busy<=0;done<=1;phase<=IDLE;end
        else if(nonce==nonce_end) begin found<=0;busy<=0;done<=1;phase<=IDLE;end
        else begin nonce<=nonce+1'b1;phase<=LAUNCH;end
      end
      default: begin phase<=IDLE;busy<=0;found<=0;end
    endcase
  end
end
endmodule
