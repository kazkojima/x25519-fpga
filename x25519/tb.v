`timescale 1 ns / 1 ps

`define P25519 255'd57896044618658097711785492504343953926634992332820282019728792003956564819949

//`define test_invm
//`define test_multmod
//`define test_point_add
`define test_scalarmultB

module testbench;
   reg clk;

   reg [10:0] state = 0;
   reg rst;
   wire [254:0] x3_out, y3_out, t3_out, z3_out;
   wire req_ready, req_busy, res_valid;
   reg res_ready;

/*
   addmod addmod0(.a(255'd15112221349535400772501151409588531511454012693041857206046113283949847762202),
		  .b(255'd46316835694926478169428394003475163141307993866256225615783033603165251855960),
		  .z(x3_out));

   submod submod0(.a(255'd15112221349535400772501151409588531511454012693041857206046113283949847762202),
		  .b(255'd46316835694926478169428394003475163141307993866256225615783033603165251855960),
		  .z(x3_out));
*/

`ifdef test_invm
`define report_period 1000
`define report_times 2
`define result_out 255'd28948022309329048855892746252171976963317496166410141009864396001978282409975

   inv_montgomery #(.N(255)) inv0
   (.clk(clk), .rst(rst), .X(255'd2), .M(`P25519), .R(x3_out),
    .real_inverse(1'b1),
    .req_valid(1'b1), .req_ready(req_ready), .req_busy(req_busy),
    .res_valid(res_valid), .res_ready(res_ready));
`endif

`ifdef test_multmod
`define report_period 1000
`define report_times 2
`define result_out 255'd41103782855417034832585754869730994192149373423248309125618910375726204070323

     multmod multmod0
     (.clk(clk), .rst(rst), .X(255'd3533012425803781230144052908719740726127014226477800802100354883158534798213), .Y(255'd3533012425803781230144052908719740726127014226477800802100354883158534798213), .Z(x3_out), .req_valid(1'b1),
    .req_ready(req_ready), .req_busy(req_busy), .res_valid(res_valid),
    .res_ready(res_ready));
`endif

`ifdef test_point_add
`define result_pt
`define report_period 2000
`define report_times 2
`define result_xout 255'd46896733464454938657123544595386787789046198280132665686241321779790909858396
`define result_yout 255'd8324843778533443976490377120369201138301417226297555316741202210403726505172

    point_add padd0(.clk(clk), .rst(rst),
		   .x1(255'd15112221349535400772501151409588531511454012693041857206046113283949847762202),
		   .y1(255'd46316835694926478169428394003475163141307993866256225615783033603165251855960),
		   .t1(255'd46827403850823179245072216630277197565144205554125654976674165829533817101731),
		   .z1(255'd1),
		   .x2(255'd24727413235106541002554574571675588834622768167397638456726423682521233608206),
		   .y2(255'd15549675580280190176352668710449542251549572066445060580507079593062643049417),
		   .t2(255'd16552979481334663544878610556091376071931149008662153799327195285289362371585),
		   .z2(255'd1),
		   .x3(x3_out), .y3(y3_out), .t3(t3_out), .z3(z3_out),
		   .affine(1'b1),
 		   .req_valid(1'b1),
		   .req_ready(req_ready),
		   .req_busy(req_busy),
		   .res_valid(res_valid),
		   .res_ready(res_ready));
`endif

`ifdef test_scalarmultB
`define result_pt
`define report_period 10000
`define report_times 8
`define result_xout 255'd17351483335618955898257769922188544065278108135404925499428750032271660309906
`define result_yout 255'd29738576592467362110154903071697150364418431465120291767221481889329610038128

    scalarmultB smlt0(.clk(clk), .rst(rst),
		     .K(255'd15112221349535400772501151409588531511454012693041857206046113283949847762202),
		     .px(x3_out), .py(y3_out), .pt(t3_out), .pz(z3_out),
		     .affine(1'b1),
		     .req_valid(1'b1),
		     .req_ready(req_ready),
		     .req_busy(req_busy),
		     .res_valid(res_valid),
		     .res_ready(res_ready));
`endif

   always #5 clk = (clk === 1'b0);

   initial
     begin
        state = 0;
	rst = 1'b1;
        $dumpfile("testbench.vcd");
        $dumpvars(0, testbench);

        repeat (`report_times) begin
           repeat (`report_period) @(posedge clk);
           $display("+%d cycles", `report_period);
        end
        $finish;
     end

  always @(posedge clk) begin
      state <= state + 1;
      if (state > 3) begin
	 rst <= 0;
      end
      else begin
	 res_ready <= 0;
      end
      if (!rst) begin
	 if (res_valid & !res_ready) begin
`ifdef result_pt
	    $display($time,,,"x3=%d, y3=%d, t3=%d, z3=%d", x3_out, y3_out, t3_out, z3_out);
	    if ((x3_out == `result_xout) & (y3_out == `result_yout)) begin
	       $display("Result OK");
	    end
`else
	    $display($time,,,"z=%d", x3_out);
	    if (x3_out == `result_out) begin

	       $display("Result OK");
	    end
`endif
	    res_ready <= 1;
	 end
	 else if (!res_valid) begin
	    res_ready <= 0;
	 end
      end
      //$display($time,,,"state=%d rst=%d", state, rst);
   end

endmodule // testbench
