module	Lab2_full_sub(output D, B, input x, y, z);
	
	wire	Dh0, Bh0, Bh1;
	
        Lab2_half_sub_gate_level HS0(Dh0, Bh0, x, y);
        Lab2_half_sub_gate_level HS1(D, Bh1, Dh0, z);

        or		G1(B, Bh0, Bh1);

endmodule

