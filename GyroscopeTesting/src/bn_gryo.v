module bn_gyro(
    input clk,
    input rx_data_valid,
    input [7:0] uart_data,
    input tx_cur_transmitting,
    input tx_done,
    output [7:0] tx_data,
    output tx_ready,
    output led_wire,
    output [63:0] gyro_response,
    output [7:0] pitch_angle
);


// startup states
localparam POWER_UP = 3'd0;
localparam CONFIG = 3'd1;
localparam WAIT_CONFIG = 3'd2;
localparam CALIBRATE = 3'd3;
localparam NDOF = 3'd4;
localparam WAIT_NDOF = 3'd5;
localparam CHECK_STATUS = 3'd6;
localparam STARTUP_DONE = 3'd7;

    // to transmit:
    // put the data you want to transmit in tx_data
    // set tx_ready high
    reg rx_data_valid_d;
    reg [7:0] gyro_received_byte;
    reg [63:0] gyro_output;
    
    reg tx_finished = 1'd0;

    reg tx_ready_reg = 1'd0;
    assign tx_ready = tx_ready_reg;

    reg [64:0] normal_tx_command_reg;
    reg [64:0] load_tx_command_reg = 64'd0;
    reg load_command_flag;
    reg [4:0] command_length;
    reg [4:0] loaded_command_length;

    reg [207:0] calibration_command = 208'hAA_00_55_16_EB_FF_1E_00_F4_FF_56_FE_02_FE_1B_02_FF_FF_00_00_FE_FF_E8_03_4F_03;
    reg calibration_command_flag = 1'd0;
    reg [4:0] calibration_command_length = 5'd26;

    reg [7:0] tx_data_reg = 8'd0;
    assign tx_data = tx_data_reg;


    // 1 when all bytes of quaternion is received
    reg quaternion_done = 1'd0;
    // keep track of bytes received
    reg [3:0] quat_bytes = 4'd0;
    reg reset_quat_count = 1'd0;

    reg just_got_data = 1'd0;

    // stuff for delay_ms
    reg [9:0] ms_to_delay;
    reg reset_delay_ms = 1'd1;
    wire delay_done_wire;
    reg delay_done_reg;

    reg startup_done = 1'd0;

    reg led_wire_reg = 1'd1;
    assign led_wire = led_wire_reg;

    assign gyro_response = gyro_output;
    

    // stuff for calculating pitch
    reg pitch_rst = 1'd1;
    wire signed [15:0] qw, qx, qy, qz;
    wire pitch_sign;
    wire [6:0] pitch_mag;
    wire pitch_valid_out;

    assign qw = {gyro_output[55:48], gyro_output[63:56]};//gyro_output[63:48];
    assign qx = {gyro_output[39:32], gyro_output[47:40]};//gyro_output[47:32];
    assign qy = {gyro_output[23:16], gyro_output[31:24]};//gyro_output[31:16];
    assign qz = {gyro_output[7:0], gyro_output[15:8]};//gyro_output[15:0];
    
    assign pitch_angle = {pitch_sign, pitch_mag};
