module uart_monitor #(
    parameter TX_PERIOD = 32'd500_000
)(
    input  wire        clk_50m,
    input  wire        rst_n,

    input  wire [ 1:0] density,
    input  wire [ 1:0] speed_level,
    input  wire [ 1:0] state,
    input  wire [15:0] pos,
    input  wire [15:0] ultra_duty,
    input  wire [15:0] led_duty,

    output reg  signed [15:0] kp,
    output reg  signed [15:0] kd,

    input  wire        rx,
    output wire        tx
);

localparam signed [15:0] DEF_KP = 16'sd3328;
localparam signed [15:0] DEF_KD = 16'sd512;

wire [7:0]  rx_byte;
wire        rx_valid;
wire        tx_busy;
reg         tx_send;
reg  [7:0]  tx_byte;

uart_tx u_tx (
    .clk_50m (clk_50m), .rst_n (rst_n),
    .data_in (tx_byte), .send (tx_send), .busy (tx_busy), .tx (tx)
);
uart_rx u_rx (
    .clk_50m (clk_50m), .rst_n (rst_n),
    .rx (rx), .data_out (rx_byte), .data_valid (rx_valid)
);

reg [31:0] tx_timer;
reg [ 3:0] tx_index;
reg [ 1:0] tx_state;
reg [7:0]  pkt [0:9];

localparam TX_IDLE = 2'd0;
localparam TX_SEND = 2'd1;
localparam TX_WAIT = 2'd2;

always @(posedge clk_50m or negedge rst_n) begin
    if (!rst_n) begin
        tx_timer <= 32'd0; tx_index <= 4'd0; tx_state <= TX_IDLE;
        tx_send  <= 1'b0;  tx_byte  <= 8'd0;
    end
    else begin
        case (tx_state)
            TX_IDLE: begin
                tx_send <= 1'b0;
                if (tx_timer >= TX_PERIOD - 1'b1) begin
                    tx_timer <= 32'd0; tx_index <= 4'd0; tx_state <= TX_SEND;
                end
                else tx_timer <= tx_timer + 1'b1;
            end
            TX_SEND: begin
                tx_byte <= pkt[tx_index]; tx_send <= 1'b1; tx_state <= TX_WAIT;
            end
            TX_WAIT: begin
                tx_send <= 1'b0;
                if (!tx_busy) begin
                    if (tx_index >= 4'd9) tx_state <= TX_IDLE;
                    else begin tx_index <= tx_index + 1'b1; tx_state <= TX_SEND; end
                end
            end
            default: tx_state <= TX_IDLE;
        endcase
    end
end

always @(*) begin
    pkt[0] = 8'hAA;
    pkt[1] = {6'b0, density};
    pkt[2] = {6'b0, speed_level};
    pkt[3] = {6'b0, state};
    pkt[4] = pos[15:8];
    pkt[5] = pos[7:0];
    pkt[6] = ultra_duty[15:8];
    pkt[7] = ultra_duty[7:0];
    pkt[8] = led_duty[15:8];
    pkt[9] = led_duty[7:0];
end

reg [1:0] rx_state;
reg [7:0] rx_idx;
reg [7:0] rx_valh;

always @(posedge clk_50m or negedge rst_n) begin
    if (!rst_n) begin
        rx_state <= 2'd0; rx_idx <= 8'd0; rx_valh <= 8'd0;
        kp <= DEF_KP; kd <= DEF_KD;
    end
    else if (rx_valid) begin
        case (rx_state)
            2'd0: if (rx_byte == 8'hBB) rx_state <= 2'd1;
            2'd1: begin rx_idx <= rx_byte; rx_state <= 2'd2; end
            2'd2: begin rx_valh <= rx_byte; rx_state <= 2'd3; end
            2'd3: begin
                case (rx_idx)
                    8'd0: kp <= $signed({rx_valh, rx_byte});
                    8'd1: kd <= $signed({rx_valh, rx_byte});
                    default: ;
                endcase
                rx_state <= 2'd0;
            end
            default: rx_state <= 2'd0;
        endcase
    end
end

endmodule
