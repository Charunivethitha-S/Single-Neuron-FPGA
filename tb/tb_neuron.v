`timescale 1ns / 1ps

module tb_neuron;

    reg clk_100MHz;
    reg rst;
    reg signed [3:0] x0, x1, x2;
    wire signed [4:0] out_equal_weights;   // UPGRADED TO 5-BIT
    wire signed [4:0] out_unequal_weights; // UPGRADED TO 5-BIT

    // Instantiate Top System Layout
    top_neuron_project uut (
        .clk_100MHz(clk_100MHz),
        .rst(rst),
        .x0(x0), .x1(x1), .x2(x2),
        .out_equal_weights(out_equal_weights),
        .out_unequal_weights(out_unequal_weights)
    );

    // Speed up clock divider for simulation testing only
    defparam uut.u_clk_div.DIV_CONSTANT = 5; 

    always #5 clk_100MHz = ~clk_100MHz;

    initial begin
        $monitor("Time=%0dt | Inputs: (%0d, %0d, %0d) | Equal-Out=%0d | Unequal-Out=%0d", 
                 $time, x0, x1, x2, out_equal_weights, out_unequal_weights);

        // System Initialization
        clk_100MHz = 0; rst = 1;
        x0 = 0; x1 = 0; x2 = 0;
        #40;
        
        rst = 0;
        #20;

        // Test Case 1: Testing the exact values you requested
        // Equal math: (2*1)+(2*1)+(3*1)+1 = 8
        // Unequal math: (2*1)+(2*2)+(3*3)+0 = 15
        x0 = 4'sd2; x1 = 4'sd2; x2 = 4'sd3;
        #200; 

        // Test Case 2: Negative Inputs (Tests ReLU Floor)
        x0 = -4'sd3; x1 = -4'sd4; x2 = 4'sd1;
        #200;

        $finish;
    end

endmodule
