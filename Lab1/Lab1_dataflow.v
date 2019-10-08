module Lab1_dataflow( A, B, C, F );

    input A, B, C;
    output F;

    wire w1, w2, w3, w4, w5;

    assign w1 = ~A;
    assign w2 = w1&&B;
    assign w3 = A&&C;
    assign w4 = C&&B;
    assign w5 = w2||w3;
    assign F = w5||w4;


endmodule
