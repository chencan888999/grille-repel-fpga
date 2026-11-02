module pwm_gen (
    input  wire        clk_50m,
    input  wire        rst_n,

    input  wire [15:0] period,
    input  wire [15:0] duty,
    input  wire        en,

    output reg         pwm
);

reg [15:0] cnt;

always @(posedge clk_50m or negedge rst_n) begin
    if (!rst_n) begin
        cnt <= 16'd0;
        pwm <= 1'b0;
    end
    else begin
        if (cnt >= period - 1'b1)
            cnt <= 16'd0;
        else
            cnt <= cnt + 1'b1;
        pwm <= (en && (cnt < duty)) ? 1'b1 : 1'b0;
    end
end

endmodule
