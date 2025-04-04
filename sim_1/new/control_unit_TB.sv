`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/17/2025 10:21:45 PM
// Design Name: 
// Module Name: control_unit_tb
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
module control_unit_tb( );

bit clk = 0;
bit rst = 0;
bit[31:0] inst;
bit valid = 1;

bit[31:0] regs[0:15];
bit ready;
bit error;

control_unit cu (
    .clk(clk),
    .rst(rst),
    .inst(inst),
    .valid(valid),
    
    .cu_regs_out(regs),
    .ready(ready),
    .error(error)
);

always #5ps clk=~clk; // 1GHz clock

localparam AND_op = 6'b000000;
localparam XOR_op = 6'b000010;
localparam SLL_op = 6'b000100;

localparam ERR_op = 6'b001101; // not supported opcode

localparam ORI = 6'b100001;
localparam EQI = 6'b101011;
localparam ADDI = 6'b101000;
localparam SRAI = 6'b100111;

localparam IMM_ONE = 18'b000000000000000001;
localparam IMM_TWO = 18'b000000000000000010;
localparam IMM_THREE = 18'b000000000000000011;
localparam IMM_F = 18'b111111111111111111;

localparam REG0 = 4'b0000;
localparam REG1 = 4'b0001;
localparam REG2 = 4'b0010;
localparam REG3 = 4'b0011;
localparam REG4 = 4'b0100;
localparam REG5 = 4'b0101;
localparam REG6 = 4'b0110;
localparam REG15 = 4'b1111;

localparam RESV = 14'b00000000000000;

initial begin
    // Load some values
    inst = {IMM_ONE, REG1, REG1, ORI};
    #20ps;
    inst = {IMM_TWO, REG2, REG2, ORI};
    #20ps;
    inst = {IMM_THREE, REG3, REG3, ORI};
    #20ps;
    inst = {IMM_F, REG4, REG4, ORI};
    #20ps;
    
    // Perform some stuff
    inst = {RESV, REG0, REG1, REG0, AND_op}; // using uninitialized register
    #20ps;
    inst = {RESV, REG3, REG1, REG4, XOR_op};
    #20ps;
    inst = {RESV, REG3, REG1, REG5, SLL_op};
    #20ps;
    
    // Perform some more IMM ops
    inst = {IMM_ONE, REG1, REG6, EQI}; // Should be true on REG6
    #20ps;
    inst = {IMM_TWO, REG2, REG2, ADDI}; // Should be 4 on REG2
    #20ps;
    
    // Error Testing
    inst = {IMM_THREE, REG4, REG15, SRAI};
    #5ps
    inst = {IMM_F, REG1, REG1, ORI}; // This should not be executed
    #5ps
    inst = {IMM_ONE, REG1, REG1, ERR_op}; // This should be the next inst, and err should be 1
    #30ps;
    
    
    #15ps;
    $finish;
end 
    
endmodule
