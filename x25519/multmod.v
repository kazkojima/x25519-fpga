// Multiplication mod 2^255-19 implementation based on
//
//  Mehrabi, Ali & Doche, Christophe. (2019). Low-Cost, Low-Power FPGA
//  Implementation of ED25519 and CURVE25519 Point Multiplication.
//  Information. 10. 285. 10.3390/info10090285.

`include "./csa.v"

`define P25519 255'd57896044618658097711785492504343953926634992332820282019728792003956564819949

// Writeable lut of carry saved i*Y for i=0:7
module lutram
  (input clk,
   input wen,
   input [2:0] addr,
   input [260-1:0] sum_in, c_in,
   output reg [260-1:0] sum_out, c_out);

   reg [260*2-1:0] mem [0:7];

   always @(posedge clk) begin
      { sum_out, c_out } <= mem[addr];
      if (wen)
        mem[addr] <= { sum_in, c_in };
   end
endmodule // lutram

// Input X, Y in 0:P-1
// Output Z in 0:P-1 where Z = X*Y mod P=2^255-19
module multmod
  (input clk,
   input rst,
   input [254:0] X,
   input [254:0] Y,
   output reg [254:0] Z,
   input req_valid,
   output reg req_ready,
   output reg req_busy,
   output reg res_valid,
   input res_ready);

   wire [254:0] P;
   reg wen;
   reg [2:0] lut1idx;
   reg [259:0] ms_in, mc_in;
   wire [259:0] ms, mc;
   reg [259:0] s, c, s1, c1, s2, c2, s3, c3, sn, cn;
   reg [15:0] l, n;
   reg [255:0] x;
   reg [255:0] z, t;
   wire [257:0] sy7, cy7;
   wire [255:0] rs, rc;
   reg [6:0] k;
   reg [4:0] state;

   localparam S_IDLE = 1;
   localparam S_PRECOMP = 2;
   localparam S_PRECOMP_END = 3;
   localparam S_LOOP = 4;
   localparam S_REDUCE_STEP1 = 6;
   localparam S_REDUCE_STEP2 = 7;
   localparam S_REDUCE_STEP3 = 8;
   localparam S_REDUCE_STEP4 = 9;
   localparam S_POST = 10;

   assign P = `P25519;

   lutram lut1(.clk(clk), .wen(wen), .addr(lut1idx[2:0]),
	       .sum_in(ms_in), .c_in(mc_in), .sum_out(ms), .c_out(mc));
   csa #(.N(257)) y7(.a({ Y, 2'b0 }), .b({ 1'b0, Y, 1'b0 }), .c({ 2'b0, Y }),
		     .carry_in(1'b0), .sum(sy7), .cout(cy7));
   csa #(.N(255)) re(.a(s[254:0]), .b(c[254:0]), .c({ 242'b0, l[15:3] }),
		     .carry_in(1'b0), .sum(rs), .cout(rc));

   // Precomputed lut of i*8*19 for i=0:23
   function [15:0] lut2(input [4:0] addr);
      case(addr)
	0: lut2 = 16'd0;
	1: lut2 = 16'd152;
	2: lut2 = 16'd304;
	3: lut2 = 16'd456;
	4: lut2 = 16'd608;
	5: lut2 = 16'd760;
	6: lut2 = 16'd912;
	7: lut2 = 16'd1064;
	8: lut2 = 16'd1216;
	9: lut2 = 16'd1368;
	10: lut2 = 16'd1520;
	11: lut2 = 16'd1672;
	12: lut2 = 16'd1824;
	13: lut2 = 16'd1976;
	14: lut2 = 16'd2128;
	15: lut2 = 16'd2280;
	16: lut2 = 16'd2432;
	17: lut2 = 16'd2584;
	18: lut2 = 16'd2736;
	19: lut2 = 16'd2888;
	20: lut2 = 16'd3040;
	21: lut2 = 16'd3192;
	22: lut2 = 16'd3344;
	23: lut2 = 16'd3496;
	24: lut2 = 16'd3648;
	25: lut2 = 16'd3800;
	26: lut2 = 16'd3952;
	27: lut2 = 16'd4104;
	28: lut2 = 16'd4256;
	29: lut2 = 16'd4408;
	30: lut2 = 16'd4560;
	31: lut2 = 16'd4712;
      endcase // case (addr)
   endfunction


   always @* begin
      if (state == S_LOOP) begin
	 s1 = { s[254:0], 3'b0 };
	 c1 = { c[254:0], 3'b0 };
	 s2 = (s1 ^ ms) ^ c1;
	 c2 = { ((s1 & ms) | (s1 & c1) | (ms & c1)), 1'b0 };
         s3 = (s2 ^ mc) ^ c2;
         c3 = { ((s2 & mc) | (s2 & c2) | (mc & c2)), 1'b0 };
         sn = { s3[259:16], (s3[15:0] ^ n) } ^ c3;
         cn = { ((s3[15:0] & n) | (s3 & c3) | (n & c3[15:0])), 1'b0 };
      end // if (state == S_LOOP)
      else if (state == S_REDUCE_STEP4) begin
	 t = z + 19;
      end
   end

   always @(posedge clk) begin
      if (rst) begin
	 state <= S_IDLE;
	 req_ready <= 0;
	 res_valid <= 0;
	 req_busy <= 0;
      end
      else begin
	 if (state == S_IDLE) begin
	    if (req_valid == 1'b1) begin
	       req_ready <= 1;
	       req_busy <= 1;
	       x <= X;
	       s <= 0;
	       c <= 0;
	       n <= 0;
	       wen <= 1;
	       lut1idx <= 0;
	       ms_in <= 0;
	       mc_in <= 0;
	       state <= S_PRECOMP;
	    end
	 end
	 else if (state == S_PRECOMP) begin
	    req_ready <= 0;
	    if (lut1idx == 7) begin
	       wen <= 0;
	       // for k = 85
	       lut1idx <= x[254:252];
	       x <= { x[251:0], 3'b0 };
	       state <= S_PRECOMP_END;
	    end
	    else begin
	       if (lut1idx == 0) begin
		  ms_in <= Y;
		  mc_in <= 0;
	       end
	       else if (lut1idx == 1) begin
		  ms_in <= Y;
		  mc_in <= Y;
	       end
	       else if (lut1idx == 2) begin
		  ms_in <= { Y, 1'b0 };
		  mc_in <= Y;
	       end
	       else if (lut1idx == 3) begin
		  ms_in <= { Y, 1'b0 };
		  mc_in <= { Y, 1'b0 };
	       end
	       else if (lut1idx == 4) begin
		  ms_in <= { Y, 2'b0 };
		  mc_in <= Y;
	       end
	       else if (lut1idx == 5) begin
		  ms_in <= { Y, 2'b0 };
		  mc_in <= { Y, 1'b0 };
	       end
	       else if (lut1idx == 6) begin
		  ms_in <= sy7;
		  mc_in <= cy7;
	       end
	       lut1idx <= lut1idx + 1;
	    end // else: !if(lut1idx == 8)
	 end // if (state == S_PRECOMP)
	 else if (state == S_PRECOMP_END) begin
	    k <= 84;
	    lut1idx <= x[254:252];
	    x <= { x[251:0], 3'b0 };
	    state <= S_LOOP;
	 end
	 else if (state == S_LOOP) begin
	    //$display("k %d s %d c %d\n s1+c1 %d\n s2+c1 %d\n s3+c3", k, sn, cn, sn+cn, s1+c1, s2+c2, s3+c3);
	    s <= sn;
	    c <= cn;
	    n <= lut2(sn[258:255] + cn[258:255]);
	    lut1idx <= x[254:252];
	    x <= { x[251:0], 3'b0 };
	    k <= k - 1;
	    state <= (k == 0) ? S_REDUCE_STEP1 : S_LOOP;
	 end // if (state == S_LOOP)
	 else if (state == S_REDUCE_STEP1) begin
	    //$display("reduce step1: s %d c %d n %d", s, c, n);
	    l <= lut2(s[258:255] + c[258:255]);
	    state <= S_REDUCE_STEP2;
	 end
	 else if (state == S_REDUCE_STEP2) begin
	    //$display("reduce step2: rs %d rc %d n %d", rs, rc, n);
	    s <= rs;
	    c <= rc;
	    l <= lut2(rs[255:255] + rc[255:255]);
	    state <= S_REDUCE_STEP3;
	 end
	 else if (state == S_REDUCE_STEP3) begin
	    //$display("reduce step3: rs %d rc %d", rs, rc);
	    z <= rs + rc;
	    state <= S_REDUCE_STEP4;
	 end
	 else if (state == S_REDUCE_STEP4) begin
	    Z <= (t[255:255]) ? t[254:0] : z[254:0];
	    res_valid <= 1;
	    req_busy <= 0;
	    state <= S_POST;
	 end
	 else if (state == S_POST) begin
	    if (res_ready == 1'b1) begin
	       res_valid <= 0;
	       state <= S_IDLE;
	    end
	 end
      end   
   end
endmodule // multmod
