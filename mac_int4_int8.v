


module input_register (
    input clk,
    input reset,
    input pulse,  // 脉动信号
    input signed [3:0] in_a,  // 4-bit 输入
    input signed [7:0] in_b,  // 8-bit 输入
    output signed [3:0] out_a, // 转发输出
    output signed [7:0] out_b  // 转发输出
);


reg signed [3:0] reg_a;  // 4-bit 寄存器
reg signed [7:0] reg_b;  // 8-bit 寄存器

always @(posedge clk or posedge reset) begin
    if (reset) begin
        reg_a <= 4'b0;
        reg_b <= 8'b0;
    end else if (pulse) begin
        // 更新寄存器
        reg_a <= in_a;
        reg_b <= in_b;
    end
end

// 转发输出无需寄存器
assign out_a = reg_a;
assign out_b = reg_b;

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
    input signed [11:0] product_in,  // 乘法器的输出
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



module mac_unit (
    input clk,
    input reset,
    input pulse,  // 脉动信号
    input signed [3:0] in_a,  // 4-bit 输入
    input signed [7:0] in_b,  // 8-bit 输入
    output signed [25:0] result,  // 26-bit 输出
    output signed [3:0] out_a, // 转发输出
    output signed [7:0] out_b  // 转发输出
);


wire signed [11:0] product;
wire signed [25:0] acc_out;

// 实例化输入寄存器
input_register u_input_register (
    .clk(clk),
    .reset(reset),
    .pulse(pulse),
    .in_a(in_a),
    .in_b(in_b),
    .out_a(out_a),
    .out_b(out_b)
);

// 实例化乘法器
signed_multiplier u_multiplier (
    .a(in_a),
    .b(in_b),
    .product(product)
);

// 实例化累加器
accumulator u_accumulator (
    .clk(clk),
    .reset(reset),
    .pulse(pulse),
    .product_in(product),
    .acc_out(acc_out)
);

assign result = acc_out;

endmodule
