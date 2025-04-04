`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/28/2025 04:11:56 PM
// Design Name: 
// Module Name: my_module_TB
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


module my_module_TB();

bit[3:0] in1_test = 4'b0111; // 4'b  it's a 4 bit binary
bit in2_test = 1;

bit output_test;

my_module #(
    .LENGTH(4) // Overwrites parameter
) localname_xyz (
    .in1(in1_test),
    .in2(in2_test),
    .out1(output_test)
);
// --
initial begin
#10ns;
in2_test = 0;
#10ns;
in1_test = 4'b1001;
#10ns;
$finish;
end


endmodule
