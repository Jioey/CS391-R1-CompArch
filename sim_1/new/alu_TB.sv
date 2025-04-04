`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/29/2025 12:37:46 PM
// Design Name: 
// Module Name: alu_TB
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


module alu_TB();

bit[3:0] op1_test;
bit[3:0] op2_test;
bit[3:0] control_test;
bit[3:0] res_test;
bit err;

alu #(
    .OP_WIDTH(4) // Overwrites parameter
) test_alu (
    .op1(op1_test),
    .op2(op2_test),
    .control(control_test),
    .error(err),
    .res(res_test)
);

initial begin
    // NOT Tests
    op1_test = 4'b0001;
    op2_test = 4'b0000;
    control_test = 4'b0000;
    #5ps;
    assert (res_test == ~op1_test) else $finish;
    
    op2_test = 4'b0001;
    #5ps;
    assert (res_test == ~op1_test) else $finish;
    
    op1_test = 4'b0000;
    #5ps; 
    assert (res_test == ~op1_test) else $finish;
    
    // XOR Tests
    control_test = 4'b0001;
    #5ps; 
    assert (res_test == (op1_test ^ op2_test)) else $finish;
    
    op2_test = 4'b0000;
    #5ps; 
    assert (res_test == (op1_test ^ op2_test)) else $finish;
    
    op1_test = 4'b1111;
    #5ps; 
    assert (res_test == (op1_test ^ op2_test)) else $finish;
    
    // AND Tests
    control_test = 4'b0010;
    #5ps; 
    assert (res_test == (op1_test & op2_test)) else $finish;
    
    op2_test = 4'b0000;
    #5ps; 
    assert (res_test == (op1_test & op2_test)) else $finish;
    
    // OR Tests
    control_test = 4'b0011;
    #5ps;
    assert (res_test == (op1_test | op2_test)) else $finish;
    
    op1_test = 4'b0000;
    #5ps;
    assert (res_test == (op1_test | op2_test)) else $finish;
    
    // XNOR
    control_test = 4'b0100;
    #5ps; 
    assert (res_test == ~(op1_test ^ op2_test)) else $finish;
    
    op2_test = 4'b1111;
    #5ps; 
    assert (res_test == ~(op1_test ^ op2_test)) else $finish;
    
    op1_test = 4'b0101;
    #5ps; 
    assert (res_test == ~(op1_test ^ op2_test)) else $finish;
    
    // Left Shift (Signed & Unsigned)
    control_test = 4'b0101;
    #5ps; 
    assert (res_test == (op1_test << op2_test)) else $finish;
    
    op2_test = 4'b1001;
    #5ps; 
    assert (res_test == (op1_test << op2_test)) else $finish;
    
    op1_test = 4'b1111;
    #5ps; 
    assert (res_test == (op1_test <<< op2_test)) else $finish;
    
    // Right Shift (Unsigned)
    control_test = 4'b0110;
    #5ps; 
    assert (res_test == (op1_test >> op2_test)) else $finish;
    
    op1_test = 4'b1000;
    op2_test = 4'b0010;
    #5ps; 
    assert (res_test == (op1_test >> op2_test)) else $finish;
    
    // Right Shift (Signed)
    control_test = 4'b0111;
    #5ps; 
    assert (res_test == $unsigned($signed(op1_test) >>> $signed(op2_test))) else $finish;
    
    op1_test = 4'b1111;
    #5ps; 
    assert (res_test == $unsigned($signed(op1_test) >>> $signed(op2_test))) else $finish;
    
    // Add
    control_test = 4'b1000;
    #5ps; 
    assert (res_test == (op1_test + op2_test)) else $finish;
    
    op2_test = 4'b1111;
    #5ps; 
    assert (res_test == (op1_test + op2_test)) else $finish;
    
    // Subtract
    control_test = 4'b1001;
    #5ps; 
    assert (res_test == (op1_test - op2_test)) else $finish;
    
    op1_test = 4'b0000;
    #5ps; 
    assert (res_test == (op1_test - op2_test)) else $finish;
    
    // Less than
    control_test = 4'b1010;
    #5ps; 
    assert (res_test == {op1_test < op2_test, 3'b000}) else $finish;
    
    op1_test = 4'b1111;
    #5ps; 
    assert (res_test == {op1_test < op2_test, 3'b000}) else $finish;
    
    // Equal to
    control_test = 4'b1011;
    #5ps; 
    assert (res_test == {op1_test == op2_test, 3'b000}) else $finish;
    
    op2_test = 4'b1111;
    #5ps; 
    assert (res_test == {op1_test == op2_test, 3'b000}) else $finish;
    
    // Greater than
    control_test = 4'b1100;
    #5ps; 
    assert (res_test == {op1_test > op2_test, 3'b000}) else $finish;
    
    op1_test = 4'b1111;
    op2_test = 4'b0000;
    #5ps; 
    assert (res_test == {op1_test > op2_test, 3'b000}) else $finish;
    
    // Error  
    control_test = 4'b1101;
    #5ps; 
    assert (err == 1) else $finish;
    
    control_test = 4'b1111;
    #5ps; 
    assert (err == 1) else $finish;
    
    $finish;
end

endmodule
