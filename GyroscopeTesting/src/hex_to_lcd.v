module hex_to_lcd #(
    parameter N = 16 // Width of the input binary number
)(
    input  wire [N-1:0] data_in,
    
    // Flat vector containing all ASCII characters. 
    // e.g., for N=16, char_out[31:24] holds the Most Significant character.
    output wire [((N+3)/4)*8-1:0] char_out
);

    localparam DIGITS = (N + 3) / 4;
    wire [DIGITS*4-1:0] padded_in = data_in; // Zero-pad input

    genvar i;
    generate
        for (i = 0; i < DIGITS; i = i + 1) begin : gen_hex_conv
            wire [3:0] nibble = padded_in[i*4 +: 4];
            
            // Map 0-9 to 0x30-0x39, and A-F to 0x41-0x46
            assign char_out[i*8 +: 8] = (nibble <= 4'h9) ? (8'h30 + nibble) : (8'h37 + nibble);
        end
    endgenerate

endmodule
