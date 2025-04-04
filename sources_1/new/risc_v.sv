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
    input wire[1:0] bresp,
    input wire bvalid,
    output reg[19:0] awaddr,
    output reg awvalid,
    output reg wvalid,
    output reg[31:0] wdata,
    output reg bready
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
reg[3:0] cu_state = 0;
reg[reg_size-1:0] current_inst;
reg[19:0] pc = 0; // 20-bit araddr (from bram size)

assign ready = cu_state == 0;

// Reading Instruction
always @(posedge clk) begin
    if (rst || ~start) begin
        cu_state <= 0;
        current_inst <= 0;
        error <= 0;
        we <= 0;

        arvalid <= 0;
        araddr <= 0;
        done <= 0;
        pc <= 0;
    end else begin
        case (cu_state) 
        0: begin // CYCLE 0 - fetch inst from BRAM
            if (arready) begin
                arvalid <= 1;
                araddr <= pc;
                rready <= 1;
                cu_state <= 1;
            end
            // else stay in this state and wait
        end

        1: begin // CYCLE 1 - Wait for BRAM and load reg file selects (DECODE)
            if (rvalid && araddr == pc) begin
                arvalid <= 0;
                rready <= 0;
                current_inst <= rdata;

                case (rdata[6:0])
                    7'b1110011: begin // ebreak - halts execution
                        // NOTE: this opcode can also be ecall
                        cu_state <= 0;
                        done <= 1;
                    end

                    7'b0110111: begin // lui
                        error <= 0; // reset error

                        we <= 1;
                        rd <= rdata[11:7];
                        d_in <= rdata[31:12] << 12;
                        // note: 1 cycle is enough for lui
                        cu_state <= 7;
                    end
                    
                    7'b0010011, 7'b0000011, 7'b0110011: begin // I-, I-Load, and R-Type
                        error <= 0; // reset error
                        we <= 0; // disable register write

                        if (rdata[6:0] == 7'b0000011) // I-Load
                            alu_control <= 0; // set alu to Add
                        else if ((rdata[14:12] == 3'b001 || rdata[14:12] == 3'b101) && rdata[31:25] == 7'h20) 
                            alu_control <= {1'b1, rdata[14:12]}; // funct3, set extra bit for SUB & SRA
                        else 
                            alu_control <= {1'b0, rdata[14:12]}; // funct3
                        
                        // Load Reg File select inputs
                        rd <= rdata[11:7];
                        rs <= rdata[19:15];
                        rt <= rdata[24:20]; // unused for I-types
                        
                        cu_state <= 2;
                    end

                    7'b0100011: begin // S-Type
                        error <= 0; // reset error
                        we <= 0; // disable register write

                        alu_control <= 0; // set alu to Add
                        // Load Reg File select inputs
                        rs <= rdata[19:15]; // rs1
                        rt <= rdata[24:20]; // rs2

                        cu_state <= 2;
                    end

                    7'b1100011: begin // B-Type
                        error <= 0; // reset error
                        we <= 0; // disable register write

                        // match inst funct3
                        case (rdata[14:12])
                            0: alu_control <= 4'b1000; // sub (is zero if two operands are equal)
                            1: alu_control <= 4'b0100; // xor, same as !=
                            4, 5, 7: alu_control <= 4'b0010; // Lt, Gte, Gte (Unsigned) respectively, this bc Gte is flipped input Lt
                            6: alu_control <= 4'b0011; // Lt (Unsigned)
                            default: begin
                                error <= 1;
                                cu_state <= 7;
                            end
                        endcase

                        if (rdata[14:12] == 5 || rdata[14:12] == 7) begin
                            // Flipping rs1 and rs2 for Gte
                            rs <= rdata[24:20]; // rs2
                            rt <= rdata[19:15]; // rs1 
                        end else begin
                            rs <= rdata[19:15]; // rs1
                            rt <= rdata[24:20]; // rs2
                        end 

                        cu_state <= 2;
                    end
                    
                    default: error <= 1;
                endcase
            end
        end

        2: begin // CYCLE 2 - load ALU operands (EXECUTE..sorta)
            case (current_inst[6:0])
                7'b0010011: begin // I-type
                    alu_op1 <= $isunknown(rsv) ? 0: rsv;

                    if (current_inst[14:12] == 3'b001 || current_inst[14:12] == 3'b101) // funct3 1 & 5 only takes imm[4:0]
                        alu_op2 <= current_inst[4:0];
                    else
                        alu_op2 <= current_inst[31:20];

                    cu_state <= 4; // Skip mem access
                end

                7'b0000011: begin // I-Load
                    alu_op1 <= $isunknown(rsv) ? 0: rsv;
                    alu_op2 <= current_inst[31:20];

                    cu_state <= 3; // Move state to mem access
                end

                7'b0110011: begin  // R-Type
                    alu_op1 <= $isunknown(rsv) ? 0: rsv;
                    alu_op2 <= $isunknown(rtv) ? 0: rtv;

                    cu_state <= 4; // Skip mem access
                end

                7'b0100011: begin // S-Type
                    alu_op1 <= $isunknown(rsv) ? 0: rsv; // rs1
                    alu_op2 <= {current_inst[31:25], current_inst[11:7]}; // imm

                    cu_state <= 3; // Move state to mem access
                end

                7'b1100011: begin // B-Type
                    alu_op1 <= $isunknown(rsv) ? 0: rsv;
                    alu_op2 <= $isunknown(rtv) ? 0: rtv;

                    cu_state <= 7; // Skip to final step to evaluate branch
                end
            endcase
        end

        3: begin // CYCLE 3 - MEMORY ACCESS
            case (current_inst[6:0])
                7'b0000011: begin // I-Load
                    arvalid <= 1;
                    araddr <= alu_res;
                    rready <= 1;

                    cu_state <= 4; // Move to write back
                end

                7'b0100011: begin // S-Type
                    // write to memory
                    awvalid <= 1;
                    wvalid <= 1;
                    awaddr <= alu_res;
                    case (current_inst[14:12]) // funct3: decides store data size
                        3'b000: wdata <= rtv[7:0]; // 0x0 Store Byte
                        3'b001: wdata <= rtv[15:0]; // 0x1 Store Half
                        3'b010: wdata <= rtv[31:0]; // 0x2 Store Word
                        default: begin
                            error <= 1;
                            cu_state <= 7;
                        end
                    endcase

                    cu_state <= 5; // Move to mem response stage
                end
            endcase
        end

        4: begin // CYCLE 4 - WRITE BACK
            if (alu_err) begin // don't write if error
                we <= 0;
                error <= 2;
            end else if (rd == 0) begin // don't write to 0 reg
                we <= 0;
            end else begin // otherwise, write to reg, based on inst
                case (current_inst[6:0])
                    7'b0000011: begin // I-Load
                        if (rvalid) begin
                            arvalid <= 0;
                            we <= 1;
                            // match funct3 to load size
                            case (current_inst[14:12]) 
                                0: d_in <= rdata[7:0];
                                1: d_in <= rdata[15:0];
                                2: d_in <= rdata[31:0];
                                // bruh why is there no 3
                                // 4 & 5 are zero extended
                                4: d_in <= {24'b0, rdata[7:0]}; 
                                5: d_in <= {16'b0, rdata[15:0]};

                                default: error <= 1;
                            endcase

                            // set CU back to ready after success
                            cu_state <= 7; 
                        end else // Otherwise stay in this cycle and wait for memory
                            we <= 0;
                    end

                    7'b0110011, 7'b0010011: begin // I- and R-Type
                        // write alu result to register
                        we <= 1;
                        d_in <= alu_res;

                        // set CU back to ready again
                        cu_state <= 7; 
                    end
                endcase
            end
        end

        5: begin // Mem Response: Wait for mem finish writing
            if (bvalid) begin
                // set error if write error occurs
                if (bresp > 1) error <= 3; 
                
                // unset bready for axi
                awvalid <= 0;
                wvalid <= 0; 
                bready <= 0;

                // set CU back to ready again
                cu_state <= 7; 

            end else begin
                bready <= 1;
            end 
        end

        7: begin
            we <= 0;
            cu_state <= 0;

            if (rdata[6:0] == 7'b1100011 && // if B-Type
                // and cmp evaluated true
                ((current_inst[14:12] == 0 && alu_res == 0) // special case: For beq, alu_res would be 0 bc I'm using SUB
                || alu_res) // otherwise, alu_res = 1 for true
            ) begin
                // bits:       31   25         11    7
                // B-Type: imm[12|10:5] ... imm[4:1|11]
                pc <= pc + 4 + 4 * {{8{current_inst[31]}}, current_inst[7], current_inst[30:25], current_inst[11:8], 1'b0}; // add imm (last bit zero bc inst alignment in memory)
            end else begin
                pc <= pc + 4;
            end

            $display("Executed Instruction: %h OPCODE = %h", current_inst, current_inst[6:0]);
            $display("ALU Operand 1: %h, Operand 2: %h", alu_op1, alu_op2);
            $display("Result: %h (Stored in register x%d)", d_in, rd);
            $display("-----------------------------------------");
        end
        endcase
    end
end
endmodule