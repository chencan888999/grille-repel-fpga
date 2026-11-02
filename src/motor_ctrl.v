module motor_ctrl #(
    parameter PWM_PERIOD = 13'd5000
)(
    input  wire        clk_50m,
    input  wire        rst_n,

    input  wire signed [15:0] duty,

    output reg         ain1,
    output reg         ain2,
    output wire        pwm
);

reg [12:0] pwm_cnt;
always @(posedge clk_50m or negedge rst_n) begin
    if (!rst_n)
        pwm_cnt <= 13'd0;
    else if (pwm_cnt >= PWM_PERIOD - 1'b1)
        pwm_cnt <= 13'd0;
    else
        pwm_cnt <= pwm_cnt + 1'b1;
end

always @(posedge clk_50m or negedge rst_n) begin
    if (!rst_n) begin
        ain1 <= 1'b0;
        ain2 <= 1'b0;
    end
    else if (duty > 0) begin
        ain1 <= 1'b1;
        ain2 <= 1'b0;
    end
    else if (duty < 0) begin
        ain1 <= 1'b0;
        ain2 <= 1'b1;
    end
    else begin
        ain1 <= 1'b0;
        ain2 <= 1'b0;
    end
end

wire [12:0] duty_abs = (duty[15]) ? (~duty[12:0] + 13'd1) : duty[12:0];
assign pwm = (pwm_cnt < duty_abs) ? 1'b1 : 1'b0;

endmodule
