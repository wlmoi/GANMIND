module layer3_discriminator (
    input wire clk,
    input wire rst,
    input wire start,
    // Flattened input bus: 32 elements * 16 bits = 512 bits
    input wire signed [16*32-1:0] flat_input_flat,
    // Output: single 16-bit score (final decision)
    output reg signed [15:0] score_out,
    output reg decision_real,
    output reg done
);

    // ==========================================
    // Memory untuk Parameter (Weights & Biases)
    // ==========================================
    // Total weights: 1 neuron * 32 input = 32
    reg signed [15:0] layer3_disc_weights [0:31]; 
    reg signed [15:0] layer3_disc_bias  [0:0];

    initial begin
        // Load data hex dari hex_data directory (expanded format)
        $readmemh("hex_data/Discriminator_Layer3_Weights_All.hex", layer3_disc_weights);
        $readmemh("hex_data/Discriminator_Layer3_Biases_All.hex", layer3_disc_bias);
    end

    // ==========================================
    // Sequential MAC Pipeline State
    // ==========================================
    // Single neuron, 32 inputs
    // Inner loop: input index (0..31)
    reg [5:0] input_idx;    // 0..31
    reg busy;
    reg signed [31:0] accumulator;
    reg signed [31:0] bias_shifted;

    // Combinational wires for current input and product
    wire signed [15:0] current_input;
    wire signed [31:0] current_product;
    wire signed [31:0] next_acc;

    assign current_input = $signed(flat_input_flat[(input_idx+1)*16-1 -: 16]);
    assign current_product = $signed(current_input) * $signed(layer3_disc_weights[input_idx]);
    assign next_acc = accumulator + current_product;

    // Sequential MAC pipeline: one MAC operation per clock cycle
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            input_idx <= 6'd0;
            accumulator <= 32'sd0;
            bias_shifted <= 32'sd0;
            busy <= 1'b0;
            done <= 1'b0;
            score_out <= 16'sd0;
            decision_real <= 1'b0;
        end else begin
            if (start && !busy) begin
                // Start a new computation: begin with input 0, load bias
                input_idx <= 6'd0;
                bias_shifted <= $signed(layer3_disc_bias[0]) <<< 8;
                accumulator <= $signed(layer3_disc_bias[0]) <<< 8;
                busy <= 1'b1;
                done <= 1'b0;
            end else if (busy) begin
                // Perform one MAC: accumulator += input[input_idx] * weight[input_idx]
                accumulator <= next_acc;

                if (input_idx == 6'd31) begin
                    // Finished all 32 inputs; write output and finish
                    score_out <= next_acc[23:8]; // scale Q16.16 -> Q8.8
                    decision_real <= (next_acc > 0) ? 1'b1 : 1'b0; // decision threshold at 0
                    busy <= 1'b0;
                    done <= 1'b1;
                end else begin
                    // Continue with next input
                    input_idx <= input_idx + 1'b1;
                end
            end else begin
                // idle: clear done after one cycle so user can pulse start again
                if (done)
                    done <= 1'b0;
            end
        end
    end

endmodule
