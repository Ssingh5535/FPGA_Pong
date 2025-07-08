module paddle #( 

parameter HRES = 1280,
parameter VRES = 720,
//parameter VTOP,
//parameter VBOT,

parameter PADDLE_W = 200,
parameter PADDLE_H = 20,
parameter COLOR = 24'h EFE62E
)   (
        input pixel_clk,
        input rst,
        
        input fsync, 
        
        input signed [11:0] hpos, 
        input signed [11:0] vpos, 
        
        //Buttons
        input right, 
        input left, 

        //Pixel output for paddle
        output [7:0] pixel [0:2] , 
        
        output active 
        
        
    );
    
    //Paddle velocity
    localparam VEL = 16; 
    
    /* NOTE: Put means the paddle is not moving */
    localparam PUT = 2'h00;
    localparam LEFT = 2'h01;
    localparam RIGHT = 2'h10;
    
    //Flip-flop for right and left buttons
    reg [0 : 2] right_ff  , left_ff ; 
    
    //Assuming this is the bottom paddle
    //And that the top left pixel represents (0,0) and bottom right is (1279, 719)
    
    //These values represent the left and right edge of the paddle
    //These values should be changed depending on the dir register
    reg signed [ 11 : 0 ] lhpos; 
    reg signed [ 11 : 0 ] rhpos; 

    //These values represent the top and bottom edge of the paddle
    //These values should be constant as the paddle should never move up or down
    reg signed [ 11 : 0 ] tvpos; 
    reg signed [ 11 : 0 ] bvpos; 
    
    
    reg [ 1 : 0 ] dir ; 
    
    reg register_right, register_left ; 
    
    
    //always @(posedge pixel_clk) 
    always @(pixel_clk) 
    
    begin 
        if(rst) begin 
            dir <= PUT ; 
            register_right <= 1'b0; 
            register_left <= 1'b0;
        end else begin 
            if (fsync) begin 
                if (register_right) begin 
                    dir <= RIGHT ; 
                end else if (register_left) begin 
                    dir <= LEFT ; 
                end else begin 
                    dir <= PUT ; 
                end 
                
                register_right <= 1'b0;
                register_left  <= 1'b0 ;
            end else begin 
                if (( ~register_right ) && (~register_left)) begin 
                
                   if (left_ff[2]) begin
                register_left <= 1'b1;
            end else if (right_ff[2]) begin
                register_right <= 1'b1;
                    end 
               end 
           end 
       end 
       
       right_ff <= {right, right_ff [ 0 : 1 ] } ; 
       left_ff <= {left, left_ff [ 0 : 1 ] } ; 
       
end                     


always @(posedge pixel_clk)
begin
    if (rst) begin
        lhpos <= 0;
        rhpos <= PADDLE_W - 1;
        tvpos <= VRES -PADDLE_H;
        bvpos <= VRES -1;
        //tvpos <= VTOP;
        //bvpos <= VBOT;
    end else begin
        if (fsync) begin
          /* The first paddle should be located at the top of the screen */
            if (dir == RIGHT && right == 1'b1) begin 
                //Before moving paddle right, check to make sure the paddles new location is within the screen
                if(( rhpos + VEL) <= HRES  - 1)begin
                    //rhpos <= rhpos;
                    //lhpos <= lhpos;
                    rhpos <= rhpos + VEL;
                    lhpos <= lhpos + VEL;
                end
                else begin
                //Move the paddle to the right bound
                    rhpos <= HRES - 1;
                    lhpos <= HRES -PADDLE_W;
                end
            end 
            else if ( left == 1'b1) begin
                //Before moving paddle left, check to make sure the paddles new location is within the screen
                if(( lhpos - VEL) >= 0)begin
                    rhpos <= rhpos - VEL;
                    lhpos <= lhpos - VEL;
                end
                else begin
                    //Move the paddle to the left bound
                    rhpos <= PADDLE_W - 1;
                    lhpos <= 0;
                end
                
            end 
            else if ( dir == PUT) begin
                //Keep paddle in same spot
                    rhpos <= rhpos;
                    lhpos <= lhpos;                   
               end
            end
        end
     end

    /* Active calculates whether the current pixel being updated by the HDMI controller is within the bounds of the ball's */
    /* Simple Example: If the ball is located at position 0,0 and vpos and rpos = 0, active will be high, placing a green pixel */
    assign active = (hpos >= lhpos && hpos <= rhpos && vpos >= tvpos && vpos <= bvpos ) ? 1'b1 : 1'b0 ; 
    
    /* If active is high, set the RGB values for neon green */
    assign pixel [ 2 ] = (active) ? COLOR [ 23 : 16 ] : 8 'h00; //red 
    assign pixel [ 1 ] = (active) ? COLOR [ 15 : 8 ] : 8 'h00; //green 
    assign pixel [ 0 ] = (active) ? COLOR [ 7 : 0 ] : 8 'h00; //blue 
    
    
                         
            
endmodule