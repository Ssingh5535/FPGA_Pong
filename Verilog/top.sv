module top ( 
    input clk125, 
    input right,
    input left, 
    input right_two,
    input left_two, 
    
    output tmds_tx_clk_p, 
    output tmds_tx_clk_n,
    
    output [2:0] tmds_tx_data_p, 
    output [2:0] tmds_tx_data_n,
    //output led_kawser, 
    
    output led_right,
    output led_left
    
    ); 
    
    
    localparam HRES = 1280; 
    localparam VRES = 720; 
    
    
    localparam PADDLE_W = 200;
    localparam PADDLE_H = 20; 
    
    localparam COLOR_OBJ = 24'h 00FF90; 
    localparam COLOR_PAD = 24'h EFE62E; 
    localparam COLOR_GMO = 24'h DD4F83; 
    
    
    localparam GAMEOVER_H = 200; 
    
    localparam GAMEOVER_VSTART = (VRES - GAMEOVER_H) >> 1 ; 
    
    
    localparam RESTART_PAUSE = 128 ;
    
    
    wire pixel_clk; 
    
    wire rst ; 
    
    wire active ; 
    
    wire fsync; 
    
    wire signed [11:0] hpos; 
    
    wire signed [11:0] vpos; 
    
    wire [7:0] pixel [0 : 2 ] ; 
    
    
    wire active_obj ; 
    
    
    reg active_passing ; 
    wire [7 : 0 ] pixel_obj [0:2] ;
    
    
    wire active_paddle; 
    wire [7 : 0 ] pixel_paddle [0:2] ;
    
    //active paddle two
    wire active_paddle_two; 
    wire [7 : 0 ] pixel_paddle_two [0:2] ;
    
    //score board
    wire active_score_board;
    wire [7 : 0 ] pixel_score_board [0:2] ;
    
    reg game_over_eval, evaluate ; 
    reg game_over; 
    reg [7 : 0 ] pause ; 


    
    wire [HRES-1 : 0] bitmap ; 
    
    wire active_gameover ; 
    wire bitmap_on; 
    wire [7:0] pixel_gameover [0:2] ; 
    
    wire player_1_win;
    wire player_2_win;
    reg player_1_score;
    reg player_2_score;
    
    reg reset_scoreboard;
    
    
    /* Add Scoreboard Instantiation Here */
    
    /* Add Top Paddle Instantiation Here */
    
    
    // HDMIT Transmit + clock video timing 
    hdmi_transmit hdmi_transmit_inst ( 
    
        .clk125         (clk125), 
        .pixel          (pixel), 
        
        
        // Shared video interface to the rest of the system 
        
        .pixel_clk      (pixel_clk), 
        .rst            (rst),
        .active         (active),
        .fsync          (fsync),
        .hpos           (hpos),
        .vpos           (vpos), 
        
        .tmds_tx_clk_p  (tmds_tx_clk_p),  
        .tmds_tx_clk_n  (tmds_tx_clk_n),
    
        .tmds_tx_data_p (tmds_tx_data_p), 
        .tmds_tx_data_n (tmds_tx_data_n)
        
     ); 
     
     
     
     
     
     // Handle Bounce 
     object #( 

 .HRES      (HRES),
 .VRES      (VRES),
 .COLOR     (COLOR_OBJ),
 .PADDLE_H  (PADDLE_H) 
)

object_inst


    (
       .pixel_clk   (pixel_clk),
       .rst         (rst || game_over),
       .fsync       (fsync),  
       .hpos        (hpos), 
       .vpos        (vpos), 
       .pixel       (pixel_obj) , 
       .active      (active_obj)
        
        
    );
     
         score_board #( 
 .PADDLE_W  (PADDLE_W),
 .PADDLE_H  (PADDLE_H),
 .HRES      (HRES),
 .VRES      (VRES),
 .COLOR     (COLOR_GMO)
)

scoreboard_inst


    (
       .pixel_clk   (pixel_clk),
       .rst         (rst || reset_scoreboard),
       .fsync       (fsync),  
       .hpos        (hpos), 
       .vpos        (vpos), 
       .player_1_scored (player_1_score),
       .player_2_scored (player_2_score),
       .pixel       (pixel_score_board),
       .active      (active_score_board),
       .player_1_win (player_1_win),
       .player_2_win (player_2_win)
        
        
    );
        
         paddle #( 

 .HRES      (HRES),
 .VRES      (VRES),
 .PADDLE_W  (PADDLE_W),
 .PADDLE_H  (PADDLE_H),
 .COLOR     (COLOR_PAD)
  
)

paddle_inst


    (
       .pixel_clk   (pixel_clk),
       .rst         (rst || game_over),
       .fsync       (fsync),  
       .hpos        (hpos), 
       .vpos        (vpos), 
       
       .right       (right),
       .left        (left), 
       
       
       .pixel       (pixel_paddle) , 
       .active      (active_paddle)
        
        
    );
    
    paddle_two #( 

 .HRES      (HRES),
 .VRES      (VRES),
 .PADDLE_W  (PADDLE_W),
 .PADDLE_H  (PADDLE_H),
 .COLOR     (COLOR_PAD)
  
)

