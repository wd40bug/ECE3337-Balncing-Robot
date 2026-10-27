module esp_commands(
input clk,
input rx_data_valid,
input [7:0] uart_data,
input tx_cur_transmitting,
input tx_done,
output [7:0] tx_data,
output tx_ready,
output on_state,
output [11:0] pitch_p,
output [11:0] pitch_i,
output [11:0] pitch_d,
output [11:0] pitch_shift,
output [11:0] motor_p,
output [11:0] motor_i,
output [11:0] motor_d,
output [11:0] motor_shift,
output reg pids_updated,
output key_up,
output key_down,
output reg [7:0] key_code,
output [103:0] esp_raw_output
);

localparam TURN_ON = 3'd1;
localparam TURN_OFF = 3'd2;
localparam BUTTON_DOWN = 3'd3;
localparam BUTTON_UP = 3'd4;
localparam SET_PIDS = 3'd5;
localparam NO_COMMAND = 3'd6;

reg [11:0] pitch_p_reg = 12'd0;
reg [11:0] pitch_i_reg = 12'd0;
reg [11:0] pitch_d_reg = 12'd0;
reg [11:0] pitch_shift_reg = 12'd0;
reg [11:0] motor_p_reg = 12'd0;
reg [11:0] motor_i_reg = 12'd0;
reg [11:0] motor_d_reg = 12'd0;
reg [11:0] motor_shift_reg = 12'd0;

assign pitch_p = pitch_p_reg;
assign pitch_i = pitch_i_reg;
assign pitch_d = pitch_d_reg;
assign pitch_shift = pitch_shift_reg;
assign motor_p = motor_p_reg;
assign motor_i = motor_i_reg;
assign motor_d = motor_d_reg;
assign motor_shift = motor_shift_reg;


reg [2:0] cmd_state = NO_COMMAND;

reg processing_command = 1'd0;
reg cmd_length = 4'd0;

reg rx_data_valid_d;

reg [103:0] total_received_data;
assign esp_raw_output = total_received_data;
reg [7:0] received_byte;
reg just_got_data;

reg on_state_reg = 1'd0;
assign on_state = on_state_reg;

reg key_up_reg = 1'd0;
reg key_down_reg = 1'd0;
assign key_up = key_up_reg;
assign key_down = key_down_reg;

// receive data
always@(posedge clk) begin
        rx_data_valid_d <= rx_data_valid;
        pids_updated <= 1'd0;
        key_up_reg <= 1'd0;
        key_down_reg <= 1'd0;
        just_got_data <= 1'd0;


        if(rx_data_valid && !rx_data_valid_d) begin
            received_byte <= uart_data;
            just_got_data <= 1'd1;

            total_received_data <= {total_received_data[95:0], received_byte};
            /*
            // echo back
            tx_byte <= uart_data;
            tx_ready <= 1'd1;*/
        end
        /*else if(just_got_data == 1'd1) begin
            // shift output left and add new byte
            
        end*/

        if(received_byte == SET_PIDS && !processing_command && just_got_data) begin
            processing_command <= 1'd1;
            cmd_state <= SET_PIDS;
            cmd_length <= cmd_length + 1;
        end
        else if(cmd_state == SET_PIDS && processing_command && cmd_length < 13 && just_got_data) begin
            cmd_length <= cmd_length + 1;
        end
        else if(cmd_state == SET_PIDS && processing_command && cmd_length == 13 && just_got_data) begin
            cmd_length <= 0;
            pitch_p_reg[11:0] <= total_received_data[95:84];
            pitch_i_reg[11:0] <= total_received_data[83:72];
            pitch_d_reg[11:0] <= total_received_data[71:60];
            pitch_shift_reg[11:0] <= total_received_data[59:48];
            motor_p_reg[11:0] <= total_received_data[47:36];
            motor_i_reg[11:0] <= total_received_data[35:24];
            motor_d_reg[11:0] <= total_received_data[23:12];
            motor_shift_reg[11:0] <= total_received_data[11:0];
            pids_updated <= 1'd1;
            cmd_state <= NO_COMMAND;
        end
        else if(received_byte == BUTTON_UP && !processing_command && just_got_data) begin
            processing_command <= 1'd1;
            cmd_state <= BUTTON_UP;
        end
        else if(cmd_state == BUTTON_UP && processing_command && just_got_data) begin
            processing_command <= 1'd0;
            key_up_reg <= 1'd1;
            key_code <= received_byte;
            cmd_state <= NO_COMMAND;
        end
        else if(received_byte == BUTTON_DOWN && !processing_command && just_got_data) begin
            processing_command <= 1'd1;
            cmd_state <= BUTTON_DOWN;
        end
        else if(cmd_state == BUTTON_DOWN && processing_command && just_got_data) begin
            processing_command <= 1'd0;
            key_down_reg <= 1'd1;
            key_code <= received_byte;
            cmd_state <= NO_COMMAND;
        end
        else if(received_byte == TURN_ON && !processing_command && just_got_data) begin
            on_state_reg <= 1'd1;
            cmd_state <= NO_COMMAND;
        end
        else if(received_byte == TURN_OFF && !processing_command && just_got_data) begin
            on_state_reg <= 1'd0;
            cmd_state <= NO_COMMAND;
        end
        else if(cmd_state == NO_COMMAND) begin
        end
end



endmodule