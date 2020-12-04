`timescale 1ns/10ps
`define MS 1000000

module synth_testbench();
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

    z1top #(
        .SYSTEM_CLOCK_FREQ(SYSTEM_CLK_FREQ),
        .B_SAMPLE_COUNT_MAX(5),
        .B_PULSE_COUNT_MAX(5),
        .RESET_PC(32'h1000_0000)
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
        $readmemh("../../software/hw_piano/hw_piano.hex", top.cpu.imem.mem, 0, 16384-1);
        $readmemh("../../software/hw_piano/hw_piano.hex", top.cpu.dmem.mem, 0, 16384-1);

        `ifndef IVERILOG
            $vcdpluson;
        `endif
        `ifdef IVERILOG
            $dumpfile("synth_testbench.fst");
            $dumpvars(0,synth_testbench);
        `endif

        // Reset all parts
        sys_rst = 1'b0;
        data_in = 8'd35; // '#' in ascii
        data_in_valid = 1'b0;
        data_out_ready = 1'b0;

        repeat (20) @(posedge sys_clk); #1;

        sys_rst = 1'b1;
        repeat (50) @(posedge sys_clk); #1;
        sys_rst = 1'b0;

        while (!data_in_ready) @(posedge sys_clk); #1;

        data_in_valid = 1'b1;
        @(posedge sys_clk); #1;
        data_in_valid = 1'b0;

        // This wait can be shortened by increasing the sampling frequency of the NCO.
        #(10 * `MS);

        // Observe waveform for correct behavior.
        // Note: In DVE, if you "Set Radix" to Two's Complement and 
        // "Set Draw Style Scheme" to analog for your LUT read values,
        // you should see the shape of the sine/square/triangle/sawtooth waves.

        `ifndef IVERILOG
            $vcdplusoff;
        `endif
        $finish();
    end
endmodule
