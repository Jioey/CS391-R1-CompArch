`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/17/2025 09:14:05 PM
// Design Name: 
// Module Name: register_file
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


module register_file # (
    parameter reg_size = 32,
    parameter reg_num = 16
)(
    input wire clk,
    input wire we, // write enable
    input wire[$clog2(reg_num)-1:0] rd, // write reg select
    input wire[reg_size-1:0] d_in, // data in
    input wire[$clog2(reg_num)-1:0] rs, // rev select
    input wire[$clog2(reg_num)-1:0] rt, // rtv select
    
    // For TESTING
    output reg[reg_size-1:0] regs_out[0:reg_num-1],
    // ----------
    
    output wire[reg_size-1:0] rsv,
    output wire[reg_size-1:0] rtv
);

reg[reg_size-1:0] regs[0:reg_num-1];
assign regs[0] = 0; // x0 should always be 0

// For TESTING
assign regs_out = regs;
// ----------

assign rsv = regs[rs];
assign rtv = regs[rt];

always @(negedge clk) begin 
    if (we && rd != 0) begin
        regs[rd] <= d_in;
    end
end

endmodule
