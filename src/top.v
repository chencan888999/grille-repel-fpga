module top (
    input  wire        clk_50m,
    input  wire        rst_n,

    input  wire [3:0]  key_sw,

    output wire        uart_tx,
    input  wire        uart_rx,

    output wire        adc_clk,
    output wire        adc_oe_n,
    input  wire [9:0]  adc_data_in,

    input  wire        enc1_a, enc1_b,

    output wire        AN1, AN2, PWMA,

    output wire [3:0]  pwm_out
);

wire [3:0] key_flag;
genvar gi;
generate for (gi = 0; gi < 4; gi = gi + 1) begin : key_gen
    key_filter #(.CNT_MAX(20'd1000_000)) u_key (
        .sys_clk(clk_50m), .sys_rst_n(rst_n),
        .key_in(key_sw[gi]), .key_flag(key_flag[gi])
    );
end
endgenerate

reg  [ 1:0] density;
reg  [15:0] speed;
reg         enable;

always @(posedge clk_50m or negedge rst_n) begin
    if (!rst_n) begin
        density <= 2'd0;
        speed   <= 16'd0;
        enable  <= 1'b0;
    end
    else if (key_flag[3]) begin
        density <= 2'd0;
        speed   <= 16'd0;
        enable  <= 1'b0;
    end
    else begin
        if (key_flag[0])
            density <= (density == 2'd3) ? 2'd0 : density + 1'b1;
        if (key_flag[1])
            speed <= (speed >= 16'd1200) ? 16'd0 : speed + 16'd400;
        if (key_flag[2])
            enable <= ~enable;
    end
end

wire [11:0] theta_raw;
adc u_adc (
    .clk_50m(clk_50m), .rst_n(rst_n),
    .adc_clk(adc_clk), .adc_oe_n(adc_oe_n),
    .adc_data_in(adc_data_in), .theta_out(theta_raw)
);

wire [15:0] pos;
encoder u_enc (
    .clk_50m(clk_50m), .rst_n(rst_n),
    .enc_a(enc1_a), .enc_b(enc1_b), .pos(pos)
);

reg [15:0] sample_cnt;
reg        sample_en;
always @(posedge clk_50m or negedge rst_n) begin
    if (!rst_n) begin sample_cnt <= 0; sample_en <= 0; end
    else if (sample_cnt == 16'd49_999) begin sample_cnt <= 0; sample_en <= 1; end
    else begin sample_cnt <= sample_cnt + 1; sample_en <= 0; end
end

reg [15:0] pos_prev;
reg signed [15:0] pos_vel;
always @(posedge clk_50m or negedge rst_n) begin
    if (!rst_n) begin pos_prev <= 0; pos_vel <= 0; end
    else if (sample_en) begin
        pos_vel  <= $signed(pos) - $signed(pos_prev);
        pos_prev <= pos;
    end
end

wire [ 1:0] speed_level;
wire [15:0] freq_comp;
wire [15:0] duty_comp;
comp_lut u_comp (
    .clk_50m(clk_50m), .rst_n(rst_n),
    .speed(speed),
    .speed_level(speed_level),
    .freq_comp(freq_comp),
    .duty_comp(duty_comp)
);

wire [ 1:0] fsm_state;
wire [15:0] ultra_period;
wire [15:0] ultra_duty;
wire [15:0] led_duty;
wire [15:0] grille_target;
repel_fsm u_repel (
    .clk_50m(clk_50m), .rst_n(rst_n),
    .density(density), .speed_level(speed_level),
    .freq_comp(freq_comp), .duty_comp(duty_comp),
    .enable(enable),
    .state(fsm_state),
    .ultra_period(ultra_period), .ultra_duty(ultra_duty),
    .led_duty(led_duty), .grille_target(grille_target)
);

wire signed [15:0] kp, kd;
wire signed [15:0] pos_err = $signed({1'b0, grille_target}) - $signed({1'b0, pos});
wire signed [15:0] motor_duty;
grille_pid u_pid (
    .clk_50m(clk_50m), .rst_n(rst_n),
    .sample_en(sample_en),
    .pos_err(pos_err), .pos_vel(pos_vel),
    .kp(kp), .kd(kd),
    .duty(motor_duty)
);

motor_ctrl u_motor (
    .clk_50m(clk_50m), .rst_n(rst_n),
    .duty(motor_duty),
    .ain1(AN1), .ain2(AN2), .pwm(PWMA)
);

localparam LED_PERIOD = 16'd50000;

pwm_gen u_ultra0 (
    .clk_50m(clk_50m), .rst_n(rst_n),
    .period(ultra_period), .duty(ultra_duty), .en(enable),
    .pwm(pwm_out[0])
);
pwm_gen u_ultra1 (
    .clk_50m(clk_50m), .rst_n(rst_n),
    .period(ultra_period), .duty(ultra_duty), .en(enable),
    .pwm(pwm_out[1])
);
pwm_gen u_led0 (
    .clk_50m(clk_50m), .rst_n(rst_n),
    .period(LED_PERIOD), .duty(led_duty), .en(enable),
    .pwm(pwm_out[2])
);
pwm_gen u_led1 (
    .clk_50m(clk_50m), .rst_n(rst_n),
    .period(LED_PERIOD), .duty(led_duty), .en(enable),
    .pwm(pwm_out[3])
);

uart_monitor u_monitor (
    .clk_50m(clk_50m), .rst_n(rst_n),
    .density(density), .speed_level(speed_level), .state(fsm_state),
    .pos(pos), .ultra_duty(ultra_duty), .led_duty(led_duty),
    .kp(kp), .kd(kd),
    .rx(uart_rx), .tx(uart_tx)
);

endmodule
