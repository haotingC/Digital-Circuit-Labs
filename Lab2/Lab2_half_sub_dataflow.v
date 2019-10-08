module Lab2_half_sub_dataflow(output D, B, input x, y);
  
    
    wire	w1, w2, w3;

    assign      w1 = ~x;
    assign      w2 = ~y;
    assign      B = w1&&y;
    assign      w3 = x&&w2;
    assign      D = B||w3;


endmodule

