
module mux_3to1 (
    input signed [7:0] a,  // 8-bit input a
    input signed [7:0] b,  // 8-bit input b
    input signed [8:0] c,  // 9-bit input c
    input [1:0] sel, // 2-bit select signal
    output reg signed [8:0] out // output is 9-bit to accommodate the largest input (c)
);

always @(*) begin
    case(sel)
        // 2'b00: out = 9'b0;   // if sel is 00, output 0
        2'b01: out = {b[7], b};  // if sel is 01, output a (8 bits), pad 1 bit to make 9-bit
        2'b10: out = {a[7], a};  // if sel is 10, output b (8 bits), pad 1 bit to make 9-bit
        2'b11: out = c;    // if sel is 11, output c (9 bits)
        default: out = 9'b0; // default case, output 0
    endcase
end

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


module input_register (
    input clk,
    input reset,
    input pulse,  // 脉动信号
    input signed [3:0] in_a1,  // 第一个4-bit 输入
    input signed [3:0] in_a2,  // 第二个4-bit 输入
    input signed [7:0] in_b1,  // 第一个8-bit 输入
    input signed [7:0] in_b2,  // 第二个8-bit 输入
    input signed [8:0] in_mix, // in_b1 + in_b2 - 9 bit
    output signed [3:0] out_a1, // 转发输出
    output signed [3:0] out_a2, // 转发输出
    output signed [7:0] out_b1, // 转发输出
    output signed [7:0] out_b2,  // 转发输出
    output signed [8:0] out_mix 
);

reg signed [3:0] reg_a1;  // 第一个4-bit 寄存器
reg signed [3:0] reg_a2;  // 第二个4-bit 寄存器
reg signed [7:0] reg_b1;  // 第一个8-bit 寄存器
reg signed [7:0] reg_b2;  // 第二个8-bit 寄存器
reg signed [8:0] reg_mix;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        reg_a1 <= 4'b0;
        reg_a2 <= 4'b0;
        reg_b1 <= 8'b0;
        reg_b2 <= 8'b0;
        reg_mix <= 9'b0;
    end else if (pulse) begin
        // 更新寄存器
        reg_a1 <= in_a1;
        reg_a2 <= in_a2;
        reg_b1 <= in_b1;
        reg_b2 <= in_b2;
        reg_mix <= in_mix;
    end
end

// 转发输出无需寄存器
assign out_a1 = reg_a1;
assign out_a2 = reg_a2;
assign out_b1 = reg_b1;
assign out_b2 = reg_b2;
assign out_mix = reg_mix;

endmodule



module sp_double_mac_unit (
    input clk,
    input reset,
    input pulse,  // 脉动信号
    input signed [3:0] in_a1,  // 第一个4-bit 输入
    input signed [3:0] in_a2,  // 第二个4-bit 输入
    input signed [7:0] in_b1,  // 第一个8-bit 输入
    input signed [7:0] in_b2,  // 第二个8-bit 输入
    input signed [8:0] in_mix,
    output signed [25:0] result,  // 26-bit 输出
    output signed [3:0] out_a1, // 转发输出
    output signed [3:0] out_a2, // 转发输出
    output signed [7:0] out_b1, // 转发输出
    output signed [7:0] out_b2, // 转发输出
    output signed [8:0] out_mix
);



// 实例化输入寄存器
input_register u_input_register (
    .clk(clk),
    .reset(reset),
    .pulse(pulse),
    .in_a1(in_a1),
    .in_a2(in_a2),
    .in_b1(in_b1),
    .in_b2(in_b2),
    .in_mix(in_mix),
    .out_a1(out_a1),
    .out_a2(out_a2),
    .out_b1(out_b1),
    .out_b2(out_b2),
    .out_mix(out_mix)
);





wire signed[12:0] product_sum;
wire signed[8:0] part_in_1;
wire signed[8:0] part_in_2;
wire signed[8:0] part_in_3;
wire signed[8:0] part_in_4;

wire signed [10:0] part_sum_1;
wire signed [12:0] part_sum_2;

mux_3to1 u_mux_in_1 (
    .a(in_b1),
    .b(in_b2),
    .c(in_mix),
    .sel({in_a1[0],in_a2[0]}),
    .out(part_in_1)
);

mux_3to1 u_mux_in_2 (
    .a(in_b1),
    .b(in_b2),
    .c(in_mix),
    .sel({in_a1[1],in_a2[1]}),
    .out(part_in_2)
);

mux_3to1 u_mux_in_3 (
    .a(in_b1),
    .b(in_b2),
    .c(in_mix),
    .sel({in_a1[2],in_a2[2]}),
    .out(part_in_3)
);

mux_3to1 u_mux_in_4 (
    .a(in_b1),
    .b(in_b2),
    .c(in_mix),
    .sel({in_a1[3],in_a2[3]}),
    .out(part_in_4)
);

assign part_sum_1 = $signed(part_in_1) + $signed({part_in_2,1'b0});
assign part_sum_2 = $signed({part_in_3,2'b00}) + $signed({part_in_4,3'b000});

assign product_sum = part_sum_1 + part_sum_2;


wire signed[25:0] acc_out;

// 实例化累加器
accumulator u_accumulator (
    .clk(clk),
    .reset(reset),
    .pulse(pulse),
    .product_in(product_sum),  // 两次乘法结果相加
    .acc_out(acc_out)
);

assign result = acc_out;

endmodule
