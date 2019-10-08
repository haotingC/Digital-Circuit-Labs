module	t_Lab2_half_sub;
	wire	D, B;
	reg	x, y;
	
	//instantiate device under test
        Lab2_half_sub_gate_level  M1(D, B, x, y);
	Lab2_half_sub_dataflow    M2(D, B, x, y);
        Lab2_half_sub_behavior    M3(D, B, x, y);

	
	//apply inputs one at a time
	initial	begin
		x=1'b0; y=1'b0;
		#100 x=1'b0; y=1'b1;
		#100 x=1'b1; y=1'b0;
		#100 x=1'b1; y=1'b1;
	end
	initial #400 $finish;
endmodule

