`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/31/2025 09:49:57 PM
// Design Name: 
// Module Name: risc_v_tb
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


module risc_v_tb( );

localparam I_op = 7'b0010011;
localparam R_op = 7'b0110011;
localparam LUI_op = 7'b0110111;
localparam I_Load_op = 7'b0000011;
localparam S_op = 7'b0100011;
localparam B_op = 7'b1100011;

localparam f3_ADD_SUB = 3'h0;
localparam f7_SUB = 7'h20;
localparam f3_XOR = 3'h4;
localparam f3_OR = 3'h6;
localparam f3_AND = 3'h7;
localparam f3_SLL = 3'h1;
localparam f3_SRL_SRA = 3'h5;
localparam f7_SRA = 7'h20;
localparam f3_LT = 3'h2;
localparam f3_LTU = 3'h3;

localparam f3_SW = 3'h2;
localparam f3_LW = 3'h2;

localparam f3_BEQ = 3'h0;
localparam f3_BGEU = 3'h7;

localparam i_1 = 12'b000000000001;
localparam i_2 = 12'b000000000010;
localparam i_3 = 12'b000000000011;
localparam i_5 = 12'b000000000101;
localparam i_100 = 12'b000001100100;
localparam i_F = 12'b111111111111;

localparam x0 = 5'b00000;
localparam t0 = 5'b00001; // x1
localparam t1 = 5'b00010; // x2
localparam t2 = 5'b00011; // x3



bit clk = 0;
bit rst = 0;
bit valid = 1;
bit[1:0] error;
reg start = 0;
wire done;

// Part 1.2: Instantiate BRAM
wire awready;
bit awvalid;
bit[19:0] awaddr;
wire wready;
bit wvalid;
bit[31:0] wdata;
bit bready;
wire bvalid;
wire[1:0] bresp;
wire arready;
reg arvalid;
reg[19:0] araddr;
reg rready;
wire rvalid;
wire[31:0] rdata;

reg _rst;
reg _awvalid;
reg[19:0] _awaddr;
reg _wvalid;
reg[31:0] _wdata;
reg _bready;

always @ (posedge clk) begin
    _rst <= rst;
    _awvalid <= awvalid;
    _awaddr <= awaddr;
    _wvalid <= wvalid;
    _wdata <= wdata;
    _bready <= bready;
end

axi_bram_ctrl_0 bram(
    .s_axi_aclk(clk),
    .s_axi_aresetn(~rst),
    .s_axi_araddr(araddr),
    .s_axi_arprot(3'b000),
    .s_axi_arready(arready),
    .s_axi_arvalid(arvalid),
    .s_axi_awaddr(_awaddr),
    .s_axi_awprot(0),
    .s_axi_awready(awready),
    .s_axi_awvalid(_awvalid),
    .s_axi_bready(_bready),
    .s_axi_bresp(bresp),
    .s_axi_bvalid(bvalid),
    .s_axi_rdata(rdata),
    .s_axi_rready(rready),
    .s_axi_rvalid(rvalid),
    .s_axi_wdata(_wdata),
    .s_axi_wready(wready),
    .s_axi_wstrb('b1111),
    .s_axi_wvalid(_wvalid) 
);

// Instantiate Control Unit
risc_v cpu1 (
    .clk(clk),
    .rst(rst),
    .start(start),
    .done(done),
    .error(error),

    .rready(rready), // axi read
    .rvalid(rvalid),
    .rdata(rdata),
    .arready(arready),
    .arvalid(arvalid),
    .araddr(araddr),

    .awready(awready), // axi write
    .bvalid(bvalid),
    .awaddr(awaddr),
    .awvalid(awvalid),
    .wready(wready),
    .wvalid(wvalid),
    .wdata(wdata),
    .bready(bready),    
    .bresp(bresp)
);

always #1ps clk=~clk; // 2ps cycles

// define write to memory macro
`define write_inst(mem_addr, inst) \
    awvalid = 1; \
    wvalid = 1; \
    awaddr = mem_addr; \
    wdata = inst; \
    #8ps; \
    awvalid = 0; \
    wvalid = 0; \
    bready = 1; \
    #8ps; \
    bready = 0; \
    #8ps;

reg [7:0] my_memory[511:0]; // for loading .hex
initial begin 
    // NOTE: Reserving first 4 bits of mem address for instructions
    `write_inst(0, {7'h00, t0, t0, f3_XOR, t0, R_op})   // xor t0 t0 t0
    `write_inst(4, {20'hfa0af, t0, LUI_op})             // lui t0 20'hfa0af
    `write_inst(8, {12'h123, t0, f3_ADD_SUB, t0, I_op}) // add t0 t0 12'h123 
    `write_inst(12, {7'b1111111, x0, t0, f3_SW, 5'b10000, S_op}) // sw t0 12'b111111110000(x0)
    `write_inst(16, {12'b111111110000, x0, f3_LW, t1, I_Load_op}) // ld t1 12'b111111110000(x0)
    `write_inst(20, {7'b0000000, x0, t0, f3_BEQ, 5'b01010, B_op}) // beq x0 t0 20 -- Should not branch
    `write_inst(24, {7'b0000001, t0, x0, f3_BGEU, 5'b01000, B_op}) // bgeu t0 x0 40 -- Should branch (to 64)

    // Load binary file into BRAM
    $readmemh("C:/Users/joeyz/CS391_R1/CS391_R1.srcs/binaries/lab4_binary.hex", my_memory);
    #40ps; // NOTE: ps?
    // 480 = 64 + 4 * 104 -- num lines in .hex
    for (int i = 64; i < 480; i+=4) begin
        `write_inst(i, {my_memory[i+3], my_memory[i+2], my_memory[i+1], my_memory[i]})
    end 
    
    // start CPU
    start = 1;
    
    while (~done) begin
        #16ps;
    end
    
    $finish;
end
endmodule
