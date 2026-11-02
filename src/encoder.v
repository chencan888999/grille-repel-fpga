module encoder (
    input  wire        clk_50m,
    input  wire        rst_n,

    input  wire        enc_a,
    input  wire        enc_b,

    output reg  [15:0] pos
);

reg [1:0] enc_sync_a, enc_sync_b;
reg [1:0] state_now, state_last;

always @(posedge clk_50m or negedge rst_n) begin
    if (!rst_n) begin
        enc_sync_a <= 2'd0;
        enc_sync_b <= 2'd0;
        state_now  <= 2'd0;
    end
    else begin
        enc_sync_a <= {enc_sync_a[0], enc_a};
        enc_sync_b <= {enc_sync_b[0], enc_b};
        state_now  <= {enc_sync_a[1], enc_sync_b[1]};
    end
end

always @(posedge clk_50m or negedge rst_n) begin
    if (!rst_n) begin
        pos        <= 16'd10000;
        state_last <= 2'b00;
    end
    else begin
        state_last <= state_now;
        case ({state_last, state_now})

            4'b00_01 : pos <= pos - 1'b1;
            4'b01_11 : pos <= pos - 1'b1;
            4'b11_10 : pos <= pos - 1'b1;
            4'b10_00 : pos <= pos - 1'b1;

            4'b00_10 : pos <= pos + 1'b1;
            4'b10_11 : pos <= pos + 1'b1;
            4'b11_01 : pos <= pos + 1'b1;
            4'b01_00 : pos <= pos + 1'b1;

            default  : pos <= pos;
        endcase
    end
end

endmodule
