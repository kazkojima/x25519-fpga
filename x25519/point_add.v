// Point add implementation on curve25519 based on
//
//  Hisil, Hüseyin & Wong, Kenneth & Carter, Gary & Dawson, Ed. (2008).
//  Twisted Edwards Curves Revisited. Lect. Notes Comput. Sci.. 5350. 326-343.
//  10.1007/978-3-540-89255-7_20.

`define K25519 255'd16295367250680780974490674513165176452449235426866156013048779062215315747161
//`define I255 255'd21330121701610878104342023554231983025602365596302209165163239159352418617876

// Point addition on 25519 curve
module point_add(input clk,
		 input rst,
		 input [254:0] x1,
		 input [254:0] y1,
		 input [254:0] t1,
		 input [254:0] z1,
		 input [254:0] x2,
		 input [254:0] y2,
		 input [254:0] t2,
		 input [254:0] z2,
		 output reg [254:0] x3,
		 output reg [254:0] y3,
		 output reg [254:0] t3,
		 output reg [254:0] z3,
		 input affine,
		 input req_valid,
		 output reg req_ready,
		 output reg req_busy,
		 output reg res_valid,
		 input res_ready);

   reg [254:0] add_in_1, add_in_2;
   wire [254:0] add_out;
   reg [254:0] sub_in_1, sub_in_2;
   wire [254:0] sub_out;
   reg [254:0] mul_in_1, mul_in_2;
   wire [254:0] mul_out;
   wire mul_req_ready;
   wire mul_req_busy;
   wire mul_res_valid;
   reg mul_req_valid;
   reg mul_res_ready;
   wire [254:0] inv_in;
   wire [254:0] inv_out;
   wire inv_req_ready;
   wire inv_req_busy;
   wire inv_res_valid;
   reg inv_req_valid;
   reg inv_res_ready;
   wire [254:0] P, k;

   assign P = `P25519;
   assign k = `K25519;
`ifdef I255
   wire [254:0] i2n;
   assign i2n = `I255;
`endif

   addmod add0(.a(add_in_1), .b(add_in_2), .z(add_out));
   submod sub0(.a(sub_in_1), .b(sub_in_2), .z(sub_out));
   multmod mul0(.clk(clk), .rst(rst),
		.X(mul_in_1), .Y(mul_in_2), .Z(mul_out),
		.req_valid(mul_req_valid),
		.req_ready(mul_req_ready),
		.req_busy(mul_req_busy),
		.res_valid(mul_res_valid),
		.res_ready(mul_res_ready));
   inv_montgomery #(.N(255)) inv0
     (.clk(clk), .rst(rst),
      .X(inv_in), .M(P), .R(inv_out), .real_inverse(1'b1),
      .req_valid(inv_req_valid),
      .req_ready(inv_req_ready),
      .req_busy(inv_req_busy),
      .res_valid(inv_res_valid),
      .res_ready(inv_res_ready));
   

   reg [4:0] state;
   reg [254:0] r1, r2, r3, r4, r5, r6, r7, r8, ri;
   reg [1:0] m_state;

   localparam S_IDLE = 1;
   localparam S_SUB_1 = 2;
   localparam S_SUB_2 = 3;
   localparam S_ADD_1 = 4;
   localparam S_ADD_2 = 5;
   localparam S_MUL_1 = 6;
   localparam S_MUL_2 = 7;
   localparam S_MUL_3 = 8;
   localparam S_MUL_4 = 9;
   localparam S_MUL_k = 10;
   localparam S_ADD_d = 11;
   localparam S_SUB_3 = 12;
   localparam S_SUB_4 = 13;
   localparam S_ADD_3 = 14;
   localparam S_ADD_4 = 15;
   localparam S_MUL_5 = 16;
   localparam S_MUL_6 = 17;
   localparam S_MUL_7 = 18;
   localparam S_MUL_8 = 19;
   localparam S_INV_M = 20;
   localparam S_INV = 21;
   localparam S_NRM_X = 22;
   localparam S_NRM_Y = 23;
   localparam S_NRM_T = 24;
   localparam S_POST = 25;

   localparam M_INIT = 1;
   localparam M_WAIT = 2;

   always @* begin
      if (state == S_SUB_1) begin
	 sub_in_1 = y1;
	 sub_in_2 = x1;
      end
      else if (state == S_SUB_2) begin
	 sub_in_1 = y2;
	 sub_in_2 = x2;
      end
      else if (state == S_ADD_1) begin
	 add_in_1 = y1;
	 add_in_2 = x1;
      end
      else if (state == S_ADD_2) begin
	 add_in_1 = y2;
	 add_in_2 = x2;
      end
      else if (state == S_MUL_1) begin
	 mul_in_1 = r1;
	 mul_in_2 = r2;
      end
      else if (state == S_MUL_2) begin
	 mul_in_1 = r3;
	 mul_in_2 = r4;
      end
      else if (state == S_MUL_3) begin
	 mul_in_1 = t1;
	 mul_in_2 = t2;
      end
      else if (state == S_MUL_4) begin
	 mul_in_1 = z1;
	 mul_in_2 = z2;
      end
      else if (state == S_MUL_k) begin
	 mul_in_1 = k;
	 mul_in_2 = r7;
      end
      else if (state == S_ADD_d) begin
	 add_in_1 = r8;
	 add_in_2 = r8;
      end
      else if (state == S_SUB_3) begin
	 sub_in_1 = r6;
	 sub_in_2 = r5;
      end
      else if (state == S_SUB_4) begin
	 sub_in_1 = r8;
	 sub_in_2 = r7;
      end
      else if (state == S_ADD_3) begin
	 add_in_1 = r8;
	 add_in_2 = r7;
      end
      else if (state == S_ADD_4) begin
	 add_in_1 = r6;
	 add_in_2 = r5;
      end
      else if (state == S_MUL_5) begin
	 mul_in_1 = r1;
	 mul_in_2 = r2;
      end
      else if (state == S_MUL_6) begin
	 mul_in_1 = r3;
	 mul_in_2 = r4;
      end
      else if (state == S_MUL_7) begin
	 mul_in_1 = r1;
	 mul_in_2 = r4;
      end
      else if (state == S_MUL_8) begin
	 mul_in_1 = r2;
	 mul_in_2 = r3;
      end
`ifdef I255
       else if (state == S_INV) begin
	 mul_in_1 = i2n;
	 mul_in_2 = ri;
      end
