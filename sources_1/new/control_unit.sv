`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/11/2025 03:54:55 PM
// Design Name: 
// Module Name: control_unit
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
module control_unit # (
    parameter reg_size = 32,
    parameter reg_num = 32
) (
    input wire clk,
    input wire rst,
    input reg start,

    output reg rready, 
    input wire rvalid, // new
    input wire[31:0] rdata, 
    input wire arready, // new
    output reg arvalid, 
    output reg[19:0] araddr,
    
    // For TESTING
    output reg[reg_size-1:0] cu_regs_out[reg_num-1:0],
    // ----------
    
    output reg done,
    output reg error
);

// ALU variables
reg[reg_size-1:0] alu_op1;
reg[reg_size-1:0] alu_op2;
reg[3:0] alu_control;
wire[reg_size-1:0] alu_res;
wire alu_err;

// 32-bit ALU Instantiation --------------------------------------------
alu #(
    .OP_WIDTH(reg_size)
) alu_1 (
    .op1(alu_op1),
    .op2(alu_op2),
    .control(alu_control),
    
    .res(alu_res),
    .error(alu_err)
);
// ----------------------------------------------------------------

// Register File variables
reg we;
reg[reg_size-1:0] d_in;
reg[reg_size-1:0] rsv;
reg[reg_size-1:0] rtv;
reg[$clog2(reg_num)-1:0] rd;
reg[$clog2(reg_num)-1:0] rs;
reg[$clog2(reg_num)-1:0] rt;
reg[reg_size-1:0] regs_out[reg_num-1:0]; // TESTING
assign cu_regs_out = regs_out;
// Register File Instantiation ------------------------------------
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
    
    .regs_out(regs_out),
    .rsv(rsv),
    .rtv(rtv)
);
// ----------------------------------------------------------------

// Start of Control Unit Code --------------------------------------
reg[1:0] cu_state = 0;
reg[31:0] current_inst;
reg[19:0] pc = 0; // size of araddr

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
    end else if (cu_state == 0) begin // CYCLE 0 - fetch inst from BRAM
        if (arready) begin
            arvalid <= 1;
            araddr <= pc;
            pc <= pc + 4;
            rready <= 1;
            cu_state <= 1;
        end
        // else stay in this state and wait
    end else if (cu_state == 1) begin // CYCLE 1 - Wait for BRAM and load reg file selects (DECODE)
        if (rvalid) begin
            arvalid <= 0;
            rready <= 0;
            current_inst <= rdata;

            case (rdata[6:0])
                7'b1111111: begin // ebreak - halts execution
                    cu_state <= 0;
                    done <= 1;
                end
                7'b0110111: begin // lui
                    error <= 0; // reset error
                    rd <= rdata[11:7];
                    d_in <= rdata[31:12] << 12;
                    we <= 1;
                    // note: 1 cycle is enough for lui
                    cu_state <= 0;
                end
                7'b0010011: begin // I-Type
                    error <= 0; // reset error
                    we <= 0; // disable register write

                    if ((rdata[14:12] == 3'b001 || rdata[14:12] == 3'b101) && rdata[31:25] == 7'h20) 
                        // I'm using an extra bit in alu_control to account for funct7 0x00 vs 0x20
                        // In I-Type, for funct3 1 & 5, imm[5:11] acts as funct7
                        alu_control <= {1'b1, rdata[14:12]}; // funct3
                    else 
                        alu_control <= {1'b0, rdata[14:12]}; // funct3
                    
                    // Load Reg File select inputs
                    rd <= rdata[11:7];
                    rs <= rdata[19:15];
                    
                    // Move CU to the next state
                    cu_state <= 2;
                end
                7'b0110011: begin // R-Type
                    error <= 0; // reset error
                    we <= 0; // disable register write

                    if ((rdata[14:12] == 3'b001 || rdata[14:12] == 3'b101) && rdata[31:25] == 7'h20) 
                        alu_control <= {1'b1, rdata[14:12]}; // funct3
                    else 
                        alu_control <= {1'b0, rdata[14:12]}; // funct3
                    
                    // Load Reg File select inputs
                    rd <= rdata[11:7];
                    rs <= rdata[19:15];
                    rt <= rdata[24:20];
                    
                    // Move CU to the next state
                    cu_state <= 2;
                end

                default: error <= 1;
            endcase
        end
    end else if (cu_state == 2) begin // CYCLE 2 - load ALU (EXECUTE)
        case (current_inst[6:0])
            7'b0010011: begin // I-type
                alu_op1 <= $isunknown(rsv) ? 0: rsv;

                if (current_inst[14:12] == 3'b001 || current_inst[14:12] == 3'b101) // funct3 1 & 5 only takes imm[4:0]
                    alu_op2 <= current_inst[4:0];
                else
                    alu_op2 <= current_inst[31:20];
            end
            7'b0110011: begin 
                alu_op1 <= $isunknown(rsv) ? 0: rsv;
                alu_op2 <= $isunknown(rtv) ? 0: rtv; 
            end
        endcase 
        
        // Move CU to the next state
        cu_state <= 3;

    end else if (cu_state == 3) begin // CYCLE 3 - write back
        if (alu_err) begin
            we <= 0;
            error <= 1;
        end else begin 
            if (rd == 0) // don't write to 0 reg
                we <= 0;
            else begin
                we <= 1; 
                d_in <= alu_res;
            end
        end
        
        // set CU back to ready again
        cu_state <= 0; 
    end
end
endmodule