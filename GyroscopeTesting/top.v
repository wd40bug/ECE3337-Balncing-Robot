`include "inc/constants.vh"

module top (
    input clk,
    input rx_pin,
    input gyro_rx_pin,
    //input rst_neg,
    input btn,
    input rst_neg,
    output [5:0] led,
    output lcd_rs,
    output lcd_rw,
    output lcd_e,
    output [7:0] lcd_db,
    output tx_pin,
    output gyro_tx_pin
);
  wire pwm_out;
  pwm #(
      .DUTY  (1),
      .PERIOD(100)
  ) pwm_inst (
      .clk(clk),
      .out(pwm_out)
  );



    
  //assign led = btn ? 6'b111111 : pwm_out ? 6'd0 : 6'b111111;

  reg [3:0] x_0 = 4'd1;
  reg [3:0] x_1 = 4'd8;
  reg [3:0] x_2 = 4'd0;

  reg [3:0] y_0 = 4'd0;
  reg [3:0] y_1 = 4'd9;
  reg [3:0] y_2 = 4'd0;

  reg [3:0] z_0 = 8'd2;
  reg [3:0] z_1 = 8'd7;
  reg [3:0] z_2 = 8'd1;
    
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

    reg led_reg_0 = 1'd1;
    reg led_reg_1 = 1'd1;
    reg led_reg_5 = 1'd1;
    wire led_wire_5;

    // register to do temp math in
    reg [7:0] temp_math;

    assign rx_ready = 1'd1; // for now always ready

    assign led[0] = led_reg_0;
    assign led[1] = led_reg_1;
    assign led[2] = rst_neg;
    //assign led[2] = led_reg_2;
    //assign led[3] = led_reg_3;
    //assign led[4] = ~rx_data_valid;
    //assign led[5] = rx_pin;
    assign led[5] = led_wire_5;
    
    // Gyroscope tx
    wire gyro_tx_ready_wire;
    wire [7:0] gyro_tx_byte_wire;
    wire gyro_tx_currently_transmitting;
    wire gyro_tx_done;

    // Gyroscope rx
    wire gyro_rx_data_valid;
    wire [7:0] gyro_uart_data;

    wire [31:0] gyro_output_data;

    // do when data is valid (receiving complete)
    // for now only does 8 bits
    always@(posedge clk) begin
        rx_data_valid_d <= rx_data_valid;

        if(rx_data_valid && !rx_data_valid_d) begin
            temp_math = uart_data - 8'h30;
            gyro_data[7:0] <= uart_data - 8'h30;      // can convert char to bcd by subtracting '0' character
            x_0 <= temp_math[3:0];
            
            // echo back
            tx_byte <= uart_data;
            tx_ready <= 1'd1;
        end
        /*if(trigger_tx_d && !tx_currently_transmitting) begin
            tx_byte <= uart_data;
            tx_ready <= 1'd1;
            trigger_tx_d <= 1'd0;
        end*/
        if(tx_currently_transmitting) begin
            tx_ready <= 1'd0;
        end
        if(tx_done) begin
            tx_finished <= 1'd1;
            tx_ready <= 1'd0;
            led_reg_0 <= 1'd1;
        end
        if(tx_ready)
            led_reg_1 <= 1'd0;
        else if(tx_done)
            led_reg_1 <= 1'd1;
        //rst_neg_d <= rst_neg;
        //if(~rst_neg && rst_neg_d) begin
            //led_reg_3 = 1'd0;  
        //end
        y_0 <= gyro_output_data[23:20];
        y_1 <= gyro_output_data[19:16];
        y_2 <= gyro_output_data[15:12];
        z_0 <= gyro_output_data[11:8];
        z_1 <= gyro_output_data[7:4];
        z_2 <= gyro_output_data[3:0];
        //if(uart_state != 3'd1)
            //temp_led_reg <= 1'd0;
    end

  lcd lcd_inst (
      .clk(clk),
      .x_0(x_0),
      .x_1(x_1),
      .x_2(x_2),
      .y_0(y_0),
      .y_1(y_1),
      .y_2(y_2),
      .z_0(z_0),
      .z_1(z_1),
      .z_2(z_2),
      .rs (lcd_rs),
      .rw (lcd_rw),
      .e  (lcd_e),
      .db (lcd_db)
  );

    uart_rx uart_rx_inst(
        .i_Clock(clk),
        .i_RX_Serial(rx_pin),
        .o_RX_DV(rx_data_valid),
        .o_RX_Byte(uart_data)
    );

    uart_tx uart_tx_inst(
        .i_Rst_L(~rst_neg),
        .i_Clock(clk),
        .i_TX_DV(tx_ready),
        .i_TX_Byte(tx_byte),
        .o_TX_Active(tx_currently_transmitting),
        .o_TX_Serial(tx_pin),
        .o_TX_Done(tx_done)
    );

    uart_tx uart_tx_gyro(
        .i_Rst_L(~rst_neg),
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
        .gyro_response(gyro_output_data)
    );

  /*always @(posedge clk) begin
    if (btn) begin
        y_0 <= 4'd3;
        y_1 = 4'd6;
        y_2 = 4'd0;
    end
  end*/
endmodule
