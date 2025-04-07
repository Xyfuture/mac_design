module input_register (
    input clk,
    input reset,
    input pulse,  // 脉动信号
    input signed [3:0] in_a1,  // 第一个4-bit 输入
    input signed [3:0] in_a2,  // 第二个4-bit 输入
    input signed [7:0] in_b1,  // 第一个8-bit 输入
    input signed [7:0] in_b2,  // 第二个8-bit 输入
    output reg signed [3:0] reg_a1,  // 第一个4-bit 寄存器
    output reg signed [3:0] reg_a2,  // 第二个4-bit 寄存器
    output reg signed [7:0] reg_b1,  // 第一个8-bit 寄存器
    output reg signed [7:0] reg_b2,  // 第二个8-bit 寄存器
    output signed [3:0] out_a1, // 转发输出
    output signed [3:0] out_a2, // 转发输出
    output signed [7:0] out_b1, // 转发输出
    output signed [7:0] out_b2  // 转发输出
);

always @(posedge clk or posedge reset) begin
    if (reset) begin
        reg_a1 <= 4'b0;
        reg_a2 <= 4'b0;
        reg_b1 <= 8'b0;
        reg_b2 <= 8'b0;
    end else if (pulse) begin
        // 更新寄存器
        reg_a1 <= in_a1;
        reg_a2 <= in_a2;
        reg_b1 <= in_b1;
        reg_b2 <= in_b2;
    end
end

// 转发输出无需寄存器
assign out_a1 = reg_a1;
assign out_a2 = reg_a2;
assign out_b1 = reg_b1;
assign out_b2 = reg_b2;

endmodule

module signed_multiplier (
    input signed [3:0] a,   // 4-bit 输入
    input signed [7:0] b,   // 8-bit 输入
    output signed [11:0] product  // 结果为12-bit
);

assign product = a * b;

endmodule

module accumulator (
    input clk,
    input reset,
    input pulse,  // 脉动信号
    input signed [12:0] product_in,  // 乘法器的输出
    output reg signed [25:0] acc_out  // 26-bit 累加器的输出
);

always @(posedge clk or posedge reset) begin
    if (reset) begin
        acc_out <= 26'b0;
    end else if (pulse) begin
        acc_out <= acc_out + product_in;
    end
end

endmodule

module double_mac_unit (
    input clk,
    input reset,
    input pulse,  // 脉动信号
    input signed [3:0] in_a1,  // 第一个4-bit 输入
    input signed [3:0] in_a2,  // 第二个4-bit 输入
    input signed [7:0] in_b1,  // 第一个8-bit 输入
    input signed [7:0] in_b2,  // 第二个8-bit 输入
    output signed [25:0] result,  // 26-bit 输出
    output signed [3:0] out_a1, // 转发输出
    output signed [3:0] out_a2, // 转发输出
    output signed [7:0] out_b1, // 转发输出
    output signed [7:0] out_b2  // 转发输出
);

wire signed [3:0] reg_a1, reg_a2;
wire signed [7:0] reg_b1, reg_b2;
wire signed [11:0] product1, product2;
wire signed [25:0] acc_out;

// 实例化输入寄存器
input_register u_input_register (
    .clk(clk),
    .reset(reset),
    .pulse(pulse),
    .in_a1(in_a1),
    .in_a2(in_a2),
    .in_b1(in_b1),
    .in_b2(in_b2),
    .reg_a1(reg_a1),
    .reg_a2(reg_a2),
    .reg_b1(reg_b1),
    .reg_b2(reg_b2),
    .out_a1(out_a1),
    .out_a2(out_a2),
    .out_b1(out_b1),
    .out_b2(out_b2)
);

// 实例化两个乘法器
signed_multiplier u_multiplier1 (
    .a(reg_a1),
    .b(reg_b1),
    .product(product1)
);

signed_multiplier u_multiplier2 (
    .a(reg_a2),
    .b(reg_b2),
    .product(product2)
);

// 实例化累加器
accumulator u_accumulator (
    .clk(clk),
    .reset(reset),
    .pulse(pulse),
    .product_in(product1 + product2),  // 两次乘法结果相加
    .acc_out(acc_out)
);

assign result = acc_out;

endmodule