// Receive data
always@(posedge clk) begin
        rx_data_valid_d <= rx_data_valid;

        if(rx_data_valid && !rx_data_valid_d) begin
            gyro_received_byte <= uart_data;
            just_got_data <= 1'd1;
            /*
            // echo back
            tx_byte <= uart_data;
            tx_ready <= 1'd1;*/
        end
        else if(just_got_data == 1'd1) begin
            // shift output left and add new byte
            gyro_output <= {gyro_output[55:0], gyro_received_byte};
            just_got_data <= 1'd0;
        end
        if(startup_state == STARTUP_DONE && just_got_data) begin
            if (gyro_received_byte == 8'hBB) begin
                quat_bytes <= 4'd1;
                quaternion_done <= 1'b0;
            end
            else if (quat_bytes >= 1 && quat_bytes < 4'd9) begin
                quat_bytes <= quat_bytes + 1'd1;
            end
            else if (quat_bytes == 4'd9) begin
                quaternion_done <= 1'b1;
            end
        end
        else if (quaternion_done && pitch_valid_out) begin
            quat_bytes <= 4'd0;
            quaternion_done <= 1'b0;
        end
    end

// Transmit data
always@(posedge clk) begin
    if(tx_cur_transmitting) begin
        tx_ready_reg <= 1'd0;
    end
    else if(load_command_flag) begin
        normal_tx_command_reg <= load_tx_command_reg;
        loaded_command_length <= command_length;
        tx_finished <= 1'd1;
    end
    else if(loaded_command_length > 0 && tx_finished) begin
        tx_data_reg <= normal_tx_command_reg[63:56];
        normal_tx_command_reg <= normal_tx_command_reg << 8;
        loaded_command_length <= loaded_command_length - 1;
        tx_ready_reg <= 1'd1;
        tx_finished <= 1'd0;
    end
    // only used to send calibration preset
    else if(calibration_command_flag && calibration_command_length > 0 && tx_finished) begin
        tx_data_reg <= calibration_command[207:200];
        calibration_command <= calibration_command << 8;
        calibration_command_length <= calibration_command_length - 1;
        tx_ready_reg <= 1'd1;
        tx_finished <= 1'd0;
    end
    if(tx_done) begin
        tx_finished <= 1'd1;
        tx_ready_reg <= 1'd0;
    end
end


// -------------------- STARTUP -----------------------
reg [2:0] startup_state = POWER_UP;
reg command_sent = 1'd0;
reg calibration_sent = 1'b0;
reg ndof_sent = 1'd0;
reg waiting = 1'd0;
reg waiting_1 = 1'd0;

always@(posedge clk) begin
    load_command_flag <= 1'd0;

    if(!startup_done) begin
        case(startup_state)
        POWER_UP: begin
            if(reset_delay_ms) begin
                ms_to_delay <= 10'd650;
                reset_delay_ms <= 1'd0;
            end
            else if(delay_done_wire && !command_sent) begin
                command_length <= 4;
                load_tx_command_reg[63:32] <= 32'hAA_01_00_01;
                command_sent <= 1'd1;
                load_command_flag <= 1'd1;
            end
            if(gyro_output[23:0] == 24'hBB_01_A0) begin
                startup_state <= CONFIG;
                command_sent <= 1'd0;
                led_wire_reg <= 1'd0;
                reset_delay_ms <= 1'd1;
            end
        end
        CONFIG: begin
            if(reset_delay_ms) begin
                ms_to_delay <= 10'd50;
                reset_delay_ms <= 1'd0;
            end
            else if(delay_done_wire && !command_sent) begin
                command_length <= 5;
                load_tx_command_reg[63:24] <= 40'hAA_00_3D_01_00;
                command_sent <= 1'd1;
                load_command_flag <= 1'd1;
            end
            if(gyro_output[15:0] == 16'hEE_01) begin
                startup_state <= WAIT_CONFIG;
                command_sent <= 1'd0;
                led_wire_reg <= 1'd1;
                reset_delay_ms <= 1'd1;
            end
        end

        // comment to mark this spot
        WAIT_CONFIG: begin
            if(reset_delay_ms) begin
                ms_to_delay <= 10'd50;
                reset_delay_ms <= 1'd0;
            end
            else if(delay_done_wire && !command_sent) begin
                calibration_command_flag <= 1'd1;
                command_sent <= 1'd1;
            end
            if(calibration_command_length == 0) begin
                calibration_sent <= 1'd1;
            end
            if(gyro_output[15:0] == 16'hEE_01 && calibration_sent) begin
                startup_state <= NDOF;
                command_sent <= 1'd0;
                led_wire_reg <= 1'd0;
                reset_delay_ms <= 1'd1;
            end
        end
        NDOF: begin
            if(reset_delay_ms) begin
                ms_to_delay <= 10'd963;
                reset_delay_ms <= 1'd0;
            end
            else if(delay_done_wire && !command_sent) begin
                command_length <= 5;
                load_tx_command_reg[63:24] <= 40'hAA_00_3D_01_0C;
                command_sent <= 1'd1;
                load_command_flag <= 1'd1;
            end
            else if(loaded_command_length == 0 && command_sent) begin
                ndof_sent <= 1'd1;
            end
            if(gyro_output [15:0] == 16'hEE_01 && ndof_sent) begin
                startup_state <= WAIT_NDOF;
                command_sent <= 1'd0;   
                led_wire_reg <= 1'd1;
                reset_delay_ms <= 1'd1;
            end
            else if(gyro_output[15:0] == 16'hEE_07 && ndof_sent) begin
                command_sent <= 1'd0;
                reset_delay_ms <= 1'd1;
                led_wire_reg = ~led_wire_reg;
            end
        end
        WAIT_NDOF: begin
            if(reset_delay_ms) begin
                ms_to_delay <= 10'd987;
                reset_delay_ms <= 1'd0;
            end
            else if(delay_done_wire && !command_sent) begin
                command_length <= 4;
                load_tx_command_reg[63:32] <= 32'hAA_01_3D_01;
                command_sent <= 1'd1;
                load_command_flag <= 1'd1;
            end
            if(gyro_output[7:0] == 8'h0C) begin
                led_wire_reg <= 1'd0;
                reset_delay_ms <= 1'd1;
                command_sent <= 1'd0;
                startup_state <= CHECK_STATUS;
            end
            else if(gyro_output[15:0] == 16'hEE_07) begin
                command_sent <= 1'd0;
                reset_delay_ms <= 1'd1;
                led_wire_reg <= ~led_wire_reg;
            end
            /*else begin
                startup_state <= NDOF;
                reset_delay_ms <= 1'd1;
                ndof_sent <= 1'd0;
            end*/
        end
        CHECK_STATUS: begin
            if(reset_delay_ms) begin
                ms_to_delay <= 10'd74;
                reset_delay_ms <= 1'd0;
            end
            else if(delay_done_wire && !command_sent) begin
                command_length <= 4;
                load_tx_command_reg[63:32] <= 32'hAA_01_39_01;
                command_sent <= 1'd1;
                load_command_flag <= 1'd1;
            end
            else if(gyro_output[15:0] == 16'hEE_07) begin
                reset_delay_ms <= 1'd1;
                command_sent <= 1'd0;
            end
            else if(gyro_output[7:0] != 8'h01 && gyro_output[7:0] != 8'h0C) begin
                startup_state <= STARTUP_DONE;
                command_sent <= 1'd0;
                reset_delay_ms <= 1'd1;
            end
        end
        STARTUP_DONE: begin
            if(reset_delay_ms && !waiting) begin
                ms_to_delay <= 10'd14;
                reset_delay_ms <= 1'd0;
            end
            else if(delay_done_wire && !command_sent) begin
                command_length <= 4;
                load_tx_command_reg[63:32] <= 32'hAA_01_20_08;
                command_sent <= 1'd1;
                load_command_flag <= 1'd1;
                waiting <= 1'd1;
                reset_delay_ms <= 1'd1;
            end
            else if(waiting && !waiting_1) begin
                ms_to_delay <= 10'd10;
                waiting_1 <= 1'd1;
            end
            else if(reset_delay_ms && waiting) begin
                reset_delay_ms <= 1'd1;
                command_sent <= 1'd0;
                waiting <= 1'd0;
                waiting_1 <= 1'd0;
            end
        end

        endcase
    end
end

/* ----------- CONFIG STEPS ----------------- */
/*
(All commands in hex)
POWER UP PHASE: Check status to see if power up is finished
Wait at least 650 ms
Send: AA 01 00 01 (command to get chip ID)
Over and over until you receive:
BB 01 A0
(A0 is the chip ID)
working :)


PUT IN CONFIG MODE
Send: AA 00 3D 01 00
3D is mode
00 is configmode

Expected response:
EE 01
(EE 03 means write fail, EE 04 means invalid address)

Wait at least 25 ms
working :)


WRITE CALIBRATION SEQUENCE
AA 00 55 16
[22 bytes of calibration data]

Expected response:
EE 01
working :)


PUT IN NDOF MODE
Send: AA 00 3D 01 0C
0C is NDOF mode

Expected response:
EE 01

Wait at least 10 ms


READ MODE BACK TO ENSURE IT IS IN NDOF
Send: AA 01 3D 01

Expected response:
BB 01 0C


CHECK SYSTEM STATUS
Send: AA 01 39 01

Expected response:
BB 01 XX
Anything other than 01 is fine for XX. 01 means error


**Possibly check error status if error, idk**


To read quaternion:
AA 01 20 08

08 means 8 bytes of data will be received:
L = low byte, H = high byte

Received data order:
QW_L QW_H
QX_L QX_H
QY_l QY_H
QZ_L QZ_H

quaternion scale: 16384 (whatever that means)   



CALIBRATION NUMS:
    0xEB,
    0xFF,
    0x1E,
    0x00,
    0xF4,
    0xFF,
    0x56,
    0xFE,
    0x02,
    0xFE,
    0x1B,
    0x02,
    0xFF,
    0xFF,
    0x00,
    0x00,
    0xFE,
    0xFF,
    0xE8,
    0x03,
    0x4F,
    0x03

*/

delay_ms delayer(
    .clk(clk),
    .ms_to_delay(ms_to_delay),
    .reset(reset_delay_ms),
    .time_elapsed(delay_done_wire)
);

pitch_lut pitch_calc(
    .clk(clk),
    .rst_neg(pitch_rst),
    .in_valid(quaternion_done),
    .qw(qw),
    .qx(qx),
    .qy(qy),
    .qz(qz),
    .pitch_sign(pitch_sign),
    .pitch_magnitude(pitch_mag),
    .out_valid(pitch_valid_out)
);

endmodule
