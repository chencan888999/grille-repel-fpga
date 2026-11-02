module comp_lut (
    input  wire        clk_50m,
    input  wire        rst_n,

    input  wire [15:0] speed,

    output reg  [ 1:0] speed_level,
    output reg  [15:0] freq_comp,
    output reg  [15:0] duty_comp
);

localparam TH1 = 16'd400;
localparam TH2 = 16'd800;
localparam TH3 = 16'd1200;

always @(posedge clk_50m or negedge rst_n) begin
    if (!rst_n) begin
        speed_level <= 2'd0;
        freq_comp   <= 16'd0;
        duty_comp   <= 16'd0;
    end
    else begin
        if (speed < TH1) begin
            speed_level <= 2'd0;
            freq_comp   <= 16'd0;
            duty_comp   <= 16'd0;
        end
        else if (speed < TH2) begin
            speed_level <= 2'd1;
            freq_comp   <= 16'd20;
            duty_comp   <= 16'd10;
        end
        else if (speed < TH3) begin
            speed_level <= 2'd2;
            freq_comp   <= 16'd50;
            duty_comp   <= 16'd25;
        end
        else begin
            speed_level <= 2'd3;
            freq_comp   <= 16'd90;
            duty_comp   <= 16'd45;
        end
    end
end

endmodule
