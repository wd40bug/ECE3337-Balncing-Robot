module button_conditioner #(
    // Set this so the counter waits ~10-20ms. 
    // Example: 50MHz clock * 20ms = 1,000,000 cycles
    parameter DEBOUNCE_MAX = 20'd1_000_000
) (
    input  wire clk,
    input  wire async_btn,  // Raw input from physical pin
    output reg  btn_pulse,   // 1-cycle pulse out
    output btn_held // Is the button begin held
);

  // ----------------------------------------------------
  // 1. Synchronizer (Double-Flop)
  // ----------------------------------------------------
  reg sync_0 = 0;
  reg sync_1 = 0;
  always @(posedge clk) begin
    sync_0 <= async_btn;
    sync_1 <= sync_0;
  end

  // ----------------------------------------------------
  // 2. Debouncer
  // ----------------------------------------------------
  reg [19:0] debounce_counter = 0;
  reg debounced_state = 0;

  assign btn_held = debounced_state;

  always @(posedge clk) begin
    // If the synchronized signal differs from our stable state, start counting
    if (sync_1 != debounced_state) begin
      debounce_counter <= debounce_counter + 1;
      // Once the signal has been stable for long enough, register it
      if (debounce_counter == DEBOUNCE_MAX) begin
        debounced_state  <= sync_1;
        debounce_counter <= 0;
      end
    end else begin
      // Reset counter if the signal bounces back
      debounce_counter <= 0;
    end
  end

  // ----------------------------------------------------
  // 3. Edge Detector (Rising Edge to 1-Cycle Pulse)
  // ----------------------------------------------------
  reg debounced_delayed = 0;
  always @(posedge clk) begin
    debounced_delayed <= debounced_state;

    // Pulse goes high for exactly 1 cycle when current state is 1 and previous was 0
    btn_pulse <= debounced_state & ~debounced_delayed;
  end

endmodule
