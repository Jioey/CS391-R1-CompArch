`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/17/2025 09:40:33 PM
// Design Name: 
// Module Name: register_file_tb
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


module register_file_tb( );

bit clk = 0;
bit we;
bit[3:0] rd;
bit[31:0] d_in;
bit[3:0] read1;
bit[3:0] read2;
bit[31:0] read1_d;
bit[31:0] read2_d;
bit[31:0] regs[0:15];

register_file # (
    .reg_size(32),
    .reg_num(16)
) reg_1 (
    .clk(clk),
    .we(we),
    .rd(rd),
    .d_in(d_in),
    .rs(read1),
    .rt(read2),
    
    .regs_out(regs),
    .rsv(read1_d),
    .rtv(read2_d)
);

always #5ps clk=~clk; // 1GHz clock

initial begin
    // write r0
    we = 1;
    rd = 4'b0000;
    d_in = 32'b11111111111111111111111111111111;
    #20ps;
    
    // write r1
    rd = 4'b0001;
    d_in = 32'b00001111111111111111111111110000;
    #20ps;
    
    // write r8
    rd = 4'b1000;
    d_in = 32'b00000000000000000000000000000001;
    #20ps;
    
    // read r0 and r8
    we = 0;
    read1 = 4'b0000;
    read2 = 4'b1000;
    // changing d_in should not update reg values here
    rd = 4'b0000;
    d_in = 32'b00000000000000000000000000000000;
    #20ps;
    
    // read r1 and r2 (unwritten)
    read1 = 4'b0001;
    read2 = 4'b0010;
    #20ps;
    $finish;
end
endmodule
