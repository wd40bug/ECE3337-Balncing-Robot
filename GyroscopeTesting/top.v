module top (
    input clk,
    // input rx_pin,
    input gyro_rx_pin,
    // input rst_neg,
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
    // output tx_pin,
    output gyro_tx_pin,
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

  assign led = {enc_left_1, enc_left_2, enc_right_1, enc_right_2, 0, 0};

  wire pitch_sign;
  wire [6:0] pitch_value;

  reg yaw_sign = 1;
  reg [6:0] yaw_value = 7'd75;

  wire [31:0] gyro_reading_lcd;

  wire encoder_reading_left_dir;
  wire [15:0] encoder_reading_left;
  wire encoder_reading_right_dir;
  wire [15:0] encoder_reading_right;

  wire data_out_left;
  wire data_out_right;

  Encoder encoder_inst_left (
      .clk(clk),
      .rst(1'b0),
      .SignalFeedback1(enc_left_1),
      .SignalFeedback2(enc_left_2),
      .dir(encoder_reading_left_dir),
      .ticks(encoder_reading_left),
      .data_out(data_out_left)
  );

  Encoder encoder_inst_right (
      .clk(clk),
      .rst(1'b0),
      // Reversed for right
      .SignalFeedback1(enc_right_2),
      .SignalFeedback2(enc_right_1),
      .dir(encoder_reading_right_dir),
      .ticks(encoder_reading_right),
      .data_out(data_out_right)
  );

  wire [7:0] lcd_driver_out;
  wire [4:0] lcd_rqst;
  // wire [2:0] demo_state;

    
    // uart
    //wire rx_pin;
    wire rx_ready;
    wire[7:0] uart_data;
    wire rx_data_valid;
    reg rx_data_valid_d;
    reg [15:0] gyro_data;
    reg gyro_data_valid;
    wire [3:0] uart_state;

    // uart tx
    reg tx_ready = 1'd0;
    reg [7:0] tx_byte;
    wire tx_currently_transmitting;
    wire tx_done;
    
    // make high to transmit the data loaded in tx_byte
    reg trigger_tx;
    reg trigger_tx_d;
    reg tx_finished;

    reg rst_neg_d;


    // register to do temp math in
    reg [7:0] temp_math;

    assign rx_ready = 1'd1; // for now always ready
    
    // Gyroscope tx
    wire gyro_tx_ready_wire;
    wire [7:0] gyro_tx_byte_wire;
    wire gyro_tx_currently_transmitting;
    wire gyro_tx_done;

    // Gyroscope rx
    wire gyro_rx_data_valid;
    wire [7:0] gyro_uart_data;

    wire [31:0] gyro_output_data;

    wire [7:0] pitch_angle;
    // hundreds, tens, and ones place
    // wire [3:0] pitch_h, pitch_t, pitch_o;


    // do when data is valid (receiving complete)
    // for now only does 8 bits
    always@(posedge clk) begin
        rx_data_valid_d <= rx_data_valid;

        if(rx_data_valid && !rx_data_valid_d) begin
            temp_math = uart_data - 8'h30;
            gyro_data[7:0] <= uart_data - 8'h30;      // can convert char to bcd by subtracting '0' character
            //x_0 <= temp_math[3:0];
            
            // echo back
            tx_byte <= uart_data;
            tx_ready <= 1'd1;
        end
        if(tx_currently_transmitting) begin
            tx_ready <= 1'd0;
        end
        if(tx_done) begin
            tx_finished <= 1'd1;
            tx_ready <= 1'd0;
        end
        
    end

    assign pitch_value = pitch_angle[6:0];
    assign pitch_sign = pitch_angle[7];
    assign gyro_reading_lcd = gyro_output_data[31:0];

  lcd_driver lcd_driver_inst (
      .clk(clk),
      .page_backward(page_back),
      .page_forward(page_forward),
      .lcd_rqst(lcd_rqst),
      .pitch_sign(pitch_sign),
      .pitch_value(pitch_value),
      .yaw_sign(yaw_sign),
      .yaw_value(yaw_value),
      .RawGyroReading(gyro_reading_lcd),
      .LeftEncoderReading(encoder_reading_left),
      .left_dir(encoder_reading_left_dir),
      .RightEncoderReading(encoder_reading_right),
      .right_dir(encoder_reading_right_dir),
      .pwm_left(left_duty),
      .pwm_left_dir(pwm_left_dir),
      .pwm_right(right_duty),
      .pwm_right_dir(pwm_right_dir),
      .demo_state(2'd0),
      .lcd_char(lcd_driver_out)
  );

  lcd lcd_inst (
      .clk(clk),
      .char(lcd_driver_out),
      .lcd_rqst(lcd_rqst),
      .rs(lcd_rs),
      .rw(lcd_rw),
      .e(lcd_e),
      .sr_data(shift_ser),
      .sr_clk(shift_srclk),
      .sr_latch(shift_rclk)
  );

    //uart_rx uart_rx_inst(
    //    .i_Clock(clk),
    //    .i_RX_Serial(rx_pin),
    //    .o_RX_DV(rx_data_valid),
    //    .o_RX_Byte(uart_data)
    //);

    // uart_tx uart_tx_inst(
    //     .i_Rst_L(~rst_neg),
    //     .i_Clock(clk),
    //     .i_TX_DV(tx_ready),
    //     .i_TX_Byte(tx_byte),
    //     .o_TX_Active(tx_currently_transmitting),
    //     .o_TX_Serial(tx_pin),
    //     .o_TX_Done(tx_done)
    // );

    uart_tx uart_tx_gyro(
        .i_Rst_L(1'b1),
        .i_Clock(clk),
        .i_TX_DV(gyro_tx_ready_wire),
        .i_TX_Byte(gyro_tx_byte_wire),
        .o_TX_Active(gyro_tx_currently_transmitting),
        .o_TX_Serial(gyro_tx_pin),
        .o_TX_Done(gyro_tx_done)
    );

    uart_rx uart_rx_gyro(
        .i_Clock(clk),
        .i_RX_Serial(gyro_rx_pin),
        .o_RX_DV(gyro_rx_data_valid),
        .o_RX_Byte(gyro_uart_data)
    );

    bn_gyro gyro_inst(
        .clk(clk),
        .rx_data_valid(gyro_rx_data_valid),
        .uart_data(gyro_uart_data),
        .tx_cur_transmitting(gyro_tx_currently_transmitting),
        .tx_done(gyro_tx_done),
        .tx_data(gyro_tx_byte_wire),
        .tx_ready(gyro_tx_ready_wire),
        .led_wire(led_wire_5),
        .gyro_response(gyro_output_data),
        .pitch_angle(pitch_angle)
    );

  wire [7:0] left_duty;
  wire [7:0] right_duty;
  reg [2:0] left_state;
  reg [2:0] right_state;
  MotorControl motor_control_inst (
      .clk(clk),
      .rst(1'b0),
      .duty1(left_duty),
      .duty2(right_duty),
      .state1({2'b0, ~pwm_left_dir}),
      .state2({2'b0, ~pwm_right_dir}),
      .left1(in1),
      .left2(in2),
      .right1(in4),
      .right2(in3),
      .leftpwm(ena),
      .rightpwm(enb)
  );

  wire signed [8:0] pwm_left_signed;
  wire pwm_left_dir; 
  wire signed [8:0] pwm_right_signed;
  wire pwm_right_dir;

  PIDMotorControl pid_motor_control_inst(
      .clk(clk),
      .data_in_left(data_out_left),
      .data_in_right(data_out_right),
      .read_speed_left(encoder_reading_left),
      .read_speed_right(encoder_reading_right),
      .speed_left(16'd20),
      .speed_right(16'd20),
      .PWM_left(pwm_left_signed),
      .PWM_right(pwm_right_signed)
  );

  signed_conversion #(.BITS(8)) signed_conversion_left_pwm(
      .in(pwm_left_signed),
      .out(left_duty),
      .sign(pwm_left_dir)
  );

  signed_conversion #(.BITS(8)) signed_conversion_right_pwm(
      .in(pwm_right_signed),
      .out(right_duty),
      .sign(pwm_right_dir)
  );

  //   demo_driver demo_driver_inst (
  //       .clk(clk),
  //       .up(up),
  //       .down(down),
  //       .left(left),
  //       .right(right),
  //       .left_state(left_state),
  //       .left_pwm(left_duty),
  //       .right_state(right_state),
  //       .right_pwm(right_duty),
  //       .demo_state(demo_state)
  //   );
endmodule
