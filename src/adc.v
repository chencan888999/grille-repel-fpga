module adc (
    input  wire        clk_50m,
    input  wire        rst_n,

    output wire        adc_clk,
    output wire        adc_oe_n,
    input  wire [9:0]  adc_data_in,

    output reg  [11:0] theta_out
);

reg clk_div;
always @(posedge clk_50m or negedge rst_n) begin
    if (!rst_n)
        clk_div <= 1'b0;
    else
        clk_div <= ~clk_div;
end
assign adc_clk    = clk_div;
assign adc_oe_n   = 1'b0;

wire [11:0] theta_12bit = {adc_data_in, 2'b00};

reg [15:0] theta_sum;
reg [17:0] cnt_3ms;
reg [13:0] cnt_187us;
reg [ 3:0] cnt_add;

always @(posedge clk_50m or negedge rst_n) begin
    if (!rst_n) begin
        cnt_3ms  <= 0;
        cnt_187us<= 0;
        theta_sum<= 0;
        cnt_add  <= 0;
        theta_out<= 0;
    end
    else begin

        if (cnt_187us == 14'd9374)
            cnt_187us <= 0;
        else
            cnt_187us <= cnt_187us + 1'b1;

        if (cnt_3ms == 18'd149999)
            cnt_3ms <= 0;
        else
            cnt_3ms <= cnt_3ms + 1'b1;

        if (cnt_187us == 14'd9373) begin
            theta_sum <= theta_sum + {4'b0, theta_12bit};
            cnt_add   <= cnt_add + 1'b1;
        end
        else if (cnt_3ms == 18'd149999) begin
            theta_out <= theta_sum[15:4];
            theta_sum <= 0;
            cnt_add   <= 0;
        end
        else begin
            theta_sum <= theta_sum;
            theta_out <= theta_out;
            cnt_add   <= cnt_add;
        end
    end
end

endmodule
