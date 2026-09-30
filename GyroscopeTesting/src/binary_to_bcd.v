module binary_to_bcd(
    input wire [7:0] binary,
    output reg [3:0] hundreds,
    output reg [3:0] tens,
    output reg [3:0] ones
);

    reg [3:0] i;

    reg [19:0] temp;

    always@(*) begin
        temp = {12'b0, binary};

        //loop 8 times
        for(i = 0; i < 8; i = i + 1) begin
            // hundreds digit
            if(temp[19:16] > 4)
                temp[19:16] = temp[19:16] + 3;
            // tens digit
            if(temp[15:12] > 4)
                temp[15:12] = temp[15:12] + 3;
            // ones digit
            if(temp[11:8] > 4)
                temp[11:8] = temp[11:8] + 3;

            // shift left 1
            temp = temp << 1;
        end
        
        // split
        hundreds = temp[19:16];
        tens = temp[15:12];
        ones = temp[11:8];
    
    end

endmodule