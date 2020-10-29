`ifndef _CSA_V
`define _CSA_V 1

// Carry saved adder
module csa #(parameter N=255)
   (input [N-1:0] a,
    input [N-1:0] b,
    input [N-1:0] c,
    input carry_in,
    output [N:0] sum,
    output [N:0] cout);
   assign sum = { 1'b0, ((a ^ b) ^ c) };
   assign cout = { (((a & b) | (a & c)) | (b & c)), carry_in };
endmodule // csa

`endif //  `ifndef _CSA_V
