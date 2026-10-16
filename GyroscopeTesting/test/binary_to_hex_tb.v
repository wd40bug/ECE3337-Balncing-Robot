module binary_to_hex_tb;
  reg [7:0] num;
  wire [15:0] chars;
  wire [7:0] char_1;
  wire [7:0] char_2;

  binary_to_hex #(.N(8))uut(.data_in(num), .char_out(chars));
  assign char_2 = chars[7:0];
  assign char_1 = chars[15:8];

  initial begin
    $dumpvars(0, binary_to_hex_tb);
    num = 8'hFF;
    #5;
    num = 8'hAB;
    #5;
    num = 8'h55;
    #5;
    num = 8'h00;
    #5;
    $finish;
  end
endmodule
