module	Lab2_ripple_borrow_4_bit_sub(output [3:0] Diff, output Bout, input [3:0] X, Y, input Bin);
	
	wire	B1, B2, B3;
	
        Lab2_full_sub  FS0(Diff[0], B1, X[0], Y[0], Bin);
        Lab2_full_sub  FS1(Diff[1], B2, X[1], Y[1], B1);
        Lab2_full_sub  FS2(Diff[2], B3, X[2], Y[2], B2);
        Lab2_full_sub  FS3(Diff[3], Bout, X[3], Y[3], B3);
                                  
 
endmodule
