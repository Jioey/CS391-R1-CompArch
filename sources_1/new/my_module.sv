`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/28/2025 03:56:18 PM
// Design Name: 
// Module Name: my_module
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


module my_module #(
    parameter integer LENGTH = 8
)(
    // [Last accessible index (i.e. length-1) : 0]
    // input wire[7:0] in1,
    input wire[LENGTH-1:0] in1,
    input wire in2,
    output wire out1
);

reg counter;

//assign out1 = !in1;
assign out1 = in1[LENGTH-1] & in2;
//assign out1 = (cond) ? (in1[LENGTH-1] & in2) : in2;

endmodule
