`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/07/2025 12:56:45 PM
// Design Name: 
// Module Name: risv_v_TB
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


module cu2_TB( );

bit clk = 0;
bit rst = 0;
bit[31:0] inst;
bit valid = 1;

bit[31:0] regs[31:0];
bit error;
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
    .s_axi_arprot(0),
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
control_unit cu (
    .clk(clk),
    .rst(rst),
    .start(start),

    .rready(rready),
    .rvalid(rvalid),
    .rdata(rdata), 
    .arready(arready),
    .arvalid(arvalid),
    .araddr(araddr),
    
    .cu_regs_out(regs),
    .done(done),
    .error(error)
);

always #1ps clk=~clk; // 2ps cycles

localparam I_op = 7'b0010011;
localparam R_op = 7'b0110011;
localparam LUI_op = 7'b0110111;
// localparam ERR_op = 6'b001101; // not supported opcode

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
localparam x4 = 5'b00100;
localparam x5 = 5'b00101;
localparam x6 = 5'b00110;
localparam x15 = 5'b01111;

// reg to store loaded mem binary
reg [7:0] my_memory[511:0];

initial begin
//    rst = 1;
//    #8ns;
//    rst = 0;
//    #8ns;

    // Load binary into BRAM
    $readmemh("C:/Users/joeyz/CS391_R1/CS391_R1.srcs/binaries/lab3_binary.hex", my_memory);

    #40ns;

    for (int i = 0; i < 352; i+=4) begin
        awvalid = 1;
        wvalid = 1;
        awaddr = i;
        wdata = {my_memory[i+3], my_memory[i+2], my_memory[i+1], my_memory[i]};
        #8ps;
        awvalid = 0;
        wvalid = 0;
        bready = 1;
        #8ps;
        bready = 0;
        #8ps;
    end
    
    // write ebreak
    awvalid = 1;
    wvalid = 1;
    awaddr = 352;
    wdata = 32'b11111111111111111111111111111111;
    #8ps;
    awvalid = 0;
    wvalid = 0;
    bready = 1;
    #8ps;
    bready = 0;
    #8ps;
    
    // start CPU
    start = 1;
    
    while (~done) begin
        #16ps;
    end

    // PART 1.1
    // 1. Check for x0
//    inst = {i_F, x0, f3_OR, x0, I_op};
//    #8ps;
//    inst = {i_100, x0, f3_ADD_SUB, x0, I_op};
//    #8ps;

//    // 2. Check for lui
//    inst = {20'hfa0af, t0, LUI_op};
//    #8ps;
//    inst = {20'h15f51, t1, LUI_op};
//    #8ps;

//    // 3. Check I-type 
//    inst = {12'h123, t0, f3_ADD_SUB, t2, I_op};
//    #8ps;
//    inst = {12'h800, t1, f3_ADD_SUB, t2, I_op};
//    #8ps;

//    inst = {i_F, t0, f3_XOR, t2, I_op};
//    #8ps;
//    inst = {i_F, t1, f3_AND, t2, I_op};
//    #8ps;
//    inst = {12'haaa, t0, f3_OR, t2, I_op};
//    #8ps;

//    // 4. Check R-type
//    inst = {12'ha0f, t0, f3_ADD_SUB, t0, I_op};
//    #8ps;
//    inst = {12'h5f1, t1, f3_ADD_SUB, t1, I_op};
//    #8ps;

//    inst = {7'h00, t0, t1, f3_ADD_SUB, t2, R_op}; //add t2, t0, t1
//    #8ps;
//    inst = {f7_SUB, t0, t1, f3_ADD_SUB, t2, R_op}; //sub t2, t0, t1
//    #8ps;
//    inst = {7'h00, t0, t1, f3_XOR, t2, R_op}; //xor t2, t0, t1
//    #8ps;
//    inst = {7'h00, t0, t1, f3_OR, t2, R_op}; //or t2, t0, t1
//    #8ps;
//    inst = {7'h00, t0, t1, f3_AND, t2, R_op}; //and t2, t0, t1
//    #8ps;

//    inst = {i_5, x0, f3_ADD_SUB, t1, I_op}; //addi, t1, x0, 5
//    #8ps;
//    inst = {7'h00, t0, t1, f3_SLL, t2, R_op}; //sll t2, t0, t1
//    #8ps;
//    inst = {7'h00, t0, t1, f3_SRL_SRA, t2, R_op}; //srl t2, t0, t1
//    #8ps;
    
    $finish;
end
endmodule
