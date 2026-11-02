module uart_tx #(
    parameter BAUD_DIV = 16'd434
)(
    input  wire        clk_50m,
    input  wire        rst_n,

    input  wire [7:0]  data_in,
    input  wire        send,
    output reg         busy,
    output reg         tx
);

reg [3:0]  bit_cnt;
reg [15:0] div_cnt;
reg [7:0]  shift_reg;

localparam IDLE = 1'b0;
localparam TXING = 1'b1;
reg state;

always @(posedge clk_50m or negedge rst_n) begin
    if (!rst_n) begin
        state     <= IDLE;
        bit_cnt   <= 4'd0;
        div_cnt   <= 16'd0;
        shift_reg <= 8'd0;
        tx        <= 1'b1;
        busy      <= 1'b0;
    end
    else begin
        case (state)
            IDLE: begin
                busy <= 1'b0;
                tx   <= 1'b1;
                if (send) begin
                    shift_reg <= data_in;
                    state     <= TXING;
                    bit_cnt   <= 4'd0;
                    div_cnt   <= 16'd0;
                    busy      <= 1'b1;
                end
            end

            TXING: begin
                if (div_cnt < BAUD_DIV - 1'b1)
                    div_cnt <= div_cnt + 1'b1;
                else begin
                    div_cnt <= 16'd0;
                    case (bit_cnt)
                        4'd0 : tx <= 1'b0;
                        4'd1 : tx <= shift_reg[0];
                        4'd2 : tx <= shift_reg[1];
                        4'd3 : tx <= shift_reg[2];
                        4'd4 : tx <= shift_reg[3];
                        4'd5 : tx <= shift_reg[4];
                        4'd6 : tx <= shift_reg[5];
                        4'd7 : tx <= shift_reg[6];
                        4'd8 : tx <= shift_reg[7];
                        4'd9 : tx <= 1'b1;
                        4'd10: begin
                            tx    <= 1'b1;
                            state <= IDLE;
                        end
                        default: tx <= 1'b1;
                    endcase
                    bit_cnt <= bit_cnt + 1'b1;
                end
            end

            default: state <= IDLE;
        endcase
    end
end

endmodule
