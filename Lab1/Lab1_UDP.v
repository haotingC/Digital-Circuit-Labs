primitive Lab1_UDP(D, A, B, C);
   output D;
   input A, B, C;

// Truth table for D = f(A, B, C) = m(2, 3, 5, 7);
   table
// A B C : D // Column header comment
   0 0 0 : 0;
   0 0 1 : 0;
   0 1 0 : 1;
   0 1 1 : 1;
   1 0 0 : 0;
   1 0 1 : 1;
   1 1 0 : 0;
   1 1 1 : 1;
 endtable
endprimitive
