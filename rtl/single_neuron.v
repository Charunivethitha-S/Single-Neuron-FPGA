`timescale 1ns / 1ps

// ==========================================================
// 1. CLOCK DIVIDER MODULE (100MHz down to 1Hz)
// ==========================================================
module clk_divider #(
    parameter DIV_CONSTANT = 50_000_000 
)(
    input wire clk_in,
    input wire rst,
    output reg clk_out
);
    reg [25:0] counter;

    always @(posedge clk_in or posedge rst) begin
        if (rst) begin
            counter <= 26'd0;
            clk_out <= 1'b0;
        end else begin
            if (counter >= (DIV_CONSTANT - 1)) begin
                counter <= 26'd0;
                clk_out <= ~clk_out; 
            end else begin
                counter <= counter + 1;
            end
        end
    end
endmodule

// ==========================================================
// 2. THE CORE NEURON TEMPLATE (Upgraded to 5-Bit Output)
// ==========================================================
module single_neuron #(
    parameter signed [7:0] W0 = 8'sd2,
    parameter signed [7:0] W1 = 8'sd2,
    parameter signed [7:0] W2 = 8'sd2,
    parameter signed [7:0] BIAS = 8'sd1
)(
    input wire clk,
    input wire rst,
    input wire signed [3:0] x0, x1, x2, 
    output reg signed [4:0] neuron_out // UPGRADED TO 5-BIT [-16 to +15]
);

    reg signed [11:0] prod0, prod1, prod2;
    reg signed [13:0] sum;

    // --- PIPELINE STAGE 1: Parallel Multiplication ---
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            prod0 <= 12'sd0; prod1 <= 12'sd0; prod2 <= 12'sd0; 
        end else begin
            prod0 <= x0 * W0; prod1 <= x1 * W1; prod2 <= x2 * W2; 
        end
    end

    // --- PIPELINE STAGE 2: Accumulation and Activation ---
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sum        <= 14'sd0;
            neuron_out <= 5'sd0;
        end else begin
            sum <= prod0 + prod1 + prod2 + $signed({{6{BIAS[7]}}, BIAS});

            // ReLU Activation & Saturation Guard for 5-Bit Signed Output (Max is +15)
            if (sum < 14'sd0) 
                neuron_out <= 5'sd0; 
            else if (sum > 14'sd15) 
                neuron_out <= 5'sd15; // New ceiling expanded to 15
            else 
                neuron_out <= sum[4:0]; // Extracts bottom 5 bits safely
        end
    end
endmodule

// ==========================================================
// 3. THE TOP SYSTEM WRAPPER
// ==========================================================
module top_neuron_project (
    input wire clk_100MHz,      
    input wire rst,             
    input wire signed [3:0] x0, x1, x2, 
    output wire signed [4:0] out_equal_weights,  // UPGRADED TO 5-BIT
    output wire signed [4:0] out_unequal_weights // UPGRADED TO 5-BIT
);

    wire clk_div; 

    clk_divider #(
        .DIV_CONSTANT(50_000_000) 
    ) u_clk_div (
        .clk_in(clk_100MHz),
        .rst(rst),
        .clk_out(clk_div)
    );

    // Instance 1: Equal Weightage 
    single_neuron #(
        .W0(8'sd1), .W1(8'sd1), .W2(8'sd1), .BIAS(8'sd1)
    ) neuron_equal (
        .clk(clk_div), .rst(rst), .x0(x0), .x1(x1), .x2(x2),
        .neuron_out(out_equal_weights)
    );

    // Instance 2: Unequal Weightage
    single_neuron #(
        .W0(8'sd1), .W1(8'sd2), .W2(8'sd3), .BIAS(8'sd0)
    ) neuron_unequal (
        .clk(clk_div), .rst(rst), .x0(x0), .x1(x1), .x2(x2), 
        .neuron_out(out_unequal_weights)
    );

endmodule
