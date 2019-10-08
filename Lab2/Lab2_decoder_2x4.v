module Lab2_decoder_2x4(output [3:0] Dout, input [1:0] A, input enable); 
    
    
    assign Dout[0] = (~A[1]) & (~A[0]) & enable;
    assign Dout[1]= (~A[1]) & A[0] & enable;
    assign Dout[2]= A[1] & (~ A[0]) & enable;
    assign Dout[3]= A[1] & A[0] & enable;

endmodule
