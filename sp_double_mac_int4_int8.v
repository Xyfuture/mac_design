




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