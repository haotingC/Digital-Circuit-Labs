module	Lab2_half_sub_behavior(D, B, x, y);
	
        output D, B;
        input  x, y;
	reg	B, D;
	
        always  @(x or y) begin
             B = ~x & y;
             D = x ^ y;
        end
endmodule

