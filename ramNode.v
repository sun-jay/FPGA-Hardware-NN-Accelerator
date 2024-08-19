module customROM #(
    parameter WIDTH = 8,
    parameter DEPTH = 16,
    parameter DEPTH_LOG = $clog2(DEPTH),
    parameter MEM_FILE = "wm1_784_0.mem"

)(
    input clk,
    input [15:0] addr_rd,
    output reg [WIDTH-1:0] data_out
);

// Declare the ROM array
reg [WIDTH-1:0] rom [0:DEPTH-1];

initial begin
    $readmemb(MEM_FILE, rom, 0, DEPTH-1);
end

always @(posedge clk) begin
    // Fetch data from ROM if address is valid
    if (addr_rd < DEPTH) begin
        data_out <= rom[addr_rd];
    end else begin
        data_out <= 0;
    end
    
end

endmodule
