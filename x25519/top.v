`timescale 1 ns / 1 ps

`define P25519 255'd57896044618658097711785492504343953926634992332820282019728792003956564819949

`include "./csa.v"
`include "./addmod.v"
`include "./submod.v"
`include "./multmod.v"
`include "./inv_montgomery.v"
`include "./point_add.v"
`include "./scalarmultB.v"

module pll_12_50(input clki, output clko);
    (* ICP_CURRENT="12" *) (* LPF_RESISTOR="8" *) (* MFG_ENABLE_FILTEROPAMP="1" *) (* MFG_GMCREF_SEL="2" *)
    EHXPLLL #(
        .PLLRST_ENA("DISABLED"),
        .INTFB_WAKE("DISABLED"),
        .STDBY_ENABLE("DISABLED"),
        .DPHASE_SOURCE("DISABLED"),
        .CLKOP_FPHASE(0),
        .CLKOP_CPHASE(11),
        .OUTDIVIDER_MUXA("DIVA"),
        .CLKOP_ENABLE("ENABLED"),
        .CLKOP_DIV(12),
        .CLKFB_DIV(25),
        .CLKI_DIV(6),
        .FEEDBK_PATH("CLKOP")
    ) pll_i (
        .CLKI(clki),
        .CLKFB(clko),
        .CLKOP(clko),
        .RST(1'b0),
        .STDBY(1'b0),
        .PHASESEL0(1'b0),
        .PHASESEL1(1'b0),
        .PHASEDIR(1'b0),
        .PHASESTEP(1'b0),
        .PLLWAKESYNC(1'b0),
        .ENCLKOP(1'b0),
    );
endmodule

module top(input wire clk,
           input wire rstn,
           output tp0,
           output [7:0] led);

   reg [7:0] state;
   reg [5:0] count;
   wire rst;
   wire [254:0] x3_out, y3_out, t3_out, z3_out;
   wire req_ready, req_busy, res_valid;
   reg res_ready;

   wire refclk;

   pll_12_50 pll_inst(clk, refclk);

/*
    addmod addmod0(.a(255'd15112221349535400772501151409588531511454012693041857206046113283949847762202),
		  .b(255'd46316835694926478169428394003475163141307993866256225615783033603165251855960),
		  .z(x3_out));

   
   submod submod0(.a(255'd15112221349535400772501151409588531511454012693041857206046113283949847762202),
		  .b(255'd46316835694926478169428394003475163141307993866256225615783033603165251855960),
		  .z(x3_out));

   inv_montgomery #(.N(255)) inv0
   (.clk(refclk), .rst(rst), .X(255'd2), .M(`P25519), .R(x3_out),
    .real_inverse(1'b1),
    .req_valid(1'b1), .req_ready(req_ready), .req_busy(req_busy),
    .res_valid(res_valid), .res_ready(res_ready));

    point_add padd0(.clk(refclk), .rst(rst),
		   .x1(255'd15112221349535400772501151409588531511454012693041857206046113283949847762202),
		   .y1(255'd46316835694926478169428394003475163141307993866256225615783033603165251855960),
		   .t1(255'd46827403850823179245072216630277197565144205554125654976674165829533817101731),
		   .z1(255'd1),
		   .x2(255'd24727413235106541002554574571675588834622768167397638456726423682521233608206),
		   .y2(255'd15549675580280190176352668710449542251549572066445060580507079593062643049417),
		   .t2(255'd16552979481334663544878610556091376071931149008662153799327195285289362371585),
		   .z2(255'd1),
		   .x3(x3_out), .y3(y3_out), .t3(t3_out), .z3(z3_out),
		   .affine(1'b0),
 		   .req_valid(1'b1),
		   .req_ready(req_ready),
		   .req_busy(req_busy),
		   .res_valid(res_valid),
		   .res_ready(res_ready));

    multmod multmod0
     (.clk(refclk), .rst(rst), .X(255'd28948022309329048855892746252171976963317496166410141009864396001978282409984), .Y(255'd21330121701610878104342023554231983025602365596302209165163239159352418617876), .Z(x3_out), .req_valid(1'b1),
    .req_ready(req_ready), .req_busy(req_busy), .res_valid(res_valid),
    .res_ready(res_ready));
*/
     scalarmultB smlt0(.clk(refclk), .rst(rst),
		     .K(255'd15112221349535400772501151409588531511454012693041857206046113283949847762202),
		     .px(x3_out), .py(y3_out), .pt(t3_out), .pz(z3_out),
		     .affine(1'b1),
		     .req_valid(1'b1),
		     .req_ready(req_ready),
		     .req_busy(req_busy),
		     .res_valid(res_valid),
		     .res_ready(res_ready));

   //assign led[7] = ~res_valid;
   //assign led[6] = ~req_busy;
   assign led[7:0] = ~count;
   assign tp0 = ~&x3_out;

   always @(posedge clk) begin
      if (rstn == 0) begin
	 rst <= 1;
	 res_ready <= 0;
	 state <= 0;
	 count <= 0;
      end
      else begin
	 state <= state + 1;
      end
      if (state > 3) begin
	 rst <= 0;
      end
      if (!rst) begin
	 if (res_valid & !res_ready) begin
	    res_ready <= 1;
	    if (x3_out == 255'd17351483335618955898257769922188544065278108135404925499428750032271660309906) begin
	       count <= count + 1;
	    end
	 end
 	 else if (!res_valid) begin
	    res_ready <= 0;
	 end
     end
   end

endmodule // testbench
