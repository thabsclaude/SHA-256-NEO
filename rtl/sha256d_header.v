// Bitcoin 80-byte header SHA256d wrapper.
// Header convention: header[639:0] is the 80 header bytes in SHA input order,
// with bytes 76..79 (nonce) ignored and supplied separately as nonce[31:0].
// Digest output is the raw SHA-256 digest byte order (H0 in the most-significant word).
module sha256d_header(
    input wire clk, reset, start,
    input wire [639:0] header,
    input wire [31:0] nonce,
    output reg busy, done,
    output reg [255:0] digest
);
localparam [255:0] IV = {32'h6a09e667,32'hbb67ae85,32'h3c6ef372,32'ha54ff53a,32'h510e527f,32'h9b05688c,32'h1f83d9ab,32'h5be0cd19};
localparam [2:0] IDLE=0, HASH_FIRST=1, WAIT_FIRST=2, HASH_SECOND=3, WAIT_SECOND=4, HASH_FINAL=5, WAIT_FINAL=6;
reg [2:0] phase;
reg core_start;
reg [511:0] core_block;
reg [255:0] core_state; wire [255:0] core_result;
wire core_busy, core_done;
sha256_compress core(.clk(clk),.reset(reset),.start(core_start),.block(core_block),.state_in(core_state),.busy(core_busy),.done(core_done),.state_out(core_result));
always @(posedge clk) begin
  if(reset) begin phase<=IDLE;busy<=0;done<=0;core_start<=0;digest<=0;core_block<=0;core_state<=IV;end
  else begin
    done<=0;core_start<=0;
    case(phase)
      IDLE: if(start) begin busy<=1;core_state<=IV;core_block<=header[639:128];phase<=HASH_FIRST;end
      HASH_FIRST: begin core_start<=1;phase<=WAIT_FIRST;end
      WAIT_FIRST: if(core_done) begin core_state<=core_result;core_block<={header[127:32],nonce,1'b1,319'b0,64'd640};phase<=HASH_SECOND;end
      HASH_SECOND: begin core_start<=1;phase<=WAIT_SECOND;end
      WAIT_SECOND: if(core_done) begin core_state<=IV;core_block<={core_result,1'b1,191'b0,64'd256};phase<=HASH_FINAL;end
      HASH_FINAL: begin core_start<=1;phase<=WAIT_FINAL;end
      WAIT_FINAL: if(core_done) begin digest<=core_result;busy<=0;done<=1;phase<=IDLE;end
      default: begin phase<=IDLE;busy<=0;end
    endcase
  end
end
endmodule