`endif
      else if (state == S_NRM_X) begin
	 mul_in_1 = x3;
	 mul_in_2 = ri;
      end
      else if (state == S_NRM_Y) begin
	 mul_in_1 = y3;
	 mul_in_2 = ri;
      end
      else if (state == S_NRM_T) begin
	 mul_in_1 = x3;
	 mul_in_2 = y3;
      end
   end

   assign inv_in = z3;

   always @(posedge clk) begin
      if (rst) begin
	 state <= S_IDLE;
	 //k <= `K25519;
	 //i2n <= `I255;
	 mul_res_ready <= 0;
	 mul_req_valid <= 0;
	 inv_res_ready <= 0;
	 inv_req_valid <= 0;
	 m_state <= M_INIT;
	 req_ready <= 0;
	 res_valid <= 0;
	 req_busy <= 0;
      end
      else if (state == S_IDLE) begin
	 if (req_valid) begin
	    req_ready <= 1;
	    req_busy <= 1;
	    state <= S_SUB_1;
	 end
      end
      else if (state == S_SUB_1) begin
	 req_ready <= 0;
	 //$display("r1 %d", sub_out);
	 r1 <= sub_out;
	 state <= S_SUB_2;
      end
      else if (state == S_SUB_2) begin
	 //$display("r2 %d", sub_out);
	 r2 <= sub_out;
	 state <= S_ADD_1;
      end
      else if (state == S_ADD_1) begin
	 //$display("r3 %d", add_out);
	 r3 <= add_out;
	 state <= S_ADD_2;
      end
      else if (state == S_ADD_2) begin
	 //$display("r4 %d", add_out);
	 r4 <= add_out;
	 state <= S_MUL_1;
      end
      else if (state == S_MUL_1) begin
	 if (m_state == M_INIT) begin
	    mul_res_ready <= 0;
	    mul_req_valid <= 1;
	    if (mul_req_ready) begin
	       mul_req_valid <= 0;
	       m_state <= M_WAIT;
	    end
	 end
	 else if (m_state == M_WAIT) begin
	    if (!mul_req_busy & mul_res_valid) begin
	       //$display("r5 %d", mul_out);
	       r5 <= mul_out;
	       mul_res_ready <= 1;
	       m_state <= M_INIT;
	       state <= S_MUL_2;
	    end
	 end
      end // if (state == S_MUL_1)
      else if (state == S_MUL_2) begin
	 if (m_state == M_INIT) begin
	    mul_res_ready <= 0;
	    mul_req_valid <= 1;
	    if (mul_req_ready) begin
	       mul_req_valid <= 0;
	       m_state <= M_WAIT;
	    end
	 end
	 else if (m_state == M_WAIT) begin
	    if (!mul_req_busy & mul_res_valid) begin
	       //$display("r6 %d", mul_out);
	       r6 <= mul_out;
	       mul_res_ready <= 1;
	       m_state <= M_INIT;
	       state <= S_MUL_3;
	    end
	 end
      end // if (state == S_MUL_2)
      else if (state == S_MUL_3) begin
	 if (m_state == M_INIT) begin
	    mul_res_ready <= 0;
	    mul_req_valid <= 1;
	    if (mul_req_ready) begin
	       mul_req_valid <= 0;
	       m_state <= M_WAIT;
	    end
	 end
	 else if (m_state == M_WAIT) begin
	    if (!mul_req_busy & mul_res_valid) begin
	       //$display("r7 %d", mul_out);
	       r7 <= mul_out;
	       mul_res_ready <= 1;
	       m_state <= M_INIT;
	       state <= S_MUL_4;
	    end
	 end
      end // if (state == S_MUL_3)
      else if (state == S_MUL_4) begin
	 if (m_state == M_INIT) begin
	    mul_res_ready <= 0;
	    mul_req_valid <= 1;
	    if (mul_req_ready) begin
	       mul_req_valid <= 0;
	       m_state <= M_WAIT;
	    end
	 end
	 else if (m_state == M_WAIT) begin
	    if (!mul_req_busy & mul_res_valid) begin
	       //$display("r8 %d", mul_out);
	       r8 <= mul_out;
	       mul_res_ready <= 1;
	       m_state <= M_INIT;
	       state <= S_MUL_k;
	    end
	 end
      end // if (state == S_MUL_4)
      else if (state == S_MUL_k) begin
	 if (m_state == M_INIT) begin
	    mul_res_ready <= 0;
	    mul_req_valid <= 1;
	    if (mul_req_ready) begin
	       mul_req_valid <= 0;
	       m_state <= M_WAIT;
	    end
	 end
	 else if (m_state == M_WAIT) begin
	    if (!mul_req_busy & mul_res_valid) begin
	       r7 <= mul_out;
	       mul_res_ready <= 1;
	       m_state <= M_INIT;
	       state <= S_ADD_d;
	    end
	 end
      end // if (state == S_MUL_k)
      else if (state == S_ADD_d) begin
	 r8 <= add_out;
	 state <= S_SUB_3;
      end
      else if (state == S_SUB_3) begin
	 r1 <= sub_out;
	 state <= S_SUB_4;
      end
      else if (state == S_SUB_4) begin
	 r2 <= sub_out;
	 state <= S_ADD_3;
      end
      else if (state == S_ADD_3) begin
	 r3 <= add_out;
	 state <= S_ADD_4;
      end
      else if (state == S_ADD_4) begin
	 r4 <= add_out;
	 state <= S_MUL_5;
      end
      else if (state == S_MUL_5) begin
	 if (m_state == M_INIT) begin
	    mul_res_ready <= 0;
	    mul_req_valid <= 1;
	    if (mul_req_ready) begin
	       mul_req_valid <= 0;
	       m_state <= M_WAIT;
	    end
	 end
	 else if (m_state == M_WAIT) begin
	    if (!mul_req_busy & mul_res_valid) begin
	       x3 <= mul_out;
	       mul_res_ready <= 1;
	       m_state <= M_INIT;
	       state <= S_MUL_6;
	    end
	 end
      end // if (state == S_MUL_5)
      else if (state == S_MUL_6) begin
	 if (m_state == M_INIT) begin
	    mul_res_ready <= 0;
	    mul_req_valid <= 1;
	    if (mul_req_ready) begin
	       mul_req_valid <= 0;
	       m_state <= M_WAIT;
	    end
	 end
	 else if (m_state == M_WAIT) begin
	    if (!mul_req_busy & mul_res_valid) begin
	       y3 <= mul_out;
	       mul_res_ready <= 1;
	       m_state <= M_INIT;
	       state <= S_MUL_7;
	    end
	 end
      end // if (state == S_MUL_6)
      else if (state == S_MUL_7) begin
	 if (m_state == M_INIT) begin
	    mul_res_ready <= 0;
	    mul_req_valid <= 1;
	    if (mul_req_ready) begin
	       mul_req_valid <= 0;
	       m_state <= M_WAIT;
	    end
	 end
	 else if (m_state == M_WAIT) begin
	    if (!mul_req_busy & mul_res_valid) begin
	       t3 <= mul_out;
	       mul_res_ready <= 1;
	       m_state <= M_INIT;
	       state <= S_MUL_8;
	    end
	 end
      end // if (state == S_MUL_7)
      else if (state == S_MUL_8) begin
	 if (m_state == M_INIT) begin
	    mul_res_ready <= 0;
	    mul_req_valid <= 1;
	    if (mul_req_ready) begin
	       mul_req_valid <= 0;
	       m_state <= M_WAIT;
	    end
	 end
	 else if (m_state == M_WAIT) begin
	    if (!mul_req_busy & mul_res_valid) begin
	       z3 <= mul_out;
	       mul_res_ready <= 1;
	       m_state <= M_INIT;
	       if (!affine) begin
		  res_valid <= 1;
		  req_busy <= 0;
		  state <= S_POST;
	       end
	       else begin
		  state <= S_INV_M;
	       end
	    end
	 end
      end // if (state == S_MUL_8)
      else if (state == S_INV_M) begin
	 if (m_state == M_INIT) begin
	    inv_res_ready <= 0;
	    inv_req_valid <= 1;
	    if (inv_req_ready) begin
	       inv_req_valid <= 0;
	       m_state <= M_WAIT;
	    end
	 end
	 else if (m_state == M_WAIT) begin
	    if (!inv_req_busy & inv_res_valid) begin
	       ri <= inv_out;
	       inv_res_ready <= 1;
	       m_state <= M_INIT;
`ifdef I255
	       state <= S_INV;
`else
	       state <= S_NRM_X;
`endif
	    end
	 end
      end // if (state == S_INV_M)
`ifdef I255
       else if (state == S_INV) begin
	 if (m_state == M_INIT) begin
	    mul_res_ready <= 0;
	    mul_req_valid <= 1;
	    if (mul_req_ready) begin
	       mul_req_valid <= 0;
	       m_state <= M_WAIT;
	    end
	 end
	 else if (m_state == M_WAIT) begin
	    if (!mul_req_busy & mul_res_valid) begin
	       ri <= mul_out;
	       mul_res_ready <= 1;
	       m_state <= M_INIT;
	       state <= S_NRM_X;
	    end
	 end
      end
`endif
      else if (state == S_NRM_X) begin
	 if (m_state == M_INIT) begin
	    mul_res_ready <= 0;
	    mul_req_valid <= 1;
	    if (mul_req_ready) begin
	       mul_req_valid <= 0;
	       m_state <= M_WAIT;
	    end
	 end
	 else if (m_state == M_WAIT) begin
	    if (!mul_req_busy & mul_res_valid) begin
	       x3 <= mul_out;
	       mul_res_ready <= 1;
	       m_state <= M_INIT;
	       state <= S_NRM_Y;
	    end
	 end
      end
      else if (state == S_NRM_Y) begin
	 if (m_state == M_INIT) begin
	    mul_res_ready <= 0;
	    mul_req_valid <= 1;
	    if (mul_req_ready) begin
	       mul_req_valid <= 0;
	       m_state <= M_WAIT;
	    end
	 end
	 else if (m_state == M_WAIT) begin
	    if (!mul_req_busy & mul_res_valid) begin
	       y3 <= mul_out;
	       mul_res_ready <= 1;
	       m_state <= M_INIT;
	       state <= S_NRM_T;
	    end
	 end
      end // if (state == S_NRM_Y)
      else if (state == S_NRM_T) begin
	 if (m_state == M_INIT) begin
	    mul_res_ready <= 0;
	    mul_req_valid <= 1;
	    if (mul_req_ready) begin
	       mul_req_valid <= 0;
	       m_state <= M_WAIT;
	    end
	 end
	 else if (m_state == M_WAIT) begin
	    if (!mul_req_busy & mul_res_valid) begin
	       t3 <= mul_out;
	       z3 <= 255'd1;
	       mul_res_ready <= 1;
	       m_state <= M_INIT;
	       res_valid <= 1;
	       req_busy <= 0;
	       state <= S_POST;
	    end
	 end
      end // if (state == S_MUL_k)
      else if (state == S_POST) begin
	 if (res_ready) begin
	    res_valid <= 0;
	    state <= S_IDLE;
	 end
      end
   end // always @ (posedge clk)

endmodule
