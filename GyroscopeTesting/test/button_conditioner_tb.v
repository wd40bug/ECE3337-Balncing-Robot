module button_conditioner_tb;

  // ----------------------------------------------------
  // Testbench Parameters & Signals
  // ----------------------------------------------------
  localparam [19:0] TB_DEBOUNCE_MAX = 20'd5;
  localparam CLK_PERIOD = 10; // 100MHz clock (10ns period)

  reg  clk = 0;
  reg  async_btn = 0;
  wire btn_pulse;
  wire btn_held;

  // ----------------------------------------------------
  // Device Under Test (DUT)
  // ----------------------------------------------------
  button_conditioner #(
      .DEBOUNCE_MAX(TB_DEBOUNCE_MAX)
  ) dut (
      .clk        (clk),
      .async_btn  (async_btn),
      .btn_pulse  (btn_pulse),
      .btn_held   (btn_held)
  );

  // ----------------------------------------------------
  // Clock Generator
  // ----------------------------------------------------
  always #(CLK_PERIOD / 2) clk = ~clk;

  // ----------------------------------------------------
  // Helper Tasks
  // ----------------------------------------------------
  
  // Simulates mechanical bounce noise on the button pin
  task automatic simulate_bounce(input integer iterations);
    integer i;
    begin
      for (i = 0; i < iterations; i++) begin
        async_btn = $urandom_range(0, 1);
        #(CLK_PERIOD * $urandom_range(1, 3));
      end
    end
  endtask

  // ----------------------------------------------------
  // Main Test Sequence
  // ----------------------------------------------------
  initial begin
    $dumpvars(0, button_conditioner_tb);

    // Initial state setup
    async_btn = 0;
    #(CLK_PERIOD * 5);

    // --------------------------------------------------
    // TEST 1: Press with Bouncing Noise
    // --------------------------------------------------
    simulate_bounce(6);

    // Drive button stable HIGH and wait out the debounce time
    async_btn = 1;
    #(CLK_PERIOD * (TB_DEBOUNCE_MAX + 10));

    if (btn_held !== 1'b1) begin
      $error("FAIL [Test 1]: btn_held should be 1 after debouncing press!");
    end

    // --------------------------------------------------
    // TEST 2: Glitch Rejection (Noise shorter than DEBOUNCE_MAX)
    // --------------------------------------------------
    async_btn = 0;
    #(CLK_PERIOD * (TB_DEBOUNCE_MAX / 2)); 
    async_btn = 1; // Return high before counter finishes
    #(CLK_PERIOD * (TB_DEBOUNCE_MAX + 5));

    if (btn_held !== 1'b1) begin
      $error("FAIL [Test 2]: Short glitch caused false debounced state change!");
    end

    // --------------------------------------------------
    // TEST 3: Release with Bouncing Noise
    // --------------------------------------------------
    simulate_bounce(6);

    // Drive button stable LOW and wait out the debounce time
    async_btn = 0;
    #(CLK_PERIOD * (TB_DEBOUNCE_MAX + 10));

    if (btn_held !== 1'b0) begin
      $error("FAIL [Test 3]: btn_held should be 0 after debouncing release!");
    end

    #(CLK_PERIOD * 5);
    $finish;
  end

  // ----------------------------------------------------
  // Assertions / Pulse Verification
  // ----------------------------------------------------
  
  // Track previous state of btn_held to catch transitions
  reg prev_btn_held = 0;
  always @(posedge clk) begin
    prev_btn_held <= btn_held;

    // Verify 1-cycle pulse asserts on rising edge of btn_held
    if (btn_held && !prev_btn_held) begin
      @(posedge clk);
      if (btn_pulse !== 1'b1) begin
        $error("[Assertion Fail] btn_pulse did not assert on rising edge of btn_held!");
      end
      @(posedge clk);
      if (btn_pulse !== 1'b0) begin
        $error("[Assertion Fail] btn_pulse remained high for more than 1 cycle!");
      end
    end
  end

endmodule
