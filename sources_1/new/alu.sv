`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/29/2025 12:36:31 PM
// Design Name: 
// Module Name: alu
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


module alu # (
    parameter OP_WIDTH = 8
)(
    input wire[OP_WIDTH-1:0] op1,
    input wire[OP_WIDTH-1:0] op2,
    input wire[3:0] control,
    output wire error,
    output logic[OP_WIDTH-1:0] res
);

assign error = (control > 4'b0111) && (control != 4'b1000) && (control != 4'b1101);

// Organized to fit RISC-V
always_comb begin
    case (control) 
        4'b0000: res = op1 + op2; // ADD       
        4'b1000: res = op1 - op2; // SUB
        4'b0001: res = (op1 << op2); // Unsigned (Logical) Left shift
        4'b0010: res = op1 < op2; // Less Than
        4'b0011: res = $unsigned(op1) < $unsigned(op2); // Less Than U(unsigned)
        4'b0100: res = op1 ^ op2; // XOR
       
        4'b0101: res = (op1 >> op2); // Unsigned (Logical) Right Shift
        // note: most significant bit in control set to 1 here to differentiate signed & unsigned
        4'b1101: res = $unsigned($signed(op1) >>> $signed(op2)); // Signed (Arithmatic) Right Shift
       
        4'b0110: res = op1 | op2; // OR        
        4'b0111: res = op1 & op2; // AND

//        default: error = 1; // Undefined
    endcase
end
endmodule
