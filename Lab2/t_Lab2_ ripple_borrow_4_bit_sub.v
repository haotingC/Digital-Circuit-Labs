module	t_Lab2_ripple_borrow_4_bit_sub;
	wire	[3:0] Diff;
        wire    Bout;
	reg	[3:0] X, Y;
        reg     Bin;
	
	//instantiate device under test
        Lab2_ripple_borrow_4_bit_sub  M1(Diff, Bout, X, Y, Bin);
	
	//apply inputs one at a time
	initial	begin
		X[3]=1'b1; X[2]=1'b1; X[1]=1'b0; X[0]=1'b0; Y[3]=1'b0; Y[2]=1'b1; Y[1]=1'b0; Y[0]=1'b1; Bin=1'b1;
		#100 X[3]=1'b1; X[2]=1'b1; X[1]=1'b0; X[0]=1'b1; Y[3]=1'b0; Y[2]=1'b1; Y[1]=1'b1; Y[0]=1'b0; Bin=1'b0; 
		#100 X[3]=1'b0; X[2]=1'b1; X[1]=1'b0; X[0]=1'b1; Y[3]=1'b1; Y[2]=1'b1; Y[1]=1'b0; Y[0]=1'b1; Bin=1'b0; 
		#100 X[3]=1'b0; X[2]=1'b1; X[1]=1'b1; X[0]=1'b0; Y[3]=1'b1; Y[2]=1'b1; Y[1]=1'b0; Y[0]=1'b1; Bin=1'b1; 
		#100 X[3]=1'b1; X[2]=1'b0; X[1]=1'b0; X[0]=1'b1; Y[3]=1'b1; Y[2]=1'b0; Y[1]=1'b0; Y[0]=1'b1; Bin=1'b0; 
		#100 X[3]=1'b0; X[2]=1'b1; X[1]=1'b0; X[0]=1'b1; Y[3]=1'b0; Y[2]=1'b1; Y[1]=1'b0; Y[0]=1'b1; Bin=1'b1; 

	end
	initial #600 $finish;
endmodule
