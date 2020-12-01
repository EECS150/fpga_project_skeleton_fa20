`timescale 1ns/10ps
`define MSG_LENGTH 4

module bios_testbench();
    parameter CPU_CLOCK_PERIOD = 20;
    parameter CPU_CLOCK_FREQ = 50_000_000;

    reg clk, rst;
    wire FPGA_SERIAL_RX, FPGA_SERIAL_TX;

    reg   [7:0] data_in;
    reg         data_in_valid;
    wire        data_in_ready;
    wire  [7:0] data_out;
    wire        data_out_valid;
    reg         data_out_ready;

    reg [4:0] i = 0;
    reg [8*`MSG_LENGTH:1] msg = "";

    initial clk = 0;
    always #(CPU_CLOCK_PERIOD/2) clk <= ~clk;

    // Instantiate your Riscv CPU here and connect the FPGA_SERIAL_TX wires
    // to the off-chip UART we use for testing. The CPU has a UART (on-chip UART) inside it.
    Riscv151 # (
        .CPU_CLOCK_FREQ(CPU_CLOCK_FREQ)
    ) CPU (
        .clk(clk),
        .rst(rst),
        .FPGA_SERIAL_RX(FPGA_SERIAL_RX),
        .FPGA_SERIAL_TX(FPGA_SERIAL_TX)
    );

    // Instantiate the off-chip UART
    uart # (
        .CLOCK_FREQ(CPU_CLOCK_FREQ)
    ) off_chip_uart (
        .clk(clk),
        .reset(rst),
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
        $readmemh("../../software/bios151v3/bios151v3.hex", CPU.bios_mem.mem, 0, 4095);

        `ifndef IVERILOG
            $vcdpluson;
        `endif
        `ifdef IVERILOG
            $dumpfile("bios_testbench.fst");
            $dumpvars(0,bios_testbench);
        `endif

        // Reset all parts
        rst = 1'b0;
        data_in = 8'h7a;
        data_in_valid = 1'b0;
        data_out_ready = 1'b0;

        repeat (20) @(posedge clk); #1;

        rst = 1'b1;
        repeat (30) @(posedge clk); #1;
        rst = 1'b0;

        fork
            begin
                // Wait for the off-chip UART to receive the '151>'
                for (i = 0; i < `MSG_LENGTH; i = i + 1) begin
                    while (!data_out_valid) @(posedge clk); #1;
                    $display("Got %h", data_out);
                    msg = {msg[8*(`MSG_LENGTH-1):1], data_out};

                    // Clear the off-chip UART's receiver for another UART packet
                    data_out_ready = 1'b1;
                    @(posedge clk); #1;
                    data_out_ready = 1'b0;
                end
                $display("Recieved %s", msg);

                done = 1;
            end
            begin
                for (cycle = 0; cycle < 50000; cycle = cycle + 1) begin
                    if (done) $finish();
                    @(posedge clk);
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
