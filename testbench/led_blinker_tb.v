`timescale 1ns / 1ps

module led_blinker_tb;
    localparam integer TEST_COUNTER_WIDTH = 4;
    localparam integer TEST_LED_COUNTER_BIT = 2;
    localparam integer HALF_PERIOD_CYCLES = 1 << TEST_LED_COUNTER_BIT;

    reg CLK100MHZ = 1'b0;
    wire [0:0] LED;
    integer cycle_count;

    // A reduced counter makes each LED transition quick to simulate.
    led_blinker #(
        .COUNTER_WIDTH(TEST_COUNTER_WIDTH),
        .LED_COUNTER_BIT(TEST_LED_COUNTER_BIT)
    ) dut (
        .CLK100MHZ(CLK100MHZ),
        .LED(LED)
    );

    always #5 CLK100MHZ = ~CLK100MHZ;

    initial begin
        // Explicit testbench initialization makes simulator startup deterministic.
        dut.counter = {TEST_COUNTER_WIDTH{1'b0}};
        #1;
        if (LED[0] !== 1'b0) begin
            $fatal(1, "LED should start low after counter initialization");
        end

        // Counter bit N first rises after 2**N rising clock edges.
        for (cycle_count = 1; cycle_count <= HALF_PERIOD_CYCLES; cycle_count = cycle_count + 1) begin
            @(posedge CLK100MHZ);
            #1;
            if (cycle_count < HALF_PERIOD_CYCLES && LED[0] !== 1'b0) begin
                $fatal(1, "LED changed too early at cycle %0d", cycle_count);
            end
        end
        if (LED[0] !== 1'b1) begin
            $fatal(1, "LED did not rise after %0d cycles", HALF_PERIOD_CYCLES);
        end

        // It falls after another 2**N rising edges.
        for (cycle_count = 1; cycle_count <= HALF_PERIOD_CYCLES; cycle_count = cycle_count + 1) begin
            @(posedge CLK100MHZ);
            #1;
            if (cycle_count < HALF_PERIOD_CYCLES && LED[0] !== 1'b1) begin
                $fatal(1, "LED changed too early on second interval at cycle %0d", cycle_count);
            end
        end
        if (LED[0] !== 1'b0) begin
            $fatal(1, "LED did not fall after another %0d cycles", HALF_PERIOD_CYCLES);
        end

        $display("PASS: LED changed at the expected reduced-counter intervals.");
        $finish;
    end
endmodule 
