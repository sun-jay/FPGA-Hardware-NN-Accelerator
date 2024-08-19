`timescale 1ns / 1ps


//**** huge optimization potential: after all the data is loaded from ram, we still waste time in the load phase fetching unused numns
// we should claculate when the loading is all done and do back to back pushes thereafter

module MM_Unit #(
    //colsA MUST == colsB before the implicit transposition
    parameter integer rowsA = 3, //rows can differ, and will define the output arr
    parameter integer colsA = 4, 
    
    // in this mod, treat matB according to these dims. the transposition will happen at the end bc we feed the rows as cols
    // data should be stored in ram with these dims
    parameter integer rowsB = 3,  
    parameter integer colsB = 4,
    
    parameter integer ram_read_latency = 3,
    
    parameter integer index_bit_size = 16, //max number we can index is 32k (all our mats are smalelr than this)
    parameter integer bit_res = 32, //each int is 32 bits
    parameter integer frac_bits = 23 // 1 sign bit 8 int bits(implied) 23 fractional bits
  
    
)(  
    
    input clk,
    input reset,
    output [index_bit_size-1:0] addr_outA,
    input [bit_res-1:0] data_inA,
    
    output [index_bit_size-1:0] addr_outB,
    input [bit_res-1:0] data_inB,
    
    output reg [bit_res-1:0] res_out,
    input [index_bit_size-1:0]  res_addr,
    
    output reg finished
);
    
    // we will assume all 15 bit numbers temporarily for simplicity

    // example architecture -- all 3 Fs are one feeder, which has a 2d array of M's. M's are connected by chainModInWires (-)
    // ram will iteratively load the feeder, then once feeder is done with the load phase, it will send the data to first col of ChainMods
    
    //           / F-M-M-M-M-
    //       RAM-- F-M-M-M-M-
    //           \ F-M-M-M-M-

    
    //define our array of chains.
    parameter rowsOut = rowsA; // each row is a chain
    parameter colsOut = rowsB; // in each row(chain), the col is the specific chainMod
    
    // Register arrays for holding current input values and states
    reg [bit_res-1:0] ramLoadingRegA [0:rowsOut-1]; // size rowsA
    reg [bit_res-1:0] ramLoadingRegB [0:colsOut-1]; // size rowsB
    
    // this corresponds with the current row that we are loading data for -- it is incremented ROWS times during a single LOAD phase
    reg signed [index_bit_size-1:0] curChainIdx, nextChainIdx; 
    
    // one col from ram will be loaded in a loadStep. It is incremented after a whole LOAD phase completes
    // corresponds with the number of columns for now, but this can change
    reg signed [index_bit_size-1:0] loadStepIdx, nextLoadStepIdx; 
    
    reg state, nextState;
    
    reg [bit_res-1:0] data_in_regA;
    reg [bit_res-1:0] data_in_regB;
    
    reg nextFinished;
    
    initial begin
        curChainIdx = 16'b0;
        nextChainIdx = 16'b0;
        
        loadStepIdx = 16'b0;
        nextLoadStepIdx = 16'b0;
        
        state = LOAD;
        nextState = LOAD;
        
        finished = 0;
        nextFinished = 0;

    end
    
    // State definitions for state machine
    
    localparam LOAD = 0;
    localparam PUSH = 1;

    
    
    // State machine driver
    always @(posedge clk) begin
    
        data_in_regA <= data_inA;
        data_in_regB <= data_inB;
        
        if (reset) begin
            state <= LOAD;
            nextState <= LOAD;

            loadStepIdx <= 16'b0;
            nextLoadStepIdx <= 16'b0;
            
            finished <= 0;
            nextFinished <= 0;
                        
        end else begin
            state <= nextState;
            curChainIdx <= nextChainIdx;
            loadStepIdx <= nextLoadStepIdx;
            
            finished <= nextFinished;
        end
    end
    
    // these are teh same for now, but they are separate to make potential future optimizations easier
    assign addr_outA = curChainIdx * colsA + loadStepIdx - curChainIdx;
    assign addr_outB = curChainIdx * colsA + loadStepIdx - curChainIdx;
        
    always @(*) begin
        case (state)
            LOAD: begin
            
                // the data_in_reg will be data requested by ADDR exatly 3 clock widths after ADDR changes
                // for this reason we wait 3 clocks from the point where we changed ADDR, then we load data_in_reg into our load_reg
                // at the beginning of our LOAD phase, we wait for 3 clocks after sending the first addr before we start loading
                            
                if (curChainIdx >= ram_read_latency) begin 
                    
                    // treat curChainIdx-3 like curChainIdx. this simply adjusts for ram latency.
                    if ( 
                        (curChainIdx- ram_read_latency) >= 
                        ( ( loadStepIdx - colsA + 1 ) > 0 ? (loadStepIdx - colsA + 1 ): 0 ) // max(loadStepIdx - rowsOut + 1, 0)
                        &&
                        (curChainIdx - ram_read_latency) <=
                        ( loadStepIdx < ( rowsA -1 ) ? loadStepIdx : ( rowsA -1 ) ) // min(loadStepIdx ,  rowsOut-1 )
                        )begin
                    
                        ramLoadingRegA[curChainIdx- ram_read_latency ] = data_in_regA;
                        
                    end else begin // if outside of the stagger range
                    
                        if (curChainIdx-ram_read_latency <= rowsA - 1 + ram_read_latency) begin // but still within a valid slot in the loadingReg
                            ramLoadingRegA[curChainIdx-3] = 0;
                        end 

                    end
                    
                    if ( 
                        (curChainIdx- ram_read_latency ) >= 
                        ( ( loadStepIdx - colsB + 1 ) > 0 ? (loadStepIdx - colsB + 1 ): 0 ) // max(loadStepIdx - rowsOut + 1, 0)
                        &&
                        (curChainIdx- ram_read_latency ) <=
                        ( loadStepIdx < ( rowsB -1 ) ? loadStepIdx : ( rowsB -1 ) ) // min(loadStepIdx ,  rowsOut-1 )
                        )begin
                    
                        ramLoadingRegB[curChainIdx- ram_read_latency ] = data_in_regB;
                        
                    end else begin // if outside of the stagger range
                        if (curChainIdx- ram_read_latency <= rowsB - 1 + ram_read_latency ) begin // but still within a valid slot in the loadingReg (which is len rowsB)
                            ramLoadingRegB[curChainIdx- ram_read_latency ] = 0;
                        end 

                    end
                    
                       
                    
                end
                // chainIdx should iterate from 0 to max(rowsA,rowsB) for each LOAD we send
                if (curChainIdx >= (  rowsA >= rowsB ? rowsA : rowsB  ) - 1 + ram_read_latency ) begin // if we just loaded the last ROW
                    nextChainIdx = 0; // reset chainIdx
                    nextLoadStepIdx = loadStepIdx + 1; // increment the load step (this will only matter after push is done)
                    nextState = PUSH; // we are now ready to push the data
                end else begin // if we didnt load the last row, we want to now
                    nextChainIdx = curChainIdx + 1;
                end
                
            end
            PUSH: begin
           
                // the enable pin for the chains IS state (PUSH = 1)
                nextState = LOAD; // Transition back to LOAD after PUSH
                
                if (loadStepIdx >= rowsA + rowsB + colsA)begin
                    nextFinished = 1;
                end 
            end

        endcase
    end
    
    
    
    
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
                    // the clock (enable) is just the state, which is 0 in load and 1 in push
                    .clk(state),
                    .reset(reset),
                    
                    .numInSide(chainModInWireA[i][j]),
                    .numOutSide(chainModInWireA[i][j+1]),
                    
//                    .numInTop(chainModInWireA[i][j]),
//                    .numOutTop(chainModInWireA[i][j+1]),
                    
                    .numInTop(chainModInWireB[i][j]),
                    .numOutTop(chainModInWireB[i+1][j]),
                    
                    .sum(sum_outputs[i*colsOut + j]) //sums accessible through the output array
                );
            end

        end
    endgenerate
    
    //here we connect the first element in each row to the corresponding element of ramLoadingReg
    // each PUSH phase, it will be pushed to the chain fabric
    genvar row;
    generate
        for (row = 0; row < rowsOut; row = row + 1) begin : link_ram_loading_regA
            assign chainModInWireA[row][0] = ramLoadingRegA[row];
        end
    endgenerate
    
    
    //by nature of this loading mechanism, matB is automatically transposed, so A and B should have the same number of COLS
    genvar col;
    generate
        for (col = 0; col < colsOut; col = col + 1) begin : link_ram_loading_regB
            assign chainModInWireB[0][col] = ramLoadingRegB[col];
        end
    endgenerate


    reg [index_bit_size-1:0] address_pipeline [0:ram_read_latency-2];

// Pipeline registers for the address
    integer k;
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (k = 0; k < ram_read_latency-1; k = k + 1) begin
                address_pipeline[k] <= 0;
            end
            res_out <= 16'd0;
        end else begin
            // Shift the address through the pipeline
            if (ram_read_latency > 1) begin
                address_pipeline[0] <= res_addr;
                for (k = 1; k < ram_read_latency-1; k = k + 1) begin
                    address_pipeline[k] <= address_pipeline[k-1];
                end
                // Use the delayed address to access the output
                res_out <= sum_outputs[address_pipeline[ram_read_latency-2] % (rowsOut * colsOut)];
            end else begin
                // If no pipeline stages are needed, use the current address directly
                res_out <= sum_outputs[res_addr % (rowsOut * colsOut)];
            end
        end
    end
        


endmodule