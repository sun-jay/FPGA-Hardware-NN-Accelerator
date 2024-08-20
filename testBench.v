`timescale 1ns / 1ps


module tb_topMod;

    // Inputs
    reg clk100_extern;
    reg reset_in;
    reg oneOrZed;

    // Outputs
    wire [7:0] Anode_Activate;
    wire [6:0] LED_out;
    
//    wire [3:0] debug;
    
//    assign debug = uut.disp.number;
    
     wire [3:0] digit_out;
     assign digit_out = uut.digit_out;

    // Instantiate the Unit Under Test (UUT)
    topMod uut (
        .clk100_extern(clk100_extern),
        .reset_in(reset_in),
        .oneOrZed(oneOrZed),
        .Anode_Activate(Anode_Activate),
        .LED_out(LED_out)
    );

    // Clock generation
    initial begin
        clk100_extern = 0;
        forever #5 clk100_extern = ~clk100_extern;  // 100MHz Clock
    end

    // Stimulus and Test Scenarios
    initial begin
        // Initialize Inputs
        reset_in = 1;  // Apply reset
        oneOrZed = 0;  // Start with default data

        // Wait for the reset to propagate
        #100;
        reset_in = 0;

        // Change data mode
        #300000  $finish;  // End simulation after some time
    end

           //colsA MUST == colsB before the implicit transposition
    parameter rowsA = 1; //rows can differ, and will define the output arr
    parameter colsA = 784;
    
    // treat matB according to these dims. the transposition will happen at the end bc we feed the rows as cols
    parameter rowsB = 110; // this represents how the arr is stored in ram and how we will read it in
    parameter colsB = 784;
    
    parameter rowsOut = rowsA; // each row is a chain
    parameter colsOut = rowsB; // in each row(chain), the col is the specific chainMod
    
    wire [31:0] modSums [0:rowsOut-1][0:colsOut-1];

    genvar i, j;
    generate
        for (i = 0; i < rowsOut; i = i + 1) begin : chains

            for (j = 0; j < colsOut; j = j + 1) begin : mods
                assign modSums[i][j] = uut.nn.mm1.chains[i].mods[j].u_chainMod.sum;
            end

        end
    endgenerate
    
    
        parameter rowsA2 = 1; //rows can differ, and will define the output arr
    parameter colsA2 = 110;
    
    // treat matB according to these dims. the transposition will happen at the end bc we feed the rows as cols
    parameter rowsB2 = 10; // this represents how the arr is stored in ram and how we will read it in
    parameter colsB2 = 110;
    
    parameter rowsOut2 = rowsA2; // each row is a chain
    parameter colsOut2 = rowsB2; // in each row(chain), the col is the specific chainMod
    
    wire [31:0] modSums2 [0:rowsOut2-1][0:colsOut2-1];

    genvar i2, j2;
    generate
        for (i2 = 0; i2 < rowsOut2; i2 = i2 + 1) begin : chains2

            for (j2 = 0; j2 < colsOut2; j2 = j2 + 1) begin : mods2
                assign modSums2[i2][j2] = uut.nn.mm2.chains[i2].mods[j2].u_chainMod.sum;
            end

        end
    endgenerate
    
    
     wire matm1Finished;
    assign matm1Finished = uut.nn.mm1.finished;
    wire matm2Finished;
    assign matm2Finished = uut.nn.mm2.finished;
    
    
    
   wire [3:0] vga_red, vga_green,vga_blue;
   
   assign vga_red = uut.vga_red;
   assign vga_green = uut.vga_green;
   assign vga_blue = uut.vga_blue;
   
   wire [16:0] vga_addr_out;
   wire [11:0] vga_data_in;
   wire clk25;
   assign clk25 = uut.clk25;
   
   assign vga_addr_out = uut.vga_addr_out;
   assign vga_data_in = uut.vga_display.frame_pixel;
   
   assign vga_internal_h = uut.vga_display.frame_pixel;
   
   wire  [31:0] addrA_mapped;
   
   assign addrA_mapped = uut.addrA_mapped;
   
   wire [31:0] weightsZero;
   assign weightsZero = uut.nn.data_busB[31:0];


   
    
    

endmodule
