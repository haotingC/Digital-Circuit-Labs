module t_Lab2_decoder_2x4;
      wire   [3:0]Dout;
      reg    [1:0]A;
      reg    enable;

      Lab2_decoder_2x4    M1(Dout, A, enable);
      

      initial begin 
              A[1]=1'b0; A[0]=1'b0; enable=1'b0;
              #100 A[1]=1'b0; A[0]=1'b1; enable=1'b0;
              #100 A[1]=1'b1; A[0]=1'b0; enable=1'b0;
              #100 A[1]=1'b1; A[0]=1'b1; enable=1'b0;
              #100 A[1]=1'b0; A[0]=1'b0; enable=1'b1;
              #100 A[1]=1'b0; A[0]=1'b1; enable=1'b1;
              #100 A[1]=1'b1; A[0]=1'b0; enable=1'b1;
              #100 A[1]=1'b1; A[0]=1'b1; enable=1'b1;
      end 
      initial #800 $finish;
endmodule 
