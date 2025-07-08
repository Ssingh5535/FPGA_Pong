module score_board #(
    parameter PADDLE_W = 200,
    parameter PADDLE_H = 20,
    parameter HRES = 1280,
    parameter VRES = 720,
    parameter COLOR = 24'hEFE62E
)(
    input pixel_clk,
    input rst,
    input fsync,
    input player_1_scored,
    input player_2_scored,
    input signed [11:0] hpos,
    input signed [11:0] vpos,
    output [7:0] pixel[0:2],
    output player_1_win,
    output player_2_win,
    output active
);

//    A 
//  F   B
//    G
//  E   C
//    D  

    //Each segment will have a 10 pixel width and 40 pixel length
    //Player 1 Segment A bounds

// Segment A bounds
localparam p1alhpos = HRES - 50;
localparam p1arhpos = HRES - 10;
localparam p1atvpos = VRES - 105;
localparam p1abvpos = VRES - 100;
wire p1a;

// Segment B bounds
localparam p1blhpos = HRES - 10;
localparam p1brhpos = HRES - 5;
localparam p1btvpos = VRES - 100;
localparam p1bbvpos = VRES - 65;
wire p1b;

// Segment C bounds
localparam p1clhpos = HRES - 10;
localparam p1crhpos = HRES - 5;
localparam p1ctvpos = VRES - 60;
localparam p1cbvpos = VRES - 25;
wire p1c;

//Segment D bounds
localparam p1dlhpos = HRES - 50;
localparam p1drhpos = HRES - 10;
localparam p1dtvpos = VRES - 25;
localparam p1dbvpos = VRES - 20;
wire p1d;


// Segment E bounds
localparam p1elhpos = HRES - 55;
localparam p1erhpos = HRES - 50;
localparam p1etvpos = VRES - 60;
localparam p1ebvpos = VRES - 25;
wire p1e;

// Segment F bounds
localparam p1flhpos = HRES - 55;
localparam p1frhpos = HRES - 50;
localparam p1ftvpos = VRES - 100;
localparam p1fbvpos = VRES - 65;
wire p1f;

// Segment G bounds
localparam p1glhpos = HRES - 50;
localparam p1grhpos = HRES - 10;
localparam p1gtvpos = VRES - 65;
localparam p1gbvpos = VRES - 60;
wire p1g;

//Player 2 Segment A bounds
localparam p2alhpos = 10;
localparam p2arhpos = 50;
localparam p2atvpos = 20;
localparam p2abvpos = 25;
wire p2a;

// Segment B bounds
localparam p2blhpos = 50;
localparam p2brhpos = 55;
localparam p2btvpos = 25;
localparam p2bbvpos = 60;
wire p2b;

// Segment C bounds
localparam p2clhpos = 50;
localparam p2crhpos = 55;
localparam p2ctvpos = 65;
localparam p2cbvpos = 100;
wire p2c;

// Segment D bounds
localparam p2dlhpos = 10;
localparam p2drhpos = 50;
localparam p2dtvpos = 100;
localparam p2dbvpos = 105;
wire p2d;

// Segment E bounds
localparam p2elhpos = 5;
localparam p2erhpos = 10;
localparam p2etvpos = 65;
localparam p2ebvpos = 100;
wire p2e;

// Segment F bounds
localparam p2flhpos = 5;
localparam p2frhpos = 10;
localparam p2ftvpos = 25;
localparam p2fbvpos = 60;
wire p2f;

