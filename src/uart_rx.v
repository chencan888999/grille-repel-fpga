module uart_rx #(
    parameter BAUD_DIV = 16'd434
)(
    input  wire        clk_50m,
    input  wire        rst_n,

    input  wire        rx,
    output reg  [7:0]  data_out,
    output reg         data_valid
);

reg [1:0]  rx_sync;
reg        rx_d1, rx_d2;
reg [15:0] div_cnt;
reg [3:0]  bit_cnt;
reg [7:0]  shift_reg;
reg        state;

localparam IDLE  = 1'b0;
localparam RXING = 1'b1;

always @(posedge clk_50m or negedge rst_n) begin
    if (!rst_n) begin
        rx_sync <= 2'b11;
        rx_d1   <= 1'b1;
        rx_d2   <= 1'b1;
    end
    else begin
        rx_sync <= {rx_sync[0], rx};
        rx_d1   <= rx_sync[1];
        rx_d2   <= rx_d1;
    end
end
wire start_edge = (rx_d2 == 1'b1) && (rx_d1 == 1'b0);

always @(posedge clk_50m or negedge rst_n) begin
    if (!rst_n) begin
        state      <= IDLE;
        div_cnt    <= 16'd0;
        bit_cnt    <= 4'd0;
        shift_reg  <= 8'd0;
        data_out   <= 8'd0;
        data_valid <= 1'b0;
    end
    else begin
        data_valid <= 1'b0;
        case (state)
            IDLE: begin
                if (start_edge) begin
                    state     <= RXING;
                    div_cnt   <= 16'd0;
                    bit_cnt   <= 4'd0;
                end
            end

            RXING: begin

                if (div_cnt == (BAUD_DIV >> 1) - 1'b1) begin
                    case (bit_cnt)
                        4'd0 : ;
                        4'd1 : shift_reg[0] <= rx_d1;
                        4'd2 : shift_reg[1] <= rx_d1;
                        4'd3 : shift_reg[2] <= rx_d1;
                        4'd4 : shift_reg[3] <= rx_d1;
                        4'd5 : shift_reg[4] <= rx_d1;
                        4'd6 : shift_reg[5] <= rx_d1;
                        4'd7 : shift_reg[6] <= rx_d1;
                        4'd8 : shift_reg[7] <= rx_d1;
                        default: ;
                    endcase
                end

                if (div_cnt < BAUD_DIV - 1'b1)
                    div_cnt <= div_cnt + 1'b1;
                else begin
                    div_cnt <= 16'd0;
                    if (bit_cnt == 4'd9) begin
                        data_out   <= shift_reg;
                        data_valid <= 1'b1;
                        state      <= IDLE;
                    end
                    else
                        bit_cnt <= bit_cnt + 1'b1;
                end
            end

            default: state <= IDLE;
        endcase
    end
end

endmodule
