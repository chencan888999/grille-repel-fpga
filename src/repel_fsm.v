module repel_fsm (
    input  wire        clk_50m,
    input  wire        rst_n,

    input  wire [ 1:0] density,
    input  wire [ 1:0] speed_level,
    input  wire [15:0] freq_comp,
    input  wire [15:0] duty_comp,
    input  wire        enable,

    output reg  [ 1:0] state,
    output reg  [15:0] ultra_period,
    output reg  [15:0] ultra_duty,
    output reg  [15:0] led_duty,
    output reg  [15:0] grille_target
);

localparam PERIOD_40K = 16'd1250;
localparam LED_PERIOD = 16'd50000;

localparam GR_HOME = 16'd10000;
localparam GR_30   = 16'd11000;
localparam GR_45   = 16'd11500;

always @(posedge clk_50m or negedge rst_n) begin
    if (!rst_n) begin
        state         <= 2'd0;
        ultra_period  <= PERIOD_40K;
        ultra_duty    <= 16'd0;
        led_duty      <= 16'd0;
        grille_target <= GR_HOME;
    end
    else begin
        if (!enable || density == 2'd0) begin

            state         <= 2'd0;
            ultra_duty    <= 16'd0;
            led_duty      <= 16'd0;
            grille_target <= GR_HOME;
        end
        else begin
            state <= density;
            case (density)
                2'd1: begin
                    ultra_period  <= PERIOD_40K + freq_comp;
                    ultra_duty    <= 16'd380 + duty_comp;
                    led_duty      <= LED_PERIOD / 3;
                    grille_target <= GR_HOME;
                end
                2'd2: begin
                    ultra_period  <= PERIOD_40K + freq_comp;
                    ultra_duty    <= 16'd625 + duty_comp;
                    led_duty      <= LED_PERIOD * 2 / 3;
                    grille_target <= GR_30;
                end
                2'd3: begin
                    ultra_period  <= PERIOD_40K + freq_comp;
                    ultra_duty    <= 16'd875 + duty_comp;
                    led_duty      <= LED_PERIOD;
                    grille_target <= GR_45;
                end
                default: begin
                    ultra_period  <= PERIOD_40K;
                    ultra_duty    <= 16'd0;
                    led_duty      <= 16'd0;
                    grille_target <= GR_HOME;
                end
            endcase
        end
    end
end

endmodule
