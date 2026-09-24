module gyro #(
    parameter integer CLK_SPEED = 27_000_000,
    parameter integer I2C_SPEED = 100_000
) (
    input clk,
    output reg scl,
    output reg sda
);

  i2c_master #(.CLK_DIV(CLK_SPEED / (4 * I2C_SPEED))) i2c_master_inst (
    .clk(clk),
    .rst(0),
    .start_tx(),
    .addr(7'h68),
    .data_byte,

    .scl(scl),
    .sda_out(),

    .sda_in(sda),

    .busy(),
    .done(),
    .ack_err()
  );


endmodule
