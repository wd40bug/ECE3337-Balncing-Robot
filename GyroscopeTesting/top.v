`include "inc/constants.vh"

module top (
    input clk,
<<<<<<< HEAD
    input rx_pin,
    input rst_neg,
=======
    input btn,
>>>>>>> will-dev
    output [5:0] led,
    output lcd_rs,
    output lcd_rw,
    output lcd_e,
    output [7:0] lcd_db
);
  wire pwm_out;
  pwm #(
      .DUTY  (1),
      .PERIOD(100)
  ) pwm_inst (
      .clk(clk),
      .out(pwm_out)
  );

<<<<<<< HEAD
  //assign led = pwm_out ? 6'd0 : 6'b111111;

  reg [3:0] x_0; //= 8'd1;
  reg [3:0] x_1 = 8'd8;
  reg [3:0] x_2 = 8'd0;
=======
  assign led = btn ? 6'b111111 : pwm_out ? 6'd0 : 6'b111111;

  reg [3:0] x_0 = 4'd1;
  reg [3:0] x_1 = 4'd8;
  reg [3:0] x_2 = 4'd0;
>>>>>>> will-dev

  reg [3:0] y_0 = 4'd0;
  reg [3:0] y_1 = 4'd9;
  reg [3:0] y_2 = 4'd0;

<<<<<<< HEAD
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
=======
  reg [3:0] z_0 = 4'd2;
  reg [3:0] z_1 = 4'd7;
  reg [3:0] z_2 = 4'd0;
>>>>>>> will-dev

    reg rst_neg_d;

    reg temp_led_reg = 1'd1;
    reg led_reg_2 = 1'd1;
    reg led_reg_3 = 1'd1;

    // register to do temp math in
    reg [7:0] temp_math;
    
    /*
    // bcd
    wire [7:0] b_to_bcd;
    wire [3:0] hundreds;
    wire [3:0] tens;
    wire [3:0] ones;
    */

    assign rx_ready = 1'd1; // for now always ready
    
    assign led[0] = temp_led_reg;
    assign led[1] = ~rst_neg;
    assign led[2] = led_reg_2;
    assign led[3] = led_reg_3;
    assign led[4] = ~rx_data_valid;
    assign led[5] = rx_pin;
    

    // do when data is valid (receiving complete)
    // for now only does 8 bits
    always@(posedge clk) begin
        rx_data_valid_d <= rx_data_valid;
        if(rx_data_valid && !rx_data_valid_d) begin
            temp_math = uart_data - 8'h30;
            gyro_data[7:0] <= uart_data - 8'h30;      // can convert char to bcd by subtracting '0' character
            x_0 <= temp_math[3:0];
            led_reg_2 <= 1'd0;
        end
        
        rst_neg_d <= rst_neg;
        if(~rst_neg && rst_neg_d) begin
            led_reg_3 = 1'd0;  
        end

        if(uart_state != 3'd1)
            temp_led_reg <= 1'd0;
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

<<<<<<< HEAD
    uart_rx uart_inst(
        .i_Clock(clk),
        .i_RX_Serial(rx_pin),
        .o_RX_DV(rx_data_valid),
        .o_RX_Byte(uart_data)
    );

=======
  always @(posedge clk) begin
    if (btn) begin
        y_0 <= 4'd3;
        y_1 = 4'd6;
        y_2 = 4'd0;
    end
  end
>>>>>>> will-dev
endmodule
