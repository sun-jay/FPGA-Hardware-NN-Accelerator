module latency_gen #(
    parameter LATENCY = 1,     // Number of clock cycles to delay
    parameter WIDTH = 8        // Bit width of the signal
)(
    input wire reset,
    input wire clk,                     // Clock signal
    input wire [WIDTH-1:0] signal_in,   // Input signal
    output wire [WIDTH-1:0] signal_out  // Output delayed signal
);
    
    generate
        if (LATENCY < 1) begin
            assign signal_out = signal_in;
        end else begin
        
            integer i;
            reg [WIDTH-1:0] sig_pipeline [0:LATENCY-1];
            
            always @(posedge clk or posedge reset) begin
                if (reset) begin
                    for (i = 0; i < LATENCY; i = i + 1) begin
                        sig_pipeline[i] <= 0;
                    end
                end else begin
                    sig_pipeline[0] <= signal_in;
                    for (i = 1; i < LATENCY; i = i + 1) begin
                        sig_pipeline[i] <= sig_pipeline[i-1];
                    end
                end
            end
            
            assign signal_out = sig_pipeline[LATENCY-1];
        end
    endgenerate
endmodule