paddle_two_inst


    (
       .pixel_clk   (pixel_clk),
       .rst         (rst || game_over),
       .fsync       (fsync),  
       .hpos        (hpos), 
       .vpos        (vpos), 
       
       .right_two       (right_two),
       .left_two        (left_two), 
       
       
       .pixel       (pixel_paddle_two) , 
       .active      (active_paddle_two)
        
        
    );
     

  
  gameover_bitmap gameover_bitmap_inst ( 
  
        .clka           (pixel_clk),
        .ena            (1'b1),
        .addra          (vpos [7:0]),
        .douta          (bitmap)
        
       ); 
       
       
    
    // GAME OVER Pixel active, middle of the screen 
    assign active_gameover = ((player_1_win || player_2_win) && vpos >= GAMEOVER_VSTART  && vpos < GAMEOVER_VSTART + GAMEOVER_H)  ? 1'b1 : 1'b0 ; 
    
    assign bitmap_on = (bitmap >> hpos) & 1'b1; 
    
    // RGB pixels for pop up game 
    assign pixel_gameover [2] = (active_gameover && bitmap_on) ? COLOR_GMO [23 : 16] : 8'h00; 
    assign pixel_gameover [1] = (active_gameover && bitmap_on) ? COLOR_GMO [15 : 8] : 8'h00; 
    assign pixel_gameover [0] = (active_gameover && bitmap_on) ? COLOR_GMO [7 : 0] : 8'h00; 
    
    
    // Display RGB pixels 
    
    //assign pixel [2] = game_over ? pixel_gameover [2] : pixel_obj [ 2 ] | pixel_paddle [ 2 ] ;
    //assign pixel [1] = game_over ? pixel_gameover [1] : pixel_obj [ 1 ] | pixel_paddle [ 1 ] ;
    //assign pixel [0] = game_over ? pixel_gameover [0] : pixel_obj [ 0 ] | pixel_paddle [ 0 ] ;
    
    assign pixel [2] = game_over ? pixel_gameover [2] : pixel_obj [ 2 ] | pixel_paddle [ 2 ] | pixel_paddle_two [ 2 ] |  pixel_score_board [2];
    assign pixel [1] = game_over ? pixel_gameover [1] : pixel_obj [ 1 ] | pixel_paddle [ 1 ] | pixel_paddle_two [ 1 ] |  pixel_score_board [1];
    assign pixel [0] = game_over ? pixel_gameover [0] : pixel_obj [ 0 ] | pixel_paddle [ 0 ] | pixel_paddle_two [ 0 ] |  pixel_score_board [0];

       
       //assign led_kawser = 1; 
       assign led_right = player_1_win;
       assign led_left = player_2_win;
     
     // We need to detect gameover 
     
     
     always @(posedge pixel_clk)
     
     begin 
        
        
        
        if(rst) begin 
            reset_scoreboard <= 1'b0;
            player_1_score <= 1'b0;
            player_2_score <= 1'b0;
            game_over               <= 1'b0; 
            game_over_eval          <= 1'b0; 
            evaluate                <= 1'b0;
            pause                   <= 0;
            active_passing          <= 1'b0; 
            
             
        
        end else begin   
            
            
            if(~evaluate) begin 
                if(fsync) begin 
                       evaluate <= 1'b1; 
                end;
                pause                   <= 0;
                active_passing          <= 1'b0; 
            
            end else begin 
                if(~game_over_eval) begin 
                    if(vpos == VRES - PADDLE_H && active_obj) begin 
                         active_passing          <= 1'b1; 
                         if (active_paddle) begin 
                               evaluate                <= 1'b0;
                         end
                    end else if(vpos == PADDLE_H -1 && active_obj) begin
                            active_passing          <= 1'b1; 
                         if (active_paddle_two) begin 
                               evaluate                <= 1'b0;
                         end
                        
                    end else if (active_passing) begin 
                        if(~active_obj) begin 
                              game_over_eval          <= 1'b1; 
                              if(vpos <= PADDLE_H -1) begin 
                                player_1_score <= 1'b1;
                                end else if (vpos >= VRES - PADDLE_H) begin 
                                player_2_score <= 1'b1;
                                end 
                                
                              
                        end
                    end
                end else if (fsync) begin 
                    if(pause == RESTART_PAUSE) begin
                        player_1_score          <= 1'b0;
                        player_2_score          <= 1'b0;
                        game_over_eval          <= 1'b0;
                        evaluate                <= 1'b0; 
                        game_over               <= 1'b0;
                        reset_scoreboard        <= 1'b0; 
                    end
                    else if(pause == RESTART_PAUSE - 1) begin
                        pause                   <= pause + 1;
                        game_over               <= 1'b1;
                        if(player_1_win || player_2_win) begin
                            reset_scoreboard        <= 1'b1;
                        end
                    end
                    
                    else begin
                    if(pause == 20 && ~player_1_win && ~player_2_win) begin
                        pause <= RESTART_PAUSE;
                    end 
                    else begin
                        pause                   <= pause + 1; 
                    end
                        game_over               <= 1'b1; 
                    end
                
                
                end
                
                
                
        
        end 
     end 
end 


endmodule