module pwm_audio
(
    input clk,
    input reset_n,
    input signed [15:0] sample,
    output pwm
);

    // Convert signed PCM to offset binary, then use the carry from a
    // first-order accumulator as the one-bit DAC output. Signed silence maps
    // to 50% density, allowing the board's analogue filter to remove DC.
    wire [15:0] unsigned_sample = sample ^ 16'h8000;
    reg [16:0] accumulator = 17'd0;

    always_ff @(posedge clk or negedge reset_n)
    begin
        if (!reset_n)
            accumulator <= 17'd0;
        else
            accumulator <= {1'b0, accumulator[15:0]} +
                           {1'b0, unsigned_sample};
    end

    assign pwm = accumulator[16];

endmodule
