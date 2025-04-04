`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/16/2025 11:03:20 AM
// Design Name: 
// Module Name: light_controller
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


module light_controller # (
    parameter N
)(
    input wire clk,
    input wire rst,
    input wire button,
    output wire[2:0] light_state // 3'd0 corresponds to light turned off,
);                              // while 3'd1 to 3'd7 correpond to different colors

int counter = 0;
reg[2:0] light_reg = 3'b000;

assign light_state = light_reg;

always @(posedge clk or posedge rst or posedge button or negedge button) begin
    if (rst) begin
        light_reg = 3'b000;
        counter = 0;
    end
    
    if (button) begin
        // init button press
        if (light_reg == 3'b000) begin
            light_reg = 3'b001;
        end 
        
        // increment light_reg when N cycles reached
        if (counter == N) begin
            if (light_reg == 3'b000) begin // wrap around
                light_reg = 3'b001;
            end else begin                // increment light state
                light_reg += 1;
                counter = 0;
            end
        end else begin // otherwise increment counter
            counter ++;
        end
    end else begin // turn light off if button not pressed
        light_reg = 3'b000;
        counter = 0;
    end
end
endmodule