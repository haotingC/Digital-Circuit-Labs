module Lab2_decoder_3x8(output [7:0] Dout, input [2:0] A, input enable); 
    
    
    assign Dout[0]= (~A[2]) & (~A[1]) & (~A[0]) & enable;
    assign Dout[1]= (~A[2]) & (~A[1]) & (A[0]) & enable;
    assign Dout[2]= (~A[2]) & (A[1]) & (~A[0]) & enable;
    assign Dout[3]= (~A[2]) & (A[1]) & (A[0]) & enable;
    assign Dout[4]= (A[2]) & (~A[1]) & (~A[0]) & enable;
    assign Dout[5]= (A[2]) & (~A[1]) & (A[0]) & enable;
    assign Dout[6]= (A[2]) & (A[1]) & (~A[0]) & enable;
    assign Dout[7]= (A[2]) & (A[1]) & (A[0]) & enable;

endmodule
