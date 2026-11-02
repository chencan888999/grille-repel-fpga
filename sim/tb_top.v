`timescale 1ns / 1ps
module tb_top;

reg clk_50m;
reg rst_n;
initial begin clk_50m = 1'b0; forever #10 clk_50m = ~clk_50m; end
initial begin rst_n = 1'b0; #200 rst_n = 1'b1; end

reg  [15:0] period, duty;
reg  en;
wire pwm;
pwm_gen u_pwm (
    .clk_50m(clk_50m), .rst_n(rst_n),
    .period(period), .duty(duty), .en(en), .pwm(pwm)
);
initial begin
    period = 16'd1250; duty = 16'd625; en = 1'b0;
    #1000;
    en = 1'b1;
    #500000;
    period = 16'd50000; duty = 16'd25000;
    #500000;
    en = 1'b0;
end

reg  [15:0] speed;
wire [ 1:0] speed_level;
wire [15:0] freq_comp, duty_comp;
comp_lut u_comp (
    .clk_50m(clk_50m), .rst_n(rst_n),
    .speed(speed), .speed_level(speed_level),
    .freq_comp(freq_comp), .duty_comp(duty_comp)
);
initial begin
    speed = 16'd0;   #100000;
    speed = 16'd400; #100000;
    speed = 16'd800; #100000;
    speed = 16'd1200;#100000;
end

reg  [1:0] density;
reg  [1:0] slvl;
reg  en2;
wire [1:0] fsm_state;
wire [15:0] up, ud, ld, gt;
repel_fsm u_fsm (
    .clk_50m(clk_50m), .rst_n(rst_n),
    .density(density), .speed_level(slvl),
    .freq_comp(16'd0), .duty_comp(16'd0),
    .enable(en2),
    .state(fsm_state),
    .ultra_period(up), .ultra_duty(ud), .led_duty(ld), .grille_target(gt)
);
initial begin
    density = 2'd0; slvl = 2'd0; en2 = 1'b0;
    #100000;
    en2 = 1'b1; density = 2'd1;  #100000;
    density = 2'd2;              #100000;
    density = 2'd3;              #100000;
    en2 = 1'b0;                  #100000;
end

reg sample_en;
reg [15:0] scnt;
always @(posedge clk_50m or negedge rst_n) begin
    if (!rst_n) begin scnt <= 0; sample_en <= 0; end
    else if (scnt == 16'd49_999) begin scnt <= 0; sample_en <= 1; end
    else begin scnt <= scnt + 1; sample_en <= 0; end
end
reg signed [15:0] pe, pv;
wire signed [15:0] md;
grille_pid u_pid (
    .clk_50m(clk_50m), .rst_n(rst_n),
    .sample_en(sample_en), .pos_err(pe), .pos_vel(pv),
    .kp(16'sd3328), .kd(16'sd512), .duty(md)
);
initial begin
    pe = 16'sd0; pv = 16'sd0;
    #5000;
    pe = 16'sd200;
    #200000;
    pe = -16'sd200;
    #200000;
end

initial begin
    $dumpfile("tb_top.vcd");
    $dumpvars(0, tb_top);
    #2000000;
    $finish;
end

endmodule
