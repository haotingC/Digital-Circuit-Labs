module Lab2_decoder_5x32 (output [31:0] Dout, input [4:0] A, input enable);

            wire [2:0]w1;
            wire [1:0]w2;
            wire [3:0]en;
            wire [7:0]w3, w4, w5, w6;

            assign w2[1] = A[1];
            assign w2[0] = A[0];

            Lab2_decoder_2x4   M0(en, w2, enable);

            assign w1[2] = A[4];
            assign w1[1] = A[3];
            assign w1[0] = A[2]; 

            Lab2_decoder_3x8   M1(w3, w1, en[0]);
            Lab2_decoder_3x8   M2(w4, w1, en[1]);
            Lab2_decoder_3x8   M3(w5, w1, en[2]);
            Lab2_decoder_3x8   M4(w6, w1, en[3]);

            assign Dout[0] = w3[0];            assign Dout[1] = w3[1];            assign Dout[2] = w3[2];            assign Dout[3] = w3[3];
            assign Dout[4] = w3[4];            assign Dout[5] = w3[5];            assign Dout[6] = w3[6];            assign Dout[7] = w3[7];
            assign Dout[8] = w4[0];            assign Dout[9] = w4[1];            assign Dout[10] = w4[2];            assign Dout[11] = w4[3];
            assign Dout[12] = w4[4];            assign Dout[13] = w4[5];            assign Dout[14] = w4[6];            assign Dout[15] = w4[7];
            assign Dout[16] = w5[0];            assign Dout[17] = w5[1];            assign Dout[18] = w5[2];            assign Dout[19] = w5[3];
            assign Dout[20] = w5[4];            assign Dout[21] = w5[5];            assign Dout[22] = w5[6];            assign Dout[23] = w5[7];
            assign Dout[24] = w6[0];            assign Dout[25] = w6[1];            assign Dout[26] = w6[2];            assign Dout[27] = w6[3];
            assign Dout[28] = w6[4];            assign Dout[29] = w6[5];            assign Dout[30] = w6[6];            assign Dout[31] = w6[7];

endmodule            