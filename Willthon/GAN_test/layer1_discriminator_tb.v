`timescale 1ns / 1ps

module layer1_discriminator_tb;

    // Inputs
    reg signed [15:0] inputs [0:255]; // Array input 256 elemen
    // Flattened bus to connect to DUT (16 bits per element)
    reg signed [16*256-1:0] flat_input;
    reg clk;
    reg rst;
    reg start;

    // Outputs
    wire signed [15:0] score_out;
    wire decision_real;
    wire done;

    // Instantiate Unit Under Test (UUT)
    layer1_discriminator uut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .flat_input(flat_input), 
        .score_out(score_out), 
        .decision_real(decision_real),
        .done(done)
    );

    // Keep the flattened bus updated from the array inputs
    integer i_pack;
    always @(*) begin
        for (i_pack = 0; i_pack < 256; i_pack = i_pack + 1) begin
            flat_input[(i_pack+1)*16-1 -: 16] = inputs[i_pack];
        end
    end

    // Helper untuk konversi tampilan float
    function real q8_8_to_real;
        input signed [15:0] val;
        begin
            q8_8_to_real = val / 256.0;
        end
    endfunction


    integer k;

    // Clock generator: 10ns period
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        $dumpfile("discriminator_test.vcd");
        $dumpvars(0, layer1_discriminator_tb);

        // Reset and init
        rst = 1;
        start = 0;
        #20;
        rst = 0;

        // 1. Load Input Test Vector dari file Hex
        // (Ini mensimulasikan data yang masuk dari Generator)
        $readmemh("disc_input_test.hex", inputs);

        $display("--------------------------------------------------");
        $display("   TESTING DISCRIMINATOR (LAYER 1) ");
        $display("--------------------------------------------------");
        
        // Tampilkan beberapa input sampel
        $display("Sample Inputs (first 5): %f, %f, %f, %f, %f", 
                 q8_8_to_real(inputs[0]), q8_8_to_real(inputs[1]), 
                 q8_8_to_real(inputs[2]), q8_8_to_real(inputs[3]), 
                 q8_8_to_real(inputs[4]));

        // Pulse start for one clock to begin MAC
        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;

        // Wait for done
        wait(done == 1);
        #1; // small delta to let outputs settle

        // 2. Cek Output
        $display("--------------------------------------------------");
        $display("OUTPUT RESULT:");
        $display("Raw Hex Score : %h", score_out);
        $display("Real Score    : %f", q8_8_to_real(score_out));
        $display("Decision      : %b (1=REAL, 0=FAKE)", decision_real);
        $display("--------------------------------------------------");

        // Test Case 2: Input Zero (Harus hanya keluar Bias)
        $display("\nTest Case 2: Zero Inputs");
        for (k=0; k<256; k=k+1) inputs[k] = 16'd0;

        // start again
        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;
        wait(done == 1);
        #1;
        $display("Score (Bias only) : %f", q8_8_to_real(score_out));

        $finish;
    end

endmodule