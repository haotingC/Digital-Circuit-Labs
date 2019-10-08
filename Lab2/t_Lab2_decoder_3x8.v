module t_Lab2_decoder_3x8;
      wire   [7:0]Dout;
      reg    [2:0]A;
      reg    enable;

      Lab2_decoder_3x8    M1(Dout, A, enable);
      

      initial begin 
              A[2]=1'b0; A[1]=1'b0; A[0]=1'b0; enable=1'b0;
              #100 A[2]=1'b0; A[1]=1'b0; A[0]=1'b1; enable=1'b0;
              #100 A[2]=1'b0; A[1]=1'b1; A[0]=1'b0; enable=1'b0;
              #100 A[2]=1'b0; A[1]=1'b1; A[0]=1'b1; enable=1'b0;
              #100 A[2]=1'b1; A[1]=1'b0; A[0]=1'b0; enable=1'b0;
              #100 A[2]=1'b1; A[1]=1'b0; A[0]=1'b1; enable=1'b0;
              #100 A[2]=1'b1; A[1]=1'b1; A[0]=1'b0; enable=1'b0;
              #100 A[2]=1'b1; A[1]=1'b1; A[0]=1'b1; enable=1'b0;
              #100 A[2]=1'b0; A[1]=1'b0; A[0]=1'b0; enable=1'b1;
              #100 A[2]=1'b0; A[1]=1'b0; A[0]=1'b1; enable=1'b1;
              #100 A[2]=1'b0; A[1]=1'b1; A[0]=1'b0; enable=1'b1;
              #100 A[2]=1'b0; A[1]=1'b1; A[0]=1'b1; enable=1'b1;
              #100 A[2]=1'b1; A[1]=1'b0; A[0]=1'b0; enable=1'b1;
              #100 A[2]=1'b1; A[1]=1'b0; A[0]=1'b1; enable=1'b1;
              #100 A[2]=1'b1; A[1]=1'b1; A[0]=1'b0; enable=1'b1;
              #100 A[2]=1'b1; A[1]=1'b1; A[0]=1'b1; enable=1'b1;
      end 
      initial #1600 $finish;
endmodule 
