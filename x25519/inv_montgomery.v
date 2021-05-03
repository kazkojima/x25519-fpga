// Montgomery modular imverse implementation based on
//
//  Dormale, G.M. & Bulens, P. & Quisquater, Jean-Jacques. (2005).
//  An improved Montgomery modular inversion targeted for efficient
//  implementation on FPGA. 441 - 444. 10.1109/FPT.2004.1393320. 

// Input X in 1:M-1 and M
// Output R in 1:M-1 where R = Xinv*2^n mod M
//  if real_inverse == false, then n = bit size of M else n = 0
module inv_montgomery #(parameter N = 255)
   (input clk,
    input rst,
    input [N-1:0] X,
    input [N-1:0] M,
    output reg [N-1:0] R,
    input real_inverse,
    input req_valid,
    output reg req_ready,
    output reg req_busy,
    output reg res_valid,
    input res_ready);

   // Phase1
   reg [3:0] state;
   reg [10:0] k;
   wire [10:0] n_ph2;
   reg [(N+2)-1:0] Luv, Ruv, Lrs, Rrs;
   reg [(N+2)-1:0] hLuv, dLuv, hRrs, dRrs, dLrs, addLuv, subLuv;
   wire [(N+2)-1:0] subLrs, hLrs, addLrs;
   reg SLuv, SRuv, nSLuv;
   wire nSLrs;

   assign n_ph2 = (real_inverse) ? 0 : N;

   // S_PHASE1_END state
   assign subLrs = Lrs - Rrs;
   assign nSLrs = subLrs[(N+2)-1];
   // S_LOOP2 state
   assign hLrs = { Lrs[(N+2)-1:(N+2)-1], Lrs[(N+2)-1:1] };
   assign addLrs = Lrs + Rrs;

   localparam S_IDLE = 1;
   localparam S_READY = 2;
   localparam S_LOOP1_STEP1 = 3;
   localparam S_LOOP1_STEP2 = 4;
   localparam S_LOOP1_UPDATE = 5;
   localparam S_PHASE1_END = 6;
   localparam S_LOOP2 = 7;
   localparam S_POST = 8;
			
   always @(posedge clk) begin
      //$display($time,,,"istate=%d rst=%d", state, rst);
      
      if (rst) begin
	 state <= S_IDLE;
	 req_ready <= 0;
	 req_busy <= 0;
	 res_valid <= 0;
	 k <= 0;
	 Luv <= 0;
	 Ruv <= 0;
	 Lrs <= 0;
	 Rrs <= 1;
      end
      else if (state == S_IDLE) begin
	 if (req_valid == 1'b1) begin
	    Ruv <= { X, 1'b0 };
	    req_ready <= 1;
	    req_busy <= 1;
	    state <= S_READY;
	 end
      end
      else if (state == S_READY) begin
	 req_ready <= 0;
	 state <= S_LOOP1_STEP1;
	 Luv <= { Luv[(N+2)-1:(N+2)-1], Luv[(N+2)-1:1] } + Ruv;
	 Ruv <= M;
	 Lrs <= Lrs + Rrs;
	 Rrs <= 0;
      end
      else if (state == S_LOOP1_STEP1) begin
	 SLuv <= Luv[(N+2)-1:(N+2)-1];
	 SRuv <= Ruv[(N+2)-1:(N+2)-1];
	 hLuv <= { Luv[(N+2)-1:(N+2)-1], Luv[(N+2)-1:1] };
	 dLuv <= { Luv[(N+2)-2:0], 1'b0 };
	 hRrs <= { Rrs[(N+2)-1:(N+2)-1], Rrs[(N+2)-1:1] };
	 dRrs <= { Rrs[(N+2)-2:0], 1'b0 };
	 dLrs <= { Lrs[(N+2)-2:0], 1'b0 };
	 addLuv <= { Luv[(N+2)-1:(N+2)-1], Luv[(N+2)-1:1] } + Ruv;
	 subLuv <= { Luv[(N+2)-1:(N+2)-1], Luv[(N+2)-1:1] } - Ruv;
	 state <= S_LOOP1_STEP2;
      end
      else if (state == S_LOOP1_STEP2) begin
	 nSLuv = (SLuv ^ SRuv) ? addLuv[(N+2)-1:(N+2)-1] : subLuv[(N+2)-1:(N+2)-1];
	 state <= S_LOOP1_UPDATE;
      end
      else if (state == S_LOOP1_UPDATE) begin
	 //$display("Luv %d Ruv %d Lrs %d Rrs %d k %d", Luv, Ruv, Lrs, Rrs, k);
	 if (Luv[1:1] == 1'b0) begin
	    if (Luv == 0) begin
	       state <=  S_PHASE1_END;
	    end
	    else begin
	       //$display("@0");
	       Luv <= hLuv;
	       Rrs <= dRrs;
	       k <= k + 1;
	       state <=  S_LOOP1_STEP1;
	    end
	 end
	 else begin
	    //$display("@1 addLuv %d subLuv %d %d", addLuv, subLuv, nSLuv);
	    Lrs <= Lrs + Rrs;
	    Luv <= (SLuv ^ SRuv) ? addLuv : subLuv;
	    k <= k + 1;
	    if (nSLuv == ((~SLuv & ~SRuv) | (~SLuv & SRuv))) begin
	       //$display("@2");
	       Ruv <= hLuv;
	       Rrs <= dLrs;
	    end
	    else begin
	       //$display("@3");
	       Rrs <= dRrs;
	    end
	    state <=  S_LOOP1_STEP1;
	 end
      end
      else if (state == S_PHASE1_END) begin
	 Lrs <= (nSLrs == 1'b0) ? subLrs : subLrs + M;
	 Rrs <= M;
	 state <= S_LOOP2;
      end
      else if (state == S_LOOP2) begin
	 //$display("Lrs %d Rrs %d k %d", Lrs, Rrs, k);
	 if (k == n_ph2) begin
	    state <= S_POST;
	    R <= Lrs;
	    res_valid <= 1;
	    req_busy <= 0;
	 end
	 else begin
	    k <= k - 1;
	    Lrs <= (Lrs[0] == 1'b0) ? hLrs : addLrs[(N+2)-1:1];
	 end
      end
      else if (state == S_POST) begin
	 if (res_ready == 1'b1) begin
	    res_valid <= 0;
	    state <= S_IDLE;
	    k <= 0;
	    Luv <= 0;
	    Ruv <= 0;
	    Lrs <= 0;
	    Rrs <= 1;
	 end
      end
   end

endmodule