// Segment G bounds
localparam p2glhpos = 10;
localparam p2grhpos = 50;
localparam p2gtvpos = 60;
localparam p2gbvpos = 65;
wire p2g;


    // Internal registers to keep track of each player's score
    reg [4:0] player_1_score;
    reg [4:0] player_2_score;

    reg player_1_scored_prev;
    reg player_2_scored_prev;

    always @(posedge pixel_clk or posedge rst) begin
        if (rst) begin
            // Reset players' scores
            player_1_score <= 4'b0000;
            player_2_score <= 4'b0000;
            player_1_scored_prev <= 1'b0;
            player_2_scored_prev <= 1'b0;
        end else begin
            // Increment player 1's score on rising edge of player_1_scored
            if (player_1_scored && !player_1_scored_prev) begin
                player_1_score <= player_1_score + 1;
            end

            // Increment player 2's score on rising edge of player_2_scored
            if (player_2_scored && !player_2_scored_prev) begin
                player_2_score <= player_2_score + 1;
            end

            // Update previous values
            player_1_scored_prev <= player_1_scored;
            player_2_scored_prev <= player_2_scored;
        end
    end

    // Determine if player 1 has won
    assign player_1_win = (player_1_score == 4'b1010) ? 1'b1 : 1'b0;
    // Determine if player 2 has won
    assign player_2_win = (player_2_score == 4'b1010) ? 1'b1 : 1'b0;

//Player 2
    assign p2a = (hpos >= p2alhpos && hpos <= p2arhpos && vpos >= p2atvpos && vpos <= p2abvpos && 
    (player_2_score != 4'b0001 && player_2_score != 4'b0100) ) ? 1'b1 : 1'b0 ; 

// Segment B
assign p2b = (hpos >= p2blhpos && hpos <= p2brhpos && vpos >= p2btvpos && vpos <= p2bbvpos && 
    (player_2_score != 4'b0101 && player_2_score != 4'b0110)) ? 1'b1 : 1'b0;

// Segment C
assign p2c = (hpos >= p2clhpos && hpos <= p2crhpos && vpos >= p2ctvpos && vpos <= p2cbvpos && 
    (player_2_score != 4'b0010 )) ? 1'b1 : 1'b0;

// Segment D
assign p2d = (hpos >= p2dlhpos && hpos <= p2drhpos && vpos >= p2dtvpos && vpos <= p2dbvpos && 
    (player_2_score != 4'b0001 && player_2_score != 4'b0100 && player_2_score != 4'b0111 && player_2_score != 4'b1001 )) ? 1'b1 : 1'b0;

// Segment E
assign p2e = (hpos >= p2elhpos && hpos <= p2erhpos && vpos >= p2etvpos && vpos <= p2ebvpos && 
    (player_2_score == 4'b0000 || player_2_score == 4'b0010 || player_2_score == 4'b0110 || player_2_score == 4'b1000)) ? 1'b1 : 1'b0;

// Segment F
assign p2f = (hpos >= p2flhpos && hpos <= p2frhpos && vpos >= p2ftvpos && vpos <= p2fbvpos && 
    (player_2_score != 4'b0001 && player_2_score != 4'b0010 && player_2_score != 4'b0011 && player_2_score != 4'b0111 )) ? 1'b1 : 1'b0;

// Segment G
assign p2g = (hpos >= p2glhpos && hpos <= p2grhpos && vpos >= p2gtvpos && vpos <= p2gbvpos && 
    (player_2_score != 4'b0000 && player_2_score != 4'b0001 && player_2_score != 4'b0111)) ? 1'b1 : 1'b0;

//Player 1
// Segment A
assign p1a = (hpos >= p1alhpos && hpos <= p1arhpos && vpos >= p1atvpos && vpos <= p1abvpos && 
    (player_1_score != 4'b0001 && player_1_score != 4'b0100) ) ? 1'b1 : 1'b0 ; 

// Segment B
assign p1b = (hpos >= p1blhpos && hpos <= p1brhpos && vpos >= p1btvpos && vpos <= p1bbvpos && 
    (player_1_score != 4'b0101 && player_1_score != 4'b0110)) ? 1'b1 : 1'b0;

// Segment C
assign p1c = (hpos >= p1clhpos && hpos <= p1crhpos && vpos >= p1ctvpos && vpos <= p1cbvpos && 
    (player_1_score != 4'b0010 )) ? 1'b1 : 1'b0;

// Segment D
assign p1d = (hpos >= p1dlhpos && hpos <= p1drhpos && vpos >= p1dtvpos && vpos <= p1dbvpos && 
    (player_1_score != 4'b0001 && player_1_score != 4'b0100 && player_1_score != 4'b0111 && player_1_score != 4'b1001 )) ? 1'b1 : 1'b0;

// Segment E
assign p1e = (hpos >= p1elhpos && hpos <= p1erhpos && vpos >= p1etvpos && vpos <= p1ebvpos && 
    (player_1_score == 4'b0000 || player_1_score == 4'b0010 || player_1_score == 4'b0110 || player_1_score == 4'b1000)) ? 1'b1 : 1'b0;

// Segment F
assign p1f = (hpos >= p1flhpos && hpos <= p1frhpos && vpos >= p1ftvpos && vpos <= p1fbvpos && 
    (player_1_score != 4'b0001 && player_1_score != 4'b0010 && player_1_score != 4'b0011 && player_1_score != 4'b0111 )) ? 1'b1 : 1'b0;

// Segment G
assign p1g = (hpos >= p1glhpos && hpos <= p1grhpos && vpos >= p1gtvpos && vpos <= p1gbvpos && 
    (player_1_score != 4'b0000 && player_1_score != 4'b0001 && player_1_score != 4'b0111)) ? 1'b1 : 1'b0;

    assign active = (p2a | p2b | p2c | p2d | p2e | p2f | p2g | p1a | p1b | p1c | p1d | p1e | p1f | p1g);

    /* If active is high, set the RGB values for neon green */
    assign pixel [ 2 ] = (active) ? COLOR [ 23 : 16 ] : 8 'h00; //red 
    assign pixel [ 1 ] = (active) ? COLOR [ 15 : 8 ] : 8 'h00; //green 
    assign pixel [ 0 ] = (active) ? COLOR [ 7 : 0 ] : 8 'h00; //blue 

endmodule