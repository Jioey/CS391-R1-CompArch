`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/26/2025 04:26:01 PM
// Design Name: 
// Module Name: risc_v
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

module risc_v # (
    parameter reg_size = 32,
    parameter reg_num = 32
) (
    input wire clk,
    input wire rst,
    input reg start,
    output reg done,
    output reg[1:0] error,
    // error 1 is inst error, 2 is alu error, and 3 is mem error

    // BRAM Connectors
    input wire rvalid, // read
    input wire[31:0] rdata, 
    input wire arready,
    output reg rready, 
    output reg arvalid, 
    output reg[19:0] araddr,
    input wire awready, // write
    input wire bvalid,
    output reg[19:0] awaddr,
    output reg awvalid,
    input wire wready,
    output reg wvalid,
    output reg[31:0] wdata,
    output reg bready,
    input wire[1:0] bresp
);

// ALU
reg[reg_size-1:0] alu_op1;
reg[reg_size-1:0] alu_op2;
reg[3:0] alu_control;
wire[reg_size-1:0] alu_res;
wire alu_err;
alu #(
    .OP_WIDTH(reg_size)
) alu_1 (
    .op1(alu_op1),
    .op2(alu_op2),
    .control(alu_control),
    
    .res(alu_res),
    .error(alu_err)
);

// Register File
reg we;
reg[reg_size-1:0] d_in;
reg[reg_size-1:0] rsv;
reg[reg_size-1:0] rtv;
reg[$clog2(reg_num)-1:0] rd;
reg[$clog2(reg_num)-1:0] rs;
reg[$clog2(reg_num)-1:0] rt;
register_file # (
    .reg_size(reg_size),
    .reg_num(reg_num)
) reg_1 (
    .clk(clk),
    .we(we),
    .rd(rd), 
    .d_in(d_in),
    .rs(rs),
    .rt(rt),
    
    .rsv(rsv),
    .rtv(rtv)
);

// CONTROL UNIT STARTS HERE --------------------------------------
reg[5:0] cu_state = 0;
// reg[reg_size-1:0] current_inst;
reg[6:0] opcode = 0;
reg[2:0] funct3 = 0;
reg[6:0] funct7 = 0;
reg[11:0] i_imm = 0;
reg[11:0] s_imm = 0;
reg[12:0] b_imm = 0;
reg[20:0] u_imm = 0;

reg[19:0] pc = 0; // 20-bit araddr (from bram size)

assign ready = cu_state == 0;

// Reading Instruction
always @(posedge clk) begin
    if (rst || ~start) begin
        cu_state <= 0;
        error <= 0;
        we <= 0;

        arvalid <= 0;
        araddr <= 0;
        rready <= 0;
        done <= 0;
        pc <= 0;
    end else begin
        case (cu_state) 
        0: begin // fetch inst from BRAM
            arvalid <= 1;
            araddr <= pc;
            cu_state <= 1;
        end

        1: begin // Wait for addr read to be taken in
            if (arready) begin
                arvalid <= 0;
                rready <= 1;
                cu_state <= 2;
            end
        end

        2: begin // Decode the instruction
            if (rvalid) begin   
                rready <= 0;     

                if (rdata[6:0] == 7'b1110011) begin // ebreak - halts execution
                    // NOTE: this opcode can also be ecall
                    cu_state <= 0;
                    done <= 1;
                end else begin
                    opcode <= rdata[6:0];

                    // register selects
                    rd <= rdata[11:7];
                    rs <= rdata[19:15]; // rs1
                    rt <= rdata[24:20]; // rs2

                    funct3 <= rdata[14:12];
                    funct7 <= rdata[31:25];

                    i_imm <= rdata[31:20];
                    s_imm <= {rdata[31:25], rdata[11:7]};
                    // B-Type Imm: inst[12|10:5] ... inst[4:1|11]
                    b_imm <= {rdata[31], rdata[7], rdata[30:25], rdata[11:8], 1'b0}; // sign extended
                    u_imm <= rdata[31:12];

                    cu_state <= 3;
                end
            end
        end

        3: begin // Configuring alu or axi
            case (opcode)
                7'b0110011: begin // R-Type
                    alu_op1 <= rsv;
                    alu_op2 <= rtv;

                    if ((funct3 == 3'b001 || funct3 == 3'b101) && funct7 == 7'h20) // extra alu_control bit for SUB & SRA
                        alu_control <= {1'b1, rdata[14:12]};
                    else 
                        alu_control <= {1'b0, rdata[14:12]};
                    cu_state <= 4;
                end 

                7'b0010011: begin // I-type (no load)
                    alu_op1 <= rsv;

                    // alu_op2
                    if (funct3 == 3'b001 || funct3 == 3'b101) // funct3 1 & 5 only takes imm[4:0]
                        alu_op2 <= i_imm[4:0];
                    else
                        alu_op2 <= i_imm;

                    // alu control
                    if (funct3 == 3'b101 && i_imm[11:5] == 7'h20)
                        alu_control <= {1'b1, funct3}; // srai
                    else
                        alu_control <= {1'b0, funct3};

                    cu_state <= 4;
                end
                
                7'b0110111: begin // lui
                    alu_op1 <= u_imm;
                    alu_op2 <= 12;
                    alu_control <= 4'b0001; // left shift

                    cu_state <= 4;
                end

                7'b0100011: begin // S-Type
                    // Write, Step 1
                    awvalid = 1;
                    wvalid = 1;
                    awaddr = rsv + s_imm;
                    case (funct3) // funct3: decides store data size
                        3'b000: wdata <= rtv[7:0]; // 0x0 Store Byte
                        3'b001: wdata <= rtv[15:0]; // 0x1 Store Half
                        3'b010: wdata <= rtv[31:0]; // 0x2 Store Word
                        default: error <= 1;
                    endcase
                    
                    cu_state <= 10;
                end

                7'b0000011: begin // L-Type (I-Load)
                    // Read addr, Step 1
                    arvalid <= 1;
                    araddr <= rsv + i_imm;
                    rready <= 1;
                    cu_state <= 20;
                end

                7'b1100011: begin // B-Type
                    // match funct3 to alu_op for B-Type
                    case (funct3)
                        0: alu_control <= 4'b1000; // sub (is zero if two operands are equal) <-- Not sure about this too
                        1: alu_control <= 4'b0100; // xor, same as !=
                        4, 5, 7: alu_control <= 4'b0010; // Lt, Gte, Gte (Unsigned) respectively, this bc Gte is flipped input Lt
                        6: alu_control <= 4'b0011; // Lt (Unsigned)

                        default: error <= 1;
                    endcase

                    // Assigning alu_op
                    case (funct3)
                        5, 7: begin // Flipping rs1 and rs2 for Gte
                            alu_op1 <= rtv; // rs2
                            alu_op2 <= rsv; // rs1
                        end 
                        default: begin
                            alu_op1 <= rsv; // rs1
                            alu_op2 <= rtv; // rs2
                        end
                    endcase
                end

                default: begin // undefined opcode
                    error <= 1;
                    cu_state <= 9; // go to finish state
                end
            endcase
        end

        4: begin // Write back
            if (alu_err) begin
                error <= 1;
                cu_state <= 9;
            end else begin
                we <= 1;
                d_in <= alu_res;
                cu_state <= 9;
            end
        end

        9: begin // Finish state
            we <= 0;
            cu_state <= 0;

            if (opcode == 7'b1100011 && // if B-Type
                // and cmp evaluated true
                ((funct3 == 0 && alu_res == 0) // special case: For beq, alu_res would be 0 bc I'm using SUB
                || alu_res) // otherwise, alu_res = 1 for true
            )
                pc <= pc + 4 + 4 * b_imm;
            else
                pc <= pc + 4;

            $display("Executed Instruction: %h OPCODE = %h", {u_imm, rd, opcode}, opcode);
            $display("ALU Operand 1: %h, Operand 2: %h", alu_op1, alu_op2);
            $display("Result: %h (Stored in register x%d)", d_in, rd);
            $display("-----------------------------------------");
        end

        10: begin // S-Type, Write, Step 2
            if (awready && wready) begin
                awvalid = 0;
                wvalid = 0; 
                bready = 1;

                cu_state <= 11;
            end            
        end

        11: begin // S-Type, Write, Step 3
            if (bvalid) begin
                bready <= 0;
                if (bresp != 0) // bram error
                    error <= 1;

                cu_state <= 9; // to finish state
            end
        end

        20: begin // L-type, Step 2
            if (arready) begin // (not sure if this step is necessary, or can arvalid be set to 0 after rvalid too?)
                arvalid <= 0;
            end else if (rvalid) begin
                rready <= 0;
                // write to register file
                we <= 1;
                case (funct3) // match funct3 to load size
                    0: d_in <= {{16{rdata[7]}}, rdata[7:0]};
                    1: d_in <= {{8{rdata[15]}}, rdata[15:0]};
                    2: d_in <= rdata[31:0];
                    // bruh why is there no 3
                    // 4 & 5 are zero extended
                    4: d_in <= {24'b0, rdata[7:0]}; 
                    5: d_in <= {16'b0, rdata[15:0]};

                    default: error <= 1;
                endcase

                cu_state <= 9; // to finish state
            end 
        end

        endcase // endcase for state
    end // end if (rst...
end // end always block
endmodule