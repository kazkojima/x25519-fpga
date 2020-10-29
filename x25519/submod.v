`define P25519 255'd57896044618658097711785492504343953926634992332820282019728792003956564819949

// t = (a - b) % (BigInt(2)^255 - 19)
// return (t < 0) ? t + (BigInt(2)^255 - 19) : t
module submod(input [254:0] a,
	      input [254:0] b,
	      output [254:0] z);

   wire [255:0] zs;
   wire [255:0] zc;
   wire [255:0] ws;
   wire [255:0] wc;
   wire [255:0] sum, alt;
   wire sel;

   csa csa0(.a(a), .b(~b), .c(255'd0), .sum(zs), .cout(zc), .carry_in(1'b0));
   csa csa1(.a(a), .b(~b), .c(`P25519), .sum(ws), .cout(wc), .carry_in(1'b0));

   assign sum = zs + zc + 1;
   assign alt = ws + wc + 1;
   assign z = (sum[255:255]) ? sum[254:0] : alt[254:0];

endmodule // submod
