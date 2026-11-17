// Simple clock divider for the Nexys A7-100T onboard 100 MHz clock.
// On the FPGA, the counter starts at zero after configuration.
// With the default 27-bit counter, LED[0] follows counter bit 25.
module led_blinker #(
    // Smaller values make the divider quicker in simulation.
    parameter integer COUNTER_WIDTH = 27,
    parameter integer LED_COUNTER_BIT = 25
)(
    input  wire       CLK100MHZ,
    output wire [0:0] LED
);

    reg [COUNTER_WIDTH-1:0] counter;

    // Vivado maps this initialization to the FPGA's register power-up value.
    initial begin
        counter = {COUNTER_WIDTH{1'b0}};
    end

    always @(posedge CLK100MHZ) begin
        counter <= counter + 1'b1;
    end

    assign LED[0] = counter[LED_COUNTER_BIT];

endmodule
