// Montgomery modular imverse implementation based on
//
//  Dormale, G.M. & Bulens, P. & Quisquater, Jean-Jacques. (2005).
//  An improved Montgomery modular inversion targeted for efficient
//  implementation on FPGA. 441 - 444. 10.1109/FPT.2004.1393320. 

// Input X in 1:M-1 and M
// Output R in 1:M-1 where R = Xinv*2^n mod M
module inv_montgomery #(parameter N = 255)
   (input clk,
    input rst,
    input [N-1:0] X,
    input [N-1:0] M,
    output reg [N-1:0] R,
    input req_valid,
    output reg req_ready,
    output reg req_busy,
    output reg res_valid,
    input res_ready);

   // Phase1
   reg [3:0] state;
   reg [9:0] k;
   reg [2*N-1:0] Luv, Ruv, Lrs, Rrs;
   reg [2*N-1:0] hLuv, dLuv, hRrs, dRrs, dLrs, addLuv, subLuv, subLrs, hLrs, addLrs;
   reg SLuv, SRuv, nSLuv, nSLrs;

   always @* begin
      if (state == S_PHASE1_END) begin
	 subLrs = Lrs - Rrs;
	 nSLrs = subLrs[2*N-1:2*N-1];
      end
      else if (state == S_LOOP2) begin
	 hLrs = { Lrs[2*N-1:2*N-1], Lrs[2*N-1:1] };
	 addLrs = Lrs + Rrs;
      end
   end // always @ *

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
	 Luv <= { Luv[2*N-1:2*N-1], Luv[2*N-1:1] } + Ruv;
	 Ruv <= M;
	 Lrs <= Lrs + Rrs;
	 Rrs <= 0;
      end
      else if (state == S_LOOP1_STEP1) begin
	 SLuv <= Luv[2*N-1:2*N-1];
	 SRuv <= Ruv[2*N-1:2*N-1];
	 hLuv <= { Luv[2*N-1:2*N-1], Luv[2*N-1:1] };
	 dLuv <= { Luv[2*N-2:0], 1'b0 };
	 hRrs <= { Rrs[2*N-1:2*N-1], Rrs[2*N-1:1] };
	 dRrs <= { Rrs[2*N-2:0], 1'b0 };
	 dLrs <= { Lrs[2*N-2:0], 1'b0 };
	 addLuv <= { Luv[2*N-1:2*N-1], Luv[2*N-1:1] } + Ruv;
	 subLuv <= { Luv[2*N-1:2*N-1], Luv[2*N-1:1] } - Ruv;
	 state <= S_LOOP1_STEP2;
      end
      else if (state == S_LOOP1_STEP2) begin
	 nSLuv = (SLuv ^ SRuv) ? addLuv[2*N-1:2*N-1] : subLuv[2*N-1:2*N-1];
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
	 if (k == N) begin
	    state <= S_POST;
	    R <= Lrs;
	    res_valid <= 1;
	    req_busy <= 0;
	 end
	 else begin
	    k <= k - 1;
	    Lrs <= (Lrs[0] == 1'b0) ? hLrs : addLrs[2*N-1:1];
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
