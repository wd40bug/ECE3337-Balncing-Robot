module LCD #(
    parameter integer DEFAULT_PAGE = 0
) (
    input clk,
    input forward,
    input backward,
    // Driver inputs
    input signed [7:0] pitch,
    input signed [7:0] yaw,
    input [63:0] gyro_raw,
    input signed [15:0] left_speed,
    input signed [15:0] right_speed,
    input signed [7:0] left_duty,
    input signed [7:0] right_duty,
    input [2:0] drive_state,
    input signed [15:0] set_speed,
    input [103:0] esp_uart_in,
    output rs,
    rw,
    e,
    sr_data,
    sr_clk,
    sr_latch
);

  wire [7:0] lcd_char;
  wire [4:0] lcd_rqst;

  raw_lcd raw_lcd_inst (
    .clk(clk),
    .char(lcd_char),
    .lcd_rqst(lcd_rqst),
    .rs(rs),
    .rw(rw),
    .e(e),
    .sr_data(sr_data),
    .sr_clk(sr_clk),
    .sr_latch(sr_latch)
  );

  lcd_driver #(.DEFAULT_PAGE(DEFAULT_PAGE)) lcd_driver_inst (
    .clk(clk),
    .page_forward(forward),
    .page_backward(backward),
    .lcd_rqst(lcd_rqst),
    .pitch(pitch),
    .yaw(yaw),
    .RawGyroReading(gyro_raw),
    .LeftEncoderReading(left_speed),
    .RightEncoderReading(right_speed),
    .pwm_left(left_duty),
    .pwm_right(right_duty),
    .demo_state(drive_state),
    .set_speed(set_speed),
    .esp_uart_in(raw_esp_uart_data),
    .esp_uart_in(esp_uart_in),
  
