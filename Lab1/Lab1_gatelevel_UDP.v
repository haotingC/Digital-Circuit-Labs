
module Lab1_gatelevel_UDP(F, A, B, C);
       output    F;
       input     A, B, C;
       wire      w2,w1;

       Lab1_UDP            M0(w2, A, B, C);

       or                  G2(F, w2, w1);
       and                 G1(w1, B, C);
endmodule
