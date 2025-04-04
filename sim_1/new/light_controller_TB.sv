`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/16/2025 12:06:12 PM
// Design Name: 
// Module Name: light_controller_tb
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


module light_controller_tb( );

// variables that can be shared
bit clk1 = 0; // 1GHz
bit clk2 = 0; // 100 MHz
bit rst = 0;
bit button;

// Controller 1 -- N = 1
bit[2:0] state1;
light_controller #(
    .N(1) // Overwrites parameter
) test_light_1 (
    .clk(clk1),
    .rst(rst),
    .button(button),
    .light_state(state1) // output
);

// Controller 2 -- N = 10
bit[2:0] state2;
light_controller #(
    .N(10) // Overwrites parameter
) test_light_2 (
    .clk(clk1),
    .rst(rst),
    .button(button),
    .light_state(state2) // output
);

// Controller 3 -- 100ns state change
    // w 1GHz clock, 100ns = 100 cycles
bit[2:0] state3;
light_controller #(
    .N(100) // Overwrites parameter
) test_light_3 (
    .clk(clk1),
    .rst(rst),
    .button(button),
    .light_state(state3) // output
);

// Controller 4 -- 3s with 100MHz clock (clk2)
    // 3s = 300,000,000 cycles
bit[2:0] state4;
light_controller #(
    .N(300000000) // Overwrites parameter
) test_light_4 (
    .clk(clk2),
    .rst(rst),
    .button(button),
    .light_state(state4) // output
);

always #5ps clk1=~clk1; // simualte clock (1GHz = 10ps period)
always #5ns clk2=~clk2; // simualte clock (100MHz = 10ns period)
    
initial begin
    button = 1;
    #20ps;
    
    // Test rst
    button = 0;
    rst = 1;
    #10ps;
    button = 1;
    rst = 0;
    #100ns;   
    
    // Test Button off
    button = 0;
    #30ns;
    
    // Test cycles
    button = 1;
end

endmodule
