`timescale 1ns/1ps
`default_nettype none

module counter #(parameter WIDTH = 4) (
    input wire clk,                 // Clock
    input wire rst_n,               // Active low reset
    input wire en,                  // Enable the counter (chip select)
    input wire dn,                  // Set 1 to count down
    input wire load,                // Set 1 to load user input
    input wire [WIDTH-1:0] data,    // Input data
    output reg [WIDTH-1:0] count    // Output of the counter
);

    always @(posedge clk or negedge rst_n) begin     // Async active low reset
        if(~rst_n) begin
            count <= {WIDTH{1'b0}};
        end else if (en) begin
            if (load) begin
                count <= data;
            end else if (dn) begin
                count <= count - 1;
            end else begin
                count <= count + 1;
            end
        end else begin
            count <= count;
        end
    end

endmodule
