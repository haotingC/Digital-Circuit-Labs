module	t_Lab2_full_sub;
	wire	D, B;
	reg	x, y, z;
	
	//instantiate device under test
        Lab2_full_sub  M1(D, B, x, y, z);
	
	//apply inputs one at a time
	initial	begin
		x=1'b0; y=1'b0; z=1'b0;
		#100 x=1'b0; y=1'b0; z=1'b1;
		#100 x=1'b0; y=1'b1; z=1'b0;
		#100 x=1'b0; y=1'b1; z=1'b1;
		#100 x=1'b1; y=1'b0; z=1'b0;
		#100 x=1'b1; y=1'b0; z=1'b1;
		#100 x=1'b1; y=1'b1; z=1'b0;
		#100 x=1'b1; y=1'b1; z=1'b1; 
	end
	initial #800 $finish;
endmodule

