module top (
    input clk,
    input gyro_rx,
    input esp_rx,
    input page_back,
    page_forward,
    up,
    down,
    left,
    right,
    enc_left_1,
    enc_left_2,
    enc_right_1,
    enc_right_2,
    output [5:0] led,
    output lcd_rs,
    output lcd_rw,
    output lcd_e,
    output gyro_tx,
    output esp_tx,
    output shift_ser,
    output shift_srclk,
    output shift_rclk,
    output wire ena,
    enb,
    in1,
    in2,
    in3,
    in4
);

  assign led = 6'b101010;

  // --- Sensor Readings ---
  // Angles
  wire signed [7:0] pitch;
  reg signed [7:0] yaw = -7'd75;
  // Speeds
  wire signed [15:0] left_speed;
  wire signed [15:0] right_speed;
  // Data in
  wire pitch_data_in;

  // --- System Variables ---
  // Set Speed
  wire signed [15:0] set_speed;
  // Drive state
  reg [2:0] drive_state = 3'd0;
  // --- Other ---
  // Debugging
  wire [63:0] raw_gyro;
  wire signed [7:0] left_duty, right_duty;

    wire [103:0] esp_uart_output;

  Gyro gyro_inst (
      .clk(clk),
      .rx(gyro_rx),
      .tx(gyro_tx),
      .pitch(pitch),
      .data_in(pitch_data_in),
      .raw_gyro(raw_gyro)
  );

  PIDPitchControl pitch_control (
      .clk(clk),
      .data_in(pitch_data_in),
      .pitch(pitch),
      .speed(set_speed)
  );

  Motors motors_inst (
      .clk(clk),
      .left_encoder_1(enc_left_1),
      .left_encoder_2(enc_left_2),
      .right_encoder_1(enc_right_1),
      .right_encoder_2(enc_right_2),
      .left_enable(ena),
      .left_in1(in1),
      .left_in2(in2),
      .right_enable(enb),
      .right_in1(in3),
      .right_in2(in4),
      .set_speed(-set_speed),
      // Debugging
      .left_speed(left_speed),
      .right_speed(right_speed),
      .left_duty(left_duty),
      .right_duty(right_duty)
  );

  LCD #(
      .DEFAULT_PAGE(0)
  ) lcd_inst (
      .clk(clk),
      .forward(page_forward),
      .backward(page_back),
      .pitch(pitch),
      .yaw(yaw),
      .gyro_raw(raw_gyro),
      .left_speed(left_speed),
      .right_speed(right_speed),
      .left_duty(left_duty),
      .right_duty(right_duty),
      .drive_state(drive_state),
      .set_speed(set_speed),
        .raw_esp_uart_data(esp_uart_output),
      .rs(lcd_rs),
      .rw(lcd_rw),
      .e(lcd_e),
      .sr_data(shift_ser),
      .sr_clk(shift_srclk),
      .sr_latch(shift_rclk)
  );

    wire esp_tx_ready;
    wire [7:0] esp_tx_data;
    wire esp_tx_done;
    wire esp_tx_active;
    wire [7:0] esp_rx_data;
    wire esp_rx_data_valid;

  esp_commands esp_inst (
    .clk(clk),
    .rx_data_valid(esp_rx_data_valid),
    .uart_data(esp_rx_data),
    .tx_cur_transmitting(esp_tx_active),
    .tx_done(esp_tx_done),
    .tx_data(esp_tx_data),
    .tx_ready(esp_tx_ready),
    .esp_raw_output(esp_uart_output)
);

    

  uart_tx uart_tx_esp (
      .i_Rst_L(1'b1),
      .i_Clock(clk),
      .i_TX_DV(esp_tx_ready),
      .i_TX_Byte(esp_tx_data),
      .o_TX_Active(esp_tx_active),
      .o_TX_Serial(esp_tx),
      .o_TX_Done(esp_tx_done)
  );

  uart_rx uart_rx_esp (
      .i_Clock(clk),
      .i_RX_Serial(esp_rx),
      .o_RX_DV(esp_rx_data_valid),
      .o_RX_Byte(esp_rx_data)
  );

endmodule
