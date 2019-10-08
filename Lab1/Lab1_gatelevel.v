module	Lab1_gatelevel(A, B, C, F);
	output	F;
	input	A, B, C;
	wire	w1, w2, w3, w4, w5;
	
	and		G1(w2, w1, B);
        and             G3(w3, A, C);
        and             G4(w4, B, C);
	not		G2(w1, A);
        or		G5(w5, w1, w2);
        or              G6(F, w5, w4);
endmodule
