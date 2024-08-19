module mmV2#(
    //colsA MUST == colsB before the implicit transposition
    parameter integer rowsA = 3, //rows can differ, and will define the output arr
    parameter integer colsA = 4, 
    
    // in this mod, treat matB according to these dims. the transposition will happen at the end bc we feed the rows as cols
    // data should be stored in ram with these dims
    parameter integer rowsB = 3,  
    parameter integer colsB = 4,
    
    parameter integer matA_input_latency_lag_to_matb = 0,
    
    parameter integer index_bit_size = 16, //max number we can index is 32k (all our mats are smalelr than this)
    parameter integer bit_res = 32, //each int is 32 bits
    parameter integer frac_bits = 23 // 1 sign bit 8 int bits(implied) 23 fractional bits    
    )(    
    input clk,
    input reset,
    output [index_bit_size-1:0] addr_outA,
    input [bit_res-1:0] data_inA,
    
    output [index_bit_size*rowsB-1:0] addr_outB,
    input [bit_res*rowsB-1:0] data_inB,
    
    output reg [bit_res-1:0] res_out,
    input [index_bit_size-1:0]  res_addr,
    
    output reg finished
    );
    
    //define our array of chains.
    parameter rowsOut = rowsA; // each row is a chain
    parameter colsOut = rowsB; // in each row(chain), the col is the specific chainMod
    
    // one col from ram will be loaded in a loadStep.
    reg signed [index_bit_size-1:0] loadStepIdx, nextLoadStepIdx; 
        

    reg nextFinished;
    
    initial begin

        loadStepIdx = 16'b0;
        nextLoadStepIdx = 16'b0;

        finished = 0;
        nextFinished = 0;

    end
    

        always @(posedge clk) begin
        
        if (reset) begin

            loadStepIdx <= 16'b0;
            nextLoadStepIdx <= 16'b0;
            
            finished <= 0;
            nextFinished <= 0;
                        
        end else begin

            if (loadStepIdx < 65536) begin
                loadStepIdx <= loadStepIdx + 1;
            end
            finished <= loadStepIdx > rowsA+rowsB+colsA + matA_input_latency_lag_to_matb+1;
        end
    end
    
    assign addr_outA = loadStepIdx >= colsB ? colsB : loadStepIdx;

    wire [index_bit_size*rowsB-1:0] addr_outB_before_latency; // this is before we delay B to match the latency of A
    
    
    genvar row_ind;
    generate
        for (row_ind = 0; row_ind < colsOut; row_ind = row_ind + 1) begin : addrs

            assign addr_outB_before_latency[(row_ind+1)*index_bit_size-1 : index_bit_size*row_ind] = 
            
                //if reset, assign each addr out to outOfBounds(returns0), else {if its in the range for the stagger, loadstep-rowInd, else outOfBounds}
            
                reset ?
                    colsB + 1
                : (
                    ( 
                    (row_ind) >= 
                    ( ( loadStepIdx - colsB + 1 ) > 0 ? (loadStepIdx - colsB + 1 ): 0 ) // max(loadStepIdx - rowsOut + 1, 0)
                    &&
                    (row_ind) <=
                    ( loadStepIdx < ( rowsB -1 ) ? loadStepIdx : ( rowsB -1 ) ) // min(loadStepIdx ,  rowsOut-1 )
                    )
                    ?
                        loadStepIdx - row_ind
                    :
                        colsB + 1
                    );
        end
    endgenerate
    
    // delay the signal of B to match the latency of A so they are still aligned 
    latency_gen #(.WIDTH(index_bit_size*rowsB), .LATENCY(matA_input_latency_lag_to_matb))
    addrB_delay
    (.reset(reset),.clk(clk),.signal_in(addr_outB_before_latency), .signal_out(addr_outB));
    

    
    // there are exactly rowsOut rows of wires, but COLS+1 cols of wires 
    // this is so that we can use one generate block to create all the chainmods: the last col of chainModInWire goes nowhere.
    wire [bit_res-1:0] chainModInWireA [0:rowsOut-1][0:colsOut]; 
    wire [bit_res-1:0] chainModInWireB [0:rowsOut][0:colsOut-1]; 
    wire [bit_res-1:0] sum_outputs[0:rowsOut*colsOut-1]; // Array to store all sums
    
    //this code will generate our chainMods, each with an in and out wire (declared above
    genvar i, j;
    generate
        for (i = 0; i < rowsOut; i = i + 1) begin : chains

            for (j = 0; j < colsOut; j = j + 1) begin : mods
                chainMod u_chainMod (
                    .clk(clk),
                    .reset(reset),
                    
                    .numInSide(chainModInWireA[i][j]),
                    .numOutSide(chainModInWireA[i][j+1]),
                    
                    
                    .numInTop(chainModInWireB[i][j]),
                    .numOutTop(chainModInWireB[i+1][j]),
                    
                    .sum(sum_outputs[i*colsOut + j]) //sums accessible through the output array
                );
            end

        end
    endgenerate
    
    //here we connect the first element in each row to the corresponding element of ramLoadingReg
    // each clk, it will be pushed to the chain fabric
    genvar row;
    generate
        for (row = 0; row < rowsOut; row = row + 1) begin : link_ram_loading_regA
            assign chainModInWireA[row][0] = data_inA;
        end
    endgenerate
    
    
    //by nature of this loading mechanism, matB is automatically transposed, so A and B should have the same number of COLS
    genvar col;
    generate
        for (col = 0; col < colsOut; col = col + 1) begin : link_ram_loading_regB
            
            //connect the top row of chainmods directly to the data in
            assign chainModInWireB[0][col] = data_inB[ (col+1)*bit_res-1 : col*bit_res ];
        end
    endgenerate
    
    
    // allow the MM mod to be indexed like a RAM mod
    always @(posedge clk) begin
        if (res_addr < rowsOut * colsOut) begin
        res_out <= sum_outputs[res_addr % (rowsOut * colsOut)];
    end else begin
        res_out <= 0;
    end
 
end


    
endmodule
