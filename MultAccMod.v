`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/26/2024 01:37:34 PM
// Design Name: 
// Module Name: chainMod
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module chainMod #(
    parameter integer index_bit_size = 16, // max number we can index is 32k (all our mats are smaller than this)
    parameter integer bit_res = 32, // each int is 32 bits
    parameter integer frac_bits = 23 // 1 sign bit, 8 int bits (implied), 23 fractional bits
)(
    input clk,
    input reset,
    input signed [bit_res-1:0] numInSide, // Declare as signed
    output reg signed [bit_res-1:0] numOutSide, // Declare as signed
    
    input signed [bit_res-1:0] numInTop, // Declare as signed
    output reg signed [bit_res-1:0] numOutTop, // Declare as signed
    
    output reg signed [bit_res-1:0] sum // Declare as signed
);

    // Temporary variable for the product
    reg signed [2*bit_res-1:0] product; // 64 bits to hold the intermediate product

    // Register the input numIn on each clk cycle
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            numOutSide <= {bit_res{1'b0}};
            numOutTop <= {bit_res{1'b0}};
            sum <= {bit_res{1'b0}};
        end else begin
            numOutSide <= numInSide;
            numOutTop <= numInTop;

            // Calculate product
            product = numInSide * numInTop;

            // Add product to sum, adjusting for fixed-point representation
            sum <= sum + (product >>> frac_bits); // Arithmetic right shift for signed numbers
        end
    end

endmodule
