`timescale 1ns/10ps
`define MSG_LENGTH 4

module bios_integration_testbench ();
    parameter SYSTEM_CLK_PERIOD = 8;
    parameter SYSTEM_CLK_FREQ = 125_000_000;

    reg sys_clk = 0;
    reg sys_rst = 0;
    always #(SYSTEM_CLK_PERIOD/2) sys_clk <= ~sys_clk;

    // UART Signals between the on-chip and off-chip UART
    wire FPGA_SERIAL_RX, FPGA_SERIAL_TX;

    // Off-chip UART Ready/Valid interface
    reg   [7:0] data_in;
    reg         data_in_valid;
    wire        data_in_ready;
    wire  [7:0] data_out;
    wire        data_out_valid;
    reg         data_out_ready;

    reg [4:0] i = 0;
    reg [8*`MSG_LENGTH:1] msg = "";

    z1top #(
        .SYSTEM_CLOCK_FREQ(SYSTEM_CLK_FREQ),
        .B_SAMPLE_COUNT_MAX(5),
        .B_PULSE_COUNT_MAX(5)
    ) top (
        .CLK_125MHZ_FPGA(sys_clk),
        .BUTTONS({3'b0, sys_rst}),
        .SWITCHES(2'b0),
        .LEDS(),
        .FPGA_SERIAL_RX(FPGA_SERIAL_RX),
        .FPGA_SERIAL_TX(FPGA_SERIAL_TX)
    );

    // Instantiate the off-chip UART
    uart # (
        .CLOCK_FREQ(SYSTEM_CLK_FREQ)
    ) off_chip_uart (
        .clk(sys_clk),
        .reset(sys_rst),
        .data_in(data_in),
        .data_in_valid(data_in_valid),
        .data_in_ready(data_in_ready),
        .data_out(data_out),
        .data_out_valid(data_out_valid),
        .data_out_ready(data_out_ready),
        .serial_in(FPGA_SERIAL_TX),
        .serial_out(FPGA_SERIAL_RX)
    );

    reg done = 0;
    reg [31:0] cycle = 0;
    initial begin
        $readmemh("../../software/bios151v3/bios151v3.hex", top.cpu.bios_mem.mem, 0, 4095);

        `ifndef IVERILOG
            $vcdpluson;
        `endif
        `ifdef IVERILOG
            $dumpfile("bios_integration_testbench.fst");
            $dumpvars(0,bios_integration_testbench);
        `endif

        // Reset all parts
        sys_rst = 1'b0;
        data_in = 8'h7a;
        data_in_valid = 1'b0;
        data_out_ready = 1'b0;

        repeat (20) @(posedge sys_clk); #1;

        sys_rst = 1'b1;
        repeat (50) @(posedge sys_clk); #1;
        sys_rst = 1'b0;

        fork
            begin
                // Wait for the off-chip UART to receive the '151>'
                for (i = 0; i < `MSG_LENGTH; i = i + 1) begin
                    while (!data_out_valid) @(posedge sys_clk); #1;
                    $display("Got %h", data_out);
                    msg = {msg[8*(`MSG_LENGTH-1):1], data_out};

                    // Clear the off-chip UART's receiver for another UART packet
                    data_out_ready = 1'b1;
                    @(posedge sys_clk); #1;
                    data_out_ready = 1'b0;
                end
                $display("Recieved %s", msg);

                done = 1;
            end
            begin
                for (cycle = 0; cycle < 100000; cycle = cycle + 1) begin
                    if (done) $finish();
                    @(posedge sys_clk);
                end
                if (!done) begin
                    $display("Failed: timing out");
                    $finish();
                end
            end
        join

        `ifndef IVERILOG
            $vcdplusoff;
        `endif
        $finish();
    end
endmodule
