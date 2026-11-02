module grille_pid #(
    parameter signed [15:0] DUTY_MAX = 16'sd4500
)(
    input  wire        clk_50m,
    input  wire        rst_n,

    input  wire        sample_en,
    input  wire signed [15:0] pos_err,
    input  wire signed [15:0] pos_vel,

    input  wire signed [15:0] kp,
    input  wire signed [15:0] kd,

    output reg  signed [15:0] duty
);

reg signed [31:0] p_term, d_term, sum;

always @(posedge clk_50m or negedge rst_n) begin
    if (!rst_n) begin
        duty <= 16'sd0;
        sum  <= 32'sd0;
    end
    else if (sample_en) begin
        p_term = $signed(pos_err) * kp;
        d_term = $signed(pos_vel) * kd;
        sum    = (p_term + d_term) >>> 8;

        if (sum > DUTY_MAX)
            duty <= DUTY_MAX;
        else if (sum < -DUTY_MAX)
            duty <= -DUTY_MAX;
        else
            duty <= sum[15:0];
    end
    else begin
        duty <= duty;
        sum  <= sum;
    end
end

endmodule
