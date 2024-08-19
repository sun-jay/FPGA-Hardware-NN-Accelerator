module debounce(
input clk,
input i,
output reg o
    );
 reg[23:0]c;
 initial c = 24'b0;
 
 always@(posedge clk)begin   
   if(i==1)begin
     if(c==24'hFFFFFF)
      o <= 1;
     else
      o <= 0;
     c <= c+1;
    end 
   else begin
     c <= 24'b0;
     o <= 0;
    end
  end  
endmodule