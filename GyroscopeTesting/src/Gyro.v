module Gyro (
    input clk,
    input rx,
    output tx,
    output signed [7:0] pitch,
    output data_in,
    // Debugging
    output [63:0] raw_gyro
);

  wire tx_ready;
  wire [7:0] tx_data;
  wire tx_active;
  wire tx_done;

  uart_tx uart_tx_gyro (
      .i_Rst_L(1'b1),
      .i_Clock(clk),
      .i_TX_DV(tx_ready),
      .i_TX_Byte(tx_data),
      .o_TX_Active(tx_active),
      .o_TX_Serial(tx),
      .o_TX_Done(tx_done)
  );

  wire rx_done;
  wire [7:0] rx_data;

  uart_rx uart_rx_gyro (
      .i_Clock(clk),
      .i_RX_Serial(rx),
      .o_RX_DV(rx_done),
      .o_RX_Byte(rx_data)
  );

  bn_gyro gyro_inst (
      .clk(clk),
      .rx_data_valid(rx_done),
      .uart_data(rx_data),
      .tx_cur_transmitting(tx_active),
      .tx_done(tx_done),
      .tx_data(tx_data),
      .tx_ready(tx_ready),
      .gyro_response(raw_gyro),
      .pitch_angle(pitch),
      .pitch_valid_out(data_in)
  );


endmodule
