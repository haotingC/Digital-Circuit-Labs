module	Lab2_half_sub_gate_level(output D, B, input x, y);
	
	wire	w1, w2, w3;
	
        not             G1(w1, x);
	not		G2(w2, y);
        and             G3(B, w1, y);
        and             G4(w3, x, w2);
        or		G5(D, B, w3);

endmodule

