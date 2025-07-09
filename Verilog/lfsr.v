module lfsr (
    input clk,
    input rst,
    input [11:0] vpos, // Input vpos from the top module
    input [11:0] PADDLE_H, // Input PADDLE_H from the top module
    input active,
    input player_1_score,
    output reg [1:0] rand_out

);

reg [3:0] lfsr_state;

always @(posedge clk) begin
    if (player_1_score) begin
        lfsr_state <= 4'b0001; // Initial state
    end else begin
        // LFSR operation based on XOR feedback
        lfsr_state[3:1] <= lfsr_state[2:0];
    end
    lfsr_state[0] <= lfsr_state[3] ^ lfsr_state[0];
end

always @(posedge rst) begin
    if (player_1_score) begin
        lfsr_state <= 4'b0001; // Initial state
    end else begin
        lfsr_state[3:1] <= 3'b000; // Reset state
    end
end

// Output restricted to the range 1-3
always @* begin
    case (lfsr_state[1:0])
        2'b00: rand_out = 2'b01; // Map 00 to 01
        2'b01: rand_out = 2'b10; // Map 01 to 10
        2'b10: rand_out = 2'b11; // Map 10 to 11
        2'b11: rand_out = 2'b01; // Map 11 to 01 (looping)
    endcase
end

endmodule
