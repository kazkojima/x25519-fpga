// z = (a + b) % (BigInt(2)^255-19)
module addmod(input [254:0] a,
	      input [254:0] b,
	      output [254:0] z);

   wire [255:0] zs;
   wire [255:0] zc;
   wire [255:0] sum;
   wire sel;

   csa csa0(.a(a), .b(b), .c(255'd18), .sum(zs), .cout(zc), .carry_in(1'b1));

   assign sum = zs + zc;
   assign z = (sum[255:255]) ? sum[254:0] : (a + b);
endmodule // addmod
