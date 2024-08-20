`timescale 1ns / 1ps


module NN(
    input clk,
    input reset,
    
    output [15:0] addrA,
    input [31:0] dataA,    
    
    output reg [3:0] digit_out
);  

    // the whole network can be paramaterized with these 3 dims
    parameter inputs_dim = 784; // inputs are 1 x inputsDim
    parameter w1_secondary_dim = 110; // inputsDim x w1
    parameter w2_secondary_dim = 10; //w1 x w2

    
    
    wire [31:0] dataA_shifted;
    
    wire [16*w1_secondary_dim-1:0] addr_busB;  
    wire [32*w1_secondary_dim-1:0] data_busB;
    
    wire [15:0] addrC; 
    wire [31:0] dataC;
    wire [31:0] dataC_relu;
    
    wire [16*w2_secondary_dim-1:0] addr_busD;  
    wire [32*w2_secondary_dim-1:0] data_busD;
    
    wire mm1_finished;
    wire mm1_finished;
    wire internal_rst;
    

    assign internal_rst = reset || mm2_finished;
    
    // input data is not stored as 32 bit in ram: it is a single bit. therefore we must shift it into our predefined fixed point
    // the weird bit shifting here is to avoid the "Z" state. we shift forward and them backward to remove Z from the whole bus
    assign dataA_shifted = (dataA << 31) >> 8;
    
    // perform a relu before we feed into the second matmul (just check the sign bit)
    assign dataC_relu = (dataC[31]) ? 32'b0 : dataC ;
    
    mmV2 #(
        //colsA MUST == colsB before the implicit transposition
        .rowsA(1),
        .colsA(inputs_dim),
        .rowsB(w1_secondary_dim),
        .colsB(inputs_dim),
        .matA_input_latency_lag_to_matb(1)
    ) mm1 (
        .clk(clk),
        .reset(reset  || mm2_finished_delay),
        
        .addr_outA(addrA),
//        .data_inA(synth_test_add),
        .data_inA(dataA_shifted),

        .addr_outB(addr_busB),
        .data_inB(data_busB),
        
        .res_addr(addrC),
        .res_out(dataC),
        
        .finished(mm1_finished)
        );
        
    // SECOND MATLMUL
    mmV2 #(
        //colsA MUST == colsB before the implicit transposition
        .rowsA(1),
        .colsA(w1_secondary_dim),
        .rowsB(w2_secondary_dim),
        .colsB(w1_secondary_dim)
    ) mm2 (
        .clk(clk),
        .reset(~mm1_finished  || mm2_finished_delay),
        
        .addr_outA(addrC),
        .data_inA(dataC_relu),

        .addr_outB(addr_busD),
        .data_inB(data_busD),
        
        .res_addr(testing_addr),
        .res_out(testing_out),
        
        .finished(mm2_finished)
        );
        
        reg mm2_finished_delay;
        
        always @(posedge clk) begin
            mm2_finished_delay <= mm2_finished;
        end
        
        
        
        // we can run argmax in a single clock cycle. amazing
        integer i;
        reg signed [31:0] max_value;  // Declare max_value as signed
        
        always @(posedge mm2_finished) begin
            max_value = $signed(mm2.sum_outputs[0]);  // Cast the first element as signed
            digit_out = 0;
        
            for (i = 1; i < 10; i = i + 1) begin
                if ($signed(mm2.sum_outputs[i]) > max_value) begin  // Cast each element as signed for comparison
                    max_value = $signed(mm2.sum_outputs[i]);
                    digit_out = i;
                end
            end
        end

    

    // Weights for mm1
    DistRAM #(
     .WIDTH(32),
     .DEPTH(inputs_dim),
     .NUM_NODES(w1_secondary_dim),
     .MEM_FILE("wm1_784_")
      )matB(
     .clk(clk),
     .addr_rd(addr_busB),
     .data_out(data_busB)
    );

    // Weights for mm2
    DistRAM #(
     .WIDTH(32),
     .DEPTH(w1_secondary_dim), // num entries in a file
     .NUM_NODES(w2_secondary_dim),
     .MEM_FILE("wm2_32_") //these should be called wm2_64 oops
      )matC(
     .clk(clk),
     .addr_rd(addr_busD),
     .data_out(data_busD)
    );
    
    
    
    
    
endmodule




