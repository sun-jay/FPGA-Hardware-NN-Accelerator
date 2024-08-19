module DistRAM #(
    parameter WIDTH = 32,
    parameter DEPTH = 784,
    parameter NUM_NODES = 32,
    parameter MEM_FILE = "wm1_784_",
    parameter ADDR_WIDTH = 16  // Address width for each node
)(
    input clk,
    input [(ADDR_WIDTH*NUM_NODES)-1:0] addr_rd, // Single, large vector for address inputs
    output [(WIDTH*NUM_NODES)-1:0] data_out     // Single, large vector for data outputs
);


    // Generate instances of customROM for each node
    genvar i;
    generate
        for (i = 0; i < NUM_NODES; i = i + 1) begin : node
        
        // Calculate the ASCII values for each digit
            localparam [7:0] ascii_index0 = "0" + (i / 100);  // 100s digit
            localparam [7:0] ascii_index1 = "0" + ((i / 10) % 10);  // Tens digit
            localparam [7:0] ascii_index2 = "0" + (i % 10);  // Units digit
            
            // Construct filename using concatenation
            localparam filename = (i >= 100) ? { MEM_FILE, ascii_index0, ascii_index1, ascii_index2, ".mem" } :
                     (i >= 10)  ? { MEM_FILE, ascii_index1, ascii_index2, ".mem" } :
                                  { MEM_FILE, ascii_index2, ".mem" };
//            localparam filename = "wm1_784_31.mem";
            
            
            
            
            customROM #(
                .WIDTH(WIDTH),
                .DEPTH(DEPTH),
                .MEM_FILE(filename)
            ) rom_instance (
                .clk(clk),
                // Slice the vector for each address and data output
                .addr_rd(addr_rd[(i+1)*ADDR_WIDTH-1 : ADDR_WIDTH * i]),
//                .addr_rd(addr_rd[15:0]),
                .data_out(data_out[(i+1)*WIDTH-1 : WIDTH * i])
//                .data_out(data_out[31: 0])

            );
        end
    endgenerate

endmodule
