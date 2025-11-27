module layer1_discriminator (
    input wire clk,
    input wire rst,
    input wire start,
    // Verilog-2001 compatible: flatten 256 x 16-bit inputs into one packed vector
    // Each input element is Q8.8 (16 bits). Total width = 16 * 256 = 4096 bits
    input wire signed [16*256-1:0] flat_input, // flattened input bus (MSB first)
    output reg signed [15:0] score_out,            // Output Skor Logit (Q8.8)
    output reg decision_real,                      // 1 = Real, 0 = Fake
    output reg done                                // High when result is ready
);

    // ==========================================
    // Memory Parameters
    // ==========================================
    reg signed [15:0] weights_mem [0:255]; // 256 Bobot (1 per input)
    reg signed [15:0] bias_mem [0:0];      // 1 Bias saja untuk output node

    initial begin
        // Load file hex yang dibuat oleh Python
        $readmemh("disc_weights.hex", weights_mem);
        $readmemh("disc_biases.hex", bias_mem);
    end

    // ==========================================
    // Perhitungan Neural Network
    // ==========================================
    integer i;
    reg signed [31:0] accumulator; // 32-bit agar tidak overflow saat penjumlahan
    reg signed [31:0] bias_shifted;
    // compute product combinationally for the current index to avoid register update races
    wire signed [15:0] slice_w;
    wire signed [31:0] current_product;
    reg signed [31:0] next_acc;
    reg [7:0] idx;                 // 0..255
    reg busy;
    
    // slice and product wires
    assign slice_w = $signed(flat_input[(idx+1)*16-1 -: 16]);
    assign current_product = $signed(slice_w) * $signed(weights_mem[idx]);

    // Sequential MAC pipeline: perform one multiply-accumulate per clock
    // Protocol: assert `start` for one cycle. Module loads bias, then performs
    // 256 MAC cycles; when done, `done` is asserted and `score_out`/`decision_real` are valid.
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            accumulator <= 32'sd0;
            bias_shifted <= 32'sd0;
            next_acc <= 32'sd0;
            idx <= 8'd0;
            busy <= 1'b0;
            done <= 1'b0;
            score_out <= 16'sd0;
            decision_real <= 1'b0;
        end else begin
            if (start && !busy) begin
                // Start a new MAC run: load bias and begin from index 0
                bias_shifted <= $signed(bias_mem[0]) <<< 8;
                accumulator <= $signed(bias_mem[0]) <<< 8;
                idx <= 8'd0;
                busy <= 1'b1;
                done <= 1'b0;
            end else if (busy) begin
                // Compute product for current index (combinational) and accumulate
                // Note: `current_product` uses the current `idx` value (from previous cycle),
                // which is the intended behavior for one MAC per clock.
                // next_acc is a combinational expression of the current accumulator and product
                // so we can update accumulator and drive outputs based on it.
                next_acc = accumulator + current_product;
                accumulator <= next_acc;

                if (idx == 8'd255) begin
                    // Last element processed this cycle; produce outputs using next_acc
                    score_out <= next_acc[23:8];
                    decision_real <= (next_acc > 0) ? 1'b1 : 1'b0;
                    busy <= 1'b0;
                    done <= 1'b1;
                end

                idx <= idx + 1'b1;
            end else begin
                // idle: clear done after one cycle so user can pulse start again
                if (done)
                    done <= 1'b0;
            end
        end
    end

endmodule