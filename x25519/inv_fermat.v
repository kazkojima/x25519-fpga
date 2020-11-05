// Modular imverse modulo 2^255-19 by the Fermat's little theorem
//
// Unused. Only for a reference.

// Input X in 1:2^255-20
// Output Xinv in 1:2^255-20
module invmod
   (input clk,
    input rst,
    input [254:0] X,
    output reg [254:0] Xinv,
    input req_valid,
    output reg req_ready,
    output reg req_busy,
    output reg res_valid,
    input res_ready);

   reg [254:0] b, a2, a9, a11, a_2_5, a_2_10, a_2_20, a_2_40, a_2_50, a_2_100,
	       a_2_200, a_2_250;
   reg [6:0] pcount;
   reg [5:0] state;
   reg [1:0] m_state;

   reg [254:0] mul_in_1, mul_in_2;
   wire [254:0] mul_out;
   wire mul_req_ready;
   wire mul_req_busy;
   wire mul_res_valid;
   reg mul_req_valid;
   reg mul_res_ready;

   multmod mul0(.clk(clk), .rst(rst),
		.X(mul_in_1), .Y(mul_in_2), .Z(mul_out),
		.req_valid(mul_req_valid),
		.req_ready(mul_req_ready),
		.req_busy(mul_req_busy),
		.res_valid(mul_res_valid),
		.res_ready(mul_res_ready));

   localparam S_IDLE = 1;
   localparam S_READY = 2;
   localparam S_A2 = 3;
   localparam S_A4 = 4;
   localparam S_A8 = 5;
   localparam S_A9 = 6;
   localparam S_A11 = 7;
   localparam S_A22 = 8;
   localparam S_A_2_5 = 9;
   localparam S_B_2_10 = 10;
   localparam S_A_2_10 = 11;
   localparam S_B_2_20 = 12;
   localparam S_A_2_20 = 13;
   localparam S_B_2_40 = 14;
   localparam S_A_2_40 = 15;
   localparam S_B_2_50 = 16;
   localparam S_A_2_50 = 17;
   localparam S_B_2_100 = 18;
   localparam S_A_2_100 = 19;
   localparam S_B_2_200 = 20;
   localparam S_A_2_200 = 21;
   localparam S_B_2_250 = 22;
   localparam S_A_2_250 = 23;
   localparam S_B_2_255 = 24;
   localparam S_INV = 25;
   localparam S_POST = 26;

   localparam M_INIT = 1;
   localparam M_WAIT = 2;

   always @* begin
      if (state == S_A2) begin
	 mul_in_1 = X;
	 mul_in_2 = X;
      end
      else if (state == S_A4) begin
	 mul_in_1 = a2;
	 mul_in_2 = a2;
      end
      else if (state == S_A8) begin
	 mul_in_1 = b;
	 mul_in_2 = b;
      end
      else if (state == S_A9) begin
	 mul_in_1 = b;
	 mul_in_2 = X;
      end
      else if (state == S_A11) begin
	 mul_in_1 = a9;
	 mul_in_2 = a2;
      end
      else if (state == S_A22) begin
	 mul_in_1 = a11;
	 mul_in_2 = a11;
      end
      else if (state == S_A_2_5) begin
	 mul_in_1 = b;
	 mul_in_2 = a9;
      end
      else if (state == S_B_2_10) begin
	 mul_in_1 = b;
	 mul_in_2 = b;
      end
      else if (state == S_A_2_10) begin
	 mul_in_1 = b;
	 mul_in_2 = a_2_5;
      end
      else if (state == S_B_2_20) begin
	 mul_in_1 = b;
	 mul_in_2 = b;
      end
      else if (state == S_A_2_20) begin
	 mul_in_1 = b;
	 mul_in_2 = a_2_10;
      end
      else if (state == S_B_2_40) begin
	 mul_in_1 = b;
	 mul_in_2 = b;
      end
      else if (state == S_A_2_40) begin
	 mul_in_1 = b;
	 mul_in_2 = a_2_20;
      end
      else if (state == S_B_2_50) begin
	 mul_in_1 = b;
	 mul_in_2 = b;
      end
      else if (state == S_A_2_50) begin
	 mul_in_1 = b;
	 mul_in_2 = a_2_10;
      end
      else if (state == S_B_2_100) begin
	 mul_in_1 = b;
	 mul_in_2 = b;
      end
      else if (state == S_A_2_100) begin
	 mul_in_1 = b;
	 mul_in_2 = a_2_50;
      end
      else if (state == S_B_2_200) begin
	 mul_in_1 = b;
	 mul_in_2 = b;
      end
      else if (state == S_A_2_200) begin
	 mul_in_1 = b;
	 mul_in_2 = a_2_100;
      end
      else if (state == S_B_2_250) begin
	 mul_in_1 = b;
	 mul_in_2 = b;
      end
      else if (state == S_A_2_250) begin
	 mul_in_1 = b;
	 mul_in_2 = a_2_50;
      end
      else if (state == S_B_2_255) begin
	 mul_in_1 = b;
	 mul_in_2 = b;
      end
      else if (state == S_INV) begin
	 mul_in_1 = b;
	 mul_in_2 = a11;
      end
   end

   always @(posedge clk) begin
      //$display($time,,,"istate=%d rst=%d", state, rst);
      
      if (rst) begin
	 state <= S_IDLE;
	 mul_res_ready <= 0;
	 mul_req_valid <= 0;
	 m_state <= M_INIT;
	 pcount <= 0;
	 req_ready <= 0;
	 req_busy <= 0;
	 res_valid <= 0;
      end
      else if (state == S_IDLE) begin
	 if (req_valid == 1'b1) begin
	    req_ready <= 1;
	    req_busy <= 1;
	    state <= S_READY;
	 end
      end
      else if (state == S_READY) begin
	 req_ready <= 0;
	 state <= S_A2;
      end
      else if (state == S_A2) begin
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
	       a2 <= mul_out;
	       mul_res_ready <= 1;
	       m_state <= M_INIT;
	       state <= S_A4;
	    end
	 end
      end
      else if (state == S_A4) begin
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
	       b <= mul_out;
	       mul_res_ready <= 1;
	       m_state <= M_INIT;
	       state <= S_A8;
	    end
	 end
      end
      else if (state == S_A8) begin
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
	       b <= mul_out;
	       mul_res_ready <= 1;
	       m_state <= M_INIT;
	       state <= S_A9;
	    end
	 end
      end
      else if (state == S_A9) begin
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
	       a9 <= mul_out;
	       mul_res_ready <= 1;
	       m_state <= M_INIT;
	       state <= S_A11;
	    end
	 end
      end
      else if (state == S_A11) begin
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
	       a11 <= mul_out;
	       mul_res_ready <= 1;
	       m_state <= M_INIT;
	       state <= S_A22;
	    end
	 end
      end
      else if (state == S_A22) begin
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
	       b <= mul_out;
	       mul_res_ready <= 1;
	       m_state <= M_INIT;
	       state <= S_A_2_5;
	    end
	 end
      end
      else if (state == S_A_2_5) begin
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
	       a_2_5 <= mul_out;
	       b <= mul_out;
	       mul_res_ready <= 1;
	       m_state <= M_INIT;
	       pcount <= 5;
	       state <= S_B_2_10;
	    end
	 end
      end
      else if (state == S_B_2_10) begin
	 if (pcount == 0) begin
	    state <= S_A_2_10;
	 end
	 else if (m_state == M_INIT) begin
	    mul_res_ready <= 0;
	    mul_req_valid <= 1;
	    if (mul_req_ready) begin
	       mul_req_valid <= 0;
	       m_state <= M_WAIT;
	    end
	 end
	 else if (m_state == M_WAIT) begin
	    if (!mul_req_busy & mul_res_valid) begin
	       b <= mul_out;
	       mul_res_ready <= 1;
	       m_state <= M_INIT;
	       pcount <= pcount - 1;
	    end
	 end
      end
      else if (state == S_A_2_10) begin
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
	       a_2_10 <= mul_out;
	       b <= mul_out;
	       mul_res_ready <= 1;
	       m_state <= M_INIT;
	       pcount <= 10;
	       state <= S_B_2_20;
	    end
	 end
      end
      else if (state == S_B_2_20) begin
	 if (pcount == 0) begin
	    state <= S_A_2_20;
	 end
	 else if (m_state == M_INIT) begin
	    mul_res_ready <= 0;
	    mul_req_valid <= 1;
	    if (mul_req_ready) begin
	       mul_req_valid <= 0;
	       m_state <= M_WAIT;
	    end
	 end
	 else if (m_state == M_WAIT) begin
	    if (!mul_req_busy & mul_res_valid) begin
	       b <= mul_out;
	       mul_res_ready <= 1;
	       m_state <= M_INIT;
	       pcount <= pcount - 1;
	    end
	 end
      end
      else if (state == S_A_2_20) begin
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
	       a_2_20 <= mul_out;
	       b <= mul_out;
	       mul_res_ready <= 1;
	       m_state <= M_INIT;
	       pcount <= 20;
	       state <= S_B_2_40;
	    end
	 end
      end
      else if (state == S_B_2_40) begin
	 if (pcount == 0) begin
	    state <= S_A_2_40;
	 end
	 else if (m_state == M_INIT) begin
	    mul_res_ready <= 0;
	    mul_req_valid <= 1;
	    if (mul_req_ready) begin
	       mul_req_valid <= 0;
	       m_state <= M_WAIT;
	    end
	 end
	 else if (m_state == M_WAIT) begin
	    if (!mul_req_busy & mul_res_valid) begin
	       b <= mul_out;
	       mul_res_ready <= 1;
	       m_state <= M_INIT;
	       pcount <= pcount - 1;
	    end
	 end
      end
      else if (state == S_A_2_40) begin
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
	       a_2_40 <= mul_out;
	       b <= mul_out;
	       mul_res_ready <= 1;
	       m_state <= M_INIT;
	       pcount <= 10;
	       state <= S_B_2_50;
	    end
	 end
      end
      else if (state == S_B_2_50) begin
	 if (pcount == 0) begin
	    state <= S_A_2_50;
	 end
	 else if (m_state == M_INIT) begin
	    mul_res_ready <= 0;
	    mul_req_valid <= 1;
	    if (mul_req_ready) begin
	       mul_req_valid <= 0;
	       m_state <= M_WAIT;
	    end
	 end
	 else if (m_state == M_WAIT) begin
	    if (!mul_req_busy & mul_res_valid) begin
	       b <= mul_out;
	       mul_res_ready <= 1;
	       m_state <= M_INIT;
	       pcount <= pcount - 1;
	    end
	 end
      end
      else if (state == S_A_2_50) begin
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
	       a_2_50 <= mul_out;
	       b <= mul_out;
	       mul_res_ready <= 1;
	       m_state <= M_INIT;
	       pcount <= 50;
	       state <= S_B_2_100;
	    end
	 end
      end
      else if (state == S_B_2_100) begin
	 if (pcount == 0) begin
	    state <= S_A_2_100;
	 end
	 else if (m_state == M_INIT) begin
	    mul_res_ready <= 0;
	    mul_req_valid <= 1;
	    if (mul_req_ready) begin
	       mul_req_valid <= 0;
	       m_state <= M_WAIT;
	    end
	 end
	 else if (m_state == M_WAIT) begin
	    if (!mul_req_busy & mul_res_valid) begin
	       b <= mul_out;
	       mul_res_ready <= 1;
	       m_state <= M_INIT;
	       pcount <= pcount - 1;
	    end
	 end
      end
      else if (state == S_A_2_100) begin
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
	       a_2_100 <= mul_out;
	       b <= mul_out;
	       mul_res_ready <= 1;
	       m_state <= M_INIT;
	       pcount <= 100;
	       state <= S_B_2_200;
	    end
	 end
      end
      else if (state == S_B_2_200) begin
	 if (pcount == 0) begin
	    state <= S_A_2_200;
	 end
	 else if (m_state == M_INIT) begin
	    mul_res_ready <= 0;
	    mul_req_valid <= 1;
	    if (mul_req_ready) begin
	       mul_req_valid <= 0;
	       m_state <= M_WAIT;
	    end
	 end
	 else if (m_state == M_WAIT) begin
	    if (!mul_req_busy & mul_res_valid) begin
	       b <= mul_out;
	       mul_res_ready <= 1;
	       m_state <= M_INIT;
	       pcount <= pcount - 1;
	    end
	 end
      end
      else if (state == S_A_2_200) begin
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
	       a_2_200 <= mul_out;
	       b <= mul_out;
	       mul_res_ready <= 1;
	       m_state <= M_INIT;
	       pcount <= 50;
	       state <= S_B_2_250;
	    end
	 end
      end
      else if (state == S_B_2_250) begin
	 if (pcount == 0) begin
	    state <= S_A_2_250;
	 end
	 else if (m_state == M_INIT) begin
	    mul_res_ready <= 0;
	    mul_req_valid <= 1;
	    if (mul_req_ready) begin
	       mul_req_valid <= 0;
	       m_state <= M_WAIT;
	    end
	 end
	 else if (m_state == M_WAIT) begin
	    if (!mul_req_busy & mul_res_valid) begin
	       b <= mul_out;
	       mul_res_ready <= 1;
	       m_state <= M_INIT;
	       pcount <= pcount - 1;
	    end
	 end
      end
      else if (state == S_A_2_250) begin
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
	       a_2_250 <= mul_out;
	       b <= mul_out;
	       mul_res_ready <= 1;
	       m_state <= M_INIT;
	       pcount <= 5;
	       state <= S_B_2_255;
	    end
	 end
      end
      else if (state == S_B_2_255) begin
	 if (pcount == 0) begin
	    state <= S_INV;
	 end
	 else if (m_state == M_INIT) begin
	    mul_res_ready <= 0;
	    mul_req_valid <= 1;
	    if (mul_req_ready) begin
	       mul_req_valid <= 0;
	       m_state <= M_WAIT;
	    end
	 end
	 else if (m_state == M_WAIT) begin
	    if (!mul_req_busy & mul_res_valid) begin
	       b <= mul_out;
	       mul_res_ready <= 1;
	       m_state <= M_INIT;
	       pcount <= pcount - 1;
	    end
	 end
      end
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
	       Xinv <= mul_out;
	       mul_res_ready <= 1;
	       m_state <= M_INIT;
               res_valid <= 1;
               req_busy <= 0;
	       state <= S_POST;
	    end
	 end
      end
      else if (state == S_POST) begin
	 if (res_ready) begin
	    res_valid <= 0;
	    state <= S_IDLE;
	 end
      end
   end

endmodule